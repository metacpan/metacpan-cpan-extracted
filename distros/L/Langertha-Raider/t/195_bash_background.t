#!/usr/bin/env perl
# ABSTRACT: Background shells: run_in_background, bash_output (status, new output, filter, block), kill_shell, the loop reaps them, none outlives its owner
use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Path::Tiny;
use Langertha::Raider::BashTools;

my $loop = IO::Async::Loop->new;
my @dirs;    # held: a temporary directory goes when its object does

sub shell_tools {
  my ( %arg ) = @_;
  push @dirs, Path::Tiny->tempdir;
  return Langertha::Raider::BashTools->new( loop => $loop, working_directory => $dirs[-1]->stringify, kill_grace => 1, %arg );
}

sub tool {
  my ( $tools, $tool, %in ) = @_;
  my ( $text, $is_error ) = $tools->$tool( \%in );
  return { text => $text, error => $is_error ? 1 : 0 };
}

sub alive {
  my ( $pid ) = @_;
  return 0 unless kill 0 => $pid;
  my $stat = eval { path( '/proc/'.$pid.'/stat' )->slurp } // return 1;
  return substr( $stat, rindex( $stat, ')' ) + 2, 1 ) ne 'Z';
}

sub wait_until {
  my ( $cond ) = @_;
  for ( 1 .. 100 ) { return 1 if $cond->(); select undef, undef, undef, 0.05 }
  return 0;
}

subtest 'run_in_background answers at once with the ID' => sub {
  my $t = shell_tools();
  my $start = time;
  my $r = tool( $t, bash => command => 'sleep 5; echo late', run_in_background => 1 );
  ok( time - $start < 3, 'did not wait for it' );
  is( $r, { error => 0, text =>
    'Command running in background with ID: bash_1. Read its output and see whether it has finished with '
    .'bash_output (bash_id: bash_1); stop it with kill_shell (shell_id: bash_1).' }, "Claude Code's text with raider's tools" );
  is( tool( $t, bash => command => 'true', run_in_background => 1 )->{text}, match qr/ID: bash_2\./, 'IDs count up' );
  $t->stop_all;
};

subtest 'bash_output: only what is new, the status, the exit code' => sub {
  my $t = shell_tools();
  my $dir = path( $t->working_directory );
  tool( $t, bash => command => 'echo one; echo two >&2; while [ ! -e go ]; do sleep 0.05; done; echo three; exit 4', run_in_background => 1 );
  ok( wait_until( sub { tool( $t, bash_output => bash_id => 'bash_1' )->{text} =~ /two/ } ), 'first output arrives' )
    or return;
  $dir->child('go')->touch;
  my $r = tool( $t, bash_output => bash_id => 'bash_1', block => 1, timeout => 10 );
  is( $r, { error => 0, text => "<status>completed</status>\n\n<exit_code>4</exit_code>\n\n<stdout>\nthree\n</stdout>" },
    'the rest, the exit code; a failed command is not an error of bash_output' );
  is( tool( $t, bash_output => bash_id => 'bash_1' ),
    { error => 0, text => "<status>completed</status>\n\n<exit_code>4</exit_code>" }, 'nothing new: no stdout block' );
};

subtest 'bash_output while running' => sub {
  my $t = shell_tools();
  tool( $t, bash => command => 'echo started; sleep 30', run_in_background => 1 );
  my $text;
  ok( wait_until( sub { ( $text = tool( $t, bash_output => bash_id => 'bash_1' )->{text} ) =~ /started/ } ), 'output while it runs' );
  is( $text, "<status>running</status>\n\n<stdout>\nstarted\n</stdout>", 'running, no exit code' );
  is( tool( $t, bash_output => bash_id => 'bash_1' )->{text}, '<status>running</status>', 'nothing new' );
  my $start = time;
  is( tool( $t, bash_output => bash_id => 'bash_1', block => 1, timeout => 1 )->{text}, '<status>running</status>',
    'block gives up after its timeout' );
  ok( time - $start < 5, 'and does not wait longer' );
  $t->stop_all;
};

subtest 'filter keeps the matching lines, the others are gone' => sub {
  my $t = shell_tools();
  tool( $t, bash => command => 'for i in 1 2 3 4 5; do echo line$i; done', run_in_background => 1 );
  is( tool( $t, bash_output => bash_id => 'bash_1', block => 1, filter => 'line[24]' )->{text},
    "<status>completed</status>\n\n<exit_code>0</exit_code>\n\n<stdout>\nline2\nline4\n</stdout>", 'only matches' );
  is( tool( $t, bash_output => bash_id => 'bash_1' )->{text}, "<status>completed</status>\n\n<exit_code>0</exit_code>",
    'the rest was read' );
  like( tool( $t, bash_output => bash_id => 'bash_1', filter => '(' ), { error => 1, text => qr/\AInvalid filter regex: / },
    'a broken regex is an error' );
};

subtest 'unknown IDs' => sub {
  my $t = shell_tools();
  is( tool( $t, bash_output => bash_id => 'bash_9' ), { error => 1, text => 'No task found with ID: bash_9' }, 'bash_output' );
  is( tool( $t, kill_shell => shell_id => 'bash_9' ), { error => 1, text => 'No task found with ID: bash_9' }, 'kill_shell' );
  tool( $t, bash => command => 'echo fg' );
  is( tool( $t, bash_output => bash_id => 'bash_1' )->{error}, 1, 'a foreground command is no background shell' );
};

subtest 'kill_shell stops the whole process group' => sub {
  my $t = shell_tools();
  my $pidfile = path( $t->working_directory )->child('inner.pid');
  tool( $t, bash => command => 'sleep 300 & echo $! > inner.pid; wait', run_in_background => 1 );
  ok( wait_until( sub { -s $pidfile } ), 'the inner process runs' ) or return;
  my ( $inner ) = $pidfile->slurp =~ /(\d+)/;
  my ( $outer ) = $t->background_pids;
  is( tool( $t, kill_shell => shell_id => 'bash_1' ),
    { error => 0, text => 'Successfully stopped task: bash_1 (sleep 300 & echo $! > inner.pid; wait)' }, "TaskStop's text" );
  ok( !alive($outer), 'the shell is gone' );
  ok( wait_until( sub { !alive($inner) } ), 'and what it started' );
  is( [ $t->background_pids ], [], 'none running' );
  is( tool( $t, bash_output => bash_id => 'bash_1' )->{text}, '<status>killed</status>', 'status killed' );
  is( tool( $t, kill_shell => shell_id => 'bash_1' ),
    { error => 1, text => 'Task bash_1 is not running (status: killed)' }, 'a second kill' );
};

subtest 'kill_shell escalates to SIGKILL' => sub {
  my $t = shell_tools();
  my $ready = path( $t->working_directory )->child('ready');
  tool( $t, bash => command => q{trap '' TERM; touch ready; while :; do sleep 0.1; done}, run_in_background => 1 );
  ok( wait_until( sub { -e $ready } ), 'ignores TERM' ) or return;
  my ( $pid ) = $t->background_pids;
  is( tool( $t, kill_shell => shell_id => 'bash_1' )->{error}, 0, 'stopped' );
  ok( !alive($pid), 'after the grace period, by SIGKILL' );
};

subtest 'kill_shell on a finished shell' => sub {
  my $t = shell_tools();
  tool( $t, bash => command => 'true', run_in_background => 1 );
  tool( $t, bash_output => bash_id => 'bash_1', block => 1 );
  is( tool( $t, kill_shell => shell_id => 'bash_1' ),
    { error => 1, text => 'Task bash_1 is not running (status: completed)' }, 'not running' );
};

subtest 'the loop reaps a background shell that ends' => sub {
  my $t = shell_tools();
  tool( $t, bash => command => 'exit 7', run_in_background => 1 );
  my ( $pid ) = $t->background_pids;
  $loop->delay_future( after => 0.3 )->get;    # the loop runs, as during a model request
  ok( !kill( 0 => $pid ), 'no zombie left: reaped by the loop' );
  is( [ $t->background_pids ], [], 'and known to have ended' );
  is( tool( $t, bash_output => bash_id => 'bash_1' )->{text}, "<status>completed</status>\n\n<exit_code>7</exit_code>",
    'with its exit code' );
};

subtest 'no background shell outlives its owner' => sub {
  my $t = shell_tools();
  tool( $t, bash => command => 'sleep 300', run_in_background => 1 );
  tool( $t, bash => command => 'sleep 300', run_in_background => 1 );
  my @pids = $t->background_pids;
  is( scalar @pids, 2, 'two running' );
  undef $t;
  ok( !( grep { alive($_) } @pids ), 'both stopped when it went away' );
};

done_testing;
