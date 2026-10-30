#!/usr/bin/env perl
# ABSTRACT: The REPL runs the prompt of a due cron job as a turn of its own when idle, never in a running turn (ADR 0031, k169)
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
use IO::Handle;
use POSIX ();
use Path::Tiny;
use Test::Raider::MockAI ();
use Test::Raider::SlowAI ();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;
use Langertha::Raider::CronTools;
use Langertha::Raider::Loadguard;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS CLAUDE_CODE_DISABLE_CRON )};
$ENV{TZ} = 'UTC';
POSIX::tzset();

# The wall clock of the cron jobs, moved by the tests.
our $NOW = POSIX::mktime( 0, 3, 10, 20, 9, 126, -1 );

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
  # The scheduler on the clock of the test, looking often.
  sub _build_cron_tools {
    my ( $self ) = @_;
    return Langertha::Raider::CronTools->new(
      loop => $self->loop, tasks => $self->tasks, recipient => $self->cron_queue,
      clock => sub { $main::NOW }, tick_interval => 0.02,
    );
  }
  __PACKAGE__->meta->make_immutable;
}

package main;

sub root { my $dir = Path::Tiny->tempdir; $dir->realpath }

sub cli {
  return My::CLI->new(
    root => ''.root(), engine => 'openai', api_key => 'mock', trace => 0, detect => 0,
    scheduling => 1, permission_mode => 'bypassPermissions',
    loadguard => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
    @_,
  );
}

sub text_of { my ( $m ) = @_; my $c = $m->{content}; ref $c ? join( '', map { $_->{text} // '' } @$c ) : $c // '' }

sub repl {
  my ( $app, %o ) = @_;
  pipe my $r, my $w or die $!;
  $w->autoflush(1);
  my $out = '';
  open my $fh, '>', \$out or die $!;
  my $repl = Langertha::Raider::CLI::REPL->new(
    app => $app, in => $r, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ),
    session_store => $app->session_store, %o,
  );
  return ( $repl, $w, sub { $out } );
}

subtest 'a job that comes due while the REPL is idle runs as a turn of its own' => sub {
  my $w;
  my $app = cli(
    script => [
      { tool_calls => [ [ cron_create => { cron => '* * * * *', prompt => 'ping job', recurring => \0 } ] ] },
      { text => 'scheduled' },
      { text => 'pong' },
    ],
    on_event => sub {
      my ( $type, %p ) = @_;
      # The run is over: the minute passes while the REPL waits for input.
      $main::NOW += 120 if $type eq 'message' && ( $p{content} // '' ) eq 'scheduled';
      close $w if $w && $type eq 'message' && ( $p{content} // '' ) eq 'pong';
    },
  );
  ( my $repl, $w, my $out ) = repl($app);
  print {$w} "go\n";
  $repl->run;
  like( $out->(), qr/scheduled.*^scheduled job cron_1 \(\* \* \* \* \*\)\n.*pong/ms, 'a meta line names the job, then its turn' );
  my @requests = @{ $app->mock_engine->requests };
  is( scalar @requests, 3, 'the prompt, the tool round and the job\'s turn' );
  like( text_of( $requests[2]{messages}[-1] ), qr/\Aping job\z|ping job\z/, 'the model got the job\'s prompt as the user message' );
  unlike( text_of( $requests[2]{messages}[-1] ), qr/task-notification|system-reminder/, 'a plain prompt, no notification' );
  my $runs = $app->session_store->read( $repl->session->id )->runs;
  is( [ map { $_->{prompt} } @$runs ], [ 'go', 'ping job' ], 'journaled as a run with that prompt' );
  is( $app->tasks->get('cron_1')->{status}, 'completed', 'the one-shot job is done' );
  is( $app->scheduled_pending, 0, 'nothing left waiting' );
};

subtest 'a job that comes due during a turn waits for the turn to end' => sub {
  my $w;
  my $app = cli(
    delay  => 0.05,
    script => [
      { tool_calls => [ [ cron_create => { cron => '* * * * *', prompt => 'ping job', recurring => \0 } ] ] },
      { tool_calls => [ [ cron_list => {} ] ] },
      { text => 'first turn done' },
      { text => 'job answered' },
    ],
    on_event => sub {
      my ( $type, %p ) = @_;
      # The minute passes in the middle of the turn, while its model request is on the loop.
      $main::NOW += 120 if $type eq 'tool.result' && ( $p{name} // '' ) eq 'cron_create';
      close $w if $w && $type eq 'message' && ( $p{content} // '' ) eq 'job answered';
    },
  );
  ( my $repl, $w, my $out ) = repl($app);
  print {$w} "go\n";
  $repl->run;
  my @requests = @{ $app->mock_engine->requests };
  is( scalar @requests, 4, 'three requests in the first turn, one for the job' );
  for my $i ( 1, 2 ) {
    ok( ( grep { text_of($_) eq 'ping job' } @{ $requests[$i]{messages} } ) ? 0 : 1, "request $i of the first turn does not carry it" );
  }
  is( text_of( $requests[3]{messages}[-1] ), 'ping job', 'the job\'s prompt is the last request, after the turn' );
  like( $out->(), qr/first turn done.*^scheduled job cron_1.*job answered/ms, 'the job ran after the first turn' );
};

subtest 'a recurring job comes again; stopping the REPL deletes the jobs' => sub {
  my $w;
  my $count = 0;
  my $app = cli(
    script => [
      { tool_calls => [ [ cron_create => { cron => '*/10 * * * *', prompt => 'again' } ] ] },
      { text => 'scheduled' },
      { text => 'one' },
      { text => 'two' },
    ],
    on_event => sub {
      my ( $type, %p ) = @_;
      my $content = $p{content} // '';
      $main::NOW += 3600 if $type eq 'message' && ( $content eq 'scheduled' || $content eq 'one' );
      close $w if $w && $type eq 'message' && $content eq 'two';
    },
  );
  ( my $repl, $w, my $out ) = repl($app);
  print {$w} "go\n";
  $repl->run;
  is( scalar @{ $app->mock_engine->requests }, 4, 'twice it fired' );
  is( $app->tasks->get('cron_1')->{fires}, 2, 'counted' );
  my $timer = $app->cron_tools->_timer;
  $app->tasks->stop_all;
  is( $app->tasks->get('cron_1')->{status}, 'killed', 'leaving raider ends the job' );
  ok( !$app->cron_tools->_timer, 'and stops the timer' );
};

subtest 'without scheduling the REPL has no cron tools and fires nothing' => sub {
  my $app = cli( scheduling => 0, script => [ { text => 'hi' } ] );
  my ( $repl, $w ) = repl($app);
  print {$w} "go\n";
  close $w;
  $repl->run;
  my @offered = map { $_->{function}{name} // $_->{name} } @{ $app->mock_engine->requests->[0]{tools} // [] };
  ok( ( grep { $_ eq 'monitor' } @offered ), 'the request does offer tools (monitor)' );
  is( [ grep { /^cron_/ } @offered ], [], 'but not the cron tools' );
};

done_testing;
