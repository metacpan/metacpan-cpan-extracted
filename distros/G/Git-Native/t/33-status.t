use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Path::Tiny;
use Git::Native;
use Git::Libgit2 qw( GIT_STATUS_CURRENT GIT_STATUS_WT_NEW GIT_STATUS_WT_MODIFIED );

# The flag assertions below go through the GIT_STATUS_* constants rather than
# the raw bit values (128 / 256 / 0) they happen to have: the flags being
# tested come out of libgit2 itself, so a constant that drifted away from the
# C enum makes these fail instead of quietly passing on a stale number.

# Need a working tree for status, so init non-bare.
my ( $repo, $tmp ) = TestRepo::new_repo();
my $wd = path( $repo->workdir );

# Write an untracked file.
$wd->child('new.txt')->spew('hello');

my $status = $repo->status;
ok exists $status->{'new.txt'}, 'untracked file shows up in status';

my $flags = $status->{'new.txt'};
ok( ( $flags & GIT_STATUS_WT_NEW ), "WT_NEW bit set (got $flags)" );

# status_for_path on the same file.
my $single = $repo->status_for_path('new.txt');
is $single, $flags, 'status_for_path matches';

# Empty repo apart from the untracked file - only one entry.
is scalar( keys %$status ), 1, 'one entry in status';

# --- multiple untracked paths, incl. a nested dir, exercise the
#     git_status_foreach Perl closure across several callback invocations ---
$wd->child('a.txt')->spew('a');
$wd->child('sub')->mkpath;
$wd->child('sub/b.txt')->spew('b');
my $multi = $repo->status;
ok exists $multi->{'a.txt'},          'a.txt shows up';
ok exists $multi->{'sub/b.txt'},      'nested file shows up (recurse into dirs)';
ok( ( $multi->{'sub/b.txt'} & GIT_STATUS_WT_NEW ), 'nested file is WT_NEW' );
is scalar( keys %$multi ), 3, 'closure accumulated all three untracked paths';

# --- a tracked-then-modified file needs a real checkout, which a clone gives
#     us: clean is GIT_STATUS_CURRENT, editing it sets GIT_STATUS_WT_MODIFIED ---
my $src_dir   = Path::Tiny->tempdir;
my $bare_dir  = Path::Tiny->tempdir;
my $clone_dir = Path::Tiny->tempdir;

my $src = Git::Native->init( "$src_dir", initial_branch => 'main' );
my $bo  = $src->blob_create_frombuffer("line\n");
my $stb = $src->tree_builder;
$stb->insert( name => 'tracked.txt', oid => $bo, mode => 0100644 );
my $sc = $src->commit_create( tree => $stb->write, parents => [], message => 'init' );
$src->reference_create( 'refs/heads/main', $sc, force => 1 );

my $bare = Git::Native->init( "$bare_dir", bare => 1, initial_branch => 'main' );
$src->remote_create( 'origin', "file://$bare_dir" )
    ->push( refspecs => ['+refs/heads/main:refs/heads/main'] );
$bare->set_head('refs/heads/main');

my $clone = Git::Native->clone( "file://$bare_dir", "$clone_dir" );
is $clone->status_for_path('tracked.txt'), GIT_STATUS_CURRENT,
  'freshly checked-out file is clean (GIT_STATUS_CURRENT)';

path( $clone->workdir )->child('tracked.txt')->spew("changed\n");
ok( ( $clone->status_for_path('tracked.txt') & GIT_STATUS_WT_MODIFIED ),
  'modifying a tracked file sets WT_MODIFIED' );

done_testing;
