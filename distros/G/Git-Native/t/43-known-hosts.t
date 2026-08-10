use strict;
use warnings;
use Test::More;
use MIME::Base64 qw( encode_base64 );
use Digest::SHA qw( hmac_sha1 );
use Git::Native::Remote;

# Unit tests for the known_hosts host-field matching that backs the SSH
# certificate_check callback. Pure string/crypto logic — no network, no
# libgit2 connection.

no warnings 'once';
*host_in_field = \&Git::Native::Remote::_host_in_field;

# Build a hashed (|1|salt|hash) field the way OpenSSH does: HMAC-SHA1 of
# the hostname, keyed by the (raw) salt, both base64-encoded.
sub hashed_field {
  my ($host) = @_;
  my $salt = pack 'C*', map { $_ } 1 .. 20;   # 20 fixed bytes
  return '|1|' . encode_base64( $salt, '' ) . '|'
       . encode_base64( hmac_sha1( $host, $salt ), '' );
}

my $hf = hashed_field('github.com');

ok host_in_field( 'github.com',   $hf ), 'hashed host matches';
ok !host_in_field( 'evil.example', $hf ), 'hashed host rejects other host';

ok host_in_field( 'github.com', 'github.com,140.82.112.3' ),
  'plain comma list matches';
ok !host_in_field( 'gitlab.com', 'github.com,140.82.112.3' ),
  'plain comma list rejects other host';

ok host_in_field( 'github.com', '[github.com]:22' ),
  '[host]:port form matches';

ok host_in_field( 'a.github.com', '*.github.com' ),  'wildcard * matches';
ok !host_in_field( 'github.com',  '*.github.com' ),  'wildcard * needs a label';
ok host_in_field( 'host1', 'host?' ),                'wildcard ? matches';

ok host_in_field( 'GitHub.com', 'github.com' ),
  'host matching is case-insensitive';

# _known_hosts_match: an unknown host yields (matched=0, host_seen=0) even
# against the operator's real known_hosts.
my ( $matched, $seen )
  = Git::Native::Remote::_known_hosts_match(
      'nonexistent.invalid.example', 'sha256', "\0" x 32 );
ok !$matched, 'unknown host does not match';
is $seen, 0, 'unknown host is never seen in known_hosts';

done_testing;
