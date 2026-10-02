#!/usr/bin/env perl
# ABSTRACT: Public plugin-host names a sibling dist builds on instead of core privates (k226)
use strict; use warnings;
use Test2::Bundle::More;

# langertha-raider composes Role::PluginHost and runs its own hook chain: it
# iterates $self->_plugin_instances, calls $self->_plugin_pipeline_tool_call and
# documents the _plugin_args constructor key. These tests pin the public names
# that replace those reach-ins (ADR 0028 pattern), and that the private names
# keep working unchanged until raider has migrated.

use Future;
use Future::AsyncAwait;
use Langertha::Chat;
use Langertha::Plugin;

{
  package MockEngine;
  use Moose;
  with 'Langertha::Role::Tools';
  has chat_model => (is => 'ro', default => 'mock-model');
  has '+mcp_servers' => (default => sub { [] });
  __PACKAGE__->meta->make_immutable;
}

{
  package TestPlugin::Opt;
  use Moose;
  extends 'Langertha::Plugin';
  has my_option => (is => 'ro', default => 'default_val');
  __PACKAGE__->meta->make_immutable;
}

{
  package TestPlugin::Rename;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  has seen => (is => 'ro', default => sub { [] });
  async sub plugin_before_tool_call {
    my ($self, $name, $input) = @_;
    push @{$self->seen}, [ $name, { %$input } ];
    return ("renamed_$name", { %$input, touched => 1 });
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package TestPlugin::Block;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  async sub plugin_before_tool_call {
    my ($self, $name, $input) = @_;
    return if $name =~ /dangerous/;
    return ($name, $input);
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package TestPlugin::Last;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  has calls => (is => 'rw', default => 0);
  async sub plugin_before_tool_call {
    my ($self, $name, $input) = @_;
    $self->calls($self->calls + 1);
    return ($name, $input);
  }
  __PACKAGE__->meta->make_immutable;
}

sub host { Langertha::Chat->new(engine => MockEngine->new, @_) }

subtest 'plugin_instances: public read-only list, private name aliases it' => sub {
  my $chat = host(plugins => ['TestPlugin::Opt', 'TestPlugin::Block']);
  my $instances = $chat->plugin_instances;
  is(ref $instances, 'ARRAY', 'an ArrayRef');
  is(scalar @$instances, 2, 'one instance per spec');
  isa_ok($instances->[0], ['TestPlugin::Opt'], 'order follows plugins');
  isa_ok($instances->[1], ['TestPlugin::Block']);
  is($instances->[0]->host, $chat, 'each plugin gets the host');
  is($chat->plugin_instances, $instances, 'built once, the same list on every read');
  is($chat->_plugin_instances, $instances, '_plugin_instances returns the very same list');
  ok(!eval { $chat->plugin_instances([]); 1 }, 'plugin_instances is read-only');
  is_deeply(host()->plugin_instances, [], 'no plugins: empty list');
};

subtest 'plugin_instances constructor contract: only _plugin_instances injects' => sub {
  # Sibling dists inject prebuilt instances via the private key (k230); the
  # public reader is deliberately not an init_arg, so it must not inject.
  my $injected = TestPlugin::Block->new(host => MockEngine->new);

  my $legacy = host(plugins => ['TestPlugin::Opt'], _plugin_instances => [ $injected ]);
  is(scalar @{$legacy->plugin_instances}, 1, '_plugin_instances: exactly the injected list');
  is($legacy->plugin_instances->[0], $injected, '_plugin_instances injects the given instance, plugins not built');

  my $public = host(plugins => ['TestPlugin::Opt'], plugin_instances => [ $injected ]);
  is(scalar @{$public->plugin_instances}, 1, 'plugin_instances key: list built from plugins');
  isa_ok($public->plugin_instances->[0], ['TestPlugin::Opt'], 'plugin_instances key is ignored, not injected');
  isnt($public->plugin_instances->[0], $injected, 'the passed instance is not used');
};

subtest 'plugin_args: public constructor key, _plugin_args still accepted' => sub {
  my $public = host(plugins => ['TestPlugin::Opt'], plugin_args => { my_option => 'public' });
  is($public->plugin_instances->[0]->my_option, 'public', 'plugin_args reaches the plugin constructor');
  is_deeply($public->plugin_args, { my_option => 'public' }, 'plugin_args reader');
  is_deeply($public->_plugin_args, { my_option => 'public' }, '_plugin_args reader aliases it');

  my $legacy = host(plugins => ['TestPlugin::Opt'], _plugin_args => { my_option => 'legacy' });
  is($legacy->plugin_instances->[0]->my_option, 'legacy', 'the old _plugin_args key still works');
  is_deeply($legacy->plugin_args, { my_option => 'legacy' }, 'and shows up under the public reader');

  my $both = host(plugins => ['TestPlugin::Opt'],
    plugin_args => { my_option => 'public' }, _plugin_args => { my_option => 'legacy' });
  is($both->plugin_instances->[0]->my_option, 'public', 'plugin_args wins when both are given');

  my $per = host(plugins => ['TestPlugin::Opt' => { my_option => 'per_plugin' }],
    plugin_args => { my_option => 'shared' });
  is($per->plugin_instances->[0]->my_option, 'per_plugin', 'per-plugin args win over plugin_args');

  is_deeply(host()->plugin_args, {}, 'defaults to an empty HashRef');
};

subtest 'plugin_pipeline_tool_call_f: chains plugin_before_tool_call in order' => sub {
  my $chat = host(plugins => ['TestPlugin::Rename', 'TestPlugin::Last']);
  my $f = $chat->plugin_pipeline_tool_call_f('search', { q => 'x' });
  isa_ok($f, ['Future'], 'returns a Future');
  my ($name, $input) = $f->get;
  is($name, 'renamed_search', 'the last plugin sees and returns the rewritten name');
  is_deeply($input, { q => 'x', touched => 1 }, 'the rewritten input is passed on');
  is_deeply($chat->plugin_instances->[0]->seen, [[ 'search', { q => 'x' } ]],
    'the first plugin saw the original call');
  is($chat->plugin_instances->[1]->calls, 1, 'the second plugin ran once');
};

subtest 'plugin_pipeline_tool_call_f: an empty list skips the call and stops the chain' => sub {
  my $chat = host(plugins => ['TestPlugin::Block', 'TestPlugin::Last']);
  my @ok = $chat->plugin_pipeline_tool_call_f('safe_tool', { x => 1 })->get;
  is_deeply(\@ok, [ 'safe_tool', { x => 1 } ], 'an allowed call passes through');
  my @skipped = $chat->plugin_pipeline_tool_call_f('dangerous_tool', { x => 1 })->get;
  is(scalar @skipped, 0, 'a blocked call resolves to the empty list');
  is($chat->plugin_instances->[1]->calls, 1, 'plugins after the blocker are not asked');
};

subtest 'plugin_pipeline_tool_call_f: no plugins returns the arguments unchanged' => sub {
  my @call = host()->plugin_pipeline_tool_call_f('t', { a => 1 })->get;
  is_deeply(\@call, [ 't', { a => 1 } ], 'identity');
};

subtest '_plugin_pipeline_tool_call: private alias behaves the same' => sub {
  my $chat = host(plugins => ['TestPlugin::Block']);
  my $f = $chat->_plugin_pipeline_tool_call('safe_tool', { x => 1 });
  isa_ok($f, ['Future'], 'still returns a Future');
  is_deeply([ $f->get ], [ 'safe_tool', { x => 1 } ], 'same result as the public method');
  is(scalar(() = $chat->_plugin_pipeline_tool_call('dangerous_tool', {})->get), 0,
    'same skip semantics');
};

done_testing;
