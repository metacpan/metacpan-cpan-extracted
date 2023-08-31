##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Response.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/21
## Modified 2022/03/21
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Response;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTTP::Promise::Message );
    use vars qw( $DEFAULT_PROTOCOL $VERSION );
    use HTTP::Promise::Status;
    our $DEFAULT_PROTOCOL = 'HTTP/1.0';
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my( $code, $status );
    if( @_ )
    {
        if( @_ == 1 && ref( $_[0] ) eq 'HASH' )
        {
            my $opts = $_[0];
            ( $code, $status ) = CORE::delete( @$opts{qw( code status )} );
        }
        elsif( @_ >= 2 && 
               defined( $_[0] ) && 
               $_[0] =~ /^\d{3}$/ &&
               ( ( defined( $_[1] ) && $_[1] =~ /\S/ ) || !defined( $_[1] ) ) )
        {
            ( $code, $status ) = splice( @_, 0, 2 );
        }
        else
        {
            return( $self->error( "Invalid parameters received. I was expecting either an hash reference or at least a code and status, but instead got: ", join( ", ", map( defined( $_ ) ? "'$_'" : 'undef', @_ ) ) ) );
        }
    }
    # properties headers and content are set by our parent class HTTP::Promise::Message
    $self->{code}       = $code;
    $self->{cookies}    = [];
    $self->{default_protocol} = $DEFAULT_PROTOCOL;
    $self->{previous}   = undef;
    $self->{request}    = undef;
    $self->{status}     = $status;
    $self->{version}    = '';
    $self->{_init_strict_use_sub} = 1;
    $self->{_init_params_order}   = [qw( content headers )];
    # $self->SUPER::init( ( defined( $headers ) ? $headers : () ), @_ ) || return( $self->pass_error );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub base
{
    my $self = shift( @_ );
    my $base = (
	$self->header( 'Content-Base' ),        # used to be HTTP/1.1
	$self->header( 'Content-Location' ),    # HTTP/1.1
	$self->header( 'Base' ),                # HTTP/1.0
    )[0];
    $self->_load_class( 'URI', { version => 5.10 } ) || return( $self->pass_error );
    if( $base && $base =~ /^[a-zA-Z][a-zA-Z0-9.+\-]*:/ )
    {
        # already absolute
        return( URI->new( $base ) );
    }

    my $req = $self->request;
    if( $req )
    {
        # if $base is undef here, the return value is effectively
        # just a copy of $self->request->uri.
        return( URI->new_abs( $base, $req->uri ) );
    }
    # Cannot find an absolute base
    return;
}

sub clone
{
    my $self = shift( @_ );
    my $new = $self->SUPER::clone;
    my $code = $self->code;
    my $status = $self->status;
    my $prev = $self->previous;
    my $req = $self->request;
    $new->code( $code );
    $new->status( $status );
    $new->previous( undef );
    # $new->previous( $prev ) if( defined( $prev ) );
    $new->request( $req->clone ) if( defined( $req ) );
    return( $new );
}

sub code { return( shift->_set_get_number( 'code', @_ ) ); }

sub current_age
{
    my $self = shift( @_ );
    my $time = shift( @_ );

    my $h_client_date = $self->client_date;
    my $h_date = $self->date;
    # Implementation of RFC 2616 section 13.2.3
    # (age calculations)
    my $response_time = $h_client_date->epoch if( $h_client_date );
    my $date = $h_date->epoch if( $h_date );

    my $age = 0;
    if( $response_time && $date )
    {
        # apparent_age
        $age = $response_time - $date;
        $age = 0 if( $age < 0 );
    }

    my $age_v = $self->header( 'Age' );
    if( $age_v && $age_v > $age )
    {
        # corrected_received_age
        $age = $age_v;
    }

    if( $response_time )
    {
        my $request = $self->request;
        if( $request )
        {
            my $req_date = $request->date;
            my $request_time = $req_date->epoch if( $req_date );
            if( $request_time && $request_time < $response_time )
            {
                # Add response_delay to age to get 'corrected_initial_age'
                $age += $response_time - $request_time;
            }
        }
        $age += ( $time || time ) - $response_time;
    }
    return( $age );
}

sub default_protocol { return( shift->_set_get_scalar_as_object( 'default_protocol', @_ ) ); }

sub dump
{
    my $self = shift( @_ );
    my $status_line = $self->status_line;
    my $proto = $self->protocol;
    $status_line = "$proto $status_line" if( $proto );
    return( $self->SUPER::dump( preheader => $status_line, @_ ) );
}

sub filename
{
    my $self = shift( @_ );
    my $file;
    my $dispo = $self->header( 'Content-Disposition' );
    # e.g.: attachment; filename="filename.jpg"
    #       form-data; name="fieldName"; filename="filename.jpg"
    # Ref: <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition>
    if( $dispo )
    {
        my $cd = $self->headers->new_field( 'Content-Disposition' => "$dispo" );
        return( $self->pass_error( $self->headers->error ) ) if( !defined( $cd ) );
        $file = $cd->filename;
    }

    unless( defined( $file ) && length( $file ) )
    {
        $self->_load_class( 'URI', { version => 5.10 } ) || return( $self->pass_error );
        my $uri;
        if( my $cl = $self->header( 'Content-Location' ) )
        {
            $uri = URI->new( $cl );
        }
        elsif( my $request = $self->request )
        {
            $uri = $request->uri;
        }

        if( $uri )
        {
            my $f = $self->new_file( $uri->path );
            $file = $f->basename;
        }
    }

    if( $file )
    {
        # basename
        $file =~ s,.*[\\/],,;
    }

    if( $file && !length( $file ) )
    {
        $file = undef;
    }

    return( $file );
}

sub fresh_until
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{time} ||= time;
    my $f = $self->freshness_lifetime( %$opts );
    return unless( defined( $f ) );
    return( $f - $self->current_age( $opts->{time} ) + $opts->{time} );
}

sub freshness_lifetime
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );

    # First look for the Cache-Control: max-age=n header
    for my $cc ( $self->header( 'Cache-Control' ) )
    {
        next if( !defined( $cc ) || !length( "$cc" ) );
        for my $cc_dir ( split( /[[:blank:]\h]*,[[:blank:]\h]*/, $cc ) )
        {
            return( $1 ) if( $cc_dir =~ /^max-age[[:blank:]\h]*=[[:blank:]\h]*(\d+)/i );
        }
    }

    my $h_date = $self->date;
    my $h_client_date = $self->client_date;
    # Next possibility is to look at the "Expires" header
    my $date = ( $h_date ? $h_date->epoch : '' ) || 
               ( $h_client_date ? $h_client_date->epoch : '' ) || 
               $opts->{time} || time;
    if( my $expires = $self->expires )
    {
        return( $expires->epoch - $date );
    }

    # Must apply heuristic expiration
    return if( exists( $opts->{heuristic_expiry} ) && !$opts->{heuristic_expiry} );

    # Default heuristic expiration parameters
    $opts->{h_min} ||= 60;
    $opts->{h_max} ||= 24 * 3600;
    # 10% since last-mod suggested by RFC2616
    $opts->{h_lastmod_fraction} ||= 0.10;
    $opts->{h_default} ||= 3600;

    # Should give a warning if more than 24 hours according to
    # RFC 2616 section 13.2.4. Here we just make this the default
    # maximum value.
    if( my $last_modified = $self->last_modified )
    {
        my $h_exp = ( $date - $last_modified ) * $opts->{h_lastmod_fraction};
        return( $opts->{h_min} ) if( $h_exp < $opts->{h_min} );
        return( $opts->{h_max} ) if( $h_exp > $opts->{h_max} );
        return( $h_exp );
    }

    # default when all else fails
    return( $opts->{h_min} ) if( $opts->{h_min} > $opts->{h_default} );
    return( $opts->{h_default} );
}

sub is_client_error { return( HTTP::Promise::Status->is_client_error( shift->code ) ); }

sub is_error        { return( HTTP::Promise::Status->is_error( shift->code ) ); }

sub is_fresh
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{time} ||= time;
    my $f = $self->freshness_lifetime( %$opts );
    return unless( defined( $f ) );
    return( $f > $self->current_age( $opts->{time} ) );
}

sub is_info         { return( HTTP::Promise::Status->is_info( shift->code ) ); }

sub is_redirect     { return( HTTP::Promise::Status->is_redirect( shift->code ) ); }

sub is_server_error { return( HTTP::Promise::Status->is_server_error( shift->code ) ); }

sub is_success      { return( HTTP::Promise::Status->is_success( shift->code ) ); }

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
    $str = $self->new_scalar( $str );
    $self->_load_class( 'HTTP::Promise::Parser' ) || return( $self->pass_error );
    my $p = HTTP::Promise::Parser->new;
    my $ent = $p->parse( $str ) || return( $self->pass_error( $p->error ) );
    return( $ent->http_message );
}

sub previous { return( shift->_set_get_object_without_init( 'previous', 'HTTP::Promise::Message', @_ ) ); }

sub redirects
{
    my $self = shift( @_ );
    my $reds = $self->new_array;
    my $r = $self;
    while( my $p = $r->previous )
    {
        $reds->unshift( $p );
        $r = $p;
    }
    return( $reds );
}

sub request { return( shift->_set_get_object_without_init( 'request', 'HTTP::Promise::Request', @_ ) ); }

# See rfc7230, section 3.1 <https://tools.ietf.org/html/rfc7230#section-3.1>
sub start_line
{
    my $self = shift( @_ );
    my $eol  = shift( @_ );
    $eol = "\n" if( !defined( $eol ) );
    my $status_line = $self->status_line;
    my $proto = $self->protocol || 'HTTP/1.1';
    my $resp_line = "$proto $status_line";
    return( $resp_line );
}

sub status { return( shift->_set_get_scalar_as_object( 'status', @_ ) ); }

sub status_line
{
    my $self = shift( @_ );
    my $code = $self->code || "000";
    my $status = $self->status || HTTP::Promise::Status->status_message( $code ) || 'Unknown code';
    return( "$code $status" );
}

# NOTE: sub FREEZE is inherited

# NOTE: sub STORABLE_freeze is inherited

# NOTE: sub STORABLE_thaw is inherited

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Response - HTTP Response Class

=head1 SYNOPSIS

    use HTTP::Promise::Response;
    my $resp = HTTP::Promise::Response->new || 
        die( HTTP::Promise::Response->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<HTTP::Promise::Response> implements a similar interface to L<HTTP::Response>, but does not inherit from it. It uses a different API internally and relies on XS modules for speed while offering more features.

L<HTTP::Promise::Response> inherits from L<HTTP::Promise::Message>

One major difference with C<HTTP::Response> is that the HTTP response content is not necessarily stored in memory, but it relies on L<HTTP::Promise::Body> as you can see below, and this class has 2 subclasses: 1 storing data in memory when the size is reasonable (threshold set by you) and 1 storing data in a file on the filesystem for larger content.

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

    my $resp = HTTP::Promise::Response->new( $code, $status, $headers, $content,
        host        => 'example.com',
        uri         => 'https://example.com/somewhere',
    );
    my $resp = HTTP::Promise::Response->new( $code, $status, $headers, $content, {
        host        => 'example.com',
        uri         => 'https://example.com/somewhere',
    });
    my $resp = HTTP::Promise::Response->new( $code, $status, $headers,
        host        => 'example.com',
        uri         => 'https://example.com/somewhere',
    );
    my $resp = HTTP::Promise::Response->new( $code, $status, $headers, {
        host        => 'example.com',
        uri         => 'https://example.com/somewhere',
    });

Provided with an HTTP code, HTTP status, an optional set of headers, as either an array reference or a L<HTTP::Promise::Headers> or a L<HTTP::Headers> object, some optional content and an optional hash reference of options (as the last or only parameter), and this instantiates a new L<HTTP::Promise::Response> object. The supported arguments are as follow. Each arguments can be set or changed later using the method with the same name.

It returns the newly created object upon success, and upon error, such as bad argument provided, this sets an L<error|Module::Generic/error> and returns C<undef>

=over 4

=item 1. C<$code>

An integer representing the status code, such as C<101> (switching protocol).

=item 2. C<$status>

The status string, such as C<Switching Protocol>.

=item 3. C<$headers>

Either an array reference of header-value pairs, or an L<HTTP::Promise::Headers> object or an L<HTTP::Headers> object.

If an array reference is provided, an L<HTTP::Promise::Headers> object will be instantiated with it.

For example::

    my $r = HTTP::Promise::Response->new( $code, $status, [
        'Content-Type' => 'text/html; charset=utf-8',
        Content_Encoding => 'gzip',
    ]);

=item 4. C<$content>

C<$content> can either be a string, a scalar reference, or an L<HTTP::Promise::Body> object (L<HTTP::Promise::Body::File> and L<HTTP::Promise::Body::Scalar>)

=back

Each supported option below can also be set using its corresponding method.

Supported options are:

=over 4

=item * C<code>

Same as C<$code> above.

=item * C<content>

Same as C<$content> above.

=item * C<headers>

Same as C<$headers> above.

=item * C<protocol>

The HTTP protocol, such as C<HTTP/1.1> or C<HTTP/2>

=item * C<status>

Same as C<$status> above.

=item * C<version>

The HTTP protocol version. Defaults to C<1.17>

=back

=head1 METHODS

=head2 add_content

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/add_content>

=head2 add_content_utf8

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/add_content_utf8>

=head2 add_part

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/add_part>

=head2 as_string

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/as_string>

=head2 base

Returns the base URI as an L<URI> object if it can find one, or C<undef> otherwise.

=head2 boundary

This is inherited from L<HTTP::Promise::Message> and returns the multipart boundary currently set in the C<Content-Type> header.

=head2 can

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/can>

=head2 clear

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/clear>

=head2 clone

This clones the current object and returns the clone version.

=head2 code

Sets or gets the HTTP response C<code>. This returns a L<number object|Module::Generic::Number>

=head2 content

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/content>

Use this method with care, because it will stringify the request body, thus loading it into memory, which could potentially be important if the body size is large. Maybe you can check the body size first? Something like:

    my $content;
    $content = $r->content if( $r->body->length < 102400 );

=head2 content_charset

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/content_charset>

=head2 content_ref

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/content_ref>

=head2 current_age

Calculates the "current age" of the response as specified by L<rfc2616, section 13.2.3|https://tools.ietf.org/html/rfc2616#section-13.2.3>.

The age of a response is the time since it was sent by the origin server.
The returned value is a number representing the age in seconds.

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

Sets or gets the default HTTP protocol to use. This defaults to C<HTTP/1.0>

=head2 dump

This dumps the HTTP response and prints it on the C<STDOUT> in void context, or returns a string of it.

=head2 encode

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/encode>

=head2 entity

Sets or gets an L<HTTP::Promise::Entity> object.

This object is automatically created upon instantiation of the HTTP request, and if you also provide some content when creating a new object, an L<HTTP::Promise::Body> object will also be created.

=head2 filename

Returns a possible filename, if any, for this response.

To achieve this, it tries different approaches:

=over 4

=item 1. C<Content-Disposition> header

It will check in the C<Content-Disposition> header of the response to see if there ia a C<filename> attribute, or a C<filename*> attribute (as defined in L<rfc2231|https://tools.ietf.org/html/rfc2231>)

For example:

    Content-Disposition: form-data; name="myfile"; filename*=UTF-8''%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt

or

    Content-Disposition: form-data; name="myfile"; filename*=UTF-8'ja-JP'%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt

In the above example, note the C<*> after the attribute name C<filename>. It is not a typo and part of the L<rfc2231 standard|https://tools.ietf.org/html/rfc2231>

or encoded with quoted-printable

    Content-Disposition: attachment; filename="=?UTF-8?Q?=E3=83=95=E3=82=A1=E3=82=A4=E3=83=AB.txt?="

or encoded with base64

    Content-Disposition: attachment; filename="=?UTF-8?B?44OV44Kh44Kk44OrLnR4dAo?="

Here the filename would be C<ファイル.txt> (i.e. "file.txt" in Japanese)

=item 2. C<Content-Location> header

It will use the base filename of the URI.

=item 3. C<request URI>

If there was an initial request URI, it will use the URI base filename.

This might not be the original request URI, because there might have been some redirect responses first.

=back

Whatever filename found is returned as-is. You need to be careful there are no dangerous characters in it before relying on it as part of a filepath.

If nothing is found, C<undef> is returned.

=head2 fresh_until

Returns the time (in seconds since epoch) when this entity is no longer fresh.

Options might be passed to control expiry heuristics. See the description of L</freshness_lifetime>.

=head2 freshness_lifetime

Calculates the "freshness lifetime" of the response as specified by L<rfc2616, section 13.2.4|https://tools.ietf.org/html/rfc2616#section-13.2.4> and updated by L<rfc7234, section 4.2|https://tools.ietf.org/html/rfc7234#section-4.2>.

The "freshness lifetime" is the length of time between the generation of a response and its expiration time.
The returned value is the number of seconds until expiry.

If the response does not contain an C<Expires> or a C<Cache-Control> header, then this function will apply some simple heuristic based on the C<Last-Modified> header to determine a suitable lifetime. The following options might be passed to control the heuristics:

=over 4

=item * C<heuristic_expiry>

Boolean. If set to a false value, do not apply heuristics and just return C<undef> when C<Expires> or C<Cache-Control> field is lacking.

=item * C<h_lastmod_fraction>

Integer. This number represent the fraction of the difference since the C<Last-Modified> timestamp to make the expiry time.

The default is C<0.10>, the suggested typical setting of 10% in L<rfc2616|https://tools.ietf.org/html/rfc2616>.

=item * C<h_min>

Integer representing seconds. This is the lower limit of the heuristic expiry age to use.
The default is C<60> (1 minute).

=item * C<h_max>

Integer representing seconds. This is the upper limit of the heuristic expiry age to use.
The default is C<86400> (24 hours).

=item * C<h_default>

Integer representing seconds. This is the expiry age to use when nothing else applies.

The default is C<3600> (1 hour) or C<h_min> if greater.

=back

=head2 header

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/header>

=head2 headers

Sets or gets a L<HTTP::Promise::Headers> object.

A header object is always created upon instantiation, whether you provided headers fields or not.

=head2 headers_as_string

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/headers_as_string>

=head2 is_client_error

Returns true if the L</code> corresponds to a client error, which typically is a code from C<400> to C<499>, or false otherwise.

See also L<HTTP::Promise::Status/is_client_error>

=head2 is_encoding_supported

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/is_encoding_supported>

=head2 is_error

Returns true if the L</code> corresponds to an error (client error or server error), which typically is a code from C<400> to C<599>, or false otherwise.

See also L<HTTP::Promise::Status/is_error>

=head2 is_fresh

Returns true if the response is fresh, based on the values of L</freshness_lifetime> and L</current_age>.
If the response is no longer fresh, then it has to be re-fetched or re-validated by the origin server.

Options might be passed to control expiry heuristics, see the description of L</freshness_lifetime>.

=head2 is_info

Returns true if the L</code> corresponds to an informational code, which typically is a code from C<100> to C<199>, or false otherwise.

See also L<HTTP::Promise::Status/is_info>

=head2 is_redirect

Returns true if the L</code> corresponds to a redirection, which typically is a code from C<300> to C<399>, or false otherwise.

See also L<HTTP::Promise::Status/is_redirect>

=head2 is_server_error

Returns true if the L</code> corresponds to a server error, which typically is a code from C<500> to C<599>, or false otherwise.

See also L<HTTP::Promise::Status/is_server_error>

=head2 is_success

Returns true if the L</code> corresponds to a successful response, which typically is a code from C<200> to C<299>, or false otherwise.

See also L<HTTP::Promise::Status/is_success>

=head2 make_boundary

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/make_boundary>

=head2 parse

Provided with a scalar reference of data, a glob or a file path, and an hash or hash reference of options and this will parse the data provided using L<HTTP::Promise::Parser/parse>, passing it whatever options has been provided. See L<HTTP::Promise::Parser/parse_fh> for the supported options.

This returns the resulting L<HTTP::Promise::Message> object from the parsing, or, upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

Note that the resulting L<HTTP::Promise::Message> object can be a L<HTTP::Promise::Request> or L<HTTP::Promise::Response> object (both of which inherits from L<HTTP::Promise::Message>) if a start-line was found, or else just an L<HTTP::Promise::Message> object.

=head2 parts

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/parts>

=head2 previous

Sets or gets an L<HTTP::Promise::Message> object corresponding to the previous HTTP query. This is used to keep track of redirection.

=head2 protocol

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/protocol>

=head2 redirects

Returns an L<array object|Module::Generic::Array> of redirect responses that lead up to this response by following the C<$r->previous> chain. The list order is oldest first.

For example:

    my $reds = $r->redirects;
    say "Number of redirects: ", $reds->length;

=head2 request

Sets or gets the L<HTTP::Promise::Request> related to this response.

It is not necessarily the same request passed to the L<HTTP::Promise/request>, because there might have been redirects and authorisation retries in between.

=head2 start_line

Returns a string representing the start-line containing the L<protocol|/protocol>, the L<code|/code> and the L<status|/status> of the response.

For example:

    GET / HTTP/1.1

See L<rfc7230, section 3.1|https://tools.ietf.org/html/rfc7230#section-3.1>

=head2 status

Sets or gets the response status string, such as C<OK> for code C<200>. This returns a L<scalar object|Module::Generic::Scalar>

=head2 status_line

Returns a regular string made of the L</code> and the L</status>. If no status is set, this will guess it from L<HTTP::Promise::Status/status_message>

=head2 version

This is inherited from L<HTTP::Promise::Message>. See L<HTTP::Promise::Message/version>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
