#!/usr/bin/env perl
# ABSTRACT: Tests for plugin Name => { args } configuration syntax

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Raider;
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
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['TestPlugin::Configurable'],
  );
  is(scalar @{$raider->plugin_instances}, 1, 'one instance');
  isa_ok($raider->plugin_instances->[0], 'TestPlugin::Configurable');
};

subtest 'Name => { args } pair syntax' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['+TestPlugin::Configurable' => { my_option => 'custom' }],
  );
  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 1, 'one instance');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  is($instances->[0]->my_option, 'custom', 'per-plugin args applied');
};

subtest 'mixed: string + Name => { args }' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => [
      'TestPlugin::Configurable',
      '+TestPlugin::Configurable' => { my_option => 'second' },
    ],
  );
  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 2, 'two instances');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  isa_ok($instances->[1], 'TestPlugin::Configurable');
  is($instances->[0]->my_option, 'default_val', 'first has defaults');
  is($instances->[1]->my_option, 'second', 'second has per-plugin args');
};

subtest 'pre-instantiated object' => sub {
  my $dummy_raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  my $plugin = TestPlugin::Configurable->new(host => $dummy_raider);

  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => [$plugin],
  );
  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 1, 'one instance');
  is($instances->[0], $plugin, 'same object passed through');
};

subtest 'mixed: object + Name => { args } + string' => sub {
  my $dummy_raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  my $obj = TestPlugin::Configurable->new(host => $dummy_raider, my_option => 'from_obj');

  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => [
      $obj,
      '+TestPlugin::Configurable' => { my_option => 'from_args' },
      'TestPlugin::Configurable',
    ],
  );
  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 3, 'three instances');
  is($instances->[0], $obj, 'object preserved');
  is($instances->[0]->my_option, 'from_obj', 'object args intact');
  isa_ok($instances->[1], 'TestPlugin::Configurable');
  is($instances->[1]->my_option, 'from_args', 'per-plugin args applied');
  isa_ok($instances->[2], 'TestPlugin::Configurable');
  is($instances->[2]->my_option, 'default_val', 'bare string gets defaults');
};

subtest 'per-plugin args override plugin_args' => sub {
  my $raider = Langertha::Raider->new(
    engine       => MockEngine->new,
    raider_mcp   => 1,
    plugins      => ['+TestPlugin::Configurable' => { my_option => 'winner' }],
    plugin_args => { my_option => 'loser' },
  );
  my $plugin = $raider->plugin_instances->[0];
  is($plugin->my_option, 'winner', 'per-plugin args win over plugin_args');
};

subtest 'plugin_args still work as fallback' => sub {
  my $raider = Langertha::Raider->new(
    engine       => MockEngine->new,
    raider_mcp   => 1,
    plugins      => ['TestPlugin::Configurable'],
    plugin_args => { my_option => 'from_fallback' },
  );
  my $plugin = $raider->plugin_instances->[0];
  is($plugin->my_option, 'from_fallback', 'plugin_args used when no per-plugin args');
};

subtest 'sugar: plugin Name => { args } works' => sub {
  {
    package TestSugarConfigRaider;
    use Langertha qw( Raider );
    plugin '+TestPlugin::Configurable' => { my_option => 'sugar_val' };
    plugin 'TestPlugin::Configurable';
    __PACKAGE__->meta->make_immutable;
  }

  my $raider = TestSugarConfigRaider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
  );
  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 2, 'two instances from sugar');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  is($instances->[0]->my_option, 'sugar_val', 'sugar args applied');
  isa_ok($instances->[1], 'TestPlugin::Configurable');
};

subtest '+ClassName loads directly without prefix search' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['+TestPlugin::Configurable'],
  );
  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 1, 'one instance');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
};

subtest '+ClassName with Name => { args } syntax' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['+TestPlugin::Configurable' => { my_option => 'custom', priority => 5 }],
  );
  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 1, 'one instance');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  is($instances->[0]->my_option, 'custom', 'args applied');
  is($instances->[0]->priority, 5, 'priority set');
};

subtest '+ClassName mixed with short names' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => [
      'TestPlugin::Configurable',
      '+TestPlugin::Configurable' => { my_option => 'from_plus' },
    ],
  );
  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 2, 'two instances');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  isa_ok($instances->[1], 'TestPlugin::Configurable');
  is($instances->[1]->my_option, 'from_plus', 'plus-syntax args applied');
};

subtest 'empty hashref is valid (no extra args)' => sub {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['+TestPlugin::Configurable' => {}],
  );
  my $instances = $raider->plugin_instances;
  is(scalar @$instances, 1, 'one instance');
  isa_ok($instances->[0], 'TestPlugin::Configurable');
  is($instances->[0]->my_option, 'default_val', 'default my_option');
};

done_testing;
