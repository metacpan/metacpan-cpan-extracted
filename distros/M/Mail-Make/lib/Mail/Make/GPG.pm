##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/GPG.pm
## Version v0.1.4
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/05
## Modified 2026/03/05
## All rights reserved.
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::GPG;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    use Mail::Make::Exception;
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION         = 'v0.1.4';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{auto_fetch} = 0;       # bool: fetch missing recipient keys from keyserver
    $self->{digest}     = 'SHA256';
    $self->{gpg_bin}    = undef;   # explicit path to gpg binary; undef = search PATH
    $self->{key_id}     = undef;   # default signing key fingerprint or ID
    $self->{keyserver}  = undef;   # keyserver URL for auto-fetch
    $self->{passphrase} = undef;   # string or CODE ref; undef = use gpg-agent
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub auto_fetch { return( shift->_set_get_boolean( 'auto_fetch', @_ ) ); }

sub digest { return( shift->_set_get_scalar( 'digest', @_ ) ); }

# encrypt( entity => $entity, recipients => \@addrs [, %opts] )
# Signs $entity and returns a new Mail::Make object whose top-level MIME type is 
# multipart/encrypted per RFC 3156 §4.
#
# The caller is responsible for supplying recipient public keys in the GnuPG keyring.
# When AutoFetch + KeyServer are set, we attempt key retrieval first.
sub encrypt
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $entity     = $opts->{entity} ||
        return( $self->error( 'encrypt(): entity option is required.' ) );
    my $recipients = $opts->{recipients} ||
        return( $self->error( 'encrypt(): recipients option is required.' ) );
    $recipients = [ $recipients ] unless( ref( $recipients ) eq 'ARRAY' );
    unless( scalar( @$recipients ) )
    {
        return( $self->error( 'encrypt(): recipients must not be empty.' ) );
    }

    $self->_maybe_fetch_keys( $recipients ) || return( $self->pass_error );

    # Serialise the original message body for gpg input
    my $plaintext = $self->_serialise_for_gpg( $entity ) || return( $self->pass_error );

    my @args = ( $self->_base_gpg_args, '--encrypt', '--armor' );
    push( @args, '--recipient', $_ ) for( @{ $recipients } );

    my $ciphertext = $self->_run_gpg( \@args, \$plaintext ) || return( $self->pass_error );

    return( $self->_build_encrypted_mail( $entity, \$ciphertext ) );
}

sub gpg_bin { return( shift->_set_get_scalar( 'gpg_bin', @_ ) ); }

sub key_id { return( shift->_set_get_scalar( 'key_id', @_ ) ); }

sub keyserver { return( shift->_set_get_scalar( 'keyserver', @_ ) ); }

sub passphrase { return( shift->_set_get_scalar( 'passphrase', @_ ) ); }

# sign( entity => $entity [, %opts] )
# Signs $entity and returns a new Mail::Make object whose top-level MIME type is 
# multipart/signed per RFC 3156 §5.
sub sign
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $entity = $opts->{entity} ||
        return( $self->error( 'sign(): entity option is required.' ) );

    my $key_id = $self->_resolve_key_id( $opts ) ||
        return( $self->error( 'sign(): KeyId is required (set via option or gpg_sign() default).' ) );
    my $digest = uc( $opts->{digest} // $self->{digest} );

    # Ensure Date and Message-ID are committed to the Mail::Make object's own _headers 
    # BEFORE serialising. This must happen without calling as_entity(), which would merge
    # RFC 2822 headers onto $self->{_parts}[0].
    $self->_ensure_envelope_headers( $entity ) || return( $self->pass_error );

    # Serialise the MIME body that will be signed - Part 1 of multipart/signed.
    # Per RFC 3156 §5.1 this is the entity with CRLF line endings, exactly as it will 
    # appear on the wire.
    my $canonical = $self->_serialise_for_gpg( $entity ) || return( $self->pass_error );

    my $passphrase = $self->_resolve_passphrase( $opts );
    return( $self->pass_error ) if( $self->error );   # CODE ref may have thrown

    my @args = (
        $self->_base_gpg_args,
        '--detach-sign',
        '--armor',
        '--digest-algo', $digest,
        '--local-user',  $key_id,
    );
    if( defined( $passphrase ) )
    {
        push( @args, '--passphrase-fd', '0', '--pinentry-mode', 'loopback' );
    }

    my $signature = $self->_run_gpg( \@args, \$canonical, passphrase => $passphrase ) || return( $self->pass_error );

    return( $self->_build_signed_mail( $entity, \$signature, $canonical, digest => $digest ) );
}

# sign_encrypt( entity => $entity, recipients => \@addrs [, %opts] )
# Signs then encrypts $entity. The result is a multipart/encrypted message whose payload 
# is a signed+encrypted OpenPGP message.
sub sign_encrypt
{
    my $self       = shift( @_ );
    my $opts       = $self->_get_args_as_hash( @_ );
    my $entity     = $opts->{entity} || return( $self->error( 'sign_encrypt(): entity option is required.' ) );
    my $recipients = $opts->{recipients} || return( $self->error( 'sign_encrypt(): recipients option is required.' ) );
    $recipients    = [ $recipients ] unless( ref( $recipients ) eq 'ARRAY' );
    unless( scalar( @$recipients ) )
    {
        return( $self->error( 'sign_encrypt(): recipients must not be empty.' ) );
    }

    my $key_id = $self->_resolve_key_id( $opts ) || return( $self->error( 'sign_encrypt(): KeyId is required.' ) );
    my $digest = uc( $opts->{digest} // $self->{digest} );

    $self->_maybe_fetch_keys( $recipients ) || return( $self->pass_error );

    my $plaintext = $self->_serialise_for_gpg( $entity ) || return( $self->pass_error );

    my $passphrase = $self->_resolve_passphrase( $opts );
    return( $self->pass_error ) if( $self->error );

    my @args = (
        $self->_base_gpg_args,
        '--sign',
        '--encrypt',
        '--armor',
        '--digest-algo', $digest,
        '--local-user',  $key_id,
    );
    push( @args, '--recipient', $_ ) for( @{ $recipients } );
    if( defined( $passphrase ) )
    {
        push( @args, '--passphrase-fd', '0', '--pinentry-mode', 'loopback' );
    }

    my $ciphertext = $self->_run_gpg( \@args, \$plaintext, passphrase => $passphrase ) || return( $self->pass_error );

    return( $self->_build_encrypted_mail( $entity, \$ciphertext ) );
}

# _base_gpg_args() → list
# Returns args common to every gpg invocation.
sub _base_gpg_args
{
    my $self = shift( @_ );
    my $bin  = $self->_find_gpg_bin || return( $self->pass_error );
    return(
        $bin,
        '--batch',
        '--no-tty',
        '--status-fd', '2',
    );
}

# _build_encrypted_mail( $original_mail, \$ciphertext ) → Mail::Make object
# Constructs a new Mail::Make object whose body is a RFC 3156 §4
# multipart/encrypted structure.
#
# Structure:
#   multipart/encrypted; protocol="application/pgp-encrypted"
#   ├── application/pgp-encrypted   ("Version: 1")
#   └── application/octet-stream    (ASCII-armoured ciphertext)
sub _build_encrypted_mail
{
    my( $self, $original, $ciphertext_ref ) = @_;
    require Mail::Make;
    require Mail::Make::Entity;

    my $boundary = _random_boundary();

    # Build the two MIME parts
    my $ver_part = Mail::Make::Entity->build(
        type     => 'application/pgp-encrypted',
        encoding => '7bit',
        data     => "Version: 1\r\n",
    ) || return( $self->pass_error( Mail::Make::Entity->error ) );
    $ver_part->headers->set( 'Content-Disposition' => 'inline' );

    my $ct_part = Mail::Make::Entity->build(
        type     => 'application/octet-stream',
        encoding => '7bit',
        data     => ${ $ciphertext_ref },
    ) || return( $self->pass_error( Mail::Make::Entity->error ) );
    $ct_part->headers->set( 'Content-Disposition' => 'inline; filename="encrypted.asc"' );

    # Assemble the multipart/encrypted container
    my $top = Mail::Make::Entity->build(
        type => sprintf(
            'multipart/encrypted; protocol="application/pgp-encrypted"; boundary="%s"',
            $boundary
        ),
    ) || return( $self->pass_error( Mail::Make::Entity->error ) );
    $top->add_part( $ver_part );
    $top->add_part( $ct_part );

    return( $self->_wrap_in_mail( $original, $top ) );
}

# _build_signed_mail( $original_mail, \$signature, digest => $algo ) → Mail::Make object
# Constructs a new Mail::Make object whose body is a RFC 3156 §5
# multipart/signed structure.
#
# Structure:
#   multipart/signed; protocol="application/pgp-signature"; micalg="pgp-sha256"
#   ├── <original MIME body - the part that was signed>
#   └── application/pgp-signature   (ASCII-armoured detached signature)
sub _build_signed_mail
{
    my $self          = shift( @_ );
    my $original      = shift( @_ );
    my $signature_ref = shift( @_ );
    my $canonical     = shift( @_ );
    my $opts          = $self->_get_args_as_hash( @_ );
    my $digest = lc( $opts->{digest} // $self->{digest} );
    require Mail::Make;
    require Mail::Make::Entity;

    my $boundary = _random_boundary();

    # Part 1: a fresh entity whose content is exactly $canonical (the MIME-only bytes
    # that gpg signed). Built via _entity_from_canonical() which parses the Content-* headers
    # from $canonical and wraps the body in a Body::InCore.
    # We never call as_entity() on $original here: for simple text/plain messages 
    # as_entity() would re-add RFC 2822 headers onto $self->{_parts}[0], corrupting the 
    # MIME-only Part 1.
    my $body_entity = $self->_entity_from_canonical( $canonical ) || return( $self->pass_error );

    # Part 2: the detached signature
    my $sig_part = Mail::Make::Entity->build(
        type     => 'application/pgp-signature',
        encoding => '7bit',
        data     => ${ $signature_ref },
    ) || return( $self->pass_error( Mail::Make::Entity->error ) );
    $sig_part->headers->set( 'Content-Disposition' => 'inline; filename="signature.asc"' );

    # Multipart/signed container
    my $top = Mail::Make::Entity->build(
        type => sprintf(
            'multipart/signed; protocol="application/pgp-signature"; micalg="pgp-%s"; boundary="%s"',
            $digest, $boundary
        ),
    ) || return( $self->pass_error( Mail::Make::Entity->error ) );
    $top->add_part( $body_entity );
    $top->add_part( $sig_part );

    return( $self->_wrap_in_mail( $original, $top ) );
}

# _ensure_envelope_headers( $mail_make_obj )
# Generates Date and Message-ID on $mail directly into its _headers object WITHOUT calling 
# as_entity(). Called by sign() and sign_encrypt() before _serialise_for_gpg() so that 
# those values exist when _wrap_in_mail() later copies _headers onto the outer multipart wrapper.
sub _ensure_envelope_headers
{
    my $self = shift( @_ );
    my $mail = shift( @_ ) ||
        return( $self->error( "No Make::Mail instance was provided." ) );
    if( !$self->_is_a( $mail => 'Mail::Make' ) )
    {
        return( $self->error( "Value provided is not a Mail::Make instance." ) );
    }
    elsif( !$self->_is_a( $mail->{_headers} => 'Mail::Make::Headers' ) )
    {
        return( $self->error( "No Mail::Make::Headers instance could be found on Mail::Make object!" ) );
    }

    # Date
    unless( $mail->{_headers}->exists( 'Date' ) )
    {
        $mail->{_headers}->init_header( Date => $mail->_format_date ) ||
            return( $self->pass_error( $mail->{_headers}->error ) );
    }

    # Message-ID
    unless( $mail->{_headers}->exists( 'Message-ID' ) )
    {
        $mail->{_headers}->message_id(
            { generate => 1, domain => $mail->_default_domain }
        ) || return( $self->pass_error( $mail->{_headers}->error ) );
    }

    return(1);
}

# _entity_from_canonical( $canonical ) → Mail::Make::Entity
# Builds a fresh Mail::Make::Entity whose headers and body match $canonical exactly (the
# MIME-only string returned by _serialise_for_gpg). Used as Part 1 of the multipart/signed
# wrapper so that what Thunderbird verifies is byte-for-byte identical to what gpg signed.
sub _entity_from_canonical
{
    my( $self, $canonical ) = @_;
    require Mail::Make::Entity;
    require Mail::Make::Headers;
    require Mail::Make::Body::InCore;

    # Split on the first CRLF+CRLF blank-line separator.
    my $pos = index( $canonical, "\015\012\015\012" );
    if( $pos < 0 )
    {
        return( $self->error( '_entity_from_canonical(): no header/body separator.' ) );
    }

    my $hdr_block = substr( $canonical, 0, $pos );
    my $body      = substr( $canonical, $pos + 4 ); # skip CRLFCRLF

    # Build a fresh entity with a fresh Headers object.
    my $entity  = Mail::Make::Entity->new  || return( $self->pass_error( Mail::Make::Entity->error ) );
    my $headers = Mail::Make::Headers->new || return( $self->pass_error( Mail::Make::Headers->error ) );
    $entity->headers( $headers );

    # Parse MIME header lines from $hdr_block.
    # Continuation lines (starting with whitespace) are folded onto the preceding field value.
    my $cur_name  = '';
    my $cur_value = '';
    for my $line ( split( /\015\012/, $hdr_block ) )
    {
        if( $line =~ /^[ \t]/ )
        {
            # Continuation: append stripped content to current value.
            ( my $cont = $line ) =~ s/^[ \t]+//;
            $cur_value .= ' ' . $cont;
        }
        elsif( $line =~ /^([\x21-\x39\x3B-\x7E]+):\s*(.*?)\s*$/ )
        {
            # New field: flush the previous one first.
            if( CORE::length( $cur_name ) )
            {
                $headers->push_header( $cur_name => $cur_value ) ||
                    return( $self->pass_error( $headers->error ) );
            }
            ( $cur_name, $cur_value ) = ( $1, $2 );
        }
    }
    # Flush the last header.
    if( CORE::length( $cur_name ) )
    {
        $headers->push_header( $cur_name => $cur_value ) ||
            return( $self->pass_error( $headers->error ) );
    }

    # Attach the body verbatim; mark is_encoded so print_body skips re-encoding (the body
    # in $canonical is already encoded).
    my $body_obj = Mail::Make::Body::InCore->new( $body ) ||
        return( $self->pass_error( Mail::Make::Body::InCore->error ) );
    $entity->body( $body_obj );
    $entity->{is_encoded} = 1;

    # Cache effective_type so is_multipart() and similar checks work.
    my $ct = $headers->get( 'Content-Type' ) // '';
    ( my $type = $ct ) =~ s/;.*//s;
    $type =~ s/\s+$//;
    $entity->effective_type( $type );

    return( $entity );
}

# _find_gpg_bin() → $path
# Locates the gpg binary: explicit gpg_bin attribute wins; otherwise we search for gpg2
# then gpg in PATH via File::Which.
sub _find_gpg_bin
{
    my $self = shift( @_ );
    if( defined( $self->{gpg_bin} ) && length( $self->{gpg_bin} ) )
    {
        return( $self->{gpg_bin} );
    }

    $self->_load_class( 'File::Which' ) ||
        return( $self->error( 'File::Which is required to locate gpg. Install it with: cpan File::Which' ) );

    for my $candidate ( qw( gpg2 gpg ) )
    {
        my $path = File::Which::which( $candidate );
        if( defined( $path ) && length( $path ) )
        {
            $self->{gpg_bin} = $path;
            return( $path );
        }
    }
    return( $self->error( 'gpg binary not found in PATH. Install GnuPG or set the GpgBin option.' ) );
}

# _maybe_fetch_keys( \@recipients )
# When auto_fetch is enabled and a keyserver is configured, attempts to retrieve missing 
# public keys for each recipient. Failures are silently ignored - the key may already be 
# in the local keyring.
sub _maybe_fetch_keys
{
    my( $self, $recipients ) = @_;
    return(1) unless( $self->{auto_fetch} && defined( $self->{keyserver} ) && length( $self->{keyserver} ) );

    $self->_load_class( 'IPC::Run' ) ||
        return( $self->error( 'IPC::Run is required for GPG operations. Install it with: cpan IPC::Run' ) );

    my $bin = $self->_find_gpg_bin || return( $self->pass_error );
    local $@;
    foreach my $r ( @$recipients )
    {
        my( $out, $err ) = ( '', '' );
        eval
        {
            IPC::Run::run(
                [ $bin, '--batch', '--no-tty',
                  '--keyserver', $self->{keyserver},
                  '--locate-keys', $r,
                ],
                \undef, \$out, \$err,
            );
        };
        # Best-effort: do not propagate errors from key fetch
    }
    return(1);
}

# _random_boundary() → $string
# Generates a random MIME boundary string.
sub _random_boundary
{
    return( sprintf( '----=_NextPart_GPG_%08X%08X', int( rand(0xFFFFFFFF) ), int( rand(0xFFFFFFFF) ) ) );
}

# _resolve_key_id( \%opts ) → $string
sub _resolve_key_id
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $kid = $opts->{key_id} // $self->{key_id} // '';
    return( $kid );
}

# _resolve_passphrase( \%opts ) → $string | undef
# Resolves the passphrase from per-call option or instance default.
# CODE refs are called once here with no arguments.
# Returns undef when no passphrase is configured (gpg-agent will be used).
sub _resolve_passphrase
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $pp = $opts->{passphrase} // $self->{passphrase};
    return unless( defined( $pp ) );
    if( ref( $pp ) eq 'CODE' )
    {
        local $@;
        $pp = eval{ $pp->() };
        if( $@ )
        {
            return( $self->error( "gpg_sign/encrypt: passphrase callback failed: $@" ) );
        }
    }
    return( $pp );
}

# _run_gpg( \@args, \$input, passphrase => $pp ) → $stdout_string | undef
#
# Executes gpg via IPC::Run. IPC::Run handles multiplexed I/O internally,
# avoiding the select()-loop complexity of a raw fork/pipe approach.
#
# Passphrase handling (--passphrase-fd 0 + --pinentry-mode loopback):
# We prepend the passphrase (followed by a newline) to the stdin payload.
# gpg reads exactly one line from fd 0 as the passphrase, then continues reading the same
# fd for the message data. This avoids opening a second file descriptor and is the standard 
# approach for batch use of GnuPG 2.1+.
sub _run_gpg
{
    my $self      = shift( @_ );
    my $args      = shift( @_ );
    my $input_ref = shift( @_ );
    my $opts      = $self->_get_args_as_hash( @_ );
    my $passphrase = $opts->{passphrase};

    $self->_load_class( 'IPC::Run' ) ||
        return( $self->error( 'IPC::Run is required for GPG operations. Install it with: cpan IPC::Run' ) );

    # Build the complete stdin blob
    my $stdin = '';
    $stdin .= $passphrase . "\n" if( defined( $passphrase ) );
    $stdin .= ( ref( $input_ref ) ? ${ $input_ref } : $input_ref );

    my( $stdout, $stderr ) = ( '', '' );

    local $@;
    local $SIG{PIPE} = 'IGNORE';
    my $ok = eval
    {
        IPC::Run::run( $args, \$stdin, \$stdout, \$stderr );
    };
    if( $@ )
    {
        return( $self->error( "gpg execution error: $@" ) );
    }
    unless( $ok )
    {
        # Extract the most informative line from gpg's stderr output
        my @lines  = split( /\n/, $stderr );
        my ($msg)  = grep { /\bERROR\b|\berror\b|failed|No secret key|No public key|bad passphrase/i } @lines;
        $msg     //= $lines[-1] // $stderr;
        $msg       =~ s/^\s+|\s+$//g;
        return( $self->error( "gpg failed: $msg" ) );
    }

    return( $stdout );
}

# _serialise_for_gpg( $mail_make_obj ) → $string
# Returns the MIME body of the Mail::Make object with CRLF line endings, suitable for 
# feeding to gpg (signing) or for encrypting.
#
# For multipart/signed (RFC 3156 §5.1) the data fed to gpg must be identical to Part 1 as
# it will appear on the wire, i.e. with CRLF.
sub _serialise_for_gpg
{
    my( $self, $mail ) = @_;
    unless( defined( $mail ) )
    {
        return( $self->error( '_serialise_for_gpg(): no Mail::Make object supplied.' ) );
    }

    unless( $mail->can( 'as_entity' ) )
    {
        return( $self->error( '_serialise_for_gpg(): argument must be a Mail::Make object.' ) );
    }

    # RFC 3156 §5.1: Part 1 of multipart/signed must carry only MIME
    # Content-* headers; RFC 2822 envelope fields belong on the outer wrapper.
    #
    # Root-cause: Mail::Make::as_entity() reuses $self->{_parts}[0] as $top_entity for 
    # simple text/plain messages and merges RFC 2822 headers directly onto it. Any call to
    # as_entity() re-adds those headers to the same object. We therefore serialise to a 
    # string and filter the RFC 2822 header lines at string level, never mutating the entity.
    my $entity = $mail->as_entity || return( $self->pass_error( $mail->error ) );

    my $full = $entity->as_string || return( $self->pass_error( $entity->error ) );

    # Canonicalise line endings to CRLF FIRST (RFC 3156 §5.1).
    # Doing this before the separator search ensures we always find \015\012\015\012
    # regardless of whether Entity::as_string used LF or CRLF.
    $full =~ s/\015?\012/\015\012/g;

    # Locate the header / body separator (first blank line).
    # After canonicalisation this is always \r\n\r\n.
    my $pos = index( $full, "\015\012\015\012" );
    if( $pos < 0 )
    {
        return( $self->error( '_serialise_for_gpg(): no header/body separator found.' ) );
    }

    # Include the \r\n that terminates the last header in hdr_block,
    # so that every kept line already carries its own EOL.
    my $hdr_block  = substr( $full, 0, $pos + 2 );   # up to and including last header \r\n
    my $body_block = substr( $full, $pos + 4 );      # skip \r\n\r\n

    # Walk header lines and keep only Content-* headers.
    # RFC 3156 §5.1: Part 1 carries Content-* headers only.
    # MIME-Version belongs on the outer wrapper, not inside Part 1.
    # Continuation lines (starting with whitespace) follow their field.
    my $mime_hdr = '';
    my $keep     = 0;
    for my $line ( split( /(?<=\015\012)/, $hdr_block ) )
    {
        if( $line =~ /^[ \t]/ )
        {
            $mime_hdr .= $line if( $keep );
        }
        else
        {
            $keep      = ( $line =~ /^Content-/i ) ? 1 : 0;
            $mime_hdr .= $line if( $keep );
        }
    }

    # Reassemble: kept MIME headers (each already ends with \r\n)
    # + one \r\n blank line + body.
    my $raw = $mime_hdr . "\015\012" . $body_block;

    # RFC 2046 §5.1.1: the \r\n immediately before a boundary delimiter belongs to the
    # boundary, not to the body. Strip exactly one trailing \r\n.
    $raw =~ s/\015\012$//;

    return( $raw );
}

# _wrap_in_mail( $original_mail, $top_entity ) → Mail::Make object
# Creates a new Mail::Make object that carries $top_entity as its pre-built entity, 
# copying envelope headers (From, To, Cc, Subject, etc.) from $original_mail.
sub _wrap_in_mail
{
    my( $self, $original, $top_entity ) = @_;
    require Mail::Make;

    # Ok, the check for error here is really semantic, because there is virtually zero chance of that happening.
    my $new = Mail::Make->new || return( $self->pass_error( Mail::Make->error ) );

    # Date and Message-ID were generated by _ensure_envelope_headers() in 
    # sign() / sign_encrypt() before _serialise_for_gpg() was called, so
    # $original->headers already has them. Do NOT call as_entity() here:
    # for simple text/plain messages as_entity() reuses $self->{_parts}[0] as $top_entity
    # and would merge RFC 2822 headers back onto it, which would corrupt Part 1 of the 
    # multipart/signed structure.

    # Merge envelope headers into BOTH the new Mail::Make object AND directly into 
    # $top_entity's headers. The hook in as_entity() returns _gpg_entity verbatim, so the 
    # standard header-merge logic never runs.
    # We must therefore inject the RFC 2822 headers here.
    my $ent_headers = $top_entity->headers;
    $ent_headers->init_header( 'MIME-Version' => '1.0' );

    $original->headers->scan(sub
    {
        my( $name, $value ) = @_;
        # Inject into top entity so the wire message carries all headers
        $ent_headers->init_header( $name => $value );
        # Also keep in the new Mail::Make object for introspection
        $new->headers->set( $name => $value );
        return(1);
    });

    # Store the pre-assembled top entity so as_entity() returns it directly.
    $new->{_gpg_entity} = $top_entity;

    return( $new );
}

# NOTE: STORABLE support
sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw   { CORE::return( CORE::shift->THAW( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::GPG - OpenPGP signing and encryption for Mail::Make

=head1 SYNOPSIS

    use Mail::Make;

    my $mail = Mail::Make->new
        ->from(    'jack@deguest.jp' )
        ->to(      'alice@example.com' )
        ->subject( 'Signed message' )
        ->plain(   "Hello Alice.\n" );

    # Sign only - multipart/signed (RFC 3156 §5)
    $mail->gpg_sign(
        KeyId      => '35ADBC3AF8355E845139D8965F3C0261CDB2E752',
        Passphrase => 'my-passphrase',   # or: sub { MyKeyring::get('gpg') }
    )->smtpsend( %smtp_opts );

    # Encrypt only - multipart/encrypted (RFC 3156 §4)
    $mail->gpg_encrypt(
        Recipients => [ 'alice@example.com' ],
    )->smtpsend( %smtp_opts );

    # Sign then encrypt
    $mail->gpg_sign_encrypt(
        KeyId      => '35ADBC3AF8355E845139D8965F3C0261CDB2E752',
        Passphrase => sub { MyKeyring::get_passphrase() },
        Recipients => [ 'alice@example.com', 'bob@example.com' ],
    )->smtpsend( %smtp_opts );

    # Auto-fetch recipient keys from a keyserver
    $mail->gpg_encrypt(
        Recipients  => [ 'alice@example.com' ],
        KeyServer   => 'keys.openpgp.org',
        AutoFetch   => 1,
    )->smtpsend( %smtp_opts );

=head1 VERSION

    v0.1.4

=head1 DESCRIPTION

C<Mail::Make::GPG> adds OpenPGP support to L<Mail::Make> via direct calls to the C<gpg> binary using L<IPC::Run>. It produces RFC 3156-compliant C<multipart/signed> and C<multipart/encrypted> MIME structures.

This approach supports all key types that your installed GnuPG supports (RSA, DSA, Ed25519, ECDSA, etc.) and integrates naturally with C<gpg-agent> for transparent passphrase caching.

This module is not normally used directly. The C<gpg_sign()>, C<gpg_encrypt()>, and C<gpg_sign_encrypt()> methods are added to L<Mail::Make> itself as fluent methods that load and delegate to this module.

=head1 OPTIONS

All options may be passed to the C<gpg_sign()>, C<gpg_encrypt()>, and C<gpg_sign_encrypt()> methods on L<Mail::Make> directly; they are forwarded to this module.

=over 4

=item C<KeyId>

Signing key fingerprint or ID (required for signing operations).
Example: C<35ADBC3AF8355E845139D8965F3C0261CDB2E752>.

=item C<Passphrase>

Passphrase to unlock the secret key. May be a plain string or a C<CODE> reference called with no arguments at operation time. If omitted, GnuPG's agent handles passphrase prompting.

=item C<Recipients>

Array reference of recipient addresses or key IDs (required for encryption).

=item C<Digest>

Hash algorithm for signing. Defaults to C<SHA256>.
Valid values: C<SHA256>, C<SHA384>, C<SHA512>, C<SHA1>.

=item C<GpgBin>

Full path to the C<gpg> executable. If omitted, C<gpg2> and then C<gpg> are searched in C<PATH>.

=item C<KeyServer>

Keyserver URL for auto-fetching recipient public keys.
Only consulted when C<AutoFetch> is true.
Example: C<'keys.openpgp.org'>.

=item C<AutoFetch>

Boolean. When true and C<KeyServer> is set, C<gpg --locate-keys> is called for each recipient address before encryption. Defaults to C<0> (disabled).

=back

=head1 METHODS

=head2 auto_fetch( [$bool] )

Gets or sets the auto-fetch flag. When true and C<keyserver()> is set, C<gpg --locate-keys> is called for each recipient before encryption.

Default: C<0>.

=head2 digest( [$algorithm] )

Gets or sets the hash algorithm used for signing. The value is uppercased automatically.

Default: C<SHA256>.

Valid values: C<SHA256>, C<SHA384>, C<SHA512>, C<SHA1>.

=head2 encrypt( entity => $mail [, %opts] )

Encrypts C<$mail> for one or more recipients and returns a new L<Mail::Make> object whose top-level MIME type is C<multipart/encrypted> (RFC 3156 §4).

The caller is responsible for supplying recipient public keys in the GnuPG keyring. When C<auto_fetch()> and C<keyserver()> are set, key retrieval via C<gpg --locate-keys> is attempted before encryption.

Required options:

=over 4

=item entity => $mail_make_obj

The L<Mail::Make> object to encrypt.

=item recipients => \@addrs_or_key_ids

Array reference of recipient e-mail addresses or key fingerprints.

=back

Optional options mirror the accessor names: C<digest>, C<gpg_bin>, C<key_id>, C<keyserver>, C<passphrase>.

=head2 gpg_bin( [$path] )

Gets or sets the full path to the C<gpg> executable. When not set, C<gpg2> and then C<gpg> are searched in C<PATH>.

=head2 key_id( [$fingerprint] )

Gets or sets the default signing key fingerprint or ID.

=head2 keyserver( [$url] )

Gets or sets the keyserver URL used for auto-fetching recipient public keys.

Example: C<'keys.openpgp.org'>.

=head2 passphrase( [$string_or_coderef] )

Gets or sets the passphrase for the secret key. May be a plain string or a C<CODE> reference called with no arguments at operation time. When C<undef>, GnuPG's agent is expected to handle passphrase prompting.

=head2 sign( entity => $mail [, %opts] )

Signs C<$mail> and returns a new L<Mail::Make> object whose top-level MIME type is C<multipart/signed> (RFC 3156 §5). The signature is always detached and ASCII-armoured.

Required options:

=over 4

=item entity => $mail_make_obj

The L<Mail::Make> object to sign.

=item key_id => $fingerprint_or_id

Signing key fingerprint or short ID.

=back

Optional options: C<digest>, C<gpg_bin>, C<passphrase>.

=head2 sign_encrypt( entity => $mail, recipients => \@addrs [, %opts] )

Signs then encrypts C<$mail>. Returns a new L<Mail::Make> object whose top-level MIME type is C<multipart/encrypted> containing a signed and encrypted OpenPGP payload.

Accepts all options from both L</sign> and L</encrypt>.

=head1 DEPENDENCIES

=over 4

=item L<IPC::Run>

Loaded on demand. Required for all GPG operations.

=item L<File::Which>

Loaded on demand. Used to locate the C<gpg> binary in C<PATH>.

=item GnuPG 2.x

Must be installed and accessible as C<gpg2> or C<gpg> in C<PATH>, or explicitly set via the C<GpgBin> option.

=back

=head1 STANDARDS

=over 4

=item RFC 3156 - MIME Security with OpenPGP

=item RFC 4880 - OpenPGP Message Format

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make>, L<IPC::Run>, L<File::Which>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
