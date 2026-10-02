#!/usr/bin/env perl
# ABSTRACT: Unit tests for use Langertha qw( Raider ) and qw( Plugin ) sugar

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Chat;

# Langertha::Raider lives in the langertha-raider distribution. The lazy
# `use Langertha qw( Raider )` sugar still wires it up when it is installed;
# the Raider subtests below are guarded so the core distribution stays green
# without it. The Plugin sugar and the import-error handling are core.
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

# --- Test: use Langertha qw( Plugin ) (core) ---

{
  package TestSugarPlugin;
  use Langertha qw( Plugin );

  has my_attr => (is => 'ro', default => 'works');

  async sub plugin_before_raid {
    my ($self, $messages) = @_;
    push @$messages, { role => 'system', content => 'injected' };
    return $messages;
  }

  __PACKAGE__->meta->make_immutable;
}

{
  package TestPlugin::AlphaSugar;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  async sub plugin_before_raid {
    my ($self, $messages) = @_;
    return $messages;
  }

  __PACKAGE__->meta->make_immutable;
}

subtest 'use Langertha qw( Plugin ) sets up plugin class' => sub {
  ok(TestSugarPlugin->isa('Langertha::Plugin'), 'extends Langertha::Plugin');
  ok(TestSugarPlugin->isa('Moose::Object'), 'is a Moose class');
};

subtest 'sugar-defined plugin works' => sub {
  # A plugin host is any Langertha::Role::PluginHost consumer; Langertha::Chat
  # is a core one, so the plugin hook is exercised without Langertha::Raider.
  my $host = Langertha::Chat->new(engine => MockEngine->new);

  my $plugin = TestSugarPlugin->new(host => $host);
  is($plugin->my_attr, 'works', 'attribute available');

  my $msgs = [{ role => 'user', content => 'hello' }];
  my $result = $plugin->plugin_before_raid($msgs)->get;
  is(scalar @$result, 2, 'plugin modified');
  is($result->[1]{content}, 'injected', 'injection works');
};

# --- Test: invalid import argument (core) ---

subtest 'invalid import argument dies' => sub {
  eval { Langertha->import('Nonsense') };
  like($@, qr/Unknown Langertha import 'Nonsense'/, 'dies with useful error');
};

# --- Test: use Langertha qw( Raider ) sugar (langertha-raider) ---

SKIP: {
  skip 'Langertha::Raider not installed (extracted to langertha-raider)', 6
    unless $has_raider;

  # The Raider-subclass packages call `use Langertha qw( Raider )` at compile
  # time, which pulls in Langertha::Raider; define them via string eval so the
  # file still compiles when that distribution is absent.
  my $setup_ok = eval q{
    package TestSugarRaider {
      use Langertha qw( Raider );
      __PACKAGE__->meta->make_immutable;
    }
    package TestSugarRaiderWithPlugin {
      use Langertha qw( Raider );
      plugin 'TestSugarPlugin';
      __PACKAGE__->meta->make_immutable;
    }
    package TestSugarRaiderCustom {
      use Langertha qw( Raider );
      has custom_flag => (is => 'rw', default => 0);
      __PACKAGE__->meta->make_immutable;
    }
    package TestSugarRaiderMulti {
      use Langertha qw( Raider );
      plugin 'TestPlugin::AlphaSugar';
      plugin 'TestSugarPlugin';
      __PACKAGE__->meta->make_immutable;
    }
    1;
  };
  BAIL_OUT("Raider sugar package setup failed: $@") unless $setup_ok;

  subtest 'use Langertha qw( Raider ) sets up class' => sub {
    ok(TestSugarRaider->isa('Langertha::Raider'), 'extends Langertha::Raider');
    ok(TestSugarRaider->isa('Moose::Object'), 'is a Moose class');

    my $raider = TestSugarRaider->new(
      engine     => MockEngine->new,
      raider_mcp => 1,
    );
    ok($raider->can('raid_f'), 'has raid_f');
    is_deeply($raider->plugins, [], 'no plugins registered');
  };

  subtest 'plugin() sugar registers plugin name' => sub {
    my $raider = TestSugarRaiderWithPlugin->new(
      engine     => MockEngine->new,
      raider_mcp => 1,
    );

    is_deeply($raider->plugins, ['TestSugarPlugin'], 'TestSugarPlugin registered');
    is(scalar @{$raider->_plugin_instances}, 1, 'one instance');
    isa_ok($raider->_plugin_instances->[0], 'TestSugarPlugin');
  };

  subtest 'use Langertha qw( Raider ) allows custom attributes' => sub {
    my $raider = TestSugarRaiderCustom->new(
      engine     => MockEngine->new,
      raider_mcp => 1,
    );
    is($raider->custom_flag, 0, 'custom attribute works');
    $raider->custom_flag(1);
    is($raider->custom_flag, 1, 'attribute writable');
  };

  subtest 'sugar-defined plugin via plugins attribute' => sub {
    my $raider = Langertha::Raider->new(
      engine     => MockEngine->new,
      raider_mcp => 1,
      plugins    => ['TestSugarPlugin'],
    );

    is(scalar @{$raider->_plugin_instances}, 1, 'one instance');
    isa_ok($raider->_plugin_instances->[0], 'TestSugarPlugin');
  };

  subtest 'multiple plugins via sugar' => sub {
    my $raider = TestSugarRaiderMulti->new(
      engine     => MockEngine->new,
      raider_mcp => 1,
    );

    is_deeply($raider->plugins, ['TestPlugin::AlphaSugar', 'TestSugarPlugin'], 'both registered');
    is(scalar @{$raider->_plugin_instances}, 2, 'two instances');
    isa_ok($raider->_plugin_instances->[0], 'TestPlugin::AlphaSugar');
    isa_ok($raider->_plugin_instances->[1], 'TestSugarPlugin');
  };

  subtest 'plugins overridden at instantiation' => sub {
    my $raider = TestSugarRaiderWithPlugin->new(
      engine     => MockEngine->new,
      raider_mcp => 1,
      plugins    => [],  # override: no plugins
    );

    is_deeply($raider->plugins, [], 'override works');
    is(scalar @{$raider->_plugin_instances}, 0, 'no instances');
  };
}

done_testing;
