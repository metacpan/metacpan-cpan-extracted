#!/usr/bin/env perl
# ABSTRACT: The application's shell tools: mounted with their effect classes, the permission modes, background shells live across runs and end with the application, a cancelled turn leaves them running
use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Path::Tiny;
use POSIX ();
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::MockAI qw( mock_app );
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::Runner;

clear_engine_env();

my @dirs;    # held: a temporary directory goes when its object does

sub app {
  my ( %arg ) = @_;
  push @dirs, Path::Tiny->tempdir;
  return mock_app( root => $dirs[-1]->realpath->stringify, permission_mode => 'bypassPermissions', %arg );
}

sub results {
  my ( $app ) = @_;
  return [ map {
    +{ name => $_->{tool_call}{name}, error => $_->{result}{isError} ? 1 : 0,
       text => join "\n", map { $_->{text} // '' } @{ $_->{result}{content} // [] } }
  } @{ $app->mock_engine->results } ];
}

sub alive {
  my ( $pid ) = @_;
  return 0 unless kill 0 => $pid;
  my $stat = eval { path( '/proc/'.$pid.'/stat' )->slurp } // return 1;
  return substr( $stat, rindex( $stat, ')' ) + 2, 1 ) ne 'Z';
}

subtest 'bash, bash_output and kill_shell on one server, with their classes' => sub {
  my %tool = map { $_->{name} => $_ } @{ app()->explain_config->{tools} };
  is( $tool{bash},        { name => 'bash',        source => 'engine:2', effects => ['code'] }, 'bash: code' );
  is( $tool{bash_output}, { name => 'bash_output', source => 'engine:2', effects => ['read'] }, 'bash_output: read' );
  is( $tool{kill_shell},  { name => 'kill_shell',  source => 'engine:2', effects => [] },       'kill_shell: none' );
};

subtest 'plan mode: bash is refused, bash_output and kill_shell are not' => sub {
  my $app = app( permission_mode => 'plan', script => [
    { tool_calls => [ [ bash => { command => 'touch ran', run_in_background => JSON::PP::true() } ] ] },
    { tool_calls => [ [ bash_output => { bash_id => 'bash_1' } ], [ kill_shell => { shell_id => 'bash_1' } ] ] },
    { text => 'planned' },
  ] );
  $app->run('look');
  my $r = results($app);
  like( $r->[0], { name => 'bash', error => 1, text => qr/plan mode/ }, 'bash refused, also in the background' );
  ok( !-e path( $app->root )->child('ran'), 'nothing ran' );
  is( [ map { [ $_->{name}, $_->{text} ] } @$r[ 1, 2 ] ],
    [ [ bash_output => 'No task found with ID: bash_1' ], [ kill_shell => 'No task found with ID: bash_1' ] ],
    'the other two reach the tool' );
};

subtest 'default mode with nobody to ask: bash refused, bash_output allowed' => sub {
  my $app = app( permission_mode => 'default', script => [
    { tool_calls => [ [ bash => { command => 'true' } ], [ bash_output => { bash_id => 'bash_1' } ] ] },
    { text => 'ok' },
  ] );
  $app->run('look');
  my $r = results($app);
  like( $r->[0], { error => 1, text => qr/nobody can approve/ }, 'bash asks, and nobody can approve' );
  is( $r->[1]{text}, 'No task found with ID: bash_1', 'bash_output ran' );
};

subtest 'a background shell lives across the runs of a session and ends with the application' => sub {
  my $app = app( script => [
    { tool_calls => [ [ bash => { command => 'echo first; touch started; sleep 300', run_in_background => JSON::PP::true() } ] ] },
    { text => 'started' },
    { tool_calls => [ [ bash_output => { bash_id => 'bash_1' } ] ] },
    { text => 'still running' },
  ] );
  $app->run('start it');
  my ( $pid ) = $app->bash_tools->background_pids;
  ok( $pid && alive($pid), 'running after the run' );
  for ( 1 .. 50 ) { last if -e path( $app->root )->child('started'); select undef, undef, undef, 0.05 }
  $app->run('how is it');
  my $r = results($app);
  is( $r->[1], { name => 'bash_output', error => 0, text => "<status>running</status>\n\n<stdout>\nfirst\n</stdout>" },
    'the next run reads it' );
  undef $app;
  ok( !alive($pid), 'stopped when the application went away' );
};

{
  package T196::App;
  use Moose;
  extends 'Langertha::Raider::CLI';
  sub cancel_run { 1 }
  __PACKAGE__->meta->make_immutable;
}

subtest 'a cancelled turn stops the tool children, not the background shells' => sub {
  push @dirs, Path::Tiny->tempdir;
  my $app = T196::App->new( root => "$dirs[-1]", engine => 'openai', api_key => 'test', trace => 0 );
  $app->bash_tools->bash({ command => 'sleep 300', run_in_background => 1 });
  my ( $shell ) = $app->bash_tools->background_pids;
  my $child = fork // die 'fork: '.$!;
  unless ($child) { open STDOUT, '>', '/dev/null'; open STDERR, '>', '/dev/null'; { exec 'sleep', '300' } POSIX::_exit(127) }
  open my $fh, '>', \my $buf or die $!;
  my $runner = Langertha::Raider::CLI::Runner->new( app => $app, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ) );
  $runner->_current({ t0 => time });
  ok( $runner->cancel_run, 'cancelled' );
  ok( !kill( 0 => $child ), 'the tool child is stopped (and reaped by the runner)' );
  ok( alive($shell), 'the background shell runs on' );
  $app->bash_tools->stop_all;
  ok( !alive($shell), 'until it is stopped' );
};

done_testing;
