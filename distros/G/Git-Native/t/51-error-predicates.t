use Test2::V0;
use Git::Libgit2 qw(
  init_lib
  GIT_ENOTFOUND GIT_EEXISTS GIT_EAUTH GIT_ECERTIFICATE GIT_ECONFLICT
  GIT_ENONFASTFORWARD GIT_EUNBORNBRANCH GIT_EINVALIDSPEC GIT_EMODIFIED
  GIT_ELOCKED GIT_EBAREREPO GIT_EAMBIGUOUS GIT_EOWNER
);
use Git::Native::Error qw( check_rc );

# Network-free contract test for Git::Native::Error itself.
#
# t/46-error-paths.t proves that REAL libgit2 failures arrive as a Throwable
# Git::Native::Error. This file pins the other half: that the curated is_*
# predicates each answer for exactly one libgit2 code, and that check_rc's
# pass-through / throw split behaves as documented. Both were reachable only
# incidentally before - most predicates had never been called on their own
# code, so a mis-wired constant (is_auth comparing GIT_ECERTIFICATE, say)
# would have shipped silently.
#
# The table below is the COMPLETE matrix over the curated predicates, and has
# to stay complete: a predicate added to Git::Native::Error and not added here
# is the one case this file exists to catch. Three of them are additionally
# pinned against a real libgit2 failure - is_bare_repo in t/46-error-paths.t
# (status() on a bare repository), is_ambiguous in t/71-object-prefix.t
# (colliding OID prefixes), is_owner_mismatch in t/72-owner-mismatch.t (a
# working directory owned by another uid). Those pins are complementary, not a
# substitute: they assert which code libgit2 really produces for a situation,
# this file asserts that each predicate is wired to exactly one code and to
# nobody else's. is_bare_repo used to be left out here on the grounds that its
# real-failure pin was the stronger assertion; it is back, because the two
# assertions are about different things and the hole showed up as soon as a
# fourth predicate had to decide which side it belonged on.

init_lib();

# code => predicate that must answer for it. Every other predicate in this
# table must answer 0 for that same code.
my %code_for = (
  is_not_found        => GIT_ENOTFOUND,
  is_exists           => GIT_EEXISTS,
  is_auth             => GIT_EAUTH,
  is_certificate      => GIT_ECERTIFICATE,
  is_conflict         => GIT_ECONFLICT,
  is_not_fast_forward => GIT_ENONFASTFORWARD,
  is_unborn_branch    => GIT_EUNBORNBRANCH,
  is_invalid_spec     => GIT_EINVALIDSPEC,
  is_not_matched      => GIT_EMODIFIED,
  is_locked           => GIT_ELOCKED,
  is_bare_repo        => GIT_EBAREREPO,
  is_ambiguous        => GIT_EAMBIGUOUS,
  is_owner_mismatch   => GIT_EOWNER,
);

# The table is only an oracle while it covers everything Git::Native::Error
# offers. Derived from the symbol table so a new predicate cannot be added to
# the module and quietly skipped here.
{
  no strict 'refs';
  my @curated = sort grep { /\Ais_/ && defined &{"Git::Native::Error::$_"} }
    keys %{'Git::Native::Error::'};
  is [ sort keys %code_for ], \@curated,
    'every is_* predicate on Git::Native::Error is covered by this table';
}

my @predicates = sort keys %code_for;

# Sanity on the table before it is used as an oracle: if two GIT_E* constants
# collided, the exclusivity sweep below would fail for a reason that has
# nothing to do with Git::Native::Error.
{
  my %seen;
  $seen{ $code_for{$_} }++ for @predicates;
  is scalar(keys %seen), scalar(@predicates),
    'the libgit2 codes under test are pairwise distinct';
}

# Each predicate: 1 on its own code, 0 on every other predicate's code.
for my $pred (@predicates) {
  subtest $pred => sub {
    my $own = $code_for{$pred};
    my $err = Git::Native::Error->new( code => $own, message => 'synthetic' );

    is $err->$pred, 1, "$pred is 1 for code $own";

    for my $other ( grep { $_ ne $pred } @predicates ) {
      my $foreign = Git::Native::Error->new(
        code => $code_for{$other}, message => 'synthetic',
      );
      is $foreign->$pred, 0,
        "$pred is 0 for the code $other answers for ($code_for{$other})";
    }

    # An unrelated code (libgit2's generic -1) must not light anything up.
    my $generic = Git::Native::Error->new( code => -1, message => 'x' );
    is $generic->$pred, 0, "$pred is 0 for the generic error code -1";
  };
}

# ---- check_rc: the pass-through side ----
# check_rc is called on every FFI int-return in the distribution, so its
# non-throwing path has to return the rc unchanged - callers rely on the
# value (e.g. git_repository_head_unborn returns 1/0 through it).
is check_rc(0),  0,  'check_rc(0) passes 0 through';
is check_rc(1),  1,  'check_rc(1) passes a positive rc through';
is check_rc(42), 42, 'check_rc keeps a larger positive rc';
is check_rc(undef), undef,
  'check_rc(undef) is a no-op (unbound FFI symbol, not a failure)';

# ---- check_rc: the throwing side ----
# No real libgit2 call precedes this, so the thread-local error is empty;
# what must still hold is the wrapper contract: a Git::Native::Error whose
# code is the rc we passed, never a leaked Git::Libgit2::Error.
{
  my $err = dies { check_rc(-99) };
  isa_ok $err, ['Git::Native::Error'], 'negative rc throws Git::Native::Error';
  isa_ok $err, ['Throwable::Error'],   'and it is Throwable';
  ok !$err->isa('Git::Libgit2::Error'),
    'the low-level Git::Libgit2::Error does not leak out of check_rc';
  is $err->code, -99, 'check_rc propagates the rc as ->code';
  ok defined $err->message && length $err->message,
    'a message is always set, even with no libgit2 error pending';
}

# ---- BUILDARGS ----
# Constructed without a message (the shape check_rc would produce if libgit2
# handed back an empty error), the object must still stringify to something
# rather than dying on a missing required attribute.
{
  my $err = Git::Native::Error->new( code => -1 );
  is $err->message, '<unknown libgit2 error>', 'missing message gets a default';
  is $err->klass, 0, 'klass defaults to 0';
}
{
  my $err = Git::Native::Error->new( code => -1, message => undef );
  is $err->message, '<unknown libgit2 error>',
    'an explicitly undef message gets the same default';
}
{
  my $err = Git::Native::Error->new( code => -1, message => 'real message' );
  is $err->message, 'real message', 'a supplied message is left alone';
}
{
  # Moo BUILDARGS accepts the hashref calling convention as well as a list.
  my $err = Git::Native::Error->new(
    { code => GIT_ENOTFOUND, klass => 11, message => 'from hashref' },
  );
  is $err->code, GIT_ENOTFOUND, 'hashref form sets code';
  is $err->klass, 11,           'hashref form sets klass';
  is $err->message, 'from hashref', 'hashref form sets message';
  is $err->is_not_found, 1, 'predicates work on a hashref-built error';
}

# code has no default: leaving it out is a programming error, not a silent 0.
{
  my $err = dies { Git::Native::Error->new( message => 'no code' ) };
  ok $err, 'code is required';
}

done_testing;
