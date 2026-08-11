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
#   * push push_update_reference reports a per-ref verdict, but libgit2
#     1.5's local transport (src/libgit2/transports/local.c) does NOT do
#     report-status and does NOT run receive hooks — it just writes the ref
#     directly. So only the SUCCESS path is reachable through a file://
#     remote; a real rejection needs an ssh/https remote with a pre-receive
#     hook (t/40-remote-ssh.t / t/41-remote-https.t, when
#     TEST_GIT_NATIVE_SSH_URL / TEST_GIT_NATIVE_HTTPS_URL is set). The
#     rejection BRANCH is covered here anyway by driving the thunk closure
#     from Perl with the arguments libgit2 would pass, the same trick
#     t/52-credential-callback.t uses.
#
# The other contract this file pins is that both callbacks produce the SAME
# entry shape — { ref, from, to, reason } — see section 3b (karr #16).

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
is $u->{reason}, '',
  'reason is "" on a fetch update — there is no server verdict on a fetch, '
  . 'the key exists so fetch and push entries have the same shape';

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

my $pu = $push_result->updated->[0];
is $pu->{ref}, 'refs/karr/test/data',
  'updated refname — the name on the REMOTE side, which is what the '
  . 'server reports back through push_update_reference';
is $pu->{reason}, '',
  'reason is "" on a successful push_update_reference';
is $pu->{to}, $commit_a->hex,
  'to oid is filled from the local source ref of the refspec — the server '
  . 'only sends a verdict, but we know what we asked it to write';
is $pu->{from}, undef,
  'from oid is undef on a push: the previous remote-side oid would cost an '
  . 'extra git_remote_ls round trip, so push reports an honest undef';

# ---- 3b. the unification: push and fetch entries have ONE shape ----
#
# The regression this pins (karr #16): updated entries used to be
# { ref, from, to } on fetch and { ref, reason } on push, so
# $result->updated->[0]{to} silently returned undef on a push — a key that
# was not there at all rather than a value that was unknown. Anything
# reading a Result generically broke on whichever operation it was not
# written against. The key set is now the contract; if a callback ever
# grows or drops a field again, this is the assertion that fails.
my @fetch_keys = sort keys %{ $fetch_result->updated->[0] };
my @push_keys  = sort keys %{ $push_result->updated->[0] };
is \@fetch_keys, [qw( from reason ref to )],
  'a fetch update entry has exactly ref/from/to/reason';
is \@push_keys, \@fetch_keys,
  'a push update entry has exactly the same keys as a fetch update entry';

# ---- 4. push push_update_reference: the rejection path --------------
#
# The REJECTED branch is unreachable through a file:// remote in libgit2
# 1.5: the local transport does not do report-status and does not run
# receive hooks, so the server side never sends an "ng" for a ref. Rather
# than leave the branch untested until someone sets
# TEST_GIT_NATIVE_SSH_URL, drive the thunk straight from Perl the way
# t/52-credential-callback.t drives the credential thunk — the closure is
# a pure function of ( refname, status, payload ) and an
# FFI::Platypus::Closure is a blessed CODE ref.
#
#   int cb(const char *refname, const char *status, void *data)
subtest 'push_update_reference sorts the server verdict into updated/rejected' => sub {
  my ( @rejected, @updated );
  my ( $closure, $keep ) = Git::Native::Remote::_make_push_update_thunk(
    \@rejected, \@updated,
    { 'refs/heads/ok'    => 'a' x 40,
      'refs/heads/empty' => 'b' x 40,
      'refs/heads/gone'  => undef },
  );

  # status == NULL: libgit2's "the server raised no objection".
  is $closure->( 'refs/heads/ok', undef, 0 ), 0,
    'a NULL status returns 0 so the push continues';
  # status == "": a server that reported success with no message.
  is $closure->( 'refs/heads/empty', '', 0 ), 0,
    'an empty status returns 0 too';
  # status != "": the server refused this ref, and said why.
  is $closure->( 'refs/heads/nope', 'pre-receive hook declined', 0 ), 0,
    'a rejection still returns 0 — one refused ref must not abort the '
    . 'reporting of the others';
  # A delete refspec: accepted, but there is no oid on the far side now.
  is $closure->( 'refs/heads/gone', undef, 0 ), 0,
    'a deleted ref is reported through the same callback';

  is \@updated, [
    { ref => 'refs/heads/ok',    from => undef, to => 'a' x 40, reason => '' },
    { ref => 'refs/heads/empty', from => undef, to => 'b' x 40, reason => '' },
    { ref => 'refs/heads/gone',  from => undef, to => undef,    reason => '' },
  ], 'NULL and "" are both "accepted", and each entry carries the four-key '
   . 'shape with `to` taken from the refspec target map';

  is \@rejected, [
    { ref => 'refs/heads/nope', reason => 'pre-receive hook declined' },
  ], 'a non-empty status is a rejection carrying the server message verbatim';

  ok $keep, 'the thunk returns a keepalive alongside the closure';
};

# A ref the server names but the refspec map does not know (a push through
# a refspec whose source is not a resolvable local reference) must still
# produce the full key set — an unknown oid is undef, never a missing key.
subtest 'an unmapped refname still yields the full four-key shape' => sub {
  my ( @rejected, @updated );
  my ( $closure, $keep ) = Git::Native::Remote::_make_push_update_thunk(
    \@rejected, \@updated,
  );
  $closure->( 'refs/heads/surprise', undef, 0 );
  is \@updated, [
    { ref => 'refs/heads/surprise', from => undef, to => undef, reason => '' },
  ], 'no target known for the ref: to is an explicit undef';
};

sub commit_in {
  my ( $repo, $text ) = @_;
  my $blob = $repo->blob_create_frombuffer($text);
  my $tb   = $repo->tree_builder;
  $tb->insert( name => 'data', oid => $blob, mode => 0100644 );
  return $repo->commit_create(
    tree => $tb->write, parents => [], message => $text,
  );
}

# The `to` a push reports comes from pairing the expanded refspecs with the
# local refs they name — the one piece of pure Perl between the refspec list
# and the callback. Unit-test it directly, no remote involved: a wrong map
# here means a push silently reports the wrong oid, which is worse than the
# missing key it replaced.
subtest '_push_update_targets maps destination refnames to local oids' => sub {
  my $tmp_t = Path::Tiny->tempdir;
  my $t     = Git::Native->init("$tmp_t");
  my $c     = commit_in( $t, "target\n" );
  $t->reference_create( 'refs/karr/a', $c, force => 1 );
  $t->reference_create( 'refs/heads/main', $c, force => 1 );
  $t->set_head('refs/heads/main');
  my $rmt = $t->remote_anonymous('file:///nonexistent');

  my $map = Git::Native::Remote::_push_update_targets( $rmt, [
    '+refs/karr/a:refs/karr/a',      # forced, same name
    'refs/karr/a:refs/backup/a',     # remapped destination
    ':refs/karr/gone',               # delete refspec (what prune emits)
    'refs/karr/missing:refs/karr/m', # source that is not a local ref
    'HEAD:refs/heads/from-head',     # symbolic source
    'refs/karr/a',                   # no colon: source is also destination
  ] );

  is $map->{'refs/karr/a'}, $c->hex,
    'a same-name refspec maps the destination to the local oid';
  is $map->{'refs/backup/a'}, $c->hex,
    'a remapped destination is keyed by the REMOTE name, which is what '
    . 'push_update_reference reports back';
  ok exists $map->{'refs/karr/gone'},
    'a delete refspec is in the map...';
  is $map->{'refs/karr/gone'}, undef,
    '...with an undef target, which is how a delete becomes to => undef';
  is $map->{'refs/karr/m'}, undef,
    'an unresolvable source yields undef rather than dying the push';
  is $map->{'refs/heads/from-head'}, $c->hex,
    'a symbolic source is resolved, so HEAD:refs/heads/x reports an oid';
  is $map->{'refs/karr/a'}, $c->hex,
    'a colonless refspec pushes the source to its own name';
};

# ---- 4b. deletions are distinguishable from updates ----------------
#
# Both operations can report a ref that DISAPPEARED, not one that moved:
# `push prune => 1` sends `:refs/...` delete refspecs, and `fetch prune => 1`
# drops stale mirror refs. libgit2 signals the fetch case by passing the
# all-zero oid as the new tip of update_tips (probed against file://), which
# we normalise to undef so both operations agree: no `to` means the ref is
# gone. Without that, a caller cannot tell "now points at X" from "no longer
# exists" except by a magic 40-zero string on one operation only.
subtest 'a deleted ref is reported with to => undef on push and on fetch' => sub {
  my $tmp_db  = Path::Tiny->tempdir;
  my $db_bare = Git::Native->init( "$tmp_db", bare => 1 );
  my $url     = 'file://' . $tmp_db;

  my $tmp_src = Path::Tiny->tempdir;
  my $src     = Git::Native->init("$tmp_src");
  my $c_keep  = commit_in( $src, "keep\n" );
  my $c_drop  = commit_in( $src, "drop\n" );
  $src->reference_create( 'refs/karr/keep', $c_keep, force => 1 );
  $src->reference_create( 'refs/karr/drop', $c_drop, force => 1 );
  my $src_rmt = $src->remote_create( 'origin', $url );
  $src_rmt->push( refspecs => ['+refs/karr/*:refs/karr/*'] );

  # A mirror that has both refs, so its fetch --prune has something to drop.
  my $tmp_mir = Path::Tiny->tempdir;
  my $mirror  = Git::Native->init("$tmp_mir");
  my $mir_rmt = $mirror->remote_create( 'origin', $url );
  $mir_rmt->fetch( refspecs => ['+refs/karr/*:refs/karr/*'] );

  # Drop it locally and push --prune: the delete refspec we synthesise
  # comes back through push_update_reference like any accepted ref.
  $src->reference_delete('refs/karr/drop');
  my $pr = $src_rmt->push(
    refspecs => ['+refs/karr/*:refs/karr/*'], prune => 1,
  );
  is scalar @{ $pr->rejected }, 0, 'prune push rejected nothing';
  my %by_ref = map { $_->{ref} => $_ } @{ $pr->updated };
  is [ sort keys %by_ref ], [ 'refs/karr/drop', 'refs/karr/keep' ],
    'prune push reports both the written ref and the deleted one';
  is $by_ref{'refs/karr/keep'}{to}, $c_keep->hex,
    'the ref that was written carries its new oid';
  is $by_ref{'refs/karr/drop'}{to}, undef,
    'the ref that was DELETED carries to => undef, so a caller can tell the '
    . 'two apart without re-listing the remote';
  is [ sort keys %{ $by_ref{'refs/karr/drop'} } ], [qw( from reason ref to )],
    'a delete entry is not a special shape, just to => undef';
  ok !$db_bare->reference_exists('refs/karr/drop'),
    'the remote really lost the ref (the report is not lying)';

  # Same story on the fetch side.
  my $fr = $mir_rmt->fetch(
    refspecs => ['+refs/karr/*:refs/karr/*'], prune => 1,
  );
  my %f_by_ref = map { $_->{ref} => $_ } @{ $fr->updated };
  ok exists $f_by_ref{'refs/karr/drop'},
    'fetch --prune reports the stale ref it dropped';
  is $f_by_ref{'refs/karr/drop'}{to}, undef,
    'a pruned mirror ref is to => undef, not the 40-zero oid libgit2 passes';
  is $f_by_ref{'refs/karr/drop'}{from}, $c_drop->hex,
    'from still says where the ref used to point';
  ok !$mirror->reference_exists('refs/karr/drop'),
    'the mirror really lost the ref';
};

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
