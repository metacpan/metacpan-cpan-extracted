package Langertha::Knarr::Proxy::Anthropic;
our $VERSION = '0.007';
# ABSTRACT: Anthropic Messages API format proxy handler
use strict;
use warnings;
use JSON::MaybeXS qw( encode_json decode_json );
use Time::HiRes qw( time );
use Langertha::Knarr::Input;
use Langertha::Knarr::Output;


sub format_name { 'anthropic' }

sub passthrough_format { 'anthropic' }

sub streaming_content_type { 'text/event-stream' }

sub extract_model {
  my ($class, $body) = @_;
  return $body->{model} // 'default';
}

sub extract_stream {
  my ($class, $body) = @_;
  return $body->{stream} ? 1 : 0;
}

sub extract_messages {
  my ($class, $body) = @_;
  my @messages;
  if ($body->{system}) {
    push @messages, { role => 'system', content => $body->{system} };
  }
  push @messages, @{$body->{messages} // []};
  return \@messages;
}

sub extract_params {
  my ($class, $body) = @_;
  my %params;
  $params{max_tokens}   = $body->{max_tokens}   if defined $body->{max_tokens};
  $params{temperature}  = $body->{temperature}  if defined $body->{temperature};
  $params{top_p}        = $body->{top_p}        if defined $body->{top_p};
  $params{stream}       = $body->{stream}       if defined $body->{stream};
  $params{tools}        = $body->{tools}        if defined $body->{tools};
  $params{tool_choice}  = $body->{tool_choice}  if defined $body->{tool_choice};
  return \%params;
}

sub prepare_engine_messages {
  my ($class, $engine, $messages, $params) = @_;
  return $messages unless $engine && $engine->isa('Langertha::Engine::OpenAIBase');

  my @out;
  for my $msg (@{$messages // []}) {
    next unless ref($msg) eq 'HASH';
    my $role = $msg->{role} // '';
    my $content = $msg->{content};

    if ($role eq 'system' || $role eq 'assistant' || $role eq 'user') {
      if (!ref($content)) {
        push @out, { role => $role, content => ($content // '') };
        next;
      }
    }

    if ($role eq 'assistant' && ref($content) eq 'ARRAY') {
      my @text;
      my @tool_calls;
      for my $block (@$content) {
        next unless ref($block) eq 'HASH';
        my $type = $block->{type} // '';
        if ($type eq 'text') {
          push @text, $block->{text} // '';
          next;
        }
        if ($type eq 'tool_use') {
          my $arguments = eval { encode_json($block->{input} // {}) };
          $arguments = '{}' if $@;
          push @tool_calls, {
            id       => ($block->{id} // ('call_' . int(rand(1000000)))),
            type     => 'function',
            function => {
              name      => ($block->{name} // 'tool'),
              arguments => $arguments,
            },
          };
        }
      }
      my %assistant = (
        role    => 'assistant',
        content => join('', @text),
      );
      $assistant{tool_calls} = \@tool_calls if @tool_calls;
      push @out, \%assistant;
      next;
    }

    if ($role eq 'user' && ref($content) eq 'ARRAY') {
      my @text;
      my @tool_msgs;
      for my $block (@$content) {
        next unless ref($block) eq 'HASH';
        my $type = $block->{type} // '';
        if ($type eq 'text') {
          push @text, $block->{text} // '';
          next;
        }
        if ($type eq 'tool_result') {
          my $tool_text = _anthropic_content_to_text($block->{content});
          push @tool_msgs, {
            role         => 'tool',
            tool_call_id => ($block->{tool_use_id} // ''),
            content      => $tool_text,
          };
        }
      }
      push @out, { role => 'user', content => join('', @text) } if @text;
      push @out, @tool_msgs if @tool_msgs;
      next;
    }

    # Fallback: keep message shape and stringify content if needed.
    push @out, {
      role    => $role || 'user',
      content => ref($content) ? _anthropic_content_to_text($content) : ($content // ''),
    };
  }

  return \@out;
}

sub prepare_engine_params {
  my ($class, $engine, $params, $messages) = @_;
  return $params unless $engine && $engine->isa('Langertha::Engine::OpenAIBase');
  my %p = %{$params || {}};

  if (ref($p{tools}) eq 'ARRAY') {
    my $canonical = Langertha::Knarr::Input->normalize_tools($p{tools});
    $p{tools} = Langertha::Knarr::Input->to_openai_tools($canonical);
  }

  if (defined $p{tool_choice}) {
    my $canonical_tc = Langertha::Knarr::Input->normalize_tool_choice($p{tool_choice});
    if ($canonical_tc) {
      $p{tool_choice} = Langertha::Knarr::Input->to_openai_tool_choice($canonical_tc);
    }
    if (!defined $p{tool_choice}) {
      delete $p{tool_choice};
    }
  }

  return \%p;
}

sub format_response {
  my ($class, $result, $model) = @_;
  my $content = "$result";
  my $id = 'msg-knarr-' . int(time * 1000);

  my %response = (
    id      => $id,
    type    => 'message',
    role    => 'assistant',
    model   => $model,
    content => [{
      type => 'text',
      text => $content,
    }],
    stop_reason => 'end_turn',
  );

  if (ref $result && $result->isa('Langertha::Response')) {
    if ($result->has_usage) {
      $response{usage} = {
        input_tokens  => $result->prompt_tokens,
        output_tokens => $result->completion_tokens,
      };
    }
    $response{model} = $result->model if $result->has_model;

    if ($result->has_raw) {
      my $raw = $result->raw;
      if (ref($raw) eq 'HASH') {
        my $msg = $raw->{choices}[0]{message};
        if (ref($msg) eq 'HASH' && ref($msg->{tool_calls}) eq 'ARRAY') {
          my $meta = Langertha::Knarr::Output->extract_from_raw($raw);
          my @blocks;
          push @blocks, { type => 'text', text => $meta->{text} }
            if defined($meta->{text}) && $meta->{text} ne '';
          push @blocks, @{Langertha::Knarr::Output->to_anthropic_tool_use_blocks($meta->{tool_calls})}
            if ref($meta->{tool_calls}) eq 'ARRAY' && @{$meta->{tool_calls}};

          if (@blocks) {
            $response{content} = \@blocks;
            $response{stop_reason} = (@blocks > 0 && grep { ($_->{type} // '') eq 'tool_use' } @blocks)
              ? 'tool_use'
              : 'end_turn';
          }
        } elsif (ref($raw->{content}) eq 'ARRAY' && @{$raw->{content}}) {
          $response{content} = $raw->{content};
          $response{stop_reason} = $raw->{stop_reason} if defined $raw->{stop_reason};
        }
      }
    }
  }

  if (ref($response{content}) eq 'ARRAY') {
    my @existing_tool_use = grep { ref($_) eq 'HASH' && (($_->{type} // '') eq 'tool_use') } @{$response{content}};
    if (!@existing_tool_use) {
      my @new_blocks;
      my @calls;
      for my $block (@{$response{content}}) {
        if (ref($block) eq 'HASH' && (($block->{type} // '') eq 'text')) {
          my ($clean, $extracted) = Langertha::Knarr::Output->parse_hermes_calls_from_text($block->{text} // '');
          push @calls, @$extracted if @$extracted;
          push @new_blocks, { type => 'text', text => $clean } if defined($clean) && length($clean);
        } else {
          push @new_blocks, $block;
        }
      }

      if (@calls) {
        push @new_blocks, @{Langertha::Knarr::Output->to_anthropic_tool_use_blocks(\@calls)};
        $response{content} = \@new_blocks;
        $response{stop_reason} = 'tool_use';
      }
    }
  }

  return \%response;
}

sub format_stream_chunk {
  my ($class, $chunk, $model) = @_;
  my @lines;

  if ($chunk->content ne '') {
    my %data = (
      type  => 'content_block_delta',
      index => 0,
      delta => {
        type => 'text_delta',
        text => $chunk->content,
      },
    );
    my $json = encode_json(\%data);
    push @lines, "event: content_block_delta\ndata: $json\n\n";
  }

  if ($chunk->is_final) {
    my %stop_data = (
      type  => 'message_delta',
      delta => { stop_reason => 'end_turn' },
    );
    if ($chunk->can('usage') && $chunk->usage) {
      $stop_data{usage} = {
        output_tokens => $chunk->usage->{output} // $chunk->usage->{completion_tokens} // 0,
      };
    }
    my $stop_json = encode_json(\%stop_data);
    push @lines, "event: message_delta\ndata: $stop_json\n\n";
  }

  return \@lines;
}

sub stream_end_marker { "event: message_stop\ndata: {}\n\n" }

sub format_error {
  my ($class, $message, $type) = @_;
  return {
    type  => 'error',
    error => {
      type    => $type // 'server_error',
      message => $message,
    },
  };
}

sub format_models_response {
  my ($class, $models) = @_;
  return {
    data    => [map {{
      id           => $_->{id},
      type         => 'model',
      display_name => $_->{id},
      created_at   => '2024-01-01T00:00:00Z',
    }} @$models],
    has_more => JSON::MaybeXS->false,
    first_id => $models->[0]{id},
    last_id  => $models->[-1]{id},
  };
}

sub _anthropic_content_to_text {
  my ($content) = @_;
  return '' unless defined $content;
  return $content unless ref($content);
  return '' unless ref($content) eq 'ARRAY';

  my @parts;
  for my $item (@$content) {
    next unless ref($item) eq 'HASH';
    my $type = $item->{type} // '';
    if ($type eq 'text') {
      push @parts, ($item->{text} // '');
      next;
    }
    if ($type eq 'tool_result') {
      my $inner = $item->{content};
      if (!ref($inner)) {
        push @parts, ($inner // '');
        next;
      }
      if (ref($inner) eq 'ARRAY') {
        for my $part (@$inner) {
          next unless ref($part) eq 'HASH';
          push @parts, ($part->{text} // '');
        }
      }
    }
  }

  return join('', @parts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Proxy::Anthropic - Anthropic Messages API format proxy handler

=head1 VERSION

version 0.007

=head1 DESCRIPTION

Handles the Anthropic Messages API format for L<Langertha::Knarr>.

Routes handled:

=over

=item * C<POST /v1/messages> — chat completions (streaming and non-streaming)

=back

The Anthropic format extracts an optional C<system> field from the request body
and prepends it to the messages list as a C<system> role message. Streaming
uses SSE with C<event: message_stop> as the end marker. Passthrough format name
is C<anthropic>, forwarding to C<https://api.anthropic.com> when passthrough
is enabled.

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr> — Main documentation

=item * L<Langertha::Knarr::Proxy::OpenAI> — OpenAI format handler

=item * L<Langertha::Knarr::Proxy::Ollama> — Ollama format handler

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
