package Langertha::Skeid::Protocol::Ollama;
our $VERSION = '0.003';
# ABSTRACT: Translate between the Ollama chat format and the upstream OpenAI call
use strict;
use warnings;
use Langertha::Skeid::Protocol;
use Langertha::ToolCall;


sub request_to_openai {
  my ($class, $body) = @_;
  my $options = ref($body->{options}) eq 'HASH' ? $body->{options} : {};

  return {
    model => ($body->{model} // ''),
    messages => _messages_to_openai($body->{messages}),
    (defined($options->{temperature}) ? (temperature => 0 + $options->{temperature}) : ()),
    (defined($options->{num_predict}) ? (max_tokens  => 0 + $options->{num_predict}) : ()),
    (defined($body->{tools}) ? (tools => $body->{tools}) : ()),
    (defined($body->{tool_choice}) ? (tool_choice => $body->{tool_choice}) : ()),
    _response_format($body->{format}),
  };
}

# Ollama's format -> OpenAI's response_format: "json" is any JSON object, a schema object is
# json_schema. Nothing else is a format (Ollama itself treats "" and null as none).
sub _response_format {
  my ($format) = @_;
  return (response_format => { type => 'json_object' })
    if defined($format) && !ref($format) && $format eq 'json';
  return (response_format => {
    type        => 'json_schema',
    json_schema => { name => 'ollama_format', schema => $format },
  }) if ref($format) eq 'HASH';
  return ();
}

# Assistant tool_calls: arguments object -> character JSON string, ids synthesized; tool
# messages: tool_name -> tool_call_id of the matching call of the preceding assistant turn.
sub _messages_to_openai {
  my ($messages) = @_;
  return [] unless ref($messages) eq 'ARRAY';

  my $next_id = 0;
  my @unanswered;   # [ id, name ] of the latest assistant turn's calls, not yet answered
  my @out;

  for my $msg (@$messages) {
    if (ref($msg) ne 'HASH') {
      push @out, $msg;
      next;
    }
    my $role = $msg->{role} // '';

    if ($role eq 'assistant' && ref($msg->{tool_calls}) eq 'ARRAY') {
      @unanswered = ();
      my @calls;
      for my $call (@{$msg->{tool_calls}}) {
        if (ref($call) ne 'HASH') {
          push @calls, $call;
          next;
        }
        my $function = ref($call->{function}) eq 'HASH' ? $call->{function} : {};
        my $args = $function->{arguments};
        my $id = (defined($call->{id}) && length($call->{id})) ? $call->{id} : 'call_skeid_' . $next_id++;
        push @calls, {
          %$call,
          id       => $id,
          type     => 'function',
          function => {
            %$function,
            arguments => (ref($args) ? Langertha::Skeid::Protocol::encode_json_text_safe($args)
                                     : ($args // '{}')),
          },
        };
        push @unanswered, [ $id, $function->{name} // '' ];
      }
      push @out, { %$msg, tool_calls => \@calls };
      next;
    }

    if ($role eq 'tool') {
      my %tool = %$msg;
      my $tool_name = delete $tool{tool_name};
      if (defined($tool{tool_call_id}) && length($tool{tool_call_id})) {
        @unanswered = grep { $_->[0] ne $tool{tool_call_id} } @unanswered;
      } elsif (@unanswered) {
        my ($pick) = grep { defined($tool_name) && $unanswered[$_][1] eq $tool_name } 0 .. $#unanswered;
        $pick //= 0;
        $tool{tool_call_id} = $unanswered[$pick][0];
        splice @unanswered, $pick, 1;
      }
      push @out, \%tool;
      next;
    }

    if ($role ne 'assistant' && ref($msg->{images}) eq 'ARRAY' && @{$msg->{images}}) {
      my %with_images = %$msg;
      my $images = delete $with_images{images};
      my $text = $with_images{content};
      $with_images{content} = [
        ((defined($text) && !ref($text) && length($text)) ? { type => 'text', text => "$text" } : ()),
        map { _image_part($_) } grep { defined($_) && !ref($_) && length($_) } @$images,
      ];
      push @out, \%with_images;
      next;
    }

    push @out, $msg;
  }

  return \@out;
}

# Ollama sends images as raw base64 without a type; the OpenAI upstream wants a URL. A client
# that already sends a data: URL keeps it.
sub _image_part {
  my ($image) = @_;
  return Langertha::Skeid::Protocol::image_url_part($image) if $image =~ /\Adata:/;
  return Langertha::Skeid::Protocol::image_url_part(undef, $image);
}


sub response_from_openai {
  my ($class, $res) = @_;
  my $choice = (ref($res->{choices}) eq 'ARRAY' ? $res->{choices}[0] : {}) || {};
  my $msg = $choice->{message} || {};
  my $text = ($msg->{content} // '');
  my $tool_calls = [];

  if (ref($msg->{tool_calls}) eq 'ARRAY') {
    my @calls = Langertha::ToolCall->extract('openai', $res || {});
    $tool_calls = [ map { $_->to_ollama } @calls ];
  } elsif (length($text)) {
    my ($clean, $calls) = Langertha::ToolCall->extract_hermes_from_text($text);
    if (@$calls) {
      $text = $clean;
      $tool_calls = [ map { $_->to_ollama } @$calls ];
    }
  }

  return {
    model      => ($res->{model} // ''),
    created_at => Langertha::Skeid::Protocol::iso8601_now(),
    message    => {
      role    => ($msg->{role} // 'assistant'),
      content => $text,
      (@$tool_calls ? (tool_calls => $tool_calls) : ()),
    },
    done       => \1,
    done_reason => ($choice->{finish_reason} // 'stop'),
    prompt_eval_count => 0 + (($res->{usage} || {})->{prompt_tokens} // 0),
    eval_count        => 0 + (($res->{usage} || {})->{completion_tokens} // 0),
  };
}


sub generate_request_to_openai {
  my ($class, $body) = @_;
  my $prompt = $body->{prompt};
  my @messages;
  push @messages, { role => 'system', content => "$body->{system}" }
    if defined($body->{system}) && !ref($body->{system}) && length($body->{system});
  push @messages, {
    role    => 'user',
    content => ((defined($prompt) && !ref($prompt)) ? "$prompt" : ''),
    (ref($body->{images}) eq 'ARRAY' ? (images => $body->{images}) : ()),
  };

  return $class->request_to_openai({
    (exists $body->{model}   ? (model   => $body->{model})   : ()),
    (exists $body->{options} ? (options => $body->{options}) : ()),
    (exists $body->{format}  ? (format  => $body->{format})  : ()),
    messages => \@messages,
  });
}


sub generate_response_from_openai {
  my ($class, $res) = @_;
  my $choice = (ref($res->{choices}) eq 'ARRAY' ? $res->{choices}[0] : {}) || {};
  my $msg = $choice->{message} || {};
  my $usage = $res->{usage} || {};

  return {
    model       => ($res->{model} // ''),
    created_at  => Langertha::Skeid::Protocol::iso8601_now(),
    response    => ($msg->{content} // ''),
    done        => \1,
    done_reason => ($choice->{finish_reason} // 'stop'),
    prompt_eval_count => 0 + ($usage->{prompt_tokens} // 0),
    eval_count        => 0 + ($usage->{completion_tokens} // 0),
  };
}


sub tags_from_models {
  my ($class, $models) = @_;
  my @models = map {
    +{
      name        => $_->{model},
      model       => $_->{model},
      modified_at => Langertha::Skeid::Protocol::iso8601_now(),
      size        => 0,
      digest      => '',
      details     => {
        family             => ($_->{engine} || 'openaibase'),
        parameter_size     => 'unknown',
        quantization_level => 'unknown',
      },
    }
  } @{$models || []};

  return { models => \@models };
}


sub manifest_endpoint {
  return {
    dialect      => 'ollama',
    path         => '',
    capabilities => [qw(
      chat streaming system_prompt
      tools_native tools_hermes
      temperature response_size
      image_input
      response_format_json_object response_format_json_schema
    )],
  };
}


sub error_body {
  my ($class, $message) = @_;
  return { error => '' . ($message // '') };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol::Ollama - Translate between the Ollama chat format and the upstream OpenAI call

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Serves C<POST /api/chat>, C<POST /api/generate> and C<GET /api/tags>. Ollama-specific field names — C<done_reason>,
C<prompt_eval_count>, C<eval_count> — live here and nowhere else in Skeid.

Ollama's messages are already OpenAI-shaped, so the request translation is small — but it is
not empty: generation settings arrive nested under C<options> with Ollama's own names.

Streaming is translated, not refused. C<stream: true> on this route — and an absent
C<stream> field, which Ollama defaults to true — is rewritten to an OpenAI stream with
C<stream_options.include_usage>; the response is re-emitted as Ollama's newline-delimited
JSON, one line per delta and a closing line that carries C<done>, C<done_reason>, and the
token counts an Ollama client reads from. C<done_reason> is the OpenAI C<finish_reason>
passed through verbatim — there is no translation to do. See
L<Langertha::Skeid::Protocol::Ollama::Stream> for the per-chunk rewrite and
F<t/31-stream-translation.t> for what the wire looks like end-to-end.

=head2 request_to_openai

  my $openai_body = Langertha::Skeid::Protocol::Ollama->request_to_openai($body);

Turns an Ollama chat request into the OpenAI chat-completions body Skeid forwards.
C<options.temperature> and C<options.num_predict> are lifted out of the nested hash to
C<temperature> and C<max_tokens>; C<tools> and C<tool_choice> pass through unchanged. No other
option is carried.

Tool-call history is made OpenAI-shaped: an assistant message's C<tool_calls> get their
C<arguments> object encoded as a JSON string and an id (C<call_skeid_N>) where they have none,
and a C<tool> message that names its call only by C<tool_name> gets the C<tool_call_id> of the
matching unanswered call of the preceding assistant turn (the first unanswered one when no name
matches).

C<format>, Ollama's structured output, becomes C<response_format>: C<"json"> is
C<< {type => 'json_object'} >>, a JSON schema object is
C<< {type => 'json_schema', json_schema => {name => 'ollama_format', schema => ...}} >> with the
schema as sent. No C<strict> is set -- Ollama's format has no such switch. An empty string,
C<null> or any other value is no format, and no C<response_format> is sent.

A user message's C<images>, raw base64 strings, become an OpenAI content array: the message
text as a C<text> part, then one C<image_url> part per image, each a C<data:> URL whose media
type is read from the image's magic bytes (PNG, JPEG, GIF, WebP; PNG otherwise, see
L<Langertha::Skeid::Protocol/image_media_type>). A message without images keeps its string
content.

=head2 response_from_openai

  my $ollama = Langertha::Skeid::Protocol::Ollama->response_from_openai($res);

Turns the upstream OpenAI response into an Ollama chat response. Tool calls come from
L<Langertha::ToolCall>, including Hermes-style calls recovered from plain text — when they are
recovered, the text they were embedded in is stripped from the message content.

Token counts are reported under Ollama's names; C<done> is always true because this path never
streams.

=head2 generate_request_to_openai

  my $openai_body = Langertha::Skeid::Protocol::Ollama->generate_request_to_openai($body);

Turns an Ollama C</api/generate> request into the same OpenAI chat-completions body
L</request_to_openai> builds for C</api/chat>, by way of a chat conversation: C<system>, when
given, becomes a system message, and C<prompt> with its C<images> becomes one user message --
so the images become C<image_url> parts exactly as a chat message's do. C<model>,
C<options> and C<format> are read as on C</api/chat>.

Everything else a generate request can carry is not forwarded: C<think> and
C<options.seed> (not carried on C</api/chat> either), and the fields that only mean something
to an Ollama server's own prompt handling -- C<suffix>, C<template>, C<raw>, C<context>,
C<keep_alive>.

=head2 generate_response_from_openai

  my $ollama = Langertha::Skeid::Protocol::Ollama->generate_response_from_openai($res);

Turns the upstream OpenAI response into an Ollama generate response: the answer text as
C<response>, C<done> true, C<done_reason> and the token counts under the same names as
L</response_from_openai>. The text is passed as the model wrote it -- generate has no tool
calls, so nothing is lifted out of it. Ollama's C<context> (its token ids for the next call)
and its timing durations are not reported; Skeid has neither.

=head2 tags_from_models

  my $tags = Langertha::Skeid::Protocol::Ollama->tags_from_models($skeid->list_models(api_key_id => $id));

Renders a model list (L<Langertha::Skeid/list_models>: hashes with C<model> and C<engine>) as an
Ollama C<< /api/tags >> answer, one entry per name, the same names C</v1/models> lists. C<family>
is the entry's C<engine>, C<openaibase> when it has none (an alias).

The fields Ollama clients expect but Skeid cannot know — size, digest, parameter size,
quantisation — are filled with empty or C<'unknown'> placeholders rather than invented, so a
client that displays them shows nothing instead of showing a lie.

=head2 manifest_endpoint

  my $spec = Langertha::Skeid::Protocol::Ollama->manifest_endpoint;
  # { dialect => 'ollama', path => '', capabilities => [ ... ] }

How this face appears in the provider manifest (skeid #29): C<ollama> at the public root, and
the capability flags L</request_to_openai> actually carries to the upstream -- messages
(a C<system> message included), C<tools>, C<options.temperature>, C<options.num_predict>
(response size), C<stream>, a message's C<images> (C<image_input>) and C<format> as
C<"json"> or a schema (C<response_format_json_object>, C<response_format_json_schema>). A
model is published here only with the capabilities declared for it that are in this list.

C</api/generate> needs no entry of its own: the C<ollama> dialect names the whole Ollama API at
this root, and the manifest's capabilities describe a chat call, which C</api/chat> is.

Not carried, so never claimed: C<options.seed> and C<think>.
C<tool_choice> is passed through when a client sends one, but the Ollama dialect has no such
field, so no C<tool_choice_*> flag is claimed.

=head2 error_body

  my $body = Langertha::Skeid::Protocol::Ollama->error_body("Model 'x' is not available for this key");

Ollama's error envelope, C<< { error => $message } >> -- the message as a plain string, not an
object: the Ollama clients decode C<error> as a string (the Go client's C<StatusError>) and fail
on anything else. Every error Skeid answers on C</api/*> is rendered from this, with the HTTP
status of the failure, and so is the mid-stream error line (see
L<Langertha::Skeid::Protocol::Ollama::Stream/error_event>) (skeid #47).

=head1 SEE ALSO

L<Langertha::Skeid::Protocol::Ollama::Stream>, L<Langertha::Skeid::Protocol>,
L<Langertha::Skeid::Proxy>

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
