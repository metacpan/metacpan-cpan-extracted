##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/21
## Modified 2023/09/08
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Headers;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTTP::XSHeaders );
    use vars qw( $VERSION $EXCEPTION_CLASS $MOD_PERL $SUPPORTED $MOD_PATH );
    use Config;
    use Cwd ();
    use Encode;
    use HTTP::Promise::Exception;
    use HTTP::XSHeaders 0.400004;
    use IO::File;
    # use Nice::Try;
    use Scalar::Util;
    use URI::Escape::XS ();
    use Want;
    if( exists( $ENV{MOD_PERL} )
        &&
        ( $MOD_PERL = $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ ) )
    {
        select( ( select( STDOUT ), $| = 1 )[ 0 ] );
        require Apache2::Log;
        # For _is_class_loaded method
        require Apache2::Module;
        require Apache2::ServerUtil;
        require Apache2::RequestUtil;
        require Apache2::ServerRec;
        require ModPerl::Util;
        require Apache2::Const;
        Apache2::Const->import( compile => qw( :log OK ) );
    }
    use constant CRLF => "\015\012";
    use constant HAS_THREADS  => ( $Config{useithreads} && $INC{'threads.pm'} );
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
    our $SUPPORTED = {};
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

my $stderr = IO::File->new;
$stderr->fdopen( fileno( STDERR ), 'w' );
$stderr->binmode( ':utf8' );
$stderr->autoflush( 1 );
my $stderr_raw = IO::File->new;
$stderr_raw->fdopen( fileno( STDERR ), 'w' );
$stderr_raw->binmode( ':raw' );
$stderr_raw->autoflush( 1 );

our $MOD_PATH = Cwd::abs_path( $INC{ ( __PACKAGE__ =~ s{::}{/}gr ) . '.pm' } );

# for mod in `ls -1 ./lib/HTTP/Promise/Headers`; do printf "%-32s => 'HTTP::Promise::Headers::%s',\n" $(echo $(basename $mod ".pm")|tr "[:upper:]" "[:lower:]") $(basename $mod ".pm"); done
# or
# perl -MModule::Generic::File=file -lE 'my $d=file("./lib/HTTP/Promise/Headers"); my $files=$d->content; $files->for(sub{ my$f=file($_); printf("%-32s => ''HTTP::Promise::Headers::%s'',\n", $f->basename(".pm")->lc, $f->basename(".pm")) })'
our $SUPPORTED =
{
    accept                           => 'HTTP::Promise::Headers::Accept',
    acceptencoding                   => 'HTTP::Promise::Headers::AcceptEncoding',
    acceptlanguage                   => 'HTTP::Promise::Headers::AcceptLanguage',
    altsvc                           => 'HTTP::Promise::Headers::AltSvc',
    cachecontrol                     => 'HTTP::Promise::Headers::CacheControl',
    clearsitedata                    => 'HTTP::Promise::Headers::ClearSiteData',
    contentdisposition               => 'HTTP::Promise::Headers::ContentDisposition',
    contentrange                     => 'HTTP::Promise::Headers::ContentRange',
    contentsecuritypolicy            => 'HTTP::Promise::Headers::ContentSecurityPolicy',
    contentsecuritypolicyreportonly  => 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly',
    contenttype                      => 'HTTP::Promise::Headers::ContentType',
    cookie                           => 'HTTP::Promise::Headers::Cookie',
    expectct                         => 'HTTP::Promise::Headers::ExpectCT',
    forwarded                        => 'HTTP::Promise::Headers::Forwarded',
    generic                          => 'HTTP::Promise::Headers::Generic',
    keepalive                        => 'HTTP::Promise::Headers::KeepAlive',
    link                             => 'HTTP::Promise::Headers::Link',
    range                            => 'HTTP::Promise::Headers::Range',
    servertiming                     => 'HTTP::Promise::Headers::ServerTiming',
    stricttransportsecurity          => 'HTTP::Promise::Headers::StrictTransportSecurity',
    te                               => 'HTTP::Promise::Headers::TE',
    wantdigest                       => 'HTTP::Promise::Headers::WantDigest',
};

sub new
{
    my $this = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $self;
    # try-catch
    local $@;
    eval
    {
        $self = $this->SUPER::new( @_ );
    };
    if( $@ )
    {
        return( $this->error( "Error instantiating an HTTP::Promise::Headers object: $@" ) );
    }
    $self->{default_type} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->debug( $opts->{debug} ) if( CORE::exists( $opts->{debug} ) );
    $self->{_ctype_cached} = '';
    return( $self );
}

# e.g. text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
sub accept
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $types = $self->_get_args_as_array( @_ );
        $self->header( accept => $types );
        CORE::delete( $self->{acceptables} );
    }
    return( $self->_set_get_one( 'Accept' ) );
}

# Obsolete header that should not be used
sub accept_charset { return( shift->_set_get_one( 'Accept-Charset', @_ ) ); }

# e.g. gzip, deflate, br
sub accept_encoding { return( shift->_set_get_multi( 'Accept-Encoding', @_ ) ); }

# e.g.: en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2
sub accept_language { return( shift->_set_get_multi( 'Accept-Language', @_ ) ); }

# NOTE: Accept-Patch is a response header
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Patch>
sub accept_patch { return( shift->_set_get_one( 'Accept-Patch', @_ ) ); }

# NOTE: Accept-Post is a response header
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Post>
sub accept_post { return( shift->_set_get_multi( 'Accept-Post', @_ ) ); }

# NOTE: Accept-Tanges is a response header
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Ranges>
sub accept_ranges { return( shift->_set_get_multi( 'Accept-Ranges', @_ ) ); }

sub acceptables
{
    my $self = shift( @_ );
    return( $self->{acceptables} ) if( $self->{acceptables} );
    my $accept_raw = $self->accept;
    if( $accept_raw )
    {
        my $f = $self->new_field( accept => $accept_raw ) ||
            return( $self->pass_error );
        $self->{acceptables} = $f;
    }
    return( $self->{acceptables} );
}

sub add { return( shift->push_header( @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Age>
sub age { return( shift->_set_get_one( 'Age', @_ ) ); }

# NOTE: Allow is a response header
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Allow>
sub allow { return( shift->_set_get_multi( 'Allow', @_ ) ); }

# Response header: <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials>
sub allow_credentials { return( shift->_set_get_one( 'Access-Control-Allow-Credentials', @_ ) ); }

# Response header <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Headers>
sub allow_headers { return( shift->_set_get_multi( 'Access-Control-Allow-Headers', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods>
sub allow_methods { return( shift->_set_get_one( 'Access-Control-Allow-Methods', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin>
sub allow_origin { return( shift->_set_get_one( 'Access-Control-Allow-Origin', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Alt-Svc>
sub alt_svc { return( shift->_set_get_multi( 'Alt-Svc', @_ ) ); }

sub alternate_server
{
    my $self = shift( @_ );
    if( @_ )
    {
        # { name => 'h2', value => 'alt.example.com:443', ma => 2592000, persist => 1
        my $def   = $self->_get_args_as_hash( @_ );
        my $name  = CORE::delete( $def->{name} );
        my $value = CORE::delete( $def->{value} );
        my $f = $self->new_field( alt_svc => [$name => $value], $def ) ||
            return( $self->pass_error );
        $self->push_header( 'Alt-Svc' => "$f" );
    }
    else
    {
        my $all = $self->alt_svc;
        return( $all ) if( !$all->length );
        my $a = $self->new_array;
        $all->foreach(sub
        {
            my $f = $self->new_field( alt_svc => $_ ) ||
                return( $self->pass_error );
            $a->push( $f );
        });
        return( $a );
    }
}

# NOTE: as_string() is inherited
# NOTE: unfortunately, HTTP::XSHeaders is not dealing with as_string properly
# It takes the given eol and replace simply any instance in-between line of \n with it,
# thus if you have something like: foo\r\nbar\r\n, it will end up with
# foo\r\r\nbar\r\n instead of foot\r\nbar\r\n
# Bug report #10 <https://github.com/p5pclub/http-xsheaders/issues/10>
# sub as_string { return( shift->SUPER::as_string( @_ ? @_ : ( CRLF ) ) ); }
sub as_string
{
    my $self = shift( @_ );
    my $type = $self->type;
    # If the type is multipart, ensure we have a boundary set.
    # This is a convenience for the user, who only needs to set the mime-type
    # without having to worry about generating a boundary.
    if( defined( $type ) && lc( [split( '/', $type, 2 )]->[0] ) eq 'multipart' )
    {
        my $boundary = $self->multipart_boundary;
        unless( $boundary )
        {
            $boundary = $self->make_boundary;
            my $ct = $self->new_field( 'Content-Type' => $type );
            $ct->boundary( $boundary );
            $self->content_type( "$ct" );
        }
    }
    my $str  = $self->SUPER::as_string( @_ ? @_ : ( CRLF ) );
    if( index( $str, "\r\r\n" ) != -1 )
    {
        $str =~ s/\r\r\n/\r\n/g;
    }
    return( $str );
}

# NOTE: authorization() is inherited
sub authorization { return( shift->_set_get_one( 'Authorization', @_ ) ); }

# NOTE: authorization_basic() is inherited
sub authorization_basic { return( shift->_basic_auth( 'Authorization', @_ ) ); }

sub boundary
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $boundary = shift( @_ );
        my $ct = $self->content_type;
        $self->{boundary} = $boundary;
        # If there is a content type set, add the charset to it; otherwise, just return
        # User should set the content type before setting the charset
        return( '' ) if( !length( $ct ) );
        my $f = $self->new_field( content_type => $ct ) ||
            return( $self->pass_error );
        $f->param( boundary => $boundary );
        $self->{type} = $f->type;
        $self->content_type( $f );
        $self->{_ctype_cached} = "$f";
    }
    unless( length( $self->{boundary} ) && $self->{_ctype_cached} eq $self->content_type )
    {
        my $ct = $self->content_type;
        my $f = $self->new_field( content_type => ( defined( $ct ) ? "$ct" : () ) );
        $self->{boundary} = $f->boundary;
        $self->{type} = $f->type;
        $self->{_ctype_cached} = $ct;
    }
    return( $self->{boundary} );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control>
sub cache_control { return( shift->_set_get_one( 'Cache-Control', @_ ) ); }

sub charset
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $charset = shift( @_ );
        my $ct = $self->content_type;
        $self->{charset} = $charset;
        # If there is a content type set, add the charset to it; otherwise, just return
        # User should set the content type before setting the charset
        return( '' ) if( !length( $ct ) );
        my $f = $self->new_field( content_type => $ct ) || return( $self->pass_error );
        $f->param( charset => $charset );
        $self->content_type( $f );
    }
    unless( length( $self->{charset} ) )
    {
        my $ct = $self->content_type;
        my $f = $self->new_field( content_type => $ct );
        $self->{charset} = $f->charset;
    }
    return( $self->{charset} );
}

# NOTE: clear() is inherited

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data>
sub clear_site_data { return( shift->_set_get_multi( 'Clear-Site-Data', @_ ) ); }

sub client_date { return( shift->_date_header( 'Client-Date', @_ ) ); }

# NOTE: clone() is inherited

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Connection>
sub connection { return( shift->_set_get_one( 'Connection', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition>
sub content_disposition { return( shift->_set_get_one( 'Content-Disposition', @_ ) ); }

# NOTE: content_encoding() is implemented in our parent class, but our implementation differs
sub content_encoding { return( shift->_set_get_one( 'Content-Encoding', @_ ) ); }

# NOTE: content_is_html() is already implemented by our parent class, but our implementation of content_type() differs
sub content_is_html
{
    my $self = shift( @_ );
    my $type = $self->type;
    return(0) if( !defined( $type ) || !length( "$type" ) );
    $type = lc( $type );
    return( $type eq 'text/html' || $self->content_is_xhtml );
}

sub content_is_json
{
    my $self = shift( @_ );
    my $type = $self->type;
    return(0) if( !defined( $type ) || !length( "$type" ) );
    $type = lc( $type );
    return( $type eq 'application/json' );
}

sub content_is_text
{
    my $self = shift( @_ );
    my $type = $self->content_type;
    return(0) if( !defined( $type ) || !length( "$type" ) );
    return( $$type =~ m,^text/,i );
}

# NOTE: content_is_xhtml() is already implemented by our parent class, but our implementation of content_type() differs
sub content_is_xhtml
{
    my $self = shift( @_ );
    my $type = $self->type;
    return(0) if( !defined( $type ) || !length( "$type" ) );
    $type = lc( $type );
    return( $type eq 'application/xhtml+xml' || $type eq 'application/vnd.wap.xhtml+xml' );
}

# NOTE: content_is_xml() is already implemented by our parent class, but our implementation of content_type() differs
sub content_is_xml
{
    my $self = shift( @_ );
    my $type = $self->type;
    return(0) if( !defined( $type ) || !length( "$type" ) );
    $type = lc( $type );
    return(1) if( $type eq 'text/xml' );
    return(1) if( $type eq 'application/xml' );
    return(1) if( $type =~ /\+xml$/ );
    return(0);
}

# NOTE: content_language() is implemented in our parent class, but our implementation differs
sub content_language { return( shift->_set_get_multi( 'Content-Language', @_ ) ); }

# NOTE: content_length() is implemented in our parent class, but our implementation differs
sub content_length { return( shift->_set_get_one_number( 'Content-Length', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Location>
sub content_location { return( shift->_set_get_one( 'Content-Location', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Range>
sub content_range { return( shift->_set_get_one( 'Content-Range', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy>
sub content_security_policy { return( shift->_set_get_one( 'Content-Security-Policy', @_ ) ); }

sub content_security_policy_report_only { return( shift->_set_get_one( 'Content-Security-Policy-Report-Only', @_ ) ); }

# NOTE: content_type() is already implemented by our parent class, but we our implementation is more straightforward in line with the idea of setting and getting exactly the header field value.
# Arguably, it is wrong to expect the return value of content_type to be only the mime_type, thus there is the type() method for that
sub content_type
{
    my $self = shift( @_ );
    my $v;
    if( @_ )
    {
        $v = shift( @_ );
        $self->header( content_type => $v );
        # Simple value, set the type() cache
        if( index( $v, ';' ) == -1 )
        {
            $self->{type} = $v;
        }
        # Force type() to find the mime-type
        else
        {
            $self->{type} = '';
        }
        
        return( $self->new_scalar( ref( $v ) ? "$v" : \$v ) );
    }
    else
    {
        $v = $self->header( 'Content-Type' );
    }
    
    if( defined( $v ) )
    {
        return( $self->new_scalar( ref( $v ) ? "$v" : \$v ) );
    }
    elsif( want( 'OBJECT' ) )
    {
        return( Module::Generic::Null->new );
    }
    else
    {
        return;
    }
}

# NOTE: content_type_charset() is inherited

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Embedder-Policy>
sub cross_origin_embedder_policy { return( shift->_set_get_one( 'Cross-Origin-Embedder-Policy', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Opener-Policy>
sub cross_origin_opener_policy { return( shift->_set_get_one( 'Cross-Origin-Opener-Policy', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Resource-Policy>
sub cross_origin_resource_policy { return( shift->_set_get_one( 'Cross-Origin-Resource-Policy', @_ ) ); }

sub cspro { return( shift->content_security_policy_report_only( @_ ) ); }

# NOTE: date() is already implemented by our parent class, but our implementation is more versatile and better
sub date { return( shift->_date_header( 'Date', @_ ) ); }

# rfc2231 <https://datatracker.ietf.org/doc/html/rfc2231>
sub decode_filename
{
    my $self = shift( @_ );
    my $fname = shift( @_ );
    return( $fname ) if( !defined( $fname ) || !length( $fname ) );
    my( $charset, $lang );
    if( $fname =~ /^(.*?)\'([^\']*)\'(.*?)$/ )
    {
        ( $charset, $lang, my $encoded_fname ) = ( $1, $2, $3 );
        unless( lc( $charset ) eq 'utf8' || lc( $charset ) eq 'utf-8' )
        {
            return( $self->error( "Character set '$charset' is not supported for file name '$encoded_fname'" ) );
        }
        # The language parameter, if any, is discarded
        $fname = Encode::decode_utf8( URI::Escape::XS::uri_unescape( $encoded_fname ) );
    }
    # rfc2047 encoded?
    elsif( $fname =~ /^=\?(.+?)\?(.+?)\?(.+)\?=$/ )
    {
        $charset = $1;
        my $encoding = uc( $2 );
        my $encfile = $3;

        if( $encoding eq 'Q' || $encoding eq 'B' )
        {
            eval
            {
                if( $encoding eq 'Q' )
                {
                    $encfile =~ s/_/ /g;
                    $self->_load_class( 'HTTP::Promise::Stream' ) || return( $self->pass_error );
                    my $s = HTTP::Promise::Stream->new( \$encfile, { decoding => 'quoted-printable' } ) ||
                        return( $self->pass_error( HTTP::Promise::Stream->error ) );
                    my $decoded = $s->decode;
                    return( $self->pass_error( $s->error ) ) if( !defined( $decoded ) );
                    $encfile = $decoded;
                }
                # $encoding eq 'B'
                else
                {
                    $self->_load_class( 'Crypt::Misc' ) || return( $self->pass_error );
                    $encfile = Crypt::Misc::decode_b64( $encfile );
                }
            };
            
            if( $@ )
            {
                # return( $self->error( "Error decoding content disposition file name: $e" ) );
                warnings::warnif( "Error decoding content disposition file name: $@" );
            }
            
            eval
            {
                $self->_load_class( 'Encode' ) || return( $self->pass_error );
                $self->_load_class( 'Encode::Locale' ) || return( $self->pass_error );
                Encode::from_to( $encfile, $charset, 'locale_fs' );
                $fname = $encfile;
            };
            
            if( $@ )
            {
                # return( $self->error( "Error encoding content disposition file name: $e" ) );
                warnings::warnif( "Error encoding content disposition file name from '$charset' to 'locale_fs': $@" );
            }
        }
    }
    return( wantarray() ? ( $fname, $charset, $lang ) : $fname );
}

sub debug
{
    my $self  = shift( @_ );
    my $class = ( ref( $self ) || $self );
    no strict 'refs';
    if( @_ )
    {
        my $flag = shift( @_ );
        $self->{debug} = $flag;
        if( $self->{debug} &&
            !$self->{debug_level} )
        {
            $self->{debug_level} = $self->{debug};
        }
    }
    return( $self->{debug} || ${"$class\:\:DEBUG"} );
}

sub default_type { return( shift->_set_get( 'default_type', @_ ) ); }

sub delete { return( shift->remove_header( @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Device-Memory>
sub device_memory { return( shift->_set_get_one( 'Device-Memory', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Digest>
sub digest { return( shift->_set_get_multi( 'Digest', @_ ) ); }

# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/DNT
sub dnt { return( shift->_set_get_one( dnt => @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Early-Data>
sub early_data { return( shift->_set_get_one( 'Early-Data', @_ ) ); }

# rfc2231 <https://datatracker.ietf.org/doc/html/rfc2231>
sub encode_filename
{
    my $self = shift( @_ );
    my $fname = shift( @_ );
    my $lang = shift( @_ );
    if( $fname =~ /[^\w\.]+/ )
    {
        $lang = '' if( !defined( $lang ) );
        return( sprintf( "UTF-8'${lang}'%s", $self->uri_escape_utf8( $fname ) ) );
    }
    # Nothing to be done. We return undef on purpose to indicate nothing was done
    return;
}

# Copied here from Module::Generic
sub error
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    no warnings;
    our $MOD_PERL;
    my $o;
    no strict 'refs';
    if( @_ )
    {
        my $args = {};
        # We got an object as first argument. It could be a child from our exception package or from another package
        # Either way, we use it as it is
        if( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) ) ||
            Scalar::Util::blessed( $_[0] ) )
        {
            $o = shift( @_ );
        }
        elsif( ref( $_[0] ) eq 'HASH' )
        {
            $args  = shift( @_ );
        }
        else
        {
            $args->{message} = join( '', map( ( ref( $_ ) eq 'CODE' && !$self->{_msg_no_exec_sub} ) ? $_->() : $_, @_ ) );
        }
        $args->{class} //= '';
        my $max_len = ( CORE::exists( $self->{error_max_length} ) && $self->{error_max_length} =~ /^[-+]?\d+$/ )
            ? $self->{error_max_length}
            : 0;
        $args->{message} = substr( $args->{message}, 0, $self->{error_max_length} ) if( $max_len > 0 && length( $args->{message} ) > $max_len );
        # Reset it
        $self->{_msg_no_exec_sub} = 0;
        # Note Taken from Carp to find the right point in the stack to start from
        my $caller_func;
        $caller_func = \&{"CORE::GLOBAL::caller"} if( defined( &{"CORE::GLOBAL::caller"} ) );
        if( defined( $o ) )
        {
            $self->{error} = ${ $class . '::ERROR' } = $o;
        }
        else
        {
            my $ex_class = CORE::length( $args->{class} )
                ? $args->{class}
                : ( CORE::exists( $self->{_exception_class} ) && CORE::length( $self->{_exception_class} ) )
                    ? $self->{_exception_class}
                    : 'Module::Generic::Exception';
            unless( $self->_is_class_loaded( $ex_class ) || scalar( keys( %{"${ex_class}\::"} ) ) )
            {
                my $pl = "use $ex_class;";
                local $SIG{__DIE__} = sub{};
                eval( $pl );
                # We have to die, because we have an error within another error
                die( __PACKAGE__ . "::error() is unable to load exception class \"$ex_class\": $@" ) if( $@ );
            }
            $o = $self->{error} = ${ $class . '::ERROR' } = $ex_class->new( $args );
        }
        
        my $r;
        if( $MOD_PERL )
        {
            # try-catch
            local $@;
            eval
            {
                $r = Apache2::RequestUtil->request;
                $r->warn( $o->as_string ) if( $r );
            };
            if( $@ )
            {
                print( STDERR "Error trying to get the global Apache2::ApacheRec: $@\n" );
            }
        }
        
        if( $r )
        {
            if( my $log_handler = $r->get_handlers( 'PerlPrivateErrorHandler' ) )
            {
                $log_handler->( $o );
            }
            else
            {
                $r->warn( $o->as_string ) if( warnings::enabled() );
            }
        }
        elsif( $self->{fatal} || ( defined( ${"${class}\::FATAL_ERROR"} ) && ${"${class}\::FATAL_ERROR"} ) )
        {
            # my $enc_str = eval{ Encode::encode( 'UTF-8', "$o", Encode::FB_CROAK ) };
            # die( $@ ? $o : $enc_str );
            die( $o );
        }
        elsif( warnings::enabled() )
        {
            if( $r )
            {
                $r->warn( $o->as_string );
            }
            else
            {
                my $enc_str = eval{ Encode::encode( 'UTF-8', "$o", Encode::FB_CROAK ) };
                # Display warnings if warnings for this class is registered and enabled or if not registered
                warn( $@ ? $o : $enc_str );
            }
        }
        
        # https://metacpan.org/pod/Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef
        # https://perlmonks.org/index.pl?node_id=741847
        # Because in list context this would create a lit with one element undef()
        # A bare return will return an empty list or an undef scalar
        # return( undef() );
        # return;
        # As of 2019-10-13, Module::Generic version 0.6, we use this special package Module::Generic::Null to be returned in chain without perl causing the error that a method was called on an undefined value
        # 2020-05-12: Added the no_return_null_object to instruct not to return a null object
        # This is especially needed when an error is called from TIEHASH that returns a special object.
        # A Null object would trigger a fatal perl segmentation fault
        if( !$args->{no_return_null_object} && want( 'OBJECT' ) )
        {
            require Module::Generic::Null;
            my $null = Module::Generic::Null->new( $o, { debug => $self->{debug}, has_error => 1 });
            rreturn( $null );
        }
        return;
    }
    # To avoid the perl error of 'called on undefined value' and so the user can do
    # $o->error->message for example without concerning himself/herself whether an exception object is actually set
    if( !$self->{error} && want( 'OBJECT' ) )
    {
        require Module::Generic::Null;
        my $null = Module::Generic::Null->new( $o, { debug => $self->{debug}, wants => 'object' });
        rreturn( $null );
    }
    return( ref( $self ) ? $self->{error} : ${ $class . '::ERROR' } );
}

sub etag { return( shift->_set_get_one( 'Etag', @_ ) ); }

sub exists
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return(0);
    my $rv = $self->header( $field );
    return( defined( $rv ) ? 1 : 0 );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expect>
sub expect { return( shift->_set_get_one( 'Expect', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expect-CT>
sub expect_ct { return( shift->_set_get_multi( 'Expect-CT', @_ ) ); }

# NOTE: expires() is inherited
sub expires { return( shift->_date_header( 'Expires', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers>
# e.g.: Access-Control-Expose-Headers: Content-Encoding, X-Kuma-Revision
sub expose_headers { return( shift->_set_get_multi( 'Access-Control-Expose-Headers', @_ ) ); }

# NOTE: flatten() is inherited

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Forwarded>
sub forwarded { return( shift->_set_get_one( 'Forwarded', @_ ) ); }

# NOTE: from() is inherited
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/From>
sub from { return( shift->_set_get_one( 'From', @_ ) ); }

sub get { return( shift->header( shift( @_ ) ) ); }

# NOTE: header() is inherited

# NOTE: header_field_names() is inherited

sub host { return( shift->_set_get_one( 'Host', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match>
sub if_match { return( shift->_set_get_one( 'If-Match', @_ ) ); }

# NOTE: if_modified_since() is inherited
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since>
sub if_modified_since { return( shift->_date_header( 'If-Modified-Since', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match>
sub if_none_match { return( shift->_set_get_one( 'If-None-Match', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Range>
sub if_range { return( shift->_set_get_one( 'If-Range', @_ ) ); }

# NOTE: if_unmodified_since() is inherited
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Unmodified-Since>
sub if_unmodified_since { return( shift->_date_header( 'If-Unmodified-Since', @_ ) ); }

# NOTE: init_header() is inherited

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Keep-Alive>
sub keep_alive { return( shift->_set_get_one( 'Keep-Alive', @_ ) ); }

# NOTE: last_modified() is inherited
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified>
sub last_modified { return( shift->_date_header( 'Last-Modified', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Link>
sub link { return( shift->_set_get_multi( 'Link', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location>
sub location { return( shift->_set_get_one( 'Location', @_ ) ); }

sub make_boundary
{
    my $self = shift( @_ );
    $self->_load_class( 'Data::UUID' ) || return( $self->pass_error );
    return( Data::UUID->new->create_str );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age>
sub max_age { return( shift->_set_get_number( 'Access-Control-Max-Age', @_ ) ); }

sub message
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    no strict 'refs';
    if( $self->{verbose} || $self->{debug} || ${ $class . '::DEBUG' } )
    {
        my $r;
        if( $MOD_PERL )
        {
            # try-catch
            local $@;
            eval
            {
                $r = Apache2::RequestUtil->request;
            };
            if( $@ )
            {
                $stderr_raw->print( "Error trying to get the global Apache2::ApacheRec: $@\n" );
            }
        }
    
        my $ref;
        $ref = $self->message_check( @_ );
        return(1) if( !$ref );
        
        my $opts = {};
        $opts = pop( @$ref ) if( ref( $ref->[-1] ) eq 'HASH' );

        my $stackFrame = $self->message_frame( (caller(1))[3] ) || 1;
        $stackFrame = 1 unless( $stackFrame =~ /^\d+$/ );
        $stackFrame-- if( $stackFrame );
        $stackFrame++ if( ( (caller(1))[3] // '' ) eq 'HTTP::Promise::Headers::messagef' );
        my( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
        my $sub = ( caller( $stackFrame + 1 ) )[3] // '';
        my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
        if( ref( $self->{_message_frame} ) eq 'HASH' )
        {
            if( exists( $self->{_message_frame}->{ $sub2 } ) )
            {
                my $frameNo = int( $self->{_message_frame}->{ $sub2 } );
                if( $frameNo > 0 )
                {
                    ( $pkg, $file, $line, $sub ) = caller( $frameNo );
                    $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
                }
            }
        }
        if( $sub2 eq 'message' )
        {
            $stackFrame++;
            ( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
            my $sub = ( caller( $stackFrame + 1 ) )[3] // '';
            $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
        }
        my $txt;
        if( $opts->{message} )
        {
            if( ref( $opts->{message} ) eq 'ARRAY' )
            {
                $txt = join( '', map( ( ref( $_ ) eq 'CODE' && !$self->{_msg_no_exec_sub} ) ? $_->() : ( $_ // '' ), @{$opts->{message}} ) );
            }
            else
            {
                $txt = $opts->{message};
            }
        }
        else
        {
            $txt = join( '', map( ( ref( $_ ) eq 'CODE' && !$self->{_msg_no_exec_sub} ) ? $_->() : ( $_ // '' ), @$ref ) );
        }
        # Reset it
        $self->{_msg_no_exec_sub} = 0;
        my $prefix = CORE::length( $opts->{prefix} ) ? $opts->{prefix} : '##';
        no overloading;
        $opts->{caller_info} = 1 if( !CORE::exists( $opts->{caller_info} ) || !CORE::length( $opts->{caller_info} ) );
        my $proc_info = " [PID: $$]";
        if( HAS_THREADS )
        {
            my $tid = threads->tid;
            $proc_info .= ' -> [thread id ' . $tid . ']' if( $tid );
        }
        my $mesg_raw = $opts->{caller_info} ? ( "${pkg}::${sub2}( $self ) [$line]${proc_info}: " . $txt ) : $txt;
        $mesg_raw    =~ s/\n$//gs;
        my $mesg = "${prefix} " . join( "\n${prefix} ", split( /\n/, $mesg_raw ) );
        
        my $info = 
        {
        'formatted' => $mesg,
        'message'   => $txt,
        'file'      => $file,
        'line'      => $line,
        'package'   => $class,
        'sub'       => $sub2,
        'level'     => ( $_[0] =~ /^\d+$/ ? $_[0] : CORE::exists( $opts->{level} ) ? $opts->{level} : 0 ),
        };
        $info->{type} = $opts->{type} if( $opts->{type} );
        
        ## If Mod perl is activated AND we are not using a private log
        if( $r && !${ "${class}::LOG_DEBUG" } )
        {
            if( my $log_handler = $r->get_handlers( 'PerlPrivateLogHandler' ) )
            {
                $log_handler->( $mesg_raw );
            }
            elsif( $self->{_log_handler} && ref( $self->{_log_handler} ) eq 'CODE' )
            {
                $self->{_log_handler}->( $info );
            }
            else
            {
                $r->log->debug( $mesg_raw );
            }
        }
        # Using ModPerl Server to log
        elsif( $MOD_PERL && !${ "${class}::LOG_DEBUG" } )
        {
            require Apache2::ServerUtil;
            my $s = Apache2::ServerUtil->server;
            $s->log->debug( $mesg );
        }
        # e.g. in our package, we could set the handler using the curry module like $self->{_log_handler} = $self->curry::log
        elsif( !-t( STDIN ) && $self->{_log_handler} && ref( $self->{_log_handler} ) eq 'CODE' )
        {
            $self->{_log_handler}->( $info );
        }
        elsif( !-t( STDIN ) && ${ $class . '::MESSAGE_HANDLER' } && ref( ${ $class . '::MESSAGE_HANDLER' } ) eq 'CODE' )
        {
            my $h = ${ $class . '::MESSAGE_HANDLER' };
            $h->( $info );
        }
        # Otherwise just on the stderr
        else
        {
            if( $opts->{no_encoding} )
            {
                $stderr_raw->print( $mesg, "\n" );
            }
            else
            {
                $stderr->print( $mesg, "\n" );
            }
        }
    }
    return(1);
}

sub message_check
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    no warnings 'uninitialized';
    no strict 'refs';
    if( @_ )
    {
        if( $_[0] !~ /^\d/ )
        {
            # The last parameter is an options parameter which has the level property set
            if( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) )
            {
                # Then let's use this
            }
            elsif( $self->{_message_default_level} =~ /^\d+$/ &&
                $self->{_message_default_level} > 0 )
            {
                unshift( @_, $self->{_message_default_level} );
            }
            else
            {
                unshift( @_, 1 );
            }
        }
        # If the first argument looks line a number, and there is more than 1 argument
        # and it is greater than 1, and greater than our current debug level
        # well, we do not output anything then...
        if( ( $_[0] =~ /^\d+$/ || 
              ( ref( $_[-1] ) eq 'HASH' && 
                CORE::exists( $_[-1]->{level} ) && 
                $_[-1]->{level} =~ /^\d+$/ 
              )
            ) && @_ > 1 )
        {
            my $message_level = 0;
            if( $_[0] =~ /^\d+$/ )
            {
                $message_level = shift( @_ );
            }
            elsif( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) )
            {
                $message_level = $_[-1]->{level};
            }
            my $target_re = '';
            if( ref( ${ "${class}::DEBUG_TARGET" } ) eq 'ARRAY' )
            {
                $target_re = scalar( @${ "${class}::DEBUG_TARGET" } ) ? join( '|', @${ "${class}::DEBUG_TARGET" } ) : '';
            }
            if( int( $self->{debug} ) >= $message_level ||
                int( $self->{verbose} ) >= $message_level ||
                ( defined( ${ $class . '::DEBUG' } ) && ${ $class . '::DEBUG' } >= $message_level ) ||
                int( $self->{debug_level} ) >= $message_level ||
                int( $self->{debug} ) >= 100 || 
                ( length( $target_re ) && $class =~ /^$target_re$/ && ${ $class . '::GLOBAL_DEBUG' } >= $message_level ) )
            {
                return( [ @_ ] );
            }
            else
            {
                return(0);
            }
        }
    }
    return(0);
}

sub message_frame
{
    my $self = shift( @_ );
    $self->{_message_frame } = {} if( !exists( $self->{_message_frame} ) );
    my $mf = $self->{_message_frame};
    if( @_ )
    {
        my $args = {};
        if( ref( $_[0] ) eq 'HASH' )
        {
            $args = shift( @_ );
            my @k = keys( %$args );
            @$mf{ @k } = @$args{ @k };
        }
        elsif( !( @_ % 2 ) )
        {
            $args = { @_ };
            my @k = keys( %$args );
            @$mf{ @k } = @$args{ @k };
        }
        elsif( scalar( @_ ) == 1 )
        {
            my $sub = shift( @_ );
            $sub = substr( $sub, rindex( $sub, '::' ) + 2 ) if( index( $sub, '::' ) != -1 );
            return( $mf->{ $sub } );
        }
        else
        {
            return( $self->error( "I was expecting a key => value pair such as routine => stack frame (integer)" ) );
        }
    }
    return( $mf );
}

# For compatibility for MIME::Decoder->head, itself used by HTTP::Promise::Entity
# "some decoders need to know a little about the file they are encoding/decoding; e.g., x-uu likes to have the filename.  The HEAD is any object which responds to messages like:
# $head->mime_attr( 'content-disposition.filename' );
sub mime_attr
{
    my $self = shift( @_ );
    my( $attr, $value ) = @_;
    return if( !defined( $attr ) || !length( $attr ) );
    # Break attribute name up
    my( $tag, $subtag ) = split( /\./, $attr, 2 );
    my $v = $self->header( $tag );
    require Module::Generic::HeaderValue;
    my $hv;
    if( defined( $v ) && length( $v ) )
    {
        $hv = Module::Generic::HeaderValue->new_from_header( $v );
        return( $self->pass_error( Module::Generic::HeaderValue->error ) ) if( !defined( $hv ) );
    }
    if( scalar( @_ ) > 1 )
    {
        if( defined( $subtag ) )
        {
            return( $self->error( "There is no header field '$tag' currently set, so you cannot assign a value for '$subtag'." ) ) if( !defined( $hv ) );
            $hv->param( $subtag => $value );
        }
        else
        {
            if( defined( $hv ) )
            {
                $hv->value( $value );
            }
            else
            {
                $hv = Module::Generic::HeaderValue->new( $value ) ||
                    return( $self->pass_error( Module::Generic::HeaderValue->error ) );
            }
        }
        $self->replace( $tag => "$hv" );
        return( $value );
    }
    else
    {
        return( '' ) if( !defined( $hv ) );
        return( defined( $subtag ) ? $hv->param( $subtag ) : $hv->value_data );
    }
}

# In HTTP parlance, the request may contain a Content-Encoding in multipart/form-data, 
# and the server response may contain Transfer-Encoding to indicate in which encoding the
# response is provided.
sub mime_encoding
{
    my $self = shift( @_ );
    my $te = $self->header( 'Content-Encoding' ) || $self->header( 'Transfer-Encoding' );
    return( '' ) if( !defined( $te ) || !length( $te ) );
    my $enc = lc( $te );
    # 7-bit, 7_bit -> 7bit. Same for 8-bit, 8_bit
    $enc =~ s{^([78])[ _-]bit\Z}{$1bit};
    return( $enc );
}

sub mime_type
{
    my $self = shift( @_ );
    my $default = shift( @_ ) || $self->default_type;
    my $ct = $self->type;
    if( !defined( $ct ) || !length( $ct ) )
    {
        return( $default ) if( defined( $default ) );
        return( '' );
    }
    return( $ct );
}

sub multipart_boundary
{
    my $self = shift( @_ );
    my $ct = $self->content_type;
    return( '' ) unless( defined( $ct ) && length( "$ct" ) );
    # There is no attributes to this Content-Type, so no need to go further.
    return( '' ) if( index( $ct, ';' ) == -1 || index( $ct, 'boundary' ) == -1 );
    require Module::Generic::HeaderValue;
    my $hv = Module::Generic::HeaderValue->new_from_header( $ct ) ||
        return( $self->pass_error( Module::Generic::HeaderValue->error ) );
    my $boundary = $hv->param( 'boundary' );
    return( $boundary );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/NEL>
sub nel { return( shift->_set_get_one( 'NEL', @_ ) ); }

sub new_array
{
    my $self = shift( @_ );
    require Module::Generic::Array;
    return( Module::Generic::Array->new( @_ ) );
}

sub new_field
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    return( $self->error( "No header field name was provided." ) ) if( !defined( $field ) || !length( "$field" ) );
    unless( scalar( keys( %$SUPPORTED ) ) )
    {
        $self->_load_class( 'Module::Generic::File' ) || return( $self->pass_error );
        my $dir = Module::Generic::File->new( ( $MOD_PATH || __FILE__ ) )->extension( undef );
        $dir->open || return( $self->error( "Unable to open directory \"$dir\": ", $dir->error ) );
        my $f;
        while( defined( $f = $dir->read( exclude_invisible => 1, as_object => 1 ) ) )
        {
            next if( $f->extension ne 'pm' );
            my $base = $f->basename( '.pm' );
            $SUPPORTED->{ lc( $base ) } = "HTTP\::Promise\::Headers\::${base}";
        }
    }
    ( my $name = $field ) =~ s/[\-_]+//g;
    $name = lc( $name );
    return( $self->error( "Unsupported field \"$field\"." ) ) if( !exists( $SUPPORTED->{ $name } ) );
    my $class = $SUPPORTED->{ $name };
    $self->_load_class( $class ) || return( $self->pass_error );
    my $o = $class->new( @_ ) ||
        return( $self->pass_error( $class->error ) );
    return( $o );
}

sub new_number
{
    my $self = shift( @_ );
    require Module::Generic::Number;
    return( Module::Generic::Number->new( @_ ) );
}

sub new_scalar
{
    my $self = shift( @_ );
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( @_ ) );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Origin>
sub origin { return( shift->_set_get_one_uri( 'Origin', @_ ) ); }

# Copied from Module::Generic to avoid loading it
sub pass_error
{
    my $self = shift( @_ );
    my $pack = ref( $self ) || $self;
    my $opts = {};
    my $err;
    my $class;
    no strict 'refs';
    if( scalar( @_ ) )
    {
        # Either an hash defining a new error and this will be passed along to error(); or
        # an hash with a single property: { class => 'Some::ExceptionClass' }
        if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
        {
            $opts = $_[0];
        }
        else
        {
            # $self->pass_error( $error_object, { class => 'Some::ExceptionClass' } );
            if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' )
            {
                $opts = pop( @_ );
            }
            $err = $_[0];
        }
    }
    # We set $class only if the hash provided is a one-element hash and not an error-defining hash
    $class = CORE::delete( $opts->{class} ) if( scalar( keys( %$opts ) ) == 1 && [keys( %$opts )]->[0] eq 'class' );
    
    # called with no argument, most likely from the same class to pass on an error 
    # set up earlier by another method; or
    # with an hash containing just one argument class => 'Some::ExceptionClass'
    if( !defined( $err ) && ( !scalar( @_ ) || defined( $class ) ) )
    {
        if( !defined( $self->{error} ) )
        {
            warn( "No error object provided and no previous error set either! It seems the previous method call returned a simple undef\n" );
        }
        else
        {
            $err = ( defined( $class ) ? bless( $self->{error} => $class ) : $self->{error} );
        }
    }
    elsif( defined( $err ) && 
           Scalar::Util::blessed( $err ) && 
           ( scalar( @_ ) == 1 || 
             ( scalar( @_ ) == 2 && defined( $class ) ) 
           ) )
    {
        $self->{error} = ${ $pack . '::ERROR' } = ( defined( $class ) ? bless( $err => $class ) : $err );
    }
    # If the error provided is not an object, we call error to create one
    else
    {
        return( $self->error( @_ ) );
    }
    
    if( want( 'OBJECT' ) )
    {
        require Module::Generic::Null;
        my $null = Module::Generic::Null->new( $err, { debug => $self->{debug}, has_error => 1 });
        rreturn( $null );
    }
    my $wantarray = wantarray();
    if( $self->debug )
    {
        my $caller = [caller(1)];
    }
    return;
}

sub print
{
    my $self = shift( @_ );
    my $fh = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $eol = $opts->{eol} || CRLF;
    $fh ||= select;
    return( $self->error( "Filehandle provided ($fh) is not a proper filehandle and its not a HTTP::Promise::IO object." ) ) if( !$self->_is_glob( $fh ) && !$self->_is_a( $fh => 'HTTP::Promise::IO' ) );
    return( $fh->print( $self->as_string( $eol ) ) );
}

sub proxy { return( shift->_set_get_uri( 'proxy', @_ ) ); }

# NOTE: proxy_authenticate() is inherited
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Proxy-Authenticate>
sub proxy_authenticate { return( shift->_set_get_one( 'Proxy-Authenticate', @_ ) ); }

# NOTE: proxy_authorization() is inherited
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Proxy-Authorization>
sub proxy_authorization { return( shift->_set_get_one( 'Proxy-Authorization', @_ ) ); }

# NOTE: proxy_authorization_basic() is inherited

# NOTE: push_header() is inherited

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Range>
sub range { return( shift->_set_get_multi( 'Range', @_ ) ); }

sub recommended_filename
{
    my $self = shift( @_ );
    foreach my $attr_name ( qw( content-disposition.filename* content-disposition.filename content-type.name ) )
    {
        my $value = $self->mime_attr( $attr_name );
        if( defined( $value ) && 
            $value ne '' &&
            $value =~ /\S/ )
        {
            return( $self->decode_filename( $value ) );
        }
    }
    return;
}

# NOTE: referer() and referrer() are inherited
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referer>
sub referer { return( shift->_set_get_one_uri( 'Referer', @_ ) ); }

sub referrer { return( shift->referer( @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy>
sub referrer_policy { return( shift->_set_get_one( 'Referrer-Policy', @_ ) ); }

sub remove { return( shift->remove_header( @_ ) ); }

# NOTE: remove_header() is inherited

# NOTE: remove_content_headers() is inherited

sub replace
{
    my $self = shift( @_ );
    my( $field, $value ) = @_;
    $self->header( $field => $value );
    return( $self );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Request-Headers>
sub request_headers { return( shift->_set_get_one( 'Access-Control-Request-Headers', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Request-Method>
sub request_method { return( shift->_set_get_one( 'Access-Control-Request-Method', @_ ) ); }

sub request_timeout { return( shift->_set_get_number( 'request_timeout', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After>
sub retry_after { return( shift->_set_get_one( 'Retry-After', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Save-Data>
sub save_data { return( shift->_set_get_one( 'Save-Data', @_ ) ); }

# NOTE: scan() is inherited

# NOTE: server() is inherited
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server>
sub server { return( shift->_set_get_one( 'Server', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server-Timing>
sub server_timing { return( shift->_set_get_one( 'Server-Timing', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>
sub set_cookie { return( shift->_set_get_one( 'Set-Cookie', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/SourceMap>
sub sourcemap { return( shift->_set_get_one( 'SourceMap', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security>
sub strict_transport_security { return( shift->_set_get_one( 'Strict-Transport-Security', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/TE>
sub te { return( shift->_set_get_one( 'TE', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Timing-Allow-Origin>
sub timing_allow_origin { return( shift->_set_get_multi( 'Timing-Allow-Origin', @_ ) ); }

# NOTE: title() is inherited and sucks really
sub title { return( shift->_set_get_one( 'Title', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Tk>
sub tk { return( shift->_set_get_one( 'Tk', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Trailer>
sub trailer { return( shift->_set_get_one( 'Trailer', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding>
sub transfer_encoding { return( shift->_set_get_one( 'Transfer-Encoding', @_ ) ); }

sub type
{
    my $self = shift( @_ );
    if( @_ )
    {
        # mime-type like text/html, text/plain or application/json, etc...
        my $type = shift( @_ );
        $self->{type} = $type;
        # We are being provided with content type parameters, such as charset=utf8, or version=1
        my $ct = $self->new_field( 'Content-Type' => $type, @_ );
        $self->header( 'Content-Type' => "$ct" );
        $self->{_ctype_cached} = "$ct";
        $self->{boundary} = $ct->boundary if( $ct->boundary );
    }
    # Cached
    elsif( CORE::length( $self->{type} ) && $self->{_ctype_cached} eq $self->content_type )
    {
        return( $self->{type} );
    }
    else
    {
        my $ctype_raw = $self->content_type;
        return if( !defined( $ctype_raw ) || !length( "$ctype_raw" ) );
        $self->{_ctype_cached} = $ctype_raw;
        # There is nothing, but the mime-type itself, so no need to bother
        if( index( $ctype_raw, ';' ) == -1 )
        {
            $self->{type} = $ctype_raw;
            $self->{boundary} = '';
        }
        else
        {
            # Content-Type: application/json; encoding=utf-8
            my $ct = $self->new_field( 'Content-Type' => $ctype_raw );
            return( $self->pass_error ) if( !defined( $ct ) );
            # Accept: application/json; version=1.0; charset=utf-8
            $self->{type} = lc( $ct->type );
            my $charset = $ct->charset;
            $charset = lc( $charset ) if( defined( $charset ) );
            $self->{charset} = $charset;
            $self->{boundary} = $ct->boundary if( $ct->boundary );
        }
    }
    return( $self->{type} );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade>
sub upgrade { return( shift->_set_get_multi( 'Upgrade', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade-Insecure-Requests>
sub upgrade_insecure_requests { return( shift->_set_get_one( 'Upgrade-Insecure-Requests', @_ ) ); }

sub uri_escape_utf8 { return( URI::Escape::XS::uri_escape( Encode::encode( 'UTF-8', $_[1] ) ) ); }

# NOTE: user_agent() is inherited
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent>
sub user_agent { return( shift->_set_get_one( 'user_agent', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Vary>
sub vary { return( shift->_set_get_multi( 'Vary', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Via>
sub via { return( shift->_set_get_multi( 'Via', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Want-Digest>
sub want_digest { return( shift->_set_get_multi( 'Want-Digest', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Warning>
sub warning { return( shift->_set_get_one( 'Warning', @_ ) ); }

# NOTE: www_authenticate() is superseded
# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/WWW-Authenticate>
sub www_authenticate { return( shift->_set_get_one( 'WWW-Authenticate', @_ ) ); }

sub x { return( shift->_set_get_one( 'X-' . $_[0], @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options>
sub x_content_type_options { return( shift->_set_get_one( 'X-Content-Type-Options', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-DNS-Prefetch-Control>
sub x_dns_prefetch_control { return( shift->_set_get_one( 'X-DNS-Prefetch-Control', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For>
sub x_forwarded_for { return( shift->_set_get_one( 'X-Forwarded-For', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-Host>
sub x_forwarded_host { return( shift->_set_get_one( 'X-Forwarded-Host', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-Proto>
sub x_forwarded_proto { return( shift->_set_get_one( 'X-Forwarded-Proto', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options>
sub x_frame_options { return( shift->_set_get_one( 'X-Frame-Options', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection>
sub x_xss_protection { return( shift->_set_get_one( 'X-XSS-Protection', @_ ) ); }

sub _basic_auth
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    return( $self->error( "No field provided to get its basic authentication value." ) ) if( !defined( $field ) || !length( $field ) );
    $self->_load_class( 'Crypt::Misc' ) || return( $self->pass_error );
    if( @_ )
    {
        my( $user, $pwd ) = @_;
        return( $self->error( "Basic authorisation user name cannot contain ':'." ) ) if( index( $user, ':' ) != -1 );
        $pwd = '' if( !defined( $pwd ) );
        $self->header( $field => sprintf( 'Basic %s', Crypt::Misc::encode_b64( "${user}:${pwd}" ) ) );
        return( "${user}:${pwd}" );
    }
    else
    {
        my $v = $self->header( $field );
        return( $v ) if( !defined( $v ) && !want( 'OBJECT' ) );
        if( defined( $v ) && $v =~ /^[[:blank:]\h]*Basic[[:blank:]\h]+(.+?)$/ )
        {
            $v = Crypt::Misc::decode_b64( $1 );
        }
        return( wantarray() ? split( /:/, "$v" ) : $self->new_scalar( $v ) );
    }
}

sub _date_header
{
    my $self = shift( @_ );
    my $f    = shift( @_ );
    return( $self->error( "No field was provided to get or set its value." ) ) if( !defined( $f ) || !length( "$f" ) );
    if( @_ )
    {
        my $this = shift( @_ );
        return( $self->remove_header( "$f" ) ) if( !defined( $this ) );
        my $opts = $self->_get_args_as_hash( @_ );
        $opts->{time_zone} = 'GMT' if( !defined( $opts->{time_zone} ) || !length( $opts->{time_zone} ) );
        require Module::Generic::DateTime;
        require DateTime::Format::Strptime;
        if( $this =~ /^\d+$/ )
        {
            # try-catch
            local $@;
            eval
            {
                $this = Module::Generic::DateTime->from_epoch( epoch => $this, time_zone => $opts->{time_zone} );
            };
            if( $@ )
            {
                return( $self->error( "An error occurred while trying to get the DateTime object for epoch value '$this': $@" ) );
            }
        }
        elsif( Scalar::Util::blessed( $this ) && $this->isa( 'DateTime' ) )
        {
            $this = Module::Generic::DateTime->new( $this );
        }
        elsif( Scalar::Util::blessed( $this ) && $this->isa( 'Module::Generic::DateTime' ) )
        {
            # Ok, pass through
        }
        else
        {
            return( $self->error( "I was expecting an integer representing a unix time or a DateTime object, but instead got '$this'." ) );
        }
        
        # try-catch
        local $@;
        eval
        {
            $this->set_time_zone( 'GMT' );
            my $fmt = DateTime::Format::Strptime->new(
                pattern => '%a, %d %b %Y %H:%M:%S GMT',
                locale  => 'en_GB',
                time_zone => 'GMT',
            );
            $this->set_formatter( $fmt );
            $self->header( $f => $this );
        };
        if( $@ )
        {
            return( $self->error( "An error occurred while trying to format the datetime '$this': $@" ) );
        }
        return( $this );
    }
    else
    {
        my $v = $self->header( "$f" );
        return( $v ) if( !defined( $v ) || !length( "${v}" ) );
        if( !length( "$v" ) || ( ref( $v ) && !overload::Method( $v, '""' ) ) )
        {
            warnings::warn( "I do not know what to do with this supposedly datetime header value '$v'\n" ) if( length( "$v" ) );
#             if( want( 'OBJECT' ) )
#             {
#                 require Module::Generic::Null;
#                 rreturn( Module::Generic::Null->new );
#             }
            return( '' );
        }
        
        # try-catch
        local $@;
        eval
        {
            unless( Scalar::Util::blessed( $v ) && $v->isa( 'Module::Generic::DateTime' ) )
            {
                # IE6 appends "; length = NNNN" on If-Modified-Since (can we handle it)
                # e.g.: Sat, 29 Oct 1994 19:43:31 GMT; length=34343
                if( index( $v, ';' ) != -1 )
                {
                    $v = [split( /[[:blank:]\h]*;[[:blank:]\h]*/, "${v}", 2 )]->[0];
                }
                require Module::Generic;
                my $dt = Module::Generic->_parse_timestamp( "$v" );
                return( $self->pass_error( Module::Generic->error ) ) if( !defined( $dt ) );
                my $fmt = DateTime::Format::Strptime->new( pattern => '%s' );
                $dt->set_formatter( $fmt );
                $v = Module::Generic::DateTime->new( $dt );
            }
        };
        if( $@ )
        {
            return( $self->error( "An error occurred while parsing datetime '$v': $@" ) );
        }
        return( $v );
    }
}

sub _get_args_as_array
{
    my $self = shift( @_ );
    return( [] ) if( !scalar( @_ ) );
    my $ref = [];
    if( scalar( @_ ) == 1 && 
        defined( $_[0] ) && 
        # Scalar::Util::reftype returns undef if the value is not a reference, which 
        # causes a warning to pop up since we then compare an undefined value.
        ref( $_[0] ) &&
        Scalar::Util::reftype( $_[0] ) eq 'ARRAY' )
    {
        $ref = shift( @_ );
    }
    else
    {
        $ref = [ @_ ];
    }
    return( $ref );
}

sub _get_args_as_hash
{
    my $self = shift( @_ );
    return( {} ) if( !scalar( @_ ) );
    no warnings 'uninitialized';
    my $ref = {};
    my $order = $self->new_array;
    my $need_list = Want::want( 'LIST' ) ? 1 : 0;
    if( scalar( @_ ) == 1 && Scalar::Util::reftype( $_[0] ) eq 'HASH' )
    {
        $ref = shift( @_ );
        $order = $self->new_array( [sort( keys( %$ref ) )] ) if( $need_list );
    }
    elsif( !( scalar( @_ ) % 2 ) )
    {
        $ref = { @_ };
        if( $need_list )
        {
            for( my $i = 0; $i < scalar( @_ ); $i += 2 )
            {
                $order->push( $_[$i] );
            }
        }
    }
    return( $need_list ? ( $ref, $order ) : $ref );
}

sub _header_get
{
    my $self = shift( @_ );
    my $f = shift( @_ );
    return( $self->error( "No header field was provided." ) ) if( !defined( $f ) || !length( "$f" ) );
    my @values = ();
    if( wantarray() )
    {
        @values = $self->header( "$f" );
        return if( !@values );
        return( @values );
    }
    else
    {
        return( $self->header( "$f" ) );
    }
}

sub _header_set
{
    my $self = shift( @_ );
    return( $self->SUPER::error( "Uneven number of parameters provided. I was expecting field-value pairs." ) ) if( @_ % 2 );
    my @args = ();
    for( my $i = 0; $i < scalar( @_ ); $i += 2 )
    {
        my( $f, $v ) = @_[$i..$i+1];
        next if( !defined( $v ) );
        if( $self->_is_array( $v ) )
        {
            my $ref = $self->_is_object( $v ) ? [@$v] : $v;
            push( @args, "$f" => $ref );
        }
        else
        {
            push( @args, "$f" => $v );
        }
    }
    
    # try-catch
    local $@;
    eval
    {
        $self->header( @args );
    };
    if( $@ )
    {
        return( $self->error( "Error trying to set headers with values: $@" ) );
    }
    return( $self );
}

sub _is_a
{
    my $self = shift( @_ );
    my $obj = shift( @_ );
    my $pkg = shift( @_ );
    no overloading;
    return if( !$obj || !$pkg );
    return if( !Scalar::Util::blessed( $obj ) );
    return( $obj->isa( $pkg ) );
}

sub _is_class_loaded
{
    my $self = shift( @_ );
    my $class = shift( @_ );
    ( my $pm = $class ) =~ s{::}{/}gs;
    $pm .= '.pm';
    return( CORE::exists( $INC{ $pm } ) );
}

sub _is_glob
{
    return(0) if( scalar( @_ < 2 ) );
    return(0) if( !defined( $_[1] ) );
    my $type = Scalar::Util::reftype( $_[1] );
    return(0) if( !defined( $type ) );
    return( $type eq 'GLOB' );
}

sub _load_class
{
    my $self = shift( @_ );
    my $class = shift( @_ ) || return( $self->error( "No class to load was provided." ) );
    eval( "require $class;" );
    return( $self->error( "Unable to load class \"$class\": $@" ) ) if( $@ );
    return( $class );
}

sub _set_get
{
    my $self = shift( @_ );
    my $prop = shift( @_ );
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

# If there can be multiple instance of the given header
sub _set_get_multi
{
    my $self = shift( @_ );
    my $f    = shift( @_ );
    return( $self->error( "No field was provided to get or set its value." ) ) if( !defined( $f ) || !length( "$f" ) );
    if( @_ )
    {
        my $v = shift( @_ );
        return( $self->remove_header( "$f" ) ) if( !defined( $v ) );
        # Too dangerous and unnecessary. The value type the user provides us defines how it will be set in the HTTP headers
        # An array reference means there will be possibly multiple instance of the header
        # A string, means there will be only one instance.
        # my $ref = Scalar::Util::reftype( $v ) eq 'ARRAY' ? $v : [split( /\,[[:blank:]\h]*/, $v)];
        # $self->header( "$f" => $ref );
        $self->header( "$f" => $v );
        return( $v );
    }
    else
    {
        my @vals = $self->header( "$f" );
        my $ref;
        if( @vals > 1 )
        {
            $ref = \@vals;
        }
        elsif( !defined( $vals[0] ) )
        {
            if( want( 'OBJECT' ) )
            {
                return( Module::Generic::Null->new );
            }
            else
            {
                return;
            }
        }
        else
        {
            $vals[0] =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
            $ref = [split( /\,[[:blank:]\h]*/, $vals[0] )];
        }
        # Thi is not such a good idea after all. It is better to return a list in list 
        # context or a scalar object otherwise
        # return( $self->new_array( $ref ) );
        return( wantarray() ? @$ref : $self->new_scalar( join( ', ', @$ref ) ) );
    }
}

# If there can be only one instance of the given header
sub _set_get_one
{
    my $self = shift( @_ );
    my $f    = shift( @_ );
    return( $self->error( "No field was provided to get or set its value." ) ) if( !defined( $f ) || !length( "$f" ) );
    if( @_ )
    {
        my $v = shift( @_ );
        return( $self->remove_header( "$f" ) ) if( !defined( $v ) );
        $self->header( "$f" => $v );
        return( $v );
    }
    else
    {
        my @vals = $self->header( "$f" );
        if( @vals > 1 )
        {
            # return( $self->new_array( \@vals ) );
            return( $self->new_scalar( join( ', ', @vals ) ) );
        }
        elsif( !defined( $vals[0] ) )
        {
            if( want( 'OBJECT' ) )
            {
                return( Module::Generic::Null->new );
            }
            else
            {
                return;
            }
        }
        else
        {
            $vals[0] =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
            return( $self->new_scalar( $vals[0] ) );
        }
    }
}

sub _set_get_one_number
{
    my $self = shift( @_ );
    my $f    = shift( @_ );
    return( $self->error( "No field was provided to get or set its value." ) ) if( !defined( $f ) || !length( "$f" ) );
    if( @_ )
    {
        my $v = shift( @_ );
        return( $self->remove_header( "$f" ) ) if( !defined( $v ) );
        $self->header( "$f" => $v );
        return( $v );
    }
    else
    {
        my $v = $self->header( "$f" );
        if( !defined( $v ) || !length( $v ) )
        {
            if( want( 'OBJECT' ) )
            {
                require Module::Generic::Null;
                my $null = Module::Generic::Null->new( '', { debug => $self->debug });
                rreturn( $null );
            }
            else
            {
                return( $v );
            }
        }
        # Ignore overflow values
        # 16 digits corresponding to 2^53-1 or 9007199254740991
        if( $v =~ /^[[:blank:]\h]*(\d{1,16})[[:blank:]\h]*$/ )
        {
            $v = $1;
        }
        else
        {
            return( '' );
        }
        return( $v ) if( ref( $v ) && !overload::Method( $v, '""' ) );
        return( $self->new_number( "$v" ) );
    }
}

sub _set_get_one_uri
{
    my $self  = shift( @_ );
    my $f = shift( @_ );
    return( $self->error( "No field was provided to get or set its value." ) ) if( !defined( $f ) || !length( "$f" ) );
    if( @_ )
    {
        my $v = shift( @_ );
        return( $self->remove_header( "$f" ) ) if( !defined( $v ) );
        $self->header( "$f" => $v );
        return( $v );
    }
    else
    {
        my $v = $self->header( "$f" );
        my $uri;
        # try-catch
        local $@;
        eval
        {
            require URI;
            $uri = URI->new( $v );
        };
        if( $@ )
        {
            return( $self->error( "Unable to create an URI object from the header value for \"$f\": $@" ) );
        }
        return( $uri );
    }
}

# NOTE: For CBOR and Sereal
sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my $h = {};
    my $headers = [];
    my $order = [];
    $self->scan(sub
    {
        my( $f, $val ) = @_;
        if( CORE::exists( $h->{ $f } ) )
        {
            $h->{ $f } = [ $h->{ $f } ] unless( CORE::ref( $h->{ $f } ) eq 'ARRAY' );
            CORE::push( @{$h->{ $f }}, $val );
        }
        else
        {
            $h->{ $f } = $val;
            CORE::push( @$order, $f );
        }
    });
    foreach my $f ( @$order )
    {
        CORE::push( @$headers, $f, $h->{ $f } );
    }
    my %hash  = %$self;
    $hash{_headers_to_restore} = $headers;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

# NOTE: Storable creates an instance of HTTP:::Promise::Headers. The only problem is that it does not work with XS module and that Storable discard whatever value is returned by STORABLE_thaw. See issue #19984 <https://github.com/Perl/perl5/issues/19984>
# So instead, we use this hook to store some data into the object created by Storable, and we call STORABLE_thaw_post_processing() with it and take what it returns.
sub STORABLE_thaw
{
    my( $self, undef, $class, $hash ) = @_;
    $class //= CORE::ref( $self ) || $self;
    $hash //= {};
    $hash->{_class} = $class;
    $self->{_deserialisation_params} = $hash;
    # Useles to do more in STORABLE_thaw, because Storable anyway ignores the value returned
    # so we just store our hash of parameters for STORABLE_thaw_post_processing to do its actual job
    CORE::return( $self );
}

sub STORABLE_thaw_post_processing
{
    my $obj = CORE::shift( @_ );
    my $hash = ( CORE::exists( $obj->{_deserialisation_params} ) && CORE::ref( $obj->{_deserialisation_params} ) eq 'HASH' )
        ? CORE::delete( $obj->{_deserialisation_params} )
        : {};
    my $class = CORE::delete( $hash->{_class} ) || CORE::ref( $obj ) || $obj;
    my $headers = CORE::ref( $hash->{_headers_to_restore} ) eq 'ARRAY'
        ? CORE::delete( $hash->{_headers_to_restore} )
        : [];
    my $new = $class->new( @$headers );
    foreach( CORE::keys( %$hash ) )
    {
        $new->{ $_ } = CORE::delete( $hash->{ $_ } );
    }
    CORE::return( $new );
}

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls STORABLE_thaw with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze. Then, after receiving $self from STORABLE_thaw, we call THAW which return a useable object. The one generated by Storable triggers the exception: "hl is not an instance of HTTP::XSHeader"
sub THAW
{
    # STORABLE_thaw would issue $cloning as the 2nd argument, while CBOR would issue
    # 'CBOR' as the second value.
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $headers = ( CORE::exists( $hash->{_headers_to_restore} ) && CORE::ref( $hash->{_headers_to_restore} ) eq 'ARRAY' )
        ? CORE::delete( $hash->{_headers_to_restore} )
        : [];
    
    my $new = $class->new( @$headers );
    foreach( CORE::keys( %$hash ) )
    {
        next if( CORE::scalar( CORE::grep( $_, @$headers ) ) );
        $new->{ $_ } = CORE::delete( $hash->{ $_ } );
    }
    CORE::return( $new );
}

sub TO_JSON
{
    my $self = shift( @_ );
    my $ref = [];
    $self->scan(sub
    {
        my( $header, $val ) = @_;
        CORE::push( @$ref, [ $header, $val ] );
    });
    return( $ref );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers - HTTP Headers Class

=head1 SYNOPSIS

    use HTTP::Promise::Headers;
    my $h = HTTP::Promise::Headers->new || 
        die( HTTP::Promise::Headers->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class uses for the most part an XS module (L<HTTP::XSHeaders>) to be very fast, and yet provides a convenient and versatile interface to retrieve and manipulate HTTP headers.

A number of classes has been created to have a more granular control on the creation of some header values. See L</SEE ALSO>

All HTTP headers known today have their corresponding method that can be used to easily get or set their corresponding header value.

=head1 CONSTRUCTOR

=head2 new

This instantiates a new L<HTTP::Promise::Headers> object. You might pass some initial
attribute-value pairs as parameters to the constructor.

For example:

    $h = HTTP::Headers->new(
        Date         => 'Mon, 09 May 2022 09:00:00 GMT',
        Content_Type => 'text/html; charset=utf-8; version=5.0',
        Content_Base => 'http://www.example.org/'
    );

The constructor arguments are passed to the L</header> method described below.

=head1 METHODS

=head2 add

This is an alias for L</push_header>

=head2 as_string

Provided with an optional C<EOL> to be used as End-Of-Line character, and this will return a string representation of the headers. C<EOL> defaults to C<\015\012>. Embedded "\n" characters in header field values will be substituted with this line ending sequence.

This uses L</scan> internally and use header field case as suggested by HTTP specifications. It will also follow recommended "Good Practice" of ordering the header fields. Long header values are not folded.

=head2 authorization_basic

This is a convenience method around the L</authorization> method for the C<Authorization> header using the "Basic Authentication Scheme".

To set the related header value, you provide a login and an optional password, and this will set the C<Authorization> header value and return the current headers object for chaining.

    $h->authorization_basic( $user, $password );

If no value is provided, this will get the curent value of the C<Authorization> header field, base64 decode it, and return the decoded string as a L<scalar object|Module::Generic::Scalar>, i.e. something like C<usernaem:password>

    my $str = $h->authorization_basic;

=head2 boundary

This is a convenience method to set or get the boundary, if any, used for multipart C<Content-Type>

If provided, this will add the C<boundary> parameter with the given value to the C<Content-Type> header field.

If no value is provided, this returns the current boundary, if any, or an empty string.

=head2 charset

This is a convenience method to set or get the charset associated with the C<Content-Type> header field.

If provided, this will add the C<charset> parameter with the given value to the C<Content-Type> header field.

If no value is provided, this returns the current charset, if any, or an empty string.

=head2 clear

This will remove all header fields.

=for Pod::Coverage:: client_date

=head2 clone

Returns a copy of this L<HTTP::Promise::Headers> object.

=head2 content_is_text

Returns true if the C<Content-Type> mime-type is textual in nature, i.e. its first half is C<text>, false otherwise. For example: C<text/plain> or C<text/html>

=head2 content_is_html

Returns true if the C<Content-Type> mime-type is html, such as C<text/html>, false otherwise.

=head2 content_is_json

Returns true if the C<Content-Type> mime-type is C<application/json>, false otherwise.

=head2 content_is_xhtml

Returns true if the C<Content-Type> mime-type is C<application/xhtml+xml> or C<application/vnd.wap.xhtml+xml>, false otherwise.

=head2 content_is_xml

Returns true if the C<Content-Type> mime-type is C<text/xml> or C<application/xml>, or contains the keyword C<xml>, false otherwise.

=head2 content_type_charset

This is a legacy method and it returns the upper-cased charset specified in the Content-Type header.
In list context return the lower-cased bare content type followed by the upper-cased charset.
Both values will be C<undef> if not specified in the header.

=head2 decode_filename

This takes a file name from the C<Content-Disposition> header value typically and returns it decoded if it was encoded as per the L<rfc2231|https://tools.ietf.org/html/rfc2231>

For example:

    Content-Disposition: form-data; name="fileField"; filename*=UTF-8''%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt
 
    my $fname = $h->decode_filename( "UTF-8''%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt" );
 
 or
 
    Content-Disposition: form-data; name="fileField"; filename*=UTF-8'ja-JP'%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt

    my $fname = $h->decode_filename( "UTF-8'ja-JP'%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt" );

or encoded with quoted-printable

    Content-Disposition: attachment; filename="=?UTF-8?Q?=E3=83=95=E3=82=A1=E3=82=A4=E3=83=AB.txt?="

    my $fname = $h->decode_filename( "=?UTF-8?Q?=E3=83=95=E3=82=A1=E3=82=A4=E3=83=AB.txt?=" );

or encoded with base64

    Content-Disposition: attachment; filename="=?UTF-8?B?44OV44Kh44Kk44OrLnR4dAo?="

    my $fname = $h->decode_filename( "=?UTF-8?B?44OV44Kh44Kk44OrLnR4dAo?=" );

In the above example, the result for C<$fname> would yield C<ファイル.txt> (i.e. file.txt in Japanese)

=head2 debug

Sets or gets the debug value. If positive, this will trigger an output of debugging messages on the STDERR or in the web server log files. Be mindful that this slows down the script, so make sure to switch it off once you are done.

=head2 default_type

Sets or gets the default mime-type to be used.

=head2 delete

This is an alias for L</remove_header>

=head2 encode_filename

This takes a file name to be used in the C<Content-Disposition> header value, and an optional language iso 639 code (see L<rfc1766|https://tools.ietf.org/html/rfc1766>), and if it contains non ascii characters, it will utf-8 encode it and URI escape it according to L<rfc2231|https://tools.ietf.org/html/rfc2231> and return the newly encoded file name.

If the file name did not require any encoding, it will return C<undef>, so you can write something like this:

    my $filename = q{マイファイル.txt};
    if( my $enc = $h->encode_filename( $filename ) )
    {
        $filename = $enc;
        # Now $filename is: UTF-8''%E3%83%9E%E3%82%A4%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt
    }

You can optionally pass a language code argument:

    if( my $enc = $h->encode_filename( $filename, 'ja-JP' ) )
    {
        $filename = $enc;
        # Now $filename is: UTF-8'ja-JP'%E3%83%9E%E3%82%A4%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt
    }

The C<Content-Disposition> header value would then contain a property C<filename*> (with the trailing wildcard).

=head2 error

Sets or gets an error and when set, this returns C<undef>. When no argument is provided, this returns the latest error set.

The error returned is actually a L<HTTP::Promise::Exception> object.

=head2 exists

Provided with a header field name and this returns true if it exists, or false otherwise.

=head2 flatten

    $h->flatten();

Returns the list of pairs of keys and values.

=head2 get

This is an alias for L</header>, mainly used without argument.

=head2 header

    $h->header( $field );
    $h->header( $field => $value );
    $h->header( $f1 => $v1, $f2 => $v2, ... );

The following is an extract from the original L<HTTP::Headers> class.

Sets or gets the value of one or more header fields.
The header field name (C<$field>) is not case sensitive.
To make the life easier for perl users who wants to avoid quoting before the => operator, you can use '_' as a replacement for '-' in header names.

The L</header> method accepts multiple field-value (C<$field => $value>) pairs, which means that you can update several header field values with a single invocation.

The C<$value> argument may be a plain string or an array reference of strings for a multi-valued field. If the C<$value> is provided as C<undef> then the field is removed.

If the C<$value> is not given, then that header field will remain unchanged. In addition to being a string, C<$value> may be something that stringifies.

The old value (or values) of the last of the header fields is returned. If no such field exists C<undef> will be returned.

A multi-valued field will be returned as separate values in list context and will be concatenated with ", " as separator in scalar context.
The HTTP spec (L<rfc7230|https://tools.ietf.org/html/rfc7230> which obsoleted L<rfc2616|https://tools.ietf.org/html/rfc2616>) promises that joining multiple values in this way will not change the semantic of a header field, but in practice there are cases like old-style Netscape cookies where "," is used as part of the syntax of a single field value.

Examples:

    $h->header( MIME_Version => '1.0',
		 User_Agent   => 'My-Web-Client/0.01' );
    $h->header( Accept => "text/html, text/plain, image/*" );
    $h->header( Accept => [qw( text/html text/plain image/* )] );
    @accepts = $h->header( 'Accept' ); # get multiple values
    $accepts = $h->header( 'Accept' ); # get values as a single string

=head2 header_field_names

The following is an extract from the original L<HTTP::Headers> class.

Returns the list of distinct names for the fields present in the header.
The field names have case as suggested by HTTP spec, and the names are returned in the recommended "Good Practice" order.

In scalar context return the number of distinct field names.

=head2 init_header

    $h->init_header( $field => $value );

Set the specified header to the given value, but only if no previous value for that field is set.

The header field name (C<$field>) is not case sensitive and '_' can be used as a replacement for '-'.

The $value argument may be a scalar or a reference to a list of scalars.

=head2 make_boundary

Returns a new boundary using L<Data::UUID>

=for Pod::Coverage message

=for Pod::Coverage message_check

=for Pod::Coverage message_frame

=head2 mime_attr

Provided with a header field name and an attribute name separated by a dot, such as C<content-disposition.filename> and this will return the value for that attribute in this header.

If a value is provided, it will be set, otherwise it will be returned.

If no attribute is provided, it will set or get the header field main value.

For example:

    Content-Disposition: attachment; filename="hello.txt"
    my $dispo = $h->mime_attr( 'content-disposition' );

will return C<attachment>

=head2 mime_encoding

Returns the value of the C<Content-Encoding>, C<Transfer-Encoding> or C<Content-Transfer-Encoding> (the latter only exists in mail, not in HTTP)

=head2 mime_type

Returns the mime-type from the C<Content-Type> header value, or the one from L<default_type>, if it is set. If nothing is found, this returns an empty string (not C<undef>).

=head2 multipart_boundary

Returns the multipart boundary used, if any, or an empty string otherwise.

    my $boundary = $h->multipart_boundary;
    # or you can provide the Content-Type if you already have it; it will save a few cycle
    my $boundary = $h->multipart_boundary( $content_type );

=head2 print

Provided with a filehandle, or an L<HTTP::Promise::IO> object and this will print on it the string representation of the headers and return whatever value L<perlfunc/print> will return.

=head2 proxy_authorization_basic

=head2 push_header

    $h->push_header( $field => $value );
    $h->push_header( $f1 => $v1, $f2 => $v2, ... );

Add a new value for the specified header. Previous values for the same header are retained.

As for the L</header> method, the field name (C<$field>) is not case sensitive and '_' can be used as a replacement for '-'.

The $value argument may be a scalar or a reference to a list of scalars.

    $header->push_header( Accept => 'image/jpeg' );
    $header->push_header( Accept => [ map( "image/$_", qw( gif png tiff ) )] );

=head2 recommended_filename

This returns the filename set in either C<Content-Disposition> with the C<filename> property or in C<Content-Type> with the C<name> property.

If none exists, this returns C<undef>.

=head2 remove

This is an alias for L</remove_header>

=head2 remove_content_headers

This will remove all the headers used to describe the content of a message.

All header field names prefixed with C<Content-> are included in this category, as well as C<Allow>, C<Expires> and
C<Last-Modified>. L<rfc7230|https://tools.ietf.org/html/rfc7230> denotes these headers as I<Entity Header Fields>.

The return value is a new L<HTTP::Promise::Headers> object that contains the removed headers only.

=head2 remove_header

    my @values = $h->remove_header( $field, ... );
    my $total_values_removed = $h->remove_header( $field, ... );

This function removes the header with the specified names.

The header names (C<$field>) are not case sensitive and '_' can be used as a replacement for '-'.

The return value is the values of the headers removed. In scalar context the number of headers removed is returned.

Note that if you pass in multiple header names then it is generally not possible to tell which of the returned values belonged to which field.

=head2 replace

Provided with a header field name and a value and this replace whatever current value with the value provided.

It returns the current object for chaining.

=head2 request_timeout

Sets or gets the request timeout. This takes an integer.

=head2 scan

    $h->scan( \&process_header_field );

Apply a subroutine to each header field in turn.
The callback routine is called with two parameters; the name of the field and a single value (a string).
If a header field is multi-valued, then the routine is called once for each value.
The field name passed to the callback routine has case as suggested by HTTP spec, and the headers will be visited in the recommended "Good Practice" order.

Any return values of the callback routine are ignored.
The loop can be broken by raising an exception (C<die>), but the caller of scan() would have to trap the exception itself.

=head2 type

This sets or gets the C<Content-Type> header value when setting a value, and returns only the mime-type when retrieving the value.

    $h->type( 'text/plain' );
    # Assuming Content-Type: text/html; charset=utf-8
    my $type = $h->type; # text/html

=head2 uri_escape_utf8

Provided with a string and this returns an URI-escaped string using L<URI::Escape::XS>

=head1 HTTP HEADERS METHODS

=head2 accept

    $h->accept( q{text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8} );
    $h->accept( [qw( text/html application/xhtml+xml application/xml;q=0.9 */*;q=0.8 )] );

Sets or gets the C<Accept> header field value. It takes either a string or an array or array reference of values.

See L<rfc7231, section 5.3.2|https://tools.ietf.org/html/rfc7231#section-5.3.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept>

See also L<HTTP::Promise::Headers::Accept>

=head2 accept_charset

    $h->accept( 'utf-8' );

Sets or gets the C<Accept-Charset> headers field value. It takes a single string value.

You should know that the C<Accept-Charset> header is deprecated by HTTP standards and that no modern web browsers is sending nor any modern HTTP server recognising it.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Charset>

=head2 accept_encoding

    $h->accept_encoding( 'gzip, deflate, br' );
    $h->accept_encoding( [qw( gzip deflate br )] );
    $h->accept_encoding( 'br;q=1.0, gzip;q=0.8, *;q=0.1' );

Sets or gets the C<Accept-Encoding> header field value. It takes either a string or an array or array reference of values.

See also L<HTTP::Promise::Headers::AcceptEncoding> to have a more granular control.

Encoding header fields and their nuances:

=over 4

=item C<Accept-Encoding>

The encodings accepted by the client.

=item C<Content-Encoding>

Contains the encodings that have been applied to the content, before transport

=item C<TE>

The encodings the user agent accepts.

=item C<Transfer-Encoding>

The encoding applied during transfer, such as C<chunked>

=back

See L<rfc7231, section 5.3.4|https://tools.ietf.org/html/rfc7231#section-5.3.4> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding>

=head2 accept_language

    $h->accept_language( 'fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5' );
    $h->accept_language( [qw(fr-CH fr;q=0.9 en;q=0.8 de;q=0.7 *;q=0.5 )] );

Sets or gets the C<Accept-Language> header field value. It takes either a string or an array or array reference of values.

See also L<HTTP::Promise::Headers::AcceptLanguage> to have a more granular control.

See L<rfc7231, section 5.3.5|https://tools.ietf.org/html/rfc7231#section-5.3.5> and  L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language>

=head2 accept_patch

    $h->accept_patch( 'application/example, text/example' );
    $h->accept_patch( [qw( application/example text/example )] );
    $h->accept_patch( 'text/example;charset=utf-8' );
    $h->accept_patch( 'application/merge-patch+json' );

Sets or gets the C<Accept-Patch> header field value. It takes either a string or an array or array reference of values.

This is a server response header.

See L<rfc5789, section 3.1|https://tools.ietf.org/html/rfc5789#section-3.1>, L<rfc7231, section 4.3.4|https://tools.ietf.org/html/rfc7231#section-4.3.4> and  L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Patch>

=head2 accept_post

    $h->accept_post( 'application/example, text/example' );
    $h->accept_post( [qw( application/example text/example )] );
    $h->accept_post( 'image/webp' );
    $h->accept_post( '*/*' );

Sets or gets the C<Accept-Post> header field value. It takes either a string or an array or array reference of values.

This is a server response header.

See L<rfc7231, section 4.3.3|https://tools.ietf.org/html/rfc7231#section-4.3.3> and  L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Post>

=head2 accept_ranges

    $h->accept_ranges(1234);

Sets or gets the C<Accept-Ranges> header field value. It takes either a string or an array or array reference of values.

This is a server response header.

See L<rfc7233, section 2.3|https://tools.ietf.org/html/rfc7233#section-2.3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Ranges>

=head2 acceptables

This returns a new L<HTTP::Promise::Headers::Accept> object based on the content of the C<Accept> header value.

=head2 age

    $h->age(1234);

Sets or gets the C<Age> header field value.  It takes a numeric value.

This is a server response header.

See L<rfc7234, section 5.1|https://tools.ietf.org/html/rfc7234#section-5.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Age>

=head2 allow

    $h->allow( 'GET, POST, HEAD' );
    $h->allow( [qw( GET POST HEAD )] );

Sets or gets the C<Allow> header field value. It takes either a string or an array or array reference of values.

This is a server response header.

See L<rfc7231, section 7.4.1|https://tools.ietf.org/html/rfc7231#section-7.4.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Age>

=head2 allow_credentials

    # Access-Control-Allow-Credentials: true
    $h->allow_credentials( 'true' );

Sets or gets the C<Access-Control-Allow-Credentials> header field value. It takes a string boolean value: C<true> or C<false>.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials>

=head2 allow_headers

    # Access-Control-Allow-Headers: X-Custom-Header, Upgrade-Insecure-Requests
    $h->allow_headers( 'X-Custom-Header, Upgrade-Insecure-Requests' );
    $h->allow_headers( [qw( X-Custom-Header Upgrade-Insecure-Requests )] );

Sets or gets the C<Access-Control-Allow-Headers> header field value. It takes either a string or an array or array reference of values.

This is a server response header.

See L<rfc7231, section 7.4.1|https://tools.ietf.org/html/rfc7231#section-7.4.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Age>

=head2 allow_methods

    # Access-Control-Allow-Methods: POST, GET, OPTIONS
    $h->allow_methods( 'POST, GET, OPTIONS' );
    $h->allow_methods( [qw( POST GET OPTIONS )] );
    # Access-Control-Allow-Methods: *
    $h->allow_methods( '*' );

Sets or gets the C<Access-Control-Allow-Methods> header field value. It takes either a string or an array or array reference of values.

This is a server response header.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods>

=head2 allow_origin

    # Access-Control-Allow-Origin: *
    $h->allow_origin( '*' );
    # Access-Control-Allow-Origin: https://food.example.org
    $h->allow_origin( 'https://food.example.org' );
    # Access-Control-Allow-Origin: null
    $h->allow_origin( 'null' );

Sets or gets the C<Access-Control-Allow-Origin> header field value. It takes a string value.

This is a server response header.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods>

=head2 alt_svc

    # Alt-Svc: h2=":443"; ma=2592000;
    $h->alt_svc( 'h2=":443"; ma=2592000' );
    # Alt-Svc: h2=":443"; ma=2592000; persist=1
    $h->alt_svc( 'h2=":443"; ma=2592000; persist=1' );
    # Alt-Svc: h2="alt.example.com:443", h2=":443"
    $h->alt_svc( 'h2="alt.example.com:443", h2=":443"' );
    # Alt-Svc: h3-25=":443"; ma=3600, h2=":443"; ma=3600
    $h->alt_svc( 'h3-25=":443"; ma=3600, h2=":443"; ma=3600' );

Sets or gets the C<Alt-Svc> header field value. It takes either a string or an array or array reference of values.

See also L<HTTP::Promise::Headers::AltSvc> to have a more granular control.

See L<rfc7838, section 3|https://tools.ietf.org/html/rfc7838#section-3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Alt-Svc>

=head2 alternate_server

This is a convenience method for the header field C<Alt-Svc>.

To et it value, you provide a hash or hash reference of properties, including C<name> and C<value> respectively for the protocol-id and the alternate authority.

    $h->alternate_server( name => 'h2', value => ':443', ma => 2592000, persist => 1 );

would create the header value:

    Alt-Svc: h2=":443"; ma=2592000; persist=1

Without any parameter, it creates a new L<HTTP::Promise::Headers::AltSvc> object for each C<Alt-Svc> header value and returns an L<array object|Module::Generic::Array> of all those L<HTTP::Promise::Headers::AltSvc> objects.

=head2 authorization

    # Authorization: Basic YWxhZGRpbjpvcGVuc2VzYW1l
    $h->authorization( 'Basic YWxhZGRpbjpvcGVuc2VzYW1l' );

Sets or gets the C<Authorization> header field value. It takes a string value.

See also L</authorization_basic>

See L<rfc7235, section 4.2|https://tools.ietf.org/html/rfc7235#section-4.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization>

=head2 cache_control

    # Cache-Control: max-age=604800
    $h->cache_control( 'max-age=604800' );
    # Cache-Control: s-maxage=604800
    $h->cache_control( 's-maxage=604800' );
    # Cache-Control: no-cache
    $h->cache_control( 'no-cache' );
    # Cache-Control: max-age=604800, must-revalidate
    $h->cache_control( 'max-age=604800, must-revalidate' );
    # Cache-Control: public, max-age=604800, immutable
    $h->cache_control( 'public, max-age=604800, immutable' );

Sets or gets the C<Cache-Control> header field value. It takes either a string or an array or array reference of values.

See also L<HTTP::Promise::Headers::CacheControl> to have a more granular control.

See L<rfc7234, section 5.2|https://tools.ietf.org/html/rfc7234#section-5.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control>

=head2 clear_site_data

    # Clear-Site-Data: "cache", "cookies", "storage", "executionContexts"
    $h->clear_site_data( q{"cache", "cookies", "storage", "executionContexts"} );
    $h->clear_site_data( [qw( cache cookies storage executionContexts )] );

The Clear-Site-Data header accepts one or more directives. If all types of data should be cleared, the wildcard directive ("*") can be used.

See also L<HTTP::Promise::Headers::ClearSiteData> to have a more granular control.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data>

=head2 connection

    # Connection: keep-alive
    # Connection: close

Sets or gets the C<Connection> header field value. It takes a string value.

See L<rfc7230, section 6.1|https://tools.ietf.org/html/rfc7230#section-6.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Connection>

=head2 content_disposition

    # Content-Disposition: inline
    # Content-Disposition: attachment
    # Content-Disposition: attachment; filename="filename.jpg"
    # Content-Disposition: form-data; name="fieldName"
    # Content-Disposition: form-data; name="fieldName"; filename="filename.jpg"

Sets or gets the C<Content-Disposition> header field value. It takes a string value.

See also L<HTTP::Promise::Headers::ContentDisposition> to have a more granular control.

See L<rfc6266, section 4|https://tools.ietf.org/html/rfc6266#section-4>, L<rfc7578, section 4.2|https://tools.ietf.org/html/rfc7578#section-4.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition>

=head2 content_encoding

    # Content-Encoding: gzip
    # Content-Encoding: compress
    # Content-Encoding: deflate
    # Content-Encoding: br

    # Multiple, in the order in which they were applied
    # Content-Encoding: deflate, gzip

Sets or gets the C<Cache-Encoding> header field value. It takes either a string or an array or array reference of values.

Encoding header fields and their nuances:

=over 4

=item C<Accept-Encoding>

The encodings accepted by the client.

=item C<Content-Encoding>

Contains the encodings that have been applied to the content, before transport

=item C<TE>

The encodings the user agent accepts.

=item C<Transfer-Encoding>

The encoding applied during transfer, such as C<chunked>

=back

See L<rfc7230, section 3.3.1|https://tools.ietf.org/html/rfc7230#section-3.3.1>:
"Unlike Content-Encoding (L<Section 3.1.2.1 of [RFC7231]|https://tools.ietf.org/html/rfc7231#section-3.1.2.1>), Transfer-Encoding is a property of the message, not of the representation"

See also L</accept_encoding>, L</transfer_encoding> and L</te> and this L<Stackoverflow discussion|https://stackoverflow.com/questions/11641923/transfer-encoding-gzip-vs-content-encoding-gzip>

See L<rfc7231, section 3.1.2.2|https://tools.ietf.org/html/rfc7231#section-3.1.2.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Encoding>

=head2 content_language

    # Content-Language: de-DE
    # Content-Language: en-US
    $h->content_language( 'en-GB' );
    # Content-Language: de-DE, en-CA
    $h->content_language( 'de-DE, en-CA' );
    $h->content_language( [qw( de-DE en-CA )] );

Sets or gets the C<Cache-Language> header field value. It takes either a string or an array or array reference of values.

There is no enforcement on the value provided, so it is up to you to set the proper value or values.

See L<rfc7231, section 3.1.3.2|https://tools.ietf.org/html/rfc7231#section-3.1.3.2>, L<rfc5646|https://tools.ietf.org/html/rfc5646> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Language>

=head2 content_length

    # Content-Length: 72
    $h->content_length(72);

Sets or gets the C<Connection> header field value. It takes a numeric value.

See L<rfc7230, section 3.3.2|https://tools.ietf.org/html/rfc7230#section-3.3.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Length>

=head2 content_location

    # Content-Location: /some/where/file.html
    $h->content_location( '/some/where/file.html' );

Sets or gets the C<Connection> header field value. It takes a numeric value.

See L<rfc7231, section 3.1.4.2|https://tools.ietf.org/html/rfc7231#section-3.1.4.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Location>

=head2 content_range

    # Content-Range: bytes 200-1000/67589
    # Unsatisfiable range value
    # Content-Range: bytes */1234

Sets or gets the C<Content-Range> header field value. It takes a string value.

See also L<HTTP::Promise::Headers::ContentRange> to have a more granular control.

See L<rfc7233, section 4.2|https://tools.ietf.org/html/rfc7233#section-4.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Range>

=head2 content_security_policy

    # Content-Security-Policy: default-src 'self' http://example.com;
    #                           connect-src 'none';
    # Content-Security-Policy: connect-src http://example.com/;
    #                           script-src http://example.com/

Sets or gets the C<Content-Security-Policy> header field value. It takes a string value.

See also L<HTTP::Promise::Headers::ContentSecurityPolicy> to have a more granular control.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy>

=head2 content_security_policy_report_only

    # Content-Security-Policy-Report-Only: default-src https:; report-uri /csp-violation-report-endpoint/

Sets or gets the C<Content-Security-Policy-Report-Only> header field value. It takes a string value of properly formatted header value.

See also L<HTTP::Promise::Headers::ContentSecurityPolicyReportOnly> to have a more granular control.

=head2 content_type

This sets or gets the C<Content-Type> header value. It takes a string value.

If a value is provided, this will set the header value. If no value is provided, this simply return the header field value.

See also L<HTTP::Promise::Headers::ContentType> to have a more granular control.

See also L<rfc7233, section 4.1|https://tools.ietf.org/html/rfc7233#section-4.1>, L<rfc7231, section 3.1.1.5|https://tools.ietf.org/html/rfc7231#section-3.1.1.5> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types>, and L<this Mozilla documentation too|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type>

=head2 cross_origin_embedder_policy

    # Cross-Origin-Embedder-Policy: require-corp
    # Cross-Origin-Opener-Policy: same-origin

This sets or gets the C<Cross-Origin-Embedder-Policy> header value. It takes a string value.

It can have either of the following value: C<require-corp> or C<same-origin>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Embedder-Policy>

=head2 cross_origin_opener_policy

    # Cross-Origin-Opener-Policy: unsafe-none
    # Cross-Origin-Opener-Policy: same-origin-allow-popups
    # Cross-Origin-Opener-Policy: same-origin

This sets or gets the C<Cross-Origin-Opener-Policy> header value. It takes a string value.

It can have either of the following value: C<unsafe-none> or C<same-origin-allow-popups> or C<same-origin>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Opener-Policy>

=head2 cross_origin_resource_policy

This sets or gets the C<Cross-Origin-Resource-Policy> header value. It takes a string value.

It can have either of the following value: C<same-site> or C<same-origin> or C<same-origin>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Resource-Policy>

For more example: L<https://resourcepolicy.fyi/>

=head2 cspro

This is an alias for L</content_security_policy_report_only>

=head2 date

This sets or gets the C<Date> header value. It takes a date string value, a unix timestamp or a L<DateTime> value.

If no value is provided, it returns the current value of the C<Date> header field as a L<DateTime> object.

=head2 device_memory

    # Device-Memory: 1

This sets or gets the C<Device-Memory> header value. It takes a number.

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Device-Memory>

=head2 digest

    # Digest: sha-256=X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE=
    # Digest: sha-256=X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE=,unixsum=30637

This sets or gets the C<Digest> header value. It takes either a string or an array or array reference of properly formatted values.

See L<draft rfc|https://tools.ietf.org/html/draft-ietf-httpbis-digest-headers-05#section-3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Digest>

=head2 dnt

    # DNT: 0
    # DNT: 1
    # DNT: null

This sets or gets the C<DNT> header value. It takes a string value.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/DNT>

=head2 early_data

    # Early-Data: 1

This sets or gets the C<Early-Data> header value. It takes a string value.

See also L<rfc8470, section 5.1|https://tools.ietf.org/html/rfc8470#section-5.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Early-Data>

=head2 etag

    # ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
    # ETag: W/"0815"

This sets or gets the C<Etag> header value. It takes a string of properly formatted value.

See also L<rfc7232, section 2.3|https://tools.ietf.org/html/rfc7232#section-2.3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag>

=head2 expect

This sets or gets the C<Expect> header value. It takes a string of properly formatted value, typically C<100-continue>

For example, before sending a very large file:

    PUT /some/where HTTP/1.1
    Host: origin.example.com
    Content-Type: video/h264
    Content-Length: 1234567890987
    Expect: 100-continue

If the server is ok, it would return a C<100 Continue>

See also L<rfc7231, section 5.1.1|https://tools.ietf.org/html/rfc7231#section-5.1.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expect>, L<interesting article|https://www.bram.us/2020/04/14/about-the-http-expect-100-continue-header/>

=head2 expect_ct

    # Expect-CT: max-age=86400, enforce, report-uri="https://foo.example.com/report"
    $h->expect_ct( q{max-age=86400, enforce, report-uri="https://foo.example.com/report"} );
    $h->expect_ct( [qw( max-age=86400 enforce report-uri="https://foo.example.com/report" )] );

This sets or gets the C<Expect-CT> header value. It takes a string of properly formatted value.

See also L<HTTP::Promise::Headers::ExpectCT> to have a more granular control.

See also L<rfc draft|https://tools.ietf.org/html/draft-ietf-httpbis-expect-ct-08> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expect-CT>

=head2 expires

This sets or gets the C<Expires> header value. It takes a date string value, a unix timestamp or a L<DateTime> value.

If no value is provided, it returns the current value of the C<Date> header field as a L<DateTime> object.

For example:

    Expires: Wed, 21 Oct 2015 07:28:00 GMT

See also L<rfc7234, section 5.3|https://tools.ietf.org/html/rfc7234#section-5.3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expires>

=head2 expose_headers

This sets or gets the C<Expose-Headers> header value. It takes either a string or an array or array reference of properly formatted values.

For example:

    Access-Control-Expose-Headers: *, Authorization

See also L<rfc7234, section 5.3|https://tools.ietf.org/html/rfc7234#section-5.3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers>

=head2 forwarded

This sets or gets the C<Forwarded> header value. It takes either a string or an array or array reference of properly formatted values.

See also L<HTTP::Promise::Headers::Forwarded> to have a more granular control.

For example:

    Forwarded: for=192.0.2.60;proto=http;by=203.0.113.43
    # Values from multiple proxy servers can be appended using a comma
    Forwarded: for=192.0.2.43, for=198.51.100.17

See also L<rfc7239, section 4|https://tools.ietf.org/html/rfc7239#section-4> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Forwarded>

=head2 from

This sets or gets the C<From> header value. It takes a string value.

For example:

    From: webmaster@example.org

See also L<rfc7231, section 5.5.1|https://tools.ietf.org/html/rfc7231#section-5.5.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/From>

=head2 host

This sets or gets the C<Host> header value. It takes a string value.

For example:

    Host: dev.example.org

See also L<rfc7230, section 5.4|https://tools.ietf.org/html/rfc7230#section-5.4> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host>

=head2 if_match

This sets or gets the C<If-Match> header value. It takes a string value.

For example:

    If-Match: "bfc13a64729c4290ef5b2c2730249c88ca92d82d"
    If-Match: "67ab43", "54ed21", "7892dd"
    If-Match: *

See also L<rfc7232, section 3.1|https://tools.ietf.org/html/rfc7232#section-3.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match>

=head2 if_modified_since

This sets or gets the C<If-Modified-Since> header value. It takes a date string value, a unix timestamp or a L<DateTime> value.

If no value is provided, it returns the current value of the C<Date> header field as a L<DateTime> object.

For example:

    If-Modified-Since: Wed, 21 Oct 2015 07:28:00 GMT

See also L<rfc7232, section 3.3|https://tools.ietf.org/html/rfc7232#section-3.3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since>

=head2 if_none_match

This sets or gets the C<If-None-Match> header value. It takes a string value.

For example:

    If-None-Match: "bfc13a64729c4290ef5b2c2730249c88ca92d82d"
    If-None-Match: W/"67ab43", "54ed21", "7892dd"
    If-None-Match: *

See also L<rfc7232, section 3.2|https://tools.ietf.org/html/rfc7232#section-3.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since>

=head2 if_range

This sets or gets the C<If-Range> header value. It takes a string value.

For example:

    If-Range: Wed, 21 Oct 2015 07:28:00 GMT

See also L<rfc7233, section 3.2|https://tools.ietf.org/html/rfc7233#section-3.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Range>

=head2 if_unmodified_since

This sets or gets the C<If-Unmodified-Since> header value. It takes a date string value, a unix timestamp or a L<DateTime> value.

If no value is provided, it returns the current value of the C<Date> header field as a L<DateTime> object.

For example:

    If-Unmodified-Since: Wed, 21 Oct 2015 07:28:00 GMT

See also L<rfc7232, section 3.4|https://tools.ietf.org/html/rfc7232#section-3.4> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Unmodified-Since>

=head2 keep_alive

This sets or gets the C<Keep-Alive> header value. It takes either a string or an array or array reference of properly formatted values.

See also L<HTTP::Promise::Headers::KeepAlive> to have a more granular control.

Example response containing a Keep-Alive header:

    HTTP/1.1 200 OK
    Connection: Keep-Alive
    Content-Encoding: gzip
    Content-Type: text/html; charset=utf-8
    Date: Thu, 11 Aug 2016 15:23:13 GMT
    Keep-Alive: timeout=5, max=1000
    Last-Modified: Mon, 25 Jul 2016 04:32:39 GMT
    Server: Apache

See also L<rfc7230, section A.1.2|https://tools.ietf.org/html/rfc7230#section-A.1.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Keep-Alive>

=head2 last_modified

This sets or gets the C<Last-Modified> header value. It takes a date string value, a unix timestamp or a L<DateTime> value.

If no value is provided, it returns the current value of the C<Date> header field as a L<DateTime> object.

For example:

    Last-Modified: Wed, 21 Oct 2015 07:28:00 GMT

See also L<rfc7232, section 2.2|https://tools.ietf.org/html/rfc7232#section-2.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified>

=head2 link

This sets or gets the C<Link> header value. It takes a string value.

See also L<HTTP::Promise::Headers::Link> to have a more granular control.

Example:

    Link: <https://example.com>; rel="preconnect"

See also L<rfc8288, section 3|https://tools.ietf.org/html/rfc8288#section-3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Link>

=head2 location

This sets or gets the C<Location> header value. It takes a string value.

Example:

    Location: /index.html

See also L<rfc7231, section 7.1.2|https://tools.ietf.org/html/rfc7231#section-7.1.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location>

=head2 max_age

This sets or gets the C<Location> header value. It takes a numeric value.

Example:

    Access-Control-Max-Age: 600

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age>

=head2 nel

This sets or gets the C<NEL> header value. It takes a string of properly formatted json value.

Example:

    NEL: { "report_to": "name_of_reporting_group", "max_age": 12345, "include_subdomains": false, "success_fraction": 0.0, "failure_fraction": 1.0 }

See also L<rfc8288, section 3|https://tools.ietf.org/html/rfc8288#section-3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/NEL>

=for Pod::Coverage new_array

=for Pod::Coverage new_field

=for Pod::Coverage new_number

=for Pod::Coverage new_scalar

=head2 origin

This sets or gets the C<Origin> header value. It takes a string of properly formatted json value.

Example:

    Origin: http://dev.example.org:80

See also L<rfc6454, section 7|https://tools.ietf.org/html/rfc6454#section-7> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Origin>

=for Pod::Coverage pass_error

=head2 proxy

Sets or gets the URI used for the proxy. It returns a L<URI> object.

=head2 proxy_authenticate

This sets or gets the C<Proxy-Authenticate> header value. It takes a string value.

Example:

    Proxy-Authenticate: Basic realm="Access to the internal site"

See also L<rfc6454, section 7|https://tools.ietf.org/html/rfc6454#section-7> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Proxy-Authenticate>

=head2 proxy_authorization

This sets or gets the C<Proxy-Authorization> header value. It takes a string value.

Example:

    Proxy-Authorization: Basic YWxhZGRpbjpvcGVuc2VzYW1l

See also L<rfc7235, section 4.4|https://tools.ietf.org/html/rfc7235#section-4.4> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Proxy-Authorization>

=head2 range

This sets or gets the C<Range> header value. It takes a string value.

See also L<HTTP::Promise::Headers::Range> to have a more granular control.

Example:

    Range: bytes=200-1000, 2000-6576, 19000-

See also L<rfc7233, section 3.1|https://tools.ietf.org/html/rfc7233#section-3.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Range>

=head2 referer

This sets or gets the C<Referer> header value. It takes a string value.

Example:

    Referer: https://dev.example.org/some/where
    Referer: https://example.org/page?q=123
    Referer: https://example.org/

See also L<rfc7231, section 5.5.2|https://tools.ietf.org/html/rfc7231#section-5.5.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referer>

=head2 referrer

This is an alias for L</referer>

=head2 referrer_policy

This sets or gets the C<Referrer-Policy> header value. It takes a string value.

The allowed values can be: C<no-referrer>, C<no-referrer-when-downgrade>, C<origin>, C<origin-when-cross-origin>, C<same-origin>, C<strict-origin>, C<strict-origin-when-cross-origin>, C<unsafe-url>

Example:

    Referrer-Policy: no-referrer
    # With fallback
    Referrer-Policy: no-referrer, strict-origin-when-cross-origin

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy>

=head2 request_headers

This sets or gets the C<Access-Control-Request-Headers> header value. It takes a string value.

Example:

    Access-Control-Request-Headers: X-PINGOTHER, Content-Type

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Request-Headers>

=head2 request_method

This sets or gets the C<Access-Control-Request-Method> header value. It takes a string value.

Example:

    Access-Control-Request-Method: POST

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Request-Method>

=head2 retry_after

This sets or gets the C<Retry-After> header value. It takes a string value.

Example:

    Retry-After: Wed, 21 Oct 2015 07:28:00 GMT
    Retry-After: 120

See also L<rfc7231, section 7.1.3|https://tools.ietf.org/html/rfc7231#section-7.1.3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After>

=head2 save_data

This sets or gets the C<Save-Data> header value. It takes a string value.

The value can be either C<on> or C<off>

Example:

    Save-Data: on

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Save-Data>

=head2 server

This sets or gets the C<Server> header value. It takes a string value.

Example:

    Server: Apache/2.4.1 (Unix)

See also L<rfc7231, section 7.4.2|https://tools.ietf.org/html/rfc7231#section-7.4.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server>

=head2 server_timing

This sets or gets the C<Server> header value. It takes a string value.

See also L<HTTP::Promise::Headers::ServerTiming> to have a more granular control.

Example:

    # Single metric without value
    Server-Timing: missedCache

    # Single metric with value
    Server-Timing: cpu;dur=2.4

    # Single metric with description and value
    Server-Timing: cache;desc="Cache Read";dur=23.2

    # Two metrics with value
    Server-Timing: db;dur=53, app;dur=47.2

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server-Timing>

=head2 set_cookie

This sets or gets the C<Set-Cookie> header value. It takes a string value.

See also L<Cookie> to have a more granular control.

Example:

    Set-Cookie: sessionId=38afes7a8
    Set-Cookie: __Secure-ID=123; Secure; Domain=example.com
    Set-Cookie: __Host-ID=123; Secure; Path=/

See also L<rfc6265, section 4.1|https://tools.ietf.org/html/rfc6265#section-4.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>

=head2 sourcemap

This sets or gets the C<SourceMap> header value. It takes a string value.

Example:

    SourceMap: /path/to/file.js.map

See also L<draft specifications|https://sourcemaps.info/spec.html> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/SourceMap>

=head2 strict_transport_security

This sets or gets the C<Strict-Transport-Security> header value. It takes a string value.

See also L<HTTP::Promise::Headers::StrictTransportSecurity> to have a more granular control.

Example:

    Strict-Transport-Security: max-age=63072000; includeSubDomains; preload

See also L<rfc6797, section 6.1|https://tools.ietf.org/html/rfc6797#section-6.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security>

=head2 te

This sets or gets the C<TE> header value. It takes a string value.

See also L<HTTP::Promise::Headers::TE> to have a more granular control.

Example:

    TE: deflate
    TE: gzip
    TE: trailers

    # Multiple directives, weighted with the quality value syntax:
    TE: trailers, deflate;q=0.5

Notably, the value C<trailers> means the HTTP client support trailers, which are a set of headers sent after the body.

Encoding header fields and their nuances:

=over 4

=item C<Accept-Encoding>

The encodings accepted by the client.

=item C<Content-Encoding>

Contains the encodings that have been applied to the content, before transport

=item C<TE>

The encodings the user agent accepts.

=item C<Transfer-Encoding>

The encoding applied during transfer, such as C<chunked>

=back

See also L</transfer_encoding>, L<rfc7230, section 4.3|https://tools.ietf.org/html/rfc7230#section-4.3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/TE>, L<article on trailers|https://httptoolkit.tech/blog/http-wtf/#http-trailers>

=head2 timing_allow_origin

This sets or gets the C<Timing-Allow-Origin> header value. It takes a string value.

Example:

    Timing-Allow-Origin: *
    Timing-Allow-Origin: https://dev.example.org, https://example.com

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Timing-Allow-Origin>

=head2 title

Sets or gets the C<Title> of the HTML document if that were the case. This is here for legacy.

=head2 tk

This sets or gets the deprecated C<Tk> header value. It takes a string value.

Example:

    Tk: N

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Tk>

=head2 trailer

This sets or gets the C<Trailer> header value. It takes a string value.

Example:

    Trailer: Expires

See also L<rfc7230, section 4.4|https://tools.ietf.org/html/rfc7230#section-4.4>, L<rfc7230, section 4.1.2|https://tools.ietf.org/html/rfc7230#section-4.1.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Trailer>

=head2 transfer_encoding

This sets or gets the C<Transfer-Encoding> header value. It takes a string value.

Example:

    Transfer-Encoding: chunked
    Transfer-Encoding: compress
    Transfer-Encoding: deflate
    Transfer-Encoding: gzip

    # Several values can be listed, separated by a comma
    Transfer-Encoding: gzip, chunked

Encoding header fields and their nuances:

=over 4

=item C<Accept-Encoding>

The encodings accepted by the client.

=item C<Content-Encoding>

Contains the encodings that have been applied to the content, before transport

=item C<TE>

The encodings the user agent accepts.

=item C<Transfer-Encoding>

The encoding applied during transfer, such as C<chunked>

=back

See L<rfc7230, section 3.3.1|https://tools.ietf.org/html/rfc7230#section-3.3.1>:
"Unlike Content-Encoding (L<Section 3.1.2.1 of [RFC7231]|https://tools.ietf.org/html/rfc7231#section-3.1.2.1>), Transfer-Encoding is a property of the message, not of the representation"

See also L</te>, L<rfc7230, section 3.3.1|https://tools.ietf.org/html/rfc7230#section-3.3.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding> and L<Wikipedia|https://en.wikipedia.org/wiki/Chunked_transfer_encoding>

=head2 upgrade

This sets or gets the C<Upgrade> header value. It takes a string value.

Example:

    Connection: upgrade
    Upgrade: HTTP/2.0, SHTTP/1.3, IRC/6.9, RTA/x11

    Connection: Upgrade
    Upgrade: websocket

See also L<rfc7230, section 6.7|https://tools.ietf.org/html/rfc7230#section-6.7>, L<rfc7231, section 6.6.15|https://tools.ietf.org/html/rfc7231#section-6.6.15>, L<rfc7240, section 8.1.1|https://tools.ietf.org/html/rfc7240#section-8.1.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade>

=head2 upgrade_insecure_requests

This sets or gets the C<Upgrade-Insecure-Requests> header value. It takes a string value.

Example:

    Upgrade-Insecure-Requests: 1

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade-Insecure-Requests>

=head2 user_agent

This sets or gets the C<User-Agent> header value. It takes a string value.

Example:

    User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0
    User-Agent: curl/7.64.1

See also L<rfc7231, section 5.5.3|https://tools.ietf.org/html/rfc7231#section-5.5.3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent>

=head2 vary

This sets or gets the C<Vary> header value. It takes a string value.

Example:

    Vary: *
    Vary: Accept-Encoding, User-Agent

See also L<rfc7231, section 7.1.4|https://tools.ietf.org/html/rfc7231#section-7.1.4> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Vary>

=head2 via

This sets or gets the C<Via> header value. It takes a string value.

Example:

    Via: 1.1 vegur
    Via: HTTP/1.1 GWA
    Via: 1.0 fred, 1.1 p.example.net

See also L<rfc7230, section 5.7.1|https://tools.ietf.org/html/rfc7230#section-5.7.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Via>

=head2 want_digest

This sets or gets the C<Want-Digest> header value. It takes a string value.

Example:

    Want-Digest: sha-256
    Want-Digest: SHA-512;q=0.3, sha-256;q=1, md5;q=0

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Want-Digest>

=head2 warning

This sets or gets the C<Warning> header value. It takes a string value.

Example:

    Warning: 110 anderson/1.3.37 "Response is stale"

See also L<rfc7234, section 5.5|https://tools.ietf.org/html/rfc7234#section-5.5> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Warning>

=head2 www_authenticate

This sets or gets the C<WWW-Authenticate> header value. It takes a string value.

Example:

    WWW-Authenticate: Basic realm="Access to the staging site", charset="UTF-8"
    WWW-Authenticate: Digest
        realm="http-auth@example.org",
        qop="auth, auth-int",
        algorithm=SHA-256,
        nonce="7ypf/xlj9XXwfDPEoM4URrv/xwf94BcCAzFZH4GiTo0v",
        opaque="FQhe/qaU925kfnzjCev0ciny7QMkPqMAFRtzCUYo5tdS"
    WWW-Authenticate: Digest
        realm="http-auth@example.org",
        qop="auth, auth-int",
        algorithm=MD5,
        nonce="7ypf/xlj9XXwfDPEoM4URrv/xwf94BcCAzFZH4GiTo0v",
        opaque="FQhe/qaU925kfnzjCev0ciny7QMkPqMAFRtzCUYo5tdS"

See also L<rfc7235, section 4.1|https://tools.ietf.org/html/rfc7235#section-4.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/WWW-Authenticate>

=head2 x

Sets or gets an arbitrary C<X-*> header. For example:

    $h->x( 'Spip-Cache' => 3600 );

would set the C<X-Spip-Cache> header value to C<3600>

    my $value = $h->x( 'Spip-Cache' );

=head2 x_content_type_options

This sets or gets the C<X-Content-Type-Options> header value. It takes a string value.

Example:

    X-Content-Type-Options: nosniff

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options>

=head2 x_dns_prefetch_control

This sets or gets the C<X-DNS-Prefetch-Control> header value. It takes a string value.

Example:

    X-DNS-Prefetch-Control: on
    X-DNS-Prefetch-Control: off

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-DNS-Prefetch-Control>

=head2 x_forwarded_for

This sets or gets the C<X-Forwarded-For> header value. It takes a string value.

Example:

    X-Forwarded-For: 2001:db8:85a3:8d3:1319:8a2e:370:7348
    X-Forwarded-For: 203.0.113.195
    X-Forwarded-For: 203.0.113.195, 2001:db8:85a3:8d3:1319:8a2e:370:7348

See also L</host>, L</forwarded>, L</x_forwarded_host>, L</x_forwarded_proto>, L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For>

=head2 x_forwarded_host

This sets or gets the C<X-Forwarded-Host> header value. It takes a string value.

Example:

    X-Forwarded-Host: id42.example-cdn.com

See also L</host>, L</forwarded>, L</x_forwarded_for>, L</x_forwarded_proto>, L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-Host>

=head2 x_forwarded_proto

This sets or gets the C<X-Forwarded-Proto> header value. It takes a string value.

Example:

   X-Forwarded-Proto: https

See also L</host>, L</forwarded>, L</x_forwarded_for>, L</x_forwarded_host>, L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-Proto>

=head2 x_frame_options

This sets or gets the C<X-Frame-Options> header value. It takes a string value.

Example:

    X-Frame-Options: DENY
    X-Frame-Options: SAMEORIGIN

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options>

=head2 x_xss_protection

This sets or gets the C<X-XSS-Protection> header value. It takes a string value.

Example:

    X-XSS-Protection: 0
    X-XSS-Protection: 1
    X-XSS-Protection: 1; mode=block
    X-XSS-Protection: 1; report=https://example.org/some/where

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection>

=for Pod::Coverage STORABLE_thaw_post_processing

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation on HTTP headers|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers>

L<HTTP::Promise::Headers::AcceptEncoding>, L<HTTP::Promise::Headers::AcceptLanguage>, L<HTTP::Promise::Headers::Accept>, L<HTTP::Promise::Headers::AltSvc>, L<HTTP::Promise::Headers::CacheControl>, L<HTTP::Promise::Headers::ClearSiteData>, L<HTTP::Promise::Headers::ContentDisposition>, L<HTTP::Promise::Headers::ContentRange>, L<HTTP::Promise::Headers::ContentSecurityPolicy>, L<HTTP::Promise::Headers::ContentSecurityPolicyReportOnly>, L<HTTP::Promise::Headers::ContentType>, L<HTTP::Promise::Headers::Cookie>, L<HTTP::Promise::Headers::ExpectCT>, L<HTTP::Promise::Headers::Forwarded>, L<HTTP::Promise::Headers::Generic>, L<HTTP::Promise::Headers::KeepAlive>, L<HTTP::Promise::Headers::Link>, L<HTTP::Promise::Headers::Range>, L<HTTP::Promise::Headers::ServerTiming>, L<HTTP::Promise::Headers::StrictTransportSecurity>, L<HTTP::Promise::Headers::TE>

L<rfc7230, section 3.2 on headers field names|https://tools.ietf.org/html/rfc7230#section-3.2>,
L<rfc6838 on mime types|https://tools.ietf.org/html/rfc6838>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
