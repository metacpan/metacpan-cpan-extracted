package Langertha::Chat;
# ABSTRACT: Chat abstraction wrapping an engine with optional overrides
our $VERSION = '0.503';
use Moose;
use Future::AsyncAwait;
use Carp qw( croak );
use JSON::MaybeXS;
use Log::Any qw( $log );
use Langertha::Role::Tools ();

with 'Langertha::Role::PluginHost';


has engine => (
  is       => 'ro',
  required => 1,
);

has system_prompt => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_system_prompt',
);

has model => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_model',
);

has temperature => (
  is        => 'ro',
  isa       => 'Num',
  predicate => 'has_temperature',
);

has mcp_servers => (
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);

has tool_max_iterations => (
  is      => 'ro',
  isa     => 'Int',
  default => 10,
);


sub _extra {
  my ( $self ) = @_;
  return (
    ($self->has_model       ? (model       => $self->model)       : ()),
    ($self->has_temperature ? (temperature => $self->temperature) : ()),
  );
}

# The wrapper's model rides %extra into the engine's request builder past
# chat_f, so the engine's per-request model warning (Role::Chat, karr k352) is
# raised here, once per call, with the request features the call uses: the
# wrapper's temperature, the gathered tools, streaming (karr k360).
sub _warn_model_override {
  my ( $self, $method, $streaming, %request ) = @_;
  return unless $self->has_model;
  my $engine = $self->engine;
  return unless $engine->can('_warn_model_override');
  $engine->_warn_model_override( "Langertha::Chat->$method", { $self->_extra, %request }, $streaming );
  return;
}

# Each message goes through the engine's own per-message step of chat_messages,
# so Langertha::Content objects become the engine's content_format blocks
# (karr k275). The leading system messages are the engine's own
# _system_messages: the engine's system_prompt unless the wrapper has one, plus
# engine prefixes such as NousResearch's reasoning prompt either way (k277).
sub _build_messages {
  my ( $self, @messages ) = @_;
  my $engine    = $self->engine;
  my $normalize = $engine->can('_normalize_content_blocks');
  my @override  = $self->has_system_prompt ? ( $self->system_prompt ) : ();
  return [
    ( $engine->can('_system_messages')
      ? $engine->_system_messages(@override)
      : map { +{ role => 'system', content => $_ } } @override ),
    map {
      my $msg = ref $_ ? $_ : { role => 'user', content => $_ };
      $normalize ? $engine->$normalize($msg) : $msg;
    } @messages
  ];
}

# The _f paths fetch the URL images the engine inlines through its async
# backend before the build, like the engine's own _f paths (karr k274, k275).
async sub _build_messages_f {
  my ( $self, @messages ) = @_;
  my $engine = $self->engine;
  @messages = await $engine->_prefetch_inline_images_f(@messages)
    if $engine->can('_prefetch_inline_images_f');
  return $self->_build_messages(@messages);
}

sub _assert_chat_engine {
  my ( $self ) = @_;
  my $engine = $self->engine;
  croak ref($engine) . " does not support chat"
    unless $engine->does('Langertha::Role::Chat');
  return $engine;
}

# --- Plugin hook runners (async) ---

async sub _run_plugin_before_llm_call {
  my ( $self, $conversation, $iteration ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    $conversation = await $plugin->plugin_before_llm_call($conversation, $iteration);
  }
  return $conversation;
}

async sub _run_plugin_after_llm_response {
  my ( $self, $data, $iteration ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    $data = await $plugin->plugin_after_llm_response($data, $iteration);
  }
  return $data;
}

async sub _run_plugin_after_tool_call {
  my ( $self, $name, $input, $result ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    $result = await $plugin->plugin_after_tool_call($name, $input, $result);
  }
  return $result;
}

# --- Simple chat (no tools) ---

sub simple_chat {
  my ( $self, @messages ) = @_;
  $log->debugf("[Chat] simple_chat via %s", ref $self->engine);
  my $engine = $self->_assert_chat_engine;
  $self->_warn_model_override( 'simple_chat', 0 );
  my $conversation = $self->_build_messages(@messages);

  $conversation = $self->_run_plugin_before_llm_call($conversation, 1)->get;

  my $request = $engine->chat_request($conversation, $self->_extra);
  my $response = $engine->user_agent->request($request);
  my $data = $request->response_call->($response);

  $data = $self->_run_plugin_after_llm_response($data, 1)->get;

  return $data;
}


# A failed response still updates the engine's rate limit before the die, so
# a caller can back off from a 429 (karr k300); returns the engine's error
# text, the same as its sync croak (karr k312).
sub _failed_message {
  my ( $self, $engine, $response, $what ) = @_;
  $engine->_update_rate_limit($response) if $engine->can('_update_rate_limit');
  return $engine->can('_request_failed_message')
    ? $engine->_request_failed_message( $response, $what )
    : "" . (ref $engine) . " $what failed: " . $response->status_line;
}

async sub simple_chat_f {
  my ( $self, @messages ) = @_;
  my $engine = $self->_assert_chat_engine;
  $self->_warn_model_override( 'simple_chat_f', 0 );
  my $conversation = await $self->_build_messages_f(@messages);

  $conversation = await $self->_run_plugin_before_llm_call($conversation, 1);

  my $request = $engine->chat_request($conversation, $self->_extra);
  my $response = await $engine->_async_do_request_f(
    request => $request,
  );
  unless ($response->is_success) {
    die $self->_failed_message( $engine, $response, 'request' );
  }
  my $data = $request->response_call->($response);

  $data = await $self->_run_plugin_after_llm_response($data, 1);

  return $data;
}


sub simple_chat_stream {
  my ( $self, $callback, @messages ) = @_;
  my $engine = $self->_assert_chat_engine;
  croak ref($engine) . " does not support streaming"
    unless $engine->can('chat_stream_request');
  croak "simple_chat_stream requires a callback as first argument"
    unless ref $callback eq 'CODE';
  $self->_warn_model_override( 'simple_chat_stream', 1 );
  my $conversation = $self->_build_messages(@messages);

  $conversation = $self->_run_plugin_before_llm_call($conversation, 1)->get;

  my $request = $engine->chat_stream_request($conversation, $self->_extra);
  my $chunks = $engine->execute_streaming_request($request, $callback);
  return join('', map { $_->content } @$chunks);
}


# --- Chat with tools ---

sub _gather_tools {
  my ( $self ) = @_;
  my @mcp_servers = @{$self->mcp_servers};
  croak "No MCP servers configured" unless @mcp_servers;

  # A name two servers offer goes on the wire once, from the first (k332).
  return $self->engine->_tool_loop_tools(
    map { [ $_, $_->list_tools->get ] } @mcp_servers );
}

sub _tool_loop_iteration {
  my ( $self, $engine, $conversation, $formatted_tools, $iteration ) = @_;

  # Plugin hook: before LLM call
  $conversation = $self->_run_plugin_before_llm_call($conversation, $iteration)->get;

  # Build and send the request
  my $request = $engine->build_tool_chat_request($conversation, $formatted_tools, $self->_extra);

  my $response = $engine->user_agent->request($request);
  # The same failure text and rate-limit update as the async loop (karr k312).
  die $self->_failed_message( $engine, $response, 'tool chat request' )
    unless $response->is_success;

  my $reply = $self->_tool_loop_reply_f( $engine, $response, $iteration )->get;

  return ($conversation, $reply->raw, $reply);
}

# One tool-loop turn's reply. plugin_after_llm_response gets the RAW decoded
# wire body -- the provider's own block list, never the flattened Response
# (karr #81) -- and the body the hooks return is read by the parser chat_f
# uses (karr k321, k322): an error-in-body 200 croaks as it does there, the
# final text is chat_f's, the calls to run are Response.tool_calls (ADR 0003).
# The assistant echo is built from ->raw of that same reply, so a hook that
# drops a call, changes its arguments or rewrites the text is honoured by all
# three, and every echoed call gets exactly one result -- karr k347.
async sub _tool_loop_reply_f {
  my ( $self, $engine, $response, $iteration ) = @_;
  my $data = $engine->parse_response($response);
  $data = await $self->_run_plugin_after_llm_response($data, $iteration);
  return $engine->tool_loop_response($data);
}

sub simple_chat_with_tools {
  my ( $self, @messages ) = @_;
  my $engine = $self->_assert_chat_engine;
  croak ref($engine) . " does not support tools"
    unless $engine->does('Langertha::Role::Tools');

  my ($all_tools, $tool_server_map) = $self->_gather_tools;
  $log->debugf("[Chat] simple_chat_with_tools via %s, %d tools, max_iterations=%d",
    ref $engine, scalar @$all_tools, $self->tool_max_iterations);
  my $formatted_tools = $engine->format_tools($all_tools);
  $self->_warn_model_override( 'simple_chat_with_tools', 0, tools => $formatted_tools );
  my $conversation = $self->_build_messages(@messages);

  for my $iteration (1..$self->tool_max_iterations) {
    ($conversation, my $data, my $reply) =$self->_tool_loop_iteration(
      $engine, $conversation, $formatted_tools, $iteration,
    );

    # Calls cut off by the token limit are dropped, as in chat_with_tools_f (k324).
    ( my $calls, $data ) = $engine->tool_loop_calls( $reply, $reply->raw );
    my @tool_calls = @$calls;
    return $reply->content unless @tool_calls;

    # Execute each tool call
    my @results;
    for my $tc (@tool_calls) {
      my ( $name, $input ) = ( $tc->name, $tc->arguments );

      # Arguments that do not decode are answered with an error result
      # before any plugin sees the call (k345).
      if ( my $bad = Langertha::Role::Tools::_undecodable_arguments_result($tc) ) {
        push @results, { tool_call => $tc, result => $bad };
        next;
      }

      $log->debugf("[Chat] Calling tool: %s", $name);

      # Plugin hook: before tool call (can skip)
      my @plugin_tc = $self->_plugin_pipeline_tool_call($name, $input)->get;
      unless (@plugin_tc) {
        push @results, { tool_call => $tc, result => {
          content => [{ type => 'text', text => "Tool call '$name' was skipped by plugin." }],
        }};
        next;
      }
      ( $name, $input ) = @plugin_tc;

      # The plugins see every call and may rename one onto a real tool; a
      # name no server offers after them is answered with an error result,
      # so the batch runs to the end and the model can correct itself
      # (k332, k348).
      my $mcp = $tool_server_map->{$name};
      unless ($mcp) {
        push @results, { tool_call => $tc,
          result => Langertha::Role::Tools::_unknown_tool_result($name) };
        next;
      }

      my $result = $mcp->call_tool($name, $input)->else(sub {
        my ( $error ) = @_;
        Future->done({
          content => [{ type => 'text', text => "Error calling tool '$name': $error" }],
          isError => JSON->true,
        });
      })->get;

      # Plugin hook: after tool call
      $result = $self->_run_plugin_after_tool_call($name, $input, $result)->get;

      push @results, { tool_call => $tc, result => $result };
    }

    push @$conversation, $engine->format_tool_results($data, \@results);
  }

  die "Tool calling loop exceeded " . $self->tool_max_iterations . " iterations";
}


async sub simple_chat_with_tools_f {
  my ( $self, @messages ) = @_;
  my $engine = $self->_assert_chat_engine;
  croak ref($engine) . " does not support tools"
    unless $engine->does('Langertha::Role::Tools');

  my ($all_tools, $tool_server_map) = $self->_gather_tools;
  my $formatted_tools = $engine->format_tools($all_tools);
  $self->_warn_model_override( 'simple_chat_with_tools_f', 0, tools => $formatted_tools );
  my $conversation = await $self->_build_messages_f(@messages);

  for my $iteration (1..$self->tool_max_iterations) {
    $conversation = await $self->_run_plugin_before_llm_call($conversation, $iteration);

    my $request = $engine->build_tool_chat_request($conversation, $formatted_tools, $self->_extra);

    my $response = await $engine->_async_do_request_f(request => $request);
    unless ($response->is_success) {
      die $self->_failed_message( $engine, $response, 'tool chat request' );
    }

    # As the sync loop: the raw body to the hook, chat_f's parser on what it
    # returns, calls, text and echo from that one reply (k321, k322, k347).
    my $reply = await $self->_tool_loop_reply_f( $engine, $response, $iteration );

    my ( $calls, $data ) = $engine->tool_loop_calls( $reply, $reply->raw );
    my @tool_calls = @$calls;
    return $reply->content unless @tool_calls;

    my @results;
    for my $tc (@tool_calls) {
      my ( $name, $input ) = ( $tc->name, $tc->arguments );

      # Arguments that do not decode are answered with an error result
      # before any plugin sees the call (k345).
      if ( my $bad = Langertha::Role::Tools::_undecodable_arguments_result($tc) ) {
        push @results, { tool_call => $tc, result => $bad };
        next;
      }

      my @plugin_tc = await $self->_plugin_pipeline_tool_call($name, $input);
      unless (@plugin_tc) {
        push @results, { tool_call => $tc, result => {
          content => [{ type => 'text', text => "Tool call '$name' was skipped by plugin." }],
        }};
        next;
      }
      ( $name, $input ) = @plugin_tc;

      # The plugins see every call and may rename one onto a real tool; a
      # name no server offers after them is answered with an error result,
      # so the batch runs to the end and the model can correct itself
      # (k332, k348).
      my $mcp = $tool_server_map->{$name};
      unless ($mcp) {
        push @results, { tool_call => $tc,
          result => Langertha::Role::Tools::_unknown_tool_result($name) };
        next;
      }

      my $result = await $mcp->call_tool($name, $input)->else(sub {
        Future->done({
          content => [{ type => 'text', text => "Error calling tool '$name': $_[0]" }],
          isError => JSON->true,
        });
      });

      $result = await $self->_run_plugin_after_tool_call($name, $input, $result);
      push @results, { tool_call => $tc, result => $result };
    }

    push @$conversation, $engine->format_tool_results($data, \@results);
  }

  die "Tool calling loop exceeded " . $self->tool_max_iterations . " iterations";
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Chat - Chat abstraction wrapping an engine with optional overrides

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::OpenAI;
    use Langertha::Chat;

    my $engine = Langertha::Engine::OpenAI->new(
        api_key => $ENV{OPENAI_API_KEY},
        model   => 'gpt-4o',
    );

    my $chat = Langertha::Chat->new(
        engine        => $engine,
        system_prompt => 'You are a helpful assistant.',
        plugins       => ['Langfuse'],
    );

    my $reply = $chat->simple_chat('Hello!');

    # With MCP tool calling
    my $chat_tools = Langertha::Chat->new(
        engine      => $engine,
        mcp_servers => [$mcp],
        plugins     => ['Langfuse'],
    );
    my $result = $chat_tools->simple_chat_with_tools('List files in /tmp');

=head1 DESCRIPTION

C<Langertha::Chat> wraps any engine that consumes L<Langertha::Role::Chat>
and adds optional overrides for model, system prompt, and temperature, plus
plugin lifecycle hooks via L<Langertha::Role::PluginHost>.

Use this class when you want to share a single engine instance across
multiple chat contexts with different configurations, or when you need
plugin observability (e.g. L<Langertha::Plugin::Langfuse>) without
modifying the engine itself.

=head2 engine

The LLM engine to delegate chat requests to. Must consume
L<Langertha::Role::Chat>.

=head2 system_prompt

Optional system prompt. When set, prepended to messages for each
request in place of the engine's own C<system_prompt>. When not set, the
engine's C<system_prompt> is sent, exactly as the engine's own
C<chat_messages> would send it. System messages the engine itself mandates
still apply either way: with L<Langertha::Engine::NousResearch> and
C<reasoning> enabled, its C<reasoning_prompt> leads the conversation,
followed by this system prompt. Plugins see these system messages in the
conversation passed to C<plugin_before_llm_call>.

=head2 model

Optional model name override. When set, it is passed to the engine's request
builder as a per-request C<model> through C<%extra>: it replaces the model in
the request body, or in the URL on engines that name the model there
(L<Langertha::Engine::Gemini>, L<Langertha::Engine::AKI>). It does not change
the engine's C<chat_model>, and every model-scoped decision (capabilities, tool
wire format, reasoning profile, body details) is still taken for
C<chat_model>, as for a C<model> passed to L<Langertha::Role::Chat/chat_f>.
When one of those decisions that the call uses would differ for this model,
each chat call warns once and names the decisions; the request is sent
unchanged. For a different model, use an engine whose C<chat_model> is that
model.

=head2 temperature

Optional temperature override. When set, overrides the engine's
temperature.

=head2 mcp_servers

ArrayRef of MCP client objects for tool calling — any
L<Net::Async::MCP>-compatible client (for example a L<Net::Async::MCP> client
as used by the langertha-raider distribution). Each must respond to
C<list_tools> and C<call_tool>.

=head2 tool_max_iterations

Maximum tool-calling round trips. Defaults to C<10>.

=head2 simple_chat

    my $response = $chat->simple_chat('Hello!');

Sends a synchronous chat request. Fires C<plugin_before_llm_call> and
C<plugin_after_llm_response> hooks.

=head2 simple_chat_f

    my $response = await $chat->simple_chat_f('Hello!');

Async version of L</simple_chat>.

=head2 simple_chat_stream

    my $content = $chat->simple_chat_stream(sub { print shift->content }, 'Hi');

Synchronous streaming chat. Calls C<$callback> with each chunk.

=head2 simple_chat_with_tools

    my $text = $chat->simple_chat_with_tools(@messages);

Synchronous tool-calling chat loop. Gathers tools from L</mcp_servers>,
sends chat requests, executes tool calls, and iterates until the LLM
returns a final text response. Fires plugin hooks at each step:
C<plugin_before_llm_call>, C<plugin_after_llm_response>,
C<plugin_before_tool_call>, and C<plugin_after_tool_call>.

Each reply is read by the engine's C<chat_response>, as in
L<Langertha::Role::Chat/chat_f>: a response whose body reports an error fails
with the same text, the final text is the reply's C<content>, and the calls
run are its L<Langertha::Response/tool_calls>. C<plugin_after_llm_response>
receives the raw decoded wire body before it is read, and the body it returns
is what the turn is read from: the calls run, the final text and the
assistant turn echoed back to the provider all follow its edits, so a call a
plugin removes is neither run nor echoed. A failed request dies with
C<tool chat request failed>, in the sync and the async loop alike. A call
whose arguments were cut off by the token limit is not run, a call whose
arguments otherwise do not decode is answered with an error result, a call to an
unknown tool is answered with an error result, and a tool name two servers
offer runs on the first, and a blocked prompt dies with C<prompt blocked>, as
in L<Langertha::Role::Tools/chat_with_tools_f>. Whether a tool is unknown is
decided on the name C<plugin_before_tool_call> returns: every call reaches the
plugins, and one may map a hallucinated name onto a real tool.

=head2 simple_chat_with_tools_f

    my $text = await $chat->simple_chat_with_tools_f(@messages);

Async version of L</simple_chat_with_tools>.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::PluginHost> - Plugin system consumed by this class

=item * L<Langertha::Role::Chat> - Chat role required by the engine

=item * L<Langertha::Role::Tools> - Tool-calling role required for MCP methods

=item * L<Langertha::Plugin::Langfuse> - Observability plugin for chat sessions

=item * L<Langertha::Embedder> - Embedding counterpart to this class

=item * L<Langertha::ImageGen> - Image generation counterpart to this class

=item * L<Langertha::Raider> - Autonomous agent with full conversation history

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
