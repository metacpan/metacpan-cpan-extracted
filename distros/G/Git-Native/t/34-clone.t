use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Path::Tiny;
use Git::Native;

# Build a source repo with one commit, clone it via file://.
my $tmp_src  = Path::Tiny->tempdir;
my $tmp_dst  = Path::Tiny->tempdir;
my $tmp_bare = Path::Tiny->tempdir;

my $src = Git::Native->init("$tmp_src");
my $blob = $src->blob_create_frombuffer("clone me\n");
my $tb   = $src->tree_builder;
$tb->insert( name => 'README', oid => $blob, mode => 0100644 );
my $tree = $tb->write;
my $commit = $src->commit_create(
  tree    => $tree,
  parents => [],
  message => 'initial',
);
$src->reference_create( 'refs/heads/main', $commit, force => 1 );

# Make a bare repo with the ref so we have something clonable (clone wants
# HEAD to resolve; a bare push from src sets it up cleanly).
my $bare = Git::Native->init( "$tmp_bare", bare => 1, initial_branch => 'main' );
my $remote = $src->remote_create( 'origin', "file://$tmp_bare" );
$remote->push( refspecs => ['+refs/heads/main:refs/heads/main'] );

# Pin the bare repo's HEAD at main so clone has a deterministic default
# branch regardless of libgit2's compiled-in default (Debian patches it to
# 'main', upstream/Homebrew still defaults to 'master').
$bare->set_head('refs/heads/main');

# Clone into dst.
my $cloned = Git::Native->clone( "file://$tmp_bare", "$tmp_dst" );
isa_ok $cloned, 'Git::Native::Repository', 'clone returns Repository';
ok !$cloned->is_bare, 'clone is not bare by default';
ok -d $tmp_dst->child('.git'), 'cloned .git exists';

# Verify the ref came across.
ok $cloned->reference_exists('refs/heads/main'), 'main present after clone';
my $cloned_main = $cloned->reference('refs/heads/main');
is $cloned_main->target->hex, $commit->hex, 'main points at expected commit';

done_testing;
