package Langertha::Role::Chat;
# ABSTRACT: Role for APIs with normal chat functionality
our $VERSION = '0.500';
use Moose::Role;
use Future::AsyncAwait;
use Carp qw( croak );
use JSON::MaybeXS;
use Log::Any qw( $log );
use Scalar::Util qw( blessed );
use Langertha::ToolChoice;
use Langertha::Tool;
use Langertha::Role::Capabilities;

requires qw(
  chat_request
  chat_response
);


sub content_format { 'openai' }


with 'Langertha::Role::Capabilities';


has chat_model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy_build => 1,
);
sub _build_chat_model {
  my ( $self ) = @_;
  croak "".(ref $self)." can't handle models!" unless $self->does('Langertha::Role::Models');
  return $self->default_chat_model if $self->can('default_chat_model');
  return $self->model;
}


sub chat {
  my ( $self, @messages ) = @_;
  return $self->chat_request($self->chat_messages(@messages));
}


sub chat_messages {
  my ( $self, @messages ) = @_;
  my @out;
  push @out, { role => 'system', content => $self->system_prompt }
    if $self->has_system_prompt;
  for my $m (@messages) {
    my $msg = ref $m ? $m : { role => 'user', content => $m };
    push @out, $self->_normalize_content_blocks($msg);
  }
  return \@out;
}

sub _normalize_content_blocks {
  my ( $self, $msg ) = @_;
  my $content = $msg->{content};
  return $msg unless ref $content eq 'ARRAY';

  my $needs_convert = 0;
  for my $b (@$content) {
    if ( blessed($b) && $b->does('Langertha::Content') ) {
      $needs_convert = 1;
      last;
    }
  }
  return $msg unless $needs_convert;

  my $fmt    = $self->content_format;
  my $method = "to_$fmt";

  my @blocks = map {
    if ( blessed($_) && $_->does('Langertha::Content') ) {
      $_->$method;
    }
    elsif ( !ref $_ ) {
      $fmt eq 'gemini'
        ? { text => $_ }
        : { type => 'text', text => $_ };
    }
    else {
      $_;
    }
  } @$content;

  if ( $fmt eq 'gemini' ) {
    my $role = ( $msg->{role} // 'user' ) eq 'assistant' ? 'model' : ( $msg->{role} // 'user' );
    return { role => $role, parts => \@blocks };
  }
  return { %$msg, content => \@blocks };
}


sub simple_chat {
  my ( $self, @messages ) = @_;
  $log->debugf("[%s] simple_chat with %d message(s), model=%s",
    ref $self, scalar @messages, $self->chat_model // 'default');
  my $request = $self->chat(@messages);
  my $response = $self->user_agent->request($request);
  my $result = $request->response_call->($response);
  if ($self->can('has_rate_limit') && $self->has_rate_limit && ref $result && $result->isa('Langertha::Response')) {
    $result = $result->clone_with(rate_limit => $self->rate_limit);
  }
  return $result;
}


sub chat_stream {
  my ( $self, @messages ) = @_;
  croak "".(ref $self)." does not support streaming"
    unless $self->can('chat_stream_request');
  return $self->chat_stream_request($self->chat_messages(@messages));
}


sub simple_chat_stream {
  my ( $self, $callback, @messages ) = @_;
  croak "simple_chat_stream requires a callback as first argument"
    unless ref $callback eq 'CODE';
  $log->debugf("[%s] simple_chat_stream (%s format)", ref $self, $self->stream_format);
  my $request = $self->chat_stream(@messages);
  my $chunks = $self->execute_streaming_request($request, $callback);
  $log->debugf("[%s] Stream completed: %d chunks", ref $self, scalar @$chunks);
  return join('', map { $_->content } @$chunks);
}


sub simple_chat_stream_iterator {
  my ( $self, @messages ) = @_;
  require Langertha::Stream;
  my $request = $self->chat_stream(@messages);
  my $chunks = $self->execute_streaming_request($request);
  return Langertha::Stream->new(chunks => $chunks);
}


# Future-based async methods

has _async_loop => (
  is => 'ro',
  lazy_build => 1,
);

sub _build__async_loop {
  require IO::Async::Loop;
  return IO::Async::Loop->new;
}

has _async_http => (
  is => 'ro',
  lazy_build => 1,
);

sub _build__async_http {
  my ($self) = @_;
  require Net::Async::HTTP;
  my $http = Net::Async::HTTP->new;
  $self->_async_loop->add($http);
  return $http;
}

async sub simple_chat_f {
  my ( $self, @messages ) = @_;
  $log->debugf("[%s] simple_chat_f with %d message(s)", ref $self, scalar @messages);
  return await $self->chat_f( messages => \@messages );
}

async sub chat_f {
  my ( $self, %opts ) = @_;

  my $messages = delete $opts{messages} // [];
  my @messages = ref $messages eq 'ARRAY' ? @$messages : ($messages);

  # Auto-fallback: forced named tool on an engine that cannot do
  # native named-tool-forcing but supports json_schema response_format.
  # Rewrite tools+tool_choice into a response_format and remember the
  # tool name so we can synthesize a tool_calls entry afterwards.
  my $synth_tool_name;
  if ( exists $opts{tool_choice}
    && exists $opts{tools}
    && !$self->supports('tool_choice_named')
    && $self->supports('response_format_json_schema')
  ) {
    my $tc = Langertha::ToolChoice->from_hash( $opts{tool_choice} );
    if ( $tc && $tc->type eq 'tool' && defined $tc->name && length $tc->name ) {
      my $name = $tc->name;
      my ($tool) =
        grep { defined $_ && $_->name eq $name }
        map  { Langertha::Tool->from_hash($_) }
        @{ $opts{tools} };
      if ($tool) {
        delete $opts{tools};
        delete $opts{tool_choice};
        $opts{response_format} = {
          type        => 'json_schema',
          json_schema => {
            %{ $tool->to_json_schema },
            strict => JSON->true,
          },
        };
        $synth_tool_name = $name;
        $log->debugf("[%s] forced-tool fallback: tool '%s' rerouted via response_format",
          ref $self, $name);
      }
    }
  }

  my $request = $self->chat_request( $self->chat_messages(@messages), %opts );

  my $response = await $self->_async_http->do_request( request => $request );

  unless ($response->is_success) {
    die "".(ref $self)." request failed: ".$response->status_line;
  }

  my $result = $request->response_call->($response);

  if ( $synth_tool_name && blessed($result) && $result->isa('Langertha::Response') ) {
    my $args = $self->decode_loose_json( $result->content );
    if ( defined $args ) {
      $result = $result->clone_with(
        tool_calls => [{
          name      => $synth_tool_name,
          arguments => $args,
          synthetic => 1,
        }],
      );
    }
  }

  if ( $self->can('has_rate_limit') && $self->has_rate_limit
       && ref $result && $result->isa('Langertha::Response') ) {
    $result = $result->clone_with( rate_limit => $self->rate_limit );
  }
  return $result;
}



sub simple_chat_stream_f {
  my ($self, @messages) = @_;
  return $self->simple_chat_stream_realtime_f(undef, @messages);
}


async sub simple_chat_stream_realtime_f {
  my ($self, $chunk_callback, @messages) = @_;

  croak "".(ref $self)." does not support streaming"
    unless $self->can('chat_stream_request');

  my $request = $self->chat_stream_request($self->chat_messages(@messages));
  my @all_chunks;
  my $buffer = '';
  my $format = $self->stream_format;
  my $response_status;

  await $self->_async_http->do_request(
    request => $request,
    on_header => sub {
      my ($response) = @_;
      $response_status = $response;

      # Return a callback that handles each body chunk
      return sub {
        my ($data) = @_;
        return unless defined $data;  # undef signals end of body

        $buffer .= $data;
        my $chunks = $self->_process_stream_buffer(\$buffer, $format);
        for my $chunk (@$chunks) {
          push @all_chunks, $chunk;
          $chunk_callback->($chunk) if $chunk_callback;
        }
      };
    },
  );

  unless ($response_status->is_success) {
    die "".(ref $self)." streaming request failed: ".$response_status->status_line;
  }

  # Process remaining buffer
  if ($buffer ne '') {
    my $chunks = $self->_process_stream_buffer(\$buffer, $format, 1);
    for my $chunk (@$chunks) {
      push @all_chunks, $chunk;
      $chunk_callback->($chunk) if $chunk_callback;
    }
  }

  my $content = join('', map { $_->content } @all_chunks);
  return ($content, \@all_chunks);
}

sub aggregate_tool_calls {
  my ( $self, $chunks ) = @_;
  return [] unless ref($chunks) eq 'ARRAY';
  my @tcs;
  for my $c (@$chunks) {
    next unless eval { $c->has_tool_calls };
    push @tcs, @{ $c->tool_calls };
  }
  return \@tcs;
}



sub _process_stream_buffer {
  my ($self, $buffer_ref, $format, $final) = @_;

  my @chunks;

  if ($format eq 'sse') {
    while ($$buffer_ref =~ s/^(.*?)\n\n//s) {
      my $block = $1;
      for my $line (split /\n/, $block) {
        next if $line eq '' || $line =~ /^:/;
        if ($line =~ /^data:\s*(.*)$/) {
          my $json_data = $1;
          next if $json_data eq '[DONE]' || $json_data eq '';
          my $parsed = $self->json->decode($json_data);
          my $chunk = $self->parse_stream_chunk($parsed);
          push @chunks, $chunk if $chunk;
        }
      }
    }
  } elsif ($format eq 'ndjson') {
    while ($$buffer_ref =~ s/^(.*?)\n//s) {
      my $line = $1;
      next if $line eq '';
      my $parsed = $self->json->decode($line);
      my $chunk = $self->parse_stream_chunk($parsed);
      push @chunks, $chunk if $chunk;
    }
  }

  return \@chunks;
}

with 'Langertha::Role::ThinkTag', 'Langertha::Role::Langfuse';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Chat - Role for APIs with normal chat functionality

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    # Synchronous chat
    my $response = $engine->simple_chat('Hello, how are you?');

    # Streaming with callback
    $engine->simple_chat_stream(sub {
        my ($chunk) = @_;
        print $chunk->content;
    }, 'Tell me a story');

    # Streaming with iterator
    my $stream = $engine->simple_chat_stream_iterator('Tell me a story');
    while (my $chunk = $stream->next) {
        print $chunk->content;
    }

    # Async with Future (traditional style)
    my $future = $engine->simple_chat_f('Hello');
    my $response = $future->get;

    # Async with Future::AsyncAwait (recommended)
    use Future::AsyncAwait;

    async sub chat_example {
        my ($engine) = @_;
        my $response = await $engine->simple_chat_f('Hello');
        say $response;
    }

    # Async streaming with real-time callback
    async sub stream_example {
        my ($engine) = @_;
        my ($content, $chunks) = await $engine->simple_chat_stream_realtime_f(
            sub { print shift->content },
            'Tell me a story'
        );
        say "\nTotal chunks: ", scalar @$chunks;
    }

=head1 DESCRIPTION

This role provides chat functionality for LLM engines. It includes both
synchronous and asynchronous (L<Future>-based) methods for chat and streaming.

The Future-based C<_f> methods are implemented using L<Future::AsyncAwait> and
L<Net::Async::HTTP>. These modules are loaded lazily only when you call a C<_f>
method, so synchronous-only usage does not require them.

=head2 chat_model

The model name used for chat requests. Lazily defaults to C<default_chat_model>
if the engine provides it, otherwise falls back to the general C<model>
attribute from L<Langertha::Role::Models>.

=head2 chat

    my $request = $engine->chat(@messages);

Builds and returns a chat HTTP request object. Messages may be plain strings
(treated as C<user> role) or HashRefs with C<role> and C<content> keys. A
system prompt from L<Langertha::Role::SystemPrompt> is prepended automatically.

=head2 chat_messages

    my $messages = $engine->chat_messages(@messages);

Normalises C<@messages> into the canonical ArrayRef-of-HashRef format expected
by C<chat_request>. Plain strings become C<{ role =E<gt> 'user', content =E<gt>
$string }>. If the engine has a C<system_prompt> set it is prepended as a
C<system> message.

=head2 simple_chat

    my $response = $engine->simple_chat(@messages);
    my $response = $engine->simple_chat('Hello, how are you?');

Sends a synchronous chat request and returns the response text. Blocks until
the request completes.

=head2 chat_stream

    my $request = $engine->chat_stream(@messages);

Builds and returns a streaming chat HTTP request object. Croaks if the engine
does not implement C<chat_stream_request>. Use L</simple_chat_stream> or
L</simple_chat_stream_iterator> to execute the request.

=head2 simple_chat_stream

    my $content = $engine->simple_chat_stream($callback, @messages);

    $engine->simple_chat_stream(sub {
        my ($chunk) = @_;
        print $chunk->content;
    }, 'Tell me a story');

Sends a synchronous streaming chat request. Calls C<$callback> with each
L<Langertha::Stream::Chunk> as it arrives. Returns the complete concatenated
content string when done. Blocks until the stream completes.

=head2 simple_chat_stream_iterator

    my $stream = $engine->simple_chat_stream_iterator(@messages);
    while (my $chunk = $stream->next) {
        print $chunk->content;
    }

Returns a L<Langertha::Stream> iterator. The full response is fetched
synchronously and buffered; iteration yields each L<Langertha::Stream::Chunk>
in order.

=head2 simple_chat_f

    # Traditional Future style
    my $response = $engine->simple_chat_f(@messages)->get;

    # With async/await (recommended)
    use Future::AsyncAwait;
    async sub my_chat {
        my $response = await $engine->simple_chat_f(@messages);
        return $response;
    }

Async version of L</simple_chat>. Returns a L<Future> that resolves to the
response text. Uses L<Net::Async::HTTP> internally; loaded lazily on first call.

For requests that need named arguments (tools, tool_choice,
response_format, etc.) use L</chat_f>; C<simple_chat_f> delegates to it.

=head2 chat_f

    my $response = await $engine->chat_f(
      messages       => [ ... ],
      tools          => [ $tool, ... ],
      tool_choice    => { type => 'tool', name => 'extract' },
      response_format => { ... },
      # any other engine-specific extras pass straight through
    );

Async I<single-turn> chat with named arguments. Returns a L<Future>
resolving to a L<Langertha::Response>. The caller is responsible for
acting on any C<tool_calls> the engine emits — C<chat_f> does not
loop. For the multi-turn MCP tool-calling loop use
L<Langertha::Role::Tools/chat_with_tools_f> instead.

C<tools> in C<chat_f> can be a mix of provider-shape HashRefs
(OpenAI, Anthropic, MCP, Gemini); the engine's C<chat_request> handles
the per-provider serialization. The L<Langertha::Tool> value object is
the canonical normalizer (C<from_hash> accepts every shape, the
C<to_PROVIDER> methods produce the wire payload).

When the caller asks for a forced named tool on an engine that cannot
do native named-tool-forcing but supports C<json_schema>
response_format (currently L<Langertha::Engine::Perplexity>), the
request is automatically rewritten to use the JSON Schema path and the
response is loose-parsed; the resulting L<Langertha::Response> exposes
the parsed arguments via L<Langertha::Response/tool_call_args> with
C<synthetic =E<gt> 1> on the synthesized tool_call entry.

=head2 simple_chat_stream_f

    my ($content, $chunks) = $engine->simple_chat_stream_f(@messages)->get;

Async streaming without a real-time callback. Convenience wrapper around
L</simple_chat_stream_realtime_f> with C<undef> as the callback. Returns a
L<Future> that resolves to C<($content, \@chunks)>.

=head2 aggregate_tool_calls

    my $tool_calls = $engine->aggregate_tool_calls( $chunks );

Walks an ArrayRef of L<Langertha::Stream::Chunk> objects and returns
the flat list of L<Langertha::ToolCall> objects collected from any
chunks that carry C<tool_calls>. Returns an empty ArrayRef if none of
the chunks emitted tool calls.

This is the streaming counterpart to L<Langertha::Response/tool_calls>.
Engines that need to assemble fragmented tool-call deltas (OpenAI's
C<delta.tool_calls> stream, Anthropic's C<input_json_delta>) are
expected to do that assembly inside C<parse_stream_chunk> and attach
the finished L<Langertha::ToolCall> to the relevant chunk; this
helper just collects them.

=head2 simple_chat_stream_realtime_f

    # With async/await (recommended)
    use Future::AsyncAwait;
    async sub my_stream {
        my ($content, $chunks) = await $engine->simple_chat_stream_realtime_f(
            sub { print shift->content },
            @messages
        );
        return $content;
    }

    # Traditional Future style
    my $future = $engine->simple_chat_stream_realtime_f($callback, @messages);
    my ($content, $chunks) = $future->get;

Async streaming with real-time callback. C<$callback> is called with each
L<Langertha::Stream::Chunk> as it arrives from the server. Returns a L<Future>
that resolves to C<($content, \@chunks)> where C<$content> is the full
concatenated text.

This is the recommended method for real-time streaming in async applications.
Pass C<undef> as the callback (or use L</simple_chat_stream_f>) if you only
need the final result.

=head2 content_format

    my $fmt = $engine->content_format;  # 'openai' | 'anthropic' | 'gemini'

Wire format for multimodal content blocks. Controls how
L<Langertha::Content> objects embedded in a message's C<content> arrayref
are serialized during L</chat_messages>. Defaults to C<'openai'>; overridden
by L<Langertha::Engine::AnthropicBase> and L<Langertha::Engine::Gemini>.

=head2 engine_capabilities

    my $caps = $engine->engine_capabilities;
    if ( $caps->{tool_choice_named} ) { ... }

Returns a HashRef of capability flags so callers can avoid passing
parameters the engine cannot honour.

The base implementation reports only what L<Langertha::Role::Chat>
itself provides (C<chat>). Every other capability-bearing role
(L<Langertha::Role::Tools>, L<Langertha::Role::ResponseFormat>,
L<Langertha::Role::Streaming>, L<Langertha::Role::Embedding>,
L<Langertha::Role::Transcription>, L<Langertha::Role::ImageGeneration>,
L<Langertha::Role::HermesTools>, L<Langertha::Role::Temperature>,
L<Langertha::Role::Seed>, L<Langertha::Role::ContextSize>,
L<Langertha::Role::ResponseSize>, L<Langertha::Role::SystemPrompt>,
L<Langertha::Role::ParallelToolUse>) hangs its own contribution into
this method via C<around engine_capabilities>. Engines override (also
via C<around>) when the wire reality differs from the role inventory
— for example to clear C<tool_choice_named> on providers that only
accept string forms.

Common keys produced by the bundled roles:

=over

=item * C<chat> — C<simple_chat>/C<simple_chat_f> work

=item * C<streaming> — C<chat_stream_request> is wired up

=item * C<tools_native> — engine accepts a C<tools> array on the wire

=item * C<tools_hermes> — tools are injected via Hermes-style XML
prompt rather than (or in addition to) the native API

=item * C<tool_choice_auto> / C<tool_choice_any> / C<tool_choice_none> —
which string-form C<tool_choice> values are accepted

=item * C<tool_choice_named> — C<{type =E<gt> 'tool', name =E<gt> '...'}>
forcing works (possibly translated internally — Gemini routes named
tools through C<allowed_function_names>, for example)

=item * C<response_format_json_object> — C<{type =E<gt> 'json_object'}>

=item * C<response_format_json_schema> — JSON Schema structured output

=item * C<embedding>, C<transcription>, C<image_generation> — auxiliary
capabilities matching the corresponding roles

=item * C<temperature>, C<seed>, C<context_size>, C<response_size>,
C<system_prompt>, C<parallel_tool_use> — generation-parameter knobs
the engine will honour

=back

Callers should treat the hash as advisory — a missing key means
"unknown / unsupported", a true value means "the engine claims it
will honour this".

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Langfuse> - Observability integration (composed by this role)

=item * L<Langertha::Role::SystemPrompt> - System prompt injection

=item * L<Langertha::Role::Streaming> - Stream parsing (SSE / NDJSON)

=item * L<Langertha::Role::Tools> - Tool calling on top of chat

=item * L<Langertha::Role::Models> - Model selection

=item * L<Langertha::Stream> - Stream iterator

=item * L<Langertha::Stream::Chunk> - Individual stream chunk

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
