use strict;
use warnings;
use utf8;

use Test::More;
use Digest::SHA qw(hmac_sha256);
use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Crypto::PBKDF2;

# reference_pbkdf2($password, $salt, $iterations)
# Computes the existing PBKDF2-HMAC-SHA256 contract independently of the FFI
# adapter so tests can detect byte-level or work-factor changes.
# Input: password and salt strings plus a positive iteration count.
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

my $ascii_password = 'password123';
my $salt = '73616c74';
my $expected = reference_pbkdf2( $ascii_password, $salt, 3 );
my $ffi_available = Developer::Dashboard::Crypto::PBKDF2->native_available;
my $ffi_checklib_available = _require_test_module('FFI::CheckLib');
my $ffi_platypus_available = _require_test_module('FFI::Platypus');
my $ffi_buffer_available = _require_test_module('FFI::Platypus::Buffer');

{
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND = { cached => 1 };
    is( Developer::Dashboard::Crypto::PBKDF2->native_available, 1, 'truthy native backend availability is cached' );
}

SKIP: {
    skip 'OpenSSL PBKDF2 FFI backend is not available on this platform', 5
      if !$ffi_available;

    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $ascii_password,
            salt       => $salt,
            iterations => 3,
        ),
        $expected,
        'native FFI PBKDF2 preserves the ASCII digest and iteration count',
    );

    my $latin1_password = "\x{a3}12345678";
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $latin1_password,
            salt       => $salt,
            iterations => 3,
        ),
        reference_pbkdf2( $latin1_password, $salt, 3 ),
        'native FFI PBKDF2 preserves Perl byte-downgrade semantics for £',
    );

    my $wide_password = "\x{1f600}12345678";
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $wide_password,
            salt       => $salt,
            iterations => 3,
        ),
        undef,
        'FFI declines characters Perl Digest::SHA cannot downgrade to bytes',
    );
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $ascii_password,
            salt       => "\x{1f600}",
            iterations => 3,
        ),
        undef,
        'FFI declines salts Perl cannot downgrade to bytes',
    );

    my $long_digest = Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
        password   => $ascii_password,
        salt       => $salt,
        iterations => 210_000,
    );
    is( length($long_digest), 64, 'native FFI supports the production 210000-round key length' );
}

SKIP: {
    skip 'OpenSSL PBKDF2 FFI backend is not available on this platform', 1
      if !$ffi_available;

    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND;
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $ascii_password,
            salt       => $salt,
            iterations => 3,
        ),
        $expected,
        'native derive lazily initializes the backend when no backend was cached',
    );
}

{
    SKIP: {
    skip 'FFI::CheckLib is optional and is not installed', 3 if !$ffi_checklib_available;
    no warnings 'redefine';
    local *FFI::CheckLib::find_lib = sub { return; };
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND;
    is(
        Developer::Dashboard::Crypto::PBKDF2->native_available,
        0,
        'missing system libcrypto is reported as unavailable rather than hidden',
    );
    is(
        Developer::Dashboard::Crypto::PBKDF2->native_available,
        0,
        'cached unavailable backend remains unavailable without repeating discovery',
    );
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $ascii_password,
            salt       => $salt,
            iterations => 3,
        ),
        undef,
        'missing system libcrypto lets the caller use the documented Perl path',
    );
    }
}

for my $optional_module (qw(FFI::CheckLib FFI::Platypus FFI::Platypus::Buffer)) {
    ( my $inc_key = $optional_module ) =~ s{::}{/}g;
    $inc_key .= '.pm';
    local @INC = ();
    local $INC{$inc_key};
    delete $INC{$inc_key};
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND;

    my $available;
    my $loaded = eval {
        $available = Developer::Dashboard::Crypto::PBKDF2->native_available;
        1;
    };
    ok( $loaded, "$optional_module absence is treated as unavailable native acceleration without an exception" )
      or diag $@;
    is( $available, 0, "$optional_module absence selects the documented Perl fallback" );
}

{
    my $bad_module_root = tempdir( CLEANUP => 1 );
    my $bad_module_dir = File::Spec->catdir( $bad_module_root, 'Local' );
    make_path($bad_module_dir);
    my $bad_module_file = File::Spec->catfile( $bad_module_dir, 'BadFFI.pm' );
    open my $bad_module_fh, '>', $bad_module_file
      or die "Unable to write optional-module failure fixture '$bad_module_file': $!";
    print {$bad_module_fh} "die qq{fixture module initialization failed\\n};\\n1;\\n"
      or die "Unable to write optional-module failure fixture '$bad_module_file': $!";
    close $bad_module_fh
      or die "Unable to close optional-module failure fixture '$bad_module_file': $!";

    local @INC = ( $bad_module_root, @INC );
    local $INC{'Local/BadFFI.pm'};
    delete $INC{'Local/BadFFI.pm'};
    my $error = eval {
        Developer::Dashboard::Crypto::PBKDF2::_require_optional_ffi_module('Local::BadFFI');
        1;
    };
    ok( !$error, 'an installed optional module that fails during initialization is not treated as absent' );
    like( $@, qr/fixture module initialization failed/, 'optional module initialization error remains visible' );
}

{
    my $program = q{
        BEGIN {
            unshift @INC, sub {
                my ( $self, $file ) = @_;
                die "Can't locate $file in \@INC (hidden by test fixture)\n"
                  if $file =~ m{\AFFI/(?:CheckLib|Platypus(?:/Buffer)?)\.pm\z};
                return;
            };
        }
        require Developer::Dashboard::Crypto::PBKDF2;
        print Developer::Dashboard::Crypto::PBKDF2->native_available ? "1\n" : "0\n";
    };
    my ( $stdout, $stderr, $status ) = capture {
        system { $^X } $^X, '-Ilib', '-e', $program;
        return $?;
    };
    is( $status, 0, 'the adapter itself loads when optional FFI modules are unavailable' )
      or diag $stderr;
    is( $stdout, "0\n", 'a fresh interpreter uses the native-unavailable fallback without FFI modules' );
    is( $stderr, '', 'optional FFI module absence produces no load-time diagnostic' );
}

{
    SKIP: {
    skip 'FFI::CheckLib is optional and is not installed', 1 if !$ffi_checklib_available;
    no warnings 'redefine';
    local *FFI::CheckLib::find_lib = sub { return '' };
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND;
    is(
        Developer::Dashboard::Crypto::PBKDF2->native_available,
        0,
        'empty library discovery result is treated as no compatible OpenSSL library',
    );
    }
}

for my $invalid_case (
    [ 'undefined password', { salt => 'salt', iterations => 1 } ],
    [ 'reference password', { password => [], salt => 'salt', iterations => 1 } ],
    [ 'undefined salt', { password => 'password', iterations => 1 } ],
    [ 'reference salt', { password => 'password', salt => [], iterations => 1 } ],
    [ 'missing iterations', { password => 'password', salt => 'salt' } ],
    [ 'non-integer iterations', { password => 'password', salt => 'salt', iterations => '1.5' } ],
    [ 'zero iterations', { password => 'password', salt => 'salt', iterations => 0 } ],
    [ 'oversized iterations', { password => 'password', salt => 'salt', iterations => '2147483648' } ],
) {
    my ( $label, $arguments ) = @{$invalid_case};
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(%{$arguments}),
        undef,
        "native adapter declines $label",
    );
}

{
    package Local::PBKDF2FailedFunction;
    sub call { return 0 }
}
{
    SKIP: {
    skip 'FFI::Platypus::Buffer is optional and is not installed', 1 if !$ffi_buffer_available;
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND = {
        pbkdf2 => bless( {}, 'Local::PBKDF2FailedFunction' ),
        sha256 => 1,
    };
    my $error = eval {
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => 'password',
            salt       => 'salt',
            iterations => 1,
        );
        1;
    } ? '' : $@;
    like( $error, qr/OpenSSL PKCS5_PBKDF2_HMAC failed/, 'native OpenSSL failure is surfaced explicitly' );
    }
}

{
    SKIP: {
    skip 'FFI::Platypus::Buffer is optional and is not installed', 1 if !$ffi_buffer_available;
    no warnings 'redefine';
    local *FFI::Platypus::Buffer::scalar_to_buffer = sub { return ( 'buffer', 1 ) };
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND = {
        pbkdf2 => bless( {}, 'Local::PBKDF2FailedFunction' ),
        sha256 => 1,
    };
    my $error = eval {
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => 'password',
            salt       => 'salt',
            iterations => 1,
        );
        1;
    } ? '' : $@;
    like( $error, qr/Unable to allocate PBKDF2 output buffer/, 'undersized output buffer is rejected explicitly' );
    }
}

{
    SKIP: {
    skip 'FFI::Platypus::Buffer is optional and is not installed', 1 if !$ffi_buffer_available;
    no warnings 'redefine';
    local *FFI::Platypus::Buffer::scalar_to_buffer = sub { return ( 'buffer', 2_147_483_648 ) };
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND = {
        pbkdf2 => bless( {}, 'Local::PBKDF2FailedFunction' ),
        sha256 => 1,
    };
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => 'password',
            salt       => 'salt',
            iterations => 1,
        ),
        undef,
        'password lengths outside OpenSSL signed-int bounds are declined for the Perl path',
    );
    }
}

{
    SKIP: {
    skip 'FFI::Platypus::Buffer is optional and is not installed', 1 if !$ffi_buffer_available;
    no warnings 'redefine';
    my $buffer_calls = 0;
    local *FFI::Platypus::Buffer::scalar_to_buffer = sub {
        $buffer_calls++;
        return ( 'buffer', $buffer_calls == 1 ? 1 : 2_147_483_648 );
    };
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND = {
        pbkdf2 => bless( {}, 'Local::PBKDF2FailedFunction' ),
        sha256 => 1,
    };
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => 'password',
            salt       => 'salt',
            iterations => 1,
        ),
        undef,
        'salt lengths outside OpenSSL signed-int bounds are declined for the Perl path',
    );
    }
}

{
    SKIP: {
    skip 'optional FFI modules are not installed', 1
      if !$ffi_checklib_available || !$ffi_platypus_available || !$ffi_buffer_available;
    no warnings qw(redefine once);
    local *FFI::CheckLib::find_lib = sub { return '/mock/libcrypto.so' };
    local *FFI::Platypus::new = sub { return bless {}, 'Local::PBKDF2FakeFFI' };
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND;
    my $error = eval {
        Developer::Dashboard::Crypto::PBKDF2->native_available;
        1;
    } ? '' : $@;
    like( $error, qr/OpenSSL EVP_sha256 returned a null digest descriptor/, 'null EVP digest descriptor is surfaced explicitly' );
    }
}

{
    no warnings qw(redefine once);
    local $INC{'FFI/CheckLib.pm'} = __FILE__;
    local $INC{'FFI/Platypus.pm'} = __FILE__;
    local $INC{'FFI/Platypus/Buffer.pm'} = __FILE__;
    local *FFI::CheckLib::find_lib = sub { return $Local::PBKDF2FakeFFI::LIBRARY };
    local *FFI::Platypus::new = sub {
        my ( $class, %args ) = @_;
        $Local::PBKDF2FakeFFI::CONSTRUCTOR_ARGS = \%args;
        return bless {}, 'Local::PBKDF2FakeFFI';
    };
    local *FFI::Platypus::Buffer::scalar_to_buffer = sub {
        my $index = ++$Local::PBKDF2FakeFFI::BUFFER_CALLS;
        my $size = length( $_[0] );
        $size = 2_147_483_648 if $Local::PBKDF2FakeFFI::BUFFER_MODE eq 'large-first' && $index == 1;
        $size = 2_147_483_648 if $Local::PBKDF2FakeFFI::BUFFER_MODE eq 'large-second' && $index == 2;
        $size = 31 if $Local::PBKDF2FakeFFI::BUFFER_MODE eq 'short-output' && $index == 3;
        return ( \$_[0], $size );
    };

    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND;
    local $Local::PBKDF2FakeFFI::LIBRARY = '/mock/libcrypto.so';
    local $Local::PBKDF2FakeFFI::SHA256_RESULT = 1;
    local $Local::PBKDF2FakeFFI::PBKDF2_RESULT = 1;
    local $Local::PBKDF2FakeFFI::BUFFER_MODE = '';
    local $Local::PBKDF2FakeFFI::BUFFER_CALLS = 0;

    is( Developer::Dashboard::Crypto::PBKDF2->native_available, 1, 'mocked native FFI backend initializes without optional system modules' );
    is_deeply(
        $Local::PBKDF2FakeFFI::CONSTRUCTOR_ARGS,
        { api => 2, lib => ['/mock/libcrypto.so'] },
        'native FFI backend uses the selected library and API version',
    );
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $ascii_password,
            salt       => $salt,
            iterations => 3,
        ),
        $expected,
        'mocked native function preserves the PBKDF2 digest contract',
    );
    is( Developer::Dashboard::Crypto::PBKDF2->native_available, 1, 'successful native backend initialization is cached' );
    ok(
        Developer::Dashboard::Crypto::PBKDF2::_load_backend() == $Developer::Dashboard::Crypto::PBKDF2::BACKEND,
        'backend loader returns the cached backend without rediscovery',
    );
    {
        local $Developer::Dashboard::Crypto::PBKDF2::BACKEND = 0;
        is( Developer::Dashboard::Crypto::PBKDF2->native_available, 0, 'native availability reports a cached unavailable backend' );
        is( Developer::Dashboard::Crypto::PBKDF2::_load_backend(), 0, 'backend loader preserves its cached unavailable state' );
    }

    {
        local $Developer::Dashboard::Crypto::PBKDF2::BACKEND;
        $Local::PBKDF2FakeFFI::BUFFER_CALLS = 0;
        is(
            Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
                password   => $ascii_password,
                salt       => $salt,
                iterations => 3,
            ),
            $expected,
            'derive lazily initializes FFI when no backend was cached',
        );
    }

    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => "\x{1f600}",
            salt       => $salt,
            iterations => 1,
        ),
        undef,
        'native derivation declines a password outside Perl byte-string range',
    );
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $ascii_password,
            salt       => "\x{1f600}",
            iterations => 1,
        ),
        undef,
        'native derivation declines a salt outside Perl byte-string range',
    );

    for my $size_case (
        [ 'large-first',  'oversized password buffer' ],
        [ 'large-second', 'oversized salt buffer' ],
    ) {
        $Local::PBKDF2FakeFFI::BUFFER_MODE = $size_case->[0];
        $Local::PBKDF2FakeFFI::BUFFER_CALLS = 0;
        is(
            Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
                password   => $ascii_password,
                salt       => $salt,
                iterations => 1,
            ),
            undef,
            "native derivation declines an $size_case->[1]",
        );
    }

    $Local::PBKDF2FakeFFI::BUFFER_MODE = 'short-output';
    $Local::PBKDF2FakeFFI::BUFFER_CALLS = 0;
    my $short_output_error = eval {
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $ascii_password,
            salt       => $salt,
            iterations => 1,
        );
        1;
    } ? '' : $@;
    like( $short_output_error, qr/Unable to allocate PBKDF2 output buffer/, 'native derivation rejects an undersized output buffer' );

    $Local::PBKDF2FakeFFI::BUFFER_MODE = '';
    $Local::PBKDF2FakeFFI::BUFFER_CALLS = 0;
    $Local::PBKDF2FakeFFI::PBKDF2_RESULT = 0;
    my $pbkdf2_error = eval {
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $ascii_password,
            salt       => $salt,
            iterations => 1,
        );
        1;
    } ? '' : $@;
    like( $pbkdf2_error, qr/OpenSSL PKCS5_PBKDF2_HMAC failed/, 'native OpenSSL call failures remain explicit' );
}

for my $library_result ( undef, '' ) {
    no warnings qw(redefine once);
    local $INC{'FFI/CheckLib.pm'} = __FILE__;
    local $INC{'FFI/Platypus.pm'} = __FILE__;
    local $INC{'FFI/Platypus/Buffer.pm'} = __FILE__;
    local *FFI::CheckLib::find_lib = sub { return $Local::PBKDF2FakeFFI::LIBRARY };
    local *FFI::Platypus::new = sub { return bless {}, 'Local::PBKDF2FakeFFI' };
    local *FFI::Platypus::Buffer::scalar_to_buffer = sub { return ( \$_[0], length( $_[0] ) ) };
    local $Local::PBKDF2FakeFFI::LIBRARY = $library_result;
    local $Local::PBKDF2FakeFFI::SHA256_RESULT = 1;
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND;
    is(
        Developer::Dashboard::Crypto::PBKDF2->native_available,
        0,
        'missing or empty libcrypto discovery result selects the Perl fallback',
    );
    is(
        Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
            password   => $ascii_password,
            salt       => $salt,
            iterations => 1,
        ),
        undef,
        'derive returns to the Perl fallback when no native backend is discoverable',
    );
}

{
    no warnings qw(redefine once);
    local $INC{'FFI/CheckLib.pm'} = __FILE__;
    local $INC{'FFI/Platypus.pm'} = __FILE__;
    local $INC{'FFI/Platypus/Buffer.pm'} = __FILE__;
    local *FFI::CheckLib::find_lib = sub { return '/mock/libcrypto.so' };
    local *FFI::Platypus::new = sub { return bless {}, 'Local::PBKDF2FakeFFI' };
    local *FFI::Platypus::Buffer::scalar_to_buffer = sub { return ( \$_[0], length( $_[0] ) ) };
    local $Local::PBKDF2FakeFFI::SHA256_RESULT = 0;
    local $Developer::Dashboard::Crypto::PBKDF2::BACKEND;
    my $error = eval { Developer::Dashboard::Crypto::PBKDF2->native_available; 1 } ? '' : $@;
    like( $error, qr/OpenSSL EVP_sha256 returned a null digest descriptor/, 'a null EVP digest result remains explicit' );
}

{
    package Local::PBKDF2FakeFFI;
    our ( $LIBRARY, $CONSTRUCTOR_ARGS, $SHA256_RESULT, $PBKDF2_RESULT, $BUFFER_MODE, $BUFFER_CALLS );
    sub function {
        my ( $self, $symbol ) = @_;
        return bless { symbol => $symbol }, 'Local::PBKDF2FakeFFIFunction';
    }
}
{
    package Local::PBKDF2FakeFFIFunction;
    sub call {
        my ( $self, @args ) = @_;
        return $Local::PBKDF2FakeFFI::SHA256_RESULT if $self->{symbol} eq 'EVP_sha256';
        my ( $password, $password_size, $salt, $salt_size, $iterations, $sha256, $output_size, $output ) = @args;
        return 0 if $Local::PBKDF2FakeFFI::PBKDF2_RESULT != 1;
        my $u = Digest::SHA::hmac_sha256( ${$salt} . pack( 'N', 1 ), ${$password} );
        my $derived = $u;
        for my $round ( 2 .. $iterations ) {
            $u = Digest::SHA::hmac_sha256( $u, ${$password} );
            $derived ^= $u;
        }
        ${$output} = $derived;
        return 1;
    }
}

done_testing;

sub _require_test_module {
# _require_test_module($module)
# Loads an optional module used by native-backend fixtures and distinguishes
# that module's absence from an initialization error inside an installed module.
# Input: fully qualified module name.
# Output: true when loaded, false when its own module file is absent.
    my ($module) = @_;
    ( my $file = $module ) =~ s{::}{/}g;
    $file .= '.pm';
    my $loaded = eval { require $file; 1 };
    return 1 if $loaded;

    my $error = $@;
    return 0 if $error =~ /\ACan't locate \Q$file\E in \@INC\b/;
    die $error;
}

__END__

=head1 NAME

t/651-crypto-pbkdf2-ffi.t - Verify native PBKDF2 interoperability

=head1 PURPOSE

This test verifies the optional OpenSSL FFI implementation of
PBKDF2-HMAC-SHA256 against the byte-for-byte behavior currently used by helper
account authentication.

=head1 WHY IT EXISTS

The FFI path collapses hundreds of thousands of Perl-to-XS HMAC calls into one
native call. A digest mismatch would invalidate existing helper credentials,
so the exact digest, iteration count, and Perl byte-string behavior are
security-sensitive compatibility requirements. The suite also supplies a
deterministic fake FFI boundary so backend setup, buffer validation, digest
parity, and explicit native errors are exercised even when optional FFI modules
or system libcrypto are absent from the test environment.

=head1 WHEN TO USE

Run this test when changing the FFI adapter, password derivation, library
discovery, or the supported native fallback behavior.

=head1 HOW TO USE

Run C<prove -lv t/651-crypto-pbkdf2-ffi.t> from a configured Developer
Dashboard checkout. Native integration checks skip when an optional FFI module
or compatible OpenSSL library is unavailable; deterministic mocked-native
checks still exercise successful setup, digest parity, buffer bounds, and
native failure handling. The test also hides each optional FFI module in turn
to verify that module absence selects the Perl fallback without masking
unrelated load failures.
It launches a fresh Perl interpreter with the optional FFI library path hidden
to verify that loading this adapter itself does not require those optional
modules, and checks that failures raised by installed modules remain visible.

=head1 WHAT USES IT

The distribution test suite uses this file to guard the implementation called
by C<Developer::Dashboard::Auth> for helper-user password creation and
verification.

=head1 EXAMPLES

Example 1:

  prove -lv t/651-crypto-pbkdf2-ffi.t

Run the isolated digest-parity, byte-semantics, and missing-library/module
fallback checks.

Example 2:

  d2 docker compose --project-name dd-problem48-test run --rm dev prove -lv t/651-crypto-pbkdf2-ffi.t

Run the same test in an isolated Docker test project.

Example 3:

  PERL5OPT='-MDevel::Cover=-db,cover_db' prove -l t/651-crypto-pbkdf2-ffi.t

Measure the adapter branches while the fake FFI boundary keeps native-path
coverage independent of installed optional modules.

=cut
