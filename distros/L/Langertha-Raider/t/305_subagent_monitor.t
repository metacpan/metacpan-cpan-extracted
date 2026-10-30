#!/usr/bin/env perl
# ABSTRACT: A subagent's monitors end with it, silently; its cron tools are the session's, not its own (ADR 0031, k169)
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
use Test::Raider::MockAI ();
use Test::Raider::SlowAI ();
use Langertha::Raider::CLI;
use Langertha::Raider::Loadguard;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS CLAUDE_CODE_DISABLE_CRON )};

package My::CLI {
  use Moose;
  extends 'Langertha::Raider::CLI';
  has script    => ( is => 'ro', default => sub { [] } );
  has delay     => ( is => 'ro', default => 0 );
  has sub_delay => ( is => 'ro', default => 0 );
  has usage     => ( is => 'ro' );
  sub mock_engine { $_[0]->_engine }
  sub _build_engine { Test::Raider::SlowAI::App::_build_engine(@_) }
  sub build_subagent_engine { Test::Raider::SlowAI::App::build_subagent_engine(@_) }
  __PACKAGE__->meta->make_immutable;
}

package main;

sub cli {
  return My::CLI->new(
    root => ''.Path::Tiny->tempdir->realpath, engine => 'openai', api_key => 'mock', trace => 0, detect => 0,
    permission_mode => 'bypassPermissions',
    loadguard => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
    @_,
  );
}

sub text_of { my ( $m ) = @_; my $c = $m->{content}; ref $c ? join( '', map { $_->{text} // '' } @$c ) : $c // '' }

subtest 'a monitor of a subagent is stopped when the subagent ends, and nobody is told' => sub {
  my $app = cli( script => [
    { tool_calls => [ [ agent => { description => 'Watcher', prompt => 'WATCH' } ] ] },
    { tool_calls => [ [ monitor => { description => 'a log', command => 'echo seen; sleep 30' } ] ] },
    { text => 'I started the watch' },
    { text => 'main done' },
  ] );
  my $outcome = $app->run('go');
  is( "$outcome", 'main done', 'the run finished' );
  my $monitor = $app->tasks->get('monitor_1');
  like( $monitor, { status => 'killed', recipient => 'agent_1' }, 'the monitor was the subagent\'s and has ended with it' );
  is( $app->tasks->pending('main'), 0, 'nothing for the main conversation' );
  is( $app->tasks->pending('agent_1'), 0, 'and nothing left for the ended subagent' );
  ok( !( grep { $_ } map { $_->pid && kill( 0 => $_->pid ) } values %{ $app->bash_tools->_monitors } ), 'no command keeps running' );
};

subtest 'a subagent does not get the cron tools, the main run does' => sub {
  my $app = cli( scheduling => 1, script => [
    { tool_calls => [ [ agent => { description => 'Helper', prompt => 'HELP' } ] ] },
    { text => 'helped' },
    { text => 'main done' },
  ] );
  $app->run('go');
  my @requests = @{ $app->mock_engine->requests };
  my $names = sub { [ sort map { $_->{function}{name} // $_->{name} } @{ $_[0]{tools} // [] } ] };
  ok( ( grep { $_ eq 'cron_create' } @{ $names->( $requests[0] ) } ), 'the main run offers cron_create' );
  ok( ( grep { $_ eq 'monitor' } @{ $names->( $requests[1] ) } ), 'the subagent offers monitor' );
  is( [ grep { /^cron_/ } @{ $names->( $requests[1] ) } ], [], 'but no cron tool' );
};

done_testing;
