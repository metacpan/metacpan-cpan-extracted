##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Entity.pm
## Version v0.1.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/04/19
## Modified 2022/08/06
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Entity;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS $BOUNDARY_DELIMITER $BOM2ENC $ENC2BOM $BOM_RE 
                 $BOM_MAX_LENGTH $DEFAULT_MIME_TYPE );
    use Data::UUID;
    use HTTP::Promise::Exception;
    use HTTP::Promise::Headers;
    use HTTP::Promise::Body;
    use Module::Generic::HeaderValue;
    use Nice::Try;
    use Symbol;
    use URI::Escape::XS ();
    use constant CRLF => "\015\012";
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
    our $BOUNDARY_DELIMITER = "\015\012";
    our $DEFAULT_MIME_TYPE = 'application/octet-stream';
    our $VERSION = 'v0.1.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{body}           = undef;
    # Sie minimum from which compression is enabled, if mime type is suitable.
    # Defaults to 200Kb
    $self->{compression_min}= 204800;
    $self->{effective_type} = undef;
    $self->{epilogue}       = undef;
    $self->{ext_vary}       = undef;
    $self->{headers}        = undef;
    $self->{is_encoded}     = 0;
    $self->{output_dir}     = undef;
    $self->{preamble}       = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_parts} = [];
    return( $self );
}

sub add_part
{
    my $self = shift( @_ );
    my( $part, $index ) = @_;
    return( $self->error( "Part provided is not a HTTP::Promise::Entity object." ) ) if( !$self->_is_a( $part => 'HTTP::Promise::Entity' ) );
    my $parts = $self->_parts;
    $index = -1 if( !defined( $index ) );
    $index = $parts->size + 2 + $index if( $index < 0 );
    $parts->splice( $index, 0, $part );
    return( $part );
}

sub as_form_data
{
    my $self = shift( @_ );
    my $type = $self->headers->type;
    return(0) unless( lc( $type ) eq 'multipart/form-data' );
    $self->_load_class( 'HTTP::Promise::Body::Form::Data' ) || return( $self->pass_error );
    my $form = HTTP::Promise::Body::Form::Data->new;
    $form->debug( $self->debug );
    my $parts = $self->parts;
    # nothing to do
    return( $form ) if( $parts->is_empty );
    foreach my $part ( @$parts )
    {
        my $headers = $part->headers;
        my $body = $part->body;
        my $name;
        my $dispo = $headers->content_disposition;
        next unless( $dispo );
        my $cd = $headers->new_field( 'Content-Disposition' => "$dispo" );
        return( $self->pass_error( $headers->error ) ) if( !defined( $cd ) );
        $name = $cd->name;
        next if( !defined( $name ) || !length( "$name" ) );
        my $encodings = $headers->content_encoding;
        if( $part->is_encoded && $encodings )
        {
            $body = $part->decode_body( encoding => $encodings ) ||
                return( $self->pass_error( $part->error ) );
        }
        
        my $field = $form->new_field(
            name => $name,
            body => $body,
            headers => $headers,
        );
        return( $self->pass_error( $form->error ) ) if( !defined( $field ) );
        
        if( exists( $form->{ $name } ) )
        {
            $form->{ $name } = [$form->{ $name }];
            push( @{$form->{ $name }}, $field );
        }
        else
        {
            $form->{ $name } = $field;
        }
    }
    return( $form );
}

sub as_string
{
    my $self = shift( @_ );
    my $eol = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{eol} = $eol if( defined( $eol ) );
    my $output = $self->new_scalar;
    # Because of an edge case where open with :binmode(utf-8) layer does not decode properly \x{FF}
    # but Encode::decode( 'utf-8', $buff ) does, and since the body is loaded into a string
    # anyway, we first read the data as raw and then decode it with Encode
    my $binmode;
    if( exists( $opts->{binmode} ) && 
        length( $opts->{binmode} ) && 
        lc( substr( $opts->{binmode}, 0, 3 ) ) eq 'utf' )
    {
        $binmode = delete( $opts->{binmode} );
        $opts->{binmode} = 'raw';
    }
    my $fh = $output->open( '>' ) || return( $self->pass_error( $output->error ) );
    # $self->print( $fh, ( scalar( keys( %$opts ) ) ? $opts : () ) ) || return( $self->pass_error );
    $self->print( $fh, ( scalar( keys( %$opts ) ) ? $opts : () ) ) || return( $self->pass_error );
    $fh->close;
    if( defined( $binmode ) )
    {
        $self->_load_class( 'Encode' ) || return( $self->pass_error );
        try
        {
            $$output = Encode::decode( $binmode, $$output, ( Encode::FB_DEFAULT | Encode::LEAVE_SRC ) );
        }
        catch( $e )
        {
            return( $self->error( "Error decoding body content with character encoding '$binmode': $e" ) );
        }
    }
    return( $output );
}

sub attach
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    $self->make_multipart || return( $self->pass_error );
    my $part = $class->build( @_, top => 0 ) ||
        return( $self->pass_error( $class->error ) );
    return( $self->add_part( $part ) );
}

sub body { return( shift->_set_get_object_without_init( 'body', [qw( HTTP::Promise::Body HTTP::Promise::Body::Form )], @_ ) ); }

sub body_as_array
{
    my $self = shift( @_ );
    my $eol  = @_ ? shift( @_ ) : CRLF; 
    return( $self->error( "You cannot use the method body() to set the encoded contents." ) ) if( scalar( @_ ) );
    my $output = $self->new_scalar;
    my $fh = $output->open( '>' ) ||
        return( $self->pass_error( $output->error ) );
    $self->print_body( $fh ) || return( $self->pass_error );
    $fh->close;
    my $ary = $output->split( qr/\015?\012/ );
    for( @$ary )
    {
        $_ .= $eol;
    }
    return( $ary );
}

sub body_as_string
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $output = $self->new_scalar;
    # Because of an edge case where open with :binmode(utf-8) layer does not decode properly \x{FF}
    # but Encode::decode( 'utf-8', $buff ) does, and since the body is loaded into a string
    # anyway, we first read the data as raw and then decode it with Encode
    my $binmode;
    if( exists( $opts->{binmode} ) && 
        length( $opts->{binmode} ) && 
        lc( substr( $opts->{binmode}, 0, 3 ) ) eq 'utf' )
    {
        $binmode = delete( $opts->{binmode} );
        $opts->{binmode} = 'raw';
    }
    my $fh = $output->open( '>' ) ||
        return( $self->pass_error( $output->error ) );
    $self->print_body( $fh, ( scalar( keys( %$opts ) ) ? $opts : () ) ) || return( $self->pass_error );
    $fh->close;
    if( defined( $binmode ) )
    {
        $self->_load_class( 'Encode' ) || return( $self->pass_error );
        try
        {
            $$output = Encode::decode( $binmode, $$output, ( Encode::FB_DEFAULT | Encode::LEAVE_SRC ) );
        }
        catch( $e )
        {
            return( $self->error( "Error decoding body content with character encoding '$binmode': $e" ) );
        }
    }
    return( $output );
}

sub build
{
    my $self = shift( @_ );
    my( $opts, $order ) = $self->_get_args_as_hash( @_ );
    my( $field, $filename, $boundary );
    my $type = delete( $opts->{type} ) || 'text/plain';
    my $charset = delete( $opts->{charset} );
    my $is_multipart = ( $type =~ m{^multipart/}i ? 1 : 0 );
    my $encoding     = delete( $opts->{encoding} ) || '';
    my $desc         = delete( $opts->{description} );
    my $top          = exists( $opts->{top} ) ? delete( $opts->{top} ) : 1;
    # my $disposition  = $opts->{disposition} || 'inline';
    # inline, attachment or multipart/form-data
    # Ref: <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition>
    # We could, technically, default to 'inline' and end up with something like:
    # Content-Disposition: inline; filename=foo.txt
    # But, even though it would be ok for mail, for HTTP, it would be weird, so, no default
    # and instead if a path is provided, but no Content-Disposition, we fall back to 'attachment'
    my $disposition  = delete( $opts->{disposition} );
    my $id           = delete( $opts->{id} );
    my $debug        = delete( $opts->{debug} ) // 0;
    # Ensure this is an object
    my $new = $self->new( debug => $debug ) || return( $self->pass_error );
    my $headers = HTTP::Promise::Headers->new( { debug => $self->debug } ) ||
        return( $self->pass_error( HTTP::Promise::Headers->error ) );
    $new->headers( $headers );
    
    # Either data or path
    my $data = delete( $opts->{data} );
    my $path = delete( $opts->{path} );
    my( $path_fname ) = ( ( $path || '' ) =~ m{([^/]+)\Z} );
    $filename = ( exists( $opts->{filename} ) ? delete( $opts->{filename} ) : $path_fname );
    $filename = undef() if( defined( $filename ) and $filename eq '' );
    my $filename_utf8;
    if( defined( $filename ) && length( $filename ) && $filename =~ /[^\w\.]+/ )
    {
        $filename_utf8 = $new->headers->encode_filename( $filename );
    }
    if( defined( $encoding ) && 
        $type =~ m{^(multipart/|message/(rfc822|partial|external-body|delivery-status|disposition-notification|feedback-report|http)$)}i )
    {
        undef( $encoding );
    }
    
    # Multipart or not? Do sanity check and fixup:
    if( $is_multipart )
    {
        # Get any supplied boundary, and check it:
        if( defined( $boundary = delete( $opts->{boundary} ) ) )
        {
            if( !length( $boundary ) )
            {
                warn( "Empty string not a legal boundary: I am ignoring it\n" ) if( $self->_warnings_is_enabled );
                $boundary = undef();
            }
            elsif( $boundary =~ m{[^0-9a-zA-Z_\'\(\)\+\,\.\/\:\=\?\- ]} )
            {
                warn( "Boundary ignored: illegal characters ($boundary)\n" ) if( $self->_warnings_is_enabled );
                $boundary = undef();
            }
        }
        # If we have to roll our own boundary, do so:
        $boundary = $new->make_boundary if( !defined( $boundary ) );
    }
    # Or this is a single part
    else
    {
        # Create body:
        if( defined( $path ) && length( $path ) )
        {
            my $f = HTTP::Promise::Body::File->new( $path ) ||
                return( $self->pass_error( HTTP::Promise::Body::File->error ) );
            $new->body( $f ) || return( $self->pass_error );
            # Set the Content-Disposition to 'attachment' by default if not set
            # $disposition = 'attachment' if( !defined( $disposition ) || !length( $disposition ) );
        }
        elsif( defined( $data ) && length( $data ) )
        {
            my $s = HTTP::Promise::Body::InCore->new( $data ) ||
                return( $self->pass_error( HTTP::Promise::Body::InCore->error ) );
            $new->body( $s ) || return( $self->pass_error );
        }
        else
        {
            return( $self->error( "Unable to build HTTP entity: no body, and not multipart" ) );
        }
        # $self->body->binmode(1) unless( $self->textual_type( $type ) );
    }
    
    my $ct = Module::Generic::HeaderValue->new_from_header( $type );
    return( $self->pass_error( Module::Generic::HeaderValue->error ) ) if( !defined( $ct ) );
    $ct->param( charset => $charset ) if( $charset );
    if( defined( $filename_utf8 ) )
    {
        $ct->param( 'name*' => sprintf( "UTF-8''%s", $filename_utf8 ) );
    }
    elsif( defined( $filename ) )
    {
        $ct->param( name => $filename );
    }
    $ct->param( boundary => $boundary ) if( defined( $boundary ) );
    $headers->replace( 'Content-Type' => "$ct" );
    
    if( defined( $encoding ) && lc( $encoding ) eq 'suggest' )
    {
        $encoding = $new->suggest_encoding;
    }
    
    # unless( $is_multipart )
    if( !$is_multipart && ( defined( $disposition ) || defined( $filename ) ) )
    {
        $disposition = 'attachment' if( !defined( $disposition ) );
        $field = Module::Generic::HeaderValue->new_from_header( ( defined( $disposition ) ? $disposition : () ) );
        return( $self->pass_error( Module::Generic::HeaderValue->error ) ) if( !defined( $field ) );
        if( defined( $filename_utf8 ) )
        {
            $field->param( 'filename*' => sprintf( "UTF-8''%s", $filename_utf8 ) );
        }
        elsif( defined( $filename ) )
        {
            $field->param( filename => $filename );
        }
        $headers->replace( 'Content-disposition', "$field" );
    }
    $headers->replace( 'Content-encoding', $encoding ) if( defined( $encoding ) && length( $encoding ) );
    if( defined( $desc ) && length( $desc ) )
    {
        warn( "There is no Content-Description in HTTP protocole\n" ) if( $self->_warnings_is_enabled );
    }

    if( defined( $id ) )
    {
        warn( "There is no Content-ID for HTTP multipart data\n" ) if( $self->_warnings_is_enabled );
    }
    
    foreach( @$order )
    {
        # Maybe it has been removed since then? So that only headers remain
        next if( !exists( $opts->{ $_ } ) );
        # Value is undef -> remove the header, if any.
        if( !defined( $opts->{ $_ } ) )
        {
            $headers->remove_header( $_ );
        }
        elsif( length( $opts->{ $_ } ) )
        {
            $headers->delete( $_ );
            foreach my $val ( $self->_is_array( $opts->{ $_ } ) ? @{$opts->{ $_ }} : ( $opts->{ $_ } ) )
            {
                $headers->add( $_ => $val );
            }
        }
    }
    return( $new );
}

sub clone
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{clone_message} //= 1;
    my $addr = $self->_refaddr( $self );
    my $new = $self->new;
    my( $new_headers, $new_body, $new_parts );
    my $headers = $self->headers;
    my $body = $self->body;
    $new_headers = $headers->clone if( defined( $headers ) );
    $new_body = $body->clone if( defined( $body ) );
    my $parts = $self->parts;
    if( !$parts->is_empty )
    {
        $new_parts = $self->new_array;
        # Each part is an HTTP::Promise::Entity
        for( @$parts )
        {
            my $paddr = $self->_refaddr( $_ );
            # This would be weird, but let's do it anyway
            if( $paddr eq $addr )
            {
                $new_parts->push( $new );
                next;
            }
            my $new_part = $_->clone;
            $new_parts->push( $new_part );
        }
        $new->parts( $new_parts );
    }
    $new->headers( $new_headers ) if( defined( $new_headers ) );
    $new->body( $new_body ) if( defined( $new_body ) );
    $new->name( $self->name ) if( $self->name );
    $new->is_encoded( $self->is_encoded );
    $new->debug( $self->debug );
    $new->preamble( $self->preamble->clone );
    $new->epilogue( $self->epilogue->clone );
    $new->compression_min( $self->compression_min );
    $new->effective_type( $self->effective_type );
    my $msg;
    if( ( $msg = $self->http_message ) && $opts->{clone_message} )
    {
        # To prevent endless recursion
        my $new_msg = $msg->clone( clone_entity => 0 );
        $new_msg->headers( $new_headers );
        $new_msg->entity( $new );
        $new->http_message( $new_msg );
    }
    return( $new );
}

sub compression_min { return( shift->_set_get_number( 'compression_min', @_ ) ); }

# NOTE: an outdated method since nowadays everyone use UTF-8
# This is not intended to be a generic method, but instead to be used specifically for this entity
# content parameter can be provided to avoid reading from the body if we already have data handy.
sub content_charset
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $headers = $self->headers;
    # If parameter content_type_charset is set to false, this means it was just tried and 
    # we should not try it again.
    if( ( my $charset = $headers->content_type_charset ) && 
        ( !exists( $opts->{content_type_charset} ) || $opts->{content_type_charset} ) )
    {
        return( $charset );
    }

    $self->_load_class( 'Encode' ) || return( $self->pass_error );
    unless( defined( $BOM2ENC ) && scalar( %$BOM2ENC ) )
    {
        # Credits: Matthew Lawrence (File::BOM)
        our $BOM2ENC = +{
            map{ Encode::encode( $_, "\x{feff}" ) => $_ } qw(
                UTF-8
                UTF-16BE
                UTF-16LE
                UTF-32BE
                UTF-32LE
            )
        };

        our $ENC2BOM = +{
            reverse( %$BOM2ENC ),
            map{ $_ => Encode::encode( $_, "\x{feff}" ) } qw(
                UCS-2
                iso-10646-1
                utf8
            )
        };
        my @boms = sort{ length( $b ) <=> length( $a ) } keys( %$BOM2ENC );
        our $BOM_MAX_LENGTH = length( $boms[0] );
        {
            local $" = '|';
            our $BOM_RE = qr/@boms/;
        }
    }
    
    # time to start guessing
    # If called from decoded_content, kind of pointless to call decoded_content again
    my $cref;
    if( exists( $opts->{content} ) && length( $opts->{content} ) )
    {
        return( $self->error( "Unsupported data type (", ref( $opts->{content} ), ")." ) ) if( ref( $opts->{content} ) && !$self->_is_scalar( $opts->{content} ) );
        $cref = $self->_is_scalar( $opts->{content} ) ? $opts->{content} : \$opts->{content};
    }
    else
    {
        my $body = $self->body || return( '' );
        my $io = $body->open( '<', { binmode => 'raw' } ) ||
            return( $self->pass_error( $body->error ) );
        my $buff;
        my $bytes = $io->read( $buff, 4096 );
        return( $self->pass_error( $io->error ) ) if( !defined( $bytes ) );
        return( '' ) if( !$bytes );
        $cref = \$buff;
    }
    
    # Is there a Byte Order Mark?
    if( $$cref =~ /^($BOM_RE)/ )
    {
        my $bom = $1;
        return( $BOM2ENC->{ $bom } );
    }

    # Unicode BOM
    return( 'UTF-8' )    if( $$cref =~ /^\xEF\xBB\xBF/ );
    return( 'UTF-32LE' ) if( $$cref =~ /^\xFF\xFE\x00\x00/ );
    return( 'UTF-32BE' ) if( $$cref =~ /^\x00\x00\xFE\xFF/ );
    return( 'UTF-16LE' ) if( $$cref =~ /^\xFF\xFE/ );
    return( 'UTF-16BE' ) if( $$cref =~ /^\xFE\xFF/ );

    if( $headers->content_is_xml )
    {
        # http://www.w3.org/TR/2006/REC-xml-20060816/#sec-guessing
        # XML entity not accompanied by external encoding information and not
        # in UTF-8 or UTF-16 encoding must begin with an XML encoding declaration,
        # in which the first characters must be '<?xml'
        return( 'UTF-32BE' ) if( $$cref =~ /^\x00\x00\x00</ );
        return( 'UTF-32LE' ) if( $$cref =~ /^<\x00\x00\x00/ );
        return( 'UTF-16BE' ) if( $$cref =~ /^(?:\x00\s)*\x00</ );
        return( 'UTF-16LE' ) if( $$cref =~ /^(?:\s\x00)*<\x00/ );
        if( $$cref =~ /^[[:blank:]\h]*(<\?xml[^\x00]*?\?>)/ )
        {
            if( $1 =~ /[[:blank:]\h\v]encoding[[:blank:]\h\v]*=[[:blank:]\h\v]*(["'])(.*?)\1/ )
            {
                my $enc = $2;
                $enc =~ s/^[[:blank:]\h]+//;
                $enc =~ s/[[:blank:]\h]+\z//;
                return( $enc ) if( $enc );
            }
        }
        return( 'UTF-8' );
    }
    elsif( $headers->content_is_text )
    {
        my $encoding = $self->guess_character_encoding( content => $cref, object => 1 );
        return( ref( $encoding ) ? $encoding->mime_name : $encoding ) if( $encoding );
    }
    elsif( $headers->content_type eq 'application/json' )
    {
        # RFC 4627, ch 3
        return( 'UTF-32BE' ) if( $$cref =~ /^\x00\x00\x00./s );
        return( 'UTF-32LE' ) if( $$cref =~ /^.\x00\x00\x00/s );
        return( 'UTF-16BE' ) if( $$cref =~ /^\x00.\x00./s );
        return( 'UTF-16LE' ) if( $$cref =~ /^.\x00.\x00/s );
        return( 'UTF-8' );
    }
    # if( $headers->content_type =~ /^text\// && $self->_load_class( 'Encode' ) )
    if( $headers->content_type =~ /^text\// )
    {
        if( length( $$cref ) )
        {
            return( 'US-ASCII' ) unless( $$cref =~ /[\x80-\xFF]/ );
            try
            {
                Encode::decode_utf8( $$cref, ( Encode::FB_CROAK | Encode::LEAVE_SRC ) );
                return( 'UTF-8' );
            }
            catch( $e )
            {
                return( $self->error( "Failed to decode utf8 content: $e" ) );
            }
            # return( 'ISO-8859-1' );
        }
    }
    return( '' );
}

sub decode_body
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "No decoding string or array has been provided." ) ) if( !defined( $this ) );
    return( $self->error( "Bad argument provided. decode_body() accepts only either an array of encodings or a string or something that stringifies." ) ) if( !$self->_is_array( $this ) && ( ref( $this ) && !overload::Method( $this => '""' ) ) );
    my $encodings = $self->_is_array( $this ) ? $this : [split( /[[:blank:]\h]*,[[:blank:]\h]*/, "${this}" )];
    $opts->{replace} //= 1;
    $opts->{raise_error} //= 0;
    $self->_load_class( 'HTTP::Promise::Stream' ) || return( $self->error );
    my $body = $self->body;
    warn( "No encoding were provided to decode the HTTP body.\n" ) if( !scalar( @$encodings ) && warnings::enabled( ref( $self ) ) );
    # Nothing to do
    return( $self ) if( !$body || !scalar( @$encodings ) );
    # Parameters to be passed. Transparent set to 0 allow for failure
    my $enc2params =
    {
    bzip2   => { Transparent => 0 },
    deflate => { Transparent => 0 },
    inflate => { Transparent => 0 },
    gzip    => { Transparent => 0 },
    lzf     => { Transparent => 0 },
    lzip    => { Transparent => 0 },
    lzma    => { Transparent => 0 },
    lzop    => { Transparent => 0 },
    rawdeflate => { Transparent => 0 },
    rawinflate => { Transparent => 0 },
    xz      => { Transparent => 0 },
    zstd    => { Transparent => 0 },
    };
    
    if( $body->isa( 'HTTP::Promise::Body::File' ) )
    {
        my $f = $body;
        if( $f->is_empty )
        {
            warn( "HTTP Body file '$f' is empty, so there is nothing to decode\n" ) if( warnings::enabled( ref( $self ) ) );
            return( $self );
        }
        my $ext = $f->extension;
        my $ext_vary = $self->ext_vary;
        my $ext_parts;
        if( $ext_vary )
        {
            $ext_parts = $f->extensions;
        }
        
        foreach my $enc ( @$encodings )
        {
            next if( $enc eq 'identity' || $enc eq 'none' );
            my $params = {};
            $params = $enc2params->{ $enc } if( exists( $enc2params->{ $enc } ) );
            my $s = HTTP::Promise::Stream->new( $f,
                decoding => $enc,
                fatal => $opts->{raise_error}
            ) || return( $self->pass_error( HTTP::Promise::Stream->error ) );
            my $ext_deb = $s->encoding2suffix( $enc )->first;
            my $ext_enc;
            if( $ext_vary && 
                ( $ext_enc = $s->encoding2suffix( $enc )->first ) && 
                $ext_parts->[-1] eq $ext_enc )
            {
                pop( @$ext_parts );
                $ext = join( '.', @$ext_parts );
            }
            my $tempfile = $self->new_tempfile( extension => $ext );
            # my $len = $s->read( $tempfile, ( exists( $params->{ $enc } ) ? %{$params->{ $enc }} : () ) );
            my $len = $s->read( $tempfile, $params );
            if( !defined( $len ) )
            {
                if( $enc eq 'deflate' || $enc eq 'inflate' )
                {
                    # Try again, but using rawinflate this time
                    if( $s->error->message =~ /Header Error: CRC mismatch/ )
                    {
                        $enc = "raw${enc}";
                        $params = {};
                        $params = $enc2params->{ $enc } if( exists( $enc2params->{ $enc } ) );
                        my $s = HTTP::Promise::Stream->new( $f,
                            decoding => $enc,
                            fatal => $opts->{raise_error}
                        ) || return( $self->pass_error( HTTP::Promise::Stream->error ) );
                        # $len = $s->read( $tempfile, ( exists( $params->{ $enc } ) ? ( $params->{ $enc } ) : () ) );
                        $len = $s->read( $tempfile, $params );
                        return( $self->pass_error( $s->error ) ) if( !defined( $len ) );
                    }
                    else
                    {
                        return( $self->pass_error( $s->error ) )
                    }
                }
                else
                {
                    return( $self->pass_error( $s->error ) );
                }
            }
            return( $self->error( "The decoding pass on the HTTP body file source '$f' to target '$tempfile' with encoding '$enc' resulted in 0 byte decoded!" ) ) if( !$len );
            $f = $tempfile;
        }
        $body = HTTP::Promise::Body::File->new( $f ) ||
            return( $self->pass_error( HTTP::Promise::Body::File->error ) );
        if( $opts->{replace} )
        {
            $self->body( $body );
            $self->is_decoded(1);
        }
    }
    elsif( $body->isa( 'HTTP::Promise::Body::Scalar' ) )
    {
        my $temp = $body;
        if( $body->is_empty )
        {
            warn( "HTTP Body in memory is empty, so there is nothing to decode\n" ) if( warnings::enabled( ref( $self ) ) );
            return( $self );
        }
        
        foreach my $enc ( @$encodings )
        {
            next if( $enc eq 'identity' || $enc eq 'none' );
            my $params = {};
            $params = $enc2params->{ $enc } if( exists( $enc2params->{ $enc } ) );
            my $s = HTTP::Promise::Stream->new( $temp,
                decoding => $enc,
                fatal => $opts->{raise_error},
                debug => $self->debug
            ) || return( $self->pass_error( HTTP::Promise::Stream->error ) );
            my $decoded = $self->new_scalar;
            # my $len = $s->read( $decoded, ( exists( $params->{ $enc } ) ? ( $params->{ $enc } ) : () ) );
            my $len = $s->read( $decoded, $params );
            # my $len = $s->read( $decoded );
            # return( $self->pass_error( $s->error ) ) if( !defined( $len ) );
            if( !defined( $len ) )
            {
                if( $enc eq 'deflate' || $enc eq 'inflate' )
                {
                    # Try again, but using rawinflate this time
                    if( $s->error->message =~ /Header Error: CRC mismatch/ )
                    {
                        $enc = "raw${enc}";
                        $params = {};
                        $params = $enc2params->{ $enc } if( exists( $enc2params->{ $enc } ) );
                        my $s = HTTP::Promise::Stream->new( $temp,
                            decoding => $enc,
                            fatal => $opts->{raise_error},
                            debug => $self->debug
                        ) || return( $self->pass_error( HTTP::Promise::Stream->error ) );
                        # $len = $s->read( $decoded, ( exists( $params->{ $enc } ) ? $params->{ $enc } : () ) );
                        $len = $s->read( $decoded, $params );
                        return( $self->pass_error( $s->error ) ) if( !defined( $len ) );
                    }
                    else
                    {
                        return( $self->pass_error( $s->error ) )
                    }
                }
                else
                {
                    return( $self->pass_error( $s->error ) );
                }
            }
            return( $self->error( "The decoding pass on the HTTP body in memory with encoding '$enc' resulted in 0 byte decoded!" ) ) if( !$len );
            $temp = $decoded;
        }
        # Replace content (default)
        if( $opts->{replace} )
        {
            $body->set( $temp );
            $self->body( $body );
            $self->is_decoded(1);
        }
        # Make a copy to return it
        else
        {
            $body = $body->new( $temp );
        }
    }
    else
    {
        return( $self->error( "I do not know how to handle HTTP body object of class ", ref( $body ) ) );
    }
    return( $body );
}

sub dump
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $content = '';
    my $maxlen = $opts->{maxlength};
    $maxlen = 512 unless( defined( $maxlen ) );
    my $no_content = $opts->{no_content};
    $no_content = "(no content)" unless( defined( $no_content ) );
    my $body = $self->body;
    my $chopped = 0;
    my $mime_type = $self->mime_type;
    my $toptype;
    $toptype = [split( '/', lc( $mime_type ), 2 )]->[0] if( defined( $mime_type ) );
    my $crlf = $HTTP::Promise::Entity::BOUNDARY_DELIMITER || CRLF;

    if( defined( $body ) )
    {
        my $io = $body->open( '<', { binmode => 'raw' } ) ||
            return( $self->pass_error( $body->error ) );
        my $bytes = $io->read( $content, ( $maxlen || $body->length ) );
        return( $self->pass_error( $io->error ) ) if( !defined( $bytes ) );
        $io->close;
        my $encoding = $self->headers->mime_encoding;
        my $encodings = [];
        $encodings = [split( /[[:blank:]\h]*,[[:blank:]\h]*/, $encoding )] if( defined( $encoding ) && length( $encoding ) );
        $self->_load_class( 'HTTP::Promise::Stream' ) || return( $self->error );
        # Process encoding
        if( scalar( @$encodings ) && !$self->is_encoded )
        {
            my $temp = $content;
            my $has_error = 0;
            foreach my $enc ( @$encodings )
            {
                my $s = HTTP::Promise::Stream->new( $temp, encoding => $enc ) ||
                    return( $self->pass_error( HTTP::Promise::Stream->error ) );
                my $encoded = $self->new_scalar;
                my $len = $s->read( $encoded );
                return( $self->pass_error( $s->error ) ) if( !defined( $len ) );
                if( !$len )
                {
                    warn( "The encoding pass on the HTTP body in memory with encoding '$enc' resulted in 0 byte encoded!\n" );
                    $has_error++;
                    last;
                }
                $temp = $encoded;
            }
            $content = $temp unless( $has_error );
        }
        
        if( length( $content ) )
        {
            if( $self->is_binary( \$content ) )
            {
                $content = '(content is ' . length( $content ) . ' bytes of binary data)';
            }
            else
            {
                if( $maxlen && $body->length > $maxlen )
                {
                    $content .= '...';
                    $chopped = $body->length - $maxlen;
                }
                $content =~ s/\\/\\\\/g;
                $content =~ s/\t/\\t/g;
                $content =~ s/\r/\\r/g;

                # no need for 3 digits in escape for these
                $content =~ s/([\0-\11\13-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;

                $content =~ s/([\0-\11\13-\037\177-\377])/sprintf('\\x%02X',ord($1))/eg;
                $content =~ s/([^\12\040-\176])/sprintf('\\x{%X}',ord($1))/eg;

                # remaining whitespace
                $content =~ s/( +)\n/("\\40" x length($1)) . "\n"/eg;
                $content =~ s/(\n+)\n/("\\n" x length($1)) . "\n"/eg;
                $content =~ s/\n\z/\\n/;
                if( $content eq $no_content )
                {
                    # escape our $no_content marker
                    $content =~ s/^(.)/sprintf('\\x%02X',ord($1))/eg;
                }
            }
        }
        else
        {
            $content = $no_content;
        }
        $content .= "\n(+ $chopped more bytes not shown)" if( $chopped );
    }
    elsif( !$self->part->is_empty )
    {
        my $boundary = $self->_prepare_multipart_headers;
        # Multipart... form-data or mixed
        if( defined( $toptype ) && $toptype eq 'multipart' )
        {
            my $boundary = $self->_prepare_multipart_headers();

            # Preamble. I do not think there should be any anyway for HTTP multipart
            my $plines = $self->preamble;
            if( defined( $plines ) )
            {
                # Defined, so output the preamble if it exists (avoiding additional
                # newline as per ticket 60931)
                $content .= join( '', @$plines ) . $crlf if( @$plines > 0 );
            }
            # Otherwise, no preamble.

            # Parts
            foreach my $part ( $self->parts->list )
            {
                $content .= "--${boundary}${crlf}";
                $content .= $part->dump( $opts );
                # Trailing CRLF
                $content .= $crlf;
            }
            $content .= "--${boundary}--${crlf}";

            # Epilogue
            my $epilogue = $self->epilogue;
            if( defined( $epilogue ) && !$epilogue->is_empty )
            {
                $content .= $epilogue->join( '' )->scalar;
                if( $epilogue !~ /(?:\015?\012)\Z/ )
                {
                    $content .= $crlf;
                }
            }
        }
        # Singlepart type with parts...
        #    This makes $ent->print handle message/rfc822 bodies
        #    when parse_nested_messages('NEST') is on [idea by Marc Rouleau].
        else
        {
            my $need_sep = 0;
            my $part;
            foreach $part ( $self->parts->list )
            {
                if( $need_sep++ )
                {
                    $content .= "${crlf}${crlf}";
                }
                $content .= $part->dump( $opts );
            }
        }
    }

    my @dump;
    push( @dump, $opts->{preheader} ) if( $opts->{preheader} );
    my $start_line;
    if( $self->http_message && ( $start_line = $self->http_message->start_line ) )
    {
        push( @dump, $start_line );
    }
    push( @dump, $self->headers->as_string, $content );

    my $dump = join( "\n", @dump, '' );
    $dump =~ s/^/$opts->{prefix}/gm if( $opts->{prefix} );
    return( $dump );
}

sub dump_skeleton
{
    my $self = shift( @_ );
    my( $fh, $indent ) = @_;
    $fh = select if( !$fh );
    $indent = 0 if( !defined( $indent ) );
    my $ind = '    ' x $indent;
    my $part;
    no strict 'refs';
    my $crlf = CRLF;
    my @first_line = ();
    if( my $msg = $self->http_message )
    {
        if( $msg->isa( 'HTTP::Promise::Request' ) )
        {
            push( @first_line, $msg->method, $msg->uri, $msg->protocol );
        }
        else
        {
            push( @first_line, $msg->protocol, $msg->code, $msg->status );
        }
        print( $fh join( ' ', @first_line ), $crlf ) if( @first_line );
    }
    my $headers = $self->headers;
    print( $fh $headers->as_string, $crlf ) || return( $self->error( $! ) );
    my $body = $self->body;
    if( $body )
    {
        if( $body->isa( 'HTTP::Promise::Body::File' ) )
        {
            print( $fh "${ind}Body is stored in a temporary file at '", $body->filename, "' and is ", $body->length, " bytes big.${crlf}" ) ||
                return( $self->error( $! ) );
        }
        elsif( $body->isa( 'HTTP::Promise::Body::Form' ) )
        {
            print( $fh "${ind}Body is a x-www-form-urlencoded data with ", $body->length, " elements:\n", $body->dump ) ||
                return( $self->error( $! ) );
        }
        else
        {
            print( $fh "${ind}Body is stored in memory and is ", $body->length, " bytes big.${crlf}" ) ||
                return( $self->error( $! ) );
        }
    }
    if( my $cd = $headers->content_disposition )
    {
        print( $fh "${ind}Body is encoded using $cd\n" ) || return( $self->error( $! ) );
    }
    my $filename = $self->headers->recommended_filename;
    print( $fh $ind, "${ind}Recommended filename is: '${filename}'$crlf" ) if( $filename );

    # The parts
    my $parts = $self->parts;
    printf( $fh "${ind}This HTTP message has %d parts.${crlf}", $parts->length );
    print( $fh $ind, "--\n" );
    foreach $part ( @$parts )
    {
        $part->dump_skeleton( $fh, $indent + 1 );
    }
    return( $self );
}

sub effective_type
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->_set_get_scalar_as_object( 'effective_type', @_ );
    }
    return( $self->_set_get_scalar_as_object( 'effective_type' ) || $self->mime_type );
}

sub encode_body
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "Bad argument provided. encode_body() accepts only either an array of encodings or a string or something that stringifies." ) ) if( !defined( $this ) || ( !$self->_is_array( $this ) && ( ref( $this ) && !overload::Method( $this => '""' ) ) ) );
    my $encodings = $self->new_array( $self->_is_array( $this ) ? $this : [split( /[[:blank:]\h]*,[[:blank:]\h]*/, "${this}" )] );
    $self->_load_class( 'HTTP::Promise::Stream' ) || return( $self->error );
    my $body = $self->body;
    warn( "No encodings were provided to encode the HTTP body.\n" ) if( !scalar( @$encodings ) && warnings::enabled( ref( $self ) ) );
    # Nothing to do
    return( $self ) if( !$body );
    my $seen = {};
    if( $body->isa( 'HTTP::Promise::Body::File' ) )
    {
        my $f = $body;
        if( $f->is_empty )
        {
            warn( "HTTP Body file '$f' is empty, so there is nothing to encode\n" ) if( warnings::enabled( ref( $self ) ) );
            return( $self );
        }
        my $ext = $f->extension;
        foreach my $enc ( @$encodings )
        {
            next if( $enc eq 'identity' || $enc eq 'none' );
            next if( ++$seen->{ $enc } > 1 );
            my $s = HTTP::Promise::Stream->new( $f, encoding => $enc ) ||
                return( $self->pass_error( HTTP::Promise::Stream->error ) );
            if( $self->ext_vary )
            {
                my $enc_ext = HTTP::Promise::Stream->encoding2suffix( $enc ) ||
                    return( $self->pass_error( HTTP::Promise::Stream->error ) );
                if( !$enc_ext->is_empty )
                {
                    $ext .= '.' . $enc_ext->join( '.' )->scalar;
                }
            }
            my $tempfile = $self->new_tempfile( extension => $ext );
            my $len = $s->read( $tempfile );
            return( $self->pass_error( $s->error ) ) if( !defined( $len ) );
            return( $self->error( "The encoding pass on the HTTP body file source '$f' to target '$tempfile' with encoding '$enc' resulted in 0 byte encoded!" ) ) if( !$len );
            $f = $tempfile;
        }
        $body = HTTP::Promise::Body::File->new( $f ) ||
            return( $self->pass_error( HTTP::Promise::Body::File->error ) );
        $self->body( $body );
    }
    elsif( $body->isa( 'HTTP::Promise::Body::Scalar' ) )
    {
        my $temp = $body;
        if( $body->is_empty )
        {
            warn( "HTTP Body in memory is empty, so there is nothing to encode\n" ) if( warnings::enabled( ref( $self ) ) );
            return( $self );
        }
        
        foreach my $enc ( @$encodings )
        {
            next if( $enc eq 'identity' || $enc eq 'none' );
            next if( ++$seen->{ $enc } > 1 );
            my $s = HTTP::Promise::Stream->new( $temp, encoding => $enc ) ||
                return( $self->pass_error( HTTP::Promise::Stream->error ) );
            my $encoded = $self->new_scalar;
            my $len = $s->read( $encoded );
            return( $self->pass_error( $s->error ) ) if( !defined( $len ) );
            return( $self->error( "The encoding pass on the HTTP body in memory with encoding '$enc' resulted in 0 byte encoded!" ) ) if( !$len );
            $temp = $encoded;
        }
        $body->set( $temp );
        $self->body( $body );
    }
    else
    {
        return( $self->error( "I do not know how to handle HTTP body object of class ", ref( $body ) ) );
    }
    return( $body );
}

sub epilogue { return( shift->_set_get_array_as_object( 'epilogue', @_ ) ); }

sub ext_vary { return( shift->_set_get_boolean( 'ext_vary', @_ ) ); }

# Credits: Christopher J. Madsen (IO::HTML)
# Extract here, because I do not want to load all the modules
sub guess_character_encoding
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $data;
    if( exists( $opts->{content} ) && length( $opts->{content} ) )
    {
        return( $self->error( "Unsupported data type (", ref( $opts->{content} ), ")." ) ) if( ref( $opts->{content} ) && !$self->_is_scalar( $opts->{content} ) );
        $data = $self->_is_scalar( $opts->{content} ) ? $opts->{content} : \$opts->{content};
    }
    else
    {
        my $body = $self->body;
        return( '' ) if( !$body || $body->is_empty );
        my $buff;
        my $io = $body->open( '<', { binmode => 'raw' } ) ||
            return( $self->pass_error( $body->error ) );
        my $bytes = $io->read( $buff, 4096 );
        $io->close;
        return( $self->pass_error( $io->error ) ) if( !defined( $bytes ) );
        $data = \$buff;
    }
    return( '' ) if( $self->is_binary( $data ) );

    my $encoding;
    if( $$data =~ /^\xFe\xFF/ )
    {
        $encoding = 'UTF-16BE';
    }
    elsif( $$data =~ /^\xFF\xFe/ )
    {
        $encoding = 'UTF-16LE';
    }
    elsif( $$data =~ /^\xEF\xBB\xBF/ )
    {
        $encoding = 'utf-8-strict';
    }

    # try decoding as UTF-8
    if( !defined( $encoding ) )
    {
        $self->_load_class( 'Encode' ) || return( $self->pass_error );
        my $test = Encode::decode( 'utf-8-strict', $$data, Encode::FB_QUIET );
        # end if valid UTF-8 with at least one multi-byte character:
        if( $$data =~ /^(?:                # nothing left over
            | [\xC2-\xDF]                  # incomplete 2-byte char
            | [\xE0-\xEF] [\x80-\xBF]?     # incomplete 3-byte char
            | [\xF0-\xF4] [\x80-\xBF]{0,2} # incomplete 4-byte char
        )\z/x and $test =~ /[^\x00-\x7F]/ )
        {
            $encoding = 'utf-8-strict';
        }
    }
    # end if testing for UTF-8
    if( defined( $encoding ) and 
        $opts->{object} and 
        !ref( $encoding ) )
    {
        $self->_load_class( 'Encode' ) || return( $self->pass_error );
        $encoding = Encode::find_encoding( $encoding );
    }
    return( defined( $encoding ) ? $encoding : '' );
}

sub header { return( shift->headers->header( @_ ) ); }

sub headers { return( shift->_set_get_object_without_init( 'headers','HTTP::Promise::Headers', @_ ) ); }

sub header_as_string { return( shift->headers->as_string( @_ ) ); }

sub http_message { return( shift->_set_get_object_without_init( 'http_message', 'HTTP::Promise::Message', @_ ) ); }

# Ref: <https://stackoverflow.com/questions/9956198/in-perl-how-can-i-can-check-if-an-encoding-specified-in-a-string-is-valid>
sub io_encoding
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    # body argument is necessary when content has been decoded, but not replaced with decode_body()
    # and then HTTP::Promise::Message::decoded_content calls io_encoding() to get the character encoding
    my $body = $opts->{body} // $self->body;
    my $headers = $self->headers;
    # Use cache if it exists
    if( !exists( $opts->{content} ) && 
        ( ( $opts->{charset_strict} && $self->{_io_encoding_strict_cached} ) || 
          ( !$opts->{charset_strict} && $self->{_io_encoding_cached} ) 
        ) && 
        $body && 
        $self->{_checksum_md5} eq $body->checksum_md5 )
    {
        return( $opts->{charset_strict} ? $self->{_io_encoding_strict_cached} : $self->{_io_encoding_cached} );
    }
    my $data;
    if( exists( $opts->{content} ) && length( $opts->{content} ) )
    {
        return( $self->error( "Unsupported data type (", ref( $opts->{content} ), ")." ) ) if( ref( $opts->{content} ) && !$self->_is_scalar( $opts->{content} ) );
        $data = $self->_is_scalar( $opts->{content} ) ? $opts->{content} : \$opts->{content};
    }
    else
    {
        # my $body = $self->body || return( '' );
        return( '' ) if( !$body );
        $self->{_checksum_md5} = $body->checksum_md5;
        my $io = $body->open( '<', { binmode => 'raw' } ) ||
            return( $self->pass_error( $body->error ) );
        my $buff;
        my $bytes = $io->read( $buff, 4096 );
        return( $self->pass_error( $io->error ) ) if( !defined( $bytes ) );
        return( '' ) if( !$bytes );
        $data = \$buff;
    }
    # return( '' ) if( $self->is_binary( $data ) );
    
    my $enc;
    if( $headers->content_is_text || ( my $is_xml = $headers->content_is_xml ) )
    {
        my $charset = lc(
            $opts->{charset} ||
            $headers->content_type_charset ||
            $opts->{default_charset} ||
            # content_type_charset to tell content_charset to not try to call this method since we just called it.
            $self->content_charset( content => $data, content_type_charset => 0 ) ||
            'UTF-8'
        );
        if( $charset eq 'none' )
        {
            # leave it as is
        }
        elsif( $charset eq 'us-ascii' || $charset eq 'iso-8859-1' )
        {
            # if( $$content_ref =~ /[^\x00-\x7F]/ && defined &utf8::upgrade )
            if( $$data =~ /[^\x00-\x7F]/ )
            {
                $enc = 'utf-8';
            }
        }
        else
        {
            $self->_load_class( 'Encode' ) || return( $self->pass_error );
            try
            {
                my $test = Encode::decode( $charset, $$data, ( ( $opts->{charset_strict} ? Encode::FB_CROAK : 0 ) | Encode::LEAVE_SRC ) );
                $enc = $charset;
            }
            catch( $e )
            {
                my $retried = 0;
                if( $e =~ /^Unknown encoding/ )
                {
                    my $alt_charset = lc( $opts->{alt_charset} || '' );
                    if( $alt_charset && $charset ne $alt_charset )
                    {
                        # Retry decoding with the alternative charset
                        my $test = Encode::decode( $alt_charset, $$data, ( ( $opts->{charset_strict} ? Encode::FB_CROAK : 0 ) | Encode::LEAVE_SRC ) ) unless( $alt_charset eq 'none' );
                        $retried++;
                        $enc = $alt_charset;
                    }
                }
                return( $self->error( $e ) ) unless( $retried );
            }
        }
    }
    if( $opts->{charset_strict} )
    {
        $self->{_io_encoding_strict_cached} = $enc;
    }
    else
    {
        $self->{_io_encoding_cached} = $enc;
    }
    return( defined( $enc ) ? $enc : '' );
}

# <https://stackoverflow.com/questions/899206/how-does-perl-know-a-file-is-binary>
# <https://github.com/morungos/perl-Data-Binary/blob/master/lib/Data/Binary.pm>
# "The "-T" and "-B" tests work as follows. The first block or so of the file is examined to see if it is valid UTF-8 that includes non-ASCII characters. If so, it's a "-T" file.
# Otherwise, that same portion of the file is examined for odd characters such as strange control codes or characters with the high bit set. If more than a third of the characters are strange, it's a "-B" file; otherwise it's a "-T" file.
# Also, any file containing a zero byte in the examined portion is considered a binary file. (If executed within the scope of a use locale which includes "LC_CTYPE", odd characters are anything that isn't a printable nor space in the current locale.) If "-T" or "-B" is used on a filehandle, the current IO buffer is examined rather than the first block. Both "-T" and "-B" return true on an empty file, or a file at EOF when testing a filehandle. Because you have to read a file to do the "-T" test, on most occasions you want to use a "-f" against the file first, as in "next unless -f $file && -T $file"."
sub is_binary
{
    my $self = shift( @_ );
    $self->_load_class( 'Encode' ) || return( $self->pass_error );
    my $data;
    if( @_ )
    {
        return(0) if( !defined( $_[0] ) || !length( "$_[0]" ) );
        return( $self->error( "Bad argument. You can only provide a string or a scalar reference." ) ) if( ref( $_[0] ) && !$self->_is_scalar( $_[0] ) );
        $data = ref( $_[0] ) ? $_[0] : \$_[0];
    }
    else
    {
        my $body = $self->body;
        return(0) if( !$body || $body->is_empty );
        my $buff;
        my $io = $body->open( '<', { binmode => 'raw' } ) ||
            return( $self->pass_error( $body->error ) );
        my $bytes = $io->read( $buff, 4096 );
        $io->close;
        return( $self->pass_error( $io->error ) ) if( !defined( $bytes ) );
        warn( "Body is ", $body->length, " bytes big, but somehow I could not read ny bytes out of it.\n" ) if( !$bytes && warnings::enabled() );
        return(0) if( !$bytes );
        $data = \$buff;
    }
    
    # There are various method to check if the data is or contains binary data
    # perl's -B function is very cautious and will lean on the false positive.
    # Data::Binary implements the perl algorithm, but still yield false positive if, for example,
    # there is even 1 \0 in the data
    # The most reliable yet is to use module Encode with the die flag on upon error and catch it.
    
    # Has the utf8 bit been set?
    # Then, let's try to encode it into utf-8
    if( utf8::is_utf8( $$data ) )
    {
        eval
        {
            Encode::encode( 'utf-8', $$data, ( Encode::FB_CROAK | Encode::LEAVE_SRC ) );
        };
        return( $@ ? 1 : 0 );
    }
    # otherwise, let's try to decode this into perl's internal utf8 representation
#     else
#     {
#         eval
#         {
#             Encode::decode( 'utf8', $$data, ( Encode::FB_CROAK | Encode::LEAVE_SRC ) );
#         };
#     }
#     return( $@ ? 1 : 0 );

    return(1) if( index( $$data, "\c@" ) != -1 );
    my $length = length( $$data );
    my $odd = ( $$data =~ tr/\x01\x02\x03\x04\x05\x06\x07\x09\x0b\x0c\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f//d );
    # Detecting >=128 and non-UTF-8 is interesting. Note that all UTF-8 >=128 has several bytes with
    # >=128 set, so a quick test is possible by simply checking if any are >=128. However, the count
    # from that is typically wrong, if this is binary data, it'll not have been decoded. So we do this
    # in two steps.

    my $copy = $$data;
    if( ( $copy =~ tr[\x80-\xff][]d ) > 0 )
    {
        my $modified = Encode::decode_utf8( $$data, Encode::FB_DEFAULT );
        my $substitions = ( $modified =~ tr/\x{fffd}//d );
        $odd += $substitions;
    }
    return(1) if( ( $odd / $length ) > 0.34 );
    return(0);
}

sub is_body_on_file
{
    my $self = shift( @_ );
    my $body = $self->body;
    return(0) if( !$body || $body->is_empty );
    return( $self->_is_a( $body => 'HTTP::Promise::Body::File' ) );
}

sub is_body_in_memory
{
    my $self = shift( @_ );
    my $body = $self->body;
    return(0) if( !$body || $body->is_empty );
    return( $self->_is_a( $body => 'HTTP::Promise::Body::Scalar' ) );
}

# Convenience
sub is_decoded
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $bool = shift( @_ );
        return( !$self->is_encoded( !$bool ) );
    }
    else
    {
        return( !$self->is_encoded );
    }
}

sub is_encoded { return( shift->_set_get_boolean( 'is_encoded', @_ ) ); }

sub is_multipart
{
    my $self = shift( @_ );
    # no head, so no MIME type!
    $self->headers or return;
    my $mime_type = $self->headers->type;
    return(0) if( !defined( $mime_type ) || !length( $mime_type ) );
    return( substr( lc( $mime_type ), 0, 9 ) eq 'multipart' ? 1 : 0 );
}

sub is_text { return( !shift->is_binary( @_ ) ); }

sub make_boundary { return( Data::UUID->new->create_str ); }
# sub make_boundary
# {
#     my $self = shift( @_ );
#     # my $uuid = $self->_uuid;
#     my $uuid = Data::UUID->new;
#     my $boundary = $uuid->create_str;
#     return( $boundary );
# }

sub make_multipart
{
    my $self = shift( @_ );
    my $subtype = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $tag;
    $subtype ||= 'form-data';
    my $force = $opts->{force};

    # Trap for simple case: already a multipart?
    return( $self ) if( $self->is_multipart and !$force );
    my $headers = $self->headers;
    

    # Rip out our guts, and spew them into our future part.
    # part is a shallow copy
    # my $part = bless( {%$self} => ref( $self ) );
#     my $part = $self->new(
#         headers => $headers->clone,
#         ( $self->body ? ( body => $self->body ) : () ),
#         debug => $self->debug,
#     );
# 
#     if( my $msg = $self->http_message )
#     {
#         my $clone = $msg->clone( clone_entity => 0 );
#         $clone->entity( $part );
#         $part->http_message( $clone );
#     }
#     $part->parts( $self->parts );
    
    my $part = $self->clone;
    
    # my $part = $self->clone;
    # lobotomize ourselves!
    # %$self = ();
    # clone the headers

    # Remove content headers from top-level, and set it up as a multipart
    my $removed = $headers->remove_content_headers;
    my $ct = $headers->new_field( 'Content-Type' => "multipart/${subtype}" ) ||
        return( $self->pass_error( $headers->error ) );
    $ct->boundary( $self->make_boundary );
    my $ct_string = $ct->as_string;
    $headers->header( 'Content-Type' => "${ct_string}" );

    # Remove non-content headers from the part
    $removed = $self->new_array;
    foreach $tag ( grep{ !/^content-/i } $part->headers->header_field_names )
    {
        $part->headers->delete( $tag );
        $removed->push( $tag );
    }
    $self->parts->reset;
    $self->add_part( $part ) if( $part->body || $part->parts->length );
    return( $self );
}

sub make_singlepart
{
    my $self = shift( @_ );
    # Trap for simple cases:
    # already a singlepart?
    return( $self ) if( !$self->is_multipart );
    # can this even be done?
    return(0) if( $self->parts > 1 );

    # Get rid of all our existing content info
    my $tag;
    foreach $tag ( grep{ /^content-/i } $self->headers->header_field_names )
    {
        $self->headers->delete( $tag );
    }

    # one part
    if( $self->parts->length == 1 )
    {
        my $part = $self->parts->index(0);
        # Populate ourselves with any content info from the part:
        foreach $tag ( grep{ /^content-/i } $part->headers->header_field_names )
        {
            $self->headers->add( $tag => $_ ) for( $part->headers->get( $tag ) );
        }

        # Save reconstructed headers, replace our guts, and restore header:
        my $new_head = $self->headers;
        # shallow copy is ok!
        %$self = %$part;
        $self->headers( $new_head );

        # One more thing: the part *may* have been a multi with 0 or 1 parts!
        return( $self->make_singlepart( @_ ) ) if( $self->is_multipart );
    }
    # no parts!
    else
    {
        $self->headers->mime_attr( 'Content-type' => 'text/plain' );   ### simple
    }
    return( $self );
}

sub mime_type
{
    my $self = shift( @_ );
    my $headers = $self->headers;
    return if( !defined( $headers ) );
    return( $headers->mime_type( @_ ) );
}

# NOTE name() is to associate a name for this entity for multipart/form-data
sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub new_body
{
    my $self = shift( @_ );
    my $type = shift( @_ ) || 'scalar';
    my $map =
    {
    file   => 'HTTP::Promise::Body::File',
    form   => 'HTTP::Promise::Body::Form',
    scalar => 'HTTP::Promise::Body::Scalar',
    string => 'HTTP::Promise::Body::Scalar',
    };
    my $class = $map->{ $type } || return( $self->error( "Unsupported body type '$type'" ) );
    if( $type eq 'form' )
    {
        $self->_load_class( $class ) || return( $self->pass_error );
    }
    my $body = $class->new( @_ );
    return( $self->pass_error( $class->error ) ) if( !defined( $body ) );
    return( $body );
}

sub open
{
    my $self = shift( @_ );
    my $body = $self->body;
    return( $self->error( "Unable to open the entity body, because none is currently set." ) ) if( !$body );
    my $io = $body->open( @_ ) ||
        return( $self->pass_error( $body->error ) );
    return( $io );
}

sub output_dir { return( shift->_set_get_file( 'output_dir', @_ ) ); }

sub parts { return( shift->_set_get_array_as_object( '_parts', @_ ) ); }

sub preamble { return( shift->_set_get_array_as_object( 'preamble', @_ ) ); }

sub print
{
    my $self = shift( @_ );
    my $out = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $eol = $opts->{eol} || $HTTP::Promise::Entity::BOUNDARY_DELIMITER || CRLF;
    $out = select if( !defined( $out ) );
    $out = Symbol::qualify( $out, scalar( caller ) ) unless( ref( $out ) );
    $self->_load_class( 'HTTP::Promise::IO' ) || return( $self->error );
    my $io = $self->_is_a( $out => 'HTTP::Promise::IO' )
        ? $out
        : HTTP::Promise::IO->new( $out, debug => $self->debug );
    return( $self->pass_error( HTTP::Promise::IO->error ) ) if( !defined( $io ) );
    $opts->{eol} = $eol;
    # The start-line
    $self->print_start_line( $io, $opts ) || return( $self->pass_error );
    # The headers
    $self->print_header( $io, $opts ) || return( $self->pass_error );
    $io->print( $eol ) ||
        return( $self->error( "Unable to print to filehandle provided '$io': $!" ) );
    # The body
    $self->print_body( $io, ( scalar( keys( %$opts ) ) ? $opts : () ) ) || return( $self->pass_error );
    return( $self );
}

sub print_body
{
    my $self = shift( @_ );
    my $out = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Filehandle provided ($out) is not a proper filehandle and its not a HTTP::Promise::IO object." ) ) if( !$self->_is_glob( $out ) && !$self->_is_a( $out => 'HTTP::Promise::IO' ) );
    $out ||= select;
    my $mime_type = $self->mime_type;
    my $toptype;
    $toptype = [split( '/', lc( $mime_type ), 2 )]->[0] if( defined( $mime_type ) );
    # my $crlf = $HTTP::Promise::Entity::BOUNDARY_DELIMITER || CRLF;
    my $crlf = $opts->{eol} || $HTTP::Promise::Entity::BOUNDARY_DELIMITER || CRLF;

    # Multipart... form-data or mixed
    if( defined( $toptype ) && $toptype eq 'multipart' )
    {
        my $boundary = $self->_prepare_multipart_headers();

        # Preamble. I do not think there should be any anyway for HTTP multipart
        my $plines = $self->preamble;
        if( defined( $plines ) )
        {
            # Defined, so output the preamble if it exists (avoiding additional
            # newline as per ticket 60931)
            $out->print( join( $crlf, @$plines ) . $crlf ) if( @$plines > 0 );
        }
        # Otherwise, no preamble.

        # Parts
        foreach my $part ( $self->parts->list )
        {
            $out->print( "--${boundary}${crlf}" ) ||
                return( $self->error( "Unable to print request body to filehandle provided '$out': $!" ) );
            $part->print( $out ) ||
                return( $self->error( "Unable to print request body to filehandle provided '$out': $!" ) );
            # Trailing CRLF
            $out->print( $crlf ) ||
                return( $self->error( "Unable to print request body to filehandle provided '$out': $!" ) );
        }
        $out->print( "--${boundary}--${crlf}" ) ||
            return( $self->error( "Unable to print request body to filehandle provided '$out': $!" ) );

        # Epilogue
        my $epilogue = $self->epilogue;
        if( defined( $epilogue ) && !$epilogue->is_empty )
        {
            $out->print( $epilogue->join( $crlf )->scalar ) ||
                return( $self->error( "Unable to print request body to filehandle provided '$out': $!" ) );
            if( $epilogue !~ /(?:\015?\012)\Z/ )
            {
                $out->print( $crlf ) ||
                    return( $self->error( "Unable to print request body to filehandle provided '$out': $!" ) );
            }
        }
    }
    # Singlepart type with parts...
    #    This makes $ent->print handle message/rfc822 bodies
    #    when parse_nested_messages('NEST') is on [idea by Marc Rouleau].
    elsif( !$self->parts->is_empty )
    {
        my $need_sep = 0;
        my $part;
        my $parts = $self->parts;
        # foreach $part ( $self->parts->list )
        foreach $part ( @$parts )
        {
            if( $need_sep++ )
            {
                $out->print( "${crlf}${crlf}" ) ||
                    return( $self->error( "Unable to print request body to filehandle provided '$out': $!" ) );
            }
            $part->print( $out ) ||
                return( $self->error( "Unable to print request body to filehandle provided '$out': $!" ) );
        }
    }
    # Singlepart type, or no parts: output body...
    else
    {
        if( $self->body )
        {
            $self->print_bodyhandle( $out, ( scalar( keys( %$opts ) ) ? $opts : () ) ) ||
                return( $self->pass_error );
        }
    }
    return( $self );
}

sub print_bodyhandle
{
    my $self = shift( @_ );
    my $out = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $out ||= select;
    return( $self->error( "Filehandle provided ($out) is not a proper filehandle and its not a HTTP::Promise::IO object." ) ) if( !$self->_is_glob( $out ) && !$self->_is_a( $out => 'HTTP::Promise::IO' ) );

    my $encoding = $self->headers->content_encoding;
    if( $encoding && 
        !$self->is_encoded && 
        ( !exists( $opts->{no_encode} ) || 
          ( exists( $opts->{no_encode} ) && !$opts->{no_encode} )
        ) )
    {
        $self->encode_body( $encoding ) || return( $self->pass_error );
        $self->is_encoded(1);
    }
    my $params = {};
    $params->{binmode} = $opts->{binmode} if( exists( $opts->{binmode} ) && $opts->{binmode} );
    # An opportunity here to specify the io layer, such as utf-8
    my $io = $self->open( 'r', ( scalar( keys( %$params ) ) ? $params : () ) ) || return( $self->pass_error );
    my $buff;
    while( $io->read( $buff, 8192 ) )
    {
        $out->print( $buff ) ||
            return( $self->error( "Unable to print request body to filehandle provided '$out': $!" ) );
    }
    $io->close;
    return( $self );
}

sub print_header { shift->headers->print( @_ ); }

# NOTE: An entity is encapsulated inside either a request or a response.
# See rfc7230, section 3.1 <https://tools.ietf.org/html/rfc7230#section-3.1>
sub print_start_line
{
    my $self = shift( @_ );
    my $out = shift( @_ );
    $out ||= select;
    return( $self->error( "Filehandle provided ($out) is not a proper filehandle and its not a HTTP::Promise::IO object." ) ) if( !$self->_is_glob( $out ) && !$self->_is_a( $out => 'HTTP::Promise::IO' ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my $eol = $opts->{eol} || CRLF;
    if( my $msg = $self->http_message )
    {
        my $sl = $msg->start_line;
        return( $self ) unless( length( $sl ) );
        $out->print( $sl . $eol );
    }
    return( $self );
}

sub purge
{
    my $self = shift( @_ );
    # purge me
    $self->body->purge if( $self->body );
    # recurse
    $_->purge for( $self->parts->list );
    return( $self );
}

sub save_file
{
    my $self = shift( @_ );
    my $fname = shift( @_ );
    my $type = $self->type;
    return( '' ) if( lc( substr( $type, 0, 10 ) ) eq 'multipart/' );
    unless( defined( $fname ) && length( "$fname" ) )
    {
        my $headers = $self->headers;
        if( my $val = $headers->content_disposition )
        {
            my $cd = $headers->new_field( 'Content-Disposition' => "$val" );
            return( $self->pass_error( $headers->error ) ) if( !defined( $cd ) );
            if( my $orig_name = $cd->filename )
            {
                my $f = $self->new_file( $orig_name );
                my $ext = $f->extension;
                my $base = $f->basename( ( defined( $ext ) && length( $ext ) ) ? $ext : () );
            
                my @unsafe = map( quotemeta( $_ ), qw/ < > “ ‘ % ; ) ( & + $ [ ] : ./ );
                push( @unsafe, "\r", "\n", ' ', '/' );
                $base =~ s/(?<!\\)\.\.(?!\.)//g;
                local $" = '|';
                $base =~ s/(@unsafe)//g;
                unless( $ext )
                {
                    # Guessing extension
                    my $mime_type = $headers->mime_type( $DEFAULT_MIME_TYPE || 'application/octet-stream' );
                    $self->_load_class( 'HTTP::Promise::MIME' ) || return( $self->pass_error );
                    my $mime = HTTP::Promise::MIME->new;
                    $ext = $mime->suffix( $mime_type );
                    return( $self->pass_error( $mime->error ) ) if( !defined( $ext ) );
                }
                $ext ||= 'dat';
                $self->_load_class( 'Module::Generic::File' ) || return( $self->pass_error );
                my $output_dir = $self->outputdir || Module::Generic::File->sys_tmpdir;
                $fname = $output_dir->child( join( '.', $base, $ext ) );
            }
        }
        
        if( !defined( $fname ) || !length( $fname ) )
        {
            # Guessing extension
            my $mime_type = $headers->mime_type( $DEFAULT_MIME_TYPE || 'application/octet-stream' );
            $self->_load_class( 'HTTP::Promise::MIME' ) || return( $self->pass_error );
            my $mime = HTTP::Promise::MIME->new;
            my $ext = $mime->suffix( $mime_type );
            return( $self->pass_error( $mime->error ) ) if( !defined( $ext ) );
            $ext ||= 'dat';
            $fname = $self->new_tempfile( extension => $ext );
        }
    }
    if( my $enc = $self->headers->content_encoding )
    {
        $self->decode_body( $enc ) if( $self->is_encoded );
    }
    my $f = $self->_is_a( $fname => 'Module::Generic::File' ) ? $fname : $self->new_file( "$fname" );
    my $io = $f->open( '+>', { binmode => 'raw', autoflush => 1 } ) ||
        return( $self->pass_error( $f->error ) );
    # Pass no_encode to ensure the file does not get automatically encoded
    $self->print_body( $io, no_encode => 1 ) || return( $self->pass_error );
    $io->close;
    return( $f );
}

sub stringify { return( shift->as_string( @_ ) ); }

sub stringify_body { return( shift->body_as_string( @_ ) ); }

sub stringify_header { return( shift->headers->as_string( @_ ) ); }

sub suggest_encoding
{
    my $self = shift( @_ );
    my $mime_type = $self->effective_type;
    my $toptype;
    $toptype = [split( '/', $mime_type, 2 )]->[0] if( defined( $mime_type ) );
    # Defaults to 200Kb
    my $threshold = $self->compression_min;
    my $rule = {qw(
        text/css                gzip
        text/html               gzip
        text/plain              gzip
        text/x-component        gzip
        application/atom+xml    gzip
        application/javascript  gzip
        application/json        gzip
        application/pdf         none
        application/rss+xml     gzip
        application/vnd.ms-fontobject   gzip
        application/x-font-opentype gzip
        application/x-font-ttf  gzip
        application/x-javascript    gzip
        application/x-web-app-manifest+json gzip
        application/xhtml+xml   gzip
        application/xml         gzip
        application/gzip        none
        font/opentype           gzip
        image/gif               none
        image/jpeg              none
        image/png               none
        image/svg+xml           gzip
        image/webp              none
        image/x-icon            none
        audio/mpeg              none
        video/mp4               none
        audio/webm              none
        video/webm              none
        font/otf                gzip
        font/ttf                gzip
        font/woff2              none
        
    )};
    # Already usually quite compressed, not much benefit compared to CPU penalty; we are
    # not in 1998 anymore :)
    # <http://web.archive.org/web/20190708231140/http://www.ibm.com/developerworks/web/library/wa-httpcomp/>
    # Also small files, like less than 1,500 bytes are a waste o time due to MTU max size
    # (https://en.wikipedia.org/wiki/Maximum_transmission_unit)
    # See also <https://httpd.apache.org/docs/2.4/mod/mod_deflate.html>
    # <https://webmasters.stackexchange.com/questions/31750/what-is-recommended-minimum-object-size-for-gzip-performance-benefits>
    if( exists( $rule->{ $mime_type } ) )
    {
        return( '' ) if( $rule->{ $mime_type } eq 'none' );
        return( $rule->{ $mime_type } ) if( !$threshold || $self->body->length >= $threshold );
    }
    elsif( $toptype eq 'image' || 
           $toptype eq 'video' || 
           $toptype eq 'audio' || 
           $toptype eq 'multipart' )
    {
        return( '' );
    }
    elsif( $toptype eq 'text' || $self->is_binary )
    {
        # Suggest gzip compression if it exceeds 200Kb
        return( 'gzip' ) if( !$threshold || $self->body->length >= $threshold );
    }
    return( '' );
}

sub textual_type
{
    my $self = shift( @_ );
    return( $_[0] =~ m{^(text|message)(/|\Z)}i ? 1 : 0 );
}

sub _parts { return( shift->_set_get_array_as_object( '_parts', @_ ) ); }

# NOTE: Used in both print_body() and dump()
sub _prepare_multipart_headers
{
    my $self = shift( @_ );
    my $mime_type = $self->mime_type;
    my $toptype;
    $toptype = [split( '/', lc( $mime_type ), 2 )]->[0] if( defined( $mime_type ) );
    my $boundary = $self->headers->multipart_boundary;
    # Ensure we have a boundary set.
    # This is the same code as in HTTP::Promise::Headers::as_string, but since
    # print_body() may be called separately, we need to check here too if a boundary
    # has been set.
    unless( $boundary )
    {
        $boundary = $self->make_boundary;
        my $ct = $self->headers->new_field( 'Content-Type' => $self->headers->content_type );
        $ct->boundary( $boundary );
        $self->headers->content_type( "$ct" );
    }
    # Parts
    # For reporting to the caller only when there are some issues.
    my $n = 0;
    # for generated part name, by default
    my $auto_name = 'part0';
    foreach my $part ( $self->parts->list )
    {
        ++$n;
        # If this is a multipart/form-data, ensure we have a part name, or isse a warning
        my $name;
        if( $mime_type eq 'multipart/form-data' )
        {
            $name = $part->name;
            if( !$name )
            {
                warn( "Warning: no part name set for this part No. ${n}\n" ) if( warnings::enabled() );
                $name = ++$auto_name;
                $part->name( $name );
            }
        }
        elsif( $mime_type eq 'multipart/mixed' )
        {
            # remove any Content-Disposition used for multipart/form-data
            $part->headers->remove( 'Content-Disposition' );
        }
        
        if( defined( $name ) )
        {
            my $content_disposition = $part->headers->content_disposition;
            if( defined( $content_disposition ) && $content_disposition->length )
            {
                # A simple check to save time from generating the Content-Disposition object
                if( $content_disposition->index( 'name=' ) == -1 || 
                    $content_disposition->index( 'form-data' ) == -1 )
                {
                    my $cd = $part->headers->new_field( 'Content-Disposition' => $part->headers->content_disposition );
                    $cd->name( $name ) if( !length( $cd->name ) );
                    $cd->disposition( 'form-data' );
                }
            }
            else
            {
                $part->headers->content_disposition( qq{form-data; name="${name}"} );
            }
        }
    }
    return( $boundary );
}

# NOTE: sub FREEZE is inherited
sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my $ref = $self->_obj2h;
    my %hash = %$ref;
    # We remove this to prevent a circular reference that CBOR::XS does not seem to be managing
    # This relation is re-created in HTTP::Promise::Message::THAW
    # It is safe to remove it, because 1) if it is a standalone HTTP::Promise::Entity object, 
    # then it would not be set anyway, and 2) if it is part of an HTTP::Promise::Message, it
    # is going to be recreated.
    CORE::delete( @hash{ qw( http_message ) } ) unless( $serialiser ne 'CBOR' );
    # Return an array reference rather than a list so this works with Sereal and CBOR
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Entity - HTTP Entity Class

=head1 SYNOPSIS

    use HTTP::Promise::Entity;
    my $this = HTTP::Promise::Entity->new || die( HTTP::Promise::Entity->error, "\n" );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This class represents an HTTP entity, which is an object class containing an headers object and a body object. It is agnostic to the type of HTTP message (request or response) it is associated with and can be used recurrently, such as to represent a part in a multipart HTTP message. Its purpose is to provide an API to access and manipulate and HTTP message entity.

Here is how it fits in overall relation with other classes.
                                                               
    +-------------------------+    +--------------------------+    
    |                         |    |                          |    
    | HTTP::Promise::Request  |    | HTTP::Promise::Response  |    
    |                         |    |                          |    
    +------------|------------+    +-------------|------------+    
                 |                               |                 
                 |                               |                 
                 |                               |                 
                 |  +------------------------+   |                 
                 |  |                        |   |                 
                 +--- HTTP::Promise::Message |---+                 
                    |                        |                     
                    +------------|-----------+                     
                                 |                                 
                                 |                                 
                    +------------|-----------+                     
                    |                        |                     
                    | HTTP::Promise::Entity  |                     
                    |                        |                     
                    +------------|-----------+                     
                                 |                                 
                                 |                                 
                    +------------|-----------+                     
                    |                        |                     
                    | HTTP::Promise::Body    |                     
                    |                        |                     
                    +------------------------+                     

=head1 CONSTRUCTOR

=head2 new

This instantiate a new L<HTTP::Promise::Entity> object and returns it. It takes the following options, which can also be set or retrieved with their related method.

=over 4

=item * C<compression_min>

Integer. Size threshold beyond which the associated body can be compressed. This defaults to 204800 (200Kb). Set it to 0 to disable it.

=item * C<effective_type>

String. The effective mime-type. Default to C<undef>

=item * C<epilogue>

An array reference of strings to be added after the headers and before the parts in a multipart message. Each array reference entry is treated as one line. This defaults to C<undef>

=item * C<ext_vary>

Boolean. Setting this to a true value and this will have L</decode_body> and L</encode_body> change the entity body file extension to reflect the encoding or decoding applied.

See L</ext_vary> for an example.

=item * C<headers>

This is an L<HTTP::Promise::Headers> object. This defaults to C<undef>

=item * C<is_encoded>

Boolean. This is a flag used to determine whether the related entity body is decoded or not. This defaults to C<undef>

See also L<HTTP::Promise::Headers/content_encoding>

=item * C<output_dir>

This is the path to the directory used when extracting body to files on the filesystem. This defaults to C<undef>

=item * C<preamble>

An array reference of strings to be added after all the parts in a multipart message. Each array reference entry is treated as one line. This defaults to C<undef>

=back

=head1 METHODS

=head2 add_part

Provided with an L<HTTP::Promise::Entity> object, and this will add it to the stack of parts for this entity.

It returns the part added, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 as_form_data

If the entity is of type C<multipart/form-data>, this will transform all of its parts into an L<HTTP::Promise::Body::Form::Data> object.

It returns the new L<HTTP::Promise::Body::Form::Data> object upon success, or 0 if there was nothing to be done i the entity is not C<multipart/form-data> for example, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

Note that this is memory savvy, because een though it breaks down the parts into an L<HTTP::Promise::Body::Form::Data> object, original entity body that were stored on file remain on file. Each of the L<HTTP::Promise::Body::Form::Data> entry is a field name and its value is an L<HTTP::Promise::Body::Form::Field> object. Thus you could access data such as:

    my $form = $ent->as_form_data;
    my $name = $form->{fullname}->value;
    if( $form->{picture}->file )
    {
        say "Picture is stored on file.";
    }
    elsif( $form->{picture}->value->length )
    {
        say "Picture is in memory.";
    }
    else
    {
        say "There is no data.";
    }

    say "Content-Type for this form-data is: ", $form->{picture}->headers->content_type;

=head2 as_string

This returns a L<scalar object|Module::Generic::Scalar> containing a string representation of the message entity.

It takes an optional string parameter containing an end of line separator, which defaults to C<\015\012>.

Internally, this calls L</print>.

If an error occurred, it set an L<error|Module::Generic/error> and returns C<undef>.

Be mindful that because this returns a scalar object, it means the entire HTTP message entity is loaded into memory, which, depending on the content size, can potentially be big and thus take a lot of memory.

You may want to check the body size first using: C<$ent->body->length> for example if this is not a multipart entity.

=head2 attach

Provided with a list of parameters and this add the created part entity to the stack of entity parts.

This will transform the current entity into a multipart, if necessary, by calling L</make_multipart>

Since it calls L</build> internally to build the message entity, see L</build> for the list of supported parameters.

It returns the newly added L<part object|HTTP::Promise::Entity> upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 body

Sets or gets this entity L<body object|HTTP::Promise::Body>.

=head2 body_as_array

This returns an L<array object|Module::Generic::Array> object containing body lines with each line terminated by an end-of-line sequence, which is optional and defaults to C<\015\012>.

Upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 body_as_string

This returns a L<scalar object|Module::Generic::Scalar> containing a string representation of the message body.

=head2 build

    my $ent = HTTP::Promise::Entity->new(
        encoding => 'gzip',
        type     => 'text/plain',
        data     => 'Hello world',
    );
    my $ent = HTTP::Promise::Entity->new(
        encoding => 'guess',
        type     => 'text/plain',
        data     => '/some/where/file.txt',
    );

This takes an hash or hash reference of parameters and build a new L<HTTP::Promise::Entity>.

It returns the newly created L<entity object|HTTP::Promise::Entity> object upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

Supported arguments are:

=over 4

=item * C<boundary>

The part boundary to be used if the entity is of type multipart.

=item * C<data>

The entity body content. If this is provided, the entity body will be an L<HTTP::Promise::Body::Scalar> object.

=item * C<debug>

An integer representing the level of debugging output. Defaults to 0.

=item * C<disposition>

A string representing the C<Content-Disposition>, such as C<form-data>. This defaults to C<inline>.

=item * C<encoding>

String. A comma-separated list of content encodings used in order you want the entity body to be encoded.

For example: C<gzip, base64> or C<brotli>

See L<HTTP::Promise::Stream> for a list of supported encodings.

If C<encoding> is C<guess>, this will call L</suggest_encoding> to find a suitable encoding, if any at all.

=item * C<filename>

The C<filename> attribute value of a C<Content-Disposition> header value, if any.

If the filename provided contains 8 bit characters like unicode characters, this will be detected and the filename will be encoded according to L<rfc2231|https://tools.ietf.org/html/rfc2231>

See also L<HTTP::Promise::Headers/content_disposition> and L<HTTP::Promise::Headers::ContentDisposition>

=item * C<path>

The filepath to the content to be used as the entity body. This is useful if the body size is big and you do not want to load it in memory.

=item * C<type>

String. The entity mime-type. This defaults to C<text/plain>

If the type is set to C<multipart/form-data> or C<multipart/mixed>, or any other multipart type, this will automatically create a boundary, which is basically a UUID generated with the XS module L<Data::UUID>

=back

=head2 compression_min

Integer. This is the body size threshold in bytes beyond which this will make the encoding of the entity body possible. You can set this to zero to deactivate it.

=head2 content_charset

This will try to guess the character set of the body and returns a string the character encoding found, if any, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>. If nothing was found, it will return an empty string.

It takes an optional hash or hash reference of options.

Supported options are;

=over 4

=item * C<content>

A string or scalar reference of some or all of the body data to be checked. If this is not provided, 4Kb of data will be read from the body to guess the character encoding.

=back

=head2 decode_body

This takes a coma-separated list of encoding or an array reference of encodings, and an optional hash or hash reference of options and decodes the entity body.

It returns the L<body object|HTTP::Promise::Body> upon success, and upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

Supported options are:

=over 4

=item * C<raise_error>

Boolean. When set to true, this will cause this method to die upon error.

=item * C<replace>

Boolean. If true, this will replace the body content with the decoded version. Defaults to true.

=back

What this method does is instantiate a new L<HTTP::Promise::Stream> object for each encoding and pass it the data whether as a scalar reference if the data are in-memory body, or a file, until all decoding have been applied.

When C<deflate> is one of the encoding, it will try to use L<IO::Uncompress::Inflate> to decompress data. However, some server encode data with C<deflate> but omit the zlib headers, which makes L<IO::Uncompress::Inflate> fail. This is detected and trapped and C<rawdeflate> is used as a fallback.

=head2 dump

This dumps the entity data into a string and returns it. It will encode the body if not yet encoded and will escape control and space characters, and show in hexadecimal representation the body content, so that even binary data is safe to dump.

It takes some optional arguments, which are:

=over 4

=item * C<maxlength>

Max body length to include in the dump.

=item * C<no_content>

The string to use when there is no content, i.e. when the body is empty.

=back

=head2 dump_skeleton

This method is more for debugging, or to get a peek at the entity structure. This takes a filehandle to print the result to.

This returns the current L<entity object|HTTP::Promise::Entity> on success, and upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 effective_type

This set or get the effective mime-type. In assignment mode, this simply stores whatever mie-type you provide and in retrieval mode, this retrieve the value previously set, or by default the value returned from L</mime_type>

=head2 encode_body

This encode the entity body according to the encodings provided either as a comma-separated string or an array reference of encodings.

The way it does this is to instantiate a new L<HTTP::Promise::Stream> object for each encoding and pass it the latest entity body.

The resulting encoded body replaces the original one.

It returns the L<entity body|HTTP::Promise::Body> upon success, and upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 epilogue

Sets or gets an array of epilogue lines. An C<epilogue> is lines of text added after the last part of a C<multipart> message.

This returns an L<array object|Module::Generic::Array>

=head2 ext_vary

Boolean. Setting this to a true value and this will have L</decode_body> and L</encode_body> change the entity body file extension to reflect the encoding or decoding applied.

For example, if the entity body is stored in a text file C</tmp/DDAB03F0-F530-11EC-8067-D968FDB3E034.txt>, applying L</encode_body> with C<gzip> will create a new body text file such as C</tmp/DE13000E-F530-11EC-8067-D968FDB3E034.txt.gz>

=head2 guess_character_encoding

This will try to guess the entity body character encoding.

It returns the encoding found as a string, if any otherwise it returns an empty string (not undef), and upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

This method tries to guess variation of unicode character sets, such as C<UTF-16BE>, C<UTF-16LE>, and C<utf-8-strict>

It takes some optional parameters:

=over 4

=item * C<content>

A string or scalar reference of content data to perform the guessing against.

If this is not provided, this method will read up to 4096 bytes of data from the body to perform the guessing.

=back

See also L</content_charset>

=head2 header

Set or get the value returned by calling L<HTTP::Promise::Headers/header>

This is just a shortcut.

=head2 headers

Sets or get the L<entity headers object|HTTP::Promise::Headers>

=head2 header_as_string

Returns the entity headers as a string.

=head2 http_message

Sets or get the L<HTTP message object|HTTP::Promise::Message>

=head2 io_encoding

This tries hard to find out the character set of the entity body to be used with L<perlfunc/open> or L<perlfunc/binmode>

It returns a string, possibly empty if nothing could be guessed, and upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

It takes the following optional parameters:

=over 4

=item * C<alt_charset>

Alternative character set to be used if none other could be found nor worked.

=item * C<body>

The entity L<body object|HTTP::Promise::Body> to use.

=item * C<charset>

A string containing the charset you think is used and this will perform checks against it.

=item * C<charset_strict>

Boolean. If true, this will enable the guessing in more strict mode (using the C<FB_CROAK> flag on L<Encode>)

=item * C<content>

A string or a scalar reference of content data to the guessing against.

=item * C<default_charset>

The default charset to use when nothing else was found.

=back

=head2 is_binary

This checks if the data provided, or by default this entity body is binary data or not.

It returns true (1) if it is, and false (0) otherwise. It returns false if the data is empty.

This performs the similar checks that perl does (see L<perlfunc/-T>

It sets and L<error|Module::Generic/error> and return C<undef> upon error

You can optionally provide some data either as a string or as a scalar reference.

See also L</is_text>

For example:

    my $bool = $ent->is_binary;
    my $bool = $ent->is_binary( $string_of_data );
    my $bool = $ent->is_binary( \$string_of_data );

=head2 is_body_in_memory

Returns true if the entity body is an L<HTTP::Promise::Body::Scalar> object, false otherwise.

=head2 is_body_on_file

Returns true if the entity body is an L<HTTP::Promise::Body::File> object, false otherwise.

=head2 is_decoded

Boolean. Set get the decoded status of the entity body.

=head2 is_encoded

Boolean. Set get the encoded status of the entity body.

=head2 is_multipart

Returns true if this entity is a multipart message or not.

=head2 is_text

This checks if the data provided, or by default this entity body is text data or not.

It returns true (1) if it is, and false (0) otherwise. It returns true if the data is empty.

It sets and L<error|Module::Generic/error> and return C<undef> upon error

You can optionally provide some data either as a string or as a scalar reference.

See also L</is_binary>

For example:

    my $bool = $ent->is_text;
    my $bool = $ent->is_text( $string_of_data );
    my $bool = $ent->is_text( \$string_of_data );

=head2 make_boundary

Returns a uniquely generated multipart boundary created using L<Data::UUID>

=head2 make_multipart

This transforms the current entity into the first part of a <multipart/form-data> HTTP message.

For HTTP request, C<multipart/form-data> is the only valid C<Content-Type> for sending multiple data. L<rfc7578 in section 4.3|https://tools.ietf.org/html/rfc7578#section-4.3> states: "[RFC2388] suggested that multiple files for a single form field be transmitted using a nested "multipart/mixed" part. This usage is deprecated."

See also this L<Stackoverflow discussion|https://stackoverflow.com/questions/36674161/http-multipart-form-data-multiple-files-in-one-input/41204533#41204533> and L<this one too|https://stackoverflow.com/questions/51575746/http-header-content-type-multipart-mixed-causes-400-bad-request>

Of course, technically, nothing prevents an HTTP message (request or response) from being a C<multipart/mixed> or something else.

This method takes a multipart subtype, such as C<form-data>, or C<mixed>, etc and creates a multipart entity of which this current entity will become the first part. If no multipart subtype is specified, this defaults to C<form-data>.

It takes also an optional hash or hash reference of parameters.

Valid parameters are:

=over 4

=item * C<force>

Boolean. Forces the creation of a multipart even when the current entity is already a multipart.

This would have the effect of having the current entity become an embedded multipart into a new multipart entity.

=back

It returns the current entity object, modified, upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 make_singlepart

This transform the current entity into a simple, i.e. no multipart, message entity.

It returns false, but not C<undef> if this contains more than one part. It returns the current object upon success, or if this is already a simple entity message, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 mime_type

Returns this entity mime-type by calling L<HTTP::Promise::Headers/mime_type> and passing it whatever arguments were provided.

=head2 name

The name of this entity used for C<multipart/form-data> as defined in L<rfc7578|https://tools.ietf.org/html/rfc7578>

=head2 new_body

This is a convenient constructor to instantiate a new entity body. It takes a single argument, one of C<file>, C<form>, C<scalar> or C<string>

=over 4

=item * C<file>

Returns a new L<HTTP::Promise::Body::File> object

=item * C<form>

Returns a new L<HTTP::Promise::Body::Form> object

=item * C<scalar> or C<string>

Returns a new L<HTTP::Promise::Body::Scalar> object

=back

The constructor of each of those classes are passed whatever argument is provided to this method (except, of course, the initial argument).

For example:

    my $body = $ent->new_body( file => '/some/where/file.txt' );
    my $body = $ent->new_body( string => 'Hello world!' );
    my $body = $ent->new_body( string => \$scalar );
    # Same, but using indistinctly 'scalar'
    my $body = $ent->new_body( scalar => \$scalar );

It returns the newly instantiated object upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 open

This calls C<open> on the entity body object, if any, and passing it whatever argument was provided.

It returns the resulting L<filehandle object|Module::Generic::File::IO>, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 output_dir

Sets or gets the path to the directory used to store extracted files, when applicable.

=head2 parts

Sets or gets the L<array object|Module::Generic::Array> of entity part objects.

=head2 preamble

Sets or gets the L<array object|Module::Generic::Array> of preamble lines. C<preamble> is the lines of text that precedes the first part in a multipart message. Normally, this is never used in HTTP parlance.

=head2 print

Provided with a filehandle, or an L<HTTP::Promise::IO> object, and an hash or hash reference of options and this will print the current entity with all its parts, if any.

What this does internally is:

=over 4

=item 1. Call L</print_start_line>

=item 2. Call L</print_header>

=item 3. Call L</print_body>

=back

The only supported option is C<eol> which is the string to be used as a new line terminator. This is printed out just right after printing the headers. This defaults to C<\015\012>, which is C<\r\n>

It returns the current entity object upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 print_body

Provided with a filehandle, or an L<HTTP::Promise::IO> object, and an hash or hash reference of options and this will print the current entity body. This is possibly is a no-op if there is no entity body.

If the entity is a multipart message, this will call L</print> on all its L<entity parts|HTTP::Promise::Entity>.

It returns the current entity object upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 print_bodyhandle

Provided with a filehandle, or an L<HTTP::Promise::IO> object, and an hash or hash reference of options and this will print the current entity body.

This will first encode the body by calling L</encode> if encodings are set and the entity body is not yet marked as being encoded with L</is_encoded>

Supported options are:

=over 4

=item * C<binmode>

The character encoding to use for PerlIO when calling open.

=back

It returns the current entity object upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 print_header

This calls L<HTTP::Promise::Headers/print>, passing it whatever arguments were provided, and returns whatever value is returned from this method call. This is basically a convenient shortcut.

=head2 print_start_line

Provided with a filehandle, and an hash or hash reference of options and this will print the message C<start line>, if any.

A message C<start line> in HTTP parlance is the first line of a request or response, so something like:

    GET / HTTP/1.0

or for a response:

    HTTP/1.0 200 OK

It returns the current entity object upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 purge

This calls C<purge> on the body object, if any, and calls it also on every parts.

It returns the current entity object upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 save_file

Provided with an optional filepath and this will save the body to it unless this is an HTTP multipart message.

If no explicit filepath is provided, this will try to guess one from the C<Content-Disposition> header value, possibly striping it of any dangerous characters and making it a complete path using L</output_dir>

If no suitable filename could be found, ultimately, this will use a generated one using L<Module::Generic/new_tempfile> inherited by this class.

The file extension will be guessed from the entity body mime-type by checking the C<Content-Type> header or by looking directly at the entity body data using L<HTTP::Promise::MIME> that uses the XS module L<File::MMagic::XS> to perform the job.

If the entity body is encoded, it will decode it before saving it to the resulting filepath.

It returns the L<file object|Module::Generic::File> upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 stringify

This is an alias for L</as_string>

=head2 stringify_body

This is an alias for L</body_as_string>

=head2 stringify_header

This is an alias for L<HTTP::Promise::Headers/as_string>

=head2 suggest_encoding

Based on the entity body mime-type, this will guess what encoding is appropriate.

It does not provide any encoding for image, audio or video files who are usually already compressed and if the body size is below the threshold set with L</compression_min>.

This returns the encoding as a string upon success, an empty string if no suitable encoding could be found, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 textual_type

Returns true if this entity mime-type starts with C<text>, such as C<text/plain> or C<text/html> or starts with C<message>, such as C<message/http>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

=over 4
 
=item L<rfc2616 section 3.7.2 Multipart Types|http://tools.ietf.org/html/rfc2616#section-3.7.2>
 
=item L<rfc2046 section 5.1.1 Common Syntax|http://tools.ietf.org/html/rfc2046#section-5.1.1>
 
=item L<rfc2388 multipart/form-data|http://tools.ietf.org/html/rfc2388>
 
=item L<rfc2045|https://tools.ietf.org/html/rfc2045>
 
=back

L<Mozilla documentation on Content-Disposition and international filename|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition> and L<other Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types.>

L<Wikipedia|https://en.wikipedia.org/wiki/MIME#Multipart_messages>

L<On Unicode|https://perldoc.perl.org/Encode::Unicode>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
