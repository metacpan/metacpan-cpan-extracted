use Test2::V0;
use Git::Native::Credential;

# default credential — no auth info needed
{
  my $cred = Git::Native::Credential->default;
  isa_ok( $cred, ['Git::Native::Credential'], 'default credential' );
}

# username-only credential
{
  my $cred = Git::Native::Credential->username( username => 'git' );
  isa_ok( $cred, ['Git::Native::Credential'], 'username credential' );
}

# userpass credential
{
  my $cred = Git::Native::Credential->userpass(
    username => 'user',
    password => 's3cr3t',
  );
  isa_ok( $cred, ['Git::Native::Credential'], 'userpass credential' );
}

# missing required args → croak
{
  my $err = dies { Git::Native::Credential->userpass( password => 'x' ) };
  like( $err, qr/username.*required/i, 'userpass: username required' );
}
{
  my $err = dies { Git::Native::Credential->userpass( username => 'u' ) };
  like( $err, qr/password.*required/i, 'userpass: password required' );
}
{
  my $err = dies { Git::Native::Credential->username() };
  like( $err, qr/username.*required/i, 'username: username required' );
}

# ssh_key — skip unless test key files present
SKIP: {
  my $priv = $ENV{TEST_GIT_NATIVE_SSH_KEY};
  skip 'TEST_GIT_NATIVE_SSH_KEY not set — skipping ssh_key test', 1
    unless $priv && -f $priv;

  my $cred = Git::Native::Credential->ssh_key(
    username    => 'git',
    private_key => $priv,
  );
  isa_ok( $cred, ['Git::Native::Credential'], 'ssh_key credential' );
}

done_testing;
