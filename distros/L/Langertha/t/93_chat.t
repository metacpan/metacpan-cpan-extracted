#!/usr/bin/env perl
# ABSTRACT: Tests for Langertha::Chat

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Chat;

# --- Mock request/response/engine ---

{
  package MockChatRequest;
  sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
  }
  sub response_call { $_[0]->{response_call} }
}

{
  package MockUserAgent;
  sub new { bless {}, $_[0] }
  sub request { 'fake_http_response' }
}

{
  package MockChatEngine;
  use Moose;

  has model => (is => 'ro', default => 'default-model');
  has chat_model => (is => 'ro', lazy => 1, default => sub { $_[0]->model });
  has user_agent => (is => 'ro', default => sub { MockUserAgent->new });

  # Track last call parameters
  has last_messages => (is => 'rw');
  has last_extra    => (is => 'rw');

  sub does {
    my ($self, $role) = @_;
    return 1 if $role eq 'Langertha::Role::Chat';
    return $self->SUPER::does($role);
  }

  sub chat_request {
    my ( $self, $messages, %extra ) = @_;
    $self->last_messages($messages);
    $self->last_extra(\%extra);
    return MockChatRequest->new(
      response_call => sub { 'mock response' },
    );
  }

  __PACKAGE__->meta->make_immutable;
}

{
  package MockNonChatEngine;
  use Moose;
  sub does { 0 }
  __PACKAGE__->meta->make_immutable;
}

# --- Tests ---

subtest 'Chat instantiation' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);

  ok($chat, 'created');
  is($chat->engine, $engine, 'engine set');
  ok(!$chat->has_system_prompt, 'no system_prompt by default');
  ok(!$chat->has_model, 'no model override by default');
  ok(!$chat->has_temperature, 'no temperature override by default');
};

subtest 'Chat with all options' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(
    engine        => $engine,
    system_prompt => 'You are helpful.',
    model         => 'custom-model',
    temperature   => 0.5,
  );

  ok($chat->has_system_prompt, 'has system_prompt');
  is($chat->system_prompt, 'You are helpful.', 'system_prompt value');
  ok($chat->has_model, 'has model');
  is($chat->model, 'custom-model', 'model value');
  ok($chat->has_temperature, 'has temperature');
  is($chat->temperature, 0.5, 'temperature value');
};

subtest 'simple_chat delegates to engine' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);

  my $response = $chat->simple_chat('Hello!');
  is($response, 'mock response', 'got response');

  my $msgs = $engine->last_messages;
  is(scalar @$msgs, 1, 'one message');
  is($msgs->[0]{role}, 'user', 'user role');
  is($msgs->[0]{content}, 'Hello!', 'message content');

  my $extra = $engine->last_extra;
  is(scalar keys %$extra, 0, 'no extra params');
};

subtest 'simple_chat with system_prompt prepends it' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(
    engine        => $engine,
    system_prompt => 'Be brief.',
  );

  $chat->simple_chat('What is Perl?');

  my $msgs = $engine->last_messages;
  is(scalar @$msgs, 2, 'two messages');
  is($msgs->[0]{role}, 'system', 'system first');
  is($msgs->[0]{content}, 'Be brief.', 'system_prompt content');
  is($msgs->[1]{role}, 'user', 'user second');
  is($msgs->[1]{content}, 'What is Perl?', 'user content');
};

subtest 'simple_chat with model override passes to engine' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(
    engine => $engine,
    model  => 'gpt-4o',
  );

  $chat->simple_chat('Hi');

  my $extra = $engine->last_extra;
  is($extra->{model}, 'gpt-4o', 'model override in extra');
};

subtest 'simple_chat with temperature override' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(
    engine      => $engine,
    temperature => 0.3,
  );

  $chat->simple_chat('Hi');

  my $extra = $engine->last_extra;
  is($extra->{temperature}, 0.3, 'temperature in extra');
};

subtest 'simple_chat with all overrides' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(
    engine        => $engine,
    system_prompt => 'System.',
    model         => 'gpt-4o',
    temperature   => 0.7,
  );

  $chat->simple_chat('Hello');

  my $msgs = $engine->last_messages;
  is($msgs->[0]{role}, 'system', 'system prompt injected');
  is($msgs->[0]{content}, 'System.', 'system prompt content');

  my $extra = $engine->last_extra;
  is($extra->{model}, 'gpt-4o', 'model in extra');
  is($extra->{temperature}, 0.7, 'temperature in extra');
};

subtest 'simple_chat with hashref messages' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);

  $chat->simple_chat(
    { role => 'user', content => 'Question 1' },
    { role => 'assistant', content => 'Answer 1' },
    { role => 'user', content => 'Question 2' },
  );

  my $msgs = $engine->last_messages;
  is(scalar @$msgs, 3, 'three messages');
  is($msgs->[0]{role}, 'user', 'first user');
  is($msgs->[1]{role}, 'assistant', 'then assistant');
  is($msgs->[2]{role}, 'user', 'then user again');
};

subtest 'simple_chat dies on engine without Chat role' => sub {
  my $engine = MockNonChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);

  eval { $chat->simple_chat('Hello') };
  like($@, qr/does not support chat/, 'dies with useful error');
};

subtest 'multiple chats share same engine' => sub {
  my $engine = MockChatEngine->new;

  my $casual = Langertha::Chat->new(
    engine        => $engine,
    system_prompt => 'Be casual and friendly.',
    temperature   => 0.9,
  );

  my $formal = Langertha::Chat->new(
    engine        => $engine,
    system_prompt => 'Be formal and precise.',
    temperature   => 0.1,
  );

  $casual->simple_chat('Hi');
  is($engine->last_messages->[0]{content}, 'Be casual and friendly.', 'casual prompt');
  is($engine->last_extra->{temperature}, 0.9, 'casual temperature');

  $formal->simple_chat('Hi');
  is($engine->last_messages->[0]{content}, 'Be formal and precise.', 'formal prompt');
  is($engine->last_extra->{temperature}, 0.1, 'formal temperature');
};

# --- Plugin tests ---

{
  package ChatTestPlugin::Logger;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  has log => (is => 'ro', default => sub { [] });

  async sub plugin_before_llm_call {
    my ($self, $conversation, $iteration) = @_;
    push @{$self->log}, { event => 'before_llm_call', iteration => $iteration, msg_count => scalar @$conversation };
    return $conversation;
  }

  async sub plugin_after_llm_response {
    my ($self, $data, $iteration) = @_;
    push @{$self->log}, { event => 'after_llm_response', iteration => $iteration, data => $data };
    return $data;
  }

  __PACKAGE__->meta->make_immutable;
}

{
  package ChatTestPlugin::Injector;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  async sub plugin_before_llm_call {
    my ($self, $conversation, $iteration) = @_;
    unshift @$conversation, { role => 'system', content => 'injected_by_plugin' };
    return $conversation;
  }

  __PACKAGE__->meta->make_immutable;
}

subtest 'Chat fires plugin_before_llm_call and plugin_after_llm_response' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(
    engine  => $engine,
    plugins => ['+ChatTestPlugin::Logger'],
  );

  $chat->simple_chat('Hello');

  my $plugin = $chat->_plugin_instances->[0];
  is(scalar @{$plugin->log}, 2, 'two events logged');
  is($plugin->log->[0]{event}, 'before_llm_call', 'before event');
  is($plugin->log->[0]{iteration}, 1, 'iteration is 1');
  is($plugin->log->[0]{msg_count}, 1, 'one message');
  is($plugin->log->[1]{event}, 'after_llm_response', 'after event');
  is($plugin->log->[1]{data}, 'mock response', 'response passed through');
};

subtest 'Chat plugin can modify conversation' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(
    engine  => $engine,
    plugins => ['+ChatTestPlugin::Injector'],
  );

  $chat->simple_chat('Hello');

  my $msgs = $engine->last_messages;
  is(scalar @$msgs, 2, 'two messages (injected + original)');
  is($msgs->[0]{content}, 'injected_by_plugin', 'plugin injected message');
  is($msgs->[1]{content}, 'Hello', 'original preserved');
};

subtest 'Chat with plugins via Name => Args syntax' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(
    engine  => $engine,
    plugins => ['+ChatTestPlugin::Logger' => {}],
  );

  $chat->simple_chat('Test');
  my $plugin = $chat->_plugin_instances->[0];
  is(scalar @{$plugin->log}, 2, 'plugin received events');
};

subtest 'Chat with system_prompt + plugin injection — both present' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(
    engine        => $engine,
    system_prompt => 'Be nice.',
    plugins       => ['+ChatTestPlugin::Injector'],
  );

  $chat->simple_chat('Hello');

  my $msgs = $engine->last_messages;
  is(scalar @$msgs, 3, 'three messages');
  is($msgs->[0]{content}, 'injected_by_plugin', 'plugin first (prepend)');
  is($msgs->[1]{content}, 'Be nice.', 'system_prompt second');
  is($msgs->[2]{content}, 'Hello', 'user last');
};

# --- Tool-calling tests ---

# Mock MCP server for tool tests
{
  package MockMCPServer;
  use Future;

  sub new {
    my ($class, %tools) = @_;
    bless { tools => \%tools }, $class;
  }

  sub list_tools {
    my ($self) = @_;
    my @tools = map {
      { name => $_, description => "Mock tool $_", inputSchema => { type => 'object', properties => {} } }
    } keys %{$self->{tools}};
    return Future->done(\@tools);
  }

  sub call_tool {
    my ($self, $name, $input) = @_;
    my $handler = $self->{tools}{$name};
    return Future->done($handler->($input)) if $handler;
    return Future->fail("Unknown tool: $name");
  }
}

# Mock engine that supports tools
{
  package MockToolChatEngine;
  use Moose;
  use Future::AsyncAwait;

  has model => (is => 'ro', default => 'mock-model');
  has chat_model => (is => 'ro', lazy => 1, default => sub { $_[0]->model });
  has user_agent => (is => 'ro', default => sub { MockUserAgent->new });
  has '+mcp_servers' => (default => sub { [] }) if __PACKAGE__->can('mcp_servers');

  # Simulate responses: first returns tool calls, then returns final text
  has _response_queue => (is => 'ro', default => sub { [] });
  has last_messages    => (is => 'rw');
  has last_tools       => (is => 'rw');

  sub does {
    my ($self, $role) = @_;
    return 1 if $role eq 'Langertha::Role::Chat';
    return 1 if $role eq 'Langertha::Role::Tools';
    return $self->SUPER::does($role);
  }

  sub chat_request {
    my ( $self, $messages, %extra ) = @_;
    $self->last_messages($messages);
    $self->last_tools($extra{tools}) if $extra{tools};
    my $resp_data = shift @{$self->_response_queue} // { final_text => 'done' };
    return MockChatRequest->new(
      response_call => sub { $resp_data },
    );
  }

  # Net::Async::HTTP mock for async
  has _async_http => (is => 'ro', lazy => 1, default => sub {
    require IO::Async::Loop;
    require Net::Async::HTTP;
    my $http = Net::Async::HTTP->new;
    IO::Async::Loop->new->add($http);
    return $http;
  });

  sub build_tool_chat_request {
    my ($self, $conversation, $formatted_tools, %extra) = @_;
    return $self->chat_request($conversation, tools => $formatted_tools, %extra);
  }

  sub format_tools {
    my ($self, $tools) = @_;
    return $tools;  # pass-through
  }

  sub response_tool_calls {
    my ($self, $data) = @_;
    return $data->{tool_calls} // [];
  }

  sub extract_tool_call {
    my ($self, $tc) = @_;
    return ($tc->{name}, $tc->{input} // {});
  }

  sub format_tool_results {
    my ($self, $data, $results) = @_;
    my @msgs;
    push @msgs, { role => 'assistant', content => 'called tools' };
    for my $r (@$results) {
      my $text = join('', map { $_->{text} // '' } @{$r->{result}{content} // []});
      push @msgs, { role => 'tool', content => $text };
    }
    return @msgs;
  }

  sub response_text_content {
    my ($self, $data) = @_;
    return $data->{final_text} // '';
  }

  sub parse_response {
    my ($self, $data) = @_;
    return $data;  # already parsed in our mock
  }

  sub think_tag_filter { 0 }
  sub json { JSON::MaybeXS->new(utf8 => 1) }

  __PACKAGE__->meta->make_immutable;
}

subtest 'Chat has tool-calling attributes' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);

  is_deeply($chat->mcp_servers, [], 'mcp_servers defaults to empty');
  is($chat->tool_max_iterations, 10, 'tool_max_iterations defaults to 10');
};

subtest 'simple_chat_with_tools_f dies without MCP servers' => sub {
  my $engine = MockToolChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);

  eval { $chat->simple_chat_with_tools_f('hello')->get };
  like($@, qr/No MCP servers/, 'dies without MCP servers');
};

subtest 'simple_chat_with_tools_f executes tool loop' => sub {
  my $mcp = MockMCPServer->new(
    get_time => sub { { content => [{ type => 'text', text => '12:00 PM' }] } },
  );

  my $engine = MockToolChatEngine->new(
    _response_queue => [
      # Iteration 1: LLM wants to call a tool
      {
        tool_calls => [{ name => 'get_time', input => {} }],
      },
      # Iteration 2: LLM returns final text
      {
        final_text => 'The time is 12:00 PM.',
      },
    ],
  );

  my $chat = Langertha::Chat->new(
    engine      => $engine,
    mcp_servers => [$mcp],
  );

  my $result = $chat->simple_chat_with_tools('What time is it?');
  is($result, 'The time is 12:00 PM.', 'got final response after tool loop');
};

subtest 'tool-calling fires plugin hooks' => sub {
  my $mcp = MockMCPServer->new(
    search => sub { { content => [{ type => 'text', text => 'found it' }] } },
  );

  # Logger that also logs tool calls
  {
    package ChatTestPlugin::ToolLogger;
    use Moose;
    use Future::AsyncAwait;
    extends 'Langertha::Plugin';

    has log => (is => 'ro', default => sub { [] });

    async sub plugin_before_llm_call {
      my ($self, $conv, $iter) = @_;
      push @{$self->log}, { event => 'before_llm', iteration => $iter };
      return $conv;
    }

    async sub plugin_after_llm_response {
      my ($self, $data, $iter) = @_;
      push @{$self->log}, { event => 'after_llm', iteration => $iter };
      return $data;
    }

    async sub plugin_before_tool_call {
      my ($self, $name, $input) = @_;
      push @{$self->log}, { event => 'before_tool', name => $name };
      return ($name, $input);
    }

    async sub plugin_after_tool_call {
      my ($self, $name, $input, $result) = @_;
      push @{$self->log}, { event => 'after_tool', name => $name };
      return $result;
    }

    __PACKAGE__->meta->make_immutable;
  }

  my $engine = MockToolChatEngine->new(
    _response_queue => [
      { tool_calls => [{ name => 'search', input => { q => 'perl' } }] },
      { final_text => 'Here is what I found.' },
    ],
  );

  my $chat = Langertha::Chat->new(
    engine      => $engine,
    mcp_servers => [$mcp],
    plugins     => ['+ChatTestPlugin::ToolLogger'],
  );

  $chat->simple_chat_with_tools('Find perl info');

  my $plugin = $chat->_plugin_instances->[0];
  my @events = map { $_->{event} } @{$plugin->log};
  is_deeply(\@events, [
    'before_llm',   # iteration 1
    'after_llm',    # iteration 1 (has tool calls)
    'before_tool',  # search
    'after_tool',   # search result
    'before_llm',   # iteration 2
    'after_llm',    # iteration 2 (final text)
  ], 'all hooks fired in correct order');

  is($plugin->log->[0]{iteration}, 1, 'first LLM call is iteration 1');
  is($plugin->log->[4]{iteration}, 2, 'second LLM call is iteration 2');
  is($plugin->log->[2]{name}, 'search', 'tool name passed to before_tool');
};

subtest 'plugin can skip tool calls' => sub {
  my $mcp = MockMCPServer->new(
    allowed_tool => sub { { content => [{ type => 'text', text => 'ok' }] } },
    blocked_tool => sub { die "should not be called" },
  );

  {
    package ChatTestPlugin::ToolBlocker;
    use Moose;
    use Future::AsyncAwait;
    extends 'Langertha::Plugin';

    async sub plugin_before_tool_call {
      my ($self, $name, $input) = @_;
      return if $name eq 'blocked_tool';
      return ($name, $input);
    }

    __PACKAGE__->meta->make_immutable;
  }

  my $engine = MockToolChatEngine->new(
    _response_queue => [
      { tool_calls => [
        { name => 'blocked_tool', input => {} },
        { name => 'allowed_tool', input => {} },
      ]},
      { final_text => 'Done with tools.' },
    ],
  );

  my $chat = Langertha::Chat->new(
    engine      => $engine,
    mcp_servers => [$mcp],
    plugins     => ['+ChatTestPlugin::ToolBlocker'],
  );

  my $result = $chat->simple_chat_with_tools('Use tools');
  is($result, 'Done with tools.', 'completed despite blocked tool');
};

done_testing;
