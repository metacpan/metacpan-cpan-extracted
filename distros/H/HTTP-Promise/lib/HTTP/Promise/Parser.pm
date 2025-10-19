##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Parser.pm
## Version v0.2.3
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/25
## Modified 2025/10/19
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Parser;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'HTTP::Promise' );
    use parent qw( Module::Generic );
    use vars qw( @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION $DEBUG $EXCEPTION_CLASS
                 $CRLF $LWS $TEXT $TOKEN $HEADER $HTTP_VERSION $REQUEST $RESPONSE 
                 $MAX_HEADERS_SIZE $MAX_READ_BUFFER $MAX_BODY_IN_MEMORY_SIZE 
                 $DEFAULT_MIME_TYPE );
    use version;
    # use HTTP::Parser::XS 0.17 ();
    use HTTP::Parser2::XS 0.01 ();
    use HTTP::Promise::Entity;
    use HTTP::Promise::Headers;
    use HTTP::Promise::IO;
    use Module::Generic::File qw( sys_tmpdir );
    # use Nice::Try;
    use URI;
    use URI::Encode::XS;
    use Wanted;
    use constant (
        TYPE_URL_ENCODED => 'application/x-www-form-urlencoded',
    );
    our @EXPORT = ();
    our @EXPORT_OK = qw( parse_headers parse_request parse_request_line parse_response 
                         parse_response_line parse_version );
    our %EXPORT_TAGS = (
        'all' => [@EXPORT_OK],
        'request'  => [qw( parse_headers parse_request parse_request_line parse_version )],
        'response' => [qw( parse_headers parse_response parse_response_line parse_version )],
    );
    # rfc2616, section 2.2 on basic rules
    # <https://tools.ietf.org/html/rfc2616#section-2.2>
    our $CRLF     = qr/\x0D?\x0A/;
    our $LWS      = qr/$CRLF[\x09\x20]|[\x09\x20]/;
    our $TEXT     = qr/[\x20-\xFF]/;
    # !, #, $, %, &, ', *, +, -, ., 0..9, A..Z, ^, _, `, a..z, |, ~
    our $TOKEN    = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;
    # rfc2616, section 4.2 on message headers
    # <https://tools.ietf.org/html/rfc2616#section-4.2>
    # rfc7230, section 3.2
    # <https://tools.ietf.org/html/rfc7230#section-3.2>
    our $HEADER   = qr/($TOKEN+)$LWS*:$LWS*((?:$TEXT|$LWS)*)$CRLF/;
    # HTTP/1.0, HTTP/1.1, HTTP/2
    our $HTTP_VERSION  = qr/(?<http_protocol>HTTP\/(?<http_version>(?<http_vers_major>[0-9])(?:\.(?<http_vers_minor>[0-9]))?))/;
    # rfc7230 superseding rfc2616 on request line
    # <https://tools.ietf.org/html/rfc7230#page-21>
    our $REQUEST = qr/(?<method>$TOKEN+)[\x09\x20]+(?<uri>[\x21-\xFF]+)[\x09\x20]+(?<protocol>$HTTP_VERSION)$CRLF/;
    our $REQUEST_RFC2616 = qr/(?:$CRLF)*($TOKEN+)[\x09\x20]+([\x21-\xFF]+)(?:[\x09\x20]+($HTTP_VERSION))?$CRLF/;
    our $RESPONSE = qr/(?<protocol>$HTTP_VERSION)[\x09\x20]+(?<code>[0-9]{3})[\x09\x20]+(?<status>$TEXT*)$CRLF/;
    # 8Kb
    # Beyond this, we return a 413 Entity Too Large
    # Ref: <https://stackoverflow.com/questions/686217/maximum-on-http-header-values>
    our $MAX_HEADERS_SIZE = 8192;
    our $MAX_READ_BUFFER  = 2048;
    # 100Kb
    our $MAX_BODY_IN_MEMORY_SIZE = 102400;
    our $DEFAULT_MIME_TYPE = 'application/octet-stream';
    our $DEBUG    = 0;
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
    our $VERSION = 'v0.2.3';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{decode_body}    = 1;
    $self->{decode_headers} = 0;
    $self->{ignore_filename}= 0;
    $self->{max_body_in_memory_size} = $MAX_BODY_IN_MEMORY_SIZE;
    $self->{max_headers_size} = $MAX_HEADERS_SIZE;
    $self->{max_read_buffer}  = $MAX_READ_BUFFER;
    $self->{output_dir}     = sys_tmpdir();
    $self->{tmp_dir}        = undef;
    $self->{tmp_to_core}    = 0;
    $self->{_init_strict_use_sub}   = 1;
    $self->{_exception_class}       = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $dir = $self->output_dir;
    return( $self->error( "No output directory set." ) ) if( !defined( $dir ) || !length( $dir ) );
    return( $self->error( "Output directory set \"$dir\" does not exist." ) ) if( !$dir->exists );
    return( $self->error( "Output directory set \"$dir\" is not actually a directory." ) ) if( !$dir->is_dir );
    return( $self );
}

sub decode_body { return( shift->_set_get_boolean( 'decode_body', @_ ) ); }

sub decode_headers { return( shift->_set_get_boolean( 'decode_headers', @_ ) ); }

sub ignore_filename { return( shift->_set_get_boolean( 'ignore_filename', @_ ) ); }

sub looks_like_request
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "Invalid argument. You can only provide either a string or a scalar reference." ) ) if( ref( $this ) && !$self->_is_scalar( $this ) );
    my $ref = $self->_is_scalar( $this ) ? $this : \$this;
    if( $$ref =~ /^$REQUEST/ )
    {
        my $def = {%+};
        return( $def );
    }
    else
    {
        # undef is for errors
        return( '' );
    }
}

sub looks_like_response
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "Invalid argument. You can only provide either a string or a scalar reference." ) ) if( ref( $this ) && !$self->_is_scalar( $this ) );
    my $ref = $self->_is_scalar( $this ) ? $this : \$this;
    if( $$ref =~ /^$RESPONSE/ )
    {
        my $def = {%+};
        return( $def );
    }
    else
    {
        # undef is for errors
        return( '' );
    }
}

sub looks_like_what
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    # Shortcut
    return( '' ) if( !defined( $this ) );
    return( $self->error( "Invalid argument. You can only provide either a string or a scalar reference." ) ) if( ref( $this ) && !$self->_is_scalar( $this ) );
    my $ref = $self->_is_scalar( $this ) ? $this : \$this;
    # No need to go further
    return( '' ) if( !defined( $$ref ) || !length( $$ref ) );
    my( $type, $def );
    if( $$ref =~ /^$REQUEST/ )
    {
        $def = {%+};
        $type = 'request';
    }
    elsif( $$ref =~ /^$RESPONSE/ )
    {
        $def = {%+};
        $type = 'response';
    }
    # undef is for errors
    return( '' ) if( !defined( $def ) );
    $def->{type} = $type;
    return( $def );
}

sub max_body_in_memory_size { return( shift->_set_get_number( 'max_body_in_memory_size', @_ ) ); }

sub max_headers_size { return( shift->_set_get_number( 'max_headers_size', @_ ) ); }

sub max_read_buffer { return( shift->_set_get_number( 'max_read_buffer', @_ ) ); }

sub new_tmpfile
{
    my $self = shift( @_ );
    my $io;
    if( $self->tmp_to_core )
    {
        my $var = $self->new_scalar;
        $io = $var->open( '+>' ) || return( $self->pass_error( $var->error ) );
    }
    else
    {
        my $tmpdir = $self->tmp_dir;
        $io = $self->new_tempfile( $tmpdir ? ( dir => $tmpdir ) : () ) ||
            return( $self->pass_error );
        $io->open( '>', { binmode => 'raw', autoflush => 1 } ) || return( $self->pass_error( $io->error ) );
    }
    return( $io );
}

sub output_dir { return( shift->_set_get_file( 'output_dir', @_ ) ); }

sub parse
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "Nothing to parse was provided." ) );
    # Can be glob, scalar reference, file path
    my $io;
    if( $self->_is_glob( $this ) )
    {
        $io = $this;
    }
    elsif( $self->_is_scalar( $this ) )
    {
        $self->_load_class( 'Module::Generic::Scalar::IO' ) ||
            return( $self->pass_error );
        $io = Module::Generic::Scalar::IO->new( $this, '<' ) ||
            return( $self->pass_error( Module::Generic::Scalar::IO->error ) );
    }
    else
    {
        my $f = $self->new_file( $this ) || return( $self->pass_error );
        $io = $f->open( '<', { binmode => 'raw' } ) || return( $self->pass_error( $f->error ) );
    }
    return( $self->parse_fh( $io, @_ ) );
}

sub parse_data
{
    my $self = shift( @_ );
    return( $self->error( "Invalid argument. parse_data() only accepts either a string or something that stringifies." ) ) if( ref( $_[0] ) && !overload::Method( $_[0] => '""' ) );
    return( $self->parse( \"$_[0]" ) );
}

sub parse_fh
{
    my $self = shift( @_ );
    my $fh = shift( @_ );
    return( $self->error( "No filehandle was provided to read from." ) ) if( !defined( $fh ) );
    return( $self->error( "Filehandle provided (", overload::StrVal( $fh ), ") is not a valid filehandle." ) ) if( !$self->_is_glob( $fh ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my $reader;
    if( $reader = $opts->{reader} )
    {
        return( $self->error( "Reader object provided (", overload::StrVal( $reader ), ") is not a HTTP::Promise::IO." ) ) if( !$self->_is_a( $reader => 'HTTP::Promise::IO' ) );
    }
    else
    {
        $reader = HTTP::Promise::IO->new( $fh, max_read_buffer => $self->max_read_buffer, debug => $self->debug ) ||
            return( $self->pass_error( HTTP::Promise::IO->error ) );
    }
    # "It is RECOMMENDED that all HTTP senders and recipients support, at a minimum, request-line lengths of 8000 octets."
    # Ref: <https://tools.ietf.org/html/rfc7230#section-3.1.1>
    my $buff = $reader->getline( max_read_buffer => 8192 );
    # "A server that receives a method longer than any that it implements SHOULD respond with a 501 (Not Implemented) status code."
    # Ref: <https://tools.ietf.org/html/rfc7230#section-3.1.1>
    return( $self->pass_error( $reader->error ) ) if( !defined( $buff ) );
    unless( $opts->{request} || $opts->{response} )
    {
        # Ref: <https://tools.ietf.org/html/rfc7230#section-3.1.2>
        if( $buff =~ m,^(${HTTP_VERSION})[[:blank:]]+, )
        {
            $opts->{response} = 1;
        }
        # rfc7230, section 3.1
        # Ref: <https://tools.ietf.org/html/rfc7230#section-3.1>
        elsif( $buff =~ m,^(?:CONNECT|DELETE|GET|HEAD|OPTIONS|PATCH|POST|PUT|TRACE)[[:blank:]]+(\S+)[[:blank:]]+${HTTP_VERSION}, )
        {
            $opts->{request} = 1;
        }
        # Actually we accept an http message that does not have a first line.
        # We just won't know what it is for, but it is ok, since we return an entity object
#         else
#         {
#             return( $self->error( "Unknown http message type and no 'request' or 'response' boolean value was provided," ) );
#         }
    }
    
    # Maximum headers size is not oficial, but we definitely need to set some limit.
    # <https://security.stackexchange.com/questions/110565/large-over-sizesd-http-header-lengths-and-security-implications>
    my $max = $self->max_headers_size;
    my( $n, $def, $headers );
    $n = -1;
    while( $n != 0 )
    {
        $n = $reader->read( $buff, 2048, length( $buff ) );
        return( $self->pass_error( $reader->error ) ) if( !defined( $n ) );
        if( $n == 0 )
        {
            if( !length( $buff ) )
            {
                return( $self->error({ code => 400, message => "No data could be retrieved from filehandle." }) );
            }
            else
            {
                return( $self->error({ code => 425, message => "No headers data could be retrieved in the first " . length( $buff ) . " bytes of data read." }) );
            }
        }
        
        # If we know the type of http message we are dealing with, we use the fast XS method
        if( $opts->{request} || $opts->{response} )
        {
            $def = $self->parse_headers_xs( \$buff, $opts );
            # $def = $self->parse_headers( \$buff, $opts );
        }
        # otherwise, we use a more lenient one that does not require a request or response line
        else
        {
            $def = $self->parse_headers( \$buff, $opts );
        }
        
        if( !defined( $def ) )
        {
            # 400 Bad request
            return( $self->error({ code => 400, message => "Unable to find the headers in the request provided, within the first ${max} bytes of data. Do you need to increase the value for max_headers_size() ?" }) ) if( $self->error->code == 400 && length( $buff ) > $max );
            # Is it an error 425 Too Early, it means we need more data.
            next if( $self->error->code == 425 );
            # For other errors, we stop and pass the error received
            return( $self->pass_error );
        }
        else
        {
            $headers = $def->{headers} ||
                return( $self->error( "No headers object set by parse_headers_xs() !" ) );
            return( $self->error( "parse_headers_xs() did not return the headers length as an integer ($def->{length})" ) ) if( !$self->_is_integer( $def->{length} ) );
            return( $self->error( "Headers length returned by parse_headers_xs() ($def->{length}) is higher than our buffer size (", length( $buff ), ") !" ) ) if( $def->{length} > length( $buff ) );
            substr( $buff, 0, $def->{length}, '' );
            $reader->unread( $buff ) if( length( $buff ) );
            last;
        }
    }
    # We need to consume the blank line separating the headers and the body, so it does 
    # not become part of the body, and because it does not belong anywhere
    my $trash = $reader->read_until_in_memory( qr/${CRLF}/, include => 1 );
    
    my $ent = HTTP::Promise::Entity->new( headers => $headers, debug => $DEBUG );
    if( ( $opts->{request} || $opts->{response} ) && $def->{protocol} )
    {
        my $message;
        if( $opts->{request} )
        {
            $self->_load_class( 'HTTP::Promise::Request' ) || return( $self->pass_error );
            $message = HTTP::Promise::Request->new( @$def{qw( method uri headers )}, {
                protocol => $def->{protocol},
                version => $def->{version},
                debug => $DEBUG
            } ) ||
                return( $self->pass_error( HTTP::Promise::Request->error ) );
        }
        else
        {
            $self->_load_class( 'HTTP::Promise::Response' ) || return( $self->pass_error );
            $message = HTTP::Promise::Response->new( @$def{qw( code status headers )}, {
                protocol => $def->{protocol},
                version => $def->{version},
                debug => $DEBUG
            } ) ||
                return( $self->pass_error( HTTP::Promise::Response->error ) );
        }
        # Mutual assignment for convenience
        $message->entity( $ent );
        $ent->http_message( $message );
    }
    my $type = $ent->mime_type;
    my $part_ent;
    # Request body can be one of 3 types:
    # application/x-www-form-urlencoded
    # multipart/form-data
    # text/plain or other mime types
    # <https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST>
    if( $type =~ m,^multipart/,i )
    {
        $part_ent = $self->parse_multi_part( entity => $ent, reader => $reader ) ||
            return( $self->pass_error );
        # Post process to assign a name to each part, to make it easy to manipulate them
        for( $ent->parts->list )
        {
            if( my $dispo = $_->headers->content_disposition )
            {
                my $cd = $_->headers->new_field( 'Content-Disposition' => $dispo );
                return( $self->pass_error( $_->headers->error ) ) if( !defined( $cd ) );
                if( my $name = $cd->name )
                {
                    $_->name( $name );
                }
            }
        }
    }
    else
    {
        $part_ent = $self->parse_singleton( entity => $ent, reader => $reader ) ||
            return( $self->pass_error );
    }
    return( $ent );
}

sub parse_headers($$)
{
    my $self = shift( @_ );
    my $str  = $self->_get_args( shift( @_ ) );
    return( $self->pass_error ) if( !defined( $str ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{convert_dash} //= 0;
    $opts->{no_headers_ok} //= 0;
    if( !CORE::length( $$str ) )
    {
        return({
            length => 0,
            headers => HTTP::Promise::Headers->new,
        });
    }
    
    # Basic error catching
    if( $$str !~ /${CRLF}${CRLF}/ )
    {
        return( $self->error({ code => 425, message => 'Incomplete request, call again when there is more data.', class => $EXCEPTION_CLASS }) );
    }
    
    my $def = {};
    pos( $$str ) = 0;
    if( $$str =~ m,^(${HTTP_VERSION})[[:blank:]]+(?<code>\d{3})[[:blank:]]+(?<status>.*?)$CRLF,gc )
    {
        @$def{qw( protocol code status )} = @+{qw( http_protocol code status )};
        $def->{version} = version->parse( $+{http_version} );
    }
    # rfc7230, section 3.1
    # Ref: <https://tools.ietf.org/html/rfc7230#section-3.1>
    # CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE
    # But there could be others including non-standard ones
    elsif( $$str =~ m|^(?<method>[A-Z]{3,12})[[:blank:]]+(?<uri>\S+)[[:blank:]]+(${HTTP_VERSION})$CRLF|gc )
    {
        @$def{qw( method uri protocol )} = @+{qw( method uri http_protocol )};
        $def->{version} = version->parse( $+{http_version} );
    }
    # HTTP/0.9 "Simple Request"
    # See rfc1945, section 5
    # <https://tools.ietf.org/html/rfc1945#page-23>
    elsif( $$str =~ m|^(GET)[[:blank:]]+(\S+)[[:blank:]]*$CRLF|gc )
    {
        @$def{qw( method uri )} = ( $1, $2 );
        $def->{protocol} = 'HTTP/0.9';
        $def->{version} = version->parse( '0.9' );
        # There should not be any header in a simple request
        return( $self->error({ code => 400, message => 'Bad request', class => $EXCEPTION_CLASS }) ) if( $$str =~ /^$HEADER/ );
        $def->{length} = pos( $$str );
        $def->{headers} = HTTP::Promise::Headers->new;
        return( $def );
    }
    elsif( $$str =~ /^(?:[A-Z]+\/\d+\.\d+|[A-Z]+[[:blank:]\h]+(?!\:))/ )
    {
        my $type = $$str =~ m,^[A-Z]+\/\d+\.\d+, ? 'Response' : 'Request';
        return( $self->error({ code => 400, message => "Bad ${type}-Line", class => $EXCEPTION_CLASS }) );
    }

    if( pos( $$str ) == 0 && $$str !~ /^$HEADER/ )
    {
        return( $self->error({ code => 400, message => 'Bad request', class => $EXCEPTION_CLASS }) );
    }

    my $headers = $self->new_array;
    
    my $len = 0;
    # my $remain = CORE::length( $$str );
    # while( $$str =~ s/^$HEADER// )
    while( $$str =~ /\G$HEADER/gc )
    {
        # $len += ( $remain - CORE::length( $$str ) );
        # $remain = CORE::length( $$str );
        my( $n, $v ) = ( lc( $1 ), $2 );
        $n =~ tr/-/_/ if( $opts->{convert_dash} );
        $headers->push( $n => $v );
    }
    $len = pos( $$str );
    
    unless( $$str =~ /\G${CRLF}/gc )
    {
        my $type = $def->{code} ? 'response' : 'request';
        return( $self->error({ code => 400, message => "Bad ${type}", class => $EXCEPTION_CLASS }) );
    }

    foreach( @$headers )
    {
        s/$LWS+/\x20/g;
        s/^$LWS//;
        s/$LWS$//;
    }
    # return( want( 'LIST' ) ? $headers->list : $headers );
    $def->{length} = $len;
    $def->{headers} = HTTP::Promise::Headers->new( @$headers );
    return( $def );
}

sub parse_headers_xs($$)
{
    my $self = shift( @_ );
    my $str  = $self->_get_args( shift( @_ ) ) || return( $self->pass_error );
    my $opts = $self->_get_args_as_hash( @_ );
    if( ( !exists( $opts->{request} ) && !exists( $opts->{response} ) ) ||
        ( !length( $opts->{request} ) && !length( $opts->{response} ) ) )
    {
        return( $self->error({ code => 500, message => "Missing 'request' or 'response' property to ste how to parse the http headers.", class => $EXCEPTION_CLASS }) );
    }
    my $max_headers_size = $self->max_headers_size // 0;
    
    my $r = {};
    my $len;
    my $bkp_version;
    # try-catch
    local $@;
    eval
    {
        if( $opts->{request} )
        {
            # We have to do this, because of a bug in TTP::Parser2::XS where HTTP/2 is not supported.
            # We save the value and replace it with one supported and we put it back after in
            # the data we return.
            # <https://rt.cpan.org/Ticket/Display.html?id=142808>
            if( index( $$str, 'HTTP/2' ) != -1 )
            {
                if( $$str =~ s,^((?:\S+)[[:blank:]\h]+(?:\S+)[[:blank:]\h]+HTTP/)(2(?:\.\d)?),${1}1.1, )
                {
                    $bkp_version = $2;
                }
            }
            $len = HTTP::Parser2::XS::parse_http_request( $$str, $r );
        }
        elsif( $opts->{response} )
        {
            if( index( $$str, 'HTTP/2' ) != -1 )
            {
                if( $$str =~ s,^(HTTP/)(2(?:\.\d)?),${1}1.1, )
                {
                    $bkp_version = $2;
                }
            }
            $len = HTTP::Parser2::XS::parse_http_response( $$str, $r );
        }
    };
    if( $@ )
    {
        return( $self->error({ code => 400, message => $@, class => $EXCEPTION_CLASS }) );
    }
    
    if( $len == -1 )
    {
        return( $self->error({ code => 400, message => 'Bad request', class => $EXCEPTION_CLASS }) );
    }
    elsif( $len == -2 && $max_headers_size > 0 && length( $$str ) > $max_headers_size )
    {
        # 431: HTTP request header fields too large
        # 413: Request entity too large
        return( $self->error({ code => 413, message => 'Incomplete and too long request', class => $EXCEPTION_CLASS }) );
    }
    # Which one is best?
    # 406 Unacceptable
    # 411 Length required
    # 417 Expectation failed
    # 422 Unprocessable entity
    # 425 Too early
    elsif( $len == -2 )
    {
        return( $self->error({ code => 425, message => 'Incomplete request, call again when there is more data.', class => $EXCEPTION_CLASS }) );
    }
    # response headers:
    # {
    #   "_content_length" => 15,
    #   "_keepalive"      => 0,
    #   "_message"        => "OK",
    #   "_protocol"       => "HTTP/1.0",
    #   "_status"         => 200,
    #   "content-length"  => [15],
    #   "content-type"    => ["text/plain"],
    #   "host"            => ["example.com"],
    #   "user-agent"      => ["hoge"],
    # }
    # request headers:
    # {
    #   "_content_length" => 27,
    #   "_keepalive"      => 1,
    #   "_method"         => "POST",
    #   "_protocol"       => "HTTP/1.1",
    #   "_query_string"   => "",
    #   "_request_uri"    => "/test",
    #   "_uri"            => "/test",
    #   "content-length"  => [27],
    #   "content-type"    => ["application/x-www-form-urlencoded"],
    #   "host"            => ["foo.example"],
    # }
    $r->{_protocol} = "HTTP/${bkp_version}" if( defined( $bkp_version ) );
    # warn( "HTTP::Parser2::XS->parse_headers_xs: bytes read ($len) differs from _content_length (", ( $r->{_content_length} // '' ), ")\n" ) if( defined( $r->{_content_length} ) && length( $r->{_content_length} ) && $len != $r->{_content_length} && $self->_warnings_is_enabled );
    my $def = { length => $len };
    # Sadly enough, HTTP::Parser2::XS does not provide the order of the header and
    # although we could find out ourself, it would defeat the purpose of using an XS module
    # so we default to alphabetical order
    # If this is really important, you can use parse_request method instead
    my $headers = $self->new_array;
    # Skip keys that start with _. They are private properties
    for( sort( grep( !/^_/, keys( %$r ) ) ) )
    {
        my $k = $_;
        $k =~ tr/-/_/ if( $opts->{convert_dash} );
        $headers->push( $k => $r->{ $_ } );
    }
    $def->{headers} = HTTP::Promise::Headers->new( @$headers );
    if( $opts->{request} )
    {
        @$def{qw( method protocol )} = @$r{qw( _method _protocol )};
        $def->{uri} = URI->new( $r->{_request_uri} ) if( exists( $r->{_request_uri} ) && length( $r->{_request_uri} ) );
    }
    elsif( $opts->{response} )
    {
        @$def{qw( code status protocol )} = @$r{qw( _status _message _protocol )};
    }
    $def->{version} = $self->parse_version( $r->{_protocol} ) || return( $self->pass_error );
    # It seems 
    while( substr( $$str, 0, $len ) =~ /$CRLF($CRLF)$/ )
    {
        $len -= length( $1 );
    }
    $def->{length} = $len;
    return( $def );
}

sub parse_multi_part
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $ent = $opts->{entity} ||
        return( $self->error({ code => 500, message => "No entity object was provided." }) );
    my $reader = $opts->{reader} ||
        return( $self->error({ code => 500, message => "No reader object was provided." }) );
    my $headers = $ent->headers ||
        return( $self->error({ code => 500, message => "No headers object found in entity object." }) );
    my $ct = $headers->content_type;
    my $h = $headers->new_field( 'Content-Type' => $ct ) || return( $self->pass_error( $headers->error ) );
    my $boundary = $h->boundary ||
        return( $self->error( "No boundary could be found in the Content-Type header '$ct'" ) );
    my $max_in_memory = $self->max_body_in_memory_size;
    my $default_mime = $DEFAULT_MIME_TYPE || 'application/octet-stream';
    
    # Position ourself right after the first boundary, including the trailing CRLF sequence
    my $trash = $reader->read_until_in_memory( qr/--${boundary}${CRLF}/, include => 1, capture => 1 );
    return( $self->pass_error( $reader->error ) ) if( !defined( $trash ) );
    return( $self->error( "Unable to find the initial boundary '${boundary}'" ) ) if( !length( $trash ) );
    my $delim = $reader->last_delimiter;
    my $preamble;
    if( length( $delim ) )
    {
        $preamble = substr( $trash, 0, index( $trash, $delim ) );
        $self->_trim_crlf( \$preamble );
        $ent->preamble( [split( /$CRLF/, $preamble )] ) if( length( $preamble ) );
    }
        
    my( $buff, $mime, $def );
    while(1)
    {
        # I expect an header token and value, but if we find a CRLF sequence right now, 
        # this just means there is no header.
        my $hdr = $reader->read_until_in_memory( qr/(?:^${CRLF}|(?:(?:$TOKEN+)[\x09\x20]*\:(?:.+?)${CRLF}${CRLF}))/, include => 1 );
        return( $self->pass_error( $reader->error ) ) if( !defined( $hdr ) );
        last if( !length( $hdr ) );
        my( $ph, $file, $mime_type, $ext, $io );
        if( length( $hdr ) && $hdr !~ /^$CRLF$/ )
        {
            $def = $self->parse_headers( $hdr ) || return( $self->pass_error );
            $ph = $def->{headers};
            my $dispo = $ph->new_field( 'Content-Disposition' => $ph->content_disposition );
            # rfc7231, section 3.1.1.5 says we can assume applicatin/octet-stream if there
            # is no Content-Type header
            # <https://tools.ietf.org/html/rfc7231#section-3.1.1.5>
            $mime_type = $ph->mime_type( $default_mime );
        }
        # If no headers are set, we create a dummy object
        else
        {
            $reader->unread( $hdr ) if( $hdr =~ /^$CRLF$/ );
            $ph = HTTP::Promise::Headers->new;
        }
        my $part_ent = HTTP::Promise::Entity->new( headers => $ph, debug => $self->debug ) ||
            return( $self->pass_error( HTTP::Promise::Entity->error ) );
        if( defined( $mime_type ) && $mime_type eq 'multipart/form-data' )
        {
            # $sub_part_ent and $part_ent should be the same
            my $sub_part_ent = $self->parse_multi_part( entity => $part_ent, reader => $reader ) ||
                return( $self->pass_error );
            # We need to consume the boundary for this part
            # Position ourself just before the next delimiter, but do not include it.
            # That way, we can capture epilogue data, if any, and although rare in HTTP parlance.
            my $trash = $reader->read_until_in_memory( qr/${CRLF}--${boundary}(?:\-{2})?${CRLF}/, include => 1, capture => 1 );
            my $delim = $reader->last_delimiter;
            my $epilogue;
            if( length( $delim ) )
            {
                $epilogue = substr( $trash, 0, index( $trash, $delim ) );
                $self->_trim_crlf( \$epilogue );
                $ent->epilogue( [split( /$CRLF/, $epilogue )] ) if( length( $epilogue ) );
            }
            # Post process to assign a name to each part, to make it easy to manipulate them
            for( $part_ent->parts->list )
            {
                if( my $dispo = $_->headers->content_disposition )
                {
                    my $cd = $_->headers->new_field( 'Content-Disposition' => $dispo );
                    return( $self->pass_error( $_->headers->error ) ) if( !defined( $cd ) );
                    if( my $name = $cd->name )
                    {
                        $_->name( $name );
                    }
                }
            }
        }
        # Otherwise, we are dealing with a simple part
        else
        {
            my $sub_part_ent = $self->parse_singleton(
                entity => $part_ent,
                reader => $reader,
                read_until => qr/${CRLF}--${boundary}(?:\-{2})?${CRLF}/,
            ) || return( $self->pass_error );
        }
        $ent->parts->push( $part_ent );
        # Have we reached the last delimiter yet?
        my $last = $reader->last_delimiter;
        # We hit the ending delimiter, stop here.
        # If there are any epilogue, they will be dealt with by our caller
        last if( $last =~ /\-\-${boundary}\-\-${CRLF}$/ );
    }
    return( $ent );
}

sub parse_open
{
    my $self = shift( @_ );
    my $expr = shift( @_ ) ||
        return( $self->error( "No file to open was provided." ) );
    my $ent;
    my $f = $self->new_file( $expr ) ||
        return( $self->pass_error );
    my $io = $f->open ||
        return( $self->pass_error( $f->error ) );
    $ent = $self->parse( $io ) ||
        return( $self->pass_error );
    $io->close or return( $self->pass_error( $io->error ) );
    return( $ent );
}

sub parse_request($$)
{
    my $self = shift( @_ );
    my $str  = $self->_get_args( shift( @_ ) ) || return( $self->pass_error );
    my $opts = $self->_get_args_as_hash( @_ );
    my $req  = $self->parse_request_headers( $str, $opts ) || return( $self->pass_error );
    substr( $$str, 0, $req->{length}, '' );
    $req->{content} = $str;
    return( $req );
}

sub parse_request_headers($$)
{
    my $self = shift( @_ );
    my $str  = $self->_get_args( shift( @_ ) ) || return( $self->pass_error );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{request} = 1;
    return( $self->parse_headers_xs( $str, $opts ) );
}

sub parse_request_line($$)
{
    my $self = shift( @_ );
    my $str  = $self->_get_args( shift( @_ ) ) || return( $self->pass_error );
    my $len  = CORE::length( $$str );
    $$str =~ s/^$REQUEST// or return( $self->error({ code => 400, message => 'Bad request-line', class => $EXCEPTION_CLASS }) );
    my $res =
    {
    method => $1,
    path => $2,
    protocol => ( $3 || 'HTTP/0.9' ),
    length => ( $len - CORE::length( $$str ) ),
    };
    $res->{version} = $self->parse_version( $res->{protocol} );
    return( $res );
}

sub parse_request_pp($$)
{
    my $self = shift( @_ );
    my $str  = $self->_get_args( shift( @_ ) ) || return( $self->pass_error );
    my $req = $self->parse_headers( $str, @_ ) || return( $self->pass_error );
    substr( $$str, 0, $req->{length}, '' );
    $$str =~ s/^$CRLF// or return( $self->error({ code => 400, message => 'Bad request', class => $EXCEPTION_CLASS }) );
    if( $req->{version} < version->parse( '1.0' ) )
    {
        $$str eq '' or return( $self->error({ code => 400, message => 'Bad request', class => $EXCEPTION_CLASS }) );
    }
    $req->{content} = $str;
    return( $req );
}

sub parse_response($$)
{
    my $self = shift( @_ );
    my $str  = $self->_get_args( shift( @_ ) ) || return( $self->pass_error );
    my $opts = $self->_get_args_as_hash( @_ );
    my $resp  = $self->parse_response_headers( $str, $opts ) || return( $self->pass_error );
    substr( $$str, 0, $resp->{length}, '' );
    $resp->{content} = $str;
    return( $resp );
}

sub parse_response_headers($$)
{
    my $self = shift( @_ );
    my $str  = $self->_get_args( shift( @_ ) ) || return( $self->pass_error );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{response} = 1;
    return( $self->parse_headers_xs( $str, $opts ) );
}

sub parse_response_line($$)
{
    my $self  = shift( @_ );
    my $str  = $self->_get_args( shift( @_ ) ) || return( $self->pass_error );
    my $len  = CORE::length( $$str );
    $$str =~ s/^$RESPONSE// or return( $self->error({ code => 400, message => 'Bad Status-Line', class => $EXCEPTION_CLASS }) );
    my $res =
    {
    protocol => $1,
    code => $2,
    status => $3,
    length => ( $len - CORE::length( $$str ) ),
    };
    $res->{version} = $self->parse_version( $res->{protocol} );
    return( $res );
}

sub parse_response_pp($$)
{
    my $self = shift( @_ );
    my $str  = $self->_get_args( shift( @_ ) ) || return( $self->pass_error );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{no_headers_ok} = 1;
    my $resp = $self->parse_headers( $str, $opts ) || return( $self->pass_error );
    substr( $$str, 0, $resp->{length}, '' );
    $$str =~ s/^$CRLF// or return( $self->error({ code => 400, message => 'Bad response', class => $EXCEPTION_CLASS }) );
    $resp->{content} = $str;
    return( $resp );
}

# Called when there is no multipart
sub parse_singleton
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $ent = $opts->{entity} ||
        return( $self->error({ code => 500, message => "No entity object was provided." }) );
    my $reader = $opts->{reader} ||
        return( $self->error({ code => 500, message => "No reader object was provided." }) );
    my $headers = $ent->headers ||
        return( $self->error({ code => 500, message => "No headers object found in entity object." }) );
    my $type = $headers->type;
    my $read_until = $opts->{read_until};
    my $max_in_memory = $self->max_body_in_memory_size;
    # rfc7231, section 3.1.1.5 says we can assume applicatin/octet-stream if there
    # is no Content-Type header
    # <https://tools.ietf.org/html/rfc7231#section-3.1.1.5>
    my $default_mime = $DEFAULT_MIME_TYPE || 'application/octet-stream';
    my $len = $headers->content_length;
    my $chunk_size = 2048;
    my( $body, $file, $mime_type, $mime, $ext );
    my $data = '';
    my $total_bytes = 0;
    
    my $get_temp_file = sub
    {
        # Guessing extension
        $mime_type = $headers->mime_type( $default_mime );
        $self->_load_class( 'HTTP::Promise::MIME' ) || return( $self->pass_error );
        $mime = HTTP::Promise::MIME->new;
        $ext = $mime->suffix( $type );
        return( $self->pass_error( $mime->error ) ) if( !defined( $ext ) );
        $ext ||= 'dat';
        my $f = $self->new_tempfile( extension => $ext ) ||
            return( $self->pass_error );
        return( $f );
    };
    
    if( defined( $len ) && !defined( $read_until ) )
    {
        # Nothing to be done. The body is zero byte, like in HEAD request
        if( !$len )
        {
            #
        }
        # Too big, saving it to file
        elsif( $len > $max_in_memory )
        {
            # We cannot save this to file if the type is application/x-www-form-urlencoded
            if( $type eq TYPE_URL_ENCODED && $self->decode_body )
            {
                # Payload too large
                return( $self->error({ code => 413, message => "The data are url-encoded, but its total amount (${len}) exceeds the maximum allowed ($max_in_memory}). You may want to increase that limit or investigate this HTTP message." }) );
            }
            $file = $get_temp_file->() || return( $self->pass_error );
            my $io = $file->open( '+>', { binmode => 'raw', autoflush => 1 } ) || 
                return( $self->pass_error( $file->error ) );
            my $buff = '';
            my $bytes;
            $chunk_size = $len if( $chunk_size > $len );
            while( $bytes = $reader->read( $buff, $chunk_size ) )
            {
                $io->print( $buff ) || return( $self->pass_error( $io->error ) );
                # We do not want to read more than we should
                $chunk_size = ( $len - $total_bytes ) if( $total_bytes + $chunk_size > $len );
                $total_bytes += $bytes;
                last if( $total_bytes == $len );
            }
            $io->close;
            return( $self->error( "Error reading http body from filehandle: ", $reader->error ) ) if( !defined( $bytes ) );
        }
        else
        {
            my $bytes = $reader->read( $data, $len );
            return( $self->error( "Error reading HTTP body from filehandle: ", $reader->error ) ) if( !defined( $bytes ) );
            # Assignment used for the warning below
            $total_bytes = $bytes;
        }
        warn( ref( $self ), "->parse_singleton: Warning only: HTTP body size advertised ($len) does not match the size actually read from filehandle ($total_bytes)\n" ) if( $total_bytes != $len && warnings::enabled( 'HTTP::Promise' ) );
    }
    # No Content-Length defined or there is a boundary expected
    else
    {
        my $buff = '';
        my $bytes = -1;
        my $io;
        while( $bytes )
        {
            if( defined( $read_until ) )
            {
                $bytes = $reader->read_until( $buff, $chunk_size, { string => $read_until, ignore => 1, capture => 1 } );
            }
            else
            {
                $bytes = $reader->read( $buff, $chunk_size );
            }
            return( $self->pass_error( $reader->error ) ) if( !defined( $bytes ) );
            
            if( defined( $io ) )
            {
                $io->print( $buff ) || return( $self->pass_error( $io->error ) );
            }
            # The cumulative bytes total for this part exceeds the allowed maximum in memory
            elsif( ( length( $data ) + length( $buff ) ) > $max_in_memory )
            {
                if( $type eq TYPE_URL_ENCODED && $self->decode_body )
                {
                    # Payload too large
                    return( $self->error({ code => 413, message => sprintf( "The data are url-encoded, but its total amount so far (%d) is about to exceed the maximum allowed ($max_in_memory}). You may want to increase that limit or investigate this HTTP message.",length( $data ) )  }) );
                }
                $file = $get_temp_file->() || return( $self->pass_error );
                $io = $file->open( '+>', { binmode => 'raw', autoflush => 1 } ) ||
                    return( $self->pass_error( $file->error ) );
                $io->print( $data ) || return( $self->pass_error( $io->error ) );
                $data = '';
            }
            else
            {
                $data .= $buff;
            }
            # reader returns negative bytes if those are the last bytes read until it reached the boundary
            last if( $bytes < 0 );
        }
        $total_bytes = defined( $file ) ? $file->length : length( $data );
    }
    

    # If we used a file and the extension is 'dat', because we were clueless based on 
    # the provided Content-Type, or maybe even the Content-Type is absent, we use the 
    # XS module in HTTP::Promise::MIME to guess the mime-type based on the actual file
    # content
    if( defined( $file ) )
    {
        if( defined( $file ) && $mime_type eq $default_mime )
        {
            unless( $mime )
            {
                $self->_load_class( 'HTTP::Promise::MIME' ) || return( $self->pass_error );
                $mime = HTTP::Promise::MIME->new;
            }
            
            # Guess the mime type from the file magic
            my $mtype = $mime->mime_type( $file );
            return( $self->pass_error( $mime->error ) ) if( !defined( $mime_type ) );
            if( $mtype && $mtype ne $default_mime )
            {
                $mime_type = $mtype;
                # Also update the type value in HTTP::Promise::Headers
                # It does not affect the actual Content-Type header
                $headers->type( $mtype );
                my $new_ext = $mime->suffix( $mtype );
                return( $self->pass_error( $mime->error ) ) if( !defined( $new_ext ) );
                if( $new_ext && $new_ext ne $ext )
                {
                    my $new_file = $file->extension( $ext ) || return( $self->pass_error( $file->error ) );
                    my $this_file = $file->move( $new_file ) || return( $self->pass_error( $file->error ) );
                    $file = $this_file;
                }
            }
        }
        
        $body = $ent->new_body( file => $file ) ||
            return( $self->pass_error( $ent->error ) );
    }
    # in memory
    else
    {
        # If this is a application/x-www-form-urlencoded type, we save it as such, and
        # the HTTP::Promise::Body::Form makes those data accessible as an hash object
        if( defined( $type ) && $type eq TYPE_URL_ENCODED )
        {
            $body = $ent->new_body( form => $data ) ||
                return( $self->pass_error( $ent->error ) ); 
        }
        else
        {
            $body = $ent->new_body( string => $data ) ||
                return( $self->pass_error( $ent->error ) ); 
        }
    }
    $ent->body( $body );
    my $enc = $headers->content_encoding;
    if( $enc && $body->length && $self->decode_body( $enc ) )
    {
        $ent->decode_body( $enc ) || return( $self->pass_error( $ent->error ) );
        $ent->is_encoded(0);
    }
    return( $ent );
}

sub parse_version($$)
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    return( $self->error({ code => 400, message => "No data was provided to parse the http version", class => $EXCEPTION_CLASS }) ) if( !defined( $str ) || !length( $str ) );
    $str =~ m/^${HTTP_VERSION}$/ or 
        return( $self->error({ code => 400, message => "Bad HTTP-Version '$str'", class => $EXCEPTION_CLASS }) );
    my $major  = $+{http_vers_major};
    # May be undef if HTTP/2 for example
    my $minor  = $+{http_vers_minor};
    my $v = version->parse( $+{http_version} );
    return( want( 'LIST' ) ? ( $major, $minor ) : $v );
}

sub tmp_dir { return( shift->_set_get_file( 'tmp_dir', @_ ) ); }

sub tmp_to_core { return( shift->_set_get_boolean( 'tmp_to_core', @_ ) ); }

sub _get_args
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    if( !ref( $str ) )
    {
        $str = \"$str";
    }
    elsif( !$self->_is_scalar( $str ) )
    {
        return( $self->error({ code => 401, message => "Value provided (" . overload::StrVal( $str ) . ") is not a string", class => $EXCEPTION_CLASS }) );
    }
    return( $str );
}

sub _trim_crlf
{
    my $self = shift( @_ );
    my $ref  = shift( @_ );
    return( $ref ) if( !defined( $ref ) );
    die( "Bad argument. This must be provided a scalar reference.\n" ) if( !$self->_is_scalar( $ref ) );
    my $n = 0;
    substr( $$ref, $n, 1, '' ), $n++ while( substr( $$ref, $n, 1 ) eq "\015" || substr( $$ref, $n, 1 ) eq "\012" );
    $n = length( $$ref );
    $n-- while( substr( $$ref, ($n - 1), 1 ) eq "\015" || substr( $$ref, ($n - 1), 1 ) eq "\012" );
    substr( $$ref, $n, length( $$ref ), '' );
    return( $ref );
}

# NOTE: sub FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Parser - Fast HTTP Request & Response Parser

=head1 SYNOPSIS

    use HTTP::Promise::Parser;
    my $p = HTTP::Promise::Parser->new || 
        die( HTTP::Promise::Parser->error, "\n" );
    my $ent = $p->parse( '/some/where/http_request.txt' ) ||
        die( $p->error );
    my $ent = $p->parse( $file_handle ) ||
        die( $p->error );
    my $ent = $p->parse( $string ) ||
        die( $p->error );

=head1 VERSION

    v0.2.3

=head1 DESCRIPTION

This is an http request and response parser using XS modules whenever posible for speed and mindful of memory consumption.

As rfc7230 states in its L<section 3|https://tools.ietf.org/html/rfc7230#section-3>:

"The normal procedure for parsing an HTTP message is to read the start-line into a structure, read each header field into a hash table by field name until the empty line, and then use the parsed data to determine if a message body is expected. If a message body has been indicated, then it is read as a stream until an amount of octets equal to the message body length is read or the connection is closed."

Thus, L<HTTP::Promise> approach is to read the data, whether a HTTP request or response, a.k.a, an HTTP message, from a filehandle, possibly L<chunked|https://tools.ietf.org/html/rfc7230#section-4.1>, and to first read the message L<headers|HTTP::Promise::Headers> and parse them, then to store the HTTP message in memory if it is under a specified threshold, or in a file. If the size is unknown, it would be first read in memory and switched automatically to a file when it reaches the threshold.

Once the overall message body is stored, if it is a multipart type, L<this class|HTTP::Promise::Parser> reads each of its parts into memory or separate file depending on its size until there is no more part, using the L<stream reader|HTTP::Promise::IO>, which reads in chunks of bytes and not in lines. If the message body is a single part it is saved to memory or file depending on its size. Each part saved on file uses a file extension related to its L<mime type|HTTP::Promise::MIME>. Each of the parts are then accessible as a L<HTTP body object|HTTP::Promise::Body> via the L<HTTP::Promise::Entity/parts> method.

Note, however, that when dealing with multipart, this only recognises C<multipart/form-data>, anything else will be treated as data.

The overall HTTP message is available as an L<HTTP::Promise::Entity> object and returned.

If an error occurs, this module does not die, at least not voluntarily, but instead sets an L<error|Module::Generic/error> and returns C<undef>, so always make sure to check the returned value from method calls.

=head1 CONSTRUCTOR

=head2 new

This instantiates a new L<HTTP::Promise::Parser> object.

It takes the following options:

=over 4

=item * C<decode_body>

Boolean. If enabled, this will have this interface automatically decode the entity body upon parsing. Default is true.

=item * C<decode_headers>

Boolean. If enabled, this will decode headers, which is used for decoding filename value in C<Content-Encoding>. Default is false.

=item * C<ignore_filename>

Boolean. Wether the filename provided in an C<Content-Disposition> should be ignored or not. This defaults to false, but actually, this is not used and the filename specified in a C<Content-Disposition> header field is never used. So, this is a no-op and should be removed.

=item * C<max_body_in_memory_size>

Integer. This is the threshold beyond which an entity body that is initially loaded into memory will switched to be loaded into a file on the local filesystem when it is a true value and exceeds the amount specified.

By defaults, this has the value set by the class variable C<$MAX_BODY_IN_MEMORY_SIZE>, which is 102400 bytes or 100K

=item * C<max_headers_size>

Integer. This is the threshold size in bytes beyond which HTTP headers will trigger an error. This defaults to the class variable C<$MAX_HEADERS_SIZE>, which itself is set by default to 8192 bytes or 8K

=item * C<max_read_buffer>

Integer. This is the read buffer size. This is used for L<HTTP::Promise::IO> and this defaults to 2048 bytes (2Kb).

=item * C<output_dir>

Filepath of the directory to be used to save entity body, when applicable.

=item * C<tmp_dir>

Set the directory to use when creating temporary files.

=item * C<tmp_to_core>

Boolean. When true, this will set the temporary file to an in-memory space.

=back

=head1 METHODS

=head2 decode_body

Boolean. If enabled, this will have this interface automatically decode the entity body upon parsing. Default is true.

=head2 decode_headers

Boolean. If enabled, this will decode headers, which is used for decoding filename value in C<Content-Encoding>. Default is false.

=head2 ignore_filename

Boolean. Wether the filename provided in an C<Content-Disposition> should be ignored or not. This defaults to false, but actually, this is not used and the filename specified in a C<Content-Disposition> header field is never used. So, this is a no-op and should be removed.

=head2 looks_like_request

Provided with a string or a scalar reference, and this returns an hash reference containing details of the request line attributes if it is indeed a request, or an empty string if it is not a request.

It sets an L<error|Module::Generic/error> and returns C<undef> upon error.

The following attributes are available:

=over 4

=item C<http_version>

The HTTP protocol version used. For example, in C<HTTP/1.1>, this would be C<1.1>, and in C<HTTP/2>, this would be C<2>.

=item C<http_vers_minor>

The HTTP protocol major version used. For example, in C<HTTP/1.0>, this would be C<1>, and in C<HTTP/2>, this would be C<2>.

=item C<http_vers_minor>

The HTTP protocol minor version used. For example, in C<HTTP/1.0>, this would be C<0>, and in C<HTTP/2>, this would be C<undef>.

=item C<method>

The HTTP request method used. For example in C<GET / HTTP/1.1>, this would be C<GET>. This uses the L<rfc7231 semantics|https://tools.ietf.org/html/rfc7231#section-4>, which means any token even non-standard ones would match.

=item C<protocol>

The HTTP protocol used, e.g. C<HTTP/1.0>, C<HTTP/1.1>, C<HTTP/2>, etc...

=item C<uri>

The request URI. For example in C<GET / HTTP/1.1>, this would be C</>

=back

    my $ref = $p->looks_like_request( \$str );
    # or
    # my $ref = $p->looks_like_request( $str );
    die( $p->error ) if( !defined( $ref ) );
    if( $ref )
    {
        say "Request method $ref->{method}, uri $ref->{uri}, protocol $ref->{protocol}, version major $ref->{http_vers_major}, version minor $ref->{http_vers_minor}";
    }
    else
    {
        say "This is not an HTTP request.";
    }

=head2 looks_like_response

Provided with a string or a scalar reference, and this returns an hash reference containing details of the response line attributes if it is indeed a response, or an empty string if it is not a response.

It sets an L<error|Module::Generic/error> and returns C<undef> upon error.

The following attributes are available:

=over 4

=item C<code>

The 3-digits HTTP response code. For example in C<HTTP/1.1 200 OK>, this would be C<200>.

=item C<http_version>

The HTTP protocol version used. For example, in C<HTTP/1.1>, this would be C<1.1>, and in C<HTTP/2>, this would be C<2>.

=item C<http_vers_minor>

The HTTP protocol major version used. For example, in C<HTTP/1.0>, this would be C<1>, and in C<HTTP/2>, this would be C<2>.

=item C<http_vers_minor>

The HTTP protocol minor version used. For example, in C<HTTP/1.0>, this would be C<0>, and in C<HTTP/2>, this would be C<undef>.

=item C<protocol>

The HTTP protocol used, e.g. C<HTTP/1.0>, C<HTTP/1.1>, C<HTTP/2>, etc...

=item C<status>

The response status text. For example in C<HTTP/1.1 200 OK>, this would be C<OK>.

=back

    my $ref = $p->looks_like_response( \$str );
    # or
    # my $ref = $p->looks_like_response( $str );
    die( $p->error ) if( !defined( $ref ) );
    if( $ref )
    {
        say "Response code $ref->{code}, status $ref->{status}, protocol $ref->{protocol}, version major $ref->{http_vers_major}, version minor $ref->{http_vers_minor}";
    }
    else
    {
        say "This is not an HTTP response.";
    }

=head2 looks_like_what

Provided with a string or a scalar reference, and this returns an hash reference containing details of the HTTP message first line attributes if it is indeed an HTTP message.

The attributes available depends on the type of HTTP message determined and are described in details in L</looks_like_request> and L</looks_like_response>. In addition to those, it also returns the attribute C<type>, which is a string representing the type of HTTP message this is, i.e. either C<request> or C<response>.

If this does not match either an HTTP request or HTTP response, it returns an empty string.

    my $ref = $p->looks_like_what( \$str );
    die( $p->error ) if( !defined( $ref ) );
    say "This is a ", ( $ref ? $ref->{type} : 'unknown' ), " HTTP message.";

    my $ref = $p->looks_like_what( \$str );
    die( $p->error ) if( !defined( $ref ) );
    if( !$ref )
    {
        say "This is unknown.";
    }
    else
    {
        say "This is a HTTP $ref->{type} with protocol version $ref->{http_version}";
    }

=head2 max_body_in_memory_size

Integer. This is the threshold beyond which an entity body that is initially loaded into memory will switched to be loaded into a file on the local filesystem when it is a true value and exceeds the amount specified.

By defaults, this has the value set by the class variable C<$MAX_BODY_IN_MEMORY_SIZE>, which is 102400 bytes or 100K

=head2 max_headers_size

Integer. This is the threshold size in bytes beyond which HTTP headers will trigger an error. This defaults to the class variable C<$MAX_HEADERS_SIZE>, which itself is set by default to 8192 bytes or 8K

=head2 max_read_buffer

Integer. This is the read buffer size. This is used for L<HTTP::Promise::IO> and this defaults to 2048 bytes (2Kb).

=head2 new_tmpfile

Creates a new temporary file. If C<tmp_to_core> is set to true, this will create a new file using a L<scalar object|Module::Generic::Scalar>, or it will create a new temporary file under the directory set with the object parameter C<tmp_dir>. The filehandle binmode is set to C<raw>.

It returns a filehandle upon success, or upon error, it sets an L<error|Module::Generic/error> and return C<undef>.

=head2 output_dir

The filepath to the output directory. This is used when saving entity bodies on the filesystem.

=head2 parse

This takes a scalar reference of data, a glob or a file path, and will parse the HTTP request or response by calling L</parse_fh> and pass it whatever options it received.

It returns an L<entity object|HTTP::Promise::Entity> upon success and upon error, it sets an L<error|Module::Generic/error> and return C<undef>.

=head2 parse_data

This takes a string or a scalar reference and returns an L<entity object|HTTP::Promise::Entity> upon success and upon error, it sets an L<error|Module::Generic/error> and return C<undef>

=head2 parse_fh

This takes a filehandle and parse the HTTP request or response, and returns an L<entity object|HTTP::Promise::Entity> upon success and upon error, it sets an L<error|Module::Generic/error> and return C<undef>.

It takes also an hash or hash reference of the following options:

=over 4

=item * C<reader>

An L<HTTP::Promise::IO>. If this is not provided, a new one will be created. Note that data will be read using this reader.

=item * C<request>

Boolean. Set this to true to indicate the data is an HTTP request. If neither C<request> nor C<response> is provided, the parser will attempt guessing it.

=item * C<response>

Boolean. Set this to true to indicate the data is an HTTP response. If neither C<request> nor C<response> is provided, the parser will attempt guessing it.

=back

=head2 parse_headers

This takes a string or a scalar reference including a scalar object, such as L<Module::Generic::Scalar>, and an optional hash or hash reference of parameters and parse the headers found in the given string, if any at all.

It returns an hash reference with the same property names and values returned by L</parse_headers_xs>.

This method uses pure perl.

Supported options are:

=over 4

=item * C<convert_dash>

Boolean. If true, this will convert C<-> in header fields to C<_>. Default is false.

=item * C<no_headers_ok>

Boolean. If set to true, this won't trigger if there is no headers

=back

=head2 parse_headers_xs

    my $def = $p->parse_headers_xs( $http_request_or_response );
    my $def = $p->parse_headers_xs( $http_request_or_response, $options_hash_ref );

This takes a string or a scalar reference including a scalar object, such as L<Module::Generic::Scalar>, and an optional hash or hash reference of parameters and parse the headers found in the given string, if any at all.

It returns a dictionary as an hash reference upon success, and it sets an L<error|Module::Generic/error> with an http error code set and returns C<undef> upon error.

Supported options are:

=over 4

=item * C<convert_dash>

Boolean. If true, this will convert C<-> in header fields to C<_>. Default is false.

=item * C<request>

Boolean. If true, this will parse the string assuming it is a request header.

=item * C<response>

Boolean. If true, this will parse the string assuming it is a response header.

=back

The properties returned in the dictionary depend on whether C<request> or C<response> were enabled.

For C<request>:

=over 4

=item * C<headers>

An L<HTTP::Promise::Headers> object.

=item * C<length>

The length in bytes of the headers parsed.

=item * C<method>

The HTTP method such as C<GET>, or C<HEAD>, C<POST>, etc.

=item * C<protocol>

String, such as C<HTTP/1.1> or C<HTTP/2>

=item * C<uri>

String, the request URI, such as C</>

=item * C<version>

This is a L<version> object and contains a value such as C<1.1>, so you can do something like:

    if( $def->{version} >= version->parse( '1.1' ) )
    {
        # Do something
    }

=back

For C<response>:

=over 4

=item * C<code>

The HTTP status code, such as C<200>

=item * C<headers>

An L<HTTP::Promise::Headers> object.

=item * C<length>

The length in bytes of the headers parsed. This is useful so you can then remove it from the string you provided:

    my $resp = <<EOT;
    HTTP/1.1 200 OK
    Content-Type: text/plain

    Hello world!
    EOT
    my $def = $p->parse_headers_xs( \$resp, response => 1 ) || die( $p->error );
    $str =~ /^\r?\n//;
    substr( $str, 0, $def->{length} ) = '';
    # $str now contains the body, i.e.: "Hello world!\n"

=item * C<status>

String, the HTTP status, i.e. something like C<OK>

=item * C<protocol>

String, such as C<HTTP/1.1>

=item * C<version>

This is a L<version> object and contains a value such as C<1.1>, so you can do something like:

    if( $def->{version} >= version->parse( '1.1' ) )
    {
        # Do something
    }

=back

If not enough data was provided to parse the headers, this will return an L<error object|Module::Generic/error> with code set to C<425> (Too early).

If the headers is incomplete and the cumulated size exceeds the value set with L</max_headers_size>, this returns an L<error object|Module::Generic/error> with code set to C<413> (Request entity too large).

If there are other issues with the headers, this sets the error code to C<400> (Bad request), and for any other error, this returns an error object without code.

=head2 parse_multi_part

This takes an hash or hash reference of options and parse an HTTP multipart portion of the HTTP request or response.

It returns an L<entity object|HTTP::Promise::Entity> upon success and upon error it sets an L<error object|Module::Generic/error> and returns C<undef>.

Supported options are:

=over 4

=item * C<entity>

The L<HTTP::Property::Entity> object to which this multipart belongs.

=item * C<reader>

The L<HTTP::Property::Reader> used for reading the data chunks from the filehandle.

=back

=head2 parse_open

Provided with a filepath, and this will open it in read mode, parse it and return an L<entity object|HTTP::Promise::Entity>.

If there is an error, this returns C<undef> and you can retrieve the error by calling L<Module::Generic/error> which is inherited by this module.

=head2 parse_request

This takes a string or a scalar reference including a scalar object, such as L<Module::Generic::Scalar>, and an optional hash or hash reference of parameters and parse the request found in the given string, including the header and the body.

It returns a dictionary as an hash reference upon success, and it sets an L<error|Module::Generic/error> with an http error code set and returns C<undef> upon error.

The properties returned are the same as the ones returned for a C<request> by L</parse_headers_xs>, and also sets the C<content> property containing the body data of the request.

Obviously this works well for simple request, i.e. not multipart ones, otherwise the entire body, whatever that is, will be stored in C<content>

=head2 parse_request_headers

This is an alias and is equivalent to calling L</parse_headers_xs> and setting the C<request> option.

=head2 parse_request_line

This takes a string or a scalar reference including a scalar object, such as L<Module::Generic::Scalar>, and parse the reuqest line returning an hash reference containing 4 properties: C<method>, C<path>, C<protocol>, C<version>

=head2 parse_request_pp

This is the same as L</parse_request>, except it uses the pure perl method L</parse_headers> to parse the headers instead of the XS one.

=head2 parse_response

This takes a string or a scalar reference including a scalar object, such as L<Module::Generic::Scalar>, and an optional hash or hash reference of parameters and parse the response found in the given string, including the header and the body.

It returns a dictionary as an hash reference upon success, and it sets an L<error|Module::Generic/error> with an http error code set and returns C<undef> upon error.

The properties returned are the same as the ones returned for a C<response> by L</parse_headers_xs>, and also sets the C<content> property containing the body data of the response.

=head2 parse_response_headers

This is an alias and is equivalent to calling L</parse_headers_xs> and setting the C<response> option.

=head2 parse_response_line

This takes a string or a scalar reference including a scalar object, such as L<Module::Generic::Scalar>, and parse the reuqest line returning an hash reference containing 4 properties: C<method>, C<path>, C<protocol>, C<version>

=head2 parse_response_pp

This is the same as L</parse_response>, except it uses the pure perl method L</parse_headers> to parse the headers instead of the XS one.

=head2 parse_singleton

Provided with an hash or hash reference of options and this parse a simple entity body.

It returns an L<entity object|HTTP::Promise::Entity> upon success and upon error it sets an L<error object|Module::Generic/error> and returns C<undef>.

Supported options are:

=over 4

=item * C<entity>

The L<HTTP::Property::Entity> object to which this multipart belongs.

=item * C<read_until>

A string or a regular expression that indicates the string up to which to read data from the filehandle.

=item * C<reader>

The L<HTTP::Property::Reader> used for reading the data chunks from the filehandle.

=back

=head2 parse_version

This takes an HTTP version string, such as C<HTTP/1.1> or C<HTTP/2> and returns its major and minor as a 2-elements array in list context, or just the L<version> object in scalar context.

=head2 tmp_dir

Sets or gets the temporary directory to use when creating temporary files.

When set, this returns a L<file object|Module::Generic::File>

=head2 tmp_to_core

Boolean. When set to true, this will store data in memory rather than in a file on the filesystem.

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<rfc6266 on Content-Disposition|https://datatracker.ietf.org/doc/html/rfc6266>,
L<rfc7230 on Message Syntax and Routing|https://tools.ietf.org/html/rfc7230>,
L<rfc7231 on Semantics and Content|https://tools.ietf.org/html/rfc7231>,
L<rfc7232 on Conditional Requests|https://tools.ietf.org/html/rfc7232>,
L<rfc7233 on Range Requests|https://tools.ietf.org/html/rfc7233>,
L<rfc7234 on Caching|https://tools.ietf.org/html/rfc7234>,
L<rfc7235 on Authentication|https://tools.ietf.org/html/rfc7235>,
L<rfc7578 on multipart/form-data|https://tools.ietf.org/html/rfc7578>,
L<rfc7540 on HTTP/2.0|https://tools.ietf.org/html/rfc7540>

L<Mozilla documentation on HTTP protocol|https://developer.mozilla.org/en-US/docs/Web/HTTP/Resources_and_specifications>

L<Mozilla documentation on HTTP messages|https://developer.mozilla.org/en-US/docs/Web/HTTP/Messages>

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
