##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Entity.pm
## Version v0.4.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/02
## Modified 2026/03/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::Entity;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS $CRLF );
    use Data::UUID;
    use Mail::Make::Body::File;
    use Mail::Make::Body::InCore;
    use Mail::Make::Exception;
    use Mail::Make::Headers;
    use Mail::Make::Headers::ContentDisposition;
    use Mail::Make::Headers::ContentTransferEncoding;
    use Mail::Make::Headers::ContentType;
    use Mail::Make::Stream;
    use Mail::Make::Stream::Base64;
    use Mail::Make::Stream::QuotedPrint;
    our $CRLF              = "\015\012";
    our $DEFAULT_MIME_TYPE = 'application/octet-stream';
    our $EXCEPTION_CLASS   = 'Mail::Make::Exception';
    our $VERSION           = 'v0.4.0';
}

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{body}                 = undef;   # Mail::Make::Body object
    $self->{effective_type}       = undef;   # cached mime type string
    $self->{epilogue}             = [];
    $self->{headers}              = undef;   # Mail::Make::Headers object
    $self->{is_encoded}           = 0;
    $self->{preamble}             = [];
    $self->{_parts}               = [];      # [ Mail::Make::Entity, ... ]
    $self->{_exception_class}     = $EXCEPTION_CLASS;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# add_part( $entity )
# Appends a Mail::Make::Entity as a sub-part of this entity.
sub add_part
{
    my( $self, $part ) = @_;
    unless( $self->_is_a( $part => 'Mail::Make::Entity' ) )
    {
        return( $self->error( "add_part: argument must be a Mail::Make::Entity" ) );
    }
    push( @{$self->{_parts}}, $part );
    return( $self );
}

# as_string()
# Returns the serialised entity (headers + blank line + body) as a plain string.
sub as_string
{
    my $self = shift( @_ );
    my $out  = '';
    open( my $fh, '>:raw', \$out ) ||
        return( $self->error( "Cannot open in-memory buffer for as_string: $!" ) );
    $self->print( $fh ) || return( $self->pass_error );
    close( $fh );
    return( $out );
}

# Returns the serialised entity as a scalar reference, avoiding a string copy.
# Useful for large messages where the caller can pass the ref directly to
# print() or write() without materialising a second copy.
sub as_string_ref
{
    my $self = shift( @_ );
    my $out  = '';
    open( my $fh, '>:raw', \$out ) ||
        return( $self->error( "Cannot open in-memory buffer for as_string_ref: $!" ) );
    $self->print( $fh ) || return( $self->pass_error );
    close( $fh );
    return( \$out );
}

# body( [$body_object] )
# Gets or sets the Mail::Make::Body object.
sub body
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $body = shift( @_ );
        if( defined( $body ) )
        {
            unless( $self->_is_a( $body => 'Mail::Make::Body' ) )
            {
                return( $self->error( "body: argument must be a Mail::Make::Body-derived object" ) );
            }
        }
        $self->{body} = $body;
        return( $self );
    }
    return( $self->{body} );
}

# body_as_string()
# Returns the encoded body content as a scalar reference.
sub body_as_string
{
    my $self = shift( @_ );
    unless( defined( $self->{body} ) )
    {
        return( $self->error( "No body is set on this entity" ) );
    }

    my $enc = $self->headers->content_transfer_encoding // '';
    if( CORE::length( $enc ) && !$self->{is_encoded} )
    {
        $self->encode_body || return( $self->pass_error );
    }
    return( $self->{body}->as_string );
}

# build( %params )
# Factory / class method: build a single MIME entity from parameters.
# This is the key method - it performs strict validation and correct encoding.
#
# Parameters:
#   type        MIME type string (default: 'text/plain')
#   charset     charset for text/* types
#   encoding    CTE (default: auto-suggested)
#   disposition inline | attachment (default: none unless filename provided)
#   filename    filename for Content-Type name= and Content-Disposition filename=
#   cid         Content-ID for inline parts (wrapped in <...> automatically if needed)
#   data        scalar body content
#   path        file path body content
#   boundary    boundary for multipart/* types (auto-generated if omitted)
#   description Content-Description value
#   top         boolean - is this the top-level entity? (default: 1)
#   debug       debug level (default: 0)
sub build
{
    my $class = shift( @_ );
    # Support both class and instance call
    my $self  = ref( $class ) ? $class : $class->new;
    return( $self->pass_error ) if( !$self );
    my $opts  = $self->_get_args_as_hash( @_ );
    $self->debug( delete( $opts->{debug} ) );

    # NOTE: 1. Extract and validate parameters
    my $type        = lc( delete( $opts->{type} )        // 'text/plain' );
    my $charset     = delete( $opts->{charset} );
    my $encoding    = defined( $opts->{encoding} )
                      ? lc( delete( $opts->{encoding} ) )
                      : undef;
    my $disposition = defined( $opts->{disposition} )
                      ? lc( delete( $opts->{disposition} ) )
                      : undef;
    my $filename    = delete( $opts->{filename} );
    my $cid         = delete( $opts->{cid} ) || delete( $opts->{id} );
    my $data        = delete( $opts->{data} );
    my $path        = delete( $opts->{path} );
    my $boundary    = delete( $opts->{boundary} );
    my $description = delete( $opts->{description} );
    my $top         = exists( $opts->{top} ) ? delete( $opts->{top} ) : 1;

    my $is_multipart = ( $type =~ m{^multipart/}i );
    my $is_message   = ( $type =~ m{^message/}i );

    # NOTE: 2. Validate the MIME type format
    my $ct_obj = Mail::Make::Headers::ContentType->new( $type ) ||
        return( $self->pass_error( Mail::Make::Headers::ContentType->error ) );

    # NOTE: 3. Validate charset (text/* types only)
    if( defined( $charset ) )
    {
        if( !$is_multipart )
        {
            $ct_obj->param( charset => $charset ) ||
                return( $self->pass_error( $ct_obj->error ) );
        }
        else
        {
            # Silently discard charset on multipart - do not pass invalid param
            undef( $charset );
        }
    }
    else
    {
        # Default charset for text/* parts
        if( $type =~ m{^text/}i && !$is_multipart )
        {
            $ct_obj->param( charset => 'utf-8' ) ||
                return( $self->pass_error( $ct_obj->error ) );
        }
    }

    # NOTE: 4. Determine filename (from explicit param or basename of path)
    if( !defined( $filename ) && defined( $path ) && CORE::length( $path ) )
    {
        ( $filename ) = ( $path =~ m{([^/\\]+)\z} );
    }
    # Empty string -> treat as no filename
    undef( $filename ) if( defined( $filename ) && !CORE::length( $filename ) );

    # NOTE: 5. Content-Type set for filename
    # 5. Set Content-Type name= parameter if we have a filename
    #    THIS IS THE KEY FIX: we go through ContentType->param() which
    #    handles RFC 2231 encoding, not a raw string that Mail::Field
    #    would misparse on commas.
    if( defined( $filename ) && !$is_multipart )
    {
        $ct_obj->param( name => $filename ) ||
            return( $self->pass_error( $ct_obj->error ) );
    }

    # NOTE: 6. Validate / generate boundary for multipart
    if( $is_multipart )
    {
        if( defined( $boundary ) )
        {
            if( !CORE::length( $boundary ) )
            {
                # Empty boundary: warn and generate a fresh one
                warn( "Empty boundary string provided; generating a new one\n" );
                undef( $boundary );
            }
            elsif( $boundary =~ /[^0-9a-zA-Z'()+_,\-.\/:=? ]/ )
            {
                return( $self->error( "Boundary '$boundary' contains illegal characters" ) );
            }
        }
        $boundary //= $self->make_boundary;
        # Boundary is safe to pass directly (we just validated it)
        $ct_obj->param( boundary => $boundary ) ||
            return( $self->pass_error( $ct_obj->error ) );
    }

    # NOTE: 7. Validate Content-Transfer-Encoding
    if( defined( $encoding ) )
    {
        if( $is_multipart )
        {
            return( $self->error(
                "build(): encoding '$encoding' is not permitted for multipart type '$type'."
            ) );
        }
        elsif( $is_message )
        {
            # RFC 2045 §6.4 - multipart and message types must not have a CTE
            undef( $encoding );
        }
        elsif( $encoding eq 'suggest' )
        {
            # Deferred: computed after we know the body type
            undef( $encoding );
        }
        else
        {
            my $cte_obj = Mail::Make::Headers::ContentTransferEncoding->new( $encoding ) ||
                return( $self->pass_error( Mail::Make::Headers::ContentTransferEncoding->error ) );
            # 'binary' is not valid for text/* parts in SMTP contexts
            if( $cte_obj->is_binary && $type =~ m{^text/}i )
            {
                return( $self->error( "Encoding 'binary' is not permitted for text/* type '$type'" ) );
            }
        }
    }

    # NOTE: 8. Build a fresh entity object with fresh headers
    my $entity  = ref( $class ) ? $class->new : $class->new;
    return( $self->pass_error ) if( !$entity );
    my $headers = Mail::Make::Headers->new ||
        return( $self->pass_error( Mail::Make::Headers->error ) );
    $entity->headers( $headers );

    # NOTE: 9. Attach body (single-part only)
    if( !$is_multipart )
    {
        if( defined( $path ) && CORE::length( $path ) )
        {
            my $body = Mail::Make::Body::File->new( $path ) ||
                return( $self->pass_error( Mail::Make::Body::File->error ) );
            $entity->body( $body );
        }
        elsif( defined( $data ) )
        {
            my $body = Mail::Make::Body::InCore->new( $data ) ||
                return( $self->pass_error( Mail::Make::Body::InCore->error ) );
            $entity->body( $body );
        }
        else
        {
            return( $self->error( "build: a body is required for non-multipart type '$type' - provide 'data' or 'path'" ) );
        }
    }

    # NOTE: 10. Auto-suggest encoding if not specified
    if( !$is_multipart && !defined( $encoding ) )
    {
        $entity->effective_type( $type );
        $encoding = $entity->suggest_encoding;
    }

    # NOTE: 11. Set the Content-Type header
    $headers->replace( 'Content-Type' => $ct_obj->as_string );
    $entity->effective_type( $type );

    # NOTE: 12. Set Content-Transfer-Encoding header (single-part only)
    if( !$is_multipart && defined( $encoding ) && CORE::length( $encoding ) )
    {
        $headers->replace( 'Content-Transfer-Encoding' => $encoding );
    }

    # NOTE: 13. Set Content-Disposition header
    if( !$is_multipart && ( defined( $disposition ) || defined( $filename ) ) )
    {
        # Default to 'attachment' when we have a filename but no explicit disposition
        $disposition //= ( defined( $filename ) ? 'attachment' : 'inline' );
        my $cd_obj = Mail::Make::Headers::ContentDisposition->new( $disposition ) ||
            return( $self->pass_error( Mail::Make::Headers::ContentDisposition->error ) );
        if( defined( $filename ) )
        {
            $cd_obj->filename( $filename ) ||
                return( $self->pass_error( $cd_obj->error ) );
        }
        $headers->replace( 'Content-Disposition' => $cd_obj->as_string );
    }

    # NOTE: 14. Set Content-ID header (for inline parts)
    if( defined( $cid ) && CORE::length( $cid ) )
    {
        # Ensure it's wrapped in angle brackets
        $cid = "<${cid}>" unless( $cid =~ /\A<[^>]+>\z/ );
        $headers->replace( 'Content-ID' => $cid );
    }

    # NOTE: 15. Set Content-Description header
    if( defined( $description ) && CORE::length( $description ) )
    {
        $headers->replace( 'Content-Description' => $description );
    }

    return( $entity );
}

# effective_type( [$type_string] )
# Gets or sets the cached effective MIME type string.
sub effective_type
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{effective_type} = shift( @_ );
        return( $self );
    }
    # Lazy: read from headers if not cached
    unless( defined( $self->{effective_type} ) )
    {
        my $ct = $self->{headers}
            ? ( $self->{headers}->content_type // '' )
            : '';
        # Strip parameters - just want type/subtype
        ( $self->{effective_type} ) = ( $ct =~ m{^([^;\s]+)} );
    }
    return( $self->{effective_type} );
}

# encode_body()
# Encodes the body according to the Content-Transfer-Encoding header.
# No-op if already encoded or no encoding header is set.
sub encode_body
{
    my $self = shift( @_ );
    return( $self ) if( $self->{is_encoded} );
    my $enc = lc( $self->headers->content_transfer_encoding // '' );
    return( $self ) unless( CORE::length( $enc ) );
    my $body = $self->{body};
    unless( defined( $body ) )
    {
        return( $self->error( "encode_body: no body to encode." ) );
    }

    # 7bit / 8bit: no transformation needed
    if( $enc ne 'base64' && $enc ne 'quoted-printable' )
    {
        $self->{is_encoded} = 1;
        return( $self );
    }

    # Open a read handle on the source body
    my $from_fh = $body->open || return( $self->pass_error( $body->error ) );

    # Choose the output destination to mirror the source:
    #   Body::File   → encode to a temp file (no large attachment loaded into RAM)
    #   Body::InCore → encode into a scalar buffer in memory
    my $new_body;
    if( $body->is_on_file )
    {
        my $tmp = $self->new_tempfile( open => 1 ) || return( $self->pass_error );
        $tmp->binmode( ':raw' );
        if( $enc eq 'base64' )
        {
            my $encoder = Mail::Make::Stream::Base64->new;
            $encoder->encode( $from_fh => $tmp ) ||
                return( $self->pass_error( $encoder->error ) );
        }
        else
        {
            my $encoder = Mail::Make::Stream::QuotedPrint->new;
            $encoder->encode( $from_fh => $tmp ) ||
                return( $self->pass_error( $encoder->error ) );
        }
        $new_body = Mail::Make::Body::File->new( "$tmp" ) ||
            return( $self->pass_error( Mail::Make::Body::File->error ) );
    }
    else
    {
        my $out = '';
        if( $enc eq 'base64' )
        {
            my $encoder = Mail::Make::Stream::Base64->new;
            $encoder->encode( $from_fh => \$out ) ||
                return( $self->pass_error( $encoder->error ) );
        }
        else
        {
            my $encoder = Mail::Make::Stream::QuotedPrint->new;
            $encoder->encode( $from_fh => \$out ) ||
                return( $self->pass_error( $encoder->error ) );
        }
        $new_body = Mail::Make::Body::InCore->new( $out ) ||
            return( $self->pass_error( Mail::Make::Body::InCore->error ) );
    }

    $self->{body}       = $new_body;
    $self->{is_encoded} = 1;
    return( $self );
}

# epilogue( [$arrayref] )
sub epilogue
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        $self->{epilogue} = ref( $val ) eq 'ARRAY' ? $val : [ $val ];
        return( $self );
    }
    return( $self->{epilogue} );
}

# headers( [$headers_object] )
sub headers
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $h = shift( @_ );
        if( !$self->_is_a( $h => 'Mail::Make::Headers' ) )
        {
            return( $self->error( "headers: argument must be a Mail::Make::Headers object" ) );
        }
        $self->{headers} = $h;
        return( $self );
    }
    unless( defined( $self->{headers} ) )
    {
        $self->{headers} = Mail::Make::Headers->new ||
            return( $self->pass_error( Mail::Make::Headers->error ) );
    }
    return( $self->{headers} );
}

# is_encoded( [$bool] )
sub is_encoded
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{is_encoded} = shift( @_ ) ? 1 : 0;
        return( $self );
    }
    return( $self->{is_encoded} );
}

# is_multipart()
# Returns true if the effective MIME type is multipart/*.
sub is_multipart
{
    my $self = shift( @_ );
    my $type = $self->effective_type // '';
    return( ( $type =~ m{^multipart/}i ) ? 1 : 0 );
}

# is_binary()
# Returns true if the MIME type is not a text type.
sub is_binary
{
    my $self = shift( @_ );
    return( $self->textual_type( $self->effective_type ) ? 0 : 1 );
}

# is_text()
sub is_text { return( !shift->is_binary ); }

# length()
# Returns the exact serialised size in bytes of this entity (headers + CRLF separator +
# encoded body, recursively for multipart).
#
# The calculation mirrors print() exactly - no serialisation buffer is accumulated.
# For singlepart entities the body is encoded first (if not already done) and the
# encoded body's length is obtained via Body::File::length (stat on disk) or 
# Body::InCore::length (in-memory scalar length) without loading the content into a 
# fresh buffer.
# Headers are unavoidably stringified since they are always in memory.
sub length
{
    my $self  = shift( @_ );
    my $total = 0;
    use bytes;

    # Headers + the blank separator line
    my $hdr_str = $self->headers->as_string;
    $total += CORE::length( $hdr_str );
    $total += CORE::length( $CRLF );    # blank line between headers and body

    if( $self->is_multipart )
    {
        my $boundary = $self->_extract_boundary;
        unless( defined( $boundary ) && CORE::length( $boundary ) )
        {
            return( $self->error( "length: cannot measure multipart entity: no boundary." ) );
        }

        # Preamble
        if( @{$self->{preamble}} )
        {
            $total += CORE::length( join( $CRLF, @{$self->{preamble}} ) . $CRLF );
        }

        for my $part ( @{$self->{_parts}} )
        {
            $total += CORE::length( "--${boundary}${CRLF}" );
            my $part_len = $part->length;
            return( $self->pass_error( $part->error ) ) unless( defined( $part_len ) );
            $total += $part_len;
            $total += CORE::length( $CRLF );    # post-part CRLF
        }

        # Closing boundary
        $total += CORE::length( "--${boundary}--${CRLF}" );

        # Epilogue
        if( @{$self->{epilogue}} )
        {
            $total += CORE::length( join( $CRLF, @{$self->{epilogue}} ) . $CRLF );
        }
    }
    elsif( @{$self->{_parts}} )
    {
        # Nested singlepart with sub-parts (e.g. message/rfc822)
        my $need_sep = 0;
        for my $part ( @{$self->{_parts}} )
        {
            $total += CORE::length( "${CRLF}${CRLF}" ) if( $need_sep++ );
            my $part_len = $part->length;
            return( $self->pass_error( $part->error ) ) unless( defined( $part_len ) );
            $total += $part_len;
        }
    }
    else
    {
        # Plain singlepart: encode if not already done, then ask the body for its byte
        # length without reading it into a new buffer.
        unless( defined( $self->{body} ) )
        {
            return( $self->error( "length: no body set on this entity." ) );
        }
        $self->encode_body || return( $self->pass_error );
        my $body_len = $self->{body}->length;
        return( $self->pass_error( $self->{body}->error ) ) unless( defined( $body_len ) );
        $total += $body_len;
    }

    return( $total );
}

# make_boundary()
# Generates a unique boundary string suitable for MIME use.
sub make_boundary { return( Data::UUID->new->create_str ); }

# mime_type()
# Returns just the type/subtype portion (no parameters).
sub mime_type
{
    my $self = shift( @_ );
    my $type = $self->effective_type // '';
    ( my $bare ) = ( $type =~ m{^([^;\s]+)} );
    return( $bare );
}

# parts( [$arrayref_or_list] )
# Gets or sets the list of sub-parts.
sub parts
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $parts = ref( $_[0] ) eq 'ARRAY' ? $_[0] : [ @_ ];
        for my $part ( @$parts )
        {
            unless( $self->_is_a( $part => 'Mail::Make::Entity' ) )
            {
                return( $self->error( "parts: each element must be a Mail::Make::Entity" ) );
            }
        }
        $self->{_parts} = $parts;
        return( $self );
    }
    return( wantarray() ? @{$self->{_parts}} : $self->{_parts} );
}

# preamble( [$arrayref] )
sub preamble
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        $self->{preamble} = ref( $val ) eq 'ARRAY' ? $val : [ $val ];
        return( $self );
    }
    return( $self->{preamble} );
}

# print( [$fh] )
# Serialises the entity to a filehandle.
sub print
{
    my $self = shift( @_ );
    my $fh   = shift( @_ ) ||
        return( $self->error( "No file handle was provided to print the mail entity to." ) );
    unless( $self->_is_glob( $fh ) )
    {
        return( $self->error( "Value provided (", $self->_str_val( $fh // 'undef' ), ") is not a file handle." ) );
    }
    # Headers
    print( $fh $self->headers->as_string ) ||
        return( $self->error( "Cannot write headers: $!" ) );
    # Blank line separating headers from body
    print( $fh $CRLF ) ||
        return( $self->error( "Cannot write header/body separator: $!" ) );
    # Body
    $self->print_body( $fh ) || return( $self->pass_error );
    return( $self );
}

# print_body( [$fh] )
# Serialises the body (or multipart boundaries and sub-parts) to a filehandle.
sub print_body
{
    my $self = shift( @_ );
    my $fh   = shift( @_ ) ||
        return( $self->error( "No file handle was provided to print the mail entity to." ) );
    unless( $self->_is_glob( $fh ) )
    {
        return( $self->error( "Value provided (", $self->_str_val( $fh // 'undef' ), ") is not a file handle." ) );
    }
    if( $self->is_multipart )
    {
        my $boundary = $self->_extract_boundary;
        unless( defined( $boundary ) && CORE::length( $boundary ) )
        {
            return( $self->error( "Cannot serialise multipart entity: no boundary in Content-Type" ) );
        }

        # Preamble
        if( @{$self->{preamble}} )
        {
            print( $fh join( $CRLF, @{$self->{preamble}} ) . $CRLF );
        }
        foreach my $part ( @{$self->{_parts}} )
        {
            print( $fh "--${boundary}${CRLF}" ) ||
                return( $self->error( "Cannot write part boundary: $!" ) );
            $part->print( $fh ) ||
                return( $self->pass_error( $part->error ) );
            print( $fh $CRLF ) ||
                return( $self->error( "Cannot write post-part CRLF: $!" ) );
        }
        print( $fh "--${boundary}--${CRLF}" ) ||
            return( $self->error( "Cannot write closing boundary: $!" ) );
        # Epilogue
        if( @{$self->{epilogue}} )
        {
            print( $fh join( $CRLF, @{$self->{epilogue}} ) . $CRLF );
        }
    }
    elsif( @{$self->{_parts}} )
    {
        # Nested singlepart with sub-parts (e.g. message/rfc822)
        my $need_sep = 0;
        foreach my $part ( @{$self->{_parts}} )
        {
            print( $fh "${CRLF}${CRLF}" ) if( $need_sep++ );
            $part->print( $fh ) || return( $self->pass_error( $part->error ) );
        }
    }
    else
    {
        # Plain single part
        unless( defined( $self->{body} ) )
        {
            return( $self->error( "print_body: no body set on this entity" ) );
        }
        $self->encode_body || return( $self->pass_error );
        my $in_ref = $self->{body}->as_string ||
            return( $self->pass_error( $self->{body}->error ) );
        print( $fh $$in_ref ) ||
            return( $self->error( "Cannot write body: $!" ) );
    }
    return( $self );
}

# stringify()
# Alias for as_string.
sub stringify { return( shift->as_string ); }

sub stringify_ref { return( shift->as_string_ref ); }

# stringify_body()
# Alias for body_as_string.
sub stringify_body { return( shift->body_as_string ); }

# stringify_header()
sub stringify_header { return( shift->headers->as_string ); }

# suggest_encoding()
# Returns a suitable Content-Transfer-Encoding for this entity's MIME type.
# Rules:
#   multipart/* / message/*  -> '' (no encoding)
#   text/*                   -> quoted-printable
#   everything else          -> base64
sub suggest_encoding
{
    my $self = shift( @_ );
    my $type = $self->effective_type // '';
    # Strip any parameters
    ( $type ) = ( $type =~ m{^([^;\s]+)} );
    $type = lc( $type );
    return( '' ) if( $type =~ m{^multipart/} );
    return( '' ) if( $type =~ m{^message/} );
    return( 'quoted-printable' ) if( $type =~ m{^text/} );
    return( 'base64' );
}

# textual_type( $mime_type )
# Returns true if the given MIME type is a text or message type.
sub textual_type
{
    my( $self, $type ) = @_;
    return(0) unless( defined( $type ) && CORE::length( $type ) );
    return( ( $type =~ m{^(text|message)(/|\z)}i ) ? 1 : 0 );
}

# make_multipart( [ $subtype [, %opts] ] )
# Promotes a single-part entity to multipart by wrapping the existing body in a child
# entity and replacing the Content-Type with multipart/$subtype.
sub make_multipart
{
    my $self    = shift( @_ );
    my $subtype = shift( @_ ) // 'mixed';
    $subtype    = lc( $subtype );
    return( $self ) if( $self->is_multipart );
    my $new_type = "multipart/${subtype}";
    my $boundary = $self->make_boundary;
    my $h        = $self->headers;
    if( $h )
    {
        my $ct_obj = Mail::Make::Headers::ContentType->new( $new_type ) ||
            return( $self->pass_error( Mail::Make::Headers::ContentType->error ) );
        $ct_obj->boundary( $boundary ) || return( $self->pass_error( $ct_obj->error ) );
        $h->set( 'Content-Type', "$ct_obj" ) || return( $self->pass_error( $h->error ) );
        $h->remove( 'Content-Transfer-Encoding' );
    }
    if( $self->body )
    {
        my $old_type = $self->effective_type;
        my $child = Mail::Make::Entity->new ||
            return( $self->pass_error );
        my $child_h = Mail::Make::Headers->new ||
            return( $self->pass_error( Mail::Make::Headers->error ) );
        my $orig_ct = $h ? $h->get( 'Content-Type' ) : undef;
        $child_h->set( 'Content-Type', $orig_ct ) if( defined( $orig_ct ) );
        $child->headers( $child_h );
        $child->body( $self->body );
        $child->effective_type( $old_type );
        $self->{body} = undef;
        push( @{$self->{_parts}}, $child );
    }
    $self->effective_type( $new_type );
    return( $self );
}

# purge()
# Recursively releases body content.
sub purge
{
    my $self = shift( @_ );
    if( my $body = $self->body )
    {
        $body->purge;
        $self->{body} = undef;
    }
    for my $part ( @{$self->{_parts}} )
    {
        $part->purge;
    }
    return( $self );
}

# _extract_boundary()
# Pulls the boundary parameter out of the Content-Type header string.
sub _extract_boundary
{
    my $self = shift( @_ );
    # content_type() returns a typed object; we need the raw string.
    my $ct   = $self->headers->get( 'Content-Type' ) // '';
    return( undef ) unless( CORE::length( $ct ) );
    # Match boundary="..." or boundary=...
    if( $ct =~ /;\s*boundary=(?:"([^"]+)"|([^;\s]+))/i )
    {
        return( $1 // $2 );
    }
    return( undef );
}

# NOTE: STORABLE support
sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw   { CORE::return( CORE::shift->THAW( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Entity - MIME Part Builder for Mail::Make

=head1 SYNOPSIS

    use Mail::Make::Entity;

    # Build a text/plain part
    my $part = Mail::Make::Entity->build(
        type     => 'text/plain',
        charset  => 'utf-8',
        data     => "Hello, World!\n",
    ) || die( Mail::Make::Entity->error );

    # Build a multipart/related container
    my $container = Mail::Make::Entity->build(
        type => 'multipart/related',
    ) || die( Mail::Make::Entity->error );

    # Add an inline image with a comma in the filename
    my $img = Mail::Make::Entity->build(
        type        => 'image/png',
        path        => '/var/www/images/Yamato,Inc-Logo.png',
        disposition => 'inline',
        cid         => 'logo@yamato-inc',
    ) || die( Mail::Make::Entity->error );
    $container->add_part( $img );

    print $container->as_string;

=head1 VERSION

    v0.4.0

=head1 DESCRIPTION

The core MIME part object for L<Mail::Make>. Represents a single MIME entity (either a leaf part with a body, or a multipart container with sub-parts).

The C<build()> class method is the primary factory. It performs strict input validation, automatic RFC 2231 encoding of filenames with special characters, and deterministic Content-Transfer-Encoding selection. It never silently corrupts a message - all invalid inputs produce an explicit error.

=head1 CLASS METHOD

=head2 build( %params )

Builds and returns a new C<Mail::Make::Entity>. Parameters:

=over 4

=item type

MIME C<type/subtype> string. Default: C<text/plain>.

=item charset

Charset for C<text/*> parts. Validated via L<Encode>. Default: C<utf-8> for text/* parts if not specified.

=item encoding

Content-Transfer-Encoding. One of C<7bit>, C<8bit>, C<binary>, C<base64>, C<quoted-printable>. Auto-suggested if omitted. C<binary> is rejected for C<text/*> types.

=item disposition

C<inline> or C<attachment>. Defaults to C<attachment> when a filename is present.

=item filename

Filename for C<Content-Type: name=> and C<Content-Disposition: filename=>. Values containing commas or other RFC 2045 specials are automatically RFC 2231 encoded. If not provided and C<path> is given, the basename is used.

=item cid

Content-ID for inline parts (e.g. embedded images). Angle brackets are added automatically if missing.

=item data

Scalar body content (for in-memory bodies).

=item path

File path (for on-disk bodies). The file must exist and be readable.

=item boundary

Boundary string for C<multipart/*> types. Validated against RFC 2046 allowed characters. Auto-generated if omitted.

=item description

Optional C<Content-Description> value.

=back

Returns C<undef> and sets an error on failure.

=head1 METHODS

=head2 add_part( $entity )

Appends a C<Mail::Make::Entity> as a sub-part of this entity.

=head2 as_string

Returns the serialised entity (headers + blank line + encoded body) as a plain string. This is the form expected by C<print>, string interpolation, and most downstream consumers.

For large messages where avoiding a string copy matters, use L</as_string_ref> instead.

=head2 as_string_ref

Returns the serialised entity as a B<scalar reference>. No string copy is made: the same buffer used during serialisation is returned directly. Dereference with C<$$ref> when a plain string is needed.

=head2 body( [$body] )

Gets or sets the L<Mail::Make::Body>-derived body object.

=head2 body_as_string

Returns a scalar reference to the (encoded) body content.

=head2 effective_type( [$type] )

Gets or sets the cached MIME C<type/subtype> string.

=head2 encode_body

Encodes the body according to the C<Content-Transfer-Encoding> header. No-op if already encoded.

=head2 epilogue( [$arrayref] )

Gets or sets the epilogue lines (appended after the closing boundary).

=head2 headers( [$headers] )

Gets or sets the L<Mail::Make::Headers> collection.

=head2 is_binary

Returns true if the effective MIME type is not a text type.

=head2 is_encoded( [$bool] )

Gets or sets the encoded flag.

=head2 is_multipart

Returns true if the effective MIME type is C<multipart/*>.

=head2 is_text

Returns true if the effective MIME type is a text type.

=head2 length

    my $bytes = $entity->length;

Returns the exact serialised size in bytes of this entity: headers, the blank CRLF separator, and the encoded body (recursively for multipart entities, including all boundary lines, preamble, and epilogue).

The calculation mirrors L</print> exactly without accumulating a serialisation buffer. For singlepart entities the body is encoded first via L</encode_body> (if not already done), then L<Mail::Make::Body::File/length> (a C<stat> call) or L<Mail::Make::Body::InCore/length> (a scalar byte count) is used to obtain the encoded body size - the content is never loaded into a second buffer.
Headers are stringified since they are always held in memory.

Returns C<undef> and sets C<error()> on failure.

=head2 make_boundary

Generates a unique boundary string.

=head2 mime_type

Returns the bare MIME type (without parameters).

=head2 parts( [$arrayref | @list] )

Gets or sets the list of sub-part entities.

=head2 preamble( [$arrayref] )

Gets or sets the preamble lines (before the first boundary).

=head2 print( [$fh] )

Serialises the entity to a filehandle.

=head2 print_body( [$fh] )

Serialises only the body portion to a filehandle.

=head2 stringify

Alias for L</as_string>.

=head2 stringify_ref

Alias for L</as_string_ref>.

=head2 stringify_body

Alias for L</body_as_string>.

=head2 stringify_header

Returns the header block as a string.

=head2 suggest_encoding

Returns the recommended Content-Transfer-Encoding for this entity's MIME type.

=head2 make_multipart( [$subtype] )

    $entity->make_multipart( 'mixed' );
    $entity->make_multipart( 'alternative' );

Promotes a single-part entity into a C<multipart/$subtype> container in-place.
The default subtype is C<mixed> if none is supplied.

If the entity is already multipart, the method returns C<$self> immediately without making any changes.

The existing body (if any) is wrapped into a child entity that preserves the original C<Content-Type>, and that child becomes the first part of the new container. A fresh MIME boundary is generated via L</make_boundary>.

The outer container's C<Content-Transfer-Encoding> header is removed, as transfer encoding applies to individual parts rather than the container itself.

Returns C<$self> on success, C<undef> on error.

=head2 purge

    $entity->purge;

Recursively releases all body content held by this entity and its child parts.

For each node in the entity tree, the body object's own C<purge()> method is called (which may, for example, delete a temporary file backing a L<Mail::Make::Body::File>), then the reference is cleared.

Returns C<$self>.

=head2 textual_type( $mime_type )

Returns true if the given MIME type is C<text/*> or C<message/*>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

RFC 2045, RFC 2046, RFC 2047, RFC 2231

L<Mail::Make>, L<Mail::Make::Headers>, L<Mail::Make::Body>, L<Mail::Make::Stream::Base64>, L<Mail::Make::Stream::QuotedPrint>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
