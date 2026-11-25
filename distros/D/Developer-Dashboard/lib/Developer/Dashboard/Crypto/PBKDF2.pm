package Developer::Dashboard::Crypto::PBKDF2;

use strict;
use warnings;
our $VERSION = '6.31';

our $BACKEND;

# native_available()
# Checks whether the shared XS extension and a compatible OpenSSL PBKDF2
# implementation are available.
# Input: none.
# Output: boolean true when XS and libcrypto are available, false otherwise.
sub native_available {
    my ($class) = @_;
    return $BACKEND ? 1 : 0 if defined $BACKEND;
    $BACKEND = _native_xs_available() ? 1 : 0;
    return $BACKEND;
}

# derive_sha256(%args)
# Derives one 32-byte PBKDF2-HMAC-SHA256 block through the native OpenSSL API
# when the password and salt have byte semantics compatible with the existing
# Digest::SHA implementation.
# Input: password, salt, and positive integer iterations.
# Output: lowercase 64-character digest, or undef when native execution is
# unavailable or the input cannot safely cross the XS byte boundary.
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

    return if !native_available();
    return _xs_pbkdf2_sha256( $password_bytes, $salt_bytes, $iterations );
}

# _native_xs_available()
# Loads the shared extension lazily and asks its XS backend to load OpenSSL.
# Input: none.
# Output: true only when the extension and OpenSSL entry points are available.
sub _native_xs_available {
    require Developer::Dashboard::HtmlEscape;
    return 0 if !$Developer::Dashboard::HtmlEscape::XS_LOADED;
    return 0 if !__PACKAGE__->can('_xs_native_available');
    return _xs_native_available() ? 1 : 0;
}

1;

__END__

=head1 NAME

Developer::Dashboard::Crypto::PBKDF2 - native PBKDF2 adapter

=head1 PURPOSE

This module calls OpenSSL's one-shot PBKDF2-HMAC-SHA256 implementation through
the distribution's shared XS extension. It is a narrow adapter for dashboard
helper authentication; it does not translate or accelerate arbitrary Perl
subroutines.

=head1 WHY IT EXISTS

The prior derivation called the XS HMAC function once per PBKDF2 round from a
Perl loop. A single native PBKDF2 call avoids that repeated Perl/native
boundary while retaining the existing digest, output size, and iteration
count. The portable Perl implementation remains the path when no compatible
system C<libcrypto> is available, the XS extension is not built, or input byte
semantics cannot safely cross the native boundary. Failures in an available
native PBKDF2 call remain visible.

=head1 WHEN TO USE

Use this module only for SHA-256 PBKDF2 derivation with scalar password/salt
values representable as Perl byte strings and a positive integer work factor.
Do not use it to reduce the iteration count or to parallelize one PBKDF2
chain; the chain is intentionally sequential.

=head1 HOW TO USE

Call C<native_available> to inspect whether the XS adapter and a compatible
OpenSSL library are available. Call C<derive_sha256> with named C<password>, C<salt>, and
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

  d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/651-crypto-pbkdf2-xs.t

Run digest-parity, unsupported-Unicode, invalid-input, and missing-library tests.

=cut
