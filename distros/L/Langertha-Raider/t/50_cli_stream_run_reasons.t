#!/usr/bin/env perl
# ABSTRACT: Why a run ended: the reason codes of run.finished and the --json document (ADR 0034 §2, k172)
use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Raider::Env qw( clear_engine_env isolate_home );
BEGIN { isolate_home() }
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use JSON::MaybeXS ();
use Path::Tiny;
use Test::Raider::MockAI qw( mock_app );
use Test::Raider::SlowAI ();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;

clear_engine_env();
delete @ENV{qw( RAIDER_HALL_SOCKET RAIDER_PACK_DIRS CLAUDE_CONFIG_DIR )};

package My::CLI {
  use Moose;
  extends 'Langertha::Raider::CLI';
  our @SCRIPT;
  has script    => ( is => 'ro', default => sub { [@SCRIPT] } );
  has delay     => ( is => 'ro', default => 0 );
  has sub_delay => ( is => 'ro', default => 0 );
  has usage     => ( is => 'ro' );
  sub mock_engine { $_[0]->_engine }
  sub _build_engine { Test::Raider::SlowAI::App::_build_engine(@_) }
  sub build_subagent_engine { Test::Raider::SlowAI::App::build_subagent_engine(@_) }
  __PACKAGE__->meta->make_immutable;
}

package My::Main {
  use Moose;
  extends 'Langertha::Raider::CLI::Main';
  sub app_class { 'My::CLI' }
  __PACKAGE__->meta->make_immutable;
}

# An application that takes any run model, and cannot build an engine for it.
package My::NoModelApp {
  use Moose;
  extends 'Test::Raider::MockAI::App';
  sub resolve_run_model { { model => $_[1] } }
  sub build_subagent_engine { die "no engine for that model\n" }
  __PACKAGE__->meta->make_immutable;
}

package main;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my @keep;
sub root { my $dir = Path::Tiny->tempdir; push @keep, $dir; return $dir->realpath }

sub stream {
  my ( $root, $script, @argv ) = @_;
  local @My::CLI::SCRIPT = @$script;
  my ( $out, $err ) = ( '', '' );
  open my $ofh, '>', \$out or die $!;
  open my $efh, '>', \$err or die $!;
  open my $in, '<', \'' or die $!;
  my $exit = My::Main->new(
    output => Langertha::Raider::CLI::Output->new( out => $ofh, color => 0 ),
    err    => $efh,
    in     => $in,
  )->run( '-r', "$root", '-e', 'openai', '-k', 'mock', '--no-trace', '--dangerously-skip-permissions', @argv, '-p', 'go' );
  my $events = grep( { $_ eq '--json' } @argv ) ? [ $json->decode($out) ] : [ map { $json->decode($_) } split /\n/, $out ];
  return ( $exit, $events, $err );
}

sub claude_project {
  my ( %a ) = @_;
  my $root = root();
  $root->child('.claude')->mkpath;
  $root->child('.claude/settings.json')->spew_raw( $json->encode({ hooks => $a{hooks} }) );
  for my $name ( keys %{ $a{scripts} } ) {
    my $f = $root->child( 'hooks', $name );
    $f->touchpath->spew_raw( "#!/bin/sh\n".$a{scripts}{$name}."\n" );
    $f->chmod(0755);
  }
  return $root;
}

sub hook { my ( $cmd, %group ) = @_; return { hooks => [ { type => 'command', command => $cmd } ], %group } }

sub journal { my ( $path ) = @_; return [ map { $json->decode($_) } path($path)->lines_raw({ chomp => 1 }) ] }

subtest 'max_iterations: the loop cap, its text unchanged' => sub {
  my ( $exit, $events ) = stream( root(), [
    { tool_calls => [ [ list_files => {} ] ] },
    { tool_calls => [ [ list_files => {} ] ] },
    { text => 'never' },
  ], '--stream-json', '--max-iterations', '1' );
  is( $exit, 1, 'exits 1' );
  like( $events->[-1], { type => 'run.finished', status => 'failed', reason => 'max_iterations',
    error => qr/\ARaider tool loop exceeded 1 iterations/ }, 'run.finished: reason max_iterations, error the human text' );
  like( journal( $events->[-1]{session}{path} )->[-1], { type => 'run.finished', reason => 'max_iterations' }, 'and so does the journal' );
};

subtest 'engine_error: the model request failed' => sub {
  my ( $exit, $events ) = stream( root(), [ { error => [ 500, 'the provider broke' ] } ], '--stream-json' );
  is( $exit, 1, 'exits 1' );
  like( $events->[-1], { status => 'failed', reason => 'engine_error', error => T() }, 'reason engine_error' );
  my ( undef, $doc ) = stream( root(), [ { error => [ 500, 'the provider broke' ] } ], '--json' );
  like( $doc->[0], { status => 'failed', reason => 'engine_error' }, '--json: the same document' );
};

subtest 'hook_blocked, hook_stopped' => sub {
  my $blocked = claude_project(
    hooks   => { UserPromptSubmit => [ hook('${CLAUDE_PROJECT_DIR}/hooks/no') ] },
    scripts => { no => 'cat >/dev/null; echo "not this prompt" >&2; exit 2' },
  );
  my ( $exit, $events ) = stream( $blocked, [ { text => 'never' } ], '--stream-json' );
  like( $events->[-1], { status => 'failed', reason => 'hook_blocked', error => qr/blocked by a UserPromptSubmit hook: not this prompt/ },
    'a UserPromptSubmit block: failed, hook_blocked' );

  my $started = claude_project(
    hooks   => { SessionStart => [ hook('${CLAUDE_PROJECT_DIR}/hooks/stop') ] },
    scripts => { stop => 'cat >/dev/null; echo \'{"continue":false,"stopReason":"closed"}\'' },
  );
  ( $exit, $events ) = stream( $started, [ { text => 'never' } ], '--stream-json' );
  like( $events->[-1], { status => 'failed', reason => 'hook_stopped', error => qr/SessionStart hook stopped/ },
    'a SessionStart stop: failed, hook_stopped' );

  my $tool = claude_project(
    hooks   => { PreToolUse => [ hook( '${CLAUDE_PROJECT_DIR}/hooks/stop', matcher => 'Bash' ) ] },
    scripts => { stop => 'cat >/dev/null; echo \'{"continue":false,"stopReason":"enough"}\'' },
  );
  ( $exit, $events ) = stream( $tool, [
    { tool_calls => [ [ bash => { command => 'true' } ] ] },
    { text => 'never' },
  ], '--stream-json' );
  like( $events->[-1], { status => 'cancelled', reason => 'hook_stopped' }, 'a PreToolUse stop cancels: hook_stopped' );
};

subtest 'provider: a --provider that cannot run' => sub {
  my ( $exit, $events ) = stream( root(), [], '--stream-json', '--provider', 'ghost' );
  is( $exit, 2, 'a usage error' );
  like( $events->[-1], { type => 'run.finished', status => 'failed', reason => 'provider', provider => 'ghost' }, 'reason provider' );
};

subtest 'user_cancel, run_setup, error: the application' => sub {
  my $app;
  $app = mock_app( root => root()->stringify, permission_mode => 'bypassPermissions',
    on_event => sub { $app->cancel_run if $_[0] eq 'tool.call' },
    script => [ { tool_calls => [ [ list_files => {} ] ] }, { text => 'never' } ] );
  my $session = $app->create_session;
  my $end = $app->run_prompt( 'go', session => $session );
  is( [ @$end{qw( status reason )} ], [qw( cancelled user_cancel )], 'cancel_run: user_cancel' );
  $session->release;
  my $journal = journal( $session->path );
  like( $journal->[-1], { type => 'run.finished', status => 'cancelled', reason => 'user_cancel' }, 'into the journal' );
  like( ( grep { $_->{type} eq 'run.started' } @$journal )[0],
    { session => $session->id, run => 'r1', cwd => T(), permission_mode => 'bypassPermissions', tools => T(), raider_version => T() },
    'the journal\'s run.started has the new fields too' );

  $app = My::NoModelApp->new( root => root()->stringify, engine_name => 'openai', api_key => 'mock',
    permission_mode => 'bypassPermissions', script => [ { text => 'never' } ] );
  $end = $app->run_prompt( 'go', model => 'gpt-4o' );
  is( [ @$end{qw( status reason )} ], [qw( failed run_setup )], 'begin_run croaked: run_setup' );
  like( $end->{error}, qr/no engine for that model/, 'the error is the text' );

  $app = mock_app( root => root()->stringify, permission_mode => 'bypassPermissions', script => [ { text => 'x' } ] );
  is( $app->end_run('failed'), undef, 'outside a run: nothing' );
  $app->begin_run;
  is( $app->end_run('failed', error => 'e')->{reason}, 'error', 'failed without a reason: error' );
  $app->begin_run;
  is( $app->end_run('interrupted', signal => 'TERM')->{reason}, 'signal', 'interrupted: signal' );
  $app->begin_run;
  is( $app->end_run('cancelled')->{reason}, 'user_cancel', 'cancelled without cancel_run: user_cancel' );
  $app->begin_run;
  ok( !exists $app->end_run('completed')->{reason}, 'completed: no reason' );
};

done_testing;
