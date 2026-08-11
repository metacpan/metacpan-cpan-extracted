use Test2::V0;
use Path::Tiny;
use MIME::Base64 qw( encode_base64 );
use Digest::SHA qw( sha1 sha256 hmac_sha1 );
use Git::Native::Remote ();

# t/43-known-hosts.t unit-tests _host_in_field (the host-field matcher).
# _known_hosts_match - the function that actually opens the known_hosts files,
# walks the lines and decides whether the offered SSH host key is the cached
# one - had no test at all: it is only reachable from the certificate_check
# callback during a live SSH connection, which skips without
# TEST_GIT_NATIVE_SSH_URL.
#
# It is pure logic over $ENV{HOME}/.ssh/known_hosts, so it can be driven from
# a temporary HOME with no network. This is a security decision - "is this the
# host key I trust?" - so the interesting cases are the negative ones:
# unknown host vs. known host with a changed key (they produce different
# warnings), and @revoked / @cert-authority lines that must never count as a
# match.

my $HOST = 'unit-test-host.invalid';

# A synthetic SSH key blob; known_hosts stores it base64-encoded, and the
# digest libssh2 reports is taken over the decoded bytes.
my $key      = join '', map { chr } 0 .. 255;
my $key64    = encode_base64( $key, '' );
my $other    = "a different host key blob";
my $other64  = encode_base64( $other, '' );

# Write a known_hosts file into a throwaway HOME and run the matcher against
# it. Returns (matched, host_seen).
sub match_against {
  my ( $content, %args ) = @_;
  my $home = Path::Tiny->tempdir;
  $home->child('.ssh')->mkpath;
  $home->child( '.ssh', $args{file} // 'known_hosts' )->spew_utf8($content);

  local $ENV{HOME} = "$home";
  return Git::Native::Remote::_known_hosts_match(
    $args{host} // $HOST,
    $args{digest} // 'sha1',
    $args{want} // sha1($key),
  );
}

subtest 'a host that is not in known_hosts at all' => sub {
  my ( $matched, $seen ) = match_against("other.invalid ssh-ed25519 $key64\n");
  is $matched, 0, 'no match';
  is $seen, 0,
    'host_seen is 0 - the caller reports "host is not in known_hosts", not "key changed"';
};

subtest 'a cached key that matches' => sub {
  my ( $matched, $seen ) = match_against("$HOST ssh-ed25519 $key64\n");
  is $matched, 1, 'the offered key matches the cached one';
  is $seen, 1, 'and the host was seen once';
};

subtest 'a cached key that does NOT match' => sub {
  # This is the case that must be distinguishable from "unknown host": the
  # host is known, so a non-zero host_seen makes the caller warn about a
  # changed / unexpected key instead of an unknown host.
  my ( $matched, $seen ) = match_against("$HOST ssh-ed25519 $other64\n");
  is $matched, 0, 'a different cached key does not match';
  is $seen, 1, 'but the host WAS seen, so the caller can say "key changed"';
};

subtest 'sha256 fingerprints' => sub {
  my ( $matched, $seen ) = match_against(
    "$HOST ssh-ed25519 $key64\n", digest => 'sha256', want => sha256($key),
  );
  is $matched, 1, 'a sha256 digest is compared against sha256 of the blob';

  # Feeding the sha1 digest while asking for sha256 must not match - the
  # digest argument really selects the hash, it is not cosmetic.
  my ($mismatch) = match_against(
    "$HOST ssh-ed25519 $key64\n", digest => 'sha256', want => sha1($key),
  );
  is $mismatch, 0, 'a sha1 value does not satisfy a sha256 comparison';
};

subtest 'comments, blank lines and short lines are skipped' => sub {
  my $content = <<"KH";
# a comment line

   # an indented comment
short-line-too-few-fields
$HOST ssh-ed25519 $key64
KH
  my ( $matched, $seen ) = match_against($content);
  is $matched, 1, 'the real entry is still found past the noise';
  is $seen, 1, 'and nothing else was counted as an entry for the host';
};

subtest '@revoked and @cert-authority never count as a match' => sub {
  # Both markers mean "this is not a host key you may connect with". Even
  # with the exact key bytes cached, the line must be ignored entirely -
  # including for host_seen, so the caller reports an unknown host.
  for my $marker ( '@revoked', '@cert-authority' ) {
    my ( $matched, $seen ) = match_against("$marker $HOST ssh-ed25519 $key64\n");
    is $matched, 0, "$marker line does not authorise the key";
    is $seen, 0, "$marker line is not counted as an entry for the host";
  }
};

subtest 'an unparsable key field is skipped, but the host still counts' => sub {
  # '!!!' is not base64; decode_base64 gives an empty blob. The line must be
  # skipped rather than compared against the digest of the empty string, but
  # the host has been seen.
  my ( $matched, $seen ) = match_against("$HOST ssh-ed25519 !!!\n");
  is $matched, 0, 'an empty key blob does not match';
  is $seen, 1, 'the host was still seen';
};

subtest 'several entries for the same host' => sub {
  # OpenSSH caches one line per key type. A match on any of them is a match,
  # and host_seen counts every line that named the host.
  my ( $matched, $seen ) = match_against(
    "$HOST ssh-rsa $other64\n$HOST ssh-ed25519 $key64\n",
  );
  is $matched, 1, 'a later entry can supply the match';
  is $seen, 2, 'host_seen counts both entries for the host';
};

subtest 'hashed host fields are matched too' => sub {
  # OpenSSH's HashKnownHosts format: |1|<base64 salt>|<base64 hmac-sha1>.
  my $salt  = pack 'C*', 1 .. 20;
  my $field = '|1|' . encode_base64( $salt, '' ) . '|'
            . encode_base64( hmac_sha1( $HOST, $salt ), '' );

  my ( $matched, $seen ) = match_against("$field ssh-ed25519 $key64\n");
  is $matched, 1, 'a hashed host field resolves to the host';
  is $seen, 1, 'and is counted once';
};

subtest 'empty elements in a comma-separated host field are skipped' => sub {
  # A stray comma must not produce an empty pattern that matches everything -
  # that would turn one malformed line into "trust any host".
  my ( $matched, $seen ) =
    match_against(",,$HOST,, ssh-ed25519 $key64\n");
  is $matched, 1, 'the real host in the list still matches';

  my ($other_host) = match_against(
    ",, ssh-ed25519 $key64\n", host => 'somewhere-else.invalid',
  );
  is $other_host, 0, 'a field of nothing but commas matches no host';
};

subtest 'known_hosts2 is consulted as well' => sub {
  my ( $matched, $seen ) = match_against(
    "$HOST ssh-ed25519 $key64\n", file => 'known_hosts2',
  );
  is $matched, 1, 'an entry in known_hosts2 is honoured';
};

subtest 'a HOME with no .ssh directory is not an error' => sub {
  my $home = Path::Tiny->tempdir;
  local $ENV{HOME} = "$home";
  my ( $matched, $seen ) = Git::Native::Remote::_known_hosts_match(
    $HOST, 'sha1', sha1($key),
  );
  is $matched, 0, 'no known_hosts anywhere -> no match';
  is $seen, 0, 'and no entries seen, rather than a die on the missing file';
};

done_testing;
