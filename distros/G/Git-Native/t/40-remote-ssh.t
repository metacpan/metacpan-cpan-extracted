use strict;
use warnings;
use Test::More;
use Path::Tiny;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Git::Native;
use Git::Native::Credential;

# Live SSH auth test. Skipped unless the operator has wired a real
# remote in via env vars. Two modes:
#
#   ssh-agent path:
#     TEST_GIT_NATIVE_SSH_URL=git@github.com:getty/p5-git-native.git
#     (no other vars — uses the running ssh-agent)
#
#   explicit key path:
#     TEST_GIT_NATIVE_SSH_URL=git@host:owner/repo.git
#     TEST_GIT_NATIVE_SSH_KEY=/path/to/id_ed25519
#     [TEST_GIT_NATIVE_SSH_PASSPHRASE=...]
#
# What gets exercised either way: remote_create → fetch with a
# credentials callback, ref-walk to confirm something came across.

my $url = $ENV{TEST_GIT_NATIVE_SSH_URL};
plan skip_all => 'TEST_GIT_NATIVE_SSH_URL not set — skipping live SSH auth test'
  unless $url;

my $key_path = $ENV{TEST_GIT_NATIVE_SSH_KEY};
if ($key_path) {
  plan skip_all => "SSH key not readable at $key_path" unless -r $key_path;
}

# TestRepo redirects HOME into a throwaway directory, and ~/.ssh is the whole
# reason that redirect still exists (karr-13): ssh keys, and above all
# ~/.ssh/known_hosts, which Git::Native::Remote verifies the hostkey against.
# This test is exactly the case that wants the operator's real ~/.ssh back - an
# empty HOME would silently downgrade hostkey checking to "host not in
# known_hosts, warn and continue". $REAL_HOME is captured in TestRepo's BEGIN
# block before the redirect, so it is the operator's actual home.
#
# Handing HOME back cannot undo the config isolation: the config no longer
# follows HOME at all. TestRepo pins libgit2's system / global / xdg search
# paths with Git::Native->set_config_search_path, which is process-global and
# indifferent to $ENV{HOME} (t/69-config-isolation.t).
$ENV{HOME} = $TestRepo::REAL_HOME if defined $TestRepo::REAL_HOME;

my $tmp = Path::Tiny->tempdir;
my $repo = Git::Native->init("$tmp");
my $remote = $repo->remote_create( 'origin', $url );

my $cb_calls = 0;
my $cred_cb = sub {
  my (%args) = @_;
  $cb_calls++;
  my $user = $args{username_from_url} // 'git';
  if ($key_path) {
    return Git::Native::Credential->ssh_key(
      username    => $user,
      private_key => $key_path,
      public_key  => -r "${key_path}.pub" ? "${key_path}.pub" : undef,
      passphrase  => $ENV{TEST_GIT_NATIVE_SSH_PASSPHRASE} // '',
    );
  }
  return Git::Native::Credential->ssh_agent( username => $user );
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

ok $cb_calls >= 1, "credential callback was invoked at least once ($cb_calls)";

my @refs = $repo->reference_names( glob => 'refs/remotes/origin/*' );
ok scalar(@refs) > 0, "fetched at least one remote-tracking ref (got @{[scalar @refs]})";

done_testing;
