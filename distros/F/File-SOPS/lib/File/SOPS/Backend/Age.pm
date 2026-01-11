package File::SOPS::Backend::Age;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: age encryption backend for SOPS

use Moo;
use Carp qw(croak);
use Crypt::Age;
use MIME::Base64 qw(encode_base64 decode_base64);
use namespace::clean;


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

        return $data_key if defined $data_key;
    }

    croak "Could not decrypt data key with any of the provided identities";
}


sub can_decrypt {
    my ($class, %args) = @_;
    my $age_keys   = $args{age_keys}   // return 0;
    my $identities = $args{identities} // return 0;

    return 0 unless ref($age_keys) eq 'ARRAY' && @$age_keys;
    return 0 unless ref($identities) eq 'ARRAY' && @$identities;

    my $data_key = eval {
        $class->decrypt_data_key(
            age_keys   => $age_keys,
            identities => $identities,
        );
    };

    return defined $data_key ? 1 : 0;
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

version 0.001

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

This is a non-throwing version of L</decrypt_data_key>.

=head1 SEE ALSO

=over 4

=item * L<File::SOPS> - Main SOPS interface

=item * L<Crypt::Age> - Perl age encryption implementation

=item * L<https://age-encryption.org/> - age specification

=back

=head1 SUPPORT

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
