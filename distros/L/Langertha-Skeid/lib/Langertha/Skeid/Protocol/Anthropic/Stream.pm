package Langertha::Skeid::Protocol::Anthropic::Stream;
our $VERSION = '0.003';
# ABSTRACT: Rewrites an OpenAI SSE stream as Anthropic streaming events
use strict;
use warnings;
use Langertha::Skeid::Protocol;
use Langertha::Skeid::Protocol::Anthropic;



sub new {
  my ($class, %args) = @_;
  return bless {
    model      => ($args{model} // ''),
    message_id => ($args{message_id} // ('msg_' . int(time * 1000))),
    started       => 0,
    finished      => 0,
    errored       => 0,
    output_tokens => 0,
    input_tokens  => 0,
    stop_reason   => undef,
    finish_reason => undef,
    text_bytes    => 0,

    # Content-block state. The OpenAI stream numbers parallel tool calls by their position
    # in tool_calls[i].index; Anthropic numbers content blocks by their own order of
    # appearance. The two numberings are different, so the translator keeps a map:
    # tool_blocks keyed by the OpenAI index, each value an {anthropic_index, id, name,
    # partial_json} record. open_blocks lists the Anthropic indices still awaiting a
    # content_block_stop; next_index is the Anthropic index the next new block will get.
    next_index      => 0,
    text_index      => undef,
    text_started    => 0,
    tool_blocks     => {},
    open_blocks     => [],
  }, $class;
}


sub content_type { 'text/event-stream' }

sub _event {
  my ($name, $payload) = @_;
  return "event: $name\ndata: " . Langertha::Skeid::Protocol::encode_json_safe($payload) . "\n\n";
}


sub start {
  my ($self) = @_;
  return '' if $self->{started};
  $self->{started} = 1;

  # The SSE event name and the "type" inside its data must agree: the official SDKs dispatch on
  # the data field, not on the event line, so a message_start carrying type "message" is a
  # frame they do not recognise as the start of anything.
  return _event('message_start', {
    type    => 'message_start',
    message => {
      id            => $self->{message_id},
      type          => 'message',
      role          => 'assistant',
      model         => $self->{model},
      content       => [],
      stop_reason   => undef,
      stop_sequence => undef,
      usage         => { input_tokens => 0, output_tokens => 0 },
    },
  });
}


sub delta {
  my ($self, $chunk) = @_;
  return '' unless ref($chunk) eq 'HASH';

  return '' if $self->{finished};

  # Some servers report a failure inside an open stream as a chunk carrying an OpenAI error
  # object instead of choices. The HTTP status is already 200, so it can only reach an
  # Anthropic client in-band, as an error event -- and nothing after it (core karr #224).
  if (ref($chunk->{error}) eq 'HASH') {
    my $message = $chunk->{error}{message} // 'upstream error';
    return $self->error_event(500, "Upstream error: $message", $chunk->{error}{type});
  }

  my $out = '';
  $out .= $self->start unless $self->{started};

  # Usage can arrive on any chunk and usually arrives on the last one, which is also the
  # chunk that has no content. Recorded whenever seen, reported at the end.
  if (my $usage = $chunk->{usage}) {
    $self->{input_tokens}  = 0 + ($usage->{prompt_tokens}     // $usage->{input_tokens}  // $self->{input_tokens});
    $self->{output_tokens} = 0 + ($usage->{completion_tokens} // $usage->{output_tokens} // $self->{output_tokens});
  }

  my $choice = (ref($chunk->{choices}) eq 'ARRAY' ? $chunk->{choices}[0] : undef) || {};
  if (defined(my $reason = $choice->{finish_reason})) {
    $self->{finish_reason} = $reason;
    $self->{stop_reason} = $reason eq 'tool_calls' ? 'tool_use'
                         : $reason eq 'length'     ? 'max_tokens'
                         :                           'end_turn';
  }

  my $delta = $choice->{delta} || {};

  # Text content. The first text delta opens a text block at the next free Anthropic index;
  # later deltas extend it.
  my $text = $delta->{content};
  if (defined($text) && length($text)) {
    if (!$self->{text_started}) {
      $self->{text_index}   = $self->{next_index}++;
      $self->{text_started} = 1;
      push @{$self->{open_blocks}}, $self->{text_index};
      $out .= _event('content_block_start', {
        type          => 'content_block_start',
        index         => $self->{text_index},
        content_block => { type => 'text', text => '' },
      });
    }
    $self->{text_bytes} += Langertha::Skeid::Protocol::utf8_length($text);
    $out .= _event('content_block_delta', {
      type  => 'content_block_delta',
      index => $self->{text_index},
      delta => { type => 'text_delta', text => $text },
    });
  }

  # Tool calls. OpenAI tracks parallel calls by tool_calls[i].index; Anthropic tracks content
  # blocks by their own order. The first time we see a new tool_calls index we allocate an
  # Anthropic block; later arguments-only deltas for the same index extend it with
  # partial_json.
  if (ref($delta->{tool_calls}) eq 'ARRAY') {
    for my $call (@{$delta->{tool_calls}}) {
      next unless ref($call) eq 'HASH';
      my $tool_idx = $call->{index} // 0;

      # Lazily allocate a content block for this OpenAI tool_call index. The do block
      # returns a hashref; ||= stores it under tool_blocks{$tool_idx} and binds $block to
      # the same ref.
      my $block = $self->{tool_blocks}{$tool_idx} ||= do {
        my $anthropic_index = $self->{next_index}++;
        push @{$self->{open_blocks}}, $anthropic_index;
        {
          anthropic_index => $anthropic_index,
          id              => ($call->{id} // ''),
          name            => ($call->{function}{name} // ''),
          partial_json    => '',
          emitted_start   => 0,
        };
      };

      # The OpenAI convention is the first chunk for a call carries id+name and later
      # chunks carry only arguments; tolerate either order, fill in whatever this chunk
      # brought.
      $block->{id}   = $call->{id}             if defined $call->{id};
      $block->{name} = $call->{function}{name} if defined $call->{function}{name};

      unless ($block->{emitted_start}) {
        $block->{emitted_start} = 1;
        $out .= _event('content_block_start', {
          type          => 'content_block_start',
          index         => $block->{anthropic_index},
          content_block => {
            type  => 'tool_use',
            id    => $block->{id},
            name  => $block->{name},
            input => {},
          },
        });
      }

      my $args = $call->{function}{arguments};
      if (defined($args) && length($args)) {
        $block->{partial_json} .= $args;
        $out .= _event('content_block_delta', {
          type  => 'content_block_delta',
          index => $block->{anthropic_index},
          delta => { type => 'input_json_delta', partial_json => $args },
        });
      }
    }
  }

  return $out;
}


sub finish {
  my ($self, %args) = @_;
  return '' if $self->{finished};

  my $out = '';
  $out .= $self->start unless $self->{started};
  $self->{finished} = 1;

  for my $idx (@{$self->{open_blocks}}) {
    $out .= _event('content_block_stop', {
      type  => 'content_block_stop',
      index => $idx,
    });
  }
  @{$self->{open_blocks}} = ();

  # A stream that emitted tool_use blocks and then finished with 'stop' (gpt-oss on
  # vLLM-style servers) ends with stop_reason tool_use, the same rule as the non-streaming
  # translation: tool calls present wins over 'stop' (core k248).
  my $stop_reason = $args{stop_reason};
  if (!defined $stop_reason) {
    my $finish_reason = $self->{finish_reason} // 'stop';
    $stop_reason = (%{$self->{tool_blocks}} && $finish_reason eq 'stop')
      ? 'tool_use'
      : ($self->{stop_reason} // 'end_turn');
  }

  $out .= _event('message_delta', {
    type  => 'message_delta',
    delta => {
      stop_reason   => $stop_reason,
      stop_sequence => undef,
    },
    usage => { output_tokens => 0 + ($args{output_tokens} // $self->{output_tokens} // 0) },
  });

  $out .= _event('message_stop', { type => 'message_stop' });
  return $out;
}


sub error_event {
  my ($self, $status, $message, $type) = @_;
  return '' if $self->{finished};
  $self->{finished} = 1;
  $self->{errored}  = 1;
  return _event('error', Langertha::Skeid::Protocol::Anthropic->error_body($status, $message, $type));
}


sub errored { $_[0]->{errored} }


sub usage {
  my ($self) = @_;
  return ($self->{input_tokens}, $self->{output_tokens}, $self->{text_bytes});
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol::Anthropic::Stream - Rewrites an OpenAI SSE stream as Anthropic streaming events

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Skeid makes one shape of upstream call and translates at the client edge (ADR 0001). For a
non-streaming response that is one function; for a stream it needs state, because Anthropic's
format is an event protocol rather than a sequence of deltas: a client is told a message began,
that a content block opened, then the text, then that both closed -- and the token counts arrive
in the closing events.

An OpenAI stream says none of that. It sends deltas and stops. Everything else here is
synthesised at the right moment from what the OpenAI stream does say.

  my $stream = Langertha::Skeid::Protocol::Anthropic::Stream->new(model => 'claude-x');
  $write->($stream->start);
  $write->($stream->delta($openai_chunk)) for @chunks;
  $write->($stream->finish);

Every method returns bytes to write, possibly empty. C<start> and C<finish> are idempotent, so
a stream that fails mid-flight can still be closed correctly.

=head2 new

  my $stream = Langertha::Skeid::Protocol::Anthropic::Stream->new(model => $requested_model);

C<model> is the model named in C<message_start> -- the one the client asked for. C<message_id>
defaults to C<msg_> plus the current time in milliseconds.

=head2 content_type

The C<Content-Type> the client edge must send. Anthropic streams are SSE, same as OpenAI, but
the events inside are not interchangeable -- which is exactly why this class exists.

=head2 start

Opens the message. Content blocks are not opened here -- they open lazily on the first delta
of the kind that fills them, so a stream whose first content is a tool call does not emit an
empty text block before the tool_use block.

=head2 delta

  my $bytes = $stream->delta($openai_chunk);

Turns one decoded OpenAI chunk into whatever Anthropic events it implies: a
C<content_block_start> the first time a content block is seen (text or tool_use), one
C<content_block_delta> per delta of that block, and along the way the usage and finish
reason that the closing events need. The first chunk for a tool_calls index opens its
block; later arguments-only deltas for the same index extend it with partial_json.

The translator carries enough state for parallel tool calls: each OpenAI tool_calls index is
mapped to its own Anthropic content block, allocated in order of first appearance, and the
list of still-open blocks is closed in order when C<finish> runs.

A chunk carrying an OpenAI C<error> object instead of choices (how some servers report a
failure inside an open stream) ends the stream with L</error_event>.

=head2 finish

Closes every still-open content block and then the message. The token count goes on
C<message_delta>, because an Anthropic client reads usage from there, and so does the
C<stop_reason>: C<tool_use> whenever tool_use blocks were emitted and the upstream finished with
C<stop> or not at all, otherwise the mapping of the upstream C<finish_reason>.

Idempotent, and it opens the message first if nothing ever did: a stream that produced no
text and no tool calls still has to be a well-formed Anthropic message, or the client waits
for an end that never comes. C<< stop_reason => ... >> and C<< output_tokens => ... >>
override what the stream recorded.

=head2 error_event

  my $bytes = $stream->error_event(500, 'Upstream error: ...');
  my $bytes = $stream->error_event(500, $message, $upstream_type);

Ends the stream with an Anthropic C<event: error> frame, the way Anthropic reports a failure
after the stream has opened (the HTTP status is already 200 by then). The frame's data is
L<Langertha::Skeid::Protocol::Anthropic/error_body>, so its C<error.type> follows the same
status mapping as every other error on C</v1/messages>; an upstream error type Anthropic also
uses (an error chunk's C<rate_limit_error>, say) is kept.

The stream is finished afterwards: C<delta> and C<finish> return nothing, so no
C<message_stop> follows and a client cannot mistake a failed stream for a complete one. Open
content blocks are left unclosed, as Anthropic leaves them. Returns nothing if the stream has
already finished.

=head2 errored

True once L</error_event> ended the stream, so the proxy records the request as failed even
though the HTTP status was 200.

=head2 usage

  my ($input, $output, $content_bytes) = $stream->usage;

What the stream carried, for the usage event. C<content_bytes> (UTF-8 bytes of the text this
translator wrote) becomes the event's C<content_bytes>, recorded beside the token counts on every
stream -- an observation, never an estimate of tokens.

=head1 SEE ALSO

L<Langertha::Skeid::Protocol::Anthropic>, L<Langertha::Skeid::Protocol::Ollama::Stream>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
