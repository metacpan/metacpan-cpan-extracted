#!/usr/bin/env perl
# ABSTRACT: Langertha::Raider::Worktree -- the git work behind worktree isolation (ADR 0032 §1, k168)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Path::Tiny;
use Test::Raider::Git qw( have_git git_repo git_in );
use Langertha::Raider::Worktree;

plan skip_all => 'needs git' unless have_git();

my $git = Langertha::Raider::Worktree->new;

# Each directory lives as long as the test does.
my @dirs;
sub tmpdir { my $d = Path::Tiny->tempdir; push @dirs, $d; $d->realpath }

subtest 'repository_top and toplevel: the main checkout, also from inside a worktree' => sub {
  my $repo = git_repo( 'lib/A.pm' => "1;\n" );
  is( $git->repository_top("$repo"), { top => "$repo" }, 'the top of the repository' );
  is( $git->repository_top( $repo->child('lib') ), { top => "$repo" }, 'from a subdirectory' );
  is( $git->toplevel( $repo->child('lib') ), { top => "$repo" }, 'toplevel of a subdirectory' );
  my $wt = $repo->child('.raider/worktrees/x');
  git_in( $repo, qw( worktree add -q -b wx ), "$wt" );
  is( $git->repository_top( $wt->child('lib') ), { top => "$repo" }, 'inside a linked worktree: the main checkout' );
  is( $git->toplevel( $wt->child('lib') ), { top => "$wt" }, 'toplevel there is the worktree' );

  my $plain = tmpdir();
  like( $git->repository_top("$plain"), { error => qr/\Agit rev-parse: fatal: not a git repository/ },
    'outside a repository: an error value, no exception' );
  like( $git->toplevel( $plain->child('nope') ), { error => qr/does not exist/ }, 'a missing directory' );
};

subtest 'base_ref: fresh is origin/HEAD when it resolves, else HEAD; head is the HEAD of the directory' => sub {
  my $repo = git_repo();
  my $head = git_in( $repo, qw( rev-parse HEAD ) ) =~ s/\s+\z//r;
  is( $git->base_ref( "$repo", 'fresh' ), { ref => 'HEAD', commit => $head }, 'no remote: fresh falls back to HEAD' );
  is( $git->base_ref( "$repo", 'head' ), { ref => 'HEAD', commit => $head }, 'head' );

  # A clone has origin/HEAD; a local commit after it makes HEAD differ.
  my $clone = tmpdir()->child('clone');
  git_in( $repo, qw( clone -q ), "$repo", "$clone" );
  git_in( $clone, qw( config user.name T ) );
  git_in( $clone, qw( config user.email t@example.com ) );
  $clone->child('local.txt')->spew("l\n");
  git_in( $clone, qw( add local.txt ) );
  git_in( $clone, qw( commit -q -m local ) );
  my $local = git_in( $clone, qw( rev-parse HEAD ) ) =~ s/\s+\z//r;
  is( $git->base_ref( "$clone", 'fresh' ), { ref => 'origin/HEAD', commit => $head }, 'fresh: the remote default branch' );
  is( $git->base_ref( "$clone", 'head' ), { ref => 'HEAD', commit => $local }, 'head: the local HEAD' );

  my $empty = tmpdir();
  git_in( $empty, qw( init -q ) );
  like( $git->base_ref("$empty"), { error => qr/HEAD does not name a commit/ }, 'no commit yet: an error value' );
};

subtest 'create, lock, changes, unlock, remove' => sub {
  my $repo = git_repo( 'a.txt' => "a\n", '.gitignore' => ".env\nsecret/\n*.log\n", '.worktreeinclude' => ".env\nsecret/\nnot-ignored.txt\n" );
  $repo->child('.env')->spew("KEY=1\n");
  $repo->child('.env')->chmod(0600);
  $repo->child('secret/deep/key')->touchpath->spew("k\n");
  $repo->child('build.log')->spew("log\n");          # ignored, not in .worktreeinclude
  $repo->child('not-ignored.txt')->spew("n\n");     # in .worktreeinclude, but not ignored
  my $base = $git->base_ref("$repo")->{commit};
  my $path = $repo->child('.claude/worktrees/agent-1');

  my $made = $git->create( source => "$repo", path => "$path", branch => 'worktree-agent-1', base => $base );
  ok( !$made->{error}, 'created' ) or diag $made->{error};
  is( $made->{path}, "$path", 'at the path' );
  is( $made->{branch}, 'worktree-agent-1', 'on the branch' );
  is( [ sort @{ $made->{copied} } ], [ '.env', 'secret/deep/key' ], '.worktreeinclude: only files that match and are ignored' );
  is( $made->{copy_errors}, [], 'nothing failed to copy' );
  is( $path->child('.env')->slurp, "KEY=1\n", 'copied with content' );
  is( ( stat $path->child('.env') )[2] & 07777, 0600, 'and mode' );
  ok( !$path->child('build.log')->exists, 'an ignored file not named is not copied' );
  ok( !$path->child('not-ignored.txt')->exists, 'an untracked file the repository does not ignore is not copied' );
  is( git_in( $path, qw( rev-parse --abbrev-ref HEAD ) ), "worktree-agent-1\n", 'the worktree is on its branch' );
  is( eval { git_in( $path, qw( config branch.worktree-agent-1.merge ) ) }, undef, 'no upstream set (--no-track)' );

  like( $git->create( source => "$repo", path => "$path", branch => 'other', base => $base ), { error => qr/exists/ },
    'an existing path is an error' );
  like( $git->create( source => "$repo", path => $repo->child('.claude/worktrees/b'), branch => 'worktree-agent-1', base => $base ),
    { error => qr/\Agit worktree add: fatal: .*already exists/ }, 'an existing branch is an error value' );

  is( $git->changes( "$path", $base ), { status => [], commits => 0 }, 'a fresh worktree has no changes (copied files are ignored)' );

  is( $git->lock( "$path", 'raider agent agent_1' ), {}, 'locked' );
  my ($entry) = grep { $_->{path} eq "$path" } @{ $git->list("$repo")->{worktrees} };
  is( $entry->{locked}, 'raider agent agent_1', 'list shows the lock and its reason' );
  like( $git->remove( dir => "$repo", path => "$path", branch => 'worktree-agent-1' ), { error => qr/\Agit worktree remove: / },
    'a locked worktree is not removed' );
  ok( $path->exists && $git->branch_exists( "$repo", 'worktree-agent-1' ), 'worktree and branch stay' );
  is( $git->unlock("$path"), {}, 'unlocked' );

  $path->child('new.txt')->spew("n\n");
  is( $git->changes( "$path", $base ), { status => [ '?? new.txt' ], commits => 0 }, 'an untracked file is a change' );
  git_in( $path, qw( add new.txt ) );
  git_in( $path, qw( commit -q -m new ) );
  is( $git->changes( "$path", $base ), { status => [], commits => 1 }, 'a commit beyond the base is one' );
  is( $git->changes("$path"), { status => [], commits => 0 }, 'without a base only the status' );

  is( $git->remove( dir => "$repo", path => "$path", branch => 'worktree-agent-1' ), {}, 'removed' );
  ok( !$path->exists, 'the directory is gone' );
  ok( !$git->branch_exists( "$repo", 'worktree-agent-1' ), 'the branch is deleted (even with an unmerged commit)' );
};

subtest 'remove refuses a dirty worktree unless forced; checkout brings a branch back' => sub {
  my $repo = git_repo( 'a.txt' => "a\n" );
  my $base = $git->base_ref("$repo")->{commit};
  my $path = $repo->child('.raider/worktrees/agent-2');
  $git->create( source => "$repo", path => "$path", branch => 'worktree-agent-2', base => $base );
  $path->child('a.txt')->spew("changed\n");
  is( $git->changes( "$path", $base ), { status => [ ' M a.txt' ], commits => 0 }, 'a modified file is a change' );
  like( $git->remove( dir => "$repo", path => "$path", branch => 'worktree-agent-2' ),
    { error => qr/\Agit worktree remove: fatal: .*modified or untracked/ }, 'git refuses, as a value' );
  ok( $git->branch_exists( "$repo", 'worktree-agent-2' ), 'the branch stays when the worktree does' );

  git_in( $path, qw( commit -q -a -m change ) );
  is( $git->remove( dir => "$repo", path => "$path" ), {}, 'removed without its branch (no branch given)' );
  ok( $git->branch_exists( "$repo", 'worktree-agent-2' ), 'the branch is still there' );
  my $back = $git->checkout( dir => "$repo", path => "$path", branch => 'worktree-agent-2' );
  is( $back, { path => "$path", branch => 'worktree-agent-2' }, 'checked out into the same path again' );
  is( $path->child('a.txt')->slurp, "changed\n", 'with the branch\'s commit' );
  is( $git->changes( "$path", $base ), { status => [], commits => 1 }, 'its commit counts against the base' );

  $path->child('a.txt')->spew("dirty\n");
  is( $git->remove( dir => "$repo", path => "$path", branch => 'worktree-agent-2', force => 1 ), {}, 'force removes it anyway' );
  ok( !$path->exists && !$git->branch_exists( "$repo", 'worktree-agent-2' ), 'worktree and branch gone' );
};

subtest 'list: the main checkout first, then the worktrees' => sub {
  my $repo = git_repo();
  my $path = $repo->child('.claude/worktrees/agent-3');
  $git->create( source => "$repo", path => "$path", branch => 'worktree-agent-3', base => 'HEAD' );
  my $list = $git->list( $path );
  is( scalar @{ $list->{worktrees} }, 2, 'two' );
  like( $list->{worktrees}[0], { path => "$repo", branch => 'main', main => 1 }, 'the main checkout' );
  like( $list->{worktrees}[1], { path => "$path", branch => 'worktree-agent-3', head => qr/\A[0-9a-f]{40}\z/ }, 'the worktree' );
  ok( !exists $list->{worktrees}[1]{main}, 'which is not main' );
};

subtest 'a git that cannot start is an error value' => sub {
  my $broken = Langertha::Raider::Worktree->new( git => '/nonexistent/git-'.$$ );
  like( $broken->repository_top('/'), { error => qr/\Agit cannot be started: / }, 'reported, not thrown' );
};

done_testing;
