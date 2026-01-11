package File::SOPS::Encrypted;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Parse and generate SOPS encrypted values

use Moo;
use Carp qw(croak);
use MIME::Base64 qw(encode_base64 decode_base64);
use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate gcm_decrypt_verify);
use namespace::clean;


has algorithm => (is => 'ro', default => 'AES256_GCM');


has data => (is => 'ro', required => 1);


has iv => (is => 'ro', required => 1);


has tag => (is => 'ro', required => 1);


has type => (is => 'ro', default => 'str');


my $ENC_REGEX = qr/^ENC\[([^,]+),data:([^,]+),iv:([^,]+),tag:([^,]+),type:([^\]]+)\]$/;

sub parse {
    my ($class, $string) = @_;

    return unless defined $string && $string =~ $ENC_REGEX;

    my ($algo, $data, $iv, $tag, $type) = ($1, $2, $3, $4, $5);

    return $class->new(
        algorithm => $algo,
        data      => decode_base64($data),
        iv        => decode_base64($iv),
        tag       => decode_base64($tag),
        type      => $type,
    );
}


sub is_encrypted {
    my ($class, $string) = @_;
    return defined $string && $string =~ $ENC_REGEX;
}


sub to_string {
    my ($self) = @_;

    my $data = _encode_base64_oneline($self->data);
    my $iv   = _encode_base64_oneline($self->iv);
    my $tag  = _encode_base64_oneline($self->tag);

    return sprintf('ENC[%s,data:%s,iv:%s,tag:%s,type:%s]',
        $self->algorithm, $data, $iv, $tag, $self->type);
}


sub encrypt_value {
    my ($class, %args) = @_;
    my $value    = $args{value};
    my $key      = $args{key}      // croak "key required";
    my $aad      = $args{aad}      // '';
    my $type     = $args{type}     // _detect_type($value);

    $value //= '';
    my $plaintext = _serialize_value($value, $type);
    my $iv = _random_bytes(32);  # SOPS uses 32-byte nonce

    my ($ciphertext, $tag) = gcm_encrypt_authenticate('AES', $key, $iv, $aad, $plaintext);

    return $class->new(
        algorithm => 'AES256_GCM',
        data      => $ciphertext,
        iv        => $iv,
        tag       => $tag,
        type      => $type,
    );
}


sub decrypt_value {
    my ($self, %args) = @_;
    my $key = $args{key} // croak "key required";
    my $aad = $args{aad} // '';

    croak "Unsupported algorithm: " . $self->algorithm
        unless $self->algorithm eq 'AES256_GCM';

    my $plaintext = gcm_decrypt_verify('AES', $key, $self->iv, $aad, $self->data, $self->tag);
    croak "Authentication failed - data may be corrupted" unless defined $plaintext;

    return _deserialize_value($plaintext, $self->type);
}


sub _detect_type {
    my ($value) = @_;
    return 'str' unless defined $value;
    # JSON::PP::Boolean from JSON::MaybeXS
    return 'bool' if ref $value && $value->isa('JSON::PP::Boolean');
    # Only string literals 'true'/'false' are bool, not '1'/'0' (those are ints)
    return 'bool' if $value eq 'true' || $value eq 'false';
    return 'int' if $value =~ /^-?\d+$/;
    return 'float' if $value =~ /^-?\d+\.\d+$/;
    return 'str';
}

sub _serialize_value {
    my ($value, $type) = @_;
    return '' unless defined $value;

    my $str;

    # SOPS uses Titlecase for bools: "True" / "False"
    if ($type eq 'bool') {
        # Handle JSON::PP::Boolean
        if (ref $value && $value->isa('JSON::PP::Boolean')) {
            $str = $value ? 'True' : 'False';
        } else {
            $str = ($value eq 'true' || $value eq '1' || $value) ? 'True' : 'False';
        }
    } else {
        $str = "$value";
    }

    # Encode to UTF-8 bytes for encryption (GCM requires bytes)
    utf8::encode($str) if utf8::is_utf8($str);
    return $str;
}

sub _deserialize_value {
    my ($data, $type) = @_;
    return $data if $type eq 'str' || $type eq 'bytes';
    return int($data) if $type eq 'int';
    return $data + 0.0 if $type eq 'float';
    if ($type eq 'bool') {
        # SOPS uses "True"/"False" (titlecase)
        return 1 if lc($data) eq 'true' || $data eq '1';
        return 0;
    }
    return $data;
}

sub _encode_base64_oneline {
    my ($data) = @_;
    my $encoded = encode_base64($data, '');
    return $encoded;
}

sub _random_bytes {
    my ($length) = @_;
    my $bytes = '';
    if (eval { require Crypt::PRNG; 1 }) {
        $bytes = Crypt::PRNG::random_bytes($length);
    } else {
        open my $fh, '<:raw', '/dev/urandom' or croak "Cannot open /dev/urandom: $!";
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

File::SOPS::Encrypted - Parse and generate SOPS encrypted values

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use File::SOPS::Encrypted;

    # Parse an encrypted value string
    my $enc = File::SOPS::Encrypted->parse(
        'ENC[AES256_GCM,data:xyz,iv:abc,tag:def,type:str]'
    );

    # Check if a string is encrypted
    if (File::SOPS::Encrypted->is_encrypted($string)) {
        my $decrypted = $enc->decrypt_value(key => $data_key, aad => $path);
    }

    # Encrypt a value
    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => 'secret',
        key   => $data_key,
        aad   => 'database:password',
    );

    # Get encrypted string representation
    my $string = $enc->to_string;
    # => ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]

=head1 DESCRIPTION

File::SOPS::Encrypted handles parsing and generation of SOPS encrypted value
strings. Each encrypted value in a SOPS file is represented as:

    ENC[AES256_GCM,data:base64,iv:base64,tag:base64,type:str]

Values are encrypted with AES-256-GCM using:

=over 4

=item * A shared data key (32 bytes, encrypted separately for each recipient)

=item * A random initialization vector (IV) per value (12 bytes)

=item * Additional Authenticated Data (AAD) derived from the value's path

=item * Type preservation (str, int, float, bool, bytes)

=back

=head2 algorithm

Encryption algorithm. Currently only C<AES256_GCM> is supported. Defaults to C<AES256_GCM>.

=head2 data

Encrypted ciphertext as raw bytes. Required.

=head2 iv

Initialization vector (IV) as raw bytes, 12 bytes for AES-GCM. Required.

=head2 tag

Authentication tag as raw bytes, 16 bytes for AES-GCM. Required.

=head2 type

Original value type for deserialization. One of: C<str>, C<int>, C<float>, C<bool>, C<bytes>.

Defaults to C<str>.

=head2 parse

    my $enc = File::SOPS::Encrypted->parse($string);
    # Returns undef if $string is not encrypted

Parses a SOPS encrypted value string.

Takes a string like C<ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]> and
returns a File::SOPS::Encrypted object with decoded attributes.

Returns C<undef> if the string is not in the encrypted format.

=head2 is_encrypted

    if (File::SOPS::Encrypted->is_encrypted($string)) {
        # It's an encrypted value
    }

Class method to check if a string is in SOPS encrypted format.

Returns true if the string matches the C<ENC[...]> pattern.

=head2 to_string

    my $string = $enc->to_string;
    # => ENC[AES256_GCM,data:xyz==,iv:abc==,tag:def==,type:str]

Serializes the encrypted value to SOPS string format.

Returns a string representation with base64-encoded components.

=head2 encrypt_value

    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => 'secret',
        key   => $data_key,        # 32 bytes
        aad   => 'database:password',  # Additional Authenticated Data
        type  => 'str',            # optional, auto-detected
    );

Class method to encrypt a value.

Encrypts a scalar value using AES-256-GCM with a random IV. Returns a
File::SOPS::Encrypted object.

The C<aad> (Additional Authenticated Data) is typically the path to the value
in the data structure (e.g., C<database:password>), used to prevent value
substitution attacks.

Type is auto-detected from the value if not specified: C<int>, C<float>, C<bool>,
or C<str>.

=head2 decrypt_value

    my $value = $enc->decrypt_value(
        key => $data_key,  # 32 bytes
        aad => 'database:password',
    );

Decrypts the encrypted value.

Returns the decrypted value with type conversion applied (int, float, bool
are converted to appropriate Perl types).

Dies if authentication fails (wrong key, corrupted data, or mismatched AAD).

=head1 SEE ALSO

=over 4

=item * L<File::SOPS> - Main SOPS interface

=item * L<Crypt::AuthEnc::GCM> - AES-GCM implementation from CryptX

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
