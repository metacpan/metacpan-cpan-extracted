use Test2::V0;
use Git::Native::Credential;

# t/35-credential.t covers default / username / userpass. The SSH constructors
# were never called - their required-argument croaks and their optional-field
# defaults (public_key may be undef, passphrase defaults to '') were entirely
# unexecuted, which is how a typo'd argument name would have shipped.
#
# No network and no agent contact: git_credential_ssh_key_new and
# git_credential_ssh_key_from_agent only allocate the credential struct. The
# key file is not read until the transport uses it, so a synthetic path is
# enough to reach the allocation.

# ---- required arguments croak before any FFI call ----
# These run on every libgit2 build, including one without SSH support,
# because Carp::croak fires ahead of the FFI.
{
  my $err = dies { Git::Native::Credential->ssh_key( private_key => '/tmp/k' ) };
  like $err, qr/ssh_key: 'username' required/, 'ssh_key without username croaks';
}
{
  my $err = dies { Git::Native::Credential->ssh_key( username => 'git' ) };
  like $err, qr/ssh_key: 'private_key' required/,
    'ssh_key without private_key croaks';
}
{
  my $err = dies { Git::Native::Credential->ssh_agent() };
  like $err, qr/ssh_agent: 'username' required/, 'ssh_agent without username croaks';
}
{
  # A croak, not a libgit2 error - the argument check must happen in Perl
  # before a NULL is handed to C.
  my $err = dies { Git::Native::Credential->ssh_key( username => 'git' ) };
  ok !ref($err),
    'the missing-argument failure is a plain croak string, not a libgit2 error object';
}

# ---- construction ----
# libgit2 can be built without SSH support; there the allocation itself fails.
# Skip loudly rather than shipping a test that fails on such a build.
my $ssh_probe = dies {
  Git::Native::Credential->ssh_key(
    username => 'git', private_key => '/nonexistent/id_ed25519',
  );
};

SKIP: {
  if ($ssh_probe) {
    diag "libgit2 rejected an ssh_key credential: $ssh_probe";
    diag 'this build appears to lack SSH support - skipping the SSH constructors';
    skip 'libgit2 built without SSH support', 4;
  }

  # public_key omitted: the wrapper passes undef and lets libgit2 derive it.
  my $derived = Git::Native::Credential->ssh_key(
    username => 'git', private_key => '/nonexistent/id_ed25519',
  );
  isa_ok $derived, ['Git::Native::Credential'],
    'ssh_key without public_key builds (libgit2 derives it)';

  # Explicit public key and passphrase take the other side of both defaults.
  my $explicit = Git::Native::Credential->ssh_key(
    username    => 'git',
    private_key => '/nonexistent/id_ed25519',
    public_key  => '/nonexistent/id_ed25519.pub',
    passphrase  => 'hunter2',
  );
  isa_ok $explicit, ['Git::Native::Credential'],
    'ssh_key with public_key and passphrase builds';

  my $agent = Git::Native::Credential->ssh_agent( username => 'git' );
  isa_ok $agent, ['Git::Native::Credential'], 'ssh_agent builds';

  # Ownership: a credential that never reaches libgit2 still owns its handle,
  # and DEMOLISH is what frees it. _disown is the only thing that hands it off.
  ok $agent->_handle, 'an unused credential keeps its git_credential*';
}

done_testing;
