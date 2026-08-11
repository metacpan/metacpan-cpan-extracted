use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Native::Oid;
use Git::Native::Signature;

# What a malformed OID string does, across the whole "Oid|hex" convenience.
#
# Every method in Git::Native that documents an argument as "an Oid or a hex
# string" converts it in Git::Native::Oid->from_hex, so one decision covers all
# of them. The decision is: a malformed OID is a caller error and dies as a
# croak - a plain string naming the caller's line - NOT as a Git::Native::Error.
#
# The reasoning, which is what this file is really pinning:
#
#   * A Git::Native::Error carries a ->code that came out of libgit2 through
#     check_rc. A string that is not 40 hex characters never reaches libgit2 -
#     git_oid_fromstr is not called - so there is no code to report. A
#     synthetic one would be the only fabricated ->code in the distribution.
#
#   * The code it would have to fabricate is GIT_EINVALIDSPEC, which libgit2
#     raises for real on a refname or refspec it rejects. Sharing it would make
#     is_invalid_spec ambiguous inside a single call: after
#     reference_create($name, $hex) the caller could no longer tell a bad
#     refname from its own typo in the OID. The last block below drives exactly
#     that call twice, once bad in each argument, and asserts the two failures
#     stay apart.
#
# Same separation t/71-object-prefix.t keeps for is_ambiguous, and the same
# style of argument check t/70-commit-create-args.t pins for commit_create -
# with one difference worth naming: object_by_prefix had to discard a code
# libgit2 had already produced, this only has to decline to invent one.

my ( $repo, $tmp ) = TestRepo::new_repo();

my $blob = $repo->blob_create_frombuffer("oid-invalid-input\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'f', oid => $blob, mode => 0100644 );
my $tree   = $tb->write;
my $commit = $repo->commit_create(
  tree => $tree, parents => [], message => 'root', update_ref => 'HEAD',
);
my $hex    = "$commit";

# The croak has to blame the line that passed the bad string, not a line
# inside the distribution - that is the diagnosis bar t/70 sets for
# commit_create, and reaching it through a wrapper method is what
# Git::Native::Oid's @CARP_NOT is for.
my $blames_caller = qr{at \S*73-oid-invalid-input\.t line \d+};

sub croaks_on_bad_oid {
  my ( $name, $code ) = @_;
  subtest $name => sub {
    my $err = dies { $code->() };
    ok defined $err, 'the call dies';
    ok !ref $err, 'the failure is a croak, not a Git::Native::Error object';
    like "$err", qr/Git::Native::Oid->from_hex requires a 40-character hex OID/,
      'the message names from_hex and what it wanted';
    like "$err", $blames_caller, 'and blames the caller, not the wrapper';
  };
}

# ---------------------------------------------------------------------------
# from_hex itself: what it rejects, and what it still accepts.
# ---------------------------------------------------------------------------
subtest 'from_hex rejects everything that is not 40 hex characters' => sub {
  croaks_on_bad_oid "undef",            sub { Git::Native::Oid->from_hex(undef) };
  croaks_on_bad_oid "empty string",     sub { Git::Native::Oid->from_hex('') };
  croaks_on_bad_oid "39 hex chars",     sub { Git::Native::Oid->from_hex( 'a' x 39 ) };
  croaks_on_bad_oid "41 hex chars",     sub { Git::Native::Oid->from_hex( 'a' x 41 ) };
  croaks_on_bad_oid "40 non-hex chars", sub { Git::Native::Oid->from_hex( 'z' x 40 ) };
  croaks_on_bad_oid "a whole sentence", sub { Git::Native::Oid->from_hex('not an oid') };

  # A trailing newline is the classic one: `my $sha = <$fh>;` unchomped. It is
  # 41 characters and must not be quietly trimmed into a valid OID.
  croaks_on_bad_oid "a trailing newline", sub { Git::Native::Oid->from_hex("$hex\n") };

  # And the accepted shapes, so the guard cannot pass by rejecting everything.
  is( Git::Native::Oid->from_hex($hex)->hex,
    $hex, 'a full 40-char hex is accepted' );
  is( Git::Native::Oid->from_hex( uc $hex )->hex,
    $hex, 'uppercase hex is accepted and normalised, as libgit2 does it' );
};

# ---------------------------------------------------------------------------
# The message points at the method that DOES resolve an abbreviation. A short
# run of hex digits is almost always an abbreviated OID, and until #6 there was
# nothing to point at; now there is, so the croak says so.
# ---------------------------------------------------------------------------
subtest 'a short hex string is told where abbreviations are resolved' => sub {
  my $err = dies { Git::Native::Oid->from_hex( substr $hex, 0, 7 ) };
  like "$err", qr/object_by_prefix/,
    'an abbreviated OID is pointed at Repository->object_by_prefix';
  like "$err", qr/\(7 characters\)/, 'and told how many characters it had';

  # Only for something that could plausibly be an abbreviation - a sentence
  # gets no such advice.
  unlike dies { Git::Native::Oid->from_hex('not an oid') }, qr/object_by_prefix/,
    'non-hex input gets no abbreviation hint';

  # The pointer is not just advice: the method it names really does take this.
  is $repo->object_by_prefix( substr $hex, 0, 7 )->oid . "", $hex,
    'and following the advice works';
};

# ---------------------------------------------------------------------------
# from_raw, the sibling constructor: same kind of failure, same reasoning.
# ---------------------------------------------------------------------------
subtest 'from_raw rejects anything that is not 20 bytes' => sub {
  for my $case ( [ 'undef', undef ], [ 'empty', '' ], [ '19 bytes', "\0" x 19 ],
    [ '21 bytes', "\0" x 21 ], [ 'a hex string', $hex ] )
  {
    my ( $label, $value ) = @$case;
    my $err = dies { Git::Native::Oid->from_raw($value) };
    ok !ref $err, "$label croaks rather than throwing a Git::Native::Error";
    like "$err", qr/Git::Native::Oid->from_raw requires exactly 20 bytes/,
      "$label is told what from_raw wanted";
  }
  is( Git::Native::Oid->from_raw( $repo->commit($hex)->oid->raw )->hex,
    $hex, 'the 20-byte form is still accepted' );
};

# ---------------------------------------------------------------------------
# The whole Oid|hex convenience, one call per wrapper that takes one. This is
# the part that makes the decision a distribution-wide contract rather than a
# property of one constructor.
# ---------------------------------------------------------------------------
subtest 'every wrapper taking Oid|hex croaks the same way' => sub {
  my $bad = 'abc';

  croaks_on_bad_oid 'Repository->object',  sub { $repo->object($bad) };
  croaks_on_bad_oid 'Repository->tree',    sub { $repo->tree($bad) };
  croaks_on_bad_oid 'Repository->commit',  sub { $repo->commit($bad) };
  croaks_on_bad_oid 'Repository->blob',    sub { $repo->blob($bad) };
  croaks_on_bad_oid 'Repository->commit_create (tree)',
    sub { $repo->commit_create( tree => $bad, message => 'm' ) };
  croaks_on_bad_oid 'Repository->commit_create (parents)',
    sub { $repo->commit_create( tree => $tree, parents => [$bad], message => 'm' ) };
  croaks_on_bad_oid 'Repository->reference_create',
    sub { $repo->reference_create( 'refs/heads/x', $bad ) };
  croaks_on_bad_oid 'Repository->reference_create (expected_old)',
    sub { $repo->reference_create( 'refs/heads/x', $commit, expected_old => $bad ) };
  croaks_on_bad_oid 'Repository->branch_create',
    sub { $repo->branch_create( 'x', $bad ) };
  croaks_on_bad_oid 'Repository->tag_create',
    sub {
      $repo->tag_create( 'v1', $bad, message => "m\n",
        tagger => Git::Native::Signature->new( name => 'T', email => 't@e' ) );
    };
  croaks_on_bad_oid 'Reference->set_target',
    sub { $repo->head->set_target($bad) };
  croaks_on_bad_oid 'Revwalker->push_oid',
    sub { $repo->revwalker->push_oid($bad) };
  croaks_on_bad_oid 'Revwalker->hide_oid',
    sub { $repo->revwalker->hide_oid($bad) };
  croaks_on_bad_oid 'TreeBuilder->insert',
    sub { $repo->tree_builder->insert( name => 'f', oid => $bad, mode => 0100644 ) };
};

# ---------------------------------------------------------------------------
# The reason for all of the above, made falsifiable.
#
# One method, two arguments, two ways to be wrong. The refname is libgit2's
# verdict on repository input and arrives as GIT_EINVALIDSPEC; the OID string
# is the caller's own typo and arrives as a croak. Had from_hex thrown
# GIT_EINVALIDSPEC too, these two would be indistinguishable - is_invalid_spec
# would answer for both and could not tell the caller which argument to fix.
# ---------------------------------------------------------------------------
subtest 'a bad refname and a bad OID stay distinguishable' => sub {
  my $bad_name = dies { $repo->reference_create( 'refs/heads/bad..name', $commit ) };
  isa_ok $bad_name, ['Git::Native::Error'],
    'a refname libgit2 rejects throws a Git::Native::Error';
  is $bad_name->is_invalid_spec, 1, 'and is_invalid_spec answers for it';

  my $bad_oid = dies { $repo->reference_create( 'refs/heads/ok', 'abc' ) };
  ok !ref $bad_oid, 'a malformed OID in the same call croaks instead';
  ok !( ref($bad_oid) && $bad_oid->isa('Git::Native::Error') ),
    'so is_invalid_spec is never asked about it';

  # Both arguments good: the call works, so neither failure above is the
  # method simply being broken.
  isa_ok $repo->reference_create( 'refs/heads/ok', $commit ),
    ['Git::Native::Reference'], 'with both arguments right the ref is created';
};

done_testing;
