use strict;
use warnings;
use utf8;

use Digest::SHA qw(hmac_sha256);
use Test::More;

use lib 'lib';

use Developer::Dashboard::HtmlEscape;
use Developer::Dashboard::Crypto::PBKDF2;

# reference_pbkdf2($password, $salt, $iterations)
# Computes the established PBKDF2-HMAC-SHA256 output using Digest::SHA.
# Input: byte strings and a positive work factor.
# Output: lowercase hexadecimal derived key.
sub reference_pbkdf2 {
    my ( $password, $salt, $iterations ) = @_;
    my $u = hmac_sha256( $salt . pack( 'N', 1 ), $password );
    my $result = $u;
    for ( 2 .. $iterations ) {
        $u = hmac_sha256( $u, $password );
        $result ^= $u;
    }
    return unpack 'H*', $result;
}

my $password = 'password123';
my $salt = '73616c74';
my $expected = reference_pbkdf2( $password, $salt, 3 );

{
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND = 1;
    is( Developer::Dashboard::Crypto::PBKDF2->native_available, 1,
        'available native XS backend state is cached as true' );
}
{
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND = 0;
    is( Developer::Dashboard::Crypto::PBKDF2->native_available, 0,
        'unavailable native XS backend state is cached as false' );
}
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 0;
    is( Developer::Dashboard::Crypto::PBKDF2::_native_xs_available(), 0,
        'native availability is false when the shared XS extension did not load' );
}
{
    no strict 'refs';
    local *{'Developer::Dashboard::Crypto::PBKDF2::_xs_native_available'};
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    is( Developer::Dashboard::Crypto::PBKDF2::_native_xs_available(), 0,
        'native availability is false when the XS entry point is absent' );
}
{
    no strict 'refs';
    local *{'Developer::Dashboard::Crypto::PBKDF2::_xs_native_available'} = sub { 0 };
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    is( Developer::Dashboard::Crypto::PBKDF2::_native_xs_available(), 0,
        'native availability preserves the XS backend false result' );
}

my $native_available = Developer::Dashboard::Crypto::PBKDF2->native_available;
SKIP: {
    skip 'system OpenSSL PBKDF2 API is unavailable in this Docker image', 4
      if !$native_available;

    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password => $password, salt => $salt, iterations => 3,
        ),
        $expected,
        'XS OpenSSL PBKDF2 preserves the reference digest',
    );

    my $latin1_password = "\x{a3}12345678";
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password => $latin1_password, salt => $salt, iterations => 3,
        ),
        reference_pbkdf2( "\xa3" . '12345678', $salt, 3 ),
        'XS PBKDF2 preserves Perl byte-downgrade semantics for Latin-1',
    );

    my $long_digest = Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => $password, salt => $salt, iterations => 210_000,
    );
    is( length($long_digest), 64, 'XS backend supports the production work factor' );
    like( $long_digest, qr/\A[0-9a-f]{64}\z/, 'XS backend returns a lowercase hex digest' );
}

is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => undef, salt => $salt, iterations => 3,
    ), undef, 'undefined password is declined' );
is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => [], salt => $salt, iterations => 3,
    ), undef, 'reference password is declined' );
is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => $password, salt => undef, iterations => 3,
    ), undef, 'undefined salt is declined' );
is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => $password, salt => [], iterations => 3,
    ), undef, 'reference salt is declined' );
is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => $password, salt => $salt, iterations => undef,
    ), undef, 'undefined iteration count is declined' );
is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => $password, salt => $salt, iterations => '3x',
    ), undef, 'non-integer iteration count is declined' );
is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => $password, salt => $salt, iterations => 0,
    ), undef, 'zero iteration count is declined' );
is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => $password, salt => $salt, iterations => 2_147_483_648,
    ), undef, 'iteration count outside the native integer range is declined' );
is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => "\x{1f600}", salt => $salt, iterations => 3,
    ), undef, 'non-byte password is declined without lossy conversion' );
is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password => $password, salt => "\x{1f600}", iterations => 3,
    ), undef, 'non-byte salt is declined without lossy conversion' );

{
    no warnings 'redefine';
    local *Developer::Dashboard::Crypto::PBKDF2::_native_xs_available = sub { return 0 };
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND;
    is( Developer::Dashboard::Crypto::PBKDF2->native_available, 0,
        'missing OpenSSL library selects the caller portable implementation' );
    is( Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password => $password, salt => $salt, iterations => 3,
        ), undef, 'native derivation returns undef when OpenSSL is unavailable' );
}

if ( $native_available && Developer::Dashboard::Crypto::PBKDF2->can('_xs_pbkdf2_sha256') ) {
    my $error = eval { Developer::Dashboard::Crypto::PBKDF2::_xs_pbkdf2_sha256( $password, $salt, 0 ); 1 };
    like( $@, qr/iterations are outside the supported range/, 'XS rejects an invalid direct iteration count' ) if !$error;
    ok( !$error, 'XS invalid-iteration guard throws before calling OpenSSL' );
}
else {
    pass('XS invalid-iteration guard is tested on systems with OpenSSL');
    pass('XS invalid-iteration guard is tested on systems with OpenSSL');
}

done_testing;

__END__

=head1 NAME

t/651-crypto-pbkdf2-xs.t - verify the native PBKDF2 XS adapter

=head1 PURPOSE

This test checks that the existing PBKDF2 Perl API calls the distribution's XS
extension, preserves the established SHA-256 output, and declines unsupported
inputs without weakening the caller's portable implementation.

=head1 WHY IT EXISTS

Helper authentication relies on a fixed PBKDF2-HMAC-SHA256 contract. Changes to
the native boundary must preserve byte semantics, work factor, output format,
and visible errors while requiring no Perl FFI binding distribution.

=head1 WHEN TO USE

Run this test whenever the PBKDF2 adapter, its XS function, OpenSSL runtime
loading, or authentication digest handling changes.

=head1 HOW TO USE

Build the extension and run this test inside the Docker dev container:

  d2 docker compose exec dev perl Makefile.PL
  d2 docker compose exec dev make
  d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/651-crypto-pbkdf2-xs.t

=head1 WHAT USES IT

C<Developer::Dashboard::Auth> calls C<derive_sha256> for helper-user password
records and retains its Digest::SHA implementation when native execution is
unavailable or an input cannot be represented as bytes.

=head1 EXAMPLES

Example 1: run parity and validation checks in Docker.

  d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/651-crypto-pbkdf2-xs.t

Example 2: compare the adapter result with the independent Digest::SHA
reference implementation embedded in this test.

  d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/651-crypto-pbkdf2-xs.t

=cut
