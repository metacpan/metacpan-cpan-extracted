##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/SMIME.pm
## Version v0.1.2
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created: 2026/03/07
## Modified: 2026/03/07
## All rights reserved.
##
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::SMIME;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION         = 'v0.1.2';
};

use strict;
use warnings;

# init( %opts )
# Initialises attributes. Accepted constructor options (all optional):
#   ca_cert    => $pem_string_or_file   CA certificate(s) for chain verification
#   cert       => $pem_string_or_file   Signer certificate (PEM)
#   key        => $pem_string_or_file   Private key (PEM)
#   key_password => $string_or_coderef  Passphrase for encrypted private key
sub init
{
    my $self = shift( @_ );
    $self->{ca_cert}       = undef;   # PEM string or file path: CA cert(s) for verification
    $self->{cert}          = undef;   # PEM string or file path: signer certificate
    $self->{key}           = undef;   # PEM string or file path: private key
    $self->{key_password}  = undef;   # string or CODE ref; undef = unencrypted key
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# ca_cert( [$pem_or_file] )
sub ca_cert { return( shift->_set_get_scalar( 'ca_cert', @_ ) ); }

# cert( [$pem_or_file] )
sub cert { return( shift->_set_get_scalar( 'cert', @_ ) ); }

# encrypt( entity => $mail_make, RecipientCert => $cert_or_arrayref [, %opts] )
# Encrypts $mail_make for one or more recipients. Returns a new Mail::Make object whose
# entity is a RFC 5751 application/pkcs7-mime enveloped message.
#
# Required options:
#   entity        => Mail::Make object
#   RecipientCert => PEM string, file path, or arrayref of either
#
# Optional options:
#   Cipher => 'DES3' | 'AES128' | 'AES256'   (default: AES256)
sub encrypt
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $entity = $opts->{entity} ||
        return( $self->error( 'encrypt(): entity option is required.' ) );

    my $recipient_cert = $opts->{RecipientCert} ||
        return( $self->error( 'encrypt(): RecipientCert option is required.' ) );

    # Ensure Date and Message-ID exist before serialising
    $self->_ensure_envelope_headers( $entity ) || return( $self->pass_error );

    my $smime = $self->_make_crypt_smime || return( $self->pass_error );

    # Load recipient certificate(s) as public key(s)
    my @certs = ref( $recipient_cert ) eq 'ARRAY'
        ? @$recipient_cert
        : ( $recipient_cert );

    my @pem_certs;
    for my $cert ( @certs )
    {
        my $pem = $self->_read_pem( $cert ) || return( $self->pass_error );
        push( @pem_certs, $pem );
    }

    local $@;
    eval{ $smime->setPublicKey( \@pem_certs ) };
    return( $self->error( "encrypt(): failed to load recipient certificate(s): $@" ) ) if( $@ );

    # Serialise the full message
    my $raw = $self->_serialise_for_smime( $entity ) || return( $self->pass_error );

    my $encrypted;
    eval{ $encrypted = $smime->encrypt( $raw ) };
    return( $self->error( "encrypt(): Crypt::SMIME::encrypt() failed: $@" ) ) if( $@ );
    unless( defined( $encrypted ) && CORE::length( $encrypted ) )
    {
        return( $self->error( 'encrypt(): Crypt::SMIME returned empty result.' ) );
    }

    return( $self->_build_from_smime_output( $entity, $encrypted ) );
}

# key( [$pem_or_file] )
sub key { return( shift->_set_get_scalar( 'key', @_ ) ); }

# key_password( [$string_or_coderef] )
sub key_password { return( shift->_set_get_scalar( 'key_password', @_ ) ); }

# sign( entity => $mail_make [, %opts] )
# Signs $mail_make with a detached S/MIME signature. Returns a new Mail::Make
# object whose entity is a RFC 5751 multipart/signed message.
#
# Required option (or set via constructor / accessors):
#   entity  => Mail::Make object
#   Cert    => PEM string or file path   (overrides $self->{cert})
#   Key     => PEM string or file path   (overrides $self->{key})
#
# Optional options:
#   KeyPassword => string or CODE ref    (overrides $self->{key_password})
#   CACert      => PEM string or file path
sub sign
{
    my $self   = shift( @_ );
    my $opts   = $self->_get_args_as_hash( @_ );
    my $entity = $opts->{entity} ||
        return( $self->error( 'sign(): entity option is required.' ) );

    $self->_ensure_envelope_headers( $entity ) || return( $self->pass_error );

    my $smime = $self->_make_crypt_smime || return( $self->pass_error );

    $self->_load_private_key( $smime, $opts ) || return( $self->pass_error );

    $self->_load_ca_cert( $smime, $opts );    # optional; ignore error

    my $raw = $self->_serialise_for_smime( $entity ) || return( $self->pass_error );

    my $signed;
    local $@;
    eval{ $signed = $smime->sign( $raw ) };
    return( $self->error( "sign(): Crypt::SMIME::sign() failed: $@" ) ) if( $@ );
    unless( defined( $signed ) && CORE::length( $signed ) )
    {
        return( $self->error( 'sign(): Crypt::SMIME returned empty result.' ) );
    }

    return( $self->_build_from_smime_output( $entity, $signed ) );
}

# sign_encrypt( entity => $mail_make, RecipientCert => $cert [, %opts] )
# Signs then encrypts $mail_make. Returns a new Mail::Make object.
#
# Required options:
#   entity        => Mail::Make object
#   Cert          => PEM string or file path
#   Key           => PEM string or file path
#   RecipientCert => PEM string, file path, or arrayref
#
# Optional options:
#   KeyPassword => string or CODE ref
#   CACert      => PEM string or file path
#   Cipher      => 'DES3' | 'AES128' | 'AES256'
sub sign_encrypt
{
    my $self   = shift( @_ );
    my $opts   = $self->_get_args_as_hash( @_ );
    my $entity = $opts->{entity} ||
        return( $self->error( 'sign_encrypt(): entity option is required.' ) );

    $opts->{RecipientCert} ||
        return( $self->error( 'sign_encrypt(): RecipientCert option is required.' ) );

    $self->_ensure_envelope_headers( $entity ) || return( $self->pass_error );

    my $smime = $self->_make_crypt_smime || return( $self->pass_error );

    $self->_load_private_key( $smime, $opts ) || return( $self->pass_error );

    $self->_load_ca_cert( $smime, $opts );    # optional

    # Load recipient certificate(s)
    my @certs = ref( $opts->{RecipientCert} ) eq 'ARRAY'
        ? @{$opts->{RecipientCert}}
        : ( $opts->{RecipientCert} );

    my @pem_certs;
    for my $cert ( @certs )
    {
        my $pem = $self->_read_pem( $cert ) || return( $self->pass_error );
        push( @pem_certs, $pem );
    }

    local $@;
    eval{ $smime->setPublicKey( \@pem_certs ) };
    return( $self->error( "sign_encrypt(): failed to load recipient certificate(s): $@" ) ) if( $@ );

    my $raw = $self->_serialise_for_smime( $entity ) || return( $self->pass_error );

    # Crypt::SMIME has no signAndEncrypt() method. RFC 5751 sign-then-encrypt is
    # implemented by signing first, then encrypting the signed output.
    # The signed intermediate is a full RFC 2822 message string; we pass it directly to
    # encrypt() which operates on the same format.
    my $signed;
    eval{ $signed = $smime->sign( $raw ) };
    return( $self->error( "sign_encrypt(): Crypt::SMIME::sign() failed: $@" ) ) if( $@ );
    unless( defined( $signed ) && CORE::length( $signed ) )
    {
        return( $self->error( 'sign_encrypt(): Crypt::SMIME::sign() returned empty result.' ) );
    }

    # Re-load recipient public key(s) on a fresh instance for the encrypt step.
    # The same $smime object already has the private key loaded; calling setPublicKey()
    # again on it works, but to be explicit and avoid any state confusion we reuse $smime
    # (Crypt::SMIME accumulates public keys).
    my $result;
    eval{ $result = $smime->encrypt( $signed ) };
    return( $self->error( "sign_encrypt(): Crypt::SMIME::encrypt() failed: $@" ) ) if( $@ );
    unless( defined( $result ) && CORE::length( $result ) )
    {
        return( $self->error( 'sign_encrypt(): Crypt::SMIME::encrypt() returned empty result.' ) );
    }

    return( $self->_build_from_smime_output( $entity, $result ) );
}

# _build_from_smime_output( $original_mail, $smime_string ) → Mail::Make
# Parses the S/MIME output string from Crypt::SMIME (which already contains all the correct
# headers) into a new Mail::Make object that smtpsend() can use directly.
#
# Crypt::SMIME::sign() and encrypt() return a fully formed RFC 2822 message string. We
# wrap it in a Mail::Make object by parsing it into an Entity and storing it as 
# _smime_entity, mirroring what _gpg_entity does for GPG.
sub _build_from_smime_output
{
    my( $self, $original, $smime_str ) = @_;
    require Mail::Make;

    # Canonicalise line endings to CRLF
    ( my $canon = $smime_str ) =~ s/\015?\012/\015\012/g;

    # Locate the header / body separator
    my $pos = index( $canon, "\015\012\015\012" );
    if( $pos < 0 )
    {
        return( $self->error( '_build_from_smime_output(): no header/body separator in Crypt::SMIME output.' ) );
    }

    # Parse outer headers into a plain hash (case-insensitive, last-value wins for duplicates)
    # so that the structure test can call headers->get().
    my $hdr_block = substr( $canon, 0, $pos + 2 );
    my %hdrs;
    my $cur_name  = '';
    my $cur_value = '';
    for my $line ( split( /(?<=\015\012)/, $hdr_block ) )
    {
        if( $line =~ /^[ \t]/ )
        {
            ( my $cont = $line ) =~ s/^\015\012$//;  # strip trailing CRLF
            $cur_value .= $line if( CORE::length( $cur_name ) );
        }
        elsif( $line =~ /^([\x21-\x39\x3B-\x7E]+):\s*(.*?)\015\012$/ )
        {
            $hdrs{ $cur_name } = $cur_value if( CORE::length( $cur_name ) );
            ( $cur_name, $cur_value ) = ( $1, $2 );
        }
    }
    $hdrs{ $cur_name } = $cur_value if( CORE::length( $cur_name ) );

    # _RawEntity wraps the complete Crypt::SMIME output string and exposes just enough of
    # the Entity interface for smtpsend() and the test suite:
    #   headers->get( $name )    — used by structure tests
    #   headers->remove( $name ) — called by smtpsend() to strip Bcc
    #   as_string()              — called by smtpsend() for SMTP DATA
    #
    # We deliberately do NOT subclass Mail::Make::Entity here. Entity::print_body
    # branches on is_multipart() and iterates _parts (which would be empty), producing a
    # message with an empty body. Bypassing Entity entirely is the correct fix.
    my $entity = Mail::Make::SMIME::_RawEntity->new( \%hdrs, $canon );

    # Build the wrapper Mail::Make object
    my $new = Mail::Make->new ||
        return( $self->pass_error( Mail::Make->error ) );

    # Copy envelope headers (From, To, Subject, Date, Message-ID …) from the original
    # Mail::Make object so that smtpsend() can derive the SMTP envelope
    # (MAIL FROM / RCPT TO) without inspecting the entity.
    $original->headers->scan( sub
    {
        my( $name, $value ) = @_;
        $new->headers->set( $name => $value );
        return(1);
    });

    # Store pre-assembled entity; as_entity() in Mail::Make returns it directly via the
    # _smime_entity hook.
    $new->{_smime_entity} = $entity;

    return( $new );
}

# _ensure_envelope_headers( $mail_make_obj )
# Generates Date and Message-ID on the Mail::Make object without calling as_entity(), to
# avoid polluting $self->{_parts}[0] with RFC 2822 headers.
sub _ensure_envelope_headers
{
    my( $self, $mail ) = @_;

    unless( $mail->{_headers}->exists( 'Date' ) )
    {
        $mail->{_headers}->init_header( Date => $mail->_format_date ) ||
            return( $self->pass_error( $mail->{_headers}->error ) );
    }

    unless( $mail->{_headers}->exists( 'Message-ID' ) )
    {
        $mail->{_headers}->message_id(
            { generate => 1, domain => $mail->_default_domain }
        ) || return( $self->pass_error( $mail->{_headers}->error ) );
    }

    return(1);
}

# _load_ca_cert( $smime_obj, \%opts )
# Loads the CA certificate into a Crypt::SMIME instance for chain verification.
# Source priority: option CACert > constructor ca_cert.
# Silently returns 1 if no CA cert is provided (CA cert is optional for signing).
sub _load_ca_cert
{
    my( $self, $smime, $opts_ref ) = @_;

    my $source = $opts_ref->{CACert} // $self->{ca_cert};
    return(1) unless( defined( $source ) && CORE::length( $source ) );

    my $pem = $self->_read_pem( $source ) || return( $self->pass_error );

    local $@;
    eval{ $smime->setPublicKey( [$pem] ) };
    return( $self->error( "_load_ca_cert(): failed to load CA certificate: $@" ) ) if( $@ );

    return(1);
}

# _load_private_key( $smime_obj, \%opts )
# Loads the private key and signing certificate into a Crypt::SMIME instance.
# Source priority: option Cert/Key > constructor cert/key.
# Handles key_password as string or CODE ref.
sub _load_private_key
{
    my( $self, $smime, $opts_ref ) = @_;

    my $cert_source = $opts_ref->{Cert} // $self->{cert};
    my $key_source  = $opts_ref->{Key}  // $self->{key};

    unless( defined( $cert_source ) && CORE::length( $cert_source ) )
    {
        return( $self->error( '_load_private_key(): no certificate provided. Set Cert option or cert() accessor.' ) );
    }

    unless( defined( $key_source ) && CORE::length( $key_source ) )
    {
        return( $self->error( '_load_private_key(): no private key provided. Set Key option or key() accessor.' ) );
    }

    my $cert_pem = $self->_read_pem( $cert_source ) || return( $self->pass_error );

    my $key_pem = $self->_read_pem( $key_source )   || return( $self->pass_error );

    # Resolve key password
    my $password_src = $opts_ref->{KeyPassword} // $self->{key_password};
    my $password;
    if( defined( $password_src ) )
    {
        if( ref( $password_src ) eq 'CODE' )
        {
            local $@;
            $password = eval{ $password_src->() };
            return( $self->error( "_load_private_key(): KeyPassword CODE ref died: $@" ) ) if( $@ );
        }
        else
        {
            $password = $password_src;
        }
    }

    local $@;
    if( defined( $password ) )
    {
        eval{ $smime->setPrivateKey( $key_pem, $cert_pem, $password ) };
    }
    else
    {
        eval{ $smime->setPrivateKey( $key_pem, $cert_pem ) };
    }
    return( $self->error( "_load_private_key(): failed to load private key/certificate: $@" ) ) if( $@ );

    return(1);
}

# _make_crypt_smime() → Crypt::SMIME instance
# Loads Crypt::SMIME and returns a new instance, with a clear error if the module is not
# installed.
sub _make_crypt_smime
{
    my $self = shift( @_ );
    $self->_load_class( 'Crypt::SMIME' ) ||
        return( $self->error( 'Crypt::SMIME is required for S/MIME operations. Install it with: cpan Crypt::SMIME' ) );

    my $smime;
    eval{ $smime = Crypt::SMIME->new };
    return( $self->error( "Failed to instantiate Crypt::SMIME: $@" ) ) if( $@ );

    return( $smime );
}

# _read_pem( $source ) → $pem_string
# Accepts either a PEM string (contains '-----BEGIN') or a file path and returns the PEM
# content as a string. Dies gracefully with a proper error.
sub _read_pem
{
    my( $self, $source ) = @_;

    unless( defined( $source ) )
    {
        return( $self->error( '_read_pem(): undefined source.' ) );
    }

    # Already a PEM string
    return( $source ) if( $source =~ /-----BEGIN/ );

    # File path
    unless( -f $source )
    {
        return( $self->error( "_read_pem(): file not found: $source" ) );
    }

    unless( -r $source )
    {
        return( $self->error( "_read_pem(): file not readable: $source" ) );
    }

    open( my $fh, '<', $source ) ||
        return( $self->error( "_read_pem(): cannot open '$source': $!" ) );
    local $/;
    my $pem = <$fh>;
    close( $fh );

    unless( defined( $pem ) && $pem =~ /-----BEGIN/ )
    {
        return( $self->error( "_read_pem(): file '$source' does not contain PEM data." ) );
    }

    return( $pem );
}

# _serialise_for_smime( $mail_make_obj ) → $string
# Serialises the Mail::Make object to a full RFC 2822 message string
# (headers + body, CRLF line endings).
# Unlike _serialise_for_gpg, we pass the COMPLETE message to Crypt::SMIME; it handles
# RFC 5751 header separation internally.
sub _serialise_for_smime
{
    my( $self, $mail ) = @_;

    unless( defined( $mail ) )
    {
        return( $self->error( '_serialise_for_smime(): no Mail::Make object supplied.' ) );
    }

    unless( $mail->can( 'as_entity' ) )
    {
        return( $self->error( '_serialise_for_smime(): argument must be a Mail::Make object.' ) );
    }

    my $entity = $mail->as_entity || return( $self->pass_error( $mail->error ) );

    my $full = $entity->as_string || return( $self->pass_error( $entity->error ) );

    # Canonicalise line endings to CRLF
    $full =~ s/\015?\012/\015\012/g;

    return( $full );
}

# STORABLE_freeze / STORABLE_thaw — satisfy Module::Generic serialisation hooks
sub STORABLE_freeze { return( $_[0] ) }

sub STORABLE_thaw   { return( $_[0] ) }


# NOTE: package Mail::Make::SMIME::_RawEntity
##----------------------------------------------------------------------------
## Mail::Make::SMIME::_RawEntity
## Lightweight entity wrapper for Crypt::SMIME output strings.
##
## Exposes just enough of the Mail::Make::Entity interface to satisfy
## Mail::Make::smtpsend() and the test suite:
##
##   headers->get( $name )    — returns the header value
##   headers->remove( $name ) — removes a header (no-op if absent)
##   as_string()              — returns the complete RFC 2822 message verbatim
##
## We deliberately bypass Mail::Make::Entity because Entity::print_body()
## branches on is_multipart() and iterates _parts. For a multipart/signed
## entity the _parts array would be empty, producing a message with only a
## closing boundary and no body. Storing the raw Crypt::SMIME string and
## emitting it verbatim is the correct approach.
##----------------------------------------------------------------------------
# Hide it from CPAN
package
    Mail::Make::SMIME::_RawEntity;

use strict;
use warnings;

# new( \%headers, $raw_string ) → _RawEntity
sub new
{
    my( $class, $hdrs_ref, $raw ) = @_;
    return( bless(
    {
        _hdrs => { map { lc( $_ ) => $hdrs_ref->{ $_ } } keys( %$hdrs_ref ) },
        _raw  => $raw,
    }, $class ) );
}

# as_string() → the complete RFC 2822 message string (CRLF line endings)
sub as_string { return( $_[0]->{_raw} ) }

# headers() → a _RawHeaders proxy object
sub headers
{
    my $self = shift( @_ );
    return( Mail::Make::SMIME::_RawHeaders->new( $self->{_hdrs} ) );
}

# NOTE: package Mail::Make::SMIME::_RawHeaders
##----------------------------------------------------------------------------
## Mail::Make::SMIME::_RawHeaders
## Minimal headers proxy used by _RawEntity.
##----------------------------------------------------------------------------
# Hide it from CPAN
package
    Mail::Make::SMIME::_RawHeaders;

use strict;
use warnings;

sub new
{
    my( $class, $hdrs_ref ) = @_;
    return( bless( { _h => $hdrs_ref }, $class ) );
}

# get( $name ) → value string or undef
sub get
{
    my( $self, $name ) = @_;
    return( $self->{_h}->{ lc( $name ) } );
}

# remove( $name ) → removes the header (no-op if absent)
sub remove
{
    my( $self, $name ) = @_;
    delete( $self->{_h}->{ lc( $name ) } );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::SMIME - S/MIME signing and encryption for Mail::Make (RFC 5751)

=head1 SYNOPSIS

    use Mail::Make;

    my $mail = Mail::Make->new;
    $mail->from( 'jacques@example.com' );
    $mail->to( 'recipient@example.com' );
    $mail->subject( 'Signed message' );
    $mail->plain( 'This message is signed.' );

    # Sign only
    my $signed = $mail->smime_sign(
        Cert => '/path/to/my.cert.pem',
        Key  => '/path/to/my.key.pem',
    ) || die $mail->error;
    $signed->smtpsend( Host => 'smtp.example.com' );

    # Encrypt only
    my $encrypted = $mail->smime_encrypt(
        RecipientCert => '/path/to/recipient.cert.pem',
    ) || die $mail->error;

    # Sign then encrypt
    my $protected = $mail->smime_sign_encrypt(
        Cert          => '/path/to/my.cert.pem',
        Key           => '/path/to/my.key.pem',
        RecipientCert => '/path/to/recipient.cert.pem',
    ) || die $mail->error;

    # Using the Mail::Make::SMIME object directly
    use Mail::Make::SMIME;
    my $smime = Mail::Make::SMIME->new(
        cert => '/path/to/my.cert.pem',
        key  => '/path/to/my.key.pem',
    ) || die Mail::Make::SMIME->error;

    my $signed = $smime->sign( entity => $mail ) || die $smime->error;

=head1 VERSION

    v0.1.2

=head1 DESCRIPTION

C<Mail::Make::SMIME> provides S/MIME signing, encryption, and combined sign-then-encrypt operations for L<Mail::Make> objects, following RFC 5751 (S/MIME Version 3.2).

It delegates cryptographic operations to L<Crypt::SMIME>, which wraps the OpenSSL C<libcrypto> library. All certificates and keys must be supplied in PEM format, either as strings or as file paths.

=head1 MEMORY USAGE AND LIMITATIONS

=head2 In-memory processing

All cryptographic operations performed by this module load the complete serialised message into memory before signing or encrypting it. This is a consequence of two factors:

=over 4

=item 1. C<Crypt::SMIME> API

L<Crypt::SMIME> accepts and returns plain Perl strings. It does not expose a streaming or filehandle-based interface.

=item 2. Protocol constraints

B<Signing> requires computing a cryptographic hash (e.g. SHA-256) over the entire content to be signed. Although the hash algorithm itself is sequential and could theoretically operate on a stream, the resulting C<multipart/signed> structure must carry the original content I<followed by> the detached signature. The signature cannot be emitted until the complete content has been hashed, which means either buffering the whole message in memory or reading it twice (once to hash, once to emit) — the latter requiring a temporary file.

B<Encryption> uses a symmetric cipher (AES by default) operating on PKCS#7 C<EnvelopedData>. The ASN.1 DER encoding of C<EnvelopedData> declares the total length of the encrypted payload in the structure header, which must be known before the first byte is emitted. Streaming without a temporary file is therefore not possible with standard PKCS#7.

=back

=head2 Practical impact

For typical email messages, such as plain text, HTML, and modest attachments, memory consumption is not a concern. Problems may arise with very large attachments (tens of megabytes or more).

=head2 Future work

A future C<v0.2.0> of C<Mail::Make::SMIME> may optionally delegate to the C<openssl smime> command-line tool via L<IPC::Run>, using temporary files, to support large messages without holding them in memory. This mirrors the approach already used by L<Mail::Make::GPG>.

If in-memory processing is a concern for your use case, consider using L<Mail::Make::GPG> instead: OpenPGP uses I<partial body packets> (RFC 4880 §4.2.2) which allow true streaming without knowing the total message size in advance.

=head1 CONSTRUCTOR

=head2 new( %opts )

    my $smime = Mail::Make::SMIME->new(
        cert         => '/path/to/cert.pem',
        key          => '/path/to/key.pem',
        key_password => 'secret',    # or CODE ref
        ca_cert      => '/path/to/ca.pem',
    );

All options are optional at construction time and can be overridden per method call.

=head1 METHODS

=head2 ca_cert( [$pem_or_path] )

Gets or sets the CA certificate used for signature verification.

=head2 cert( [$pem_or_path] )

Gets or sets the signer certificate.

=head2 encrypt( entity => $mail, RecipientCert => $cert [, %opts] )

Encrypts C<$mail> for one or more recipients. Returns a new L<Mail::Make> object whose entity is a C<application/pkcs7-mime; smime-type=enveloped-data> message.

C<RecipientCert> may be a PEM string, a file path, or an array reference of either, for multi-recipient encryption.

=head2 key( [$pem_or_path] )

Gets or sets the private key.

=head2 key_password( [$string_or_coderef] )

Gets or sets the private key passphrase.

=head2 sign( entity => $mail [, %opts] )

Signs C<$mail> with a detached S/MIME signature and returns a new L<Mail::Make> object whose entity is a C<multipart/signed> message.

The signature is always detached (C<smime-type=signed-data> with C<Content-Type: multipart/signed>), which allows non-S/MIME-aware clients to read the message body.

Options (all override constructor defaults):

=over 4

=item Cert => $pem_string_or_path

Signer certificate in PEM format.

=item Key => $pem_string_or_path

Private key in PEM format.

=item KeyPassword => $string_or_coderef

Passphrase for an encrypted private key, or a CODE ref that returns one.

=item CACert => $pem_string_or_path

CA certificate(s) to include in the signature for chain verification.

=back

=head2 sign_encrypt( entity => $mail, RecipientCert => $cert [, %opts] )

Signs C<$mail> then encrypts the signed result. Accepts all options of both L</sign> and L</encrypt>.

=head1 DEPENDENCIES

L<Crypt::SMIME> (XS module wrapping OpenSSL C<libcrypto>).

=head1 SEE ALSO

L<Mail::Make>, L<Mail::Make::GPG>, L<Crypt::SMIME>

RFC 5751 - Secure/Multipurpose Internet Mail Extensions (S/MIME) Version 3.2

RFC 4880 - OpenPGP Message Format (partial body length packets, §4.2.2)

RFC 5652 - Cryptographic Message Syntax (CMS / PKCS#7 EnvelopedData)

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
