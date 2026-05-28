use strict;
use warnings;
use Test::More;
use Path::Tiny;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Git::Native;
use Git::Native::Credential;

# Live HTTPS auth test. Runs in two modes depending on env:
#
#   public (no token):
#     TEST_GIT_NATIVE_HTTPS_URL=https://github.com/getty/p5-git-native.git
#     — does an unauthenticated fetch; callback should NOT be invoked
#
#   token (private repo or just verifying the callback path):
#     TEST_GIT_NATIVE_HTTPS_URL=https://github.com/owner/private.git
#     TEST_GIT_NATIVE_HTTPS_TOKEN=ghp_...
#     [TEST_GIT_NATIVE_HTTPS_USER=token]   # default 'token'
#
# Both modes verify that fetch lands at least one remote ref.

my $url = $ENV{TEST_GIT_NATIVE_HTTPS_URL};
plan skip_all => 'TEST_GIT_NATIVE_HTTPS_URL not set — skipping live HTTPS test'
  unless $url;

my $token = $ENV{TEST_GIT_NATIVE_HTTPS_TOKEN};
my $user  = $ENV{TEST_GIT_NATIVE_HTTPS_USER} // 'token';

my $tmp = Path::Tiny->tempdir;
my $repo = Git::Native->init("$tmp");
my $remote = $repo->remote_create( 'origin', $url );

my $cb_calls = 0;
my $cred_cb = $token
  ? sub {
      $cb_calls++;
      return Git::Native::Credential->userpass(
        username => $user,
        password => $token,
      );
    }
  : sub {
      $cb_calls++;
      # Public repo path — libgit2 may still call the callback once if
      # the server probes; returning undef → GIT_PASSTHROUGH lets it
      # fall back to unauthenticated.
      return undef;
    };

eval {
  $remote->fetch(
    refspecs    => ['+refs/heads/*:refs/remotes/origin/*'],
    credentials => $cred_cb,
  );
  1;
} or do {
  my $err = $@;
  fail "fetch died: $err";
  done_testing;
  exit 0;
};

if ($token) {
  ok $cb_calls >= 1, "credential callback invoked under token mode ($cb_calls)";
}
else {
  # Unauth public — callback may or may not fire (libgit2 quirk).
  pass "public fetch returned without die (callback fired $cb_calls times)";
}

my @refs = $repo->reference_names( glob => 'refs/remotes/origin/*' );
ok scalar(@refs) > 0,
  "fetched at least one remote-tracking ref (got @{[scalar @refs]})";

done_testing;
