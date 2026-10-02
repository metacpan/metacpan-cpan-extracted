#!/usr/bin/env perl
# ABSTRACT: Tests for plugin Name => { args } configuration syntax

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Chat;
use Langertha::Plugin;

# The plugin-configuration feature under test lives in
# Langertha::Role::PluginHost, so it is exercised through a core plugin host —
# Langertha::Chat. Langertha::Raider (in the langertha-raider distribution) is a
# host too; the `plugin` sugar subtest below is guarded on its presence.
my $has_raider = eval { require Langertha::Raider; 1 };

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

# --- Helper: a plugin host built on a core PluginHost consumer ---

sub host { Langertha::Chat->new(engine => MockEngine->new, @_) }

# --- Test plugin with custom attributes ---

{
  package TestPlugin::Configurable;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  has my_option => (is => 'ro', default => 'default_val');
  has priority  => (is => 'ro', default => 0);

  __PACKAGE__->meta->make_immutable;
}

# --- Tests ---

subtest 'classic string syntax still works' => sub {
  my $chat = host(
    plugins => ['TestPlugin::Configurable'],
  );
  is(scalar @{$chat->_plugin_instances}, 1, 'one instance');
  isa_ok($chat->_plugin_instances->[0], 'TestPlugin::Configurable');
};

subtest 'Name => { args } pair syntax' => sub {
  my $chat = host(
    plugins => ['+TestPlugin::Configurable' => { my_option => 'custom' }],
  );
  my $instances = $chat->_plugin_instances;
  is(scalar @$instances, 1, 'one instance');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  is($instances->[0]->my_option, 'custom', 'per-plugin args applied');
};

subtest 'mixed: string + Name => { args }' => sub {
  my $chat = host(
    plugins => [
      'TestPlugin::Configurable',
      '+TestPlugin::Configurable' => { my_option => 'second' },
    ],
  );
  my $instances = $chat->_plugin_instances;
  is(scalar @$instances, 2, 'two instances');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  isa_ok($instances->[1], 'TestPlugin::Configurable');
  is($instances->[0]->my_option, 'default_val', 'first has defaults');
  is($instances->[1]->my_option, 'second', 'second has per-plugin args');
};

subtest 'pre-instantiated object' => sub {
  my $dummy_host = host();
  my $plugin = TestPlugin::Configurable->new(host => $dummy_host);

  my $chat = host(
    plugins => [$plugin],
  );
  my $instances = $chat->_plugin_instances;
  is(scalar @$instances, 1, 'one instance');
  is($instances->[0], $plugin, 'same object passed through');
};

subtest 'mixed: object + Name => { args } + string' => sub {
  my $dummy_host = host();
  my $obj = TestPlugin::Configurable->new(host => $dummy_host, my_option => 'from_obj');

  my $chat = host(
    plugins => [
      $obj,
      '+TestPlugin::Configurable' => { my_option => 'from_args' },
      'TestPlugin::Configurable',
    ],
  );
  my $instances = $chat->_plugin_instances;
  is(scalar @$instances, 3, 'three instances');
  is($instances->[0], $obj, 'object preserved');
  is($instances->[0]->my_option, 'from_obj', 'object args intact');
  isa_ok($instances->[1], 'TestPlugin::Configurable');
  is($instances->[1]->my_option, 'from_args', 'per-plugin args applied');
  isa_ok($instances->[2], 'TestPlugin::Configurable');
  is($instances->[2]->my_option, 'default_val', 'bare string gets defaults');
};

subtest 'per-plugin args override _plugin_args' => sub {
  my $chat = host(
    plugins      => ['+TestPlugin::Configurable' => { my_option => 'winner' }],
    _plugin_args => { my_option => 'loser' },
  );
  my $plugin = $chat->_plugin_instances->[0];
  is($plugin->my_option, 'winner', 'per-plugin args win over _plugin_args');
};

subtest '_plugin_args still work as fallback' => sub {
  my $chat = host(
    plugins      => ['TestPlugin::Configurable'],
    _plugin_args => { my_option => 'from_fallback' },
  );
  my $plugin = $chat->_plugin_instances->[0];
  is($plugin->my_option, 'from_fallback', '_plugin_args used when no per-plugin args');
};

subtest '+ClassName loads directly without prefix search' => sub {
  my $chat = host(
    plugins => ['+TestPlugin::Configurable'],
  );
  my $instances = $chat->_plugin_instances;
  is(scalar @$instances, 1, 'one instance');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
};

subtest '+ClassName with Name => { args } syntax' => sub {
  my $chat = host(
    plugins => ['+TestPlugin::Configurable' => { my_option => 'custom', priority => 5 }],
  );
  my $instances = $chat->_plugin_instances;
  is(scalar @$instances, 1, 'one instance');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  is($instances->[0]->my_option, 'custom', 'args applied');
  is($instances->[0]->priority, 5, 'priority set');
};

subtest '+ClassName mixed with short names' => sub {
  my $chat = host(
    plugins => [
      'TestPlugin::Configurable',
      '+TestPlugin::Configurable' => { my_option => 'from_plus' },
    ],
  );
  my $instances = $chat->_plugin_instances;
  is(scalar @$instances, 2, 'two instances');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  isa_ok($instances->[1], 'TestPlugin::Configurable');
  is($instances->[1]->my_option, 'from_plus', 'plus-syntax args applied');
};

subtest 'empty hashref is valid (no extra args)' => sub {
  my $chat = host(
    plugins => ['+TestPlugin::Configurable' => {}],
  );
  my $instances = $chat->_plugin_instances;
  is(scalar @$instances, 1, 'one instance');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  is($instances->[0]->my_option, 'default_val', 'default my_option');
};

# --- Raider sugar (langertha-raider) ---

SKIP: {
  skip 'Langertha::Raider not installed (extracted to langertha-raider)', 1
    unless $has_raider;

  subtest 'sugar: plugin Name => { args } works' => sub {
    my $setup_ok = eval q{
      package TestSugarConfigRaider {
        use Langertha qw( Raider );
        plugin '+TestPlugin::Configurable' => { my_option => 'sugar_val' };
        plugin 'TestPlugin::Configurable';
        __PACKAGE__->meta->make_immutable;
      }
      1;
    };
    BAIL_OUT("Raider sugar package setup failed: $@") unless $setup_ok;

    my $raider = TestSugarConfigRaider->new(
      engine     => MockEngine->new,
      raider_mcp => 1,
    );
    my $instances = $raider->_plugin_instances;
    is(scalar @$instances, 2, 'two instances from sugar');
    isa_ok($instances->[0], 'TestPlugin::Configurable');
    is($instances->[0]->my_option, 'sugar_val', 'sugar args applied');
    isa_ok($instances->[1], 'TestPlugin::Configurable');
  };
}

done_testing;
