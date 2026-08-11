use strict;
use warnings FATAL => 'all';

use Digest::SHA qw(sha256_hex hmac_sha256);
use File::Spec;
use File::Temp qw(tempdir);
use Socket qw(AF_INET pack_sockaddr_in inet_aton);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathRegistry;

# reference_pbkdf2($password, $salt, $iterations)
# Independent PBKDF2-HMAC-SHA256 reference (single output block) used to
# cross-check the module implementation against RFC test vectors.
# Input: password string, salt string, iteration count.
# Output: 64-character lowercase hex derived key.
sub reference_pbkdf2 {
    my ( $password, $salt, $iterations ) = @_;
    my $u   = hmac_sha256( $salt . pack( 'N', 1 ), $password );
    my $out = $u;
    for ( 2 .. $iterations ) {
        $u = hmac_sha256( $u, $password );
        $out ^= $u;
    }
    return unpack( 'H*', $out );
}

my $home  = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $auth  = Developer::Dashboard::Auth->new( files => $files, paths => $paths );

# ---------------------------------------------------------------------------
# Finding (2): helper passwords must be stretched with a work factor, not a
# single unstretched SHA-256, while pre-existing SHA-256 records keep working.
# ---------------------------------------------------------------------------

# The module's PBKDF2 helper must match published PBKDF2-HMAC-SHA256 vectors,
# proving the stretching primitive is correct and not a bespoke miscalculation.
is(
    Developer::Dashboard::Auth::_pbkdf2_hmac_sha256_hex( 'password', 'salt', 1 ),
    '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    'pbkdf2 matches the RFC vector for one iteration',
);
is(
    Developer::Dashboard::Auth::_pbkdf2_hmac_sha256_hex( 'password', 'salt', 2 ),
    'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
    'pbkdf2 matches the RFC vector for two iterations',
);
is(
    Developer::Dashboard::Auth::_pbkdf2_hmac_sha256_hex( 'password', 'salt', 4096 ),
    reference_pbkdf2( 'password', 'salt', 4096 ),
    'pbkdf2 agrees with an independent reference at a higher work factor',
);

my $username = 'stretchuser';
my $password = 'helper-pass-123';
my $record   = $auth->add_user( username => $username, password => $password );

is( $record->{password_scheme}, 'pbkdf2-hmac-sha256', 'add_user records the stretched password scheme' );
cmp_ok( $record->{iterations}, '>=', 200_000, 'add_user records a strong PBKDF2 work factor' );
is( length( $record->{password_hash} ), 64, 'stored password hash is a 32-byte derived key in hex' );

my $unstretched = sha256_hex( join ':', $record->{salt}, $username, $password );
isnt(
    $record->{password_hash},
    $unstretched,
    'stored password hash is stretched, not a single-round salted SHA-256',
);
is(
    $record->{password_hash},
    reference_pbkdf2( $password, $record->{salt}, $record->{iterations} ),
    'stored password hash is exactly the PBKDF2 derivation of the password',
);

ok( $auth->verify_user( username => $username, password => $password ), 'correct password verifies against a stretched record' );
ok( !$auth->verify_user( username => $username, password => 'wrong-password' ), 'wrong password is rejected for a stretched record' );

# Backward compatibility: a helper record written before stretching existed has
# no scheme label and a single-round SHA-256 hash. It must still verify so an
# upgrade never locks established helper users out of their own dashboard.
my $legacy_user = 'legacyhelper';
my $legacy_salt = 'legacy-fixed-salt';
my $legacy_pass = 'legacy-pass-123';
my $legacy_record = {
    username      => $legacy_user,
    role          => 'helper',
    salt          => $legacy_salt,
    password_hash => sha256_hex( join ':', $legacy_salt, $legacy_user, $legacy_pass ),
    updated_at    => '2026-01-01T00:00:00Z',
};
my $legacy_file = File::Spec->catfile( $paths->users_root, "$legacy_user.json" );
open my $lfh, '>:raw', $legacy_file or die "Unable to write $legacy_file: $!";
print {$lfh} json_encode($legacy_record);
close $lfh;

ok( $auth->verify_user( username => $legacy_user, password => $legacy_pass ), 'legacy single-round SHA-256 records still verify (no lockout on upgrade)' );
ok( !$auth->verify_user( username => $legacy_user, password => 'nope' ), 'legacy records still reject wrong passwords' );

# The constant-time comparison must behave like equality across the edge cases
# that matter for hash checking without leaking match progress via early exit.
ok( Developer::Dashboard::Auth::_secure_compare( 'abc123', 'abc123' ), 'secure compare accepts identical strings' );
ok( !Developer::Dashboard::Auth::_secure_compare( 'abc123', 'abc124' ), 'secure compare rejects equal-length differing strings' );
ok( !Developer::Dashboard::Auth::_secure_compare( 'abc', 'abcd' ), 'secure compare rejects length mismatches' );
ok( !Developer::Dashboard::Auth::_secure_compare( undef, 'abc' ), 'secure compare rejects an undefined operand' );

# ---------------------------------------------------------------------------
# Finding (1): DNS-rebinding admin-trust — FIXED.  Arbitrary hostnames that
# merely resolve to loopback are no longer trusted as admin.  Well-known
# local machine aliases (localhost, localhost.localdomain) are still
# accepted without DNS resolution.
# ---------------------------------------------------------------------------

is(
    $auth->trust_tier( remote_addr => '127.0.0.1', host => '127.0.0.1:7890' ),
    'admin',
    'literal loopback host over a loopback connection stays admin',
);
is(
    $auth->trust_tier( remote_addr => '10.0.0.9', host => '127.0.0.1:7890' ),
    'helper',
    'a non-loopback client never gains admin regardless of the host header',
);
is(
    $auth->trust_tier(
        remote_addr          => '127.0.0.1',
        host                 => 'dashboard-alias.example:7890',
        extra_loopback_hosts => ['dashboard-alias.example'],
    ),
    'admin',
    'an explicitly configured local alias host stays admin',
);

{
    no warnings qw(redefine once);
    local *Developer::Dashboard::Auth::getaddrinfo = sub {
        return (
            0,
            { family => AF_INET, addr => pack_sockaddr_in( 0, inet_aton('127.0.0.1') ) },
        );
    };
    is(
        $auth->trust_tier( remote_addr => '::1', host => 'rebind.attacker.example:7890' ),
        'helper',
        'arbitrary hostnames that only resolve to loopback must not be trusted as admin',
    );
}

done_testing;

__END__

=head1 NAME

t/57-hunt-auth.t - regression hunt for helper-password stretching and loopback admin-trust

=head1 PURPOSE

This test pins two authentication properties of
C<Developer::Dashboard::Auth>. First, that helper passwords are stored stretched
with PBKDF2-HMAC-SHA256 and that older single-round SHA-256 records still
verify. Second, that the loopback admin-trust invariants (literal loopback,
non-loopback clients, and configured aliases) behave correctly, and that an
arbitrary hostname which merely resolves to loopback is refused admin.

=head1 WHY IT EXISTS

An adversarial review flagged that helper passwords used an unstretched
SHA-256 with no work factor, and that a Host header which merely resolves to
loopback could be granted admin from a loopback connection. This file exists so
the password-stretching fix cannot silently regress to an unstretched hash or
break existing stored logins, and so the DNS-rebinding fix that closed the
Host-header hole stays pinned instead of quietly reopening.

=head1 WHEN TO USE

Use this file when changing helper password storage, the password verification
scheme, the legacy-hash compatibility path, the constant-time hash comparison,
or the trust-tier rules that decide when a loopback request is treated as
admin.

=head1 HOW TO USE

Run C<prove -lv t/57-hunt-auth.t> while iterating on the auth module, and keep
it green under C<prove -lr t> and the coverage gate before calling the work
complete. The PBKDF2 assertions cross-check the derivation against published
vectors, the round-trip and legacy-record assertions guard backward
compatibility, and the trust-tier assertions guard the loopback admin
invariants, including the stubbed-resolver case that proves a hostname which
only resolves to loopback is still denied admin.

=head1 WHAT USES IT

Developers changing authentication during TDD, the full repository test suite,
and the release metadata and coverage gates all use this file to keep the auth
module's password and trust behavior verified.

=head1 EXAMPLES

Example 1:

  prove -lv t/57-hunt-auth.t

Run this focused auth regression by itself while editing the auth module.

Example 2:

  prove -lr t

Run the auth regression inside the whole repository suite before release.

=cut
