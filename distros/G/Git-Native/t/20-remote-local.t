use strict;
use warnings;
use Test::More;
use Path::Tiny;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Git::Native;
use Git::Native::Credential;

# Two repos linked by a file:// remote — push and pull a refs/karr/* ref
# end-to-end through Git::Native::Remote. No fork/exec.

my $tmp_bare = Path::Tiny->tempdir;
my $tmp_a    = Path::Tiny->tempdir;
my $tmp_b    = Path::Tiny->tempdir;

# Set up a bare upstream.
my $bare = Git::Native->init( "$tmp_bare", bare => 1 );
ok $bare, 'bare repo initialised';
ok $bare->is_bare, 'is_bare';

# Repo A: write a blob → tree → commit, point a ref at it.
my $a = Git::Native->init("$tmp_a");
my $blob_oid = $a->blob_create_frombuffer("hello from karr\n");
my $tb = $a->tree_builder;
$tb->insert( name => 'data', oid => $blob_oid, mode => 0100644 );
my $tree_oid = $tb->write;

my $commit_oid = $a->commit_create(
  tree    => $tree_oid,
  parents => [],
  message => 'native commit',
);
ok $commit_oid, "commit oid: $commit_oid";

my $ref = $a->reference_create( 'refs/karr/test/data', $commit_oid, force => 1 );
ok $ref, 'ref created in repo A';

# Wire A → bare via file:// remote, push.
my $url = 'file://' . $tmp_bare;
my $remote_a = $a->remote_create( 'origin', $url );
is $remote_a->url, $url, 'remote A url roundtrip';

# Wildcard push — Remote auto-expands.
$remote_a->push( refspecs => ['+refs/karr/*:refs/karr/*'] );
ok 1, 'push completed without die (wildcard auto-expanded)';

# Verify on bare side directly.
my $bare_ref = $bare->reference('refs/karr/test/data');
is $bare_ref->target->hex, $commit_oid->hex, 'bare has the pushed ref';

# Repo B: fetch from bare.
my $b = Git::Native->init("$tmp_b");
my $remote_b = $b->remote_create( 'origin', $url );
$remote_b->fetch( refspecs => ['+refs/karr/*:refs/karr/*'] );
ok 1, 'fetch completed without die';

my $b_ref = $b->reference('refs/karr/test/data');
is $b_ref->target->hex, $commit_oid->hex, 'repo B has the fetched ref';

# Credentials callback exercises the closure path even when not strictly
# needed (file:// requires no auth — libgit2 still asks if registered).
my $remote_b2 = $b->remote_anonymous($url);
$remote_b2->fetch(
  refspecs    => ['+refs/karr/*:refs/karr/*'],
  credentials => sub { undef },   # PASSTHROUGH → falls through
);
ok 1, 'fetch with credentials callback (PASSTHROUGH path)';

# --- prune semantics ---
# Add a second ref to A, push it; remote now has both.
my $extra_blob = $a->blob_create_frombuffer("extra\n");
my $tb2 = $a->tree_builder;
$tb2->insert( name => 'data', oid => $extra_blob, mode => 0100644 );
my $tree2 = $tb2->write;
my $commit2 = $a->commit_create( tree => $tree2, parents => [], message => 'extra' );
$a->reference_create( 'refs/karr/extra/data', $commit2, force => 1 );
$remote_a->push( refspecs => ['+refs/karr/*:refs/karr/*'] );
my $names_before = $bare->reference_names( glob => 'refs/karr/*' );
is scalar(@$names_before), 2, 'bare has two refs after second push';

# Delete the extra ref locally and push with prune — remote loses it too.
$a->reference_delete('refs/karr/extra/data');
$remote_a->push(
  refspecs => ['+refs/karr/*:refs/karr/*'],
  prune    => 1,
);
my $names_after = $bare->reference_names( glob => 'refs/karr/*' );
is scalar(@$names_after), 1, 'bare has one ref after prune push';
is $names_after->[0], 'refs/karr/test/data', 'pruned ref remained';

done_testing;
