#!/usr/bin/env perl
# ABSTRACT: Unit tests for Raider plugin system (class-based)

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Raider;
use Langertha::Raider::Result;
use Langertha::Plugin;

# --- Helper: minimal mock engine ---

{
  package MockEngine;
  use Moose;
  with 'Langertha::Role::Tools';

  has chat_model => (is => 'ro', default => 'mock-model');
  has '+mcp_servers' => (default => sub { [] });

  sub format_tools { return $_[1] }
  sub response_tool_calls { return [] }
  sub extract_tool_call { return ($_[1]->{name}, $_[1]->{input}) }
  sub format_tool_results { return () }
  sub response_text_content { return 'mock response' }
  sub think_tag_filter { 0 }

  __PACKAGE__->meta->make_immutable;
}

# --- Inline test plugin (available before subtests) ---

{
  package TestPlugin::NoOp;
  use Moose;
  extends 'Langertha::Plugin';

  has noop_flag => (is => 'ro', default => 'noop');

  __PACKAGE__->meta->make_immutable;
}

# --- Test: plugins attribute exists ---

subtest 'plugins attribute defaults to empty' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );

  is_deeply($raider->plugins, [], 'plugins defaults to empty');
  is_deeply($raider->plugin_instances, [], 'no plugin instances');
};

# --- Test: base Plugin class hooks are passthrough ---

subtest 'base Plugin hooks are passthrough' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );

  my $plugin = Langertha::Plugin->new(raider => $raider);

  my $msgs = [{ role => 'user', content => 'hello' }];
  my $result = $plugin->plugin_before_raid($msgs)->get;
  is_deeply($result, $msgs, 'plugin_before_raid passes through');

  my $conv = [{ role => 'system', content => 'hi' }];
  $result = $plugin->plugin_build_conversation($conv)->get;
  is_deeply($result, $conv, 'plugin_build_conversation passes through');

  $result = $plugin->plugin_before_llm_call($conv, 1)->get;
  is_deeply($result, $conv, 'plugin_before_llm_call passes through');

  my $data = { some => 'response' };
  $result = $plugin->plugin_after_llm_response($data, 1)->get;
  is_deeply($result, $data, 'plugin_after_llm_response passes through');

  my @tc = $plugin->plugin_before_tool_call('my_tool', { x => 1 })->get;
  is_deeply(\@tc, ['my_tool', { x => 1 }], 'plugin_before_tool_call passes through');

  my $tr = { content => [{ type => 'text', text => 'ok' }] };
  $result = $plugin->plugin_after_tool_call('my_tool', {}, $tr)->get;
  is_deeply($result, $tr, 'plugin_after_tool_call passes through');

  my $rr = Langertha::Raider::Result->new(type => 'final', text => 'done');
  $result = $plugin->plugin_after_raid($rr)->get;
  is($result, $rr, 'plugin_after_raid passes through');

  is_deeply($plugin->self_tools, [], 'self_tools defaults to empty');
};

# --- Test: plugins are instantiated with raider reference ---

subtest 'plugins instantiated with raider back-reference' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::NoOp'],
  );

  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 1, 'one plugin instance');
  isa_ok($instances->[0], 'TestPlugin::NoOp');
  isa_ok($instances->[0], 'Langertha::Plugin');
  is($instances->[0]->raider, $raider, 'raider back-reference set');
};

# --- Test: namespace resolution ---

subtest 'plugin namespace resolution' => sub {
  # Fully qualified inline test class (contains ::, already loaded)
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::NoOp'],
  );
  isa_ok($raider->plugin_instances->[0], 'TestPlugin::NoOp');

  # +FullName bypass
  $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['+TestPlugin::NoOp'],
  );
  isa_ok($raider->plugin_instances->[0], 'TestPlugin::NoOp');
};

subtest 'unknown plugin dies with useful error' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['NonExistentPlugin'],
  );
  eval { $raider->plugin_instances };
  like($@, qr/Plugin 'NonExistentPlugin' not found/, 'useful error');
  like($@, qr/Langertha::Plugin::NonExistentPlugin/, 'shows tried names');
  like($@, qr/LangerthaX::Plugin::NonExistentPlugin/, 'shows LangerthaX fallback');
};

# --- Test: plugin pipeline ---

{
  package TestPlugin::Alpha;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  has alpha_value => (is => 'ro', default => 'alpha');

  async sub plugin_before_raid {
    my ($self, $messages) = @_;
    unshift @$messages, { role => 'system', content => 'alpha_was_here' };
    return $messages;
  }

  __PACKAGE__->meta->make_immutable;
}

{
  package TestPlugin::Beta;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  has beta_value => (is => 'ro', default => 'beta');

  async sub plugin_before_raid {
    my ($self, $messages) = @_;
    push @$messages, { role => 'system', content => 'beta_was_here' };
    return $messages;
  }

  __PACKAGE__->meta->make_immutable;
}

{
  package TestPlugin::Configurable;
  use Moose;
  extends 'Langertha::Plugin';

  has my_option => (is => 'ro', default => 'default_val');

  __PACKAGE__->meta->make_immutable;
}

subtest 'single plugin modifies messages' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::Alpha'],
  );

  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 1, 'one instance');

  my $msgs = [{ role => 'user', content => 'hello' }];
  my $result = $instances->[0]->plugin_before_raid($msgs)->get;
  is($result->[0]{content}, 'alpha_was_here', 'alpha prepended');
};

subtest 'multiple plugins chain in order' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::Alpha', 'TestPlugin::Beta'],
  );

  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 2, 'two instances');

  # Simulate what Raider does: iterate plugins
  my $msgs = [{ role => 'user', content => 'hello' }];
  for my $plugin (@$instances) {
    $msgs = $plugin->plugin_before_raid($msgs)->get;
  }
  is(scalar @$msgs, 3, 'both plugins modified');
  is($msgs->[0]{content}, 'alpha_was_here', 'alpha first');
  is($msgs->[1]{content}, 'hello', 'original in middle');
  is($msgs->[2]{content}, 'beta_was_here', 'beta last');
};

# --- Test: plugin_before_tool_call can skip ---

{
  package TestPlugin::Guardrails;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  has blocked_tools => (is => 'ro', default => sub { ['dangerous_tool'] });

  async sub plugin_before_tool_call {
    my ($self, $name, $input) = @_;
    for my $blocked (@{$self->blocked_tools}) {
      return if $name eq $blocked;
    }
    return ($name, $input);
  }

  __PACKAGE__->meta->make_immutable;
}

subtest 'plugin_before_tool_call can skip tool' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::Guardrails'],
  );

  # Allowed
  my @result = $raider->plugin_pipeline_tool_call_f('safe_tool', { x => 1 })->get;
  is(scalar @result, 2, 'allowed tool passes');
  is($result[0], 'safe_tool', 'name unchanged');

  # Blocked
  @result = $raider->plugin_pipeline_tool_call_f('dangerous_tool', { x => 1 })->get;
  is(scalar @result, 0, 'blocked tool returns empty');
};

# --- Test: plugin self-tools ---

{
  package TestPlugin::WithTool;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  sub self_tools {
    return [{
      name        => 'my_custom_tool',
      description => 'A custom tool from a plugin',
      input_schema => {
        type       => 'object',
        properties => { query => { type => 'string' } },
      },
      code => sub { $_[0]->text_result("custom result: $_[1]->{query}") },
    }];
  }

  __PACKAGE__->meta->make_immutable;
}

subtest 'plugin self-tools are registered' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::WithTool'],
  );

  my $tools = $raider->plugin_instances->[0]->self_tools;
  is(scalar @$tools, 1, 'one tool');
  is($tools->[0]{name}, 'my_custom_tool', 'tool name correct');
};

{
  package MockLoopHTTP;
  use Moose;
  use IO::Async::Loop;
  has loop => (is => 'ro', default => sub { IO::Async::Loop->new });
  __PACKAGE__->meta->make_immutable;
}

{
  package MockLoopEngine;
  use Moose;
  extends 'MockEngine';
  has _http => (is => 'ro', default => sub { MockLoopHTTP->new });
  sub async_loop { $_[0]->_http->loop }
  __PACKAGE__->meta->make_immutable;
}

subtest 'plugin self-tools are listed exactly once' => sub {
  my $raider = Langertha::Raider->new(
    engine  => MockLoopEngine->new,
    plugins => ['TestPlugin::WithTool'],
  );

  $raider->_initialize_inline_mcp_f->get;
  my ( $tools, $map ) = $raider->_gather_tools_f->get;
  my @names = grep { $_ eq 'my_custom_tool' } map { $_->{name} } @$tools;
  is(scalar @names, 1, 'plugin tool gathered once');
  ok($map->{my_custom_tool}, 'plugin tool routed through the inline MCP');
  is(ref $raider->_inline_mcp, 'Net::Async::MCP', 'inline MCP is a plain Net::Async::MCP');
};

# The inline MCP notifier must live on the loop the engine's HTTP futures run
# on ($engine->async_loop, ADR 0028 in core): a raid awaiting futures from two
# loops hangs, since the outer ->get drives only one. Only when the engine has
# no loop (sync fallback, loop-less client) does raider fall back to the
# process-wide IO::Async::Loop->new (k195).
{
  package MockForeignLoopEngine;
  use Moose;
  use IO::Async::Loop::Poll;
  extends 'MockEngine';
  has _loop => (is => 'ro', default => sub { IO::Async::Loop::Poll->new });
  sub async_loop { $_[0]->_loop }
  __PACKAGE__->meta->make_immutable;
}

{
  package MockNoLoopEngine;
  use Moose;
  extends 'MockEngine';
  sub async_loop { undef }
  __PACKAGE__->meta->make_immutable;
}

subtest 'inline MCP joins the engine loop, falls back without one' => sub {
  my $engine = MockForeignLoopEngine->new;
  isnt($engine->async_loop, IO::Async::Loop->new, 'test engine runs on a foreign loop');
  my $raider = Langertha::Raider->new(engine => $engine, plugins => ['TestPlugin::WithTool']);
  $raider->_initialize_inline_mcp_f->get;
  is($raider->_inline_mcp->loop, $engine->async_loop, 'inline MCP added to the engine loop');

  my $raider2 = Langertha::Raider->new(engine => MockNoLoopEngine->new, plugins => ['TestPlugin::WithTool']);
  $raider2->_initialize_inline_mcp_f->get;
  is($raider2->_inline_mcp->loop, IO::Async::Loop->new, 'no engine loop: the process-wide loop');
};

# --- Test: pre-instantiated plugin objects ---

subtest 'pre-instantiated plugin objects' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );

  my $plugin = TestPlugin::Alpha->new(host => $raider);

  my $raider2 = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => [$plugin],
  );

  is(scalar @{$raider2->plugin_instances}, 1, 'one instance');
  is($raider2->plugin_instances->[0], $plugin, 'same object');
};

# --- Test: plugin_args passed to constructors ---

subtest 'plugin_args forwarded to plugin constructors' => sub {
  my $raider = Langertha::Raider->new(
    engine       => MockEngine->new,
    raider_mcp   => 1,
    plugins      => ['TestPlugin::Configurable'],
    plugin_args => { my_option => 'from_args' },
  );

  my $plugin = $raider->plugin_instances->[0];
  is($plugin->my_option, 'from_args', 'my_option forwarded via plugin_args');
};

# --- Test: host attribute and raider convenience ---

subtest 'host attribute and raider convenience' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::Alpha'],
  );

  my $plugin = $raider->plugin_instances->[0];
  is($plugin->host, $raider, 'host is set');
  is($plugin->raider, $raider, 'raider returns host when host is Raider');

  # Backwards compat: raider => $x in constructor sets host
  my $p2 = Langertha::Plugin->new(raider => $raider);
  is($p2->host, $raider, 'raider => sets host via BUILDARGS');
};

# --- Test: plugin event system ---

{
  package TestPlugin::EventProvider;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  sub provides_events { ['data_saved'] }

  __PACKAGE__->meta->make_immutable;
}

{
  package TestPlugin::EventConsumer;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  has event_log => (is => 'ro', default => sub { [] });

  sub requires_events { ['data_saved'] }

  async sub on_data_saved {
    my ( $self, $data ) = @_;
    push @{$self->event_log}, $data;
    return 'ack';
  }

  __PACKAGE__->meta->make_immutable;
}

{
  package TestPlugin::EventNeedsMissing;
  use Moose;
  extends 'Langertha::Plugin';

  sub requires_events { ['nonexistent_event'] }

  __PACKAGE__->meta->make_immutable;
}

subtest 'event system: provides_events and requires_events' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::EventProvider', 'TestPlugin::EventConsumer'],
  );

  is(scalar @{$raider->plugin_instances}, 2, 'both loaded');
};

subtest 'event system: missing required event dies' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::EventNeedsMissing'],
  );
  eval { $raider->plugin_instances };
  like($@, qr/requires event 'nonexistent_event'/, 'dies with useful error');
  like($@, qr/provides_events/, 'mentions provides_events');
};

subtest 'fire_event_f dispatches to on_ methods' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::EventProvider', 'TestPlugin::EventConsumer'],
  );

  my @results = $raider->fire_event_f('data_saved', { key => 'value' })->get;
  is(scalar @results, 1, 'one handler responded');
  is($results[0], 'ack', 'got ack from consumer');

  my $consumer = $raider->plugin_instances->[1];
  is(scalar @{$consumer->event_log}, 1, 'event received');
  is($consumer->event_log->[0]{key}, 'value', 'data passed through');
};

subtest 'fire_event_f with no listeners returns empty' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::EventProvider'],
  );

  my @results = $raider->fire_event_f('data_saved', 'hello')->get;
  is(scalar @results, 0, 'no listeners, no results');
};

# --- Test: multiple event consumers ---

{
  package TestPlugin::EventConsumer2;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  has event_log => (is => 'ro', default => sub { [] });

  sub requires_events { ['data_saved'] }

  async sub on_data_saved {
    my ( $self, $data ) = @_;
    push @{$self->event_log}, $data;
    return 'ack2';
  }

  __PACKAGE__->meta->make_immutable;
}

subtest 'multiple event consumers all receive event' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => [
      'TestPlugin::EventProvider',
      'TestPlugin::EventConsumer',
      'TestPlugin::EventConsumer2',
    ],
  );

  my @results = $raider->fire_event_f('data_saved', { x => 42 })->get;
  is(scalar @results, 2, 'two consumers responded');
  is($results[0], 'ack', 'first consumer');
  is($results[1], 'ack2', 'second consumer');

  my $c1 = $raider->plugin_instances->[1];
  my $c2 = $raider->plugin_instances->[2];
  is(scalar @{$c1->event_log}, 1, 'consumer 1 got event');
  is(scalar @{$c2->event_log}, 1, 'consumer 2 got event');
  is($c1->event_log->[0]{x}, 42, 'data correct in consumer 1');
  is($c2->event_log->[0]{x}, 42, 'data correct in consumer 2');
};

# --- Test: plugins on Engine (not just Raider) ---

{
  package TestPlugin::EngineLogger;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  has log => (is => 'ro', default => sub { [] });

  sub provides_events { ['engine_test'] }

  # Answers with itself, so the test reaches the instance through the public
  # fire_event_f instead of reaching into plugin_instances.
  async sub on_engine_test { my ($self) = @_; push @{$self->log}, 'engine_test'; return $self }

  __PACKAGE__->meta->make_immutable;
}

subtest 'plugins work on Engine via PluginHost role' => sub {
  # Engine::Remote consumes Role::PluginHost, so engines support plugins
  require Langertha::Engine::OpenAI;
  my $engine = Langertha::Engine::OpenAI->new(
    api_key => 'test-key',
    model   => 'gpt-4o-mini',
    plugins => ['TestPlugin::EngineLogger'],
  );

  my @results = $engine->fire_event_f('engine_test')->get;
  is(scalar @results, 1, 'one plugin on engine answered the event');
  isa_ok($results[0], 'TestPlugin::EngineLogger');
  is($results[0]->host, $engine, 'host is the engine');
  is($results[0]->raider, undef, 'raider returns undef on engine');
  is_deeply($results[0]->log, ['engine_test'], 'handler ran once');
};

subtest 'engine plugin event validation works' => sub {
  require Langertha::Engine::OpenAI;
  my $engine = Langertha::Engine::OpenAI->new(
    api_key => 'test-key',
    model   => 'gpt-4o-mini',
    plugins => ['TestPlugin::EventNeedsMissing'],
  );
  eval { $engine->fire_event_f('engine_test')->get };
  like($@, qr/requires event 'nonexistent_event'/, 'engine validates events too');
};

done_testing;
