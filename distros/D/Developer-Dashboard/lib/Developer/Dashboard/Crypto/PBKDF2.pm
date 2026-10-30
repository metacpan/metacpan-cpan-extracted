package Developer::Dashboard::Crypto::PBKDF2;

use strict;
use warnings;
our $VERSION = '6.06';

our $BACKEND;

# native_available()
# Checks whether a compatible OpenSSL PBKDF2 symbol can be bound through
# FFI::Platypus, loading the native modules only on demand.
# Input: none.
# Output: boolean true when FFI and libcrypto are available, false when the
# optional FFI modules or a compatible libcrypto are not present.
sub native_available {
    my ($class) = @_;
    return $BACKEND ? 1 : 0 if defined $BACKEND;
    return _load_backend() ? 1 : 0;
}

# derive_sha256(%args)
# Derives one 32-byte PBKDF2-HMAC-SHA256 block through the native OpenSSL API
# when the password and salt have byte semantics compatible with the existing
# Digest::SHA implementation.
# Input: password, salt, and positive integer iterations.
# Output: lowercase 64-character digest, or undef when native execution is not
# compatible/available and the caller should use its Perl implementation.
sub derive_sha256 {
    my ( $class, %args ) = @_;
    my $password = $args{password};
    my $salt = $args{salt};
    my $iterations = $args{iterations};

    return if !defined $password || ref($password);
    return if !defined $salt || ref($salt);
    return if !defined $iterations || $iterations !~ /\A\d+\z/ || $iterations < 1;
    return if $iterations > 2_147_483_647;

    my $password_bytes = "$password";
    my $salt_bytes = "$salt";
    return if !utf8::downgrade( $password_bytes, 1 );
    return if !utf8::downgrade( $salt_bytes, 1 );

    my $backend = $BACKEND || _load_backend();
    return if !$backend;

    my ( $password_pointer, $password_size ) = FFI::Platypus::Buffer::scalar_to_buffer($password_bytes);
    my ( $salt_pointer, $salt_size ) = FFI::Platypus::Buffer::scalar_to_buffer($salt_bytes);
    return if $password_size > 2_147_483_647 || $salt_size > 2_147_483_647;
    my $output = "\0" x 32;
    my ( $output_pointer, $output_size ) = FFI::Platypus::Buffer::scalar_to_buffer($output);
    die 'Unable to allocate PBKDF2 output buffer' if $output_size < 32;

    my $ok = $backend->{pbkdf2}->call(
        $password_pointer,
        $password_size,
        $salt_pointer,
        $salt_size,
        $iterations,
        $backend->{sha256},
        32,
        $output_pointer,
    );
    die 'OpenSSL PKCS5_PBKDF2_HMAC failed' if !$ok;

    return unpack 'H*', $output;
}

# _load_backend()
# Finds libcrypto and builds the typed FFI bindings once per interpreter.
# Input: none.
# Output: backend hash reference, or undef if no compatible libcrypto exists.
sub _load_backend {
    return $BACKEND if defined $BACKEND;

    for my $module ( qw(FFI::CheckLib FFI::Platypus FFI::Platypus::Buffer) ) {
        if ( !_require_optional_ffi_module($module) ) {
            $BACKEND = 0;
            return;
        }
    }

    my ($library) = FFI::CheckLib::find_lib(
        lib    => 'crypto',
        symbol => 'PKCS5_PBKDF2_HMAC',
    );
    if ( !defined $library || $library eq '' ) {
        $BACKEND = 0;
        return;
    }

    my $ffi = FFI::Platypus->new(
        api => 2,
        lib => [$library],
    );
    my $sha256 = $ffi->function( EVP_sha256 => [] => 'opaque' )->call;
    die 'OpenSSL EVP_sha256 returned a null digest descriptor' if !$sha256;
    my $pbkdf2 = $ffi->function(
        PKCS5_PBKDF2_HMAC => [ qw(opaque sint32 opaque sint32 sint32 opaque sint32 opaque) ] => 'sint32',
    );
    $BACKEND = {
        ffi    => $ffi,
        library => $library,
        pbkdf2 => $pbkdf2,
        sha256 => $sha256,
    };
    return $BACKEND;
}

# _require_optional_ffi_module($module)
# Loads one FFI integration module while distinguishing its absence from a
# failure inside an installed module or one of its dependencies.
# Input: fully qualified FFI module name.
# Output: true when loaded, false only when the requested module file itself is
# absent; unrelated load failures remain visible as exceptions.
sub _require_optional_ffi_module {
    my ($module) = @_;
    my $file = $module;
    $file =~ s{::}{/}g;
    $file .= '.pm';
    my $loaded = eval { require $file; 1 };
    return 1 if $loaded;

    my $error = $@;
    return 0 if $error =~ /\ACan't locate \Q$file\E in \@INC\b/;
    die $error;
}

1;

__END__

=head1 NAME

Developer::Dashboard::Crypto::PBKDF2 - native PBKDF2 adapter

=head1 PURPOSE

This module binds OpenSSL's one-shot PBKDF2-HMAC-SHA256 implementation through
FFI::Platypus. It is a narrow adapter for the dashboard helper-authentication
hot path; it does not translate or accelerate arbitrary Perl subroutines.

=head1 WHY IT EXISTS

The prior derivation called the XS HMAC function once per PBKDF2 round from a
Perl loop. A single native PBKDF2 call avoids that repeated Perl/native
boundary while retaining the existing digest, output size, and iteration
count. The portable Perl implementation remains the documented path when no
compatible system C<libcrypto> or optional FFI module is available, or when
input byte semantics cannot safely cross the FFI boundary. Only absence of
the requested optional FFI module selects the fallback; other module-load
errors remain visible.

=head1 WHEN TO USE

Use this module only for SHA-256 PBKDF2 derivation with scalar password/salt
values representable as Perl byte strings and a positive integer work factor.
Do not use it to reduce the iteration count or to parallelize one PBKDF2
chain; the chain is intentionally sequential.

=head1 HOW TO USE

Call C<native_available> to inspect whether the optional FFI modules and a
compatible OpenSSL library are available. Call C<derive_sha256> with named C<password>, C<salt>, and
C<iterations> arguments. An undefined result means the caller should execute
its explicit Perl implementation. Library-binding and native-call failures
die with a visible error rather than being hidden as fallback.

=head1 WHAT USES IT

C<Developer::Dashboard::Auth> calls this adapter when creating and verifying
PBKDF2 helper-user records. The Auth module retains the existing Digest::SHA
implementation for unsupported input and systems without libcrypto.

=head1 EXAMPLES

Example 1:

  my $digest = Developer::Dashboard::Crypto::PBKDF2->derive_sha256(
    password => $password,
    salt => $salt,
    iterations => 210_000,
  );

Derive the same stored PBKDF2-SHA256 key through OpenSSL when the adapter can
preserve the input byte semantics.

Example 2:

  if (Developer::Dashboard::Crypto::PBKDF2->native_available) {
      print "OpenSSL PBKDF2 acceleration is available\n";
  }

Check whether the current machine has a compatible native crypto library.

Example 3:

  prove -lv t/651-crypto-pbkdf2-ffi.t

Run digest-parity, unsupported-Unicode, missing-library, and missing-optional-module tests.

=cut
