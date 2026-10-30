#!/usr/bin/env perl
# ABSTRACT: A subagent inherits the caller's permission policy through for_subrun; the agent call itself is gated by the caller's (ADR 0020 §4, ADR 0021, k153)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Path::Tiny;
use Scalar::Util qw( refaddr );
use Test::Raider::MockAI qw( mock_app );
use Langertha::Raider::Subagent;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

my @tmp;   # the temporary directories live as long as the test
sub root { push @tmp, Path::Tiny->tempdir; $tmp[-1]->realpath }

our @SEEN;
{
  # Records the subagents the agent tool would start, without running them.
  package Test::Raider::Subagent::Spy;
  use Moose;
  extends 'Langertha::Raider::Subagent';
  sub foreground_f { push @main::SEEN, $_[0]; return Future->done( 'spied', 0 ) }
  __PACKAGE__->meta->make_immutable;
}

sub child {
  my ( $app, %o ) = @_;
  return Langertha::Raider::Subagent->new(
    app             => $app,
    agent           => { name => 'x', description => 'x', body => 'X', tools => undef, disallowed => [] },
    depth           => $o{depth} // 1,
    prompt          => 'do it',
    caller_servers  => $app->_tool_servers,
    on_caller_event => sub { },
    ( $o{policy} ? ( caller_policy => $o{policy} ) : () ),
  );
}

# A run whose subagent writes child.txt; returns the app, its events and
# the session.
sub run_writing_child {
  my ( %o ) = @_;
  my @events;
  my $app = mock_app(
    root     => $o{root} // ''.root(),
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script   => [
      { tool_calls => [ [ agent => { description => 'd', prompt => 'write it' } ] ] },
      { tool_calls => [ [ write_file => { path => 'child.txt', content => 'c' } ] ] },
      { text => 'child answer' },
      { text => 'parent answer' },
    ],
    %{ $o{app} // {} },
  );
  my $session = $app->create_session;
  my $outcome = $app->run_prompt( 'go', session => $session );
  is( $outcome->{status}, 'completed', 'the run completes' );
  return ( $app, \@events, $session );
}

# The tool result of the subagent's write_file.
sub child_write_result {
  my ( $app ) = @_;
  my ($r) = grep { $_->{tool_call}{name} eq 'write_file' } @{ $app->mock_engine->results };
  return ( join( "\n", map { $_->{text} // '' } @{ $r->{result}{content} // [] } ), !!$r->{result}{isError} );
}

sub child_events {
  my ( $app, $events ) = @_;
  my ($started) = grep { $_->{type} eq 'agent.started' } @$events;
  return $app->session_store->read( $started->{session} )->events;
}

subtest 'the policy: for_subrun of the caller\'s' => sub {
  my $app = mock_app( root => ''.root(), permission_mode => 'acceptEdits', max_agent_depth => 2 );
  my $parent = $app->permissions;
  my $sub = child($app);
  my $p = $sub->permissions;
  isnt( refaddr $p, refaddr $parent, 'a policy of its own' );
  is( [ $p->mode, $p->mode_source ], [ q(acceptEdits), $parent->mode_source ], 'the caller\'s mode and its source' );
  is( refaddr $p->session_rules, refaddr $parent->session_rules, 'the same session rules array' );
  is( refaddr $p->rules, refaddr $parent->rules, 'the same configured rules' );
  is( $p->root, $parent->root, 'the same root' );

  $p->set_mode( 'plan', 'test' );
  is( $parent->mode, 'acceptEdits', 'a mode change of the child stays with the child' );
  my $grandchild = child( $app, depth => 2, policy => $p );
  is( $grandchild->permissions->mode, 'plan', 'a nested subagent inherits from its caller, not from the main run' );
  is( refaddr $grandchild->permissions->session_rules, refaddr $parent->session_rules, 'session rules still shared' );

  $parent->set_mode( 'bypassPermissions', 'later' );
  is( child($app)->permissions->mode, 'bypassPermissions', 'the mode the caller has when the call starts' );
  is( $p->mode, 'plan', 'a running child keeps its own' );
};

subtest 'the agent tool hands its policy to the subagent' => sub {
  my $app = mock_app( root => ''.root(), permission_mode => 'plan' );
  my $server = Test::Raider::Subagent::Spy->agent_tool_server( app => $app, depth => 0, caller => sub { {
    servers => $app->_tool_servers, session => undef, call => 'c1', event => sub { },
    policy  => $app->permissions,
  } } );
  my ($tool) = grep { $_->name eq 'agent' } @{ $server->tools };
  $tool->call( { description => 'd', prompt => 'p' }, {} );
  is( scalar @SEEN, 1, 'spawned' );
  is( refaddr $SEEN[0]->caller_policy, refaddr $app->permissions, 'with the caller\'s policy' );
  is( $SEEN[0]->permissions->mode, 'plan', 'and so its mode' );
};

subtest 'default mode, nobody to ask: the child refuses a write as the parent would' => sub {
  my ( $app, $events ) = run_writing_child( app => { permission_mode => 'default' } );
  ok( !-e path( $app->root, 'child.txt' ), 'nothing written' );
  my ( $text, $is_error ) = child_write_result($app);
  ok( $is_error, 'an error result' );
  is( [ grep { $_->{type} eq 'permission.denied' } @$events ], [], 'no permission.denied in the caller\'s stream' );
  my $parent = $app->_permission_gate( { name => 'write_file', source => 'engine:0',
    arguments => { path => 'child.txt', content => 'c' } } );
  is( $parent->{verdict}, 'deny', 'the parent refuses the same call' );
  like( $text, qr/\Q$parent->{reason}\E/, 'with the same reason' );
  my @child = @{ child_events( $app, $events ) };
  like( [ grep { $_->{type} eq 'permission.denied' } @child ],
    [ { tool => 'write_file', by => 'noninteractive', mode => 'default' } ], 'permission.denied in the child journal' );};

subtest 'bypassPermissions: the child writes' => sub {
  my ( $app ) = run_writing_child( app => { permission_mode => 'bypassPermissions' } );
  is( path( $app->root, 'child.txt' )->slurp_utf8, 'c', 'written' );
};

subtest 'a deny rule Write in the Claude settings holds in the child, bypassPermissions or not' => sub {
  my $root = root();
  $root->child('CLAUDE.md')->spew_utf8("Project.\n");
  $root->child('.claude/settings.json')->touchpath->spew_utf8('{ "permissions": { "deny": [ "Write" ] } }');
  my ( $app ) = run_writing_child( root => "$root", app => { permission_mode => 'bypassPermissions' } );
  ok( !-e $root->child('child.txt'), 'nothing written' );
  my ( $text, $is_error ) = child_write_result($app);
  ok( $is_error, 'an error result' );
  like( $text, qr/denied by rule 'Write' from \.claude\/settings\.json/, 'the rule and its source' );
};

subtest 'a session rule allowed in the child holds for the parent, and one of the parent for the child' => sub {
  my @asked;
  my ( $app ) = run_writing_child( app => {
    permission_mode       => 'default',
    on_permission_request => sub { push @asked, $_[0]; { answer => 'session' } },
  } );
  is( path( $app->root, 'child.txt' )->slurp_utf8, 'c', 'the child wrote after the person allowed it' );
  like( \@asked, [ { tool => 'write_file', rule => 'Edit(/**)', arguments => { path => 'child.txt' } } ],
    'the person was asked once, for the child\'s call' );
  is( [ map { $_->text } @{ $app->permissions->session_rules } ], ['Edit(/**)'], 'the parent policy has the rule' );
  is( $app->permissions->decide( { name => 'write_file', source => 'engine:0', arguments => { path => 'other.txt' } } )->{verdict},
    'allow', 'and allows the parent\'s write without asking' );

  my $fresh = mock_app( root => ''.root(), permission_mode => 'default' );
  $fresh->permissions->add_session_rule('Bash(make)');
  is( child($fresh)->permissions->decide( { name => 'bash', source => 'engine:1', arguments => { command => 'make' } } )->{verdict},
    'allow', 'a session rule of the parent holds in a child started later' );
};

subtest 'an approval once binds the child\'s own session and run' => sub {
  my @asked;
  my ( $app, $events ) = run_writing_child( app => {
    permission_mode       => 'default',
    on_permission_request => sub { push @asked, $_[0]; { answer => 'once' } },
  } );
  is( path( $app->root, 'child.txt' )->slurp_utf8, 'c', 'written once' );
  is( scalar @asked, 1, 'asked once' );
  my @child = @{ child_events( $app, $events ) };
  like( [ grep { $_->{type} eq 'permission.granted' } @child ], [ { tool => 'write_file', scope => 'once' } ],
    'permission.granted in the child journal' );
  is( [ map { $_->text } @{ $app->permissions->session_rules } ], [], 'no session rule' );

  my $sub = child( mock_app( root => ''.root() ) );
  is( [ $sub->approval_binding ], [], 'without a session: the application\'s stand-ins' );
};

subtest 'the agent call is gated by the caller\'s policy' => sub {
  my $call = sub { +{ name => 'agent', source => 'engine:5', arguments => { description => 'd', prompt => 'p', @_ } } };
  my $root = root();
  my $app = mock_app( root => "$root", permission_mode => 'default' );
  is( $app->permissions->decide( $call->( subagent_type => 'reader' ) )->{verdict}, 'allow',
    'no rule: starting a subagent needs no approval, in default mode' );
  my $plan = mock_app( root => ''.root(), permission_mode => 'plan' );
  is( $plan->permissions->decide( $call->() )->{verdict}, 'allow', 'nor in plan mode' );

  $root->child('.raider/config.yml')->touchpath->spew_utf8(
    "permissions:\n  deny: [ 'Agent(reader)', 'Task(general-purpose)' ]\n  ask: [ 'Agent(writer)' ]\n" );
  my $ruled = mock_app( root => "$root", permission_mode => 'bypassPermissions' );
  my $p = $ruled->permissions;
  like( $p->decide( $call->( subagent_type => 'reader' ) ), { verdict => 'deny', rule => 'Agent(reader)' },
    'Agent(reader) denies that agent' );
  is( $p->decide( $call->( subagent_type => 'other' ) )->{verdict}, 'allow', 'but not another' );
  like( $p->decide( $call->() ), { verdict => 'deny', rule => 'Task(general-purpose)' },
    'a call without subagent_type counts as general-purpose' );
  like( $p->decide( $call->( subagent_type => '' ) ), { verdict => 'deny' }, 'so does an empty one' );

  my $asking = mock_app( root => "$root", permission_mode => 'default' );
  my $v = $asking->_permission_gate( $call->( subagent_type => 'writer' ) );
  like( $v, { verdict => 'deny', by => 'noninteractive' }, 'an ask rule with nobody to ask refuses the spawn' );
};

done_testing;
