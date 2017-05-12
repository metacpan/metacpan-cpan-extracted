package JSON::WebEncryption;

use strict;

use parent 'Exporter';

our $VERSION = '0.05';

use Carp qw(croak);
use Crypt::CBC;
use Crypt::OpenSSL::RSA;
use JSON qw(decode_json encode_json);
use Digest::SHA qw(hmac_sha256 hmac_sha512);
use MIME::Base64 qw(encode_base64url decode_base64url);

our @EXPORT = qw( encode_jwe decode_jwe );

our %allowed_alg = (
"dir"    => [ \&_alg_dir_encode,    \&_alg_dir_decode    ],
"RSA1_5" => [ \&_alg_RSA1_5_encode, \&_alg_RSA1_5_decode ],
);

our %allowed_enc = (
#                   Type     keysize ivsize    pading  integrity func
"A128CBC-HS256" => ['Rijndael', '128', '128', 'PKCS#5', \&hmac_sha256], # AES 128 in CBC with SHA256 HMAC integrity check
"A256CBC-HS512" => ['Rijndael', '256', '128', 'PKCS#5', \&hmac_sha512], # AES 256 in CBC with SHA512 HMAC integrity check
"BF128BC-HS256" => ['Blowfish', '128',  '64', 'PKCS#5', \&hmac_sha256], # Blowfish 128 in CBC with SHA256 HMAC integrity check
);

our %crypt_padding_map = (
    'PKCS#5' => 'standard'
);

# -----------------------------------------------------------------------------

sub new {
    my($caller, %arg) = @_;

    my $self =  bless {}, $caller;

    $self->{alg}         = $arg{alg};
    $self->{enc}         = $arg{enc};
    $self->{key}         = $arg{key};
    $self->{private_key} = $arg{private_key};
    $self->{public_key}  = $arg{public_key};

    return $self;
}

# -----------------------------------------------------------------------------

sub encode_from_hash {
    my ($self, $hash) = @_;

    return $self->encode(encode_json($hash));
}

# -----------------------------------------------------------------------------

sub decode_to_hash {
    my ($self, $jwe) = @_;

    return decode_json($self->decode($jwe));
}

# -----------------------------------------------------------------------------

sub encode
{
    my ($self, $plaintext, $enc, $key, $alg, $extra_headers ) = @_;

    $alg //= $self->{alg};
    $enc //= $self->{enc};

    my $alg_params = $allowed_alg{$alg};
    my $enc_params = $allowed_enc{$enc};

    croak "Unsupported alg value $alg. Possible values are ".join( ', ', (keys %allowed_alg) ) unless $alg_params;
    croak "Unsupported enc value $enc. Possible values are ".join( ', ', (keys %allowed_enc) ) unless $enc_params;

    my $ivsize       = $enc_params->[2] / 8; # /8 to get it in bytes
    my $integrity_fn = $enc_params->[4];

    my $iv = Crypt::CBC->random_bytes($ivsize);

    my $encoder = $alg_params->[0];

    my ($ciphertext, $encrypted_key) = &$encoder( $self, $enc_params, $key, $iv, $plaintext );

    $extra_headers //= {};

    my $header = {
        typ => 'JWE',
        alg => $alg,
        enc => $enc,
        %$extra_headers,
    };

    my @segment;
    push @segment, encode_base64url( encode_json($header) );
    push @segment, encode_base64url( $encrypted_key );
    push @segment, encode_base64url( $iv );
    push @segment, encode_base64url( $ciphertext );

    my $to_be_signed = join('.', @segment);

    my $icheck = encode_base64url( &$integrity_fn( $to_be_signed ) );

   return $to_be_signed.".$icheck";
}

# -----------------------------------------------------------------------------

sub encode_jwe
{
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    __PACKAGE__->encode(@_);
}

# -----------------------------------------------------------------------------

sub decode
{
    my ($self, $jwe, $key) = @_;

    my @segment = split( /\./, $jwe );

    # Decode the header first, to see what we're dealing with
    #
    my $header = decode_json( decode_base64url( $segment[0] ) );

    croak "Cannot decode a non JWE message."  if $header->{typ} ne 'JWE';

    my $alg_params = $allowed_alg{$header->{alg}};
    my $enc_params = $allowed_enc{$header->{enc}};

    croak "Unsupported enc value in JWE. JWE may be decoded with env values of ".join( ', ', (keys %allowed_enc) ) unless $enc_params;
    croak "Unsupported alg value in JWE. JWE may be decoded with alg values of ".join( ', ', (keys %allowed_alg) ) unless $alg_params;

    my $encrypted_key = decode_base64url( $segment[1] );
    my $iv            = decode_base64url( $segment[2] );
    my $ciphertext    = decode_base64url( $segment[3] );
    my $icheckB64     = $segment[4];

    my $integrity_fn = $enc_params->[4];

    my $signed_section = substr( $jwe, 0, rindex($jwe, '.') );

    if( $icheckB64 ne encode_base64url( &$integrity_fn($signed_section) ) )
    {
        croak "Cannot decode JWE." ;
    }

    my $decoder = $alg_params->[1];

    my $plaintext = &$decoder( $self, $enc_params, $key, $iv, $ciphertext, $encrypted_key );

    return $plaintext;
}

# -----------------------------------------------------------------------------

sub decode_jwe
{
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    __PACKAGE__->decode(@_);
}

# -----------------------------------------------------------------------------

sub _getCipher
{
    my ($cipherType, $symetric_key, $padding, $iv, $keysize) = @_;
    my $cipher = Crypt::CBC->new( -literal_key => 1,
                                  -key         => $symetric_key,
                                  -keysize     => $keysize,
                                  -iv          => $iv,
                                  #-header      => 'salt', # Openssl Compatible
                                  -header      => 'none',
                                  -padding     => $padding,
                                  -cipher      => $cipherType
                                );
}


# -----------------------------------------------------------------------------

sub _alg_dir_encode
{
    my ( $self, $enc_params, $key, $iv, $plaintext ) = @_;

    $key //= $self->{key};

    my $cipherType = $enc_params->[0];
    my $keysize    = $enc_params->[1] / 8; # /8 to get it in bytes
    my $padding    = $crypt_padding_map{ $enc_params->[3] };

    my $cipher     = _getCipher( $cipherType, $key, $padding, $iv, $keysize );
    my $ciphertext = $cipher->encrypt( $plaintext );
    my $encrypted_key = '';

    return ($ciphertext, $encrypted_key);
}

# -----------------------------------------------------------------------------

sub _alg_dir_decode
{
    my ( $self, $enc_params, $key, $iv, $ciphertext  ) = @_;

    $key //= $self->{key};

    my $cipherType = $enc_params->[0];
    my $keysize    = $enc_params->[1] / 8; # /8 to get it in bytes
    my $padding    = $crypt_padding_map{ $enc_params->[3] };

    my $cipher = _getCipher( $cipherType, $key, $padding, $iv, $keysize );
    return $cipher->decrypt( $ciphertext );
}

# -----------------------------------------------------------------------------

sub _alg_RSA1_5_encode
{
    my ( $self, $enc_params, $public_key, $iv, $plaintext ) = @_;

    $public_key //= $self->{public_key};

    my $cipherType = $enc_params->[0];
    my $keysize    = $enc_params->[1] / 8; # /8 to get it in bytes
    my $padding    = $crypt_padding_map{ $enc_params->[3] };

    # Purely alg = RSA1_5
    my $rsa = Crypt::OpenSSL::RSA->new_public_key( $public_key ); # Key passed in is a Public Key
    $rsa->use_pkcs1_oaep_padding;

    my $CEK           = Crypt::CBC->random_bytes( $keysize );
    my $encrypted_key = $rsa->encrypt( $CEK );

    my $cipher     = _getCipher( $cipherType, $CEK, $padding, $iv, $keysize );
    my $ciphertext = $cipher->encrypt( $plaintext );

    return ($ciphertext, $encrypted_key);
}

# -----------------------------------------------------------------------------

sub _alg_RSA1_5_decode
{
    my ( $self, $enc_params, $private_key, $iv, $ciphertext, $encrypted_key  ) = @_;

    $private_key //= $self->{private_key};

    my $cipherType = $enc_params->[0];
    my $keysize    = $enc_params->[1] / 8; # /8 to get it in bytes
    my $padding    = $crypt_padding_map{ $enc_params->[3] };

    # Decrypt the encryption key using the Private Key
    my $rsa = Crypt::OpenSSL::RSA->new_private_key( $private_key ); # Key passed in is a Private Key
    $rsa->use_pkcs1_oaep_padding;
    my $CEK = $rsa->decrypt( $encrypted_key );

    # Use the encryption key to decrypt the message
    my $cipher = _getCipher( $cipherType, $CEK, $padding, $iv, $keysize );

    return  $cipher->decrypt( $ciphertext );
}

# -----------------------------------------------------------------------------
1;

__END__

=head1 NAME

JSON::WebEncryption - Perl JSON Web Encryption (JWE) implementation

=head1 DESCRIPTION



=cut
