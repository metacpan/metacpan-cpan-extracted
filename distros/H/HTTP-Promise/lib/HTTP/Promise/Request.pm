##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Request.pm
## Version v0.1.0_2
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/21
## Modified 2022/03/21
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Request;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTTP::Promise::Message );
    use vars qw( $VERSION $EXCEPTION_CLASS $KNOWN_METHODS $KNOWN_METHODS_I $TIMEOUT
                 $DEFAULT_MIME_TYPE $DEFAULT_METHOD $DEFAULT_PROTOCOL $SCHEME_RE $INTL_URI_RE );
    use Cookie::Jar;
    use Crypt::Misc 0.076;
    # use HTTP::Parser2::XS 0.01 ();
    use HTTP::Promise::Exception;
    use HTTP::Promise::Parser;
    use HTTP::Promise::Stream;
    use Nice::Try v1.2.0;
    use Regexp::Common qw( URI net );
    # URI::Fast is great, but only supports simple protocols
    # use URI::Fast 0.55;
    use URI 5.10;
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
    # rc7231, section 4.1
    # Ref: <https://datatracker.ietf.org/doc/html/rfc7231#section-4.1>
    # + PATCH
    # HTTP "method token is case-sensitive"
    # rfc7231, section 4.1 <https://tools.ietf.org/html/rfc7231#section-4.1>
    # our $KNOWN_METHODS = qr/^(?:CONNECT|DELETE|GET|HEAD|OPTIONS|PATCH|POST|PUT|TRACE)$/;
    local $" = '|';
    my @methods = qw( CONNECT DELETE GET HEAD OPTIONS PATCH POST PUT TRACE );
    our $KNOWN_METHODS = qr/(?:@methods)/;
    our $KNOWN_METHODS_I = qr/(?:@methods)/i;
    our $TIMEOUT = 10;
    our $DEFAULT_MIME_TYPE = 'application/octet-stream';
    our $DEFAULT_METHOD = 'GET';
    our $DEFAULT_PROTOCOL = 'HTTP/1.1';
    # Borrowed from URI::_server
    our $GROSS_URI_RE  = qr{(?<scheme>(?:https?:)?)//(?<host>[^/?\#]*)(?<rest>.*)};
    # [\x00-\x7f]
    our $INTL_URI_RE  = qr{(?<scheme>(?:https?:)?)//(?<host>[^\x00-\x7f]+\.[^/?\#]*)(?<rest>.*)};
    our $VERSION = 'v0.1.0_2';
};

use strict;
use warnings;

# $req->new( $method, $uri, $headers, $content, k1 => v1, k2 => v2);
# $req->new( $method, $uri, $headers, $content, { k1 => v1, k2 => v2 });
# $req->new( $method, $uri, $headers, k1 => v1, k2 => v2);
# $req->new( $method, $uri, $headers, { k1 => v1, k2 => v2 });
# $req->new( $method, $uri, k1 => v1, k2 => v2);
# $req->new( $method, k1 => v1, k2 => v2);
# $req->new( k1 => v1, k2 => v2 );
sub init
{
    my $self = shift( @_ );
    my( $method, $uri );
    my $iKNOWN_METHODS = qr/$KNOWN_METHODS/i;
    if( @_ )
    {
        if( @_ == 1 && ref( $_[0] ) eq 'HASH' )
        {
            my $opts = $_[0];
            ( $method, $uri ) = CORE::delete( @$opts{qw( method uri )} );
        }
        elsif( @_ >= 2 &&
               defined( $_[0] ) && 
               # rfc7230 says methods are case sensitive, so unless this is an unknown method we care about the case
               ( $_[0] =~ /^(?:$KNOWN_METHODS)$/ || ( $_[0] =~ /^[A-Za-z]{3,12}$/ && $_[0] !~ /^(?:$KNOWN_METHODS_I)$/i ) ) &&
               (
                   ( defined( $_[1] ) && $_[1] =~ m,^(?:$RE{URI}{HTTP}|$RE{URI}{HTTP}{-scheme => 'https'}|(?:https?\:\/{2}\[?(?:$RE{net}{IPv4}|$RE{net}{IPv6}|\:{2}1)\]?(?:\:\d+)?)|$INTL_URI_RE|/), ) || 
                   !defined( $_[1] )
               ) )
        {
            ( $method, $uri ) = splice( @_, 0, 2 );
        }
        else
        {
            return( $self->error( "Invalid parameters received. I was expecting either an hash reference or at least a method and a valid uri, but instead got: '", join( "', '", @_ ), "'" ) );
        }
    }
    $self->{default_protocol} = $DEFAULT_PROTOCOL;
    # properties headers and content are set by our parent class HTTP::Promise::Message
    $self->{method}         = $method;
    $self->{timeout}        = $TIMEOUT;
    $self->{uri}            = $uri;
    # Should as_string return an absolute uri or just the absolute path?
    $self->{uri_absolute}   = 0;
    $self->{_init_strict_use_sub} = 1;
    $self->{_init_params_order}   = [qw( content headers )];
    $self->{_exception_class} = $EXCEPTION_CLASS;
    # $self->SUPER::init( ( defined( $headers ) ? $headers : () ), @_ ) || return( $self->pass_error );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub accept_decodable
{
    my $self = shift( @_ );
    return( $self->header( 'Accept-Encoding', $self->decodable->join( ', ' )->scalar ) );
}

sub clone
{
    my $self = shift( @_ );
    my $new = $self->SUPER::clone;
    $new->method( $self->method );
    $new->uri( $self->uri );
    return( $new );
}

# NOTE: method content is inherited from HTTP::Promise::Message

sub cookie_jar { return( shift->_set_get_object( 'cookie_jar', 'Cookie::Jar', @_ ) ); }

sub default_protocol { return( shift->_set_get_scalar_as_object( 'default_protocol', @_ ) ); }

sub dump
{
    my $self = shift( @_ );
    my $start_line = $self->start_line;
    return( $self->SUPER::dump( preheader => $start_line ) );
}

sub headers { return( shift->_set_get_object_without_init( 'headers', 'HTTP::Promise::Headers', @_ ) ); }

sub make_form_data
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    $self->_load_class( 'HTTP::Promise::Entity' ) || return( $self->pass_error );
    $self->_load_class( 'HTTP::Promise::Headers' ) || return( $self->pass_error );
    my $ent = HTTP::Promise::Entity->new( debug => $self->debug );
    my( $headers, $ct );
    if( $headers = $self->headers )
    {
        $ct = $headers->new_field( 'Content-Type' => $headers->content_type );
        $ct->boundary( $ent->make_boundary ) unless( $ct->boundary );
    }
    else
    {
        $headers = HTTP::Promise::Headers->new;
        $ct = $headers->new_field( 'Content-Type' );
        my $boundary = $ent->make_boundary;
        $ct->boundary( $boundary );
    }
    $ent->headers( $headers );
    $ct->type( 'multipart/form-data' );
    $headers->content_type( "$ct" );
    $self->entity( $ent );
    
    if( $self->_is_a( $this => 'HTTP::Promise::Body::Form' ) )
    {
        my $form_data = $this->as_form_data ||
            return( $self->pass_error( $this->error ) );
        my $parts = $form_data->make_parts ||
            return( $self->pass_error( $form_data->error ) );
        $ent->parts( $parts );
        return( $ent );
    }
    elsif( $self->_is_a( $this => 'HTTP::Promise::Body::Form::Data' ) )
    {
        my $parts = $this->make_parts ||
            return( $self->pass_error( $this->error ) );
        $ent->parts( $parts );
        return( $ent );
    }
    
    my $args = $self->_is_array( $this ) ? $this : [%$this];
    for( my $i = 0; $i < scalar( @$args ); $i += 2 )
    {
        my $k = $args->[$i];
        my $v = $args->[$i+1];
        # Content-Type: image/gif
        # Content-Transfer-Encoding: base64
        # Content-Disposition: inline; filename="3d-vise.gif"
        
        # Content-Disposition: form-data; name="file_upload"; filename="&#22825;&#29399;.png"
        # Content-Type: image/png
        
        my $def;
        # This will be true also for HTTP::Promise::Body::File, because it inherits from Module::Generic::File
        if( $self->is_a( $v => 'Module::Generic::File' ) )
        {
            $def =
            {
            filename => $v->basename,
            type => ( $v->finfo->mime_type || $DEFAULT_MIME_TYPE ),
            };
        }
        # An hash referenece can be passed as the value to provide granularity.
        # It can be used for regular scalar or file upload
        elsif( ref( $v ) eq 'HASH' )
        {
            $def = $v;
            my $f;
            if( $def->{file} )
            {
                $f = $self->_is_a( $def->{file} => 'Module::Generic::File' )
                    ? $def->{file}
                    : $self->new_file( $def->{file} );
                return( $self->pass_error ) if( !defined( $f ) );
                $def->{file} = $f;
            }
            
            if( $f && 
                !$def->{filename} && 
                ( !$def->{headers} || 
                  ( ref( $def->{headers} ) ne 'ARRAY' && 
                    !$self->_is_a( $def->{headers} => 'HTTP::Promise::Headers' )
                  ) ||
                  (
                    $self->_is_a( $def->{headers} => 'HTTP::Promise::Headers' ) &&
                    $def->{headers}->content_disposition->index( 'filename' ) == -1
                  )
                ) )
            {
                $def->{filename} = $f->basename;
            }
            if( $f && 
                !$def->{type} &&
                ( !$def->{headers} || 
                  ( ref( $def->{headers} ) ne 'ARRAY' && 
                    !$self->_is_a( $def->{headers} => 'HTTP::Promise::Headers' )
                  ) ||
                  (
                    $self->_is_a( $def->{headers} => 'HTTP::Promise::Headers' ) &&
                    !$def->{headers}->content_type
                  )
                ) )
            {
                $def->{type} = $f->finfo->mime_type;
            }
        }
        
        my $part = HTTP::Promise::Entity->new;
        my $disp = $headers->new_field( 'Content-Disposition' => 'form-data' );
        $disp->name( "$k" );
        my( $ph, $body );
        if( defined( $def ) && ref( $def ) eq 'HASH' )
        {
            if( exists( $def->{headers} ) && ref( $def->{headers} ) eq 'ARRAY' )
            {
                $ph = HTTP::Promise::Headers->new( @{$def->{headers}} ) ||
                    return( $self->pass_error( HTTP::Promise::Headers->error ) );
            }
            elsif( exists( $def->{headers} ) && $self->_is_a( $def->{headers} => 'HTTP::Promise::Headers' ) )
            {
                $ph = $def->{headers};
            }
            $disp->filename( $def->{filename} ) if( $def->{filename} );
            $ph->content_type( "$def->{type}" ) if( $def->{type} && !$ph->exists( 'Content-Type' ) );
            
            # If the user asks to encode the file and the file is not zero-byte big
            if( $def->{file} && $def->{encoding} && $def->{file}->length )
            {
                my $encodings = $self->_is_array( $def->{encoding} ) ? $def->{encoding} : [$def->{encoding}];
                $self->_load_class( 'HTTP::Promise::Stream' ) ||
                    return( $self->pass_error );
                my $source = $def->{file};
                foreach my $enc ( @$encodings )
                {
                    my $s = HTTP::Promise::Stream->new( $source, encoding => $def->{encoding} ) ||
                        return( $self->pass_error( HTTP::Promise::Stream->error ) );
                    my $file = $self->new_file;
                    my $bytes = $s->read( $file );
                    return( $self->pass_error( $s->error ) ) if( !defined( $bytes ) );
                    return( $self->error( "No encoded byte could be writen to file '$file' for encoding '$enc' with source file '$source'." ) ) if( !$bytes );
                    $source = $file;
                }
                $ph->content_transfer_encoding( join( ' ', @$encodings ) ) if( scalar( @$encodings ) );
                $part->is_encoded(1);
            }
            
            if( $def->{file} )
            {
                $body = $part->new_body( file => $def->{file} );
            }
            elsif( $def->{value} )
            {
                $body = $part->new_body( string => $def->{value} );
            }
        }
        else
        {
            $ph = HTTP::Promise::Headers->new ||
                return( $self->pass_error( HTTP::Promise::Headers->error ) );
            $body = $part->new_body( string => $v );
        }
        
        $ph->content_disposition( "${disp}" );
        $part->headers( $ph ) if( defined( $ph ) );
        $part->body( $body ) if( defined( $body ) );
        $ent->parts->push( $part );
    }
    return( $self );
}

sub method { return( shift->_set_get_scalar_as_object( 'method', @_ ) ); }

sub parse
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    warnings::warnif( 'Undefined argument to ' . ( ref( $self ) || $self ) . '->parse()' ) if( !defined( $str ) );
    $self->clear_error;
    if( !defined( $str ) || !length( $str ) )
    {
        return( ref( $self ) ? $self : $self->new );
    }
    my $opts = $self->_get_args_as_hash( @_ );
    my $p = HTTP::Promise::Parser->new( debug => ( delete( $opts->{debug} ) || $self->debug ) );
    $opts->{request} = 1;
    my $ent = $p->parse( $str, ( %$opts ? ( $opts ) : () ) ) || return( $self->pass_error( $p->error ) );
    return( $ent->http_message );
}

# See rfc7230, section 3.1 <https://tools.ietf.org/html/rfc7230#section-3.1>
sub start_line
{
    my $self = shift( @_ );
    my $eol  = shift( @_ );
    $eol = "\n" if( !defined( $eol ) );
    my $req_line = $self->method || $DEFAULT_METHOD || 'GET';
    my $uri = $self->uri;
    if( defined( $uri ) )
    {
        if( $self->uri_absolute )
        {
            $uri = "$uri";
        }
        else
        {
            $uri = $uri->path_query;
        }
        $uri = '/' if( !length( $uri ) );
    }
    else
    {
        # $uri = '-';
        $uri = '/';
    }
    $req_line .= " $uri";
    my $proto = $self->protocol;
    # $req_line .= " $proto" if( defined( $proto ) && length( $proto ) );
    if( defined( $proto ) && length( $proto ) )
    {
        $req_line .= " $proto";
    }
    else
    {
        $req_line .= ' ' . ( $self->default_protocol || 'HTTP/1.1' );
    }
    return( $req_line );
}

# NOTE: method protocol is inherited from HTTP::Promise::Message
sub timeout { return( shift->_set_get_number( 'timeout', @_ ) ); }

sub uri { return( shift->_set_get_uri( { field => 'uri', class => 'URI' }, @_ ) ); }

sub uri_absolute { return( shift->_set_get_boolean( 'uri_absolute', @_ ) ); }

sub uri_canonical { return( shift->uri->canonical ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Request - Asynchronous HTTP Request and Promise

=head1 SYNOPSIS

    use HTTP::Promise::Request;
    my $this = HTTP::Promise::Request->new || die( HTTP::Promise::Request->error, "\n" );

=head1 VERSION

    v0.1.0_2

=head1 DESCRIPTION

L<HTTP::Promise::Request> implements a similar interface to L<HTTP::Request>, but does not inherit from it. It uses a different API internally and relies on XS modules for speed while offering more features.

L<HTTP::Promise::Request> inherits from L<HTTP::Promise::Message>

One major difference with C<HTTP::Request> is that the HTTP request content is not necessarily stored in memory, but it relies on L<HTTP::Promise::Body> as you can see below, and this class has 2 subclasses: 1 storing data in memory when the size is reasonable (threshold set by you) and 1 storing data in a file on the filesystem for larger content.

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

    my $r = HTTP::Promise::Request->new( $method, $uri, $headers, $content, k1 => v1, k2 => v2);
    my $r = HTTP::Promise::Request->new( $method, $uri, $headers, $content, { k1 => v1, k2 => v2 });
    my $r = HTTP::Promise::Request->new( $method, $uri, $headers, k1 => v1, k2 => v2);
    my $r = HTTP::Promise::Request->new( $method, $uri, $headers, { k1 => v1, k2 => v2 });
    my $r = HTTP::Promise::Request->new( $method, $uri, k1 => v1, k2 => v2);
    my $r = HTTP::Promise::Request->new( $method, k1 => v1, k2 => v2);
    my $r = HTTP::Promise::Request->new( k1 => v1, k2 => v2 );
    die( HTTP::Promise::Request->error ) if( !defined( $r ) );

Provided with an HTTP method, URI, an optional set of headers, as either an array reference or a L<HTTP::Promise::Headers> or a L<HTTP::Headers> object, some optional content and an optional hash reference of options (as the last or only parameter), and this instantiates a new L<HTTP::Promise::Request> object. The supported arguments are as follow. Each arguments can be set or changed later using the method with the same name.

It returns the newly created object upon success, and upon error, such as bad argument provided, this sets an L<error|Module::Generic/error> and returns C<undef>

It takes the following arguments:

=over 4

=item 1. C<$method>

This is a proper HTTP method in upper case. Note that you can also provide non-standard method in any case you want.

=item 2. C<$uri>

The request uri such as C</> or an absolute uri, typical for making request to proxy, such as C<https://example.org/some/where>

=item 3. C<$headers>

An L<HTTP::Promise::Headers> object or an array reference of header field-value pairs, such as:

    my $r = HTTP::Promise::Request->new( $method, $uri, [
        'Content-Type' => 'text/html; charset=utf-8',
        Content_Encoding => 'gzip',
    ]);

=item 4. C<$content>

C<$content> can either be a string, a scalar reference, or an L<HTTP::Promise::Body> object (L<HTTP::Promise::Body::File> and L<HTTP::Promise::Body::Scalar>)

=back

Each supported option below can also be set using its corresponding method.

Supported options are:

=over 4

=item * C<content>

Same as C<$content> above.

=item * C<headers>

Same as C<$headers> above.

=item * C<method>

Same as C<$method> above.

=item * C<protocol>

The HTTP protocol, such as C<HTTP/1.1> or C<HTTP/2>

=item * C<uri>

The request uri, such as C</chat> or it could also be a fully qualified uri such as C<wss://example.com/chat>

=item * C<version>

The HTTP protocol version. Defaults to C<1.17>

=back

=head1 METHODS

=head2 accept_decodable

This sets and returns the header C<Accept-Encoding> after having set it the value of L</decodable>

=head2 add_content

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/add_content>

=head2 add_content_utf8

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/add_content_utf8>

=head2 add_part

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/add_part>

=head2 as_string

Depending on whether L<uri_absolute> is true, this returns a HTTP request with an URI including the HTTP host (a.k.a C<absolute-form>) or only the absolute path (a.k.a C<origin-form>). The former is used when issuing requests to proxies.

C<origin-form>:

    GET /where?q=now HTTP/1.1
    Host: www.example.org

C<absolute-form>:

    GET http://www.example.org/pub/WWW/TheProject.html HTTP/1.1

See L<rfc7230, section 5.3|https://tools.ietf.org/html/rfc7230#section-5.3>

=head2 boundary

This is inherited from L<HTTP::Promise::Message> and returns the multipart boundary currently set in the C<Content-Type> header.

=head2 can

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/can>

=head2 clear

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/clear>

=head2 clone

This clones the current object and returns the clone version.

=head2 content

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/content>

Use this method with care, because it will stringify the request body, thus loading it into memory, which could potentially be important if the body size is large. Maybe you can check the body size first? Something like:

    my $content;
    $content = $r->content if( $r->body->length < 102400 );

=head2 content_charset

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/content_charset>

=head2 content_ref

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/content_ref>

=head2 cookie_jar

Sets or gets the L<Cookie::Jar> object. This is used to read and store cookies.

=head2 decodable

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/decodable>

=head2 decode

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/decode>

=head2 decode_content

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/decode_content>

=head2 decoded_content

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/decoded_content>

=head2 decoded_content_utf8

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/decoded_content_utf8>

=head2 default_protocol

Sets or gets the default HTTP protocol to use. This defaults to C<HTTP/1.1>

=head2 dump

This dumps the HTTP request and prints it on the C<STDOUT> in void context, or returns a string of it.

=head2 encode

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/encode>

=head2 entity

Sets or gets an L<HTTP::Promise::Entity> object.

This object is automatically created upon instantiation of the HTTP request, and if you also provide some content when creating a new object, an L<HTTP::Promise::Body> object will also be created.

=head2 header

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/header>

=head2 headers

Sets or gets a L<HTTP::Promise::Headers> object.

A header object is always created upon instantiation, whether you provided headers fields or not.

=head2 headers_as_string

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/headers_as_string>

=head2 is_encoding_supported

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/is_encoding_supported>

=head2 make_boundary

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/make_boundary>

=head2 make_form_data

This takes either an L<HTTP::Promise::Body::Form> object, an L<HTTP::Promise::Body::Form::Data> object, an array reference or an hash reference of form name-value pairs and builds a C<multipart/form-data>

If a C<boundary> is already set in the C<Content-Type> header field, it will be used, otherwise a new one will be generated.

Each name provided will be the C<form-data> name for each part.

It returns the current entity object, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

Each value provided can be either one of the following:

=over 4

=item 1. string

=item 2. a L<Module::Generic::File> object

In this case, the file-mime type will try to be guessed. If you prefer to be specific about the file mime-type, use the alternate C<hash reference> below.

=item 3. an hash reference

For more granular control, you can provide an hash reference with the following supported properties:

=over 8

=item * C<encoding>

The encoding to be applied to the content. This will also set the C<Content-Encoding> for this C<form-data> part.

Note that when provided, the encodings will be applied immediately on the C<form-data> content, whether it is a string or a file.

=item * C<file>

A filepath to content for this part. The file content will not be loaded into memory, but instead will be used as-is. When it will need to be sent, it will be read from in chunks.

If this provided, the L<body object|HTTP::Promise::Body> will be a L<HTTP::Promise::Body::File>

=item * C<filename>

The C<filename> attribute of the C<Content-Disposition> or this C<form-data> part.

If this is not provided and C<headers> property is not provided, or C<headers> is specified, but the C<Content-Disposition> C<filename> attribute is not set, then the C<file> basename will be used instead.

=item * C<headers>

An L<HTTP::Promise::Headers> object or an array reference of header field-value pairs.

=item * C<type>

The mime-type to be used for this C<form-data> part.

If a C<file> is provided and this is not specified, it will try to guess the mime-type using L<HTTP::Promise::MIME>

Note that even if this provided, and if a C<headers> has been specified, it will not override an existing C<Content-Type> header that would have been set.

=item * C<value>

The C<form-data> value. This is an alternative to providing the C<form-data> content as a C<file>

Obviously you should not use both and if you do, C<file> will take priority.

If this provided, the L<body object|HTTP::Promise::Body> will be a L<HTTP::Promise::Body::Scalar>

=back

=back

C<multipart/form-data> is the only valid Content-Type for sending multiple data. L<rfc7578 in section 4.3|https://tools.ietf.org/html/rfc7578#section-4.3> states: "[RFC2388] suggested that multiple files for a single form field be transmitted using a nested "multipart/mixed" part. This usage is deprecated."

See also this L<Stackoverflow discussion|https://stackoverflow.com/questions/36674161/http-multipart-form-data-multiple-files-in-one-input/41204533#41204533> and L<this one too|https://stackoverflow.com/questions/51575746/http-header-content-type-multipart-mixed-causes-400-bad-request>

See also L<HTTP::Promise::Body::Form::Data> for an alternate easy way to create and manipulate C<form-data>, and see also L<HTTP::Promise::Entity/as_form_data>, which will create and return a L<HTTP::Promise::Body::Form::Data> object.

=head2 method

Sets or gets the HTTP C<method>, such as C<CONNECT>, C<DELETE>, C<GET>, C<HEAD>, C<OPTIONS>, C<PATCH>, C<POST>, C<PUT>, C<TRACE> which are the standard ones as defined by L<rfc7231, section 4.1|https://tools.ietf.org/html/rfc7231#section-4.1>

Note that casing must be uppercase for standard methods, but non-standard ones can be whatever you want as long as it complies with the rfc7231.

This returns the current method set, if any, as an L<scalar object|Module::Generic::Scalar>

=head2 parse

Provided with a scalar reference of data, a glob or a file path, and an hash or hash reference of options and this will parse the data provided using L<HTTP::Promise::Parser/parse>, passing it whatever options has been provided. See L<HTTP::Promise::Parser/parse_fh> for the supported options.

This returns the resulting L<HTTP::Promise::Message> object from the parsing, or, upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

Note that the resulting L<HTTP::Promise::Message> object can be a L<HTTP::Promise::Request> or L<HTTP::Promise::Response> object (both of which inherits from L<HTTP::Promise::Message>) if a start-line was found, or else just an L<HTTP::Promise::Message> object.

=head2 parts

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/parts>

=head2 protocol

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/protocol>

=head2 start_line

Read-only.

Returns a regular string representing the start-line containing the L<method|/method>, the L<uri|/uri> and the L<protocol|/protocol> of the request.

For example:

    GET / HTTP/1.1

See L<rfc7230, section 3.1|https://tools.ietf.org/html/rfc7230#section-3.1>

=head2 timeout

Sets or gets the C<timeout> as an integer. This returns the value as an L<number object|Module::Generic::Number>

=head2 uri

Sets or gets the C<uri>. Returns the current value, if any, as an L<URI> object.

=head2 uri_absolute

Boolean. Sets or gets whether L</as_string> will return a request including an uri in C<absolute-form> (with the host included) or in C<origin-form> (only with the absolute path).

If true, it sets the former otherwise the latter. Default to false.

=head2 uri_canonical

Returns the current L</uri> in its canonical form by calling L<URI/canonical>

=head2 version

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/version>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<rfc7230|https://tools.ietf.org/html/rfc7230>, and L<rfc7231|https://tools.ietf.org/html/rfc7231>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
