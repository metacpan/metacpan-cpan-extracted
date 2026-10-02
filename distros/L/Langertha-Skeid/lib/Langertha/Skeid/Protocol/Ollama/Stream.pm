package Langertha::Skeid::Protocol::Ollama::Stream;
our $VERSION = '0.003';
# ABSTRACT: Rewrites an OpenAI SSE stream as Ollama newline-delimited JSON
use strict;
use warnings;
use Langertha::Skeid::Protocol;
use Langertha::Skeid::Protocol::Ollama;



sub new {
  my ($class, %args) = @_;
  return bless {
    model         => ($args{model} // ''),
    shape         => (($args{shape} // 'chat') eq 'generate' ? 'generate' : 'chat'),
    started       => 0,
    finished      => 0,
    input_tokens  => 0,
    output_tokens => 0,
    done_reason   => undef,
    text_bytes    => 0,
    errored       => 0,
    tool_stream_state => {},
    tool_parser_active => 0,
    tool_call_pending  => 0,
  }, $class;
}


sub content_type { 'application/x-ndjson' }

sub _line {
  my ($payload) = @_;
  return Langertha::Skeid::Protocol::encode_json_safe($payload) . "\n";
}

# Parsing OpenAI tool-call deltas is Langertha's wire-format job.  The parser
# object is stateless when every caller supplies its own state, so construct it
# only when the first tool fragment reaches this process and share it; each
# translator below still owns a separate tool_stream_state HashRef.
my $OPENAI_STREAM_PARSER;
sub _openai_stream_parser {
  require Langertha::Engine::OpenAIBase;
  return $OPENAI_STREAM_PARSER ||= Langertha::Engine::OpenAIBase->new(
    url => 'http://skeid.invalid',
  );
}

# The state belongs to one translated request.  Replacing our reference ends
# its lifetime without reaching into Langertha's private parser state.
sub _discard_tool_stream_state {
  my ($self) = @_;
  $self->{tool_stream_state} = {};
  $self->{tool_parser_active} = 0;
  $self->{tool_call_pending} = 0;
  return;
}

# Feed a tool-bearing stream through Langertha until it returns finished
# Langertha::ToolCall objects.  Text-only streams never instantiate the engine,
# and /api/generate never grows a chat-only tool_calls field.
sub _tool_calls_from_chunk {
  my ($self, $chunk) = @_;
  return [] if $self->{shape} eq 'generate';

  my $choice = (ref($chunk->{choices}) eq 'ARRAY' ? $chunk->{choices}[0] : undef) || {};
  my $delta = ref($choice->{delta}) eq 'HASH' ? $choice->{delta} : {};
  my $fragments = $delta->{tool_calls};
  my $has_fragments = ref($fragments) eq 'ARRAY' && @$fragments;
  return [] unless $self->{tool_parser_active} || $has_fragments;

  if ($has_fragments) {
    $self->{tool_parser_active} = 1;
    $self->{tool_call_pending} = 1;
  }
  my $parsed = _openai_stream_parser()->parse_stream_chunk(
    $chunk, undef, $self->{tool_stream_state},
  );
  return [] unless $parsed;

  my $tool_calls = $parsed->has_tool_calls ? ($parsed->tool_calls // []) : [];
  die "OpenAI stream produced undecodable tool arguments\n"
    if grep { $_->arguments_undecodable } @$tool_calls;
  die "OpenAI stream ended without a complete tool call\n"
    if $parsed->is_final && $self->{tool_call_pending} && !@$tool_calls;

  $self->{tool_call_pending} = 0 if @$tool_calls;
  $self->_discard_tool_stream_state if $parsed->is_final;
  return $tool_calls;
}

# The content of one line in this stream's shape: a chat message, or generate's bare response.
sub _text_field {
  my ($self, $text, $tool_calls) = @_;
  return (response => $text) if $self->{shape} eq 'generate';

  my $message = { role => 'assistant', content => $text };
  $message->{tool_calls} = [ map { $_->to_ollama } @$tool_calls ]
    if ref($tool_calls) eq 'ARRAY' && @$tool_calls;
  return (message => $message);
}


sub start {
  my ($self) = @_;
  $self->{started} = 1;
  return '';
}


sub delta {
  my ($self, $chunk) = @_;
  return '' unless ref($chunk) eq 'HASH';
  return '' if $self->{finished};

  # Some servers report a failure inside an open stream as a chunk carrying an OpenAI error
  # object. The HTTP status is already 200, so an Ollama client can only learn of it in-band,
  # as Ollama's own error line -- and nothing after it (skeid #47).
  if (ref($chunk->{error}) eq 'HASH') {
    my $message = $chunk->{error}{message} // 'upstream error';
    return $self->error_event(500, "Upstream error: $message");
  }

  if (my $usage = $chunk->{usage}) {
    $self->{input_tokens}  = 0 + ($usage->{prompt_tokens}     // $usage->{input_tokens}  // $self->{input_tokens});
    $self->{output_tokens} = 0 + ($usage->{completion_tokens} // $usage->{output_tokens} // $self->{output_tokens});
  }

  my $choice = (ref($chunk->{choices}) eq 'ARRAY' ? $chunk->{choices}[0] : undef) || {};
  $self->{done_reason} = $choice->{finish_reason} if defined $choice->{finish_reason};
  $self->{model} = $chunk->{model} if defined($chunk->{model}) && length($chunk->{model});

  my $text = $choice->{delta}{content};
  my $tool_calls;
  unless (eval { $tool_calls = $self->_tool_calls_from_chunk($chunk); 1 }) {
    return $self->error_event(500, 'Upstream stream could not be translated');
  }
  my $has_text = defined($text) && length($text);
  return '' unless $has_text || @$tool_calls;

  $text = '' unless defined $text;
  $self->{started} = 1;
  $self->{text_bytes} += Langertha::Skeid::Protocol::utf8_length($text) if $has_text;
  return _line({
    model      => $self->{model},
    created_at => Langertha::Skeid::Protocol::iso8601_now(),
    $self->_text_field($text, $tool_calls),
    done       => \0,
  });
}


sub finish {
  my ($self, %args) = @_;
  return '' if $self->{finished};

  # A tool fragment is not a call until Langertha returns it on a final chunk.
  # Ending the request first is a failed stream, never a successful call with
  # guessed arguments.  Dropping our request-owned state needs no Core hook.
  if ($self->{tool_call_pending}) {
    return $self->error_event(500, 'Upstream tool stream ended without finish_reason');
  }

  my $line;
  unless (eval {
    $line = _line({
      model       => $self->{model},
      created_at  => Langertha::Skeid::Protocol::iso8601_now(),
      $self->_text_field(''),
      done        => \1,
      done_reason => ($args{done_reason} // $self->{done_reason} // 'stop'),
      prompt_eval_count => 0 + ($args{input_tokens}  // $self->{input_tokens}  // 0),
      eval_count        => 0 + ($args{output_tokens} // $self->{output_tokens} // 0),
    });
    1;
  }) {
    return $self->error_event(500, 'Stream translation failed');
  }

  $self->_discard_tool_stream_state;
  $self->{finished} = 1;
  return $line;
}


sub error_event {
  my ($self, $status, $message) = @_;
  return '' if $self->{finished};
  $self->_discard_tool_stream_state;
  $self->{finished} = 1;
  $self->{errored}  = 1;
  return _line(Langertha::Skeid::Protocol::Ollama->error_body($message));
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

Langertha::Skeid::Protocol::Ollama::Stream - Rewrites an OpenAI SSE stream as Ollama newline-delimited JSON

=head1 VERSION

version 0.003

=head1 DESCRIPTION

The counterpart to L<Langertha::Skeid::Protocol::Anthropic::Stream> for Ollama's C</api/chat>,
and a simpler job: Ollama streams newline-delimited JSON objects rather than SSE events, each
one a whole message with a C<done> flag. There is no prologue and no event framing — just one
line per delta and a final line that says it is over.

  my $stream = Langertha::Skeid::Protocol::Ollama::Stream->new(model => 'qwen3');
  $write->($stream->start);            # empty, by design
  $write->($stream->delta($chunk)) for @chunks;
  $write->($stream->finish);

The trailing line matters more than it looks: an Ollama client reads token counts from it and
treats the stream as unfinished without it.

C</api/generate> streams the same lines with the text under C<response> instead of
C<message>; C<< shape => 'generate' >> selects that, the default C<chat> is C</api/chat>.

  my $stream = Langertha::Skeid::Protocol::Ollama::Stream->new(model => 'qwen3', shape => 'generate');

=head2 new

  my $stream = Langertha::Skeid::Protocol::Ollama::Stream->new(model => $requested_model,
    shape => 'chat');

C<model> is named on every line until an upstream chunk names its own; C<shape> is C<chat>
(default) or C<generate>. Tool calls are only rendered for C<chat>.

=head2 content_type

C<application/x-ndjson>. Not SSE: relaying the upstream's C<text/event-stream> here would tell
an Ollama client to parse something it does not speak.

=head2 start

Nothing. Ollama has no prologue — the first line a client sees is the first delta. Present so
both stream translators answer the same three calls.

=head2 delta

One decoded OpenAI chunk becomes one Ollama line when it carries text or completed tool calls,
or nothing for a role-only chunk or the final usage-only one. OpenAI tool-call fragments are
fed to L<Langertha::Engine::OpenAIBase/parse_stream_chunk> with state private to this stream;
only its completed L<Langertha::ToolCall> objects are rendered, through C<to_ollama>. Usage and
finish reason are recorded for the closing line. A top-level OpenAI error object ends the stream
with L</error_event>; a parser rejection does the same with a generic message rather than
reflecting parser/provider details.

=head2 finish

The closing line: C<done> true, the reason, and the token counts an Ollama client reads its
statistics from. C<< done_reason => ... >>, C<< input_tokens => ... >> and
C<< output_tokens => ... >> override what the stream recorded. Idempotent. A pending tool call whose stream supplied no final chunk is an
L</error_event>, not a successful close; failures while building the closing line are contained
at the same boundary.

=head2 error_event

  my $bytes = $stream->error_event(500, 'Upstream error: ...');

Ends the stream with Ollama's error line, C<{"error":"<message>"}> -- how Ollama itself reports a
failure after the stream has opened, and what its clients check every line for. The status is
accepted for the same call shape as L<Langertha::Skeid::Protocol::Anthropic::Stream/error_event>
and is not on the wire: the HTTP status went out with the first line.

The stream is finished afterwards: C<delta> and C<finish> return nothing, so no C<done: true>
line follows and a client cannot mistake a failed stream for a complete one. Returns nothing if
the stream has already finished.

=head2 errored

True once L</error_event> ended the stream, so the proxy records the request as failed even
though the HTTP status was 200.

=head2 usage

  my ($input, $output, $content_bytes) = $stream->usage;

What the stream carried, for the usage event. C<content_bytes> counts UTF-8 bytes of the text
this translator wrote and becomes the event's C<content_bytes>, recorded beside the token counts
on every stream -- an observation, never an estimate of tokens.

=head1 SEE ALSO

L<Langertha::Skeid::Protocol::Ollama>, L<Langertha::Skeid::Protocol::Anthropic::Stream>

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
