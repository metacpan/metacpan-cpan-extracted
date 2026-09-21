package File::SOPS::Backend::Age;
# ABSTRACT: age encryption backend for SOPS
our $VERSION = '0.004';
use Moo;
use Carp qw(croak);
use Crypt::Age;
use MIME::Base64 qw(encode_base64 decode_base64);
use namespace::clean;

# Same reason as in the two format handlers (k71): every frame between a
# caller and this backend is File::SOPS's own, so "could not decrypt the data
# key" named a line in SOPS.pm rather than the line the caller wrote decrypt()
# on. The house rule is that an error reports the caller's line, not ours.
our @CARP_NOT = qw( File::SOPS );


sub encrypt_data_key {
    my ($class, %args) = @_;
    my $data_key   = $args{data_key}   // croak "data_key required";
    my $recipients = $args{recipients} // croak "recipients required";

    croak "recipients must be an array ref" unless ref($recipients) eq 'ARRAY';
    croak "at least one recipient required" unless @$recipients;

    my @encrypted_keys;

    for my $recipient (@$recipients) {
        my $encrypted = Crypt::Age->encrypt(
            plaintext  => $data_key,
            recipients => [$recipient],
        );

        # Armor the output for SOPS compatibility
        my $armored = _armor($encrypted);

        push @encrypted_keys, {
            recipient => $recipient,
            enc       => $armored,
        };
    }

    return \@encrypted_keys;
}


sub decrypt_data_key {
    my ($class, %args) = @_;
    my $age_keys   = $args{age_keys}   // croak "age_keys required";
    my $identities = $args{identities} // croak "identities required";

    croak "age_keys must be an array ref" unless ref($age_keys) eq 'ARRAY';
    croak "identities must be an array ref" unless ref($identities) eq 'ARRAY';

    # k192 / CVE-2026-85783 -- Crypt::Age's per-blob stanza DoS (capped upstream
    # in 0.004) is amplified on this path: the loop below tries every age entry
    # in the document, and each try costs an X25519 scalar multiplication per
    # stanza before the header is authenticated, so a document carrying many age
    # entries multiplies the cost by entries x stanzas x identities. Nothing
    # before us bounds the entry count, so bound it here, ahead of any age work.
    # 64 is a deliberately conservative default -- real documents carry a handful
    # of recipients; a caller that legitimately has more may raise it.
    my $max_stanzas = $args{max_stanzas} // 64;
    _check_max_stanzas($args{max_stanzas});
    croak sprintf(
        "SOPS document has %d age stanzas, exceeding the max_stanzas limit of %d; refusing to decrypt",
        scalar(@$age_keys),
        $max_stanzas,
    ) if @$age_keys > $max_stanzas;

    # The data key the SOPS data path consumes is exactly 32 bytes -- the
    # AES-256 key every value in the document is encrypted under. A short
    # return is silently accepted by CryptX as a working AES-128/192 key
    # (k52, the same defect class as the data-key / IV checks in
    # Encrypted::_random_bytes); a long return is not a valid AES key and
    # dies inside CryptX, attributed to gcm and naming neither the CSPRNG
    # nor the age layer. Crypt::Age 0.001 happens to return 32 bytes; we
    # cannot rely on that, and we cannot see the inner values (file key,
    # nonce, ephemeral key) that produced the result.
    my $EXPECTED_DATA_KEY_LEN = 32;

    for my $key_info (@$age_keys) {
        my $encrypted = $key_info->{enc};
        next unless defined $encrypted;

        # Dearmor if needed
        my $ciphertext = _dearmor($encrypted);

        my $data_key = eval {
            Crypt::Age->decrypt(
                ciphertext => $ciphertext,
                identities => $identities,
            );
        };

        next unless defined $data_key;

        croak sprintf(
            "Crypt::Age returned a data key of %d bytes, expected %d",
            length($data_key),
            $EXPECTED_DATA_KEY_LEN,
        ) if length($data_key) != $EXPECTED_DATA_KEY_LEN;

        return $data_key;
    }

    croak "Could not decrypt data key with any of the provided identities";
}


sub can_decrypt {
    my ($class, %args) = @_;
    my $age_keys   = $args{age_keys}   // return 0;
    my $identities = $args{identities} // return 0;

    return 0 unless ref($age_keys) eq 'ARRAY' && @$age_keys;
    return 0 unless ref($identities) eq 'ARRAY' && @$identities;

    # A bad max_stanzas is a caller error, not a "can't decrypt" answer: validate
    # it here, ahead of the eval below, so it croaks clearly instead of being
    # swallowed into a false result (k200).
    _check_max_stanzas($args{max_stanzas});

    my $data_key = eval {
        $class->decrypt_data_key(
            age_keys    => $age_keys,
            identities  => $identities,
            max_stanzas => $args{max_stanzas},
        );
    };

    return defined $data_key ? 1 : 0;
}


# k200 -- validate max_stanzas the way Crypt::Age does (a positive integer),
# ahead of the count guard. Absent/undef means the default and is not an error
# here (unlike Crypt::Age); a defined non-positive-integer is. Without this,
# max_stanzas => 0/negative refuses every non-empty document with a confusing
# "exceeding the limit" message, and a non-numeric value numifies to 0 with a
# Perl warning. The message names neither recipients nor blobs.
sub _check_max_stanzas {
    my ($max_stanzas) = @_;
    return unless defined $max_stanzas;
    croak "max_stanzas must be a positive integer"
        unless $max_stanzas =~ m{\A[0-9]+\z} && $max_stanzas > 0;
    return;
}

sub _armor {
    my ($data) = @_;

    my $encoded = encode_base64($data, '');
    # Split into 64-character lines
    $encoded =~ s/(.{64})/$1\n/g;
    $encoded =~ s/\n$//;

    return "-----BEGIN AGE ENCRYPTED FILE-----\n"
         . $encoded . "\n"
         . "-----END AGE ENCRYPTED FILE-----\n";
}

sub _dearmor {
    my ($armored) = @_;

    # If it's already raw (starts with age-encryption.org), return as-is
    return $armored if $armored =~ /^age-encryption\.org/;

    # Strip PEM headers and decode
    if ($armored =~ /-----BEGIN AGE ENCRYPTED FILE-----(.*?)-----END AGE ENCRYPTED FILE-----/s) {
        my $encoded = $1;
        $encoded =~ s/\s//g;
        return decode_base64($encoded);
    }

    # Assume it's raw if we can't parse it
    return $armored;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS::Backend::Age - age encryption backend for SOPS

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use File::SOPS::Backend::Age;

    # Encrypt data key for recipients
    my $encrypted_keys = File::SOPS::Backend::Age->encrypt_data_key(
        data_key   => $random_32_bytes,
        recipients => ['age1ql3z7hjy...', 'age1xyz...'],
    );

    # Decrypt data key
    my $data_key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys   => $encrypted_keys,
        identities => ['AGE-SECRET-KEY-1...'],
    );

    # Check if can decrypt
    if (File::SOPS::Backend::Age->can_decrypt(
        age_keys   => $encrypted_keys,
        identities => \@identities,
    )) {
        # One of the identities can decrypt
    }

=head1 DESCRIPTION

This module provides the age encryption backend for File::SOPS. It handles
encrypting and decrypting the SOPS data key (32 random bytes) using age
public/secret keys.

age (Actually Good Encryption) uses X25519 for key agreement and
ChaCha20-Poly1305 for encryption.

The data key is encrypted separately for each recipient, allowing multiple
people/systems to decrypt the same SOPS file.

=head2 encrypt_data_key

    my $encrypted_keys = File::SOPS::Backend::Age->encrypt_data_key(
        data_key   => $random_32_bytes,
        recipients => \@age_public_keys,
    );

Class method to encrypt a data key for multiple age recipients.

The C<data_key> should be 32 random bytes (the AES-256 key used for value encryption).

The C<recipients> parameter must be an ArrayRef of age public keys (e.g.,
C<age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p>).

Returns an ArrayRef of HashRefs, each containing:

    {
        recipient => 'age1...',
        enc       => '-----BEGIN AGE ENCRYPTED FILE-----...'
    }

The encrypted data is PEM-armored for compatibility with the reference SOPS implementation.

=head2 decrypt_data_key

    my $data_key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys   => $encrypted_keys,  # from metadata
        identities => \@age_secret_keys,
    );

Class method to decrypt a data key using age identities.

The C<age_keys> parameter should be an ArrayRef of encrypted key entries from
the SOPS metadata (as returned by L</encrypt_data_key>).

The C<identities> parameter must be an ArrayRef of age secret keys (e.g.,
C<AGE-SECRET-KEY-1QYQSZQGPQYQSZQGPQYQSZQGPQYQSZQGPQYQSZQGPQYQSZ...>).

The optional C<max_stanzas> parameter bounds the number of age stanzas (entries
in the document's C<sops.age> list) that will be attempted, and defaults to
B<64> -- a deliberately conservative limit. A document presenting more age
stanzas than this is refused with a C<croak> before any of them is decrypted,
because each attempt costs work before the age header is authenticated
(CVE-2026-85783). Raise it explicitly for a document that legitimately carries
more recipients. A C<max_stanzas> that is defined but not a positive integer is
a caller error and C<croak>s before any document is inspected.

Tries each encrypted key until one can be decrypted with the provided identities.

Returns the decrypted data key (32 bytes) on success.

Dies if none of the identities can decrypt any of the encrypted keys.

=head2 can_decrypt

    if (File::SOPS::Backend::Age->can_decrypt(
        age_keys   => $encrypted_keys,
        identities => \@identities,
    )) {
        # Can decrypt
    }

Class method to check if any of the provided identities can decrypt the data key.

Returns true if decryption is possible, false otherwise.

The optional C<max_stanzas> parameter is forwarded to L</decrypt_data_key> and
carries the same meaning and default (B<64>): an over-limit document answers
false rather than throwing. As with L</decrypt_data_key>, a C<max_stanzas> that
is defined but not a positive integer is a caller error and C<croak>s.

This is a non-throwing version of L</decrypt_data_key> for the decryption
outcome; a malformed C<max_stanzas> argument still C<croak>s.

=head1 SEE ALSO

=over 4

=item * L<File::SOPS> - Main SOPS interface

=item * L<Crypt::Age> - Perl age encryption implementation

=item * L<https://age-encryption.org/> - age specification

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-file-sops/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
