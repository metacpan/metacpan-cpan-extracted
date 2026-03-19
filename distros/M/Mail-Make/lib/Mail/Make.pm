##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make.pm
## Version v0.22.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/02
## Modified 2026/03/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS $CRLF $MAX_BODY_IN_MEMORY_SIZE );
    use Mail::Make::Entity;
    use Mail::Make::Exception;
    use Mail::Make::Headers;
    use Mail::Make::Headers::Subject;
    use Scalar::Util ();
    our $CRLF                    = "\015\012";
    our $MAX_BODY_IN_MEMORY_SIZE = 1_048_576;  # 1 MiB default
    our $EXCEPTION_CLASS         = 'Mail::Make::Exception';
    our $VERSION                 = 'v0.22.0';
}

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    # Top-level envelope headers live in a Mail::Make::Headers instance.
    # All RFC 2822 envelope fields (From, To, Cc, Bcc, Subject, Date, Message-ID,
    # In-Reply-To, References, Reply-To, Sender) are stored there directly, avoiding any
    # duplication between Mail::Make and the final Mail::Make::Entity's headers object.
    $self->{_headers}                = Mail::Make::Headers->new;
    # Accumulated body parts (Mail::Make::Entity objects, in order of addition)
    $self->{_parts}                  = [];
    # When the serialised message exceeds this byte threshold (or when use_temp_file is true),
    # as_string_ref() spools to a temporary file rather than keeping the entire message in RAM.
    # Set to 0 or undef to disable file spooling entirely.
    $self->{max_body_in_memory_size} = $MAX_BODY_IN_MEMORY_SIZE;
    $self->{use_temp_file}           = 0;
    $self->{_exception_class}        = $EXCEPTION_CLASS;
    $self->{_init_strict_use_sub}    = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# as_entity()
# Returns the fully assembled top-level Mail::Make::Entity object.
# The MIME structure is chosen based on the accumulated parts:
#
#   Only plain text             -> text/plain
#   Only HTML                   -> text/html
#   Plain + HTML                -> multipart/alternative
#   Any of the above + inlines  -> multipart/related
#   Any of the above + attachments -> multipart/mixed
sub as_entity
{
    my $self = shift( @_ );

    # When gpg_sign() / gpg_encrypt() / gpg_sign_encrypt() have already assembled the
    # top-level entity (stored in _gpg_entity), return it directly. Envelope headers have
    # already been merged by _wrap_in_mail().
    return( $self->{_gpg_entity} ) if( defined( $self->{_gpg_entity} ) );

    # S/MIME: entity pre-assembled by Mail::Make::SMIME::_build_from_smime_output().
    # Headers are already embedded in the parsed entity; return it directly.
    return( $self->{_smime_entity} ) if( defined( $self->{_smime_entity} ) );

    # Partition accumulated parts by role
    my( @plain, @html, @inline, @attachment );
    for my $part ( @{$self->{_parts}} )
    {
        my $type = lc( $part->effective_type // '' );
        # Use get() for the raw string value; content_disposition() returns a typed
        # object which stringifies to '' when uninitialised, making // unreliable.
        my $cd   = lc( $part->headers->get( 'Content-Disposition' ) // '' );
        if( $type eq 'text/plain' && $cd !~ /attachment/ )
        {
            push( @plain, $part );
        }
        elsif( $type eq 'text/html' && $cd !~ /attachment/ )
        {
            push( @html, $part );
        }
        elsif( $cd =~ /inline/ && $part->headers->get( 'Content-ID' ) )
        {
            push( @inline, $part );
        }
        else
        {
            push( @attachment, $part );
        }
    }

    # NOTE: Step 1: build the text body (plain, html, or alternative)
    my $body_entity;
    if( @plain && @html )
    {
        $body_entity = Mail::Make::Entity->build( type => 'multipart/alternative' ) ||
            return( $self->pass_error( Mail::Make::Entity->error ) );
        $body_entity->add_part( $_ ) for( @plain );
        $body_entity->add_part( $_ ) for( @html );
    }
    elsif( @html )
    {
        $body_entity = $html[0];
    }
    elsif( @plain )
    {
        $body_entity = $plain[0];
    }
    else
    {
        return( $self->error( "No body parts have been added." ) );
    }

    # NOTE: Step 2: wrap in multipart/related if there are inline parts
    my $related_entity = $body_entity;
    if( @inline )
    {
        $related_entity = Mail::Make::Entity->build( type => 'multipart/related' ) ||
            return( $self->pass_error( Mail::Make::Entity->error ) );
        $related_entity->add_part( $body_entity );
        $related_entity->add_part( $_ ) for( @inline );
    }

    # NOTE: Step 3: wrap in multipart/mixed if there are attachments
    my $top_entity = $related_entity;
    if( @attachment )
    {
        $top_entity = Mail::Make::Entity->build( type => 'multipart/mixed' ) ||
            return( $self->pass_error( Mail::Make::Entity->error ) );
        $top_entity->add_part( $related_entity );
        $top_entity->add_part( $_ ) for( @attachment );
    }

    # NOTE: Step 4: transfer envelope headers to the top-level entity
    # We merge our own _headers into the entity's headers object so that MIME-specific
    # headers already set on the entity (Content-Type, CTE, etc.) take precedence, while
    # envelope headers come from _headers.
    # Any header already present in the entity headers is left untouched.
    my $ent_headers = $top_entity->headers;

    # Auto-generate Date if not set
    $self->{_headers}->init_header(
        'Date' => $self->_format_date()
    );

    # Auto-generate Message-ID if not set
    unless( $self->{_headers}->exists( 'Message-ID' ) )
    {
        $self->{_headers}->message_id( { generate => 1, domain => $self->_default_domain } ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
    }

    # MIME-Version is always added to the entity's own headers (not the envelope), since
    # it belongs at the top of the MIME structure.
    $ent_headers->init_header( 'MIME-Version' => '1.0' );

    # Merge envelope headers into the entity: each field from _headers that is not already
    # present in ent_headers is copied over.
    $self->{_headers}->scan( sub
    {
        my( $name, $value ) = @_;
        $ent_headers->init_header( $name => $value );
        return(1);
    });

    return( $top_entity );
}

# as_string()
# Assembles the message and returns it as a plain string, consistent with
# MIME::Entity::stringify. Use print($fh) to avoid loading the whole message into memory,
# or as_string_ref() to avoid a string copy.
sub as_string
{
    my $self   = shift( @_ );
    my $entity = $self->as_entity || return( $self->pass_error );
    return( $entity->as_string( @_ ) );
}

# as_string_ref()
# Returns the assembled message as a scalar reference (no string copy).
# When use_temp_file is true, or the serialised entity size exceeds max_body_in_memory_size,
# the message is written to a Module::Generic::Scalar buffer, thus keeping peak RAM use
# to a single copy rather than two overlapping buffers (the serialisation buffer plus the
# returned string).
sub as_string_ref
{
    my $self   = shift( @_ );
    my $entity = $self->as_entity || return( $self->pass_error );
    my $threshold  = $self->{max_body_in_memory_size};
    my $force_file = $self->{use_temp_file};

    # Fast path: build directly in memory when neither condition applies
    unless( $force_file || ( defined( $threshold ) && $threshold > 0 && $entity->length > $threshold ) )
    {
        return( $entity->as_string_ref );
    }

    # new_scalar() is inherited from Module::Generic, and returns a Module::Generic::Scalar object
    my $buf = $self->new_scalar;
    # In-memory fielhandle; returns a Module::Generic::Scalar::IO object
    my $fh  = $buf->open( '>', { binmode => ':raw', autoflush => 1 } ) || return( $buf->error );
    $entity->print( $fh ) || return( $self->pass_error( $entity->error ) );
    # The scalar object stringifies as necessary.
    return( $buf );
}

# attach( %opts )
# Adds a standard (downloadable) attachment.
# Recognised keys: path, data, type, filename, charset, encoding, description
sub attach
{
    my $self = shift( @_ );
    # Detect positional shorthand: attach( '/path/to/file.pdf' ) or
    # attach( '/path/to/file.pdf', encoding => 'base64', ... )
    # Triggered when argument count is odd and the first argument is a plain scalar
    # (not a reference), contains no newline, and resolves to an existing file.
    if( ( scalar( @_ ) % 2 ) &&
        ( !ref( $_[0] ) || $self->_can_overload( $_[0] => '""' ) ) &&
        index( "$_[0]", "\n" ) == -1 )
    {
        # shift() first to avoid $_[0] being altered by new_file() resolution
        my $f = $self->new_file( shift( @_ ) ); # Module::Generic::File will trigger stringification
        if( $f->exists )
        {
            # then, we pass it back here:
            unshift( @_, path => $f );
        }
    }
    my $opts = $self->_get_args_as_hash( @_ );
    unless( defined( $opts->{data} ) || defined( $opts->{path} ) )
    {
        return( $self->error( "attach(): 'data' or 'path' is required." ) );
    }
    $opts->{disposition} //= 'attachment';
    my $entity = Mail::Make::Entity->build( %$opts ) ||
        return( $self->pass_error( Mail::Make::Entity->error ) );
    push( @{$self->{_parts}}, $entity );
    return( $self );
}

# attach_inline( %opts )
# Adds an inline part (e.g. an image referenced via cid: in HTML).
# 'id' or 'cid' is required.
sub attach_inline
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    unless( defined( $opts->{data} ) || defined( $opts->{path} ) )
    {
        return( $self->error( "attach_inline(): 'data' or 'path' is required." ) );
    }
    unless( defined( $opts->{id} ) || defined( $opts->{cid} ) )
    {
        return( $self->error( "attach_inline(): 'id' or 'cid' is required for inline parts." ) );
    }
    # Normalise: Entity->build() expects 'cid'
    $opts->{cid} //= delete( $opts->{id} );
    $opts->{disposition} //= 'inline';
    my $entity = Mail::Make::Entity->build( %$opts ) ||
        return( $self->pass_error( Mail::Make::Entity->error ) );
    push( @{$self->{_parts}}, $entity );
    return( $self );
}

# bcc( @addresses )
# Accumulates BCC recipients (may be called multiple times).
sub bcc
{
    my $self = shift( @_ );
    if( @_ )
    {
        my @encoded = map { $self->_encode_address( $_ ) } ( ref( $_[0] ) eq 'ARRAY' ? @{$_[0]} : @_ );
        $self->{_headers}->push_header( 'Bcc' => join( ', ', @encoded ) ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->header( 'Bcc' ) );
}

# build( %params ) - alternate hash-based constructor/factory
# Returns a Mail::Make object with all parameters applied.
sub build
{
    my $class  = shift( @_ );
    my $params = $class->_get_args_as_hash( @_ );
    my $self   = $class->new || return( $class->pass_error );

    # Scalar envelope fields
    foreach my $field ( qw( date from in_reply_to message_id reply_to return_path sender subject ) )
    {
        $self->$field( $params->{ $field } ) || return( $self->pass_error )
            if( exists( $params->{ $field } ) );
    }
    # List fields
    foreach my $field ( qw( bcc cc references to ) )
    {
        if( exists( $params->{ $field } ) )
        {
            my $v = $params->{ $field };
            $self->$field( ref( $v ) eq 'ARRAY' ? @$v : $v ) || return( $self->pass_error );
        }
    }
    # Body convenience shorthands
    if( exists( $params->{plain} ) )
    {
        if( exists( $params->{plain_opts} ) && ref( $params->{plain_opts} ) ne 'HASH' )
        {
            return( $self->error( "The parameter 'plain_opts' must be a hash reference. You provided '", $self->_str_val( $params->{plain_opts} // 'undef' ), "'." ) );
        }
        my %opts = %{$params->{plain_opts} // {}};
        $self->plain( $params->{plain}, %opts ) || return( $self->pass_error );
    }
    if( exists( $params->{html} ) )
    {
        if( exists( $params->{html_opts} ) && ref( $params->{html_opts} ) ne 'HASH' )
        {
            return( $self->error( "The parameter 'html_opts' must be a hash reference. You provided '", $self->_str_val( $params->{html_opts} // 'undef' ), "'." ) );
        }
        my %opts = %{$params->{html_opts} // {}};
        $self->html( $params->{html}, %opts ) || return( $self->pass_error );
    }
    # Attachments: scalar, arrayref of scalars, or arrayref of hashrefs
    if( exists( $params->{attach} ) && defined( $params->{attach} ) )
    {
        my $attach = $params->{attach};
        # Accepts vanilla array reference or array objects like Module::Generic::Array
        my @items  = $self->_is_array( $attach ) ? @$attach : ( $attach );
        foreach my $item ( @items )
        {
            next unless( defined( $item ) );
            # Such as:
            # { path => '/some/where/file.pdf', filename => '04 report.pdf', type => 'application/pdf' }
            # { data => $attachment_data, filename => '04 report.pdf', type => 'application/pdf' }
            if( ref( $item ) eq 'HASH' )
            {
                $self->attach( %$item ) || return( $self->pass_error );
            }
            else
            {
                # Plain scalar or stringifiable object - delegate to attach() which
                # already handles the positional shorthand
                # So, this can be an attachment data, or a file path, or a file object
                # like Module::Generic::File (as long as it stringifies) and does not
                # contain a "\n"
                $self->attach( $item ) || return( $self->pass_error );
            }
        }
    }
    # Extra arbitrary headers
    if( exists( $params->{headers} ) && ref( $params->{headers} ) eq 'HASH' )
    {
        while( my( $n, $v ) = each( %{$params->{headers}} ) )
        {
            $self->header( $n, $v ) || return( $self->pass_error );
        }
    }
    return( $self );
}

# cc( @addresses )
# Accumulates CC recipients.
sub cc
{
    my $self = shift( @_ );
    if( @_ )
    {
        my @encoded = map { $self->_encode_address( $_ ) } ( ref( $_[0] ) eq 'ARRAY' ? @{$_[0]} : @_ );
        $self->{_headers}->push_header( 'Cc' => join( ', ', @encoded ) ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->header( 'Cc' ) );
}

# date( [$date_string_or_epoch] )
# Delegates to Mail::Make::Headers::date(), which handles epoch integers, string validation,
# and RFC 5322 formatting.
sub date
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{_headers}->date( @_ ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->date );
}

# from( [$address] )
sub from
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $addr = $self->_encode_address( shift( @_ ) );
        $self->{_headers}->set( 'From' => $addr ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->header( 'From' ) );
}

# header( $name, $value )
# Appends an arbitrary extra header to the envelope (push_header semantics: does not
# replace, allows multiple values for the same field).
sub header
{
    my $self = shift( @_ );
    if( @_ == 1 )
    {
        # Getter shortcut
        return( $self->{_headers}->header( $_[0] ) );
    }
    my( $name, $value ) = @_;
    unless( defined( $name ) && length( $name ) && defined( $value ) )
    {
        return( $self->error( "header(): name and value are required." ) );
    }
    $self->{_headers}->push_header( $name => $value ) ||
        return( $self->pass_error( $self->{_headers}->error ) );
    return( $self );
}

# headers()
# Returns the Mail::Make::Headers object that holds the envelope headers.
# Read-only: the object is created in init() and is not replaceable from outside, to
# prevent accidental aliasing.
sub headers { return( $_[0]->{_headers} ); }

# html( $content [, %opts] )
# Adds a text/html body part.
sub html
{
    my $self = shift( @_ );
    my $text = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    unless( defined( $text ) )
    {
        return( $self->error( "html(): text content is required." ) );
    }
    my $part = Mail::Make::Entity->build(
        type     => 'text/html',
        charset  => ( $opts->{charset}  // 'utf-8' ),
        encoding => ( $opts->{encoding} // 'quoted-printable' ),
        data     => $text,
    ) || return( $self->pass_error( Mail::Make::Entity->error ) );
    push( @{$self->{_parts}}, $part );
    return( $self );
}

# in_reply_to( [$mid] )
sub in_reply_to
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{_headers}->set( 'In-Reply-To' => shift( @_ ) ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->header( 'In-Reply-To' ) );
}

# max_body_in_memory_size( [$bytes] )
# Gets or sets the byte threshold above which as_string_ref() spools to a temporary file.
# Set to 0 to disable the threshold (always use memory).
# Default: $Mail::Make::MAX_BODY_IN_MEMORY_SIZE (1 MiB).
sub max_body_in_memory_size { return( shift->_set_get_number( 'max_body_in_memory_size', @_ ) ); }

# message_id( [$mid | \%opts] )
# Delegates fully to Mail::Make::Headers::message_id(), which handles generation,
# validation, and removal.
sub message_id
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{_headers}->message_id( @_ ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->message_id );
}

# plain( $content [, %opts] )
# Adds a text/plain body part.
sub plain
{
    my $self = shift( @_ );
    my $text = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    unless( defined( $text ) )
    {
        return( $self->error( "plain(): text content is required." ) );
    }
    my $part = Mail::Make::Entity->build(
        type     => 'text/plain',
        charset  => ( $opts->{charset}  // 'utf-8' ),
        encoding => ( $opts->{encoding} // 'quoted-printable' ),
        data     => $text,
    ) || return( $self->pass_error( Mail::Make::Entity->error ) );
    push( @{$self->{_parts}}, $part );
    return( $self );
}

# print( $fh )
# Serialises the assembled message to a filehandle.
sub print
{
    my $self = shift( @_ );
    my $fh   = shift( @_ ) ||
        return( $self->error( "No file handle was provided to print the mail entity." ) );
    unless( $self->_is_glob( $fh ) )
    {
        return( $self->error( "Value provided (", $self->_str_val( $fh // 'undef' ), ") is not a file handle." ) );
    }
    my $entity = $self->as_entity || return( $self->pass_error );
    $entity->print( $fh ) || return( $self->pass_error( $entity->error ) );
    return( $self );
}

# references( @mids )
# Accumulates Message-ID references.
sub references
{
    my $self = shift( @_ );
    if( @_ )
    {
        my @mids = ( ref( $_[0] ) eq 'ARRAY' ? @{$_[0]} : @_ );
        # References is a single folded header: accumulate by appending.
        my $existing = $self->{_headers}->header( 'References' ) // '';
        my $new = join( ' ', grep{ length( $_ ) } $existing, @mids );
        $self->{_headers}->set( 'References' => $new ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->header( 'References' ) );
}

# reply_to( [$address] )
sub reply_to
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $addr = $self->_encode_address( shift( @_ ) );
        $self->{_headers}->set( 'Reply-To' => $addr ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->header( 'Reply-To' ) );
}

# return_path( [$address] )
sub return_path
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $addr = $self->_encode_address( shift( @_ ) );
        $self->{_headers}->set( 'Return-Path' => $addr ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->header( 'Return-Path' ) );
}

# sender( [$address] )
sub sender
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $addr = $self->_encode_address( shift( @_ ) );
        $self->{_headers}->set( 'Sender' => $addr ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->header( 'Sender' ) );
}

# smtpsend( %opts )
# Assembles the message and submits it via SMTP using Net::SMTP.
#
# Recognised options:
#   Host      => $hostname_or_Net_SMTP_object
#                Defaults to trying $ENV{SMTPHOSTS} (colon-separated),
#                'mailhost', then 'localhost'.
#   MailFrom  => $envelope_sender  (MAIL FROM)
#                Defaults to the From: header address-spec.
#   To        => \@recipients      Override the To header for RCPT TO.
#   Cc        => \@recipients      Additional CC addresses for RCPT TO.
#   Bcc       => \@recipients      Additional BCC addresses for RCPT TO.
#                Note: Bcc is stripped from the outgoing headers per RFC 2822 §3.6.3.
#   Hello     => $fqdn             EHLO/HELO hostname.
#   Port      => $port             SMTP port (default 25).
#   Debug     => $bool             Enable Net::SMTP debug output.
#
# Returns the list of recipients successfully handed to the MTA on success, or undef and
# sets error() on failure.
sub smtpsend
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );

    $self->_load_class( 'Net::SMTP' ) || return( $self->pass_error );

    # Build the entity first so we can inspect its headers
    my $entity = $self->as_entity || return( $self->pass_error );

    # Determine envelope sender (MAIL FROM)
    my $mail_from = $opts->{MailFrom};
    unless( defined( $mail_from ) && length( $mail_from ) )
    {
        my $from_hdr = $self->{_headers}->header( 'From' ) // '';
        if( $from_hdr =~ /<([^>]+)>/ )
        {
            $mail_from = $1;
        }
        else
        {
            ( $mail_from = $from_hdr ) =~ s/\s+//g;
        }
    }

    unless( defined( $mail_from ) && length( $mail_from ) )
    {
        return( $self->error( "smtpsend(): cannot determine envelope sender (MAIL FROM). Set MailFrom or From header." ) );
    }

    # Validate auth credentials before touching the network
    # Password may be a plain string or a CODE ref (resolved later).
    my $username = $opts->{Username};
    my $password = $opts->{Password};

    if( defined( $username ) && length( $username ) )
    {
        unless( defined( $password ) )
        {
            return( $self->error( "smtpsend(): Username supplied but Password is missing." ) );
        }

        # Authen::SASL and MIME::Base64 are required for SMTP AUTH.
        # Check early so the error is clear rather than a cryptic auth failure.
        foreach my $mod ( qw( MIME::Base64 Authen::SASL ) )
        {
            $self->_load_class( $mod ) ||
                return( $self->error( "smtpsend(): SMTP authentication requires $mod, which is not installed. Install it with: cpan $mod" ) );
        }
    }

    # Determine RCPT TO addresses before connecting, so we can bail early.
    # Honour explicit override lists first; fall back to message headers.
    my @rcpt_raw;
    foreach my $field ( qw( To Cc Bcc ) )
    {
        my $v = $opts->{ $field };
        if( defined( $v ) )
        {
            push( @rcpt_raw, ref( $v ) eq 'ARRAY' ? @$v : $v );
        }
        else
        {
            my $hv = $self->{_headers}->header( $field ) // '';
            push( @rcpt_raw, $hv ) if( length( $hv ) );
        }
    }

    # Parse each raw value into bare addr-specs
    my @addr;
    foreach my $raw ( @rcpt_raw )
    {
        my @found_angle;
        while( $raw =~ /<([^>]+)>/g )
        {
            push( @found_angle, $1 );
        }
        if( @found_angle )
        {
            push( @addr, @found_angle );
        }
        else
        {
            # Bare comma-separated list (no angle brackets)
            push( @addr, grep{ /\@/ } map{ s/^\s+|\s+$//gr } split( /,/, $raw ) );
        }
    }
    # Deduplicate while preserving order
    my %seen;
    @addr = grep{ !$seen{ $_ }++ } @addr;

    unless( @addr )
    {
        return( $self->error( "smtpsend(): no recipients found." ) );
    }

    # Build Net::SMTP connection options
    # SSL => 1  : direct SSL/TLS (e.g. port 465, aka SMTPS)
    my @smtp_opts;
    push( @smtp_opts, Hello   => $opts->{Hello}    ) if( defined( $opts->{Hello}   ) );
    push( @smtp_opts, Port    => $opts->{Port}     ) if( defined( $opts->{Port}    ) );
    push( @smtp_opts, Debug   => $opts->{Debug}    ) if( defined( $opts->{Debug}   ) );
    push( @smtp_opts, Timeout => $opts->{Timeout}  ) if( defined( $opts->{Timeout} ) );
    if( $opts->{SSL} )
    {
        push( @smtp_opts, SSL => 1 );
        if( ref( $opts->{SSL_opts} ) eq 'HASH' )
        {
            push( @smtp_opts, %{$opts->{SSL_opts}} );
        }
    }

    # NOTE: SMTP connect
    my $smtp;
    my $quit = 1;
    my $host = $opts->{Host};

    if( !defined( $host ) )
    {
        my @hosts = qw( mailhost localhost );
        if( defined( $ENV{SMTPHOSTS} ) && length( $ENV{SMTPHOSTS} ) )
        {
            unshift( @hosts, split( /:/, $ENV{SMTPHOSTS} ) );
        }

        foreach my $h ( @hosts )
        {
            local $@;
            $smtp = eval{ Net::SMTP->new( $h, @smtp_opts ) };
            last if( defined( $smtp ) );
        }
    }
    elsif( $self->_is_a( $host => 'Net::SMTP' ) )
    {
        # Caller passes an already-connected object; we must not quit it.
        $smtp = $host;
        $quit = 0;
    }
    else
    {
        local $@;
        $smtp = eval{ Net::SMTP->new( $host, @smtp_opts ) };
    }

    unless( defined( $smtp ) )
    {
        return( $self->error( "smtpsend(): could not connect to any SMTP server." ) );
    }

    # STARTTLS upgrade (ignored when caller supplied a pre-built object or SSL)
    if( $opts->{StartTLS} && $quit )
    {
        my %tls_opts;
        if( ref( $opts->{SSL_opts} ) eq 'HASH' )
        {
            %tls_opts = %{$opts->{SSL_opts}};
        }
        unless( $smtp->starttls( %tls_opts ) )
        {
            my $smtp_msg = join( ' ', $smtp->message );
            $smtp->quit;
            return( $self->error( "smtpsend(): STARTTLS negotiation failed" . ( length( $smtp_msg ) ? ": $smtp_msg" : '.' ) ) );
        }
    }

    # -------------------------------------------------------------------------
    # SMTP Authentication (SASL via Authen::SASL + Net::SMTP::auth)
    # Password is resolved here so the CODE ref is called as late as possible.
    #
    # We build an explicit Authen::SASL object rather than letting Net::SMTP
    # pick the mechanism freely. Left to itself, Authen::SASL prefers
    # DIGEST-MD5 and CRAM-MD5, which are both deprecated (RFC 6331, RFC 8314) and
    # routinely disabled on modern Postfix/Dovecot servers. Over an already
    # encrypted STARTTLS or SSL channel, PLAIN and LOGIN are both safe and
    # universally supported.
    #
    # Mechanism selection:
    #   1. Caller may supply an explicit list via AuthMechanisms option.
    #   2. Otherwise we use our preferred order: PLAIN LOGIN.
    #   3. We intersect with what the server actually advertises (supports AUTH).
    # -------------------------------------------------------------------------
    if( defined( $username ) && length( $username ) )
    {
        if( ref( $password ) eq 'CODE' )
        {
            local $@;
            $password = eval{ $password->() };
            if( $@ || !defined( $password ) )
            {
                $smtp->quit if( $quit );
                return( $self->error( "smtpsend(): password callback failed: " . ( $@ // 'returned undef' ) ) );
            }
        }

        # Determine which mechanisms the server advertises
        my $server_mechs = $smtp->supports( 'AUTH' ) // '';

        # Build the preferred mechanism list
        my $preferred = $opts->{AuthMechanisms} // 'PLAIN LOGIN';

        # Intersect: keep only those the server supports, preserving our order
        my %server_set = map{ uc( $_ ) => 1 } split( /\s+/, $server_mechs );
        my @agreed = grep{ $server_set{ uc( $_ ) } } split( /\s+/, $preferred );

        if( !@agreed )
        {
            # No intersection -- fall back to whatever the server offers,
            # excluding the deprecated challenge-response mechanisms.
            @agreed = grep{ !/^(?:DIGEST-MD5|CRAM-MD5|GSSAPI)$/i }
                      split( /\s+/, $server_mechs );
        }

        my $sasl = Authen::SASL->new(
            mechanism => join( ' ', @agreed ),
            callback  => {
                user     => $username,
                pass     => $password,
                authname => $username,
            },
        );

        unless( $smtp->auth( $sasl ) )
        {
            # Capture the server's error message for a more useful diagnostic
            my $smtp_msg = join( ' ', $smtp->message );
            $smtp->quit if( $quit );
            return( $self->error( "smtpsend(): SMTP authentication failed for user '$username'" . ( length( $smtp_msg ) ? ": $smtp_msg" : '.' ) ) );
        }
    }

    # Serialise message, stripping Bcc from transmitted copy
    my $send_entity = $self->as_entity || do
    {
        $smtp->quit if( $quit );
        return( $self->pass_error );
    };
    $send_entity->headers->remove( 'Bcc' );
    my $msg = $send_entity->as_string || do
    {
        $smtp->quit if( $quit );
        return( $self->pass_error( $send_entity->error ) );
    };

    # Submit
    my $ok =  $smtp->mail( $mail_from )
           && $smtp->to( @addr )
           && $smtp->data( $msg );

    $smtp->quit if( $quit );

    unless( $ok )
    {
        return( $self->error( "smtpsend(): SMTP transaction failed." ) );
    }

    return( wantarray() ? @addr : \@addr );
}

# subject( [$string] )
# RFC 2047-encodes non-ASCII subjects before storing.
sub subject
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $enc = $self->_encode_header( shift( @_ ) );
        $self->{_headers}->set( 'Subject' => $enc ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->header( 'Subject' ) );
}

# to( @addresses )
# Accumulates To recipients.
sub to
{
    my $self = shift( @_ );
    if( @_ )
    {
        my @encoded = map{ $self->_encode_address( $_ ) } ( ref( $_[0] ) eq 'ARRAY' ? @{$_[0]} : @_ );
        # Merge into a single To: header (RFC 5322 §3.6.3 allows only one To field)
        my $existing = $self->{_headers}->header( 'To' );
        my $new_val  = join( ', ', grep{ defined( $_ ) && length( $_ ) } $existing, @encoded );
        $self->{_headers}->set( 'To' => $new_val ) ||
            return( $self->pass_error( $self->{_headers}->error ) );
        return( $self );
    }
    return( $self->{_headers}->header( 'To' ) );
}

# use_temp_file( [$bool] )
# When true, as_string_ref() always spools to a temporary file regardless of message size.
# This is used when we know the message will be large, or when we want to bound peak 
# memory use unconditionally.
# Default: false.
sub use_temp_file { return( shift->_set_get_boolean( 'use_temp_file', @_ ) ); }

# gpg_encrypt( %opts )
# Encrypts this message for one or more recipients and returns a new Mail::Make object
# whose body is a RFC 3156 multipart/encrypted structure.
#
# Required options:
#   Recipients => [ 'alice@example.com', ... ]
#
# Optional options:
#   GpgBin    => '/usr/bin/gpg2'
#   KeyServer => 'keys.openpgp.org'
#   AutoFetch => 1
#   Digest    => 'SHA256'
sub gpg_encrypt
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    require Mail::Make::GPG;
    my $gpg  = Mail::Make::GPG->new(
        ( defined( $opts->{GpgBin}    ) ? ( gpg_bin    => $opts->{GpgBin}    ) : () ),
        ( defined( $opts->{Digest}    ) ? ( digest     => $opts->{Digest}    ) : () ),
        ( defined( $opts->{KeyServer} ) ? ( keyserver  => $opts->{KeyServer} ) : () ),
        ( defined( $opts->{AutoFetch} ) ? ( auto_fetch => $opts->{AutoFetch} ) : () ),
    ) || return( $self->pass_error( Mail::Make::GPG->error ) );

    my $recipients = $opts->{Recipients} ||
        return( $self->error( 'gpg_encrypt(): Recipients option is required.' ) );
    $recipients = [ $recipients ] unless( ref( $recipients ) eq 'ARRAY' );

    return( $gpg->encrypt(
        entity     => $self,
        recipients => $recipients,
    ) || $self->pass_error( $gpg->error ) );
}

# gpg_sign( %opts )
# Signs this message and returns a new Mail::Make object whose body is a
# RFC 3156 multipart/signed structure with a detached ASCII-armoured signature.
#
# Required options:
#   KeyId => '35ADBC3AF8355E845139D8965F3C0261CDB2E752'
#
# Optional options:
#   Passphrase => 'secret'   # or CODE ref; omit to use gpg-agent
#   Digest     => 'SHA256'
#   GpgBin     => '/usr/bin/gpg2'
sub gpg_sign
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    require Mail::Make::GPG;
    my $gpg  = Mail::Make::GPG->new(
        ( defined( $opts->{GpgBin} ) ? ( gpg_bin => $opts->{GpgBin} ) : () ),
        ( defined( $opts->{Digest} ) ? ( digest  => $opts->{Digest} ) : () ),
    ) || return( $self->pass_error( Mail::Make::GPG->error ) );

    return( $gpg->sign(
        entity     => $self,
        key_id     => ( $opts->{KeyId}      // '' ),
        passphrase => ( $opts->{Passphrase} // undef ),
        ( defined( $opts->{Digest} ) ? ( digest => $opts->{Digest} ) : () ),
    ) || $self->pass_error( $gpg->error ) );
}

# gpg_sign_encrypt( %opts )
# Signs then encrypts this message. Returns a new Mail::Make object whose body is a
# RFC 3156 multipart/encrypted structure containing a signed and encrypted payload.
#
# Required options:
#   KeyId      => '35ADBC3AF8355E845139D8965F3C0261CDB2E752'
#   Recipients => [ 'alice@example.com', ... ]
#
# Optional options:
#   Passphrase => 'secret'   # or CODE ref
#   Digest     => 'SHA256'
#   GpgBin     => '/usr/bin/gpg2'
#   KeyServer  => 'keys.openpgp.org'
#   AutoFetch  => 1
sub gpg_sign_encrypt
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    require Mail::Make::GPG;
    my $gpg  = Mail::Make::GPG->new(
        ( defined( $opts->{GpgBin}    ) ? ( gpg_bin    => $opts->{GpgBin}    ) : () ),
        ( defined( $opts->{Digest}    ) ? ( digest     => $opts->{Digest}    ) : () ),
        ( defined( $opts->{KeyServer} ) ? ( keyserver  => $opts->{KeyServer} ) : () ),
        ( defined( $opts->{AutoFetch} ) ? ( auto_fetch => $opts->{AutoFetch} ) : () ),
    ) || return( $self->pass_error( Mail::Make::GPG->error ) );

    my $recipients = $opts->{Recipients} ||
        return( $self->error( 'gpg_sign_encrypt(): Recipients option is required.' ) );
    $recipients = [ $recipients ] unless( ref( $recipients ) eq 'ARRAY' );

    return( $gpg->sign_encrypt(
        entity     => $self,
        key_id     => ( $opts->{KeyId}      // '' ),
        passphrase => ( $opts->{Passphrase} // undef ),
        recipients => $recipients,
        ( defined( $opts->{Digest} ) ? ( digest => $opts->{Digest} ) : () ),
    ) || $self->pass_error( $gpg->error ) );
}


# smime_encrypt( %opts )
# Encrypts this message for one or more recipients. Returns a new Mail::Make object whose
# entity is a RFC 5751 application/pkcs7-mime enveloped message.
#
# Required options:
#   RecipientCert => $pem_string_or_path   (or arrayref of either)
#
# Optional options:
#   CACert => $pem_string_or_path
sub smime_encrypt
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    require Mail::Make::SMIME;
    my $smime = Mail::Make::SMIME->new(
        ( defined( $opts->{CACert} ) ? ( ca_cert => $opts->{CACert} ) : () ),
    ) || return( $self->pass_error( Mail::Make::SMIME->error ) );

    return( $smime->encrypt(
        entity        => $self,
        RecipientCert => ( $opts->{RecipientCert} || return( $self->error( 'smime_encrypt(): RecipientCert option is required.' ) ) ),
    ) || $self->pass_error( $smime->error ) );
}

# smime_sign( %opts )
# Signs this message and returns a new Mail::Make object whose entity is a RFC 5751
#  multipart/signed structure with a detached S/MIME signature.
#
# Required options:
#   Cert => $pem_string_or_path
#   Key  => $pem_string_or_path
#
# Optional options:
#   KeyPassword => $string_or_coderef
#   CACert      => $pem_string_or_path
sub smime_sign
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    require Mail::Make::SMIME;
    my $smime = Mail::Make::SMIME->new(
        ( defined( $opts->{Cert}        ) ? ( cert         => $opts->{Cert}        ) : () ),
        ( defined( $opts->{Key}         ) ? ( key          => $opts->{Key}         ) : () ),
        ( defined( $opts->{KeyPassword} ) ? ( key_password => $opts->{KeyPassword} ) : () ),
        ( defined( $opts->{CACert}      ) ? ( ca_cert      => $opts->{CACert}      ) : () ),
    ) || return( $self->pass_error( Mail::Make::SMIME->error ) );

    return( $smime->sign(
        entity => $self,
    ) || $self->pass_error( $smime->error ) );
}

# smime_sign_encrypt( %opts )
# Signs then encrypts this message. Returns a new Mail::Make object whose entity is a
# RFC 5751 enveloped message containing a signed payload.
#
# Required options:
#   Cert          => $pem_string_or_path
#   Key           => $pem_string_or_path
#   RecipientCert => $pem_string_or_path   (or arrayref of either)
#
# Optional options:
#   KeyPassword => $string_or_coderef
#   CACert      => $pem_string_or_path
sub smime_sign_encrypt
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    require Mail::Make::SMIME;
    my $smime = Mail::Make::SMIME->new(
        ( defined( $opts->{Cert}        ) ? ( cert         => $opts->{Cert}        ) : () ),
        ( defined( $opts->{Key}         ) ? ( key          => $opts->{Key}         ) : () ),
        ( defined( $opts->{KeyPassword} ) ? ( key_password => $opts->{KeyPassword} ) : () ),
        ( defined( $opts->{CACert}      ) ? ( ca_cert      => $opts->{CACert}      ) : () ),
    ) || return( $self->pass_error( Mail::Make::SMIME->error ) );

    return( $smime->sign_encrypt(
        entity        => $self,
        RecipientCert => ( $opts->{RecipientCert} ||
            return( $self->error( 'smime_sign_encrypt(): RecipientCert option is required.' ) ) ),
    ) || $self->pass_error( $smime->error ) );
}

# _default_domain()
# Returns a reasonable FQDN for auto-generating Message-IDs.
# Uses Sys::Hostname (core) and falls back to 'mail.make.local'.
sub _default_domain
{
    my $self = shift( @_ );
    local $@;
    my $host = eval
    {
        require Sys::Hostname;
        Sys::Hostname::hostname();
    };
    return( 'mail.make.local' ) if( $@ || !defined( $host ) || !length( $host ) );
    # If it is not a FQDN (no dot), append .local to avoid rejection by
    # Mail::Make::Headers::_generate_message_id
    $host .= '.local' if( index( $host, '.' ) == -1 );
    return( $host );
}

# _encode_address( $addr_string )
# Encodes the display name portion of an RFC 2822 address using RFC 2047 when it contains
# non-ASCII characters. The addr-spec (the part inside angle brackets) is never altered.
#
# Recognised forms:
#   "Display Name" <local@domain>
#   Display Name <local@domain>
#   local@domain              (bare addr-spec, passed through unchanged)
#
# Returns the wire-safe string.
sub _encode_address
{
    my( $self, $addr ) = @_;
    return( $addr ) unless( defined( $addr ) && length( $addr ) );
    if( $addr =~ /^("?)([^<"]+)\1\s*<([^>]+)>\s*$/ )
    {
        my( $name, $spec ) = ( $2, $3 );
        $name =~ s/^\s+|\s+$//g;
        my $enc = $self->_encode_header( $name );
        # If the name was encoded (contains non-ASCII), the encoded-word is
        # self-quoting and must NOT be surrounded by double-quotes.
        # If it is plain ASCII, keep surrounding quotes for correct parsing.
        return( $enc ne $name
            ? "${enc} <${spec}>"
            : qq{"${name}" <${spec}>} );
    }
    # Bare addr-spec - nothing to encode
    return( $addr );
}

# _encode_header( $string )
# Encodes a header value for the wire using RFC 2047 if necessary.
# Delegates to Mail::Make::Headers::Subject which handles fragmentation, fold points,
# and UTF-8 boundary safety.
sub _encode_header
{
    my( $self, $str ) = @_;
    return( $str ) unless( defined( $str ) );
    my $s = Mail::Make::Headers::Subject->new;
    $s->value( $str );
    return( $s->as_string );
}

# _format_date()
# Returns the current date/time in RFC 2822 format.
sub _format_date
{
    my @t   = localtime( time );
    my @day = qw( Sun Mon Tue Wed Thu Fri Sat );
    my @mon = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my $tz  = do
    {
        my @lt = localtime( time );
        my @gt = gmtime( time );
        my $diff = ( $lt[2] - $gt[2] ) * 60 + ( $lt[1] - $gt[1] );
        $diff += 1440 if( $lt[5] > $gt[5] || ( $lt[5] == $gt[5] && $lt[7] > $gt[7] ) );
        $diff -= 1440 if( $lt[5] < $gt[5] || ( $lt[5] == $gt[5] && $lt[7] < $gt[7] ) );
        my $sign = $diff >= 0 ? '+' : '-';
        $diff = abs( $diff );
        sprintf( '%s%02d%02d', $sign, int( $diff / 60 ), $diff % 60 );
    };
    return( sprintf( '%s, %02d %s %04d %02d:%02d:%02d %s',
        $day[ $t[6] ], $t[3], $mon[ $t[4] ], $t[5] + 1900,
        $t[2], $t[1], $t[0], $tz ) );
}

# NOTE: STORABLE support
sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw   { CORE::return( CORE::shift->THAW( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make - Strict, Fluent MIME Email Builder

=head1 SYNOPSIS

    use Mail::Make;

    # Fluent API
    my $mail = Mail::Make->new
        ->from( 'hello@example.com' )
        ->to( 'jack@example.jp' )
        ->subject( "Q4 Report - Yamato, Inc." )
        ->plain( "Please find the report attached." )
        ->html( '<p>Please find the report <b>attached</b>.</p>' )
        ->attach_inline(
            path => '/var/www/images/Yamato,Inc-Logo.png',
            type => 'image/png',
            cid  => 'logo@yamato-inc',
        )
        # Positional shorthand - path, type, and filename are auto-detected
        ->attach( '/path/to/report.pdf' )
    
        # Explicit form - override type and filename
        ->attach(
            path     => '/tmp/Q4-Report.pdf',
            type     => 'application/pdf',
            filename => 'Q4 Report 2025.pdf',
        );

    my $raw = $mail->as_string || die( $mail->error );
    print $raw;

    # Scalar-ref form - no string copy, useful for large messages
    my $raw_ref = $mail->as_string_ref || die( $mail->error );
    print $$raw_ref;

    # Write directly to a filehandle - no in-memory buffering
    open( my $fh, '>', '/tmp/message.eml' ) or die $!;
    $mail->print( $fh ) || die( $mail->error );

    # Send directly
    $mail->smtpsend( Host => 'smtp.example.com' )
        || die( $mail->error );

    # Direct access to the envelope headers object
    my $h = $mail->headers;
    $h->set( 'X-Priority' => '1' );

    # Hash-based alternative constructor
    my $mail2 = Mail::Make->build(
        from    => 'hello@example.com',
        to      => [ 'jack@example.jp' ],
        subject => 'Hello',
        plain   => "Hi there.\n",
        html    => '<p>Hi there.</p>',
    ) || die( Mail::Make->error );

=head1 VERSION

    v0.22.0

=head1 DESCRIPTION

C<Mail::Make> is a strict, validating MIME email builder with a fluent interface.

All RFC 2822 envelope fields (C<From>, C<To>, C<Cc>, C<Bcc>, C<Subject>, C<Date>, C<Message-ID>, C<In-Reply-To>, C<References>, C<Reply-To>, C<Sender>) are stored in a L<Mail::Make::Headers> instance accessible via L</headers>, eliminating any duplication between C<Mail::Make>'s own fields and the final entity's headers.

The MIME structure is assembled lazily when L</as_entity>, L</as_string>, or L</print> is called. Structure selection is automatic:

=over 4

=item * plain only → C<text/plain>

=item * html only → C<text/html>

=item * plain + html → C<multipart/alternative>

=item * above + inline parts → wrapped in C<multipart/related>

=item * above + attachments → wrapped in C<multipart/mixed>

=back

Non-ASCII display names in address fields and non-ASCII subjects are RFC 2047 encoded automatically.

L</as_string> returns a plain string, consistent with C<MIME::Entity::stringify>.

L</as_string_ref> returns a B<scalar reference> to avoid a string copy, useful for large messages. L</print> writes directly to a filehandle without buffering the message in memory at all, and is the recommended approach for very large messages.

When L</use_temp_file> is set, or the assembled message size would exceed L</max_body_in_memory_size>, L</as_string_ref> spools to a temporary file during serialisation and reads it back, keeping peak memory use to a single copy rather than two overlapping buffers.

=head1 CONSTRUCTOR

=head2 new( [%opts] )

Creates a new C<Mail::Make> object. Takes an hash or hash reference of options. Supported options are:

=over 4

=item * C<max_body_in_memory_size>

Sets the byte threshold above which L</as_string_ref> spools to a temporary file rather than building the message in RAM. Set to C<0> or C<undef> to disable the threshold entirely. Default: C<$Mail::Make::MAX_BODY_IN_MEMORY_SIZE> (1 MiB).

=item * C<use_temp_file>

When true, L</as_string_ref> always spools to a temporary file regardless of message size. Useful when you know the message will be large, or when you want to bound peak memory use unconditionally. Default: false.

=back

=head2 build( %params )

An alternate hash-based constructor.

Takes an hash or hash reference of options.

Recognised parameters are: L<from|/from>, L<to|/to>, L<cc|/cc>, L<bcc|/bcc>, L<date|/date>, L<reply_to|/reply_to>, L<sender|/sender>, L<subject|/subject>, L<in_reply_to|/in_reply_to>, L<message_id|/message_id>, L<references|/references>, L<plain|/plain>, L<html|/html>, C<plain_opts>, C<html_opts>, C<attach>, C<headers>.

When using the standard mail envelop headers, C<build> will call each respective method, such as L<from|/from>, L<to|/to>, etc.

When passing the C<plain> parameter, it will call L<plain|/plain>, and passing it the optional hash reference of parameters provided with C<plain_opts>

Likewise when passing the C<html> parameter, it will call L<html|/html>, and passing it the optional hash reference of parameters provided with C<html_opts>

The C<attach> parameter accepts one of the following forms:

=over 4

=item * A plain scalar or stringifiable object resolving to an existing file; C<path>, C<type>, and C<filename> are auto-detected:

    attach => 'report.pdf'

=item * An array reference of plain scalars for multiple attachments; likewise C<path>, C<type>, and C<filename> are auto-detected:

    attach => [ 'report.pdf', 'log.pdf' ]

=item * An array reference of hash references for full control over each attachment:

    attach => [
        { path => 'report.pdf', filename => 'Q4 Report.pdf' },
        { path => 'log.pdf',    filename => 'Access Log.pdf' },
    ]

=item * A mix of both forms is also accepted:

    attach => [ 'report.pdf', { path => 'log.pdf', filename => 'Access Log.pdf' } ]

=back

If C<type> is not provided in any of the above forms, it is auto-detected from the file content using L<Module::Generic::File::Magic>.

Each element is forwarded to L</attach>, so all options supported by L</attach> are available in the hash reference form.

You can also provide additional mail envelop headers by providing the parameter C<headers> as an hash reference.

For each element of that hash reference, it will call L<header/header>

Returns the populated C<Mail::Make> object, or upon error, set an L<error object|Mail::Make::Exception>, and returns C<undef> in scalar context or an empty list in list context.

=head1 FLUENT METHODS

All setter methods return C<$self> to allow chaining. Called without arguments, they act as getters and return the stored value (delegating to the internal L<Mail::Make::Headers> object).

=head2 attach( %opts )

    # Positional shorthand: path, type, and filename are auto-detected
    $mail->attach( '/path/to/report.pdf' );

    # Explicit form
    $mail->attach(
        path     => $pdf_path,
        type     => 'application/pdf',
        filename => 'report.pdf',
    ); # returns $mail

Adds a downloadable attachment, and returns the current instance for chaining.

Takes either a single positional file path as a shorthand, or an hash or hash reference of parameters.

When a single plain scalar or stringifiable object is provided and it resolves to an existing file on disk, C<path>, C<type>, and C<filename> are set automatically. Additional named options may still be passed after the path:

    $mail->attach( '/path/to/report.pdf', encoding => 'base64' );

Requires either C<path> or C<data> when using the named-parameter form.

Options are:

=over 4

=item * C<charset>

The optional charset of the attachment.

=item * C<description>

A short description.

=item * C<encoding>

The encoding of the attachment, such as C<zip>, C<gzip>, C<bzip2>, etc..

=item * C<filename>

The attachment filename as displayed to the reader.

=item * C<type>

The attachment mime-type.

=back

All parameters are forwarded to L<Mail::Make::Entity/build>.

=head2 attach_inline( %opts )

    $mail->attach_inline(
        path     => $img_path,
        type     => 'image/png',
        filename => 'Yamato,Inc-Logo.png',
        cid      => 'logo@yamato-inc',
    ); # returns $mail

Adds an inline part (e.g. an embedded image referenced via C<cid:> in HTML), and returns the current instance for chaining.

Takes an hash or hash reference of parameters.

Requires either <path> or C<data> and either C<id> or C<cid>.

Supported parameters are:

=over 4

=item * C<boundary>

The boundary used.

=item * C<charset>

The optional charset of the attachment.

=item * C<cid> or C<id>

The attachment ID (C<Content-ID>)

=item * C<data>

The attachement raw data.

=item * C<debug>

An unsigned integer to enable debugging.

=item * C<description>

A short description.

See also C<path> for an alternative.

=item * C<disposition>

Can be either C<attachment> or C<inline>

=item * C<encoding>

The encoding of the attachment, such as C<zip>, C<gzip>, C<bzip2>, etc..

=item * C<filename>

The attachment filename as displayed to the reader.

=item * C<path>

The attachment file path.

See also C<data> for an alternative.

=item * C<type>

The attachment mime-type.

=back

=head2 bcc( @addresses )

    $mail->bcc( qw( hello@example.com john@example.jp ) );

    $mail->bcc( [qw( hello@example.com john@example.jp )] );

Accumulates one or more BCC addresses. May be called multiple times.

This takes either an array reference or a list of e-mail addresses, encode them if necessary, and add them to the C<Bcc> mail envelop header as a comma-separated value using L<Mail::Make::Headers/push_header>

When called as a mutator, it returns the current instance of L<Mail::Make::Headers>, otherwise, as an accessor, it returns the current value of the mail envelop header.

=head2 cc( @addresses )

    $mail->cc( qw( hello@example.com john@example.jp ) );

    $mail->cc( [qw( hello@example.com john@example.jp )] );

Accumulates one or more CC addresses.

This takes either an array reference or a list of e-mail addresses, encode them if necessary, and add them to the C<Cc> mail envelop header as a comma-separated value using L<Mail::Make::Headers/push_header>

When called as a mutator, it returns the current instance of L<Mail::Make::Headers>, otherwise, as an accessor, it returns the current value of the mail envelop header.

=head2 date( [$date_string_or_epoch] )

Gets or sets the C<Date> header.

Accepts a Unix epoch integer (converted to RFC 5322 format automatically) or a pre-formatted RFC 5322 string.

Delegates to L<Mail::Make::Headers/date>. If not set explicitly, the current date and time are used when L</as_entity> is first called.

When called as a mutator, it returns the current instance of L<Mail::Make::Headers>, otherwise, as an accessor, it returns the current value of the mail envelop header.

=head2 from( [$address] )

    $mail->from( 'hello@example.com' );

Gets or sets the C<From> header by calling L<Mail::Make::Headers/set>.

Non-ASCII display names are RFC 2047 encoded automatically.

When called as a mutator, it returns the current instance of L<Mail::Make>, otherwise, as an accessor, it returns the current value of the mail envelop header.

=head2 header( $name [, $value] )

    $mail->header( 'X-Mailer' => 'MySoft/v1.0.0' ); # returns $mail
    # or
    $mail->header( X_Mailer => 'MySoft/v1.0.0' ); # returns $mail

    my $software = $mail->header( 'X-Mailer' );

With two arguments: appends an arbitrary header to the envelope using L<push_header|Mail::Make::Headers/push_header> semantics (does not replace an existing field of the same name).

Returns the current instance of C<Mail::Make>

With one argument: returns the current value of the named header.

=head2 headers()

    my $headers = $mail->headers; # Mail::Make::Headers

Returns the internal L<Mail::Make::Headers> object. Use this for operations not covered by the fluent methods, such as setting C<X-*> headers or reading back any field.

=head2 html( $content [, %opts] )

    $mail->html( '<p>Hello world</p>', {
        charset     => 'utf-8',
        encoding    => 'quoted-printable',
    }); # returns $mail

Adds a C<text/html> body part, and returns the current instance for chaining.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

This takes an optional hash or hash reference of the following parameters:

=over 4

=item * C<charset>

The character set used for thise HTML data.

Defaults to C<utf-8>

=item * C<data>

The HTML data.

=item * C<encoding>

Can be C<quoted-printable> or C<base64>

Defaults to C<quoted-printable>

=back

=head2 in_reply_to( [$mid] )

    $mail->in_reply_to( 'dave.null@example.com' ); # Returns $mail
    my $email = $mail->in_reply_to;

Gets or sets the C<In-Reply-To> header.

In mutator mode, this sets the C<In-Reply-To> mail envelop header using L<Mail::Make::Headers/set>, and returns the current instance of C<Mail::Make>, and in accessor mode, this returns the current value for the mail envelop header C<In-Reply-To>

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 message_id( [$mid | \%opts] )

    $mail->message_id( '2adefb89-a26a-4cf1-91c7-1413b13cfd0f@local' ); # Returns $mail
    $mail->message_id( '2adefb89-a26a-4cf1-91c7-1413b13cfd0f@local', { strict => 1 } ); # Returns $mail
    $mail->message_id({ generate => 1, domain => 'example.com' });
    $mail->message_id( undef ); # remove the message ID
    my $msgid = $mail->message_id;

Gets or sets the C<Message-ID>. Auto-generated when L</as_entity> is called if not explicitly set.

Delegates to L<Mail::Make::Headers/message_id>.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

This takes an optional hash reference of the following parameters:

=over 4

=item * C<domain>

The domain name to use when generating the message ID.

=item * C<generate>

If set to true, then L<Mail::Make::Headers/message_id> will generate the message ID.

If the option C<domain> is not provided, it will use L<Sys::Hostname/hostname> to guess the domain name.

=item * C<strict>

A boolean value (C<1> or C<0>).

When this is set to true, L<message_id>|Mail::Make::Headers/message_id> will call C<_validate_message_id_value> in L<Mail::Make::Headers> to thoroughly validate the value provided. This means, it will reject the value if:

=over 8

=item 1. It contains any non-ASCII or spaces/control characters.

=item 2. It is not wrapped in angle brackets: C<< < >> and C<< > >>

=item 3. Does not have exactly one at-mark C<@>

=item 4. The local part (the part on the left of the at-mark) contains characters other than:

    [A-Za-z0-9.!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+

=item 5. The domain part (the part of the right of the at-mark) contains characters other than:

    [A-Za-z0-9](?:[A-Za-z0-9\-\.]*[A-Za-z0-9])?

=back

=back

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 plain( $content [, %opts] )

    $mail->plain( 'Hello world', {
        charset     => 'utf-8',
        encoding    => 'quoted-printable',
    }); # returns $mail

Adds a C<text/plain> body part, and returns the current instance for chaining.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

This takes an optional hash or hash reference of the following parameters:

=over 4

=item * C<charset>

The character set used for thise HTML data.

Defaults to C<utf-8>

=item * C<data>

The HTML data.

=item * C<encoding>

Can be C<quoted-printable> or C<base64>

Defaults to C<quoted-printable>

=back

=head2 references( @mids )

    $mail->references( [ $msg_id1, $msg_id2 ] ); # Returns $mail
    $mail->references( $msg_id1, $msg_id2 );     # Returns $mail
    # Removes the header
    $mail->references( undef );                  # Returns $mail
    my @message_ids = $mail->references;
    my $comma_list  = $mail->references;

Accumulates one or more Message-IDs in the C<References> header.

In mutator mode, this returns the current instance of L<Mail::Make>

In accessor mode, this returns a list of message IDs, and in scalar mode, this returns a comma-separate list of message IDs.s

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 reply_to( [$address] )

    $mail->reply_to( 'hello@example.com' );

Gets or sets the C<Reply-To> header by calling L<Mail::Make::Headers/set>.

Non-ASCII display names are RFC 2047 encoded automatically.

When called as a mutator, it returns the current instance of L<Mail::Make>, otherwise, as an accessor, it returns the current value of the mail envelop header.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 return_path( [$address] )

    $mail->return_path( 'dave.null@example.com' );

Gets or sets the C<Return-Path> header by calling L<Mail::Make::Headers/set>.

Non-ASCII display names are RFC 2047 encoded automatically.

When called as a mutator, it returns the current instance of L<Mail::Make>, otherwise, as an accessor, it returns the current value of the mail envelop header.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 sender( [$address] )

    $mail->sender( 'hello@example.com' );

Gets or sets the C<Sender> header by calling L<Mail::Make::Headers/set>.

When called as a mutator, it returns the current instance of L<Mail::Make>, otherwise, as an accessor, it returns the current value of the mail envelop header.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 subject( [$string] )

    $mail->subject( '会議議事録' );  # Returns $mail
    $mail->subject;

Gets or sets the C<Subject> by calling L<Mail::Make::Headers/set>.

When called as a mutator, it returns the current instance of L<Mail::Make>, otherwise, as an accessor, it returns the current value of the mail envelop header.

Non-ASCII subjects are RFC 2047 encoded before being stored.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 to( @addresses )

    $mail->to( 'hello@example.com' );

Accumulates one or more To addresses. Multiple calls are merged into a single C<To:> field per RFC 5322 §3.6.3 by calling L<Mail::Make::Headers/set>.

Non-ASCII display names are RFC 2047 encoded automatically.

Note that it is up to you to ensure there are no duplicates.

When called as a mutator, it returns the current instance of L<Mail::Make>, otherwise, as an accessor, it returns the current value of the mail envelop header.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head1 OUTPUT METHODS

=head2 as_entity

    my $entity = $mail->as_entity; # Returns a Mail::Make::Entity object

Assembles and returns the top-level L<Mail::Make::Entity> based on the various content that has been specified, such as plain text, html mail, attachments, or inline attachments.

The MIME structure is selected automatically (see L</DESCRIPTION>). Envelope headers are merged into the entity using C<init_header> semantics: fields already set on the entity (C<Content-Type>, C<MIME-Version>, etc.) are never overwritten.

If no C<Message-ID> is set yet, it will compute one.

C<MIME-Version> will be set to C<1.0> no matter what value may have been set previously.

The computed value is cached, so repetitive calls will return the cached value.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 as_string

    my $string = $mail->as_string;

Assembles the message and returns it as a plain string, consistent with C<MIME::Entity::stringify>. This is the form suitable for direct printing, string interpolation, and most downstream consumers.

For large messages, prefer L</print> (no buffering) or L</as_string_ref> (no copy on return).

This method calls L</as_entity>, and returns the value returned by L<Mail::Make::Entity/as_string>, passing it whatever value was provided.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 as_string_ref

    my $scalar_ref = $mail->as_string_ref;

Assembles the message and returns it as a B<scalar reference> (or a L<Module::Generic::Scalar> object, which stringifies as needed). No extra string copy is made during the fast path.

When L</use_temp_file> is true, B<or> the serialised entity size returned by L<Mail::Make::Entity/length> exceeds L</max_body_in_memory_size>, the message is written to a C<Module::Generic::Scalar> buffer via its in-memory filehandle.
This keeps peak RAM use to a single copy of the assembled message.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 max_body_in_memory_size( [$bytes] )

Gets or sets the byte threshold above which L</as_string_ref> spools to a temporary file rather than building the message in RAM. Set to C<0> or C<undef> to disable the threshold entirely. Default: C<$Mail::Make::MAX_BODY_IN_MEMORY_SIZE> (1 MiB).

=head2 print( $fh )

    $mail->print( $fh ) || die( $mail->error );

Writes the fully assembled message to a filehandle without buffering it in memory. This is the recommended approach for very large messages: the MIME tree is serialised part by part directly to C<$fh>, keeping memory use proportional to the largest single part rather than the total message size.

This returns the current instance of L<Mail::Make> for chaining.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 smtpsend( %opts )

    my @recipients = $mail->smtpsend( Host => $smtp );

    my $rv = $mail->smtpsend(
        Host  => '127.0.0.1',
        Port  => $port,
        Hello => 'test.local',
    );

    my $recipients_array_ref = $mail->smtpsend(
        Host     => '127.0.0.1',
        Port     => $port,
        Hello    => 'test.local',
        MailFrom => 'bounce@example.com',
    );

Assembles the message and submits it to an SMTP server via L<Net::SMTP>, which is a core perl module, and loaded only when this method is called.

This takes a hash or hash reference of options.

Credential and recipient validation is performed B<before> any network connection is attempted, so configuration errors are reported immediately without consuming network resources.

Recognised options:

=over 4

=item C<AuthMechanisms>

Space-separated list of SASL mechanism names in preference order.

Defaults to C<"PLAIN LOGIN">, which are safe and universally supported over an encrypted channel (STARTTLS or SSL).

The actual mechanism used is the intersection of this list and what the server advertises. If no intersection exists, deprecated challenge-response mechanisms (C<DIGEST-MD5>, C<CRAM-MD5>, C<GSSAPI>) are excluded and the remainder of the server's list is tried.

=item C<Debug>

Boolean. Enables L<Net::SMTP> debug output.

=item C<Hello>

The FQDN sent in the EHLO/HELO greeting.

=item C<Host>

Hostname, IP address, or an already-connected L<Net::SMTP> object. If an existing object is passed, it is used as-is and B<not> quit on completion (the caller retains ownership of the connection).

If omitted, the colon-separated list in C<$ENV{SMTPHOSTS}> is tried first, then C<mailhost> and C<localhost> in that order.

=item C<MailFrom>

The envelope sender address (C<MAIL FROM>). Defaults to the bare addr-spec extracted from the C<From:> header.

=item C<Password>

Password for SMTP authentication. May be:

=over 4

=item * A plain string.

=item * A C<CODE> reference called with no arguments at authentication time.

Useful for reading credentials from a keyring or secrets manager without storing them in memory until needed:

    Password => sub { MyKeyring::get('smtp') }

=back

=item C<Port>

SMTP port number. Common values:

=over 4

=item * C<25>  - plain SMTP (default when C<SSL> is false)

=item * C<465> - SMTPS, direct SSL/TLS (use with C<< SSL => 1 >>)

=item * C<587> - submission, usually STARTTLS (use with C<< StartTLS => 1 >>)

=back

=item C<SSL>

Boolean. When true, the connection is wrapped in SSL/TLS from the start (SMTPS, typically port 465).

Requires L<IO::Socket::SSL>.

=item C<StartTLS>

Boolean. When true, a plain connection is established first and then upgraded to TLS via the SMTP C<STARTTLS> extension (typically port 587).

Requires L<IO::Socket::SSL>. Ignored when C<Host> is a pre-built L<Net::SMTP> object.

=item C<SSL_opts>

Hash reference of additional options passed to L<IO::Socket::SSL> during the SSL/TLS handshake. For example:

    SSL_opts => { SSL_verify_mode => 0 }           # disable peer cert check
    SSL_opts => { SSL_ca_file => '/etc/ssl/ca.pem' }

=item C<Timeout>

Connection and command timeout in seconds, passed directly to L<Net::SMTP>.

=item C<To>, C<Cc>, C<Bcc>

Override the RCPT TO list. Each may be a string or an array reference of addresses. When omitted, the corresponding message headers are used.

C<Bcc:> is always stripped from the outgoing message headers before transmission, per RFC 2822 §3.6.3.

=item C<Username>

Login name for SMTP authentication (SASL). Requires L<Authen::SASL>.

Must be combined with C<Password>. Validated before any connection is made.

=back

B<Typical usage examples:>

    # Plain SMTP, no auth (LAN relay)
    $mail->smtpsend( Host => 'mail.example.com' );

    # SMTPS (direct TLS, port 465)
    $mail->smtpsend(
        Host     => 'smtp.example.com',
        Port     => 465,
        SSL      => 1,
        Username => 'jack@example.com',
        Password => 'secret',
    );

    # Submission with STARTTLS (port 587) and password callback
    $mail->smtpsend(
        Host     => 'smtp.example.com',
        Port     => 587,
        StartTLS => 1,
        Username => 'jack@example.com',
        Password => sub { MyKeyring::get('smtp_pass') },
    );

Returns the list of accepted recipient addresses in list context, or a reference to that list in scalar context.

If an error occurs, it sets an L<exception object|Mail::Make::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head2 use_temp_file( [$bool] )

When true, L</as_string_ref> always spools to a temporary file regardless of message size. Useful when you know the message will be large, or when you want to bound peak memory use unconditionally. Default: false.

=head1 GPG METHODS

These methods delegate to L<Mail::Make::GPG>, which requires L<IPC::Run> and a working C<gpg> (or C<gpg2>) installation. All three methods produce RFC 3156-compliant messages and return a new L<Mail::Make> object suitable for passing directly to C<smtpsend()>.

=head2 gpg_encrypt( %opts )

Encrypts this message for one or more recipients and returns a new L<Mail::Make> object whose entity is an RFC 3156 C<multipart/encrypted; protocol="application/pgp-encrypted"> message.

Required options:

=over 4

=item Recipients => \@addrs_or_key_ids

Array reference of recipient e-mail addresses or key fingerprints. Each recipient's public key must already be present in the local GnuPG keyring, unless C<AutoFetch> is enabled.

=back

Optional options:

=over 4

=item C<< AutoFetch => $bool >>

When true and C<KeyServer> is set, calls C<gpg --locate-keys> for each recipient before encryption. Default: C<0>.

=item C<< Digest => $algorithm >>

Hash algorithm for the signature embedded in the encrypted payload.
Default: C<SHA256>.

=item C<< GpgBin => $path >>

Full path to the C<gpg> executable. Defaults to searching C<gpg2> then C<gpg> in C<PATH>.

=item C<< KeyServer => $url >>

Keyserver URL for auto-fetching recipient public keys (e.g. C<'keys.openpgp.org'>). Only consulted when C<AutoFetch> is true.

=back

=head2 gpg_sign( %opts )

Signs this message and returns a new L<Mail::Make> object whose entity is an RFC 3156 C<multipart/signed; protocol="application/pgp-signature"> message with a detached, ASCII-armoured signature.

Required options:

=over 4

=item C<< KeyId => $fingerprint_or_id >>

Signing key fingerprint or short ID (e.g. C<'35ADBC3AF8355E845139D8965F3C0261CDB2E752'>).

=back

Optional options:

=over 4

=item C<< Digest => $algorithm >>

Hash algorithm. Default: C<SHA256>.

Valid values: C<SHA256>, C<SHA384>, C<SHA512>, C<SHA1>.

=item C<< GpgBin => $path >>

Full path to the C<gpg> executable.

=item C<< Passphrase => $string_or_coderef >>

Passphrase to unlock the secret key. May be a plain string or a C<CODE> reference called with no arguments at signing time. When omitted, GnuPG's agent handles passphrase prompting.

=back

=head2 gpg_sign_encrypt( %opts )

Signs then encrypts this message. Returns a new L<Mail::Make> object whose entity is an RFC 3156 C<multipart/encrypted> message containing a signed and encrypted OpenPGP payload.

Accepts all options from both L</gpg_sign> and L</gpg_encrypt>.

B<Note:> C<KeyId> and C<Recipients> are both required.

B<Typical usage:>

    # Sign only
    my $signed = $mail->gpg_sign(
        KeyId      => '35ADBC3AF8355E845139D8965F3C0261CDB2E752',
        Passphrase => 'my-passphrase',   # or: sub { MyKeyring::get('gpg') }
    ) || die $mail->error;
    $signed->smtpsend( Host => 'smtp.example.com' );

    # Encrypt only
    my $encrypted = $mail->gpg_encrypt(
        Recipients => [ 'alice@example.com' ],
    ) || die $mail->error;

    # Sign then encrypt
    my $protected = $mail->gpg_sign_encrypt(
        KeyId      => '35ADBC3AF8355E845139D8965F3C0261CDB2E752',
        Passphrase => sub { MyKeyring::get_passphrase() },
        Recipients => [ 'alice@example.com', 'bob@example.com' ],
    ) || die $mail->error;

=head1 S/MIME METHODS

These methods delegate to L<Mail::Make::SMIME>, which requires L<Crypt::SMIME> (an XS module wrapping OpenSSL C<libcrypto>). All certificates and keys must be supplied in PEM format, either as file paths or as PEM strings.

=head2 Memory usage

All three methods load the complete serialised message into memory before performing any cryptographic operation. This is a fundamental constraint imposed by two factors: the L<Crypt::SMIME> API accepts only Perl strings (no filehandle or streaming interface), and the underlying protocols themselves require the entire content to be available before the result can be emitted, thus signing requires a complete hash before the signature can be appended, and PKCS#7 encryption requires the total payload length to be declared in the ASN.1 DER header before any ciphertext is written.

For typical email messages this is not a concern. If you anticipate very large attachments, consider L<Mail::Make::GPG> instead, which delegates to the C<gpg> command-line tool via L<IPC::Run> and can handle arbitrary message sizes through temporary files. A future C<v0.2.0> of L<Mail::Make::SMIME> may add a similar C<openssl smime> backend.

See L<Mail::Make::SMIME/"MEMORY USAGE AND LIMITATIONS"> for a full discussion.

=head2 smime_encrypt( %opts )

    $encrypted = $mail->smime_encrypt(
        RecipientCert => $smime_rec_cert,
    );

Encrypts this message for one or more recipients and returns a new C<Mail::Make> object whose entity is an RFC 5751 C<application/pkcs7-mime; smime-type=enveloped-data> message.

Takes an hash or hash reference of options.

Required options:

=over 4

=item C<< RecipientCert => $pem_string_or_path >>

Recipient certificate in PEM format (for encryption). May also be an array reference of PEM strings or file paths for multi-recipient encryption.

=back

Optional options:

=over 4

=item C<< CACert => $pem_string_or_path >>

CA certificate to include for chain verification.

=back

=head2 smime_sign( %opts )

    my $signed = $mail->smime_sign(
        Cert   => $smime_cert,
        Key    => $smime_key,
        CACert => $smime_ca, # optional
    );

Signs this message with a detached S/MIME signature and returns a new C<Mail::Make> object whose entity is an RFC 5751 C<multipart/signed> message.

The signature is always detached, which allows non-S/MIME-aware clients to read the message body.

Required options:

=over 4

=item C<< Cert => $pem_string_or_path >>

Signer certificate in PEM format.

=item C<< Key => $pem_string_or_path >>

Private key in PEM format.

=back

Optional options:

=over 4

=item C<< KeyPassword => $string_or_coderef >>

Passphrase for an encrypted private key, or a CODE ref that returns one.

=item C<< CACert => $pem_string_or_path >>

CA certificate to include in the signature for chain verification.

=back

=head2 smime_sign_encrypt( %opts )

    my $result = $mail->smime_sign_encrypt(
        Cert          => $smime_cert,
        Key           => $smime_key,
        RecipientCert => $smime_rec_cert,
        CACert        => $smime_ca, # optional
    );

Signs this message then encrypts the signed result. Returns a new C<Mail::Make> object whose entity is an RFC 5751 enveloped message containing a signed payload.

Accepts all options from both L</smime_sign> and L</smime_encrypt>.

B<Note:> C<Cert>, C<Key>, and C<RecipientCert> are all required.

B<Typical usage:>

    # Sign only
    my $signed = $mail->smime_sign(
        Cert   => '/path/to/my.cert.pem',
        Key    => '/path/to/my.key.pem',
        CACert => '/path/to/ca.crt',
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

=head1 PRIVATE METHODS

=head2 _default_domain

Returns a FQDN for auto-generated C<Message-ID> values. Uses L<Sys::Hostname> and appends C<.local> when the hostname contains no dot.

Falls back to C<mail.make.local>.

=head2 _encode_address( $addr_string )

Encodes the display-name portion of an RFC 2822 address using RFC 2047 when the display name contains non-ASCII characters. The addr-spec is never modified.

=head2 _encode_header( $string )

Encodes an arbitrary header string for the wire using RFC 2047 encoded-words.

Delegates to L<Mail::Make::Headers::Subject>.

=head2 _format_date

Returns the current local date and time as an RFC 2822 string.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

RFC 2045, RFC 2046, RFC 2047, RFC 2183, RFC 2231, RFC 2822

L<Mail::Make::Entity>, L<Mail::Make::Headers>, L<Mail::Make::Headers::ContentType>, L<Mail::Make::Headers::ContentDisposition>, L<Mail::Make::Headers::ContentTransferEncoding>, L<Mail::Make::Body::InCore>, L<Mail::Make::Body::File>, L<Mail::Make::Stream::Base64>, L<Mail::Make::Stream::QuotedPrint>, L<Mail::Make::Exception>, L<Net::SMTP>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
