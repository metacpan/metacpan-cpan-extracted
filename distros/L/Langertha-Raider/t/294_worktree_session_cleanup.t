#!/usr/bin/env perl
# ABSTRACT: A worktree of the session is closed at /clear and at the end of the session (ADR 0032 §5, §6; k168)
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
use JSON::MaybeXS ();
use Path::Tiny;
use Test::Raider::Git qw( have_git git_repo git_in );
use Test::Raider::MockAI qw( mock_app );
use Test::Raider::SlowAI ();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;
use Langertha::Raider::Loadguard;
use Langertha::Raider::Worktree;

plan skip_all => 'needs git' unless have_git();

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

# The raider CLI on the scripted mock model; the script of an app Main
# builds comes from @My::CLI::SCRIPT.
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

package main;

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $git = Langertha::Raider::Worktree->new;

sub collect { my ( $list ) = @_; return sub { my ( $type, %p ) = @_; push @$list, { type => $type, %p } } }

sub app_in {
  my ( $root, %o ) = @_;
  return mock_app( root => "$root", permission_mode => 'bypassPermissions', %o );
}

sub cli {
  my ( $root, @script ) = @_;
  return My::CLI->new(
    root => "$root", engine => 'openai', api_key => 'mock', trace => 0, detect => 0,
    skip_permissions => 1, script => \@script,
    loadguard => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
  );
}

# A REPL reading @lines from a pipe; returns what it printed.
sub repl_run {
  my ( $app, @lines ) = @_;
  pipe my $r, my $w or die $!;
  $w->autoflush(1);
  my $out = '';
  open my $fh, '>', \$out or die $!;
  my $repl = Langertha::Raider::CLI::REPL->new(
    app => $app, in => $r, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ),
    session_store => $app->session_store,
  );
  print {$w} map { $_."\n" } @lines;
  close $w;
  $repl->run;
  return ( $out, $repl );
}

sub enter {
  my ( $app, %in ) = @_;
  my ( $text, $err ) = $app->_enter_worktree( \%in );
  die $text if $err;
  return path( $app->worktree_session->{path} );
}

subtest 'a new conversation: an unchanged worktree is removed with its branch' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my @events;
  my $app = app_in( $repo, on_event => collect( \@events ),
    script => [ { tool_calls => [ [ enter_worktree => {} ] ] }, { text => 'in' } ] );
  my $session = $app->create_session;
  $app->run_prompt( 'go', session => $session );
  my $wt = path( $app->working_root );
  is( "$wt", $repo->child('.raider/worktrees/session-1')->stringify, 'in the worktree after the run' );
  $app->note_history_cleared;
  ok( !$wt->exists, 'the worktree is gone' );
  ok( !$git->branch_exists( "$repo", 'worktree-session-1' ), 'and its branch' );
  is( $app->working_root, "$repo", 'the working root is the root again' );
  is( $app->permissions->root, "$repo", 'and so is the policy\'s' );
  is( [ $app->take_meta_notes ], [], 'nothing to tell' );
  my ($exited) = grep { $_->{type} eq 'worktree.exited' } @events;
  like( $exited, { path => "$wt", branch => 'worktree-session-1', removed => T(), reason => 'clear' }, 'worktree.exited, reason clear' );
  $session->release;
  my ($journaled) = grep { $_->{type} eq 'worktree.exited' } map { $json->decode($_) } $session->path->lines_raw;
  like( $journaled, { reason => 'clear', removed => T() }, 'outside the run: into the session it was entered in' );
};

subtest 'with changes it is kept and named; one entered by path is only left' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in($repo);
  my $wt = enter( $app, name => 'busy' );
  $wt->child('new.txt')->spew("n\n");
  $app->note_history_cleared;
  ok( $wt->exists && $git->branch_exists( "$repo", 'worktree-busy' ), 'kept with its branch' );
  is( [ $app->take_meta_notes ], [ "worktree $wt kept on branch worktree-busy (has changes)" ], 'the meta line' );
  is( $app->working_root, "$repo", 'back at the root' );

  my $other = $repo->child('.raider/worktrees/other');
  git_in( $repo, qw( worktree add -q -b other ), "$other" );
  my @events;
  $app = app_in( $repo, on_event => collect( \@events ) );
  enter( $app, path => "$other" );
  $app->close_worktree_session('session_end');
  ok( $other->exists, 'an entered one stays, unchanged or not' );
  is( [ $app->take_meta_notes ], [], 'no meta line' );
  like( [ grep { $_->{type} eq 'worktree.exited' } @events ], [ { removed => F(), reason => 'session_end' } ], 'only left' );
  $app->close_worktree_session('session_end');
  is( scalar( grep { $_->{type} eq 'worktree.exited' } @events ), 1, 'outside a session: nothing' );
};

subtest 'commits beyond the base count as changes' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = app_in($repo);
  my $wt = enter( $app, name => 'committed' );
  $wt->child('c.txt')->spew("c\n");
  git_in( $wt, qw( add c.txt ) );
  git_in( $wt, qw( commit -q -m c ) );
  $app->close_worktree_session('session_end');
  ok( $wt->exists, 'a clean status with a commit: kept' );
  is( [ $app->take_meta_notes ], [ "worktree $wt kept on branch worktree-committed (has changes)" ], 'named' );
};

subtest 'the REPL: /clear closes it, and so does leaving' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $app = cli( $repo,
    { tool_calls => [ [ enter_worktree => { name => 'one' } ] ] }, { text => 'in one' },
    { tool_calls => [ [ enter_worktree => { name => 'two' } ] ] },
    { tool_calls => [ [ write_file => { path => 'w.txt', content => "w\n" } ] ] }, { text => 'in two' },
  );
  my ( $out ) = repl_run( $app, 'go one', '/clear', 'go two', '/quit' );
  my $one = $repo->child('.raider/worktrees/one');
  my $two = $repo->child('.raider/worktrees/two');
  ok( !$one->exists, '/clear removed the unchanged one' );
  ok( $two->exists && $two->child('w.txt')->exists, 'leaving kept the changed one' );
  like( $out, qr/^history cleared\.$/m, '/clear' );
  like( $out, qr/^bye\.\nworktree \Q$two\E kept on branch worktree-two \(has changes\)$/m, 'the meta line when leaving' );
  is( $app->working_root, "$repo", 'the working root is back' );
};

subtest 'the REPL left by SIGTERM closes it too' => sub {
  for my $dirty ( 0, 1 ) {
    my $repo = git_repo( 'a.txt' => "a\n" );
    my $outfile = Path::Tiny->tempfile;
    pipe my $r, my $w or die $!;
    $w->autoflush(1);
    my $pid = fork // die "fork: $!";
    unless ($pid) {
      close $w;
      open my $fh, '>', "$outfile" or die $!;
      $fh->autoflush(1);
      my $app = cli( $repo,
        { tool_calls => [ [ enter_worktree => { name => 'term' } ] ] },
        ( $dirty ? { tool_calls => [ [ write_file => { path => 'w.txt', content => "w\n" } ] ] } : () ),
        { text => 'ready' },
      );
      Langertha::Raider::CLI::REPL->new( app => $app, in => $r,
        output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ) )->run;
      exit 3;   # not reached: SIGTERM leaves with 0
    }
    close $r;
    print {$w} "go\n";
    my $until = time + 30;
    sleep 1 until $outfile->slurp =~ /ready/ || time > $until;
    kill TERM => $pid;
    waitpid $pid, 0;
    is( $? >> 8, 0, ( $dirty ? 'dirty' : 'clean' ).': left with 0' );
    my $wt = $repo->child('.raider/worktrees/term');
    my $out = $outfile->slurp;
    if ($dirty) {
      ok( $wt->exists, 'dirty: kept' );
      like( $out, qr/^worktree \Q$wt\E kept on branch worktree-term \(has changes\)\nbye\.$/m, 'dirty: named before bye.' );
    }
    else {
      ok( !$wt->exists && !$git->branch_exists( "$repo", 'worktree-term' ), 'clean: removed with its branch' );
    }
  }
};

subtest 'raider -p: the end of the run closes it; the meta line goes to stderr' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  for my $case ( [ clean => [] ], [ dirty => [ [ write_file => { path => 'd.txt', content => "d\n" } ] ] ] ) {
    my ( $name, $calls ) = @$case;
    local @My::CLI::SCRIPT = (
      { tool_calls => [ [ enter_worktree => { name => $name } ] ] },
      ( @$calls ? { tool_calls => $calls } : () ),
      { text => 'answered' },
    );
    my ( $out, $err ) = ( '', '' );
    open my $ofh, '>', \$out or die $!;
    open my $efh, '>', \$err or die $!;
    open my $in, '<', \'' or die $!;
    my $exit = My::Main->new(
      output => Langertha::Raider::CLI::Output->new( out => $ofh, color => 0 ),
      err    => $efh,
      in     => $in,
    )->run( '-r', "$repo", '-e', 'openai', '-k', 'mock', '--no-trace', '--no-session', '--dangerously-skip-permissions', '-p', 'go' );
    is( $exit, 0, $name.': exits 0' );
    like( $out, qr/answered/, $name.': answered' );
    my $wt = $repo->child( '.raider/worktrees/'.$name );
    if ( $name eq 'clean' ) {
      ok( !$wt->exists && !$git->branch_exists( "$repo", 'worktree-clean' ), 'clean: removed with its branch' );
      unlike( $err, qr/kept on branch/, 'clean: no meta line' );
    }
    else {
      ok( $wt->exists, 'dirty: kept' );
      like( $err, qr/^worktree \Q$wt\E kept on branch worktree-dirty \(has changes\)$/m, 'dirty: named on stderr' );
    }
  }
};

done_testing;
