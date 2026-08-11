use Test2::V0;
use Git::Libgit2 qw( init_lib GIT_PASSTHROUGH );
use Git::Native::Remote ();
use Git::Native::Credential ();
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

# Network-free unit test for the credential-acquire thunk.
#
# Why this file exists: a file:// fetch never asks for credentials (libgit2
# calls the registered callback zero times - instrumented, see the note in
# t/20-remote-local.t), and t/40 / t/41 skip without operator-set env vars.
# So the whole credential path - the FFI closure, the PASSTHROUGH mapping,
# the disown-and-memcpy handoff - had no test that runs on a clean checkout.
#
# Git::Native::Remote::_make_credential_thunk is a pure function: it takes the
# user's coderef and returns ($closure, $keepalive). An FFI::Platypus::Closure
# is a blessed CODE ref, so the closure can be invoked straight from Perl with
# synthetic arguments - exactly the values libgit2 would pass for
#   int cb(git_credential **out, const char *url,
#          const char *username_from_url, unsigned int allowed_types,
#          void *payload)
# The one thing we cannot fake is libgit2 taking ownership of the credential,
# so the success case frees the handed-off pointer itself.

init_lib();

# Synthetic call arguments, standing in for what libgit2 passes.
my $URL          = 'https://example.invalid/repo.git';
my $USER_FROM_URL = 'git';
my $ALLOWED       = 3;   # USERPASS_PLAINTEXT | SSH_KEY bitmask

# Allocate a writable 8-byte cell for the `git_credential **out` out-param and
# return ( $address, \$scalar ) - the scalar must stay alive while the address
# is in use. Same scalar_to_buffer trick Remote.pm uses to write into C memory.
sub out_cell {
  my $buf = "\0" x 8;
  my ($addr) = scalar_to_buffer($buf);
  return ( $addr, \$buf );
}

subtest 'user coderef returning undef maps to GIT_PASSTHROUGH' => sub {
  my @calls;
  my ( $closure, $keep ) = Git::Native::Remote::_make_credential_thunk(
    sub { push @calls, {@_}; return undef },
  );

  my ( $out, $cell ) = out_cell();
  my $rc = $closure->( $out, $URL, $USER_FROM_URL, $ALLOWED, 0 );

  is $rc, GIT_PASSTHROUGH,
    'undef from the user callback returns GIT_PASSTHROUGH so libgit2 tries the next auth type';
  is $rc, -30, 'GIT_PASSTHROUGH is -30 (the value libgit2 checks for)';

  is unpack( 'J', $$cell ), 0,
    'the out-param is left NULL on PASSTHROUGH - libgit2 must not read a stale pointer';

  is scalar(@calls), 1, 'the user callback was invoked exactly once';
  is $calls[0], {
    url               => $URL,
    username_from_url => $USER_FROM_URL,
    allowed_types     => $ALLOWED,
  }, 'the user callback gets url / username_from_url / allowed_types as named args';

  ok $keep, 'the thunk returns a keepalive alongside the closure';
};

subtest 'a Git::Native::Credential is handed to libgit2 through the out-param' => sub {
  my $cred   = Git::Native::Credential->userpass(
    username => 'user', password => 's3cr3t',
  );
  my $handle = $cred->_handle;
  ok $handle, 'the credential wrapper starts out owning a git_credential*';

  my ( $closure, $keep ) = Git::Native::Remote::_make_credential_thunk(
    sub { return $cred },
  );

  my ( $out, $cell ) = out_cell();
  my $rc = $closure->( $out, $URL, $USER_FROM_URL, $ALLOWED, 0 );

  is $rc, 0, 'returning a credential returns 0 (libgit2 takes it from here)';
  is unpack( 'J', $$cell ), $handle,
    'the git_credential* was memcpy-ed into the out-param';
  is $cred->_handle, undef,
    'the wrapper was disowned, so DEMOLISH cannot double-free what libgit2 now owns';

  # libgit2 is not actually here to free it - do its job so the test does not
  # leak the credential it just handed over.
  Git::Libgit2::FFI::git_credential_free($handle);
};

subtest 'a dying user coderef is contained inside the closure' => sub {
  my ( $closure, $keep ) = Git::Native::Remote::_make_credential_thunk(
    sub { die "no credentials for you\n" },
  );

  my ( $out, $cell ) = out_cell();
  my @warnings;
  my $rc;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $rc = $closure->( $out, $URL, $USER_FROM_URL, $ALLOWED, 0 );
  }

  is $rc, -1,
    'a die in the user callback becomes rc -1, not a Perl exception unwinding through C';
  is unpack( 'J', $$cell ), 0, 'the out-param stays NULL when the callback died';
  is scalar(@warnings), 1, 'the failure is reported once, not swallowed';
  like $warnings[0], qr/credential callback died: no credentials for you/,
    'the warning carries the original error';
};

# Regression test for karr ticket 4. The type check used to Carp::croak from
# *outside* the eval that wraps the user coderef, so a callback returning the
# wrong thing unwound a Perl exception out of the FFI closure through libgit2's
# C frames - exactly what the eval one line above was there to prevent.
#
# Each shape below hit a different flavour of the same bug: a plain string
# reached the croak; an unblessed reference died one step earlier inside
# ->isa ("Can't call method \"isa\" on unblessed reference"), because the guard
# tested `ref $cred` (true for any reference) rather than blessedness; a
# blessed object of the wrong class reached the croak too.
#
# The contract now: warn with the same diagnosis the croak carried, and return
# a negative rc. Not GIT_PASSTHROUGH - a broken callback must fail the
# operation loudly, not fall through to the next auth type and surface later
# as a generic "authentication required".
subtest 'a user coderef returning a non-credential is contained inside the closure' => sub {
  my @cases = (
    { what    => 'a plain string',
      value   => 'ssh-agent',
      names   => qr/'ssh-agent'/ },
    { what    => 'an unblessed reference',
      value   => { username => 'git' },
      names   => qr/HASH reference/ },
    { what    => 'a blessed object of the wrong class',
      value   => bless( {}, 'Git::Native::NotACredential' ),
      names   => qr/Git::Native::NotACredential object/ },
  );

  for my $case (@cases) {
    my $what = $case->{what};
    my ( $closure, $keep ) = Git::Native::Remote::_make_credential_thunk(
      sub { return $case->{value} },
    );

    my ( $out, $cell ) = out_cell();
    my @warnings;
    my $rc;
    my $survived = lives {
      local $SIG{__WARN__} = sub { push @warnings, $_[0] };
      $rc = $closure->( $out, $URL, $USER_FROM_URL, $ALLOWED, 0 );
    };

    ok $survived,
      "$what: the closure returns instead of dying out through libgit2's C frames";
    is $rc, -1, "$what: reported as rc -1";
    isnt $rc, GIT_PASSTHROUGH,
      "$what: NOT passthrough - a broken callback must not silently fall through to the next auth type";
    is unpack( 'J', $$cell ), 0,
      "$what: the out-param stays NULL, so libgit2 never dereferences a credential we did not produce";
    is scalar(@warnings), 1, "$what: diagnosed exactly once";
    like $warnings[0], qr/must return a Git::Native::Credential/,
      "$what: the warning states the contract the callback broke";
    like $warnings[0], $case->{names},
      "$what: the warning names what the callback actually returned";
  }
};

done_testing;
