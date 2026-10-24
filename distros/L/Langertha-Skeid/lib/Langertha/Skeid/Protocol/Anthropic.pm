package Langertha::Skeid::Protocol::Anthropic;
our $VERSION = '0.004';
# ABSTRACT: Translate between the Anthropic Messages format and the upstream OpenAI call
use strict;
use warnings;
use Langertha::Skeid::Protocol;
use Langertha::Skeid::Protocol::Refusal;
use Langertha::Tool;
use Langertha::ToolCall;
use Langertha::ToolChoice;

# What a tool message says when its tool_result held images only.
my $TOOL_IMAGES_MOVED = 'The tool result is the images in the next message.';


sub request_to_openai {
  my ($class, $body) = @_;
  my @messages;

  if (defined $body->{system}) {
    if (ref($body->{system}) eq 'ARRAY') {
      my $txt = join('', map { ref($_) eq 'HASH' ? ($_->{text} // '') : "$_" } @{$body->{system}});
      push @messages, { role => 'system', content => $txt } if length $txt;
    } else {
      push @messages, { role => 'system', content => "$body->{system}" } if length $body->{system};
    }
  }

  my $started;  # a message that is not a system message has been seen
  my @pending;  # reminders waiting for the next user message

  for my $m (@{$body->{messages} || []}) {
    next unless ref($m) eq 'HASH';
    my $role = $m->{role} // 'user';
    my $content = $m->{content};

    # A system message is never forwarded where it stands: a chat template wants its system
    # message first. Before the first turn it is part of the one leading system message; after
    # it, text of a user turn -- not of the leading one, whose prefix has to stay the same from
    # turn to turn for the node's prefix cache.
    if ($role eq 'system') {
      my $txt = _system_text($content);
      next unless length $txt;
      if (!$started) {
        if (@messages) {
          $messages[0]{content} = join("\n\n", grep { length } $messages[0]{content}, $txt);
        } else {
          push @messages, { role => 'system', content => $txt };
        }
        next;
      }
      my $reminder = "<system-reminder>\n" . $txt . "\n</system-reminder>";
      if (@messages && $messages[-1]{role} eq 'user') {
        _add_reminder($messages[-1], $reminder);
      } else {
        push @pending, $reminder;
      }
      next;
    }
    $started = 1;

    if (!ref($content)) {
      _push_message(\@messages, \@pending, { role => $role, content => (defined($content) ? "$content" : '') });
      next;
    }

    if (ref($content) eq 'ARRAY') {
      my @text;
      my @parts;        # text and image parts in client order, used once an image appears
      my $has_image;
      my @tool_calls;
      my @tool_images;  # image parts lifted out of this message's tool_result blocks

      for my $block (@$content) {
        next unless ref($block) eq 'HASH';
        my $type = $block->{type} // '';

        if ($type eq 'text') {
          push @text, ($block->{text} // '');
          push @parts, { type => 'text', text => ($block->{text} // '') };
          next;
        }

        if ($type eq 'image' && $role ne 'assistant') {
          push @parts, _image_part($block);
          $has_image = 1;
          next;
        }

        if ($type eq 'tool_use') {
          my $id = $block->{id} // ('toolu_' . int(rand(1_000_000)));
          my $name = $block->{name} // 'tool';
          my $args = Langertha::Skeid::Protocol::encode_json_text_safe($block->{input} || {});
          push @tool_calls, {
            id => $id,
            type => 'function',
            function => {
              name => $name,
              arguments => $args,
            },
          };
          next;
        }

        if ($type eq 'tool_result') {
          my $tcid = $block->{tool_use_id} // $block->{id} // '';
          my $val = $block->{content};
          # An OpenAI tool message carries no image parts. Its images move to the one user
          # message that follows this run of tool messages; the tool message keeps the rest.
          if (ref($val) eq 'ARRAY' && grep { _is_image_block($_) } @$val) {
            push @tool_images, { type => 'text', text => "Images from tool result $tcid:" },
              map { _image_part($_) } grep { _is_image_block($_) } @$val;
            my @rest = grep { !_is_image_block($_) } @$val;
            $val = @rest ? \@rest : $TOOL_IMAGES_MOVED;
          }
          my $txt = ref($val) ? Langertha::Skeid::Protocol::encode_json_text_safe($val) : (defined($val) ? "$val" : '');
          _push_message(\@messages, \@pending, {
            role => 'tool',
            tool_call_id => $tcid,
            content => $txt,
          });
          next;
        }
      }

      my $text = join('', @text);
      if ($role eq 'assistant') {
        my %msg = (role => 'assistant');
        $msg{content} = $text if length $text;
        $msg{tool_calls} = \@tool_calls if @tool_calls;
        $msg{content} = '' if !exists($msg{content}) && !exists($msg{tool_calls});
        _push_message(\@messages, \@pending, \%msg);
      } else {
        # The tool-result images and the client's own content of this one Anthropic message
        # are one user message (content arrays concatenated); never merged across messages.
        my @client = $has_image ? @parts : length($text) ? ({ type => 'text', text => $text }) : ();
        if (@tool_images) {
          _push_message(\@messages, \@pending, { role => 'user', content => [ @tool_images, @client ] });
        } elsif ($has_image) {
          _push_message(\@messages, \@pending, { role => $role, content => \@parts });
        } elsif (length $text) {
          _push_message(\@messages, \@pending, { role => $role, content => $text });
        }
      }
    }
  }

  # Reminders no user message came for end the conversation as one.
  push @messages, { role => 'user', content => join("\n\n", @pending) } if @pending;

  my %out = (
    model    => ($body->{model} // ''),
    messages => \@messages,
    (defined($body->{max_tokens}) ? (max_tokens => 0 + $body->{max_tokens}) : ()),
    (defined($body->{temperature}) ? (temperature => 0 + $body->{temperature}) : ()),
    (defined($body->{top_p}) ? (top_p => 0 + $body->{top_p}) : ()),
  );

  if (ref($body->{tools}) eq 'ARRAY') {
    # Skeid forwards one OpenAI chat call (ADR 0001); a provider built-in has no function shape
    # there and nothing downstream would run it. from_list croaks on one (Langertha k210), so
    # ask the non-croaking classifier first and refuse with a message the client can act on.
    # Non-hash entries are left to from_list, which skips them.
    my $i = -1;
    for my $tool (@{$body->{tools}}) {
      $i++;
      next unless ref($tool) eq 'HASH';
      my ($category, undef, $label) = Langertha::Tool->classify($tool, 'anthropic');
      next if $category eq 'function';
      Langertha::Skeid::Protocol::Refusal->refuse("tools[$i]: tool type '" . ($label // '') . "' ($category) is not supported: "
        . "skeid does not forward provider built-in tools, only function tools");
    }
    my $tools = Langertha::Tool->from_list($body->{tools});
    $out{tools} = [ map { $_->to_openai } @$tools ];
  }

  if (defined $body->{tool_choice}) {
    my $tc = Langertha::ToolChoice->from_hash($body->{tool_choice});
    if ($tc) {
      my $oai_tc = $tc->to_openai;
      $out{tool_choice} = $oai_tc if defined $oai_tc;
    }
  }

  return \%out;
}

# The text of a system message: a string, or the text blocks of a block list joined like the
# top-level system.
sub _system_text {
  my ($content) = @_;
  return defined($content) ? "$content" : '' unless ref($content);
  return '' unless ref($content) eq 'ARRAY';
  return join('', map { ref($_) eq 'HASH' ? ($_->{text} // '') : "$_" } @$content);
}

# Adds a reminder to a user message, behind what it says or in front of it: text joined by a
# blank line, or a text part of its own when the content is an array of parts.
sub _add_reminder {
  my ($msg, $reminder, $in_front) = @_;
  if (ref($msg->{content}) eq 'ARRAY') {
    my $part = { type => 'text', text => $reminder };
    $in_front ? unshift(@{$msg->{content}}, $part) : push(@{$msg->{content}}, $part);
    return;
  }
  my $text = $msg->{content} // '';
  $msg->{content} = join("\n\n", grep { length } $in_front ? ($reminder, $text) : ($text, $reminder));
}

# Adds a translated message. Waiting reminders go in front of a user message's own content; a
# tool message leaves them waiting, so nothing comes between an assistant's tool calls and
# their answers; anything else gets them as a user message in front of it.
sub _push_message {
  my ($messages, $pending, $msg) = @_;
  if (@$pending && $msg->{role} ne 'tool') {
    my $reminders = join("\n\n", splice(@$pending));
    if ($msg->{role} eq 'user') {
      _add_reminder($msg, $reminders, 1);
    } else {
      push @$messages, { role => 'user', content => $reminders };
    }
  }
  push @$messages, $msg;
}

sub _is_image_block {
  my ($block) = @_;
  return ref($block) eq 'HASH' && ($block->{type} // '') eq 'image';
}

# An Anthropic image block as an OpenAI image_url part: a base64 source becomes a data URL
# with its media_type, a url source is passed as the URL. Any other source (a Files API
# file_id) has no OpenAI-chat equivalent and is refused like a built-in tool.
sub _image_part {
  my ($block) = @_;
  my $source = ref($block->{source}) eq 'HASH' ? $block->{source} : {};
  my $kind = $source->{type} // '';
  return Langertha::Skeid::Protocol::image_url_part(undef, $source->{data}, $source->{media_type})
    if $kind eq 'base64' && defined($source->{data}) && !ref($source->{data});
  return Langertha::Skeid::Protocol::image_url_part($source->{url})
    if $kind eq 'url' && defined($source->{url}) && !ref($source->{url}) && length($source->{url});
  Langertha::Skeid::Protocol::Refusal->refuse("image source type '$kind' is not supported: skeid forwards base64 and url images only");
}


sub response_from_openai {
  my ($class, $res, $default_model) = @_;

  my $choice = (ref($res->{choices}) eq 'ARRAY' ? $res->{choices}[0] : {}) || {};
  my $msg = $choice->{message} || {};
  my $text = $msg->{content} // '';
  my @calls = Langertha::ToolCall->extract('openai', $res || {});

  if (!@calls && length($text)) {
    my ($clean, $extracted) = Langertha::ToolCall->extract_hermes_from_text($text);
    $text = $clean;
    @calls = @$extracted;
  }

  my @content;
  push @content, { type => 'text', text => $text } if length $text;
  my $i = 0;
  for my $call (@calls) {
    $i++;
    push @content, $call->to_anthropic_block( fallback_id => "toolu_skeid_$i" );
  }

  # gpt-oss on vLLM-style servers (seen live on AKI.IO) answers a tool call with finish_reason
  # 'stop'. The reply carries tool_use blocks, and an Anthropic client only runs them when
  # stop_reason says tool_use, so tool calls present wins over 'stop' -- the rule core applies
  # to Response.finish_reason (core k248). 'length' and the rest keep their mapping.
  my $fr = $choice->{finish_reason} // 'stop';
  my $stop_reason = ($fr eq 'tool_calls' || (@calls && $fr eq 'stop')) ? 'tool_use'
                  : $fr eq 'length'     ? 'max_tokens'
                  : 'end_turn';

  return {
    id           => ($res->{id} ? ('msg_' . $res->{id}) : ('msg_' . int(time * 1000))),
    type         => 'message',
    role         => 'assistant',
    model        => ($res->{model} // $default_model),
    content      => \@content,
    stop_reason  => $stop_reason,
    stop_sequence => undef,
    usage => {
      input_tokens  => 0 + (($res->{usage} || {})->{prompt_tokens} // 0),
      output_tokens => 0 + (($res->{usage} || {})->{completion_tokens} // 0),
    },
  };
}


my %ERROR_TYPE_FOR_STATUS = (
  400 => 'invalid_request_error',
  401 => 'authentication_error',
  402 => 'billing_error',
  403 => 'permission_error',
  404 => 'not_found_error',
  409 => 'conflict_error',
  413 => 'request_too_large',
  429 => 'rate_limit_error',
  500 => 'api_error',
  504 => 'timeout_error',
  529 => 'overloaded_error',
);

my %KNOWN_ERROR_TYPE = map { $_ => 1 } values %ERROR_TYPE_FOR_STATUS;

sub error_type_for_status {
  my ($class, $status) = @_;
  $status = 0 + ($status // 500);
  return $ERROR_TYPE_FOR_STATUS{$status} // ($status >= 500 ? 'api_error' : 'invalid_request_error');
}


sub error_body {
  my ($class, $status, $message, $type) = @_;
  $type = $class->error_type_for_status($status)
    unless defined($type) && $KNOWN_ERROR_TYPE{$type};
  return {
    type  => 'error',
    error => {
      type    => $type,
      message => ($message // ''),
    },
  };
}


sub manifest_endpoint {
  return {
    dialect      => 'anthropic-compat',
    path         => '',
    capabilities => [qw(
      chat streaming system_prompt
      tools_native tools_hermes
      tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
      temperature response_size
      image_input
    )],
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol::Anthropic - Translate between the Anthropic Messages format and the upstream OpenAI call

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Serves C<POST /v1/messages>. Anthropic-specific field names live here and nowhere else in
Skeid.

Tool shapes are not translated by hand — L<Langertha::Tool>, L<Langertha::ToolCall> and
L<Langertha::ToolChoice> own what a tool looks like in each dialect, including recovering
Hermes-style C<< <tool_call> >> blocks from plain text. A format Langertha cannot express is a
Langertha ticket, not a parser here.

Streaming is translated, not refused: C<stream: true> is rewritten to an OpenAI stream with
C<stream_options.include_usage> set, so the token counts an Anthropic client reads from
C<message_delta> actually arrive; the response is re-emitted at the client edge as the
Anthropic event protocol — C<message_start>, C<content_block_start>,
C<content_block_delta>, C<content_block_stop>, C<message_delta>, C<message_stop>. The same
single upstream call (ADR 0001) carries the load; the format-specific framing is the only
thing that changes between the wire Skeid speaks and the wire the client reads. See
L<Langertha::Skeid::Protocol::Anthropic::Stream> for the per-chunk rewrite and the usage
accumulator, and F<t/31-stream-translation.t> for what the wire looks like end-to-end.

C<< finish_reason >> mapping is the same as the non-streaming path: C<tool_calls> becomes
C<tool_use>, C<length> becomes C<max_tokens>, anything else becomes C<end_turn> -- and a reply
that carries tool calls but finished with C<stop> reports C<tool_use>. Tool calls in a stream
are re-emitted as C<tool_use> content blocks with C<input_json_delta> deltas, one block per
parallel call.

=head2 request_to_openai

  my $openai_body = Langertha::Skeid::Protocol::Anthropic->request_to_openai($body);

Turns an Anthropic Messages request into the OpenAI chat-completions body Skeid forwards:
C<model>, the messages, and C<max_tokens>, C<temperature> and C<top_p> when given. Nothing else
of the request is carried -- C<stop_sequences>, C<metadata>, C<thinking> and C<cache_control>
included; C<stream> is set by the proxy.

C<system> (a string or a block array) becomes a leading system message, and it is the only
system message the upstream gets: a chat template wants it first (Qwen3 on vLLM answers
C<System message must be at the beginning.>) or wants strictly alternating turns. A message
with C<role: system> inside C<messages> -- string or block array, its text blocks joined -- is
therefore never forwarded where it stands, and one without text is dropped:

=over 4

=item *

Before the first message of another role it is part of that leading system message, after the
top-level C<system>, the pieces separated by a blank line.

=item *

After it, its text is wrapped as C<< <system-reminder>\n...\n</system-reminder> >> -- always,
whatever the text holds -- and becomes text of a user turn of the translated conversation. It
is appended to the last message when that is a user message. Otherwise it waits, and goes in
front of the next user message; when an assistant message comes first, or the conversation
ends, the waiting reminders are a user message of their own at that point. A tool message
neither takes a reminder nor ends the wait, so nothing comes between an assistant's
C<tool_calls> and their answers. Reminders that meet keep the client's order, a blank line
between them. Joined to a text content it is a blank line apart from the user's text; a content
array (image parts) gets it as a text part of its own.

=back

A later system message is never moved into the leading one: that would change the start of the
prompt on every turn and with it the node's prefix cache. A request without a system message in
C<messages> is translated exactly as before. An empty top-level C<system> (C<"">) is dropped
like an empty block array: no empty system message goes upstream (k101).

Content block arrays
fold to text, unless a user message carries an C<image> block: then its text and image blocks
become an OpenAI content array in the order the client sent them, text as C<text> parts and
each image as an C<image_url> part -- a C<base64> source as a C<data:> URL with its
C<media_type>, a C<url> source as that URL. An image source of any other type (a Files API
C<file_id>) makes it die, answered as a C<400>. C<tool_use> blocks become C<tool_calls> on the assistant message; C<tool_result>
blocks become their own C<role => 'tool'> message carrying C<tool_call_id>, which is why a
single Anthropic message can expand into several OpenAI ones. A structured C<tool_result>
content is sent as its JSON text.

An OpenAI tool message cannot carry images, so the C<image> blocks of a C<tool_result> are
lifted out of it: its tool message keeps the other blocks as JSON text (or, when there are none,
a sentence saying the result is the images in the next message), and right after the run of
tool messages one user message follows with the images of every C<tool_result> in that
Anthropic message, each result's images as C<image_url> parts after a text part
C<Images from tool result E<lt>tool_use_idE<gt>:>. The user message goes after all the tool
messages because an OpenAI conversation wants the answers to an assistant's tool calls
directly after it. The client's own text and images in the same Anthropic message are parts of that same
user message, after the images; messages are never merged across Anthropic message
boundaries, so the prompt of earlier turns does not change.

Only function tools are translated. A provider built-in in C<tools> (C<web_search_20250305>,
C<bash_20250124>, C<text_editor_*>, C<computer_*>, C<mcp_toolset>, ...) or a definition
L<Langertha::Tool/classify> does not recognise, and an image source that is neither base64 nor a
url, make it throw a L<Langertha::Skeid::Protocol::Refusal> with a one-line message naming the
tool type and its category; the proxy answers that as a C<400 invalid_request_error> carrying
the message. Any other failure to translate the request is answered as a C<400> with the fixed
text C<Invalid request>: that exception's text can quote the request, so it is neither sent
nor logged.

=head2 response_from_openai

  my $anthropic = Langertha::Skeid::Protocol::Anthropic->response_from_openai($res, $model);

Turns the upstream OpenAI response into an Anthropic message. Content becomes a C<text> block,
tool calls become C<tool_use> blocks, and C<finish_reason> maps C<tool_calls> to C<tool_use>,
C<length> to C<max_tokens>, everything else to C<end_turn> -- except that a reply carrying tool
calls with C<stop> (gpt-oss on vLLM-style servers) reports C<tool_use>.

C<$model> is the model the client asked for, used only when the upstream omits it.

=head2 error_type_for_status

  my $type = Langertha::Skeid::Protocol::Anthropic->error_type_for_status(429);  # rate_limit_error

The C<error.type> an Anthropic client expects for an HTTP status, from Anthropic's Messages API
error reference: 400 C<invalid_request_error>, 401 C<authentication_error>, 402
C<billing_error>, 403 C<permission_error>, 404 C<not_found_error>, 409 C<conflict_error>, 413
C<request_too_large>, 429 C<rate_limit_error>, 500 C<api_error>, 504 C<timeout_error>, 529
C<overloaded_error>. A
status the reference does not list falls back by class: any other 5xx (Skeid's own 502 and
503) is C<api_error>, any other 4xx C<invalid_request_error>. The SDKs choose their exception
class from the HTTP status first, so the fallback only decides the type string.

=head2 error_body

  my $body = Langertha::Skeid::Protocol::Anthropic->error_body(429, 'Timed out waiting ...');
  my $body = Langertha::Skeid::Protocol::Anthropic->error_body(500, $message, $upstream_type);

The Anthropic error envelope, C<< { type => 'error', error => { type, message } } >>, with the
type taken from L</error_type_for_status>. An optional third argument, an error type the
upstream reported, wins when it is one of the types in that table -- an OpenAI-dialect upstream
often spells a rate limit or a bad request the same way -- and is ignored otherwise, so a
foreign type such as C<server_error> never reaches an Anthropic client. Every error Skeid answers on C</v1/messages> is
rendered from this -- also the C<data> of a mid-stream C<event: error> frame (see
L<Langertha::Skeid::Protocol::Anthropic::Stream/error_event>) -- so an Anthropic SDK can parse
it and raise the matching exception.

=head2 manifest_endpoint

  my $spec = Langertha::Skeid::Protocol::Anthropic->manifest_endpoint;
  # { dialect => 'anthropic-compat', path => '', capabilities => [ ... ] }

How this face appears in the provider manifest (skeid #29): C<anthropic-compat> at the public
root, and the capability flags L</request_to_openai> actually carries to the upstream --
C<system>, function C<tools>, C<tool_choice> (auto, any, none, a named tool), C<max_tokens>,
C<temperature>, C<stream> and C<image> blocks (C<image_input>). A model is published here
only with the capabilities declared for it that are in this list.

It is C<anthropic-compat>, not C<anthropic>: C<output_config.format> is not translated, so a
client takes the synthetic-tool path for structured output, which is what that dialect tells
it. Not carried, so never claimed: structured output, C<thinking> (reasoning),
C<cache_control> (prompt cache), and C<disable_parallel_tool_use>.

=head1 SEE ALSO

L<Langertha::Skeid::Protocol::Anthropic::Stream>, L<Langertha::Skeid::Protocol>,
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
