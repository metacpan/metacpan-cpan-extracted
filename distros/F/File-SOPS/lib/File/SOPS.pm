package File::SOPS;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Perl implementation of Mozilla SOPS encrypted file format

use Moo;
use Carp qw(croak);
use Digest::SHA qw(sha512);
use File::SOPS::Encrypted;
use File::SOPS::Metadata;
use File::SOPS::Backend::Age;
use File::SOPS::Format::YAML;
use File::SOPS::Format::JSON;
use namespace::clean;

our $VERSION = '0.001';


my %FORMATS = (
    yaml => 'File::SOPS::Format::YAML',
    yml  => 'File::SOPS::Format::YAML',
    json => 'File::SOPS::Format::JSON',
);

sub encrypt {
    my ($class, %args) = @_;
    my $data       = $args{data}       // croak "data required";
    my $recipients = $args{recipients} // croak "recipients required";
    my $format     = $args{format}     // 'yaml';

    croak "data must be a hash ref" unless ref($data) eq 'HASH';
    croak "recipients must be an array ref" unless ref($recipients) eq 'ARRAY';

    # Generate random 256-bit data key
    my $data_key = _random_bytes(32);

    # Create metadata
    my $metadata = File::SOPS::Metadata->new;
    $metadata->update_lastmodified;

    # Encrypt data key for each recipient
    my $encrypted_keys = File::SOPS::Backend::Age->encrypt_data_key(
        data_key   => $data_key,
        recipients => $recipients,
    );
    $metadata->age($encrypted_keys);

    # Compute MAC over plaintext values BEFORE encryption (SOPS behavior)
    my $mac = _compute_mac($data, $data_key, $metadata->lastmodified);
    $metadata->mac($mac);

    # Encrypt all values in the data structure
    my $encrypted_data = _encrypt_tree($data, $data_key, $metadata, []);

    # Serialize
    my $format_class = $FORMATS{$format} // croak "Unknown format: $format";
    return $format_class->serialize(
        data     => $encrypted_data,
        metadata => $metadata,
    );
}


sub decrypt {
    my ($class, %args) = @_;
    my $encrypted  = $args{encrypted}  // croak "encrypted required";
    my $identities = $args{identities} // croak "identities required";
    my $format     = $args{format};

    croak "identities must be an array ref" unless ref($identities) eq 'ARRAY';

    # Auto-detect format if not specified
    $format //= _detect_format($encrypted);

    my $format_class = $FORMATS{$format} // croak "Unknown format: $format";

    # Parse the encrypted content
    my ($data, $metadata) = $format_class->parse($encrypted);
    croak "No SOPS metadata found" unless $metadata;

    # Decrypt data key using age backend
    my $data_key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys   => $metadata->age,
        identities => $identities,
    );

    # Decrypt all values first
    my $decrypted_data = _decrypt_tree($data, $data_key, $metadata, []);

    # Verify MAC (AAD is lastmodified timestamp in RFC3339 format)
    # MAC is computed over decrypted (plaintext) values IN DOCUMENT ORDER
    # Perl hashes are randomized, so we must extract values from original string
    my $expected_mac = $metadata->mac;
    my $lastmodified = $metadata->lastmodified;
    if (defined $expected_mac) {
        my $expected_enc = File::SOPS::Encrypted->parse($expected_mac);
        if ($expected_enc) {
            my $expected_hash = $expected_enc->decrypt_value(key => $data_key, aad => $lastmodified);

            # Extract and decrypt values in document order from original string
            my $computed_hash = _compute_mac_from_encrypted_string($encrypted, $data_key, $data);

            croak "MAC verification failed" unless $expected_hash eq $computed_hash;
        }
    }

    return $decrypted_data;
}


sub encrypt_file {
    my ($class, %args) = @_;
    my $input      = $args{input}      // croak "input required";
    my $output     = $args{output}     // $args{input};
    my $recipients = $args{recipients} // croak "recipients required";
    my $format     = $args{format};

    # Auto-detect format from filename
    $format //= _detect_format_from_filename($input);

    # Read input file
    open my $fh, '<:raw', $input
        or croak "Cannot open input file '$input': $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    # Parse to get data structure
    my $format_class = $FORMATS{$format} // croak "Unknown format: $format";
    my ($data, undef) = $format_class->parse($content);

    # Encrypt
    my $encrypted = $class->encrypt(
        data       => $data,
        recipients => $recipients,
        format     => $format,
    );

    # Write output
    open my $out_fh, '>:raw', $output
        or croak "Cannot open output file '$output': $!";
    print $out_fh $encrypted;
    close $out_fh;

    return 1;
}


sub decrypt_file {
    my ($class, %args) = @_;
    my $input      = $args{input}      // croak "input required";
    my $output     = $args{output}     // croak "output required";
    my $identities = $args{identities} // croak "identities required";
    my $format     = $args{format};

    $format //= _detect_format_from_filename($input);

    # Read encrypted file
    open my $fh, '<:raw', $input
        or croak "Cannot open input file '$input': $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    # Decrypt
    my $data = $class->decrypt(
        encrypted  => $content,
        identities => $identities,
        format     => $format,
    );

    # Serialize decrypted data
    my $format_class = $FORMATS{$format} // croak "Unknown format: $format";

    my $decrypted;
    if ($format eq 'json') {
        require JSON::MaybeXS;
        $decrypted = JSON::MaybeXS->new(utf8 => 1, pretty => 1, canonical => 1)
            ->encode($data);
    } else {
        require YAML::XS;
        $decrypted = YAML::XS::Dump($data);
    }

    # Write output
    open my $out_fh, '>:raw', $output
        or croak "Cannot open output file '$output': $!";
    print $out_fh $decrypted;
    close $out_fh;

    return 1;
}


sub extract {
    my ($class, %args) = @_;
    my $file       = $args{file}       // croak "file required";
    my $path       = $args{path}       // croak "path required";
    my $identities = $args{identities} // croak "identities required";
    my $format     = $args{format};

    $format //= _detect_format_from_filename($file);

    # Read and decrypt
    open my $fh, '<:raw', $file
        or croak "Cannot open file '$file': $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    my $data = $class->decrypt(
        encrypted  => $content,
        identities => $identities,
        format     => $format,
    );

    # Navigate to path
    return _extract_path($data, $path);
}


sub rotate {
    my ($class, %args) = @_;
    my $file       = $args{file}       // croak "file required";
    my $identities = $args{identities} // croak "identities required";
    my $recipients = $args{recipients};
    my $format     = $args{format};

    $format //= _detect_format_from_filename($file);

    # Read encrypted file
    open my $fh, '<:raw', $file
        or croak "Cannot open file '$file': $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    my $format_class = $FORMATS{$format} // croak "Unknown format: $format";
    my (undef, $metadata) = $format_class->parse($content);

    # Get current recipients if not specified
    unless ($recipients) {
        $recipients = [ map { $_->{recipient} } @{$metadata->age} ];
    }

    # Decrypt
    my $data = $class->decrypt(
        encrypted  => $content,
        identities => $identities,
        format     => $format,
    );

    # Re-encrypt with new data key
    my $encrypted = $class->encrypt(
        data       => $data,
        recipients => $recipients,
        format     => $format,
    );

    # Write back
    open my $out_fh, '>:raw', $file
        or croak "Cannot write file '$file': $!";
    print $out_fh $encrypted;
    close $out_fh;

    return 1;
}


# Internal helpers

sub _encrypt_tree {
    my ($node, $key, $metadata, $path) = @_;

    if (ref $node eq 'HASH') {
        my %result;
        for my $k (keys %$node) {
            my $new_path = [@$path, $k];
            if ($metadata->should_encrypt_key($k)) {
                $result{$k} = _encrypt_tree($node->{$k}, $key, $metadata, $new_path);
            } else {
                $result{$k} = $node->{$k};
            }
        }
        return \%result;
    }
    elsif (ref $node eq 'ARRAY') {
        my @result;
        for my $item (@$node) {
            # SOPS does NOT add array index to path - all array elements share parent's path
            push @result, _encrypt_tree($item, $key, $metadata, $path);
        }
        return \@result;
    }
    else {
        # Leaf value - encrypt it
        # SOPS doesn't encrypt empty values, returns empty string
        return '' if !defined $node || $node eq '';

        my $aad = _path_to_aad($path);
        my $enc = File::SOPS::Encrypted->encrypt_value(
            value => $node,
            key   => $key,
            aad   => $aad,
        );
        return $enc->to_string;
    }
}

sub _decrypt_tree {
    my ($node, $key, $metadata, $path) = @_;

    if (ref $node eq 'HASH') {
        my %result;
        for my $k (keys %$node) {
            my $new_path = [@$path, $k];
            $result{$k} = _decrypt_tree($node->{$k}, $key, $metadata, $new_path);
        }
        return \%result;
    }
    elsif (ref $node eq 'ARRAY') {
        my @result;
        for my $item (@$node) {
            # SOPS does NOT add array index to path - all array elements share parent's path
            push @result, _decrypt_tree($item, $key, $metadata, $path);
        }
        return \@result;
    }
    elsif (File::SOPS::Encrypted->is_encrypted($node)) {
        my $enc = File::SOPS::Encrypted->parse($node);
        my $aad = _path_to_aad($path);
        return $enc->decrypt_value(key => $key, aad => $aad);
    }
    else {
        return $node;
    }
}

sub _path_to_aad {
    my ($path) = @_;
    return '' unless $path && @$path;
    # SOPS format: path components joined with ":" plus trailing ":"
    return join(':', @$path) . ':';
}

sub _compute_mac {
    my ($data, $key, $lastmodified) = @_;

    # SOPS computes SHA-512 hash over all values (not paths)
    my $ctx = Digest::SHA->new(512);
    _hash_values_for_mac($data, $ctx);

    # Get uppercase hex digest (SOPS format)
    my $mac_value = uc($ctx->hexdigest);

    # AAD is the lastmodified timestamp in RFC3339 format
    my $aad = $lastmodified // '';

    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => $mac_value,
        key   => $key,
        aad   => $aad,
        type  => 'str',
    );

    return $enc->to_string;
}

sub _compute_mac_from_encrypted_string {
    my ($encrypted_string, $data_key, $parsed_data) = @_;

    # Build a mapping of ENC-String -> Path from the parsed tree
    # This lets us find the correct AAD for each encrypted value
    my %enc_to_path;
    _build_enc_path_mapping($parsed_data, [], \%enc_to_path);

    # Extract all ENC[...] values from the original string in DOCUMENT ORDER
    # Perl hashes are randomized, so we must use the original string order!
    my @ordered_enc;
    while ($encrypted_string =~ /(ENC\[AES256_GCM,data:[^,]+,iv:[^,]+,tag:[^,]+,type:[^\]]+\])/g) {
        my $enc_str = $1;
        # Skip the MAC value (appears after "mac": or mac: )
        my $pos = pos($encrypted_string) - length($enc_str);
        my $before = substr($encrypted_string, 0, $pos);
        next if $before =~ /["']?mac["']?\s*:\s*["']?\s*$/;
        push @ordered_enc, $enc_str;
    }

    # Hash values in document order
    my $ctx = Digest::SHA->new(512);
    for my $enc_str (@ordered_enc) {
        my $path = $enc_to_path{$enc_str};
        next unless $path;  # Skip if not found (shouldn't happen)

        my $aad = join(':', @$path) . ':';
        my $enc = File::SOPS::Encrypted->parse($enc_str);
        next unless $enc;

        my $plaintext = eval { $enc->decrypt_value(key => $data_key, aad => $aad) };
        next unless defined $plaintext;

        # Convert to bytes same as SOPS ToBytes()
        my $bytes = _value_to_bytes_for_type($plaintext, $enc->type);
        $ctx->add($bytes);
    }

    return uc($ctx->hexdigest);
}

sub _build_enc_path_mapping {
    my ($node, $path, $mapping) = @_;

    if (ref $node eq 'HASH') {
        for my $k (keys %$node) {
            _build_enc_path_mapping($node->{$k}, [@$path, $k], $mapping);
        }
    }
    elsif (ref $node eq 'ARRAY') {
        for my $item (@$node) {
            # SOPS arrays don't add index to path
            _build_enc_path_mapping($item, $path, $mapping);
        }
    }
    elsif (File::SOPS::Encrypted->is_encrypted($node)) {
        $mapping->{$node} = [@$path];
    }
}

sub _value_to_bytes_for_type {
    my ($value, $type) = @_;
    return '' unless defined $value;

    my $str;
    if ($type eq 'bool') {
        # Already deserialized to 1/0 by decrypt_value
        $str = $value ? 'True' : 'False';
    } else {
        $str = "$value";
    }

    # Encode to UTF-8 bytes for hashing (Digest::SHA requires bytes)
    utf8::encode($str) if utf8::is_utf8($str);
    return $str;
}

sub _hash_values_for_mac {
    my ($node, $ctx) = @_;

    if (ref $node eq 'HASH') {
        # SOPS iterates over keys in order they appear (we use sorted for consistency)
        for my $k (sort keys %$node) {
            _hash_values_for_mac($node->{$k}, $ctx);
        }
    }
    elsif (ref $node eq 'ARRAY') {
        for my $item (@$node) {
            _hash_values_for_mac($item, $ctx);
        }
    }
    else {
        # Hash the value with same conversion as SOPS ToBytes()
        my $value = _value_to_bytes($node);
        $ctx->add($value);
    }
}

sub _value_to_bytes {
    my ($value) = @_;
    return '' unless defined $value;

    my $str;

    # Handle JSON::PP::Boolean (from JSON::MaybeXS)
    if (ref $value && $value->isa('JSON::PP::Boolean')) {
        $str = $value ? 'True' : 'False';
    }
    else {
        # Detect type same as encryption
        my $type = _detect_type_for_mac($value);

        if ($type eq 'bool') {
            $str = ($value eq 'true' || $value eq '1' || $value) ? 'True' : 'False';
        } else {
            $str = "$value";
        }
    }

    # Encode to UTF-8 bytes for hashing (Digest::SHA requires bytes)
    utf8::encode($str) if utf8::is_utf8($str);
    return $str;
}

sub _detect_type_for_mac {
    my ($value) = @_;
    return 'str' unless defined $value;
    # JSON::PP::Boolean
    return 'bool' if ref $value && $value->isa('JSON::PP::Boolean');
    # Only string literals 'true'/'false' are bool, not '1'/'0' (those are ints)
    return 'bool' if $value eq 'true' || $value eq 'false';
    return 'int' if $value =~ /^-?\d+$/;
    return 'float' if $value =~ /^-?\d+\.\d+$/;
    return 'str';
}

sub _extract_path {
    my ($data, $path) = @_;

    # Parse path like ["database"]["password"] or .database.password
    my @parts;
    if ($path =~ /^\[/) {
        while ($path =~ /\["([^"]+)"\]/g) {
            push @parts, $1;
        }
    } else {
        $path =~ s/^\.//;
        @parts = split /\./, $path;
    }

    my $current = $data;
    for my $part (@parts) {
        if (ref $current eq 'HASH') {
            $current = $current->{$part};
        } elsif (ref $current eq 'ARRAY' && $part =~ /^\d+$/) {
            $current = $current->[$part];
        } else {
            croak "Cannot navigate path: $path";
        }
    }

    return $current;
}

sub _detect_format {
    my ($content) = @_;

    # Try to detect based on content
    if ($content =~ /^\s*\{/) {
        return 'json';
    }
    return 'yaml';
}

sub _detect_format_from_filename {
    my ($filename) = @_;

    return 'json' if $filename =~ /\.json$/i;
    return 'yaml' if $filename =~ /\.ya?ml$/i;
    return 'yaml';
}

sub _random_bytes {
    my ($length) = @_;
    my $bytes = '';
    if (eval { require Crypt::PRNG; 1 }) {
        $bytes = Crypt::PRNG::random_bytes($length);
    } else {
        open my $fh, '<:raw', '/dev/urandom'
            or croak "Cannot open /dev/urandom: $!";
        read $fh, $bytes, $length;
        close $fh;
    }
    return $bytes;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS - Perl implementation of Mozilla SOPS encrypted file format

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use File::SOPS;

    # Encrypt a data structure
    my $encrypted = File::SOPS->encrypt(
        data       => {
            database => {
                password => 'secret123',
                host     => 'db.example.com',
            },
        },
        recipients => ['age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p'],
        format     => 'yaml',
    );

    # Decrypt
    my $data = File::SOPS->decrypt(
        encrypted  => $encrypted,
        identities => ['AGE-SECRET-KEY-1...'],
    );

    # File operations
    File::SOPS->encrypt_file(
        input      => 'secrets.yaml',
        output     => 'secrets.enc.yaml',
        recipients => ['age1...'],
    );

    File::SOPS->decrypt_file(
        input      => 'secrets.enc.yaml',
        output     => 'secrets.yaml',
        identities => ['AGE-SECRET-KEY-1...'],
    );

    # Extract single value
    my $password = File::SOPS->extract(
        file       => 'secrets.enc.yaml',
        path       => '["database"]["password"]',
        identities => ['AGE-SECRET-KEY-1...'],
    );

    # Rotate data key
    File::SOPS->rotate(
        file       => 'secrets.enc.yaml',
        identities => ['AGE-SECRET-KEY-1...'],
    );

=head1 DESCRIPTION

File::SOPS is a pure Perl implementation of Mozilla SOPS (Secrets OPerationS),
compatible with the reference Go implementation at L<https://github.com/getsops/sops>.

SOPS encrypts B<values> in structured files (YAML, JSON) while keeping B<keys>
readable. This enables:

=over 4

=item * Git-friendly diffs - see which keys changed without decrypting

=item * Partial file inspection without full decryption

=item * Multiple encryption backends (currently age, with PGP/KMS planned)

=item * MAC verification to detect tampering

=back

=head2 How SOPS Works

=over 4

=item 1. Generate a random 256-bit data key

=item 2. Encrypt the data key for each recipient using age (X25519 + ChaCha20-Poly1305)

=item 3. Store encrypted data keys in the C<sops> metadata section

=item 4. Encrypt each value with AES-256-GCM using the data key

=item 5. Compute MAC over the entire structure for tamper detection

=back

=head2 Encrypted Value Format

Each encrypted value is stored as:

    ENC[AES256_GCM,data:base64==,iv:base64==,tag:base64==,type:str]

=head2 File Structure Example

    database:
        password: ENC[AES256_GCM,data:xyz,iv:abc,tag:def,type:str]
        host: ENC[AES256_GCM,data:xyz,iv:abc,tag:def,type:str]
    sops:
        age:
            - recipient: age1ql3z7hjy...
              enc: |
                -----BEGIN AGE ENCRYPTED FILE-----
                <encrypted data key>
                -----END AGE ENCRYPTED FILE-----
        lastmodified: "2025-01-10T12:00:00Z"
        mac: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
        version: 3.7.3

=head2 Special Features

=over 4

=item * B<unencrypted_suffix> - Keys ending with C<_unencrypted> are not encrypted but included in MAC

=item * B<Key rotation> - Re-encrypt all values with a new data key via L</rotate>

=item * B<Multiple recipients> - Encrypt once, multiple recipients can decrypt

=back

=head2 encrypt

    my $encrypted = File::SOPS->encrypt(
        data       => \%data,
        recipients => \@age_public_keys,
        format     => 'yaml',  # or 'json', defaults to 'yaml'
    );

Encrypts a data structure for specified recipients.

Takes a HashRef in C<data>, encrypts all values (not keys) using AES-256-GCM,
and encrypts the data key for each age recipient. Returns serialized encrypted
content as a string.

The C<recipients> parameter must be an ArrayRef of age public keys (starting
with C<age1...>).

Supported formats: C<yaml>, C<yml>, C<json>.

=head2 decrypt

    my $data = File::SOPS->decrypt(
        encrypted  => $encrypted_content,
        identities => \@age_secret_keys,
        format     => 'yaml',  # optional, auto-detected
    );

Decrypts SOPS-encrypted content.

Takes encrypted content as a string, decrypts the data key using provided age
identities, verifies the MAC, and returns the decrypted data structure as a
HashRef.

The C<identities> parameter must be an ArrayRef of age secret keys (starting
with C<AGE-SECRET-KEY-1...>).

If C<format> is not specified, it will be auto-detected from the content.

Dies if MAC verification fails or if none of the provided identities can
decrypt the data key.

=head2 encrypt_file

    File::SOPS->encrypt_file(
        input      => 'secrets.yaml',
        output     => 'secrets.enc.yaml',  # optional, defaults to input (in-place)
        recipients => \@age_public_keys,
        format     => 'yaml',              # optional, auto-detected from filename
    );

Encrypts a file.

Reads the input file, encrypts it for the specified recipients, and writes the
encrypted content to the output file. If C<output> is not specified, encrypts
in-place (overwrites the input file).

Format is auto-detected from the filename extension (C<.yaml>, C<.yml>, C<.json>)
unless explicitly specified.

Returns true on success.

=head2 decrypt_file

    File::SOPS->decrypt_file(
        input      => 'secrets.enc.yaml',
        output     => 'secrets.yaml',
        identities => \@age_secret_keys,
        format     => 'yaml',  # optional, auto-detected from filename
    );

Decrypts a SOPS-encrypted file.

Reads the encrypted input file, decrypts it using the provided identities,
and writes the decrypted content to the output file.

Unlike L</encrypt_file>, C<output> is required to prevent accidental data loss.

Returns true on success.

=head2 extract

    my $value = File::SOPS->extract(
        file       => 'secrets.enc.yaml',
        path       => '["database"]["password"]',
        identities => \@age_secret_keys,
        format     => 'yaml',  # optional, auto-detected from filename
    );

Extracts and decrypts a single value from an encrypted file.

This is more efficient than decrypting the entire file when you only need
one value.

Path can be specified in two formats:

=over 4

=item * Bracket notation: C<["database"]["password"]>

=item * Dot notation: C<database.password>

=back

For array indices, use numeric keys: C<["items"][0]> or C<items.0>

Returns the decrypted value (scalar, not reference).

=head2 rotate

    File::SOPS->rotate(
        file       => 'secrets.enc.yaml',
        identities => \@age_secret_keys,
        recipients => \@new_recipients,  # optional, keeps current recipients
        format     => 'yaml',            # optional, auto-detected from filename
    );

Rotates the data key (re-encrypts all values with a new key).

This operation:

=over 4

=item 1. Decrypts the file using C<identities>

=item 2. Generates a new random data key

=item 3. Re-encrypts all values with the new data key

=item 4. Encrypts the new data key for C<recipients> (or existing recipients if not specified)

=item 5. Writes back to the same file

=back

Key rotation is recommended periodically for security, or when removing
a recipient's access.

Returns true on success.

=head1 SEE ALSO

=over 4

=item * L<File::SOPS::Encrypted> - Encrypted value parsing and generation

=item * L<File::SOPS::Metadata> - SOPS metadata section handling

=item * L<File::SOPS::Backend::Age> - Age encryption backend

=item * L<Crypt::Age> - Perl age encryption implementation

=item * L<https://github.com/getsops/sops> - Reference SOPS implementation in Go

=item * L<https://age-encryption.org/> - age encryption specification

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
