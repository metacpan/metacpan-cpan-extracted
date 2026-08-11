use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Native::Signature;
use Git::Libgit2 qw( GIT_OID_MINPREFIXLEN );

# Repository->object_by_prefix($hex) - the `git rev-parse abc1234` lookup.
#
# Three things are worth pinning here, none of which t/47-object.t can cover
# because object() only ever sees a complete OID:
#
#   * the length libgit2 wants counts hex characters (nibbles), NOT bytes.
#     Getting that wrong is silent for even-length prefixes that happen to
#     match anyway, so the odd-length and minimum-length cases below are the
#     ones that would catch it.
#   * an ambiguous prefix must arrive as a Git::Native::Error with
#     is_ambiguous true - the whole reason that predicate exists.
#   * a prefix below GIT_OID_MINPREFIXLEN must NOT arrive that way. libgit2
#     answers it with GIT_EAMBIGUOUS too ("OID prefix is too short"), which
#     would make is_ambiguous mean two different things; the wrapper croaks
#     first so it keeps meaning one.

# ---------------------------------------------------------------------------
# Typed dispatch: object_by_prefix returns what object() returns.
# ---------------------------------------------------------------------------
{
  my ( $repo, $tmp ) = TestRepo::new_repo();

  my $blob_oid = $repo->blob_create_frombuffer("payload\n");
  my $tb       = $repo->tree_builder;
  $tb->insert( name => 'f', oid => $blob_oid, mode => 0100644 );
  my $tree_oid   = $tb->write;
  my $commit_oid = $repo->commit_create(
    tree => $tree_oid, parents => [], message => 'c',
  );
  my $tag_oid = $repo->tag_create(
    'v1.0.0', $commit_oid,
    message => "rel\n",
    tagger  => Git::Native::Signature->new( name => 'T', email => 't@e' ),
  );

  my $blob = $repo->object_by_prefix( substr "$blob_oid", 0, 7 );
  isa_ok $blob, ['Git::Native::Blob'], 'short blob prefix -> Blob';
  is $blob->content, "payload\n", 'and it is the right blob';
  is "" . $blob->oid, "$blob_oid", 'the resolved object carries the full OID';

  isa_ok $repo->object_by_prefix( substr "$tree_oid", 0, 7 ),
    ['Git::Native::Tree'], 'short tree prefix -> Tree';
  isa_ok $repo->object_by_prefix( substr "$commit_oid", 0, 7 ),
    ['Git::Native::Commit'], 'short commit prefix -> Commit';
  isa_ok $repo->object_by_prefix( substr "$tag_oid", 0, 7 ),
    ['Git::Native::Tag'], 'short annotated tag prefix -> Tag';

  # An odd length is the interesting one: a byte-count reading of the length
  # would halve 5 to 2 and libgit2 would reject it as too short.
  is $repo->object_by_prefix( substr "$blob_oid", 0, 5 )->oid . "", "$blob_oid",
    'an odd-length prefix resolves (length is hex characters, not bytes)';

  # Degenerate ends of the accepted range.
  is $repo->object_by_prefix("$blob_oid")->oid . "", "$blob_oid",
    'a full 40-character hex string is accepted';
  is $repo->object_by_prefix($blob_oid)->oid . "", "$blob_oid",
    'a Git::Native::Oid is accepted and behaves like object()';
  is $repo->object_by_prefix( uc( substr "$blob_oid", 0, 7 ) )->oid . "", "$blob_oid",
    'prefix matching is case-insensitive';

  # The child holds its parent alive (memory ownership contract).
  ok $blob->_owner == $repo, 'the returned wrapper owns the repository';
}

# ---------------------------------------------------------------------------
# Boundary: GIT_OID_MINPREFIXLEN characters is enough.
#
# Its own repository, holding exactly one object, so "4 characters resolve"
# cannot be spoiled by a chance collision with a second object.
# ---------------------------------------------------------------------------
{
  my ( $repo, $tmp ) = TestRepo::new_repo();
  my $oid = $repo->blob_create_frombuffer("only object\n");

  is GIT_OID_MINPREFIXLEN, 4, 'libgit2 minimum prefix length is 4';

  my $obj = $repo->object_by_prefix( substr "$oid", 0, GIT_OID_MINPREFIXLEN );
  is $obj->oid . "", "$oid", 'a prefix of exactly GIT_OID_MINPREFIXLEN resolves';

  # ---- nothing matches ----
  my $err = dies { $repo->object_by_prefix('deadbeef') };
  isa_ok $err, ['Git::Native::Error'], 'an unmatched prefix throws';
  is $err->is_not_found, 1, 'and it is a not-found, like a full OID lookup';
  is $err->is_ambiguous, 0, 'not-found does not answer is_ambiguous';

  # ---- too short: a croak, deliberately not a Git::Native::Error ----
  for my $short ( '', 'a', 'ab', 'abc' ) {
    my $e = dies { $repo->object_by_prefix($short) };
    ok !ref $e,
      "prefix '$short' croaks rather than throwing a Git::Native::Error";
  }
  like dies { $repo->object_by_prefix('abc') },
    qr/shorter than the 4 characters/,
    'the too-short croak says what is wrong';

  # ---- other rejected shapes ----
  like dies { $repo->object_by_prefix( 'a' x 41 ) },
    qr/at most 40 characters/, 'more than 40 characters croaks';
  like dies { $repo->object_by_prefix('zzzzzz') },
    qr/hex OID prefix/, 'a non-hex prefix croaks';
  like dies { $repo->object_by_prefix(undef) },
    qr/hex OID prefix/, 'undef croaks';
}

# ---------------------------------------------------------------------------
# Ambiguity.
#
# Two objects sharing their first 4 hex characters. The blob contents are
# fixed, so their OIDs are fixed and the collision is reproducible; the loop
# only has to find it (261 blobs, measured).
# ---------------------------------------------------------------------------
{
  my ( $repo, $tmp ) = TestRepo::new_repo();

  my ( %seen, $first, $second, $prefix );
  for my $i ( 1 .. 5000 ) {
    my $oid = "" . $repo->blob_create_frombuffer("blob $i\n");
    my $p   = substr $oid, 0, 4;
    if ( $seen{$p} && $seen{$p} ne $oid ) {
      ( $first, $second, $prefix ) = ( $seen{$p}, $oid, $p );
      last;
    }
    $seen{$p} = $oid;
  }

  if ( !$prefix ) {
    fail 'no 4-character OID collision found - cannot exercise the ambiguous path';
  }
  else {
    my $err = dies { $repo->object_by_prefix($prefix) };
    isa_ok $err, ['Git::Native::Error'], 'an ambiguous prefix throws';
    is $err->is_ambiguous, 1, 'is_ambiguous is true for it';

    # Exclusivity against a REAL GIT_EAMBIGUOUS, not a synthetic code: no
    # other curated predicate may answer for it (t/51 does the same sweep
    # over the synthetic codes).
    for my $other (
      qw( is_not_found is_exists is_auth is_certificate is_conflict
      is_not_fast_forward is_unborn_branch is_invalid_spec is_not_matched
      is_locked is_bare_repo )
      )
    {
      is $err->$other, 0, "$other is 0 for a real ambiguous-prefix error";
    }

    # The objects themselves are fine - only the abbreviation is ambiguous.
    is $repo->object_by_prefix($first)->oid . "",  $first,  'first colliding object resolves in full';
    is $repo->object_by_prefix($second)->oid . "", $second, 'second colliding object resolves in full';

    # One more character than they share disambiguates, and picks the right
    # one of the two. This is the tightest check on the nibble semantics: an
    # off-by-one in the length would resolve to the wrong object or stay
    # ambiguous.
    my $common = 4;
    $common++ while substr( $first, $common, 1 ) eq substr( $second, $common, 1 );
    is $repo->object_by_prefix( substr $first, 0, $common + 1 )->oid . "", $first,
      "a $common-plus-1 character prefix picks the first object";
    is $repo->object_by_prefix( substr $second, 0, $common + 1 )->oid . "", $second,
      "the same length picks the second object from its own prefix";
  }
}

done_testing;
