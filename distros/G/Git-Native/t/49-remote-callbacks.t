use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Git::Native;
use Git::Native::Remote;
use Git::Native::Remote::Result;

# libgit2 returns 0 from git_remote_fetch even when a ref was skipped as
# non-fast-forward, and from git_remote_push even when the server rejected
# a ref (pre-receive hook, protected branch, etc). The only way to see
# those outcomes is via the per-ref callbacks:
#
#   git_remote_callbacks.update_tips        (fetch)  - per accepted local update
#   git_remote_callbacks.push_update_reference (push) - per server-side verdict
#
# This test exercises what we can against a file:// remote. Caveats:
#
#   * fetch update_tips fires for every accepted local ref update, even on
#     a local file:// transport. Easy to exercise.
#
#   * push push_update_reference only fires when the server sends a
#     report-status "ng" for a ref. libgit2 1.5's local transport
#     (src/libgit2/transports/local.c) does NOT do report-status and does
#     NOT run receive hooks — it just writes the ref directly. So we can
#     only test the SUCCESS path against a local bare. Testing the
#     REJECTED path needs an ssh/https remote with a pre-receive hook;
#     t/40-remote-ssh.t and t/41-remote-https.t are the place for that
#     when TEST_GIT_NATIVE_SSH_URL / TEST_GIT_NATIVE_HTTPS_URL is set.

# ---- 1. fetch update_tips: a brand-new ref appears in ->updated ----

my $tmp_bare = Path::Tiny->tempdir;
my $bare     = Git::Native->init( "$tmp_bare", bare => 1 );

# Seed the bare with a commit at refs/karr/test/data.
my $tmp_seed = Path::Tiny->tempdir;
my $seed = Git::Native->init("$tmp_seed");
my $seed_blob = $seed->blob_create_frombuffer("A\n");
my $seed_tb   = $seed->tree_builder;
$seed_tb->insert( name => 'f', oid => $seed_blob, mode => 0100644 );
my $seed_tree = $seed_tb->write;
my $commit_a  = $seed->commit_create(
  tree => $seed_tree, parents => [], message => 'upstream tip A',
);
$seed->reference_create( 'refs/karr/test/data', $commit_a, force => 1 );
my $seed_remote = $seed->remote_create( 'origin', 'file://' . $tmp_bare );
$seed_remote->push( refspecs => ['+refs/karr/*:refs/karr/*'] );

# Fresh client fetches it for the first time. update_tips must fire.
my $tmp_client = Path::Tiny->tempdir;
my $client     = Git::Native->init("$tmp_client");
my $client_remote = $client->remote_create( 'origin', 'file://' . $tmp_bare );

my $fetch_result = $client_remote->fetch(
  refspecs => ['+refs/karr/*:refs/karr/*'],
);

isa_ok $fetch_result, ['Git::Native::Remote::Result'], 'fetch returns a Result';
is scalar @{ $fetch_result->updated }, 1, 'fetch recorded exactly one update';

my $u = $fetch_result->updated->[0];
is $u->{ref},  'refs/karr/test/data', 'updated refname';
is $u->{from}, undef,                  'from oid is undef for a brand-new ref';
is $u->{to},   $commit_a->hex,         'to oid matches the upstream tip';

# ---- 2. fetch update_tips: a re-fetch (no-op) records nothing -----

# A second fetch on the same client should not report any update (the
# local tip is already up to date). Pins the negative case for the
# callback: the callback is ONLY called for refs that actually moved.
my $r_noop = $client_remote->fetch( refspecs => ['+refs/karr/*:refs/karr/*'] );
is scalar @{ $r_noop->updated }, 0,
  're-fetching the same tip produces no update events';

# ---- 3. push push_update_reference: success path -------------------

# A no-op (no-op same-oid) push still goes through report-status on a
# "real" transport. On local file://, the success side of the callback
# fires: the ref lands in $updated with reason "".
my $tmp_pp = Path::Tiny->tempdir;
my $pp = Git::Native->init("$tmp_pp");
my $pp_rmt = $pp->remote_create( 'origin', 'file://' . $tmp_bare );
$pp_rmt->fetch( refspecs => ['+refs/karr/*:refs/karr/*'] );
# Push the same tip back. Fast-forward, accepted.
my $push_result = $pp_rmt->push(
  refspecs => ['refs/karr/test/data:refs/karr/test/data'],
);
is scalar @{ $push_result->rejected }, 0, 'fast-forward push: nothing rejected';
is scalar @{ $push_result->updated }, 1, 'fast-forward push: one ref updated';
is $push_result->updated->[0]{ref}, 'refs/karr/test/data',
  'updated refname';
is $push_result->updated->[0]{reason}, '',
  'reason is "" on a successful push_update_reference';

# ---- 4. push push_update_reference: rejection path (live network) ---
#
# The REJECTED branch of push_update_reference is unreachable against a
# file:// remote in libgit2 1.5: the local transport does not do
# report-status and does not run receive hooks. Reproducing it requires
# an ssh/https remote with a pre-receive hook. We pin that gap with a
# TODO marker so it's clear what the live-network tests should cover.
TODO_LOCAL: {
  ok 1, 'TODO: rejection path needs ssh/https + pre-receive hook '
     . '(file:// transport bypasses hooks in libgit2 1.5)';
}

# ---- 5. Result->ok: semantics -------------------------------------

is( Git::Native::Remote::Result->new->ok, 1,
  'a fresh Result with empty lists is ok' );
isnt( Git::Native::Remote::Result->new(
  updated => [ { ref => 'r', from => 'a', to => 'b' } ]
)->ok, 1, 'a Result with updates is not ok' );
isnt( Git::Native::Remote::Result->new(
  rejected => [ { ref => 'r', reason => 'no' } ]
)->ok, 1, 'a Result with rejections is not ok' );

# ---- 6. closure lifetime: closure must outlive the C call ---------
# Build a fetch inside a scope that ends before the C call returns. If
# the closure is GC'd before the C call, we segfault. We can't observe
# a successful segfault from a test, so this test simply exercises the
# pattern; if Remote keeps the closure in @keep as it claims, the fetch
# completes cleanly. (The hidden contract test: prove by absence of
# segfault.)
sub fetch_in_nested_scope {
  my ($url) = @_;
  my $tmp = Path::Tiny->tempdir;
  my $r   = Git::Native->init("$tmp");
  my $rmt = $r->remote_create( 'o', $url );
  my $kept;
  do {
    # The fetch result itself holds the keepalive. Discard the
    # intermediate; the returned Result's @updated list captures the
    # outcome independently of the closure's lifetime.
    $kept = $rmt->fetch( refspecs => ['+refs/karr/*:refs/karr/*'] );
  };
  return $kept;
}
my $nested = fetch_in_nested_scope( 'file://' . $tmp_bare );
ok $nested, 'fetch in nested scope completes without segfault';
ok scalar @{ $nested->updated } >= 1,
  'nested-scope fetch still recorded updates';

done_testing;
