##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise.pm
## Version v0.5.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/05/06
## Modified 2024/02/07
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $AUTOLOAD $CONTENT_SIZE_THRESHOLD $CRLF 
                 $DEFAULT_PROTOCOL $EXCEPTION_CLASS $EXTENSION_VARY
                 $IS_WIN32 $HTTP_TOKEN $HTTP_QUOTED_STRING $BUFFER_SIZE 
                 $MAX_HEADERS_SIZE $MAX_BODY_IN_MEMORY_SIZE $EXPECT_THRESHOLD $DEFAULT_MIME_TYPE 
                 $SERIALISER @EXPORT_OK );
    use Cookie;
    use Cookie::Jar;
    use Errno qw( EAGAIN ECONNRESET EINPROGRESS EINTR EWOULDBLOCK ECONNABORTED EISCONN );
    use HTTP::Promise::Exception;
    use HTTP::Promise::IO;
    use HTTP::Promise::Pool;
    use HTTP::Promise::Request;
    use HTTP::Promise::Response;
    use HTTP::Promise::Status qw( :all );
    # use Nice::Try;
    use Promise::Me;
    use Scalar::Util ();
    use URI;
    use URI::Escape::XS ();
    # < 0 so we recognise those as system errors
    use constant {
        ERROR_EINTR => ( abs( Errno::EINTR ) * -1 ),
        TYPE_URL_ENCODED => 'application/x-www-form-urlencoded',
    };
    our @EXPORT_OK = qw( fetch );
    # "\r\n" is not portable
    our $CRLF = "\015\012";
    our $DEFAULT_PROTOCOL = 'HTTP/1.1';
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
    our $HTTP_TOKEN         = qr/[^\x00-\x31\x7F]+/;
    our $HTTP_QUOTED_STRING = qr/"([^"]+|\\.)*"/;
    # 10K
    our $BUFFER_SIZE = 10240000;
    our $MAX_HEADERS_SIZE = 8192;
    # 256Kb
    our $MAX_BODY_IN_MEMORY_SIZE = 102400;
    # 1Mb
    our $EXPECT_THRESHOLD = 1024000000;
    our $EXTENSION_VARY = 1;
    our $DEFAULT_MIME_TYPE = 'application/octet-stream';
    our $SERIALISER = $Promise::Me::SERIALISER;
    our $VERSION = 'v0.5.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{accept_language}        = [];
    $self->{accept_encoding}        = 'auto';
    $self->{agent}                  = qq{HTTP-Promise/$VERSION (perl; +https://metacpan.org/pod/HTTP::Promise)};
    $self->{auto_switch_https}      = 1;
    $self->{buffer_size}            = $BUFFER_SIZE;
    $self->{cookie_jar}             = Cookie::Jar->new;
    $self->{default_headers}        = undef;
    $self->{default_protocol}       = ( $DEFAULT_PROTOCOL || 'HTTP/1.1' );
    # DNT -> Do not track header field
    $self->{dnt}                    = undef;
    $self->{expect_threshold}       = $EXPECT_THRESHOLD;
    $self->{ext_vary}               = $EXTENSION_VARY;
    $self->{from}                   = undef;
    $self->{inactivity_timeout}     = 600;
    $self->{local_host}             = undef;
    $self->{local_port}             = undef;
    $self->{max_body_in_memory_size} = $MAX_BODY_IN_MEMORY_SIZE;
    $self->{max_headers_size}       = $MAX_HEADERS_SIZE;
    $self->{max_redirect}           = 7;
    $self->{max_size}               = undef;
    $self->{medium}                 = $Promise::Me::SHARE_MEDIUM;
    $self->{no_proxy}               = [];
    $self->{proxy}                  = $ENV{http_proxy} || $ENV{HTTP_PROXY} || undef;
    $self->{proxy_authorization}    = undef;
    $self->{requests_redirectable}  = [qw( GET HEAD )];
    $self->{send_te}                = 1;
    $self->{serialiser}             = $SERIALISER;
    $self->{shared_mem_size}        = $Promise::Me::RESULT_MEMORY_SIZE;
    $self->{ssl_opts}               = undef;
    $self->{stop_if}                = sub{};
    $self->{threshold}              = $CONTENT_SIZE_THRESHOLD;
    # 3 minutes
    $self->{timeout}                = 180;
    $self->{use_content_file}       = 0;
    $self->{use_promise}            = 1;
    $self->{_init_strict_use_sub}   = 1;
    $self->{_exception_class}       = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $headers = $self->default_headers;
    if( $headers )
    {
        unless( $self->connection_header )
        {
            my $connection_header = 'keep-alive';
            if( $headers->exists( 'connection' ) )
            {
                $connection_header = $headers->get( 'connection' );
            }
            $self->{connection_header} = $connection_header;
        }
    }
    else
    {
        $self->default_headers( HTTP::Promise::Headers->new ) ||
            return( $self->pass_error( HTTP::Promise::Headers->error ) );
    }
    $self->{_pool} = HTTP::Promise::Pool->new;
    return( $self );
}

sub accept_language { return( shift->_set_get_array_as_object( 'accept_language', @_ ) ); }

sub accept_encoding { return( shift->_set_get_scalar_as_object( 'accept_encoding', @_ ) ); }

# NOTE: request parameter
sub agent { return( shift->_set_get_scalar_as_object( 'agent', @_ ) ); }

sub auto_switch_https { return( shift->_set_get_boolean( 'auto_switch_https', @_ ) ); }

sub buffer_size { return( shift->_set_get_number( 'buffer_size', @_ ) ); }

sub clone
{
    my $self = shift( @_ );
    my $new = $self->SUPER::clone;
    if( $self->{default_headers} )
    {
        $new->{default_headers} = $self->{default_headers}->clone;
    }
    $new->{_pool} = HTTP::Promise::Pool->new;
    return( $new );
}

sub connection_header { return( shift->_set_get_scalar_as_object( 'connection_header', @_ ) ); }

# NOTE: request parameter
sub cookie_jar { return( shift->_set_get_scalar( 'cookie_jar', @_ ) ); }

sub decodable { return( HTTP::Promise::Stream->decodable( @_ ) ); }

# NOTE: request parameter
sub default_header { return( shift->default_headers->header( @_ ) ); }

# NOTE: request parameter
sub default_headers { return( shift->_set_get_object_without_init( 'default_headers', [qw( HTTP::Promise::Headers HTTP::Headers )], @_ ) ); }

sub default_protocol { return( shift->_set_get_scalar_as_object( 'default_protocol', @_ ) ); }

sub delete
{
    my $self = shift( @_ );
    if( $self->use_promise )
    {
        my $prom = Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            my $req = HTTP::Promise::Request->new( 'DELETE' => @_ ) ||
            return( $reject->( HTTP::Promise::Request->error ) );
            my $resp = $self->send( $req ) || return( $reject->( $self->error ) );
            return( $resolve->( $resp ) );
        },
        {
            args => [@_],
            ( defined( $self->{serialiser} ) ? ( serialiser => $self->{serialiser} ) : () ),
            ( defined( $self->{medium} ) ? ( medium => $self->{medium} ) : () ),
            ( defined( $self->{shared_mem_size} ) ? ( result_shared_mem_size => $self->{shared_mem_size} ) : () ),
        }) || return( $self->pass_error( Promise::Me->error ) );
        return( $prom );
    }
    else
    {
        my $req = HTTP::Promise::Request->new( 'DELETE' => @_ ) ||
            return( $self->pass_error( HTTP::Promise::Request->error ) );
        unless( $req->headers->host )
        {
            $req->headers->host( $req->host );
        }
        my $resp = $self->send( $req ) ||
            return( $self->pass_error );
        return( $resp );
    }
}

sub dnt { return( shift->_set_get_boolean( 'dnt', @_ ) ); }

sub expect_threshold { return( shift->_set_get_number( 'expect_threshold', @_ ) ); }

sub ext_vary { return( shift->_set_get_boolean( 'ext_vary', @_ ) ); }

sub fetch
{
    my $self;
    if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( __PACKAGE__ ) )
    {
        $self = shift( @_ );
    }
    else
    {
        $self = __PACKAGE__->new;
    }
    my $meth = 'get';
    for( my $i = 0; $i < scalar( @_ ); $i += 2 )
    {
        if( $_[$i] eq 'method' )
        {
            $meth = $_[$i + 1];
            splice( @_, $i, 2 );
            last;
        }
    }
    return( $self->error( "Unknown HTTP method \"${meth}\"." ) ) if( $meth !~ /^$HTTP::Promise::Request::KNOWN_METHODS_I$/i );
    my $code = $self->can( $meth ) ||
        return( $self->error( "Somehow the HTTP method \"${meth}\" is not supported by ", ref( $self ) ) );
    return( $code->( $self, @_ ) );
}

sub file { return( shift->_set_get_object_without_init( 'file', 'Module::Generic::File', @_ ) ); }

# NOTE: request parameter
sub from { return( shift->_set_get_scalar_as_object( 'from', @_ ) ); }

sub get
{
    my $self = shift( @_ );
    if( $self->use_promise )
    {
        my $prom = Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            my $req = $self->_make_request_query( GET => @_ ) ||
            return( $reject->( HTTP::Promise::Request->error ) );
            my $resp = $self->send( $req ) || return( $reject->( $self->error ) );
            return( $resolve->( $resp ) );
        },
        {
            args => [@_],
            ( defined( $self->{serialiser} ) ? ( serialiser => $self->{serialiser} ) : () ),
            ( defined( $self->{medium} ) ? ( medium => $self->{medium} ) : () ),
            ( defined( $self->{shared_mem_size} ) ? ( result_shared_mem_size => $self->{shared_mem_size} ) : () ),
        }) || return( $self->pass_error( Promise::Me->error ) );
        return( $prom );
    }
    else
    {
        my $req = $self->_make_request_query( GET => @_ ) ||
            return( $self->pass_error( HTTP::Promise::Request->error ) );
        my $resp = $self->send( $req ) ||
            return( $self->pass_error );
        return( $resp );
    }
}

sub head
{
    my $self = shift( @_ );
    if( $self->use_promise )
    {
        my $prom = Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            my $req = $self->_make_request_query( HEAD => @_ ) ||
            return( $reject->( HTTP::Promise::Request->error ) );
            my $resp = $self->send( $req ) || return( $reject->( $self->error ) );
            return( $resolve->( $resp ) );
        },
        {
            args => [@_],
            ( defined( $self->{serialiser} ) ? ( serialiser => $self->{serialiser} ) : () ),
            ( defined( $self->{medium} ) ? ( medium => $self->{medium} ) : () ),
            ( defined( $self->{shared_mem_size} ) ? ( result_shared_mem_size => $self->{shared_mem_size} ) : () ),
        }) || return( $self->pass_error( Promise::Me->error ) );
        return( $prom );
    }
    else
    {
        my $req = $self->_make_request_query( HEAD => @_ ) ||
            return( $self->pass_error( HTTP::Promise::Request->error ) );
        my $resp = $self->send( $req ) ||
            return( $self->pass_error );
        return( $resp );
    }
}

sub httpize_datetime { return( shift->_datetime( @_ ) ); }

sub inactivity_timeout { return( shift->_set_get_number( 'inactivity_timeout', @_ ) ); }

sub is_protocol_supported
{
    my $self = shift( @_ );
    my $scheme = shift( @_ ) ||
        return( $self->error( "No scheme value was provided." ) );
    if( $self->_is_object( $scheme ) )
    {
        return( $self->error( "Object provided (", overload::StrVal( $scheme ), ") does not support the 'scheme' method." ) ) if( !$scheme->can( 'scheme' ) );
        $scheme = $scheme->scheme;
    }
    else
    {
        return( $self->error( "Illegal scheme '$scheme' passed to is_protocol_supported" ) ) if( $scheme =~ /\W/ );
        $scheme = lc $scheme;
    }
    return(1) if( $scheme eq 'http' || $scheme eq 'https' );
    return(0);
}

sub languages { return( shift->_set_get_array_as_object( 'accept_language', @_ ) ); }

# NOTE: request parameter
sub local_address { return( shift->_set_get_scalar( 'local_host', @_ ) ); }

sub local_host { return( shift->_set_get_scalar( 'local_host', @_ ) ); }

sub local_port { return( shift->_set_get_scalar( 'local_port', @_ ) ); }

sub max_body_in_memory_size { return( shift->_set_get_number( 'max_body_in_memory_size', @_ ) ); }

sub max_headers_size { return( shift->_set_get_number( 'max_headers_size', @_ ) ); }

# NOTE: request parameter
sub max_redirect { return( shift->_set_get_number( 'max_redirect', @_ ) ); }

# NOTE: request parameter
sub max_size { return( shift->_set_get_number( 'max_size', @_ ) ); }

# NOTE: medium method for Promise::Me
sub medium { return( shift->_set_get_scalar( 'medium', @_ ) ); }

# TODO: mirror
sub mirror
{
    my $self = shift( @_ );
    my( $url, $file ) = @_;
    if( $self->use_promise )
    {
        return( Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            return( $reject->( HTTP::Promise::Exception->new({
                code => 500,
                message => 'Local file name is missing',
            }) ) ) unless( defined( $file ) && length( $file ) );

            my $request = HTTP::Promise::Request->new( 'GET' => $url ) ||
                return( $reject->( HTTP::Promise::Exception->new({
                    code => 500,
                    message => HTTP::Promise::Request->error->message
                }) ) );
            $self->prepare_headers( $request ) ||
                return( $reject->( HTTP::Promise::Exception->new({
                    code => 500,
                    message => $self->error->message,
                }) ) );
            $file = $self->new_file( $file ) ||
                return( $reject->( HTTP::Promise::Exception->new({
                    code => 500,
                    message => $self->error->message,
                }) ) );
            # If the file exists, add a cache-related header
            if( $file->exists )
            {
                # Module::Generic::Finfo->mtime returns a Module::Generic::DateTime object
                my $mtime = $file->mtime;
                if( $mtime )
                {
                    my $strtime = $self->_datetime( $mtime ) ||
                        return( $reject->( HTTP::Promise::Exception->new({
                            code => 500,
                            message => $self->error->message,
                        }) ) );
                    $request->header( 'If-Modified-Since' => $strtime );
                }
            }

            my $tmpfile = $self->new_tempfile;
            $tmpfile->touch || return( $reject->( $tmpfile->error ) );

            my $response = $self->send( $request ) || return( $reject->( $self->pass_error ) );
    
            if( $response->header( 'X-Died' ) )
            {
                $tmpfile->unlink;
                return( $reject->( HTTP::Promise::Exception->new({
                    code => 500,
                    message => $response->header( 'X-Died' ),
                }) ) );
            }

            # Only fetching a fresh copy of the file would be considered success.
            # If the file was not modified, "304" would returned, which
            # is considered by HTTP::Status to be a "redirect", /not/ "success"
            if( $response->is_success )
            {
                my $body = $response->entity->body;
                return( $reject->( HTTP::Promise::Exception->new({
                    code => 500,
                    message => "No body set for this HTTP message entity.",
                }) ) ) if( !$body );
                my $io = $body->open( '<' ) ||
                    return( $reject->( HTTP::Promise::Exception->new({
                        code => 500,
                        message => "Unable to open HTTP message entity body: " . $body->error,
                    }) ) ) if( !$body );
                my $out = $tmpfile->open( '>', { autoflush => 1 } ) ||
                    return( $reject->( HTTP::Promise::Exception->new({
                        code => 500,
                        message => "Unable to open temporary file \"$tmpfile\" in write mode: " . $tmpfile->error,
                    }) ) ) if( !$body );
                while( $io->read( my $buff, 8192 ) )
                {
                    $out->print( $buff ) ||
                    return( $reject->( HTTP::Promise::Exception->new({
                        code => 500,
                        message => "Unable to write to temporary file \"$tmpfile\": " . $out->error,
                    }) ) ) if( !$body );
                }
                $io->close;
                $out->close;
                my $stat = $tmpfile->stat or 
                    return( $reject->( HTTP::Promise::Exception->new({
                        code => 500,
                        message => "Could not stat tmpfile '$tmpfile': " . $tmpfile->error,
                    }) ) );
                my $file_length = $stat->size;
                my( $content_length ) = $response->header( 'Content-length' );

                if( defined( $content_length ) and $file_length < $content_length )
                {
                    $tmpfile->unlink;
                    return( $reject->( HTTP::Promise::Exception->new({
                        code => 500,
                        message => "Transfer truncated: only $file_length out of $content_length bytes received",
                    }) ) );
                }
                elsif( defined( $content_length ) and $file_length > $content_length )
                {
                    $tmpfile->unlink;
                    return( $reject->( HTTP::Promise::Exception->new({
                        code => 500,
                        message => "Content-length mismatch: expected $content_length bytes, got $file_length",
                    }) ) );
                }
                # The file was the expected length.
                else
                {
                    # Replace the stale file with a fresh copy
                    # File::Copy will attempt to do it atomically,
                    # and fall back to a delete + copy if that fails.
                    $file = $tmpfile->move( $file, overwrite => 1 ) || 
                        return( $reject->( HTTP::Promise::Exception->new({
                            code => 500,
                            message => "Cannot copy '$tmpfile' to '$file': $!",
                        }) ) );

                    # Set standard file permissions if umask is supported.
                    # If not, leave what Module::Generic::File created in effect.
                    if( defined( my $umask = umask() ) )
                    {
                        my $mode = 0666 &~ $umask;
                        $file->chmod( $mode ) ||
                            return( $reject->( HTTP::Promise::Exception->new({
                                code => 500,
                                message => sprintf( "Cannot chmod %o '%s': %s", $mode, $file, $file->error ),
                            }) ) );
                    }

                    # make sure the file has the same last modification time
                    if( my $lm = $response->last_modified )
                    {
                        $file->utime( $lm, $lm ) || do
                        {
                            warn( "Warning: cannot update modification time for file '$file': $!\n" ) if( $self->_warnings_is_enabled );
                        };
                    }
                }
            }
            # The local copy is fresh enough, so just delete the temp file
            else
            {
                $tmpfile->unlink;
            }
            return( $resolve->( $response ) );
        }, { ( defined( $self->{serialiser} ) ? ( serialiser => $self->{serialiser} ) : () ) } ) );
    }
    else
    {
        return( $self->error({
            code => 500,
            message => 'Local file name is missing',
        }) ) unless( defined( $file ) && length( $file ) );

        my $request = HTTP::Promise::Request->new( 'GET' => $url ) ||
            return( $self->error({
                code => 500,
                message => HTTP::Promise::Request->error->message
            }) );
        $self->prepare_headers( $request ) || return( $self->pass_error );
        $file = $self->new_file( $file ) || return( $self->pass_error );
        # If the file exists, add a cache-related header
        if( $file->exists )
        {
            # Module::Generic::Finfo->mtime returns a Module::Generic::DateTime object
            my $mtime = $file->mtime;
            if( $mtime )
            {
                my $strtime = $self->_datetime( $mtime ) ||
                    return( $self->pass_error );
                $request->header( 'If-Modified-Since' => $strtime );
            }
        }

        my $tmpfile = $self->new_tempfile;
        $tmpfile->touch || return( $self->pass_error( $tmpfile->error ) );

        my $response = $self->send( $request ) || return( $self->pass_error );

        if( $response->header( 'X-Died' ) )
        {
            $tmpfile->unlink;
            return( $self->error({
                code => 500,
                message => $response->header( 'X-Died' ),
            }) );
        }

        # Only fetching a fresh copy of the file would be considered success.
        # If the file was not modified, "304" would returned, which
        # is considered by HTTP::Status to be a "redirect", /not/ "success"
        if( $response->is_success )
        {
            my $body = $response->entity->body;
            return( $self->error({
                code => 500,
                message => "No body set for this HTTP message entity.",
            }) ) if( !$body );
            my $io = $body->open( '<' ) ||
                return( $self->error({
                    code => 500,
                    message => "Unable to open HTTP message entity body: " . $body->error,
                }) ) if( !$body );
            my $out = $tmpfile->open( '>', { autoflush => 1 } ) ||
                return( $self->error({
                    code => 500,
                    message => "Unable to open temporary file \"$tmpfile\" in write mode: " . $tmpfile->error,
                }) ) if( !$body );
            while( $io->read( my $buff, 8192 ) )
            {
                $out->print( $buff ) ||
                return( $self->error({
                    code => 500,
                    message => "Unable to write to temporary file \"$tmpfile\": " . $out->error,
                }) ) if( !$body );
            }
            $io->close;
            $out->close;
            my $stat = $tmpfile->stat or 
                return( $self->error({
                    code => 500,
                    message => "Could not stat tmpfile '$tmpfile': " . $tmpfile->error,
                }) );
            my $file_length = $stat->size;
            my( $content_length ) = $response->header( 'Content-length' );

            if( defined( $content_length ) and $file_length < $content_length )
            {
                $tmpfile->unlink;
                return( $self->error({
                    code => 500,
                    message => "Transfer truncated: only $file_length out of $content_length bytes received",
                }) );
            }
            elsif( defined( $content_length ) and $file_length > $content_length )
            {
                $tmpfile->unlink;
                return( $self->error({
                    code => 500,
                    message => "Content-length mismatch: expected $content_length bytes, got $file_length",
                }) );
            }
            # The file was the expected length.
            else
            {
                # Replace the stale file with a fresh copy
                # File::Copy will attempt to do it atomically,
                # and fall back to a delete + copy if that fails.
                $file = $tmpfile->move( $file, overwrite => 1 ) || 
                    return( $self->error({
                        code => 500,
                        message => "Cannot copy '$tmpfile' to '$file': $!",
                    }) );

                # Set standard file permissions if umask is supported.
                # If not, leave what Module::Generic::File created in effect.
                if( defined( my $umask = umask() ) )
                {
                    my $mode = 0666 &~ $umask;
                    $file->chmod( $mode ) ||
                        return( $self->error({
                            code => 500,
                            message => sprintf( "Cannot chmod %o '%s': %s", $mode, $file, $file->error ),
                        }) );
                }

                # make sure the file has the same last modification time
                if( my $lm = $response->last_modified )
                {
                    $file->utime( $lm, $lm ) || do
                    {
                        warn( "Warning: cannot update modification time for file '$file': $!\n" ) if( $self->_warnings_is_enabled );
                    };
                }
            }
        }
        # The local copy is fresh enough, so just delete the temp file
        else
        {
            $tmpfile->unlink;
        }
        return( $response );
    }
}

sub new_headers
{
    my $self = shift( @_ );
    $self->_load_class( 'HTTP::Promise::Headers' ) || return( $self->pass_error );
    my $headers = HTTP::Promise::Headers->new( @_ ) ||
        return( $self->pass_error( HTTP::Promise::Headers->error ) );
    return( $headers );
}

# NOTE: request parameter
sub no_proxy { return( shift->_set_get_array_as_object( 'no_proxy', @_ ) ); }

sub options
{
    my $self = shift( @_ );
    if( $self->use_promise )
    {
        my $prom = Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            my $req = $self->_make_request_data( OPTIONS => @_ ) ||
                die( HTTP::Promise::Request->error );
            my $resp = $self->send( $req ) || return( $reject->( $self->error ) );
            return( $resolve->( $resp ) );
        },
        {
            args => [@_],
            ( defined( $self->{serialiser} ) ? ( serialiser => $self->{serialiser} ) : () ),
            ( defined( $self->{medium} ) ? ( medium => $self->{medium} ) : () ),
            ( defined( $self->{shared_mem_size} ) ? ( result_shared_mem_size => $self->{shared_mem_size} ) : () ),
        }) || return( $self->pass_error( Promise::Me->error ) );
        return( $prom );
    }
    else
    {
        my $req = $self->_make_request_data( OPTIONS => @_ ) ||
            return( $self->pass_error( HTTP::Promise::Request->error ) );
        my $resp = $self->send( $req ) ||
            return( $self->pass_error );
        return( $resp );
    }
}

sub patch
{
    my $self = shift( @_ );
    if( $self->use_promise )
    {
        my $prom = Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            my $req = $self->_make_request_data( PATCH => @_ ) ||
                die( HTTP::Promise::Request->error );
            my $resp = $self->send( $req ) || return( $reject->( $self->error ) );
            return( $resolve->( $resp ) );
        },
        {
            args => [@_],
            ( defined( $self->{serialiser} ) ? ( serialiser => $self->{serialiser} ) : () ),
            ( defined( $self->{medium} ) ? ( medium => $self->{medium} ) : () ),
            ( defined( $self->{shared_mem_size} ) ? ( result_shared_mem_size => $self->{shared_mem_size} ) : () ),
        }) || return( $self->pass_error( Promise::Me->error ) );
        return( $prom );
    }
    else
    {
        my $req = $self->_make_request_data( PATCH => @_ ) ||
            return( $self->pass_error( HTTP::Promise::Request->error ) );
        my $resp = $self->send( $req ) ||
            return( $self->pass_error );
        return( $resp );
    }
}

sub post
{
    my $self = shift( @_ );
    if( $self->use_promise )
    {
        my $prom = Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            my $req = $self->_make_request_data( POST => @_ ) ||
                die( HTTP::Promise::Request->error );
            my $resp = $self->send( $req ) || return( $reject->( $self->error ) );
            return( $resolve->( $resp ) );
        },
        {
            args => [@_],
            ( defined( $self->{serialiser} ) ? ( serialiser => $self->{serialiser} ) : () ),
            ( defined( $self->{medium} ) ? ( medium => $self->{medium} ) : () ),
            ( defined( $self->{shared_mem_size} ) ? ( result_shared_mem_size => $self->{shared_mem_size} ) : () ),
        }) || return( $self->pass_error( Promise::Me->error ) );
        return( $prom );
    }
    else
    {
        my $req = $self->_make_request_data( POST => @_ ) ||
            return( $self->pass_error( HTTP::Promise::Request->error ) );
        my $resp = $self->send( $req ) ||
            return( $self->pass_error );
        return( $resp );
    }
}

sub prepare
{
    my $self = shift( @_ );
    my $meth = shift( @_ ) || return( $self->error( "No HTTP method was provided to prepare the request." ) );
    my @args = @_;
    $meth = uc( $meth );
    if( $meth eq 'GET' || $meth eq 'HEAD' )
    {
        return( $self->_make_request_query( $meth, @args ) );
    }
    elsif( $meth eq 'OPTIONS' || $meth eq 'PATCH' || $meth eq 'POST' || $meth eq 'PUT' )
    {
        return( $self->_make_request_data( $meth, @args ) );
    }
    else
    {
        my $req = HTTP::Promise::Request->new( $meth, @args ) ||
            return( $self-pass_error( HTTP::Promise::Request->error ) );
        return( $req );
    }
}

sub prepare_headers
{
    my $self = shift( @_ );
    my $req  = shift( @_ );
    return( $self->error( "Object provided is not an HTTP::Promise::Request object" ) ) if( !$self->_is_a( $req => 'HTTP::Promise::Request' ) );
    my $h = $req->headers;
    return( $self->error( "Request object provided does not have an HTTP::Promise::Headers object set to it!" ) ) if( !$h );
    unless( $req->protocol )
    {
        $req->protocol( $self->default_protocol || 'HTTP/1.1' );
    }
    
    # Set default headers now
    my $default_headers = $self->default_headers;
    $default_headers->scan(sub
    {
        my( $name, $value ) = @_;
        $h->header( $name => $value );
    });
    
    my $ua = $self->agent;
    if( defined( $ua ) && !$h->user_agent )
    {
        $h->user_agent( $ua );
    }
    # e.g.: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8
    if( !$h->accept )
    {
        $h->accept( 'text/html,application/xhtml+xml;q=0.9,*/*;q=0.8' );
    }
    # Accept-Encoding: gzip, deflate, br
    my $ae = $self->accept_encoding;
    if( !$h->accept_encoding && $ae ne 'none' )
    {
        $self->_load_class( 'HTTP::Promise::Stream' ) || return( $self->pass_error );
        my $decodables;
        if( !$ae->is_empty && $ae ne 'all' && $ae ne 'auto' )
        {
            $decodables = HTTP::Promise::Stream->decodable( [split( /[[:blank:]\h]*\,[[:blank:]\h]*/, "$ae" )] );
        }
        else
        {
            $decodables = HTTP::Promise::Stream->decodable( 'browser' );
        }
        $h->accept_encoding( $decodables->join( ',' )->scalar );
    }
    # Accept-Language: fr-FR,en-GB;q=0.8,fr;q=0.6,en;q=0.4,ja;q=0.2
    if( !$h->accept_language && !$self->accept_language->is_empty )
    {
        my $pref = 0.9;
        my $langs = [];
        $self->accept_language->foreach(sub
        {
            push( @$langs, sprintf( '%s;q=%.1f', $_, $pref ) );
            $pref -= 0.1 unless( $pref == 0.1 );
        });
        $h->accept_language( join( ',', @$langs ) );
    }
    my $dnt = $self->dnt;
    if( !defined( $h->dnt ) && defined( $dnt ) )
    {
        $h->dnt( $dnt ? 1 : 0 );
    }
    # Upgrade-Insecure-Requests: 1
    my $upgrade_ssl = $self->auto_switch_https;
    if( $req->uri->scheme eq 'http' && ( !defined( $upgrade_ssl ) || $upgrade_ssl ) )
    {
        $h->upgrade_insecure_requests(1);
    }
    unless( $req->headers->host )
    {
        $req->headers->host( $req->host );
    }
    return( $req );
}

sub proxy { return( shift->_set_get_scalar_as_object( 'proxy', @_ ) ); }

sub proxy_authorization { return( shift->_set_get_scalar_as_object( 'proxy_authorization', @_ ) ); }

sub put
{
    my $self = shift( @_ );
    if( $self->use_promise )
    {
        my $prom = Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            my $req = $self->_make_request_data( PUT => @_ ) ||
                die( HTTP::Promise::Request->error );
            my $resp = $self->send( $req ) || return( $reject->( $self->error ) );
            return( $resolve->( $resp ) );
        },
        {
            args => [@_],
            ( defined( $self->{serialiser} ) ? ( serialiser => $self->{serialiser} ) : () ),
            ( defined( $self->{medium} ) ? ( medium => $self->{medium} ) : () ),
            ( defined( $self->{shared_mem_size} ) ? ( result_shared_mem_size => $self->{shared_mem_size} ) : () ),
        }) || return( $self->pass_error( Promise::Me->error ) );
        return( $prom );
    }
    else
    {
        my $req = $self->_make_request_data( PUT => @_ ) ||
            return( $self->pass_error( HTTP::Promise::Request->error ) );
        my $resp = $self->send( $req ) ||
            return( $self->pass_error );
        return( $resp );
    }
}

sub request
{
    my $self = shift( @_ );
    my $req  = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{read_size} //= 0;
    if( $self->use_promise )
    {
        my $prom = Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            return( $reject->( HTTP::Promise::Exception->new({
                code => 500,
                message => "No request object was provided."
            }) ) ) if( !$req );
            $self->use_content_file( $opts->{use_content_file} ) if( exists( $opts->{use_content_file} ) );
            my $resp = $self->send( $req, $opts ) || return( $reject->( $self->pass_error ) );
            return( $resolve->( $resp ) );
        },
        {
            ( defined( $self->{serialiser} ) ? ( serialiser => $self->{serialiser} ) : () ),
            ( defined( $self->{medium} ) ? ( medium => $self->{medium} ) : () ),
            ( defined( $self->{shared_mem_size} ) ? ( result_shared_mem_size => $self->{shared_mem_size} ) : () ),
        }) || return( $self->pass_error( Promise::Me->error ) );
        return( $prom );
    }
    else
    {
        return( $self->error( "No request object was provided." ) ) if( !$req );
        $self->use_content_file( $opts->{use_content_file} ) if( exists( $opts->{use_content_file} ) );
        my $resp = $self->send( $req, $opts ) || return( $self->pass_error );
        return( $resp );
    }
}

# NOTE: request parameter
sub requests_redirectable { return( shift->_set_get_array_as_object( 'requests_redirectable', @_ ) ); }

sub send
{
    my $self = shift( @_ );
    my $req  = shift( @_ );
    return( $self->error( "Request object provided ($req) is not a HTTP::Promise::Request object." ) ) if( !$self->_is_a( $req => 'HTTP::Promise::Request' ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{expect_threshold} //= $self->expect_threshold // 0;
    $opts->{total_attempts} //= 0;

    my $p = {};
    # my $timeout = time() + $self->timeout;
    my $timeout = $self->timeout;
    my $uri = $req->uri;
    # my ($scheme, $username, $password, $host, $port, $path_query);
    if( !$uri->scheme )
    {
        $uri->scheme( 'http' );
    }
    elsif( $uri->scheme ne 'http' && $uri->scheme ne 'https' )
    {
        return( $self->error( "Unsupported scheme: ", $uri->scheme ) );
    }
    my $default_port = $uri->scheme eq 'http'
        ? 80
        : 443;
    if( !$uri->can( 'port' ) || !defined( $uri->port ) || !length( $uri->port ) )
    {
        $p->{port} = $default_port;
    }
    else
    {
        $p->{port} = $uri->port;
    }
    $uri->path( '/' ) if( !length( $uri->path ) );

    $p->{host} = $uri->host ||
        return( $self->error( "No host set for request uri \"$uri\"." ) );
    
    if( my $local_host = $self->local_host )
    {
        $p->{local_host} = $local_host;
    }
    if( my $local_port = $self->local_port )
    {
        $p->{local_port} = $local_port;
    }
    
    my $proxy = $self->proxy;
    my $no_proxy = $self->no_proxy;
    if( $proxy && $no_proxy )
    {
        if( $self->_match_no_proxy( $no_proxy, $p->{host} ) )
        {
            undef( $proxy );
        }
    }
    
    local $SIG{PIPE} = 'IGNORE';
    my $io;
    my $sock = $self->_pool->steal( @$p{qw( host port )} );
    if( defined( $sock ) && Scalar::Util::openhandle( $sock ) )
    {
        $io = HTTP::Promise::IO->new( $sock, stop_if => $self->stop_if ) ||
            return( $self->pass_error( HTTP::Promise::IO->error ) );
        if( $io->make_select( write => 0, timeout => 0 ) )
        {
            close( $sock );
            undef( $sock );
        }
        else
        {
            $p->{in_keepalive} = 1;
        }
    }
    if( !$p->{in_keepalive} )
    {
        if( $proxy )
        {
            # my( undef, $proxy_user, $proxy_pass, $proxy_host, $proxy_port, undef) = $self->_parse_url($proxy);
            return( $self->error( "Proxy set '$proxy' (", overload::StrVal( $proxy ), ") is not URI object." ) ) if( !$self->_is_a( $proxy => 'URI' ) );
            my $proxy_auth = $proxy->userinfo;
            my( $proxy_user, $proxy_pass ) = split( /:/, $proxy_auth, 2 );
            my $proxy_authorization;
            if( defined( $proxy_user ) && length( $proxy_user ) )
            {
                $self->_load_class( 'URI::Escape::XS' ) || return( $self->pass_error );
                $p->{proxy_user} = URI::Escape::XS::uri_unescape( $proxy_user );
                $p->{proxy_pass} = URI::Escape::XS::uri_unescape( $proxy_pass );
                $self->_load_class( 'Crypt::Misc' ) || return( $self->pass_error );
                $proxy_authorization = 'Basic ' . Crypt::Misc::encode_b64( join( ':', @$p{qw( proxy_user proxy_pass )} ), '' );
            }
            if( $uri->scheme eq 'http' )
            {
                $io = HTTP::Promise::IO->connect(
                    host => $proxy->host,
                    port => $proxy->port,
                    stop_if => $self->stop_if,
                    timeout => $timeout,
                    debug   => $self->debug,
                    ( defined( $p->{local_host} ) ? ( local_host => $p->{local_host} ) : () ),
                    ( defined( $p->{local_port} ) ? ( local_port => $p->{local_port} ) : () ),
                ) || return( HTTP::Promise::IO->pass_error );
                if( defined( $proxy_authorization ) )
                {
                    $self->proxy_authorization( $proxy_authorization );
                }
            }
            else
            {
                $io = HTTP::Promise::IO->connect_ssl_over_proxy(
                    proxy_host  => $proxy->host,
                    proxy_port  => $proxy->port,
                    host        => $p->{host},
                    port        => $p->{port},
                    stop_if     => $self->stop_if,
                    timeout     => $timeout,
                    proxy_authorization => $proxy_authorization,
                    debug       => $self->debug,
                    ( defined( $p->{local_host} ) ? ( local_host => $p->{local_host} ) : () ),
                    ( defined( $p->{local_port} ) ? ( local_port => $p->{local_port} ) : () ),
                ) || return( HTTP::Promise::IO->pass_error );
            }
        }
        else
        {
            if( $uri->scheme eq 'http' )
            {
                $io = HTTP::Promise::IO->connect(
                    host => $uri->host,
                    port => $uri->port,
                    stop_if => $self->stop_if,
                    timeout => $timeout,
                    debug   => $self->debug,
                    ( defined( $p->{local_host} ) ? ( local_host => $p->{local_host} ) : () ),
                    ( defined( $p->{local_port} ) ? ( local_port => $p->{local_port} ) : () ),
                ) || return( HTTP::Promise::IO->pass_error );
            }
            else
            {
                my $ssl_opts = $self->ssl_opts;
                $io = HTTP::Promise::IO->connect_ssl(
                    host => $uri->host,
                    port => $uri->port,
                    stop_if => $self->stop_if,
                    timeout => $timeout,
                    debug   => $self->debug,
                    ( defined( $p->{local_host} ) ? ( local_host => $p->{local_host} ) : () ),
                    ( defined( $p->{local_port} ) ? ( local_port => $p->{local_port} ) : () ),
                    ( ( defined( $ssl_opts ) && scalar( keys( %$ssl_opts ) ) ) ? ( ssl_opts => $ssl_opts ) : () ),
                ) || return( HTTP::Promise::IO->pass_error );
            }
        }
        # return( $self->pass_error ) unless( $io );
    }

    my $total_bytes_sent = 0;
    my $total_bytes_read = 0;

    my $send_body = sub
    {
        my $entity = shift( @_ );
        my $body = $entity->body;
        my $body_len = $body->length;
        my $ct_len = $req->headers->content_length;
        if( $body_len != $ct_len )
        {
            warn( "Content-Length set (${ct_len}) does not match the actual body size (${body_len})\n" ) if( warnings::enabled( ref( $self ) ) );
        }
        
        my $sock = $io->filehandle;
        my $bytes_sent = 0;
        $entity->print_body( $io ) || return( $self->pass_error( $entity->error ) );
        # NOTE: Hmmmm, really not great, but otherwise I would need to change a lot of code
        $bytes_sent = $body->length;
        return( $bytes_sent );
    };

    # write request
    my $method = $req->method;
    my $connection_header = $self->connection_header;
    # If no connection_header value was provided, let's guess it based on the protocol used
    unless( $connection_header )
    {
        if( uc( $method ) eq 'HEAD' )
        {
            $connection_header = 'close';
        }
        elsif( $req->version && $req->version > 1.0 )
        {
            $connection_header = 'keep-alive';
        }
        else
        {
            $connection_header = 'close';
        }
    }
    
    my $cookie_jar = $self->cookie_jar;
    {
        my $headers = $req->headers;
        # Add headers that were provided as parameters
        my $in_headers = $opts->{headers};
        if( $self->_is_array( $in_headers ) )
        {
            for( my $i = 0; $i < @$in_headers; $i += 2 )
            {
                my $name = $in_headers->[$i];
                if( lc( $name ) eq 'connection' )
                {
                    $connection_header = $in_headers->[$i + 1];
                }
                else
                {
                    $headers->push_header( $name => $in_headers->[$i + 1] );
                }
            }
        }
        $headers->header( Connection => $connection_header );
        
        if( my $pa = $self->proxy_authorization )
        {
            $headers->header( 'Proxy-Authorization' => $pa );
        }
        my $userinfo = $uri->userinfo;
        if( defined( $userinfo ) && length( $userinfo ) )
        {
            my( $username, $password ) = split( /:/, $userinfo, 2 );
            $self->_load_class( 'URI::Escape' ) || return( $self->pass_error );
            my $unescape_username = URI::Escape::uri_unescape( $username );
            my $unescape_password = URI::Escape::uri_unescape( $password );
            $self->_load_class( 'Crypt::Misc' ) || return( $self->pass_error );
            my $authorization = 'Basic ' . Crypt::Misc::encode_b64( "${unescape_username}:${unescape_password}" );
            $headers->header( Authorization => 'Basic ' . $authorization );
        }

        # set Cookie header
        if( defined( $cookie_jar ) )
        {
            $cookie_jar->add_request_header( $req ) ||
                return( $self->pass_error( $cookie_jar->error ) );
        }

        my $body = $req->entity->body;
        if( defined( $body ) && $body )
        {
            if( $body->isa( 'HTTP::Promise::Body::Form' ) && 
                ( !$headers->exists( 'Content-Type' ) || $headers->content_type->is_empty ) )
            {
                $headers->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
            }
            if( !$headers->exists( 'Content-Length' ) )
            {
                my $content_length = $body->length;
                $headers->header( 'Content-Length' => "$content_length" );
            }
        }

        # finally, set Host header
        unless( $headers->host )
        {
            my $request_target = ( $uri->port == $default_port ) ? $uri->host : $uri->host_port;
            $headers->header( Host => $request_target );
        }
        
        my $expect_threshold = $opts->{expect_threshold} // $self->expect_threshold;
        if( defined( $expect_threshold ) )
        {
            if( $self->_is_integer( $expect_threshold ) )
            {
                $expect_threshold += 0;
            }
            else
            {
                undef( $expect_threshold );
            }
        }
        
        if( $req->version && 
            $req->version > 1.0 && 
            defined( $expect_threshold ) && 
            defined( $body ) &&
            $body->length > $expect_threshold )
        {
            $headers->expect( '100-Continue' );
        }
        
        my $request = $req->start_line . $CRLF . $req->headers->as_string;
        $request .= $CRLF;
        my $bytes = $io->write_all( $request, $timeout );
        if( !defined( $bytes ) )
        {
            return( $self->pass_error( $io->error ) );
        }
        # Could not transmit the headers
        elsif( !$bytes )
        {
            return( $self->error({ code => 500, message => "Zero byte could actually be sent to the socket '", $io->filehandle, "'." }) );
        }
        $total_bytes_sent = $bytes;

        # If this is not an Expect query, we send the body now
        # otherwise if this is an Expect type of query, we would read the response header
        # and send the body
        if( !$headers->expect && defined( $body ) && $body )
        {
            my $bytes = $send_body->( $req->entity );
            return( $self->pass_error ) if( !defined( $bytes ) );
            $total_bytes_sent += $bytes;
        }
    }
    
    # read response
    my $buff = '';
    my $parser = HTTP::Promise::Parser->new;
    my $bufsize = $self->buffer_size;
    $io->max_read_buffer( $bufsize );
    $io->debug( $self->debug );
    
    # Maximum headers size is not oficial, but we definitely need to set some limit.
    # <https://security.stackexchange.com/questions/110565/large-over-sizesd-http-header-lengths-and-security-implications>
    my $max = $self->max_headers_size;
    my( $n, $def, $headers );
    $n = -1;
    LOOP: while(1)
    {
        $n = $io->read( $buff, 2048, length( $buff ) );
        if( !defined( $n ) || $n == 0 )
        {
            my $code = defined( $n ) ? '' : $io->error->code;
            if( $p->{in_keepalive} && 
                ( length( $buff ) // 0 ) == 0 &&
                !$opts->{total_attempts} &&
                ( defined( $n ) || $code == ECONNRESET || ( $IS_WIN32 && $code == ECONNABORTED ) ) )
            {
                # the server closed the connection (maybe because of keep-alive timeout)
                $opts->{total_attempts}++;
                return( $self->send( $req, %$opts ) );
            }
            elsif( !length( $buff ) )
            {
                return( $self->error({ code => HTTP_BAD_REQUEST, message => "Unexpected EOF while reading response from socket '", $io->filehandle, "'." }) );
            }
            elsif( !defined( $n ) )
            {
                return( $self->pass_error( $io->error ) );
            }
            else
            {
                return( $self->error({ code => HTTP_BAD_REQUEST, message => "No headers data could be retrieved in the first " . length( $buff ) . " bytes of data read." }) );
            }
        }
        
        $def = $parser->parse_response_headers( \$buff );
        if( !defined( $def ) )
        {
            # Is it an error 425 Too Early, it means we need more data.
            if( $parser->error->code == HTTP_TOO_EARLY )
            {
                next LOOP;
            }
            # 400 Bad request
            elsif( $parser->error->code == HTTP_BAD_REQUEST && length( $buff ) > $max )
            {
                return( $self->error({ code => HTTP_BAD_REQUEST, message => "Unable to find the response headers, within the first ${max} bytes of data. Do you need to increase the value for max_headers_size() ?" }) );
            }
            # For other errors, we stop and pass the error received
            return( $self->pass_error );
        }
        else
        {
            $headers = $def->{headers} ||
                return( $self->error( "No headers object set by \$parser->parse_headers_xs() !" ) );
            return( $self->error( "\$parser->parse_headers_xs() did not return the headers length as an integer ($def->{length})" ) ) if( !$self->_is_integer( $def->{length} ) );
            return( $self->error( "Headers length returned by \$parser->parse_headers_xs() ($def->{length}) is higher than our buffer size (", length( $buff ), ") !" ) ) if( $def->{length} > length( $buff ) );
            # succeeded
            substr( $buff, 0, $def->{length}, '' );
            $total_bytes_read += $def->{length};
            $io->unread( $buff ) if( length( $buff ) );
            # We need to consume the blank line separating the headers and the body, so it does 
            # not become part of the body, and because it does not belong anywhere
            my $trash = $io->read_until_in_memory( qr/${CRLF}/, include => 1 );
            return( $self->pass_error( $io->error ) ) if( !defined( $trash ) );
            if( $req->headers->exists( 'Expect' ) )
            {
                # If we initially sent an Expect request, i.e. without a body, we just got
                # The green light to proceed, so we remove the Expect: 100-Continue header and re-submit.
                # If we did not have that request header, we just read on as this is the final, albeit weird, response
                if( $def->{code} == HTTP_CONTINUE )
                {
                    # Read on to get the actual server response headers
                    my $bytes = $send_body->( $req->entity );
                    return( $self->pass_error ) if( !defined( $bytes ) );
                    $total_bytes_sent += $bytes;
                    # moving on to read the full response headers
                    # Something like this:
                    # HTTP/1.1 100 Continue
                    # 
                    # HTTP/1.1 200 OK
                    # Content-Type: text/plain
                    # Content-Length: 15
                    # Host: example.com
                    # User-Agent: hoge
                    # 
                    next LOOP;
                }
                # If this is a HTTP/1.0 protocol (but not limited to), this just means the server did not support 
                # the Expect: 100-Continue header, so we just remove it and re-submit.
                elsif( $def->{code} == HTTP_EXPECTATION_FAILED )
                {
                    $req->headers->remove( 'Expect' );
                    # Disable the Expect feature
                    $opts->{expect_threshold} = 0;
                    return( $self->send( $req, $opts ) );
                }
            }
            last LOOP;
        }
    }

    my $ent = HTTP::Promise::Entity->new(
        headers => $headers,
        ext_vary => $self->ext_vary,
        debug => $self->debug,
        ( ( $headers->exists( 'Content-Encoding' ) && !$headers->content_encoding->is_empty ) ? ( is_encoded => 1 ) : () ),
    );
    $self->_load_class( 'HTTP::Promise::Response' ) || return( $self->pass_error );
    my $resp = HTTP::Promise::Response->new( @$def{qw( code status headers )}, {
        protocol => $def->{protocol},
        version => $def->{version},
        debug => $self->debug,
    } ) || return( $self->pass_error( HTTP::Promise::Response->error ) );
    # Mutual assignment for convenience
    $resp->entity( $ent );
    $ent->http_message( $resp );
    $resp->request( $req );
    my $body;
    
    my $max_redirect = 0;
    my $do_redirect = undef;
    if( $headers->exists( 'Location' ) )
    {
        $max_redirect = ( defined( $opts->{max_redirect} ) && $opts->{max_redirect} =~ /^\d+$/ )
            ? $opts->{max_redirect}
            : $self->max_redirect;
        $max_redirect //= 0;
        # Perform redirect for:
        # Moved Permanently (301),
        # Moved Temporarily (302)
        # See Other (303)
        # Temporary Redirect (307)
        # Permanent Redirect (308)
        $do_redirect = ( $max_redirect && $def->{code} =~ /^30[12378]$/ );
    }

    my $chunked = ( ( $headers->transfer_encoding // '' ) eq 'chunked' );
    my $content_length = $headers->content_length;
    if( defined( $content_length ) && 
        length( $content_length ) && 
        $content_length !~ /^\d+$/ )
    {
        # return( $self->error({ code => 500, message => "Bad Content-Length: ${content_length}" }) );
        warn( "Bad Content-Length '${content_length}' in server response.\n" ) if( $self->_warnings_is_enabled );
        undef( $content_length );
    }

    unless( $req->method eq 'HEAD'
            || ( $def->{code} >= 100 && $def->{code} < 200 )
            || $def->{code} == 204
            || $def->{code} == 302
            || $def->{code} == 304 )
    {
        if( $chunked )
        {
            $body = $self->_read_body_chunked(
                reader => $io,
                headers => $headers,
                entity => $ent,
            );
        }
        else
        {
            $body = $self->_read_body(
                reader => $io,
                headers => $headers,
                entity => $ent,
            );
        }
        return( $self->pass_error ) if( !defined( $body ) );
        $total_bytes_read += $body->length;
        $ent->body( $body );
    }

    # manage connection cache (i.e. keep-alive)
    if( defined( $connection_header ) && 
        lc( $connection_header ) eq 'keep-alive' )
    {
        my $connection = $headers->connection->lc;
        if( ( $def->{version} > 1.0
             ? $connection ne 'close'      # HTTP/1.1 can keep alive by default
             : $connection eq 'keep-alive' # HTTP/1.0 needs explicit keep-alive
            ) && ( defined( $content_length ) or $chunked ) )
        {
            my $sock = $io->filehandle;
            $self->_pool->push( $uri->host, $uri->port, $sock ) ||
                return( $self->pass_error );
        }
    }
    # explicitly close here, just after returning the socket to the pool,
    # since it might be reused in the upcoming recursive call
    # undef( $sock );
    $io->close;

    # Process 'Set-Cookie' header before redirect, because Cookies may have been set upon redirection.
    if( defined( $cookie_jar ) )
    {
        $cookie_jar->add_response_header( $resp ) ||
            return( $self->pass_error( $cookie_jar->error ) );
    }
    
    if( $do_redirect )
    {
        my $location = $headers->location;
        unless( $location =~ m{^[a-zA-Z][a-zA-Z0-9]+://} )
        {
            # RFC 2616 14.30 says Location header is absolute URI.
            # But, a lot of servers return relative URI.
            $location = URI->new_abs( $location => $uri );
        }
        # Note: RFC 1945 and RFC 2068 specify that the client is not allowed
        # to change the method on the redirected request. However, most
        # existing user agent implementations treat 302 as if it were a 303
        # response, performing a GET on the Location field-value regardless
        # of the original request method. The status codes 303 and 307 have
        # been added for servers that wish to make unambiguously clear which
        # kind of reaction is expected of the client. Also, 308 was introduced
        # to avoid the ambiguity of 301.
        # TODO: Create new object and add the old one as previous() to the new request.
        my $clone = $req->clone || return( $self->pass_error( $req->error ) );
        unless( $def->{code} =~ /^30[178]$/ )
        {
            $clone->method( 'GET' );
        }
        $clone->uri( $location );
        $max_redirect-- if( $max_redirect > 0 );
        $opts->{max_redirect} = $max_redirect;
        return( $self->send( $clone, $opts ) );
        my $resp2 = $self->send( $clone, $opts ) ||
            return( $self->pass_error );
        $resp2->previous( $resp );
        return( $resp2 );
    }

    my $type = $ent->mime_type;
    # I we have a body at and it is a multipart, we parse it otherwise, we already have it stored
    if( $ent->body && $type =~ m,^multipart/,i )
    {
        # Now parse the raw data saved earlier
        my $fh = $ent->body->open( '+<', { binmode => 'raw' } ) ||
            return( $self->pass_error( $ent->body->error ) );
        my $reader = HTTP::Promise::IO->new( $fh, max_read_buffer => $bufsize, debug => $self->debug ) ||
            return( $self->pass_error( HTTP::Promise::IO->error ) );
        my $ent2 = HTTP::Promise::Entity->new( headers => $headers, http_message => $resp, debug => $self->debug ) ||
            return( $self->pass_error( HTTP::Promise::Entity->error ) );
        $resp->entity( $ent2 );
    
        # Request body can be one of 3 types:
        # application/x-www-form-urlencoded
        # multipart/form-data
        # text/plain or other mime types
        # <https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST>
        my $part_ent = $parser->parse_multi_part( entity => $ent2, reader => $reader ) ||
            return( $parser->pass_error );
    }
    
    return( $resp );
}

# NOTE: request parameter
sub send_te { return( shift->_set_get_boolean( 'send_te', @_ ) ); }

# NOTE: serialiser method for Promise::Me
sub serialiser { return( shift->_set_get_scalar( 'serialiser', @_ ) ); }

# NOTE: shared_mem_size method for Promise::Me
sub shared_mem_size { return( shift->_set_get_scalar( 'shared_mem_size', @_ ) ); }

sub simple_request
{
    my $self = shift( @_ );
    my $req  = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{read_size} //= 0;
    if( $self->use_promise )
    {
        return( Promise::Me->new(sub
        {
            my( $resolve, $reject ) = @$_;
            return( $reject->( HTTP::Promise::Exception->new({
                code => 500,
                message => "No request object was provided."
            }) ) ) if( !$req );
            $self->use_content_file( $opts->{use_content_file} ) if( exists( $opts->{use_content_file} ) );
            $opts->{max_redirect} = 0;
            my $resp = $self->send( $req, $opts ) || return( $reject->( $self->pass_error ) );
            return( $resolve->( $resp ) );
        }) );
    }
    else
    {
        return( $self->error( "No request object was provided." ) ) if( !$req );
        $self->use_content_file( $opts->{use_content_file} ) if( exists( $opts->{use_content_file} ) );
        $opts->{max_redirect} = 0;
        my $resp = $self->send( $req, $opts ) || return( $self->pass_error );
        return( $resp );
    }
}

sub ssl_opts { return( shift->_set_get_hash_as_mix_object( 'ssl_opts', @_ ) ); }

sub stop_if { return( shift->_set_get_code( 'stop_if', @_ ) ); }

sub threshold { return( shift->_set_get_scalar( 'threshold', @_ ) ); }

# NOTE: request parameter
sub timeout { return( shift->_set_get_number( 'timeout', @_ ) ); }

# NOTE: upgrade_insecure_requestsis an alias for auto_switch_https
sub upgrade_insecure_requests { return( shift->_set_get_boolean( 'auto_switch_https', @_ ) ); }

sub uri_escape { return( URI::Escape::XS::uri_escape( $_[1] ) ); }

sub uri_unescape { return( URI::Escape::XS::uri_unescape( $_[1] ) ); }

sub use_content_file { return( shift->_set_get_boolean( 'use_content_file', @_ ) ); }

sub use_promise { return( shift->_set_get_boolean( 'use_promise', @_ ) ); }

sub _datetime
{
    my $self = shift( @_ );
    my $dt;
    if( @_ )
    {
        return( $self->error( "Object provided (", ref( $_[0] ), ") is not a DateTime or Module::Generic::DateTime object." ) ) if( !$self->_is_a( $_[0] => [qw( DateTime Module::Generic::DateTime )] ) );
        $dt = shift( @_ );
    }
    
    if( !defined( $dt ) )
    {
        $dt = DateTime->now;
    }
    # We need to get the underlying DateTime object if it is wrapped inside Module::Generic::DateTime
    elsif( $dt->isa( 'Module::Generic::DateTime' ) )
    {
        $dt = $dt->datetime;
    }
    
    $dt->set_time_zone( 'GMT' );
    my $fmt = DateTime::Format::Strptime->new(
        pattern => '%a, %d %b %Y %H:%M:%S GMT',
        locale  => 'en_GB',
        time_zone => 'GMT',
    );
    $dt->set_formatter( $fmt );
    return( $dt );
}

# my $res = $prom->_make_request_data( $form_object );
# my $res = $prom->_make_request_data( $form_data_object );
# my $res = $prom->_make_request_data( 'post' => $url, \%form );
# my $res = $prom->_make_request_data( 'post' => $url, \%form );
# my $res = $prom->_make_request_data( 'post' => $url, \@form );
# my $res = $prom->_make_request_data( 'post' => $url, \%form, $field_name => $value, ... );
# my $res = $prom->_make_request_data( 'post' => $url, $field_name => $value, Content => \%form, Query => $escaped_string );
# my $res = $prom->_make_request_data( 'post' => $url, $field_name => $value, Content => \@form, Query => $escaped_string );
# my $res = $prom->_make_request_data( 'post' => $url, $field_name => $value, Content => $content, Query => $escaped_string );
sub _make_request_data
{
    my $self = shift( @_ );
    my $meth = shift( @_ ) || return( $self->error( 'No http method was provided.' ) );
    my $uri  = shift( @_ ) || return( $self->error( 'No uri was provided.' ) );
    my $req = HTTP::Promise::Request->new( $meth => $uri, { debug => $self->debug } ) ||
        return( $self->pass_error( HTTP::Promise::Request->error ) );
    $self->prepare_headers( $req );
    # To set up a possible escaped query string for this POST/PUT request
    my $u = $req->uri || 
        return( $self->error( "No URL was provided for this HTTP query." ) );
    my $ent = $req->entity;
    my $content;
    if( scalar( @_ ) == 1 && 
        defined( $_[0] ) && 
        ref( $_[0] ) eq 'HASH' &&
        CORE::exists( $_[0]->{Content} ) )
    {
        warn( "It seems you are passing an hash reference of parameters, but this should be avoided as it may be confused with an hash reference of form parameters." ) if( $self->_is_warnings_enabled );
    }

    # Maybe content is provided as the first argument?
    if( scalar( @_ ) && defined( $_[0] ) && 
        (
            $self->_is_array( $_[0] ) || 
            ( ref( $_[0] ) eq 'HASH' && !scalar( grep( /^Content$/i, @_ ) ) ) || 
            $self->_is_a( $_[0] => 'HTTP::Promise::Body::Form' ) ||
            $self->_is_a( $_[0] => 'HTTP::Promise::Body::Form::Data' )
        ) )
    {
        $content = shift( @_ );
    }
    # Maybe content is provided as the last argument?
    elsif( scalar( @_ ) && 
           ( @_ % 2 ) &&
           defined( $_[-1] ) &&
           (
               $self->_is_array( $_[-1] ) || 
               ( ref( $_[-1] ) eq 'HASH' && !scalar( grep( /^Content$/i, @_ ) ) ) || 
               $self->_is_a( $_[-1] => 'HTTP::Promise::Body::Form' ) ||
               $self->_is_a( $_[-1] => 'HTTP::Promise::Body::Form::Data' )
           ) )
    {
        $content = pop( @_ );
    }
    
    my( $k, $v );
    while( ( $k, $v ) = splice( @_, 0, 2 ) )
    {
        if( lc( $k ) eq 'content' )
        {
            $content = $v;
        }
        # Handle possible escaped query string for this POST/PUT request
        elsif( lc( $k ) eq 'query' )
        {
            if( ref( $v ) eq 'HASH' || $self->_is_array( $v ) )
            {
                # try-catch
                local $@;
                eval
                {
                    $u->query_form( $v );
                };
                if( $@ )
                {
                    return( $self->error( "Error while setting query form key-value pairs: $@" ) );
                }
            }
            elsif( !ref( $v ) || ( ref( $v ) && overload::Method( $v => '""' ) ) )
            {
                $u->query( "$v" );
            }
        }
        else
        {
            # $req->headers->push_header( $k, $v );
            $req->headers->replace( $k, $v );
        }
    }
    my $orig_ct = $req->headers->header( 'Content-Type' );
    my $ct = $orig_ct;
    my( $obj, $type );
    # By default
    if( !$ct && defined( $content ) )
    {
        $ct = 'application/x-www-form-urlencoded';
    }
    elsif( $ct && $ct eq 'form-data' )
    {
        $ct = 'multipart/form-data';
    }

    if( defined( $ct ) && length( "$ct" ) )
    {
        $obj = $req->headers->new_field( 'Content-Type' => "$ct" );
        return( $self->pass_error( $req->headers->error ) ) if( !defined( $obj ) );
        $type = $obj->type;
    }
    
    # $content can be an array reference, hash reference, an HTTP::Promise::Body::Form object, or an HTTP::Promise::Body::Form::Data object
    if( ref( $content ) )
    {
        # if( $ct =~ m,^multipart/form-data[[:blank:]\h]*(;|$),i )
        if( lc( substr( "$type", 0, 19 ) ) eq 'multipart/form-data' )
        {
            unless( $obj->boundary )
            {
                $obj->boundary( $req->make_boundary );
            }
            # HTTP::Promise::Body::Form::Data inherits from HTTP::Promise::Body::Form, so we do it first
            if( $self->_is_a( $content => 'HTTP::Promise::Body::Form::Data' ) )
            {
                my $parts = $content->make_parts ||
                    return( $self->pass_error( $content->error ) );
                $ent->parts( $parts );
            }
            if( $self->_is_a( $content => 'HTTP::Promise::Body::Form' ) )
            {
                my $form = $content->as_form_data ||
                    return( $self->pass_error( $content->error ) );
                my $parts = $form->make_parts ||
                    return( $self->pass_error( $form->error ) );
                $ent->parts( $parts );
            }
            elsif( $self->_is_array( $content ) )
            {
                # Keep track of the order of the fields
                my $fields = [];
                for( my $i = 0; $i < scalar( @$content ); $i += 2 )
                {
                    push( @$fields, $content->[$i] );
                }
                $self->_load_class( 'HTTP::Promise::Body::Form::Data' ) ||
                    return( $self->pass_error );
                my $form = HTTP::Promise::Body::Form::Data->new( @$content ) ||
                    return( $self->pass_error( HTTP::Promise::Body::Form::Data->error ) );
                my $parts = $form->make_parts( fields => $fields ) ||
                    return( $self->pass_error( $form->error ) );
                $ent->parts( $parts );
            }
            elsif( ref( $content ) eq 'HASH' )
            {
                $self->_load_class( 'HTTP::Promise::Body::Form::Data' ) ||
                    return( $self->pass_error );
                my $form = HTTP::Promise::Body::Form::Data->new( $content ) ||
                    return( $self->pass_error( HTTP::Promise::Body::Form::Data->error ) );
                my $parts = $form->make_parts ||
                    return( $self->pass_error( $form->error ) );
                $ent->parts( $parts );
            }
            else
            {
                return( $self->error( "Unsupported content of type '", ref( $content ), "'" ) );
            }
        }
        elsif( lc( $type ) eq TYPE_URL_ENCODED &&
               (
                   Scalar::Util::reftype( $content ) eq 'ARRAY' ||
                   ref( $content ) eq 'HASH' ||
                   $self->_is_a( $content => 'HTTP::Promise::Body::Form' )
               ) )
        {
            my $form;
            if( $self->_is_a( $content => 'HTTP::Promise::Body::Form' ) )
            {
                $form = $content;
            }
            else
            {
                my $reftype = Scalar::Util::reftype( $content );
                $self->_load_class( 'HTTP::Promise::Body::Form' ) ||
                    return( $self->pass_error );
                $form = HTTP::Promise::Body::Form->new( ( $reftype eq 'ARRAY' && !$self->_can_overload( $content => '""' ) ) ? @$content : $content ) ||
                    return( $self->pass_error( HTTP::Promise::Body::Form->error ) );
            }
            $ent->body( $form );
        }
        elsif( $self->_is_a( $content => 'HTTP::Promise::Body' ) )
        {
            $ent->body( $content );
        }
        # Module::Generic::File has stringification overloaded, so we put it here first
        elsif( $self->_is_a( $content => 'Module::Generic::File' ) )
        {
            my $body = $ent->new_body( file => $content ) ||
                return( $self->pass_error( $ent->error ) );
            $ent->body( $body );
        }
        elsif( overload::Method( $content => '""' ) )
        {
            my $body = $ent->new_body( string => "$content" ) ||
                return( $self->pass_error( $ent->error ) );
            $ent->body( $body );
        }
        else
        {
            return( $self->error( "Unsupported Content-Type: $ct for data type '", ref( $content ), "'" ) );
        }
    }
    # $content is not a reference and is not empty
    elsif( defined( $content ) && length( $content ) )
    {
        my $body = $ent->new_body( string => $content ) ||
            return( $self->pass_error( $ent->error ) );
        $ent->body( $body );
    }

    # Set Content-Type if needed
    $req->headers->content_type( "$obj" ) if( defined( $obj ) && !$orig_ct );
    if( defined( $content ) )
    {
        # Make sure the content is encoded, if applicable, so we can get the proper content length.
        if( my $encodings = $req->headers->content_encoding )
        {
            $ent->encode_body( $encodings ) if( !$ent->is_encoded );
        }
        $req->content_length( $ent->body->length );
    }
    # Set the Content-Length to 0 only if there is a Content-Type set
    elsif( $ct )
    {
        $req->header( 'Content-Length' => 0 );
    }
    return( $req );
}

sub _make_request_query
{
    my $self = shift( @_ );
    my $meth = shift( @_ ) || return( $self->error( 'No http method was provided.' ) );
    my $uri  = shift( @_ ) || return( $self->error( 'No uri was provided.' ) );
    my $req = HTTP::Promise::Request->new( $meth => $uri, { debug => $self->debug } ) ||
        return( $self->pass_error( HTTP::Promise::Request->error ) );
    $self->prepare_headers( $req );
    my $u = $req->uri || 
        return( $self->error( "No URL was provided for this HTTP query." ) );
    my( $k, $v );
    while( ( $k, $v ) = ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) ? each( %{$_[0]} ) : splice( @_, 0, 2 ) )
    {
        if( lc( $k ) eq 'content' || lc( $k ) eq 'query' )
        {
            if( ref( $v ) eq 'HASH' || $self->_is_array( $v ) )
            {
                # try-catch
                local $@;
                eval
                {
                    $u->query_form( $v );
                };
                if( $@ )
                {
                    return( $self->error( "Error while setting query form key-value pairs: $@" ) );
                }
            }
            elsif( !ref( $v ) || ( ref( $v ) && overload::Method( $v => '""' ) ) )
            {
                $u->query( "$v" );
            }
            else
            {
                warn( "Option \"$k\" was provided, but no content data (", overload::StrVal( $v ), ") is allowed for this type of HTTP query. Ignoring it.\n" ) if( $self->_warnings_is_enabled );
            }
        }
        else
        {
            # $req->headers->push_header( $k, $v );
            $req->headers->replace( $k, $v );
        }
    }
    return( $req );
}

sub _match_no_proxy
{
    my( $self, $no_proxy, $host ) = @_;

    # ref. curl.1.
    #   list of host names that shouldn't go through any proxy.
    #   If set to a asterisk '*' only, it matches all hosts.
    if( $no_proxy eq '*'  )
    {
        return(1);
    }
    elsif( $self->_is_array( $no_proxy ) )
    {
        for my $pat ( @$no_proxy )
        {
            # suffix match (same behavior as LWP)
            if( $host =~ /\Q$pat\E$/ )
            {
                return(1);
            }
        }
    }
    return(0);
}

sub _pool { return( shift->_set_get_object( '_pool', 'HTTP::Promise::Pool', @_ ) ); }

# The purpose of this method is to read the entire HTPP message body, whatever that is, i.e. multipart o not
# Parsing and decoding is done after data has been read from the socket, because speed matters.
sub _read_body
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $timeout = $opts->{timeout} // $self->timeout;
    my $headers = $opts->{headers};
    return( $self->error( "Headers object provided is not a HTTP::Promise::Headers object." ) ) if( !$self->_is_a( $headers => 'HTTP::Promise::Headers' ) );
    my $ent = $opts->{entity};
    return( $self->error( "Entity object provided is not a HTTP::Promise::Entity object." ) ) if( !$self->_is_a( $ent => 'HTTP::Promise::Entity' ) );
    my $reader = $opts->{reader};
    return( $self->error( "Reader object provided is not a HTTP::Promise::IO object." ) ) if( !$self->_is_a( $reader => 'HTTP::Promise::IO' ) );
    my $bufsize = $self->buffer_size;

    my $type = $headers->type;
    my $max_in_memory = $self->max_body_in_memory_size;
    # rfc7231, section 3.1.1.5 says we can assume applicatin/octet-stream if there
    # is no Content-Type header
    # <https://tools.ietf.org/html/rfc7231#section-3.1.1.5>
    my $default_mime = $DEFAULT_MIME_TYPE || 'application/octet-stream';
    my $len = $headers->content_length;
    my $chunk_size = $self->buffer_size;
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
    
    if( defined( $len ) )
    {
        # Too big, saving it to file; or
        # use_content_file is set to true.
        if( ( $len > $max_in_memory ) || $self->use_content_file )
        {
            $file = $get_temp_file->() || return( $self->pass_error );
            my $io = $file->open( '+>', { binmode => 'raw', autoflush => 1 } ) || 
                return( $self->pass_error( $file->error ) );
            my $buff = '';
            my $bytes;
            $chunk_size = $len if( $chunk_size > $len );
            while( $bytes = $reader->read( $buff, $chunk_size ) )
            {
                my $bytes_out = $io->syswrite( $buff );
                return( $self->pass_error( $io->error ) ) if( !defined( $bytes_out ) );
                # We do not want to read more than we should
                $chunk_size = ( $len - $total_bytes ) if( ( $total_bytes < $len ) && ( ( $total_bytes + $chunk_size ) > $len ) );
                $total_bytes += $bytes;
                last if( $total_bytes == $len );
            }
            $io->close;
            return( $self->error( "Error reading http body from socket: ", $reader->error ) ) if( !defined( $bytes ) );
        }
        else
        {
            my $buff = '';
            my $bytes;
            $chunk_size = $len if( $chunk_size > $len );
            while( $bytes = $reader->read( $buff, $chunk_size ) )
            {
                $data .= $buff;
                # We do not want to read more than we should
                $chunk_size = ( $len - $total_bytes ) if( ( $total_bytes < $len ) && ( ( $total_bytes + $chunk_size ) > $len ) );
                $total_bytes += $bytes;
                last if( $total_bytes == $len );
            }
            return( $self->error( "Error reading HTTP body from socket: ", $reader->error ) ) if( !defined( $bytes ) );
        }
        warn( "HTTP::Promise: HTTP body size advertised ($len) does not match the size actually read from socket ($total_bytes)\n" ) if( $total_bytes != $len && $self->_warnings_is_enabled );
    }
    # No Content-Length defined
    else
    {
        my $buff = '';
        my $bytes = -1;
        my $io;
        while( $bytes )
        {
            $bytes = $reader->read( $buff, $chunk_size );
            return( $self->pass_error( $reader->error ) ) if( !defined( $bytes ) );
            
            if( defined( $io ) )
            {
                my $bytes_out = $io->syswrite( $buff );
                return( $self->pass_error( $io->error ) ) if( !defined( $bytes_out ) );
            }
            # The cumulative bytes total for this part exceeds the allowed maximum in memory
            elsif( ( length( $data ) + length( $buff ) ) > $max_in_memory )
            {
                $file = $get_temp_file->() || return( $self->pass_error );
                $io = $file->open( '+>', { binmode => 'raw', autoflush => 1 } ) ||
                    return( $self->pass_error( $file->error ) );
                my $bytes_out = $io->syswrite( $data );
                return( $self->pass_error( $io->error ) ) if( !defined( $bytes_out ) );
                $bytes_out = $io->syswrite( $buff );
                return( $self->pass_error( $io->error ) ) if( !defined( $bytes_out ) );
                $data = '';
            }
            else
            {
                $data .= $buff;
            }
        }
        $total_bytes = defined( $file ) ? $file->length : length( $data );
    }

    # If we used a file and the extension is 'dat', because we were clueless based on 
    # the provided Content-Type, or maybe even the Content-Type is absent, we use the 
    # XS module in HTTP::Promise::MIME to guess the mime-type based on the actual file
    # content
    if( defined( $file ) )
    {
        if( $mime_type eq $default_mime )
        {
            unless( $mime )
            {
                $self->_load_class( 'HTTP::Promise::MIME' ) || return( $self->pass_error );
                $mime = HTTP::Promise::MIME->new;
            }
            
            # Guess the mime type from the file magic
            my $mtype = $mime->mime_type( $file );
            return( $self->pass_error( $mime->error ) ) if( !defined( $mime_type ) );
            my( $enc, $enc_ext );
            if( $self->ext_vary && ( $enc = $headers->content_encoding ) )
            {
                $self->_load_class( 'HTTP::Promise::Stream' ) || return( $self->pass_error );
                my $enc_exts = HTTP::Promise::Stream->encoding2suffix( $enc ) ||
                    return( $self->pass_error( HTTP::Promise::Stream->error ) );
                $enc_ext = $enc_exts->join( '.' )->scalar if( !$enc_exts->is_empty );
                # Mark body as being encoded if necessary
                $ent->is_encoded(1);
            }
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
                    $new_ext .= ".${enc_ext}" if( defined( $enc_ext ) );
                    my $new_file = $file->extension( $new_ext ) || return( $self->pass_error( $file->error ) );
                    my $this_file = $file->move( $new_file ) || return( $self->pass_error( $file->error ) );
                    $file = $this_file;
                }
            }
            elsif( defined( $enc_ext ) )
            {
                my $old_ext = $file->extension;
                $old_ext .= ".${enc_ext}";
                my $new_file = $file->extension( $old_ext ) || return( $self->pass_error( $file->error ) );
                my $this_file = $file->move( $new_file ) || return( $self->pass_error( $file->error ) );
                $file = $this_file;
            }
        }
        else
        {
            my( $enc );
            if( $self->ext_vary && ( $enc = $headers->content_encoding ) )
            {
                $self->_load_class( 'HTTP::Promise::Stream' ) || return( $self->pass_error );
                my $old_ext = $file->extension;
                my $enc_exts = HTTP::Promise::Stream->encoding2suffix( $enc ) ||
                    return( $self->pass_error( HTTP::Promise::Stream->error ) );
                if( !$enc_exts->is_empty )
                {
                    $old_ext .= '.' . $enc_exts->join( '.' )->scalar;
                    my $new_file = $file->extension( $old_ext ) || return( $self->pass_error( $file->error ) );
                    my $this_file = $file->move( $new_file ) || return( $self->pass_error( $file->error ) );
                    $file = $this_file;
                }
                # Mark body as being encoded if necessary
                $ent->is_encoded(1);
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
        if( $type eq TYPE_URL_ENCODED )
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
    return( $body );
}

sub _read_body_chunked
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $timeout = $opts->{timeout} // $self->timeout;
    my $headers = $opts->{headers};
    return( $self->error( "Headers object provided is not a HTTP::Promise::Headers object." ) ) if( !$self->_is_a( $headers => 'HTTP::Promise::Headers' ) );
    my $ent = $opts->{entity};
    return( $self->error( "Entity object provided is not a HTTP::Promise::Entity object." ) ) if( !$self->_is_a( $ent => 'HTTP::Promise::Entity' ) );
    my $reader = $opts->{reader};
    return( $self->error( "Reader object provided is not a HTTP::Promise::IO object." ) ) if( !$self->_is_a( $reader => 'HTTP::Promise::IO' ) );
    my $bufsize = $self->buffer_size;
    # rfc7231, section 3.1.1.5 says we can assume applicatin/octet-stream if there
    # is no Content-Type header
    # <https://tools.ietf.org/html/rfc7231#section-3.1.1.5>
    my $default_mime = $DEFAULT_MIME_TYPE || 'application/octet-stream';
    my $len = $headers->content_length;

    # Guessing extension
    my $mime_type = $headers->mime_type( $default_mime );
    $self->_load_class( 'HTTP::Promise::MIME' ) || return( $self->pass_error );
    my $mime = HTTP::Promise::MIME->new;
    my $ext = $mime->suffix( $mime_type );
    return( $self->pass_error( $mime->error ) ) if( !defined( $ext ) );
    $ext ||= 'dat';
    my $enc;
    if( $self->ext_vary && ( $enc = $headers->content_encoding ) )
    {
        $self->_load_class( 'HTTP::Promise::Stream' ) || return( $self->pass_error );
        my $enc_ext = HTTP::Promise::Stream->encoding2suffix( $enc ) ||
            return( $self->pass_error( HTTP::Promise::Stream->error ) );
            $ext .= '.' . $enc_ext->join( '.' )->scalar if( !$enc_ext->is_empty );
    }
    my $tempfile = $self->new_tempfile( extension => $ext ) ||
        return( $self->pass_error );
    # HTTP::Promise::Body::File inherits from Module::Generic::File, so we pass it some
    # appropriate parameters.
    my $body = $ent->new_body( 'file', $tempfile ) ||
        return( $self->pass_error( $ent->error ) );
    my $io = $body->open( '+>', { binmode => 'raw', autoflush => 1 } ) ||
        return( $self->pass_error( $body->error ) );
    my $buff = '';
    my $bytes = -1;
    my $te_re = qr{
    \A (                 # header
        ( [0-9a-fA-F]+ ) # next_len (hex number)
        (?:;
            $HTTP_TOKEN
            =
            (?: $HTTP_TOKEN | $HTTP_QUOTED_STRING )
        )*               # optional chunk-extensions
        [[:blank:]]*     # www.yahoo.com adds spaces here.
                         # Is this valid?
        \015\012         # CR+LF
    )
    }mxs;
    
    READ_LOOP: while( $bytes )
    {
        # If we do not find anything within the maximum allocable memory size, this will
        # return an error, so we can bank on it
        my $hdr = $reader->read_until_in_memory( $te_re, include => 1 );
        return( $self->pass_error( $reader->error ) ) if( !defined( $hdr ) );
        last if( !length( $hdr ) );
        
        my( $header, $hex_len ) = ( $hdr =~ m/$te_re/ );
        # remove header from buffer
        # $hdr = substr( $hdr, 0, length( $header ), '' );
        my $len = hex( $hex_len );
        if( $len == 0 )
        {
            last READ_LOOP;
        }
        # $reader->unread( $hdr ) if( length( $hdr ) );

        my $chunk_size = $bufsize;
        $chunk_size = $len if( $chunk_size > $len );
        my $total_bytes = 0;
        READ_CHUNK: while( $bytes = $reader->read( $buff, $chunk_size ) )
        {
            if( $ent->is_binary( $buff ) )
            {
                if( -t( STDIN ) )
                {
                    $self->message_colour( 5, '<green>[' . length( $buff ) . ' bytes of binary data not shown here]</>', { prefix => '<<<' } );
                }
                else
                {
                    $self->message_colour( 5, '[' . length( $buff ) . ' bytes of binary data not shown here]', { prefix => '<<<' } );
                }
            }
            else
            {
            }

            my $bytes_out = $io->syswrite( $buff );
            return( $self->pass_error( $io->error ) ) if( !defined( $bytes_out ) );

            if( $bytes_out != $bytes )
            {
                return( $self->error( "Error writing to body $body: bytes read ($bytes) do not equate to bytes writen ($bytes_out)" ) );
            }
            $total_bytes += $bytes;
            last READ_CHUNK if( $total_bytes == $len );
            # We do not want to read more than we should
            $chunk_size = ( $len - $total_bytes ) if( ( $total_bytes < $len ) && ( ( $total_bytes + $chunk_size ) > $len ) );
        }
        return( $self->error( "Error reading http body from socket: ", $reader->error ) ) if( !defined( $bytes ) );
        # consume the trailing CRLF sequence
        my $trash = $reader->read_until_in_memory( qr/${CRLF}/, include => 1 );
        return( $self->pass_error( $reader->error ) ) if( !defined( $trash ) );
    }
    $io->close;
    # consume the final CRLF sequence
    my $trash = $reader->read_until_in_memory( qr/${CRLF}/, include => 1 );
    # Mark body as being encoded if necessary
    $ent->is_encoded( ( defined( $enc ) && CORE::length( $enc ) ) ? 1 : 0 );
    return( $body );
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

HTTP::Promise - Asynchronous HTTP Request and Promise

=head1 SYNOPSIS

    use HTTP::Promise;
    my $p = HTTP::Promise->new(
        agent => 'MyBot/1.0'
        accept_encoding => 'auto', # set to 'none' to disable receiving compressed data
        accept_language => [qw( fr-FR fr en-GB en ja-JP )],
        auto_switch_https => 1,
        # For example, a Cookie::Jar object
        cookie_jar => $cookie_jar,
        dnt => 1,
        # 2Mb. Any data to be sent being bigger than this will trigger a Continue conditional query
        expect_threshold => 2048000,
        # Have the file extension reflect the encoding, if any
        ext_vary => 1,
        # 100Kb. Anything bigger than this will be automatically saved on file rather than memory
        max_body_in_memory_size => 102400,
        # 8Kb
        max_headers_size => 8192,
        max_redirect => 3,
        # For Promise::Me
        medium => 'mmap',
        proxy => 'https://proxy.example.org:8080',
        # The serialiser to use for the promise in Promise::Me
        # Defaults to storable, but can also be cbor and sereal
        serialiser => 'sereal',
        shared_mem_size => 1048576,
        # You can also use decimals with Time::HiRes
        timeout => 15,
        # force the use of files to store the response content
        use_content_file => 1,
        # Should we use promise?
        # use_promise => 0,
    );
    my $prom = $p->get( 'https://www.example.org', $hash_of_query_params )->then(sub
    {
        # Nota bene: the last value in this sub will be passed as the argument to the next 'then'
        my $resp = shift( @_ ); # get the HTTP::Promise::Response object
    })->catch(sub
    {
        my $ex = shift( @_ ); # get a HTTP::Promise::Exception object
        say "Exception code is: ", $ex->code;
    });
    # or using hash reference of options to prepare the request
    my $req = HTTP::Promise::Request->new( get => 'https://www.example.org' ) ||
        die( HTTP::Promise::Request->error );
    my $prom = $p->request( $req )->then(sub{ #... })->catch(sub{ # ... });
    # Prepare the query and get an HTTP::Promise::Request in return
    # This is useful for debugging
    my $req = $p->prepare( GET => 'https://example.com',
        Authorization => "Bearer $some_token",
        Accept => 'application/json',
        Query => {
            param1 => $value1,
            param2 => $value2,
        },
    ) || die( $p->error );
    say "Request would be: ", $req->as_string;

=head1 VERSION

    v0.5.0

=head1 DESCRIPTION

L<HTTP::Promise> provides with a fast and powerful yet memory-friendly API to make true asynchronous HTTP requests using fork with L<Promise::Me>.

It is based on the design of L<HTTP::Message>, but with a much cleaner interface to make requests and manage HTTP entity bodies.

Here are the key features:

=over 4

=item * Support for HTTP/1.0 and HTTP/1.1

=item * Handles gracefully very large files by reading and sending them in chunks.

=item * Supports C<Continue> conditional requests

=item * Support redirects

=item * Reads data in chunks of bytes and not line by line.

=item * Easy-to-use interface to encode and decode with L<HTTP::Promise::Stream>

=item * Multi-lingual and complete HTTP Status codes with L<HTTP::Promise::Status>

=item * MIME guessing module with L<HTTP::Promise::MIME>

=item * Powerful HTTP parser with L<HTTP::Promise::Parser> supporting complex C<multipart> HTTP messages.

=item * Has thorough documentation

=back

Here is how it is organised in overall:

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

It differentiates from other modules by using several XS modules for speed, and has a notion of HTTP L<entity|HTTP::Promise::Entity> and L<body|HTTP::Promise::Body> stored either on file or in memory.

It also has modules to make it really super easy to create C<x-www-form-urlencoded> requests with L<HTTP::Promise::Body::Form>, or C<multipart> ones with L<HTTP::Promise::Body::Form::Data>

Thus, you can either have a fine granularity by creating your own request using L<HTTP::Promise::Request>, or you can use the high level methods provided by L<HTTP::Promise>, which are: L</delete>, L</get>, L</head>, L</options>, L</patch>, L</post>, L</put> and each will occur asynchronously.

Each of those methods returns a L<promise|Promise::Me>, which means you can chain the results using a chainable L<then|Promise::Me/then> and L<catch|Promise::Me/catch> for errors.

You can also wait for all of them to finish using L<await|Promise::Me/await>, which is exported by default by L<HTTP::Promise> and L<all|Promise::Me/all> or L<race|Promise::Me/|race>.

    my @results = await( $p1, $p2 );
    my @results = HTTP::Promise->all( $p1, $p2 );
    # First promise that is resolved or rejected makes this super promise resolved and
    # return the result
    my @results = HTTP::Promise->race( $p1, $p2 );

You can also share variables using C<share>, such as:

    my $data : shared = {};
    # or
    my( $name, @first_names, %preferences );
    share( $name, @first_names, %preferences );

See L<Promise::Me> for more information.

It calls L<resolve|Promise::Me/resolve> when the request has been completed and sends a L<HTTP::Promise::Response> object whose API is similar to that of L<HTTP::Response>.

When an error occurs, it is caught and sent by calling L<Promise::Me/reject> with an L<HTTP::Promise::Exception> object.

Cookies are automatically and transparently managed with L<Cookie::Jar> which can load and store cookies to a json file you specify. You can create a L<cookie object|Cookie::Jar> and pass it to the constructor with the C<cookie_jar> option.

=head1 CONSTRUCTOR

=head2 new

Provided with some optional parameters, and this instantiates a new L<HTTP::Promise> objects and returns it. If an error occurred, it will return C<undef> and the error can be retrieved using L<error|Module::Generic/error> method.

It accepts the following parameters. Each of those options have a corresponding method, so you can get or change its value later:

=over 4

=item * C<accept_encoding>

String. This sets whether we should accept compressed data.

You can set it to C<none> to disable it. By default, this is C<auto>, and it will set the C<Accept-Encoding> C<HTTP> header to all the supported encoding based on the availability of associated modules.

You can also set this to a comma-separated list of known encoding, typically: C<bzip2,deflate,gzip,rawdeflate,brotli>

See L<HTTP::Promise::Stream> for more details.

=item * C<agent>

String. Set the user agent, i.e. the way this interface identifies itself when communicating with an HTTP server. By default, it uses something like C<HTTP-Promise/v0.1.0>

=item * C<cookie_jar>

Object. Set the class handling the cookie jar. By default it uses L<Cookie::Jar>

=item * C<default_headers>

L<HTTP::Promise::Headers>, or L<HTTP::Headers> Object. Sets the headers object containing the default headers to use.

=item * C<local_address>

String. A local IP address or local host name to use when establishing TCP/IP connections.

=item * C<local_host>

String. Same as C<local_address>

=item * C<local_port>

Integer. A local port to use when establishing TCP/IP connections.

=item * C<max_redirect>

Integer. This is the maximum number of redirect L<HTTP::Promise> will follow until it gives up. Default value is C<7>

=item * C<max_size>

Integer. Set the size limit for response content. If the response content exceeds the value set here, the request will be aborted and a C<Client-Aborted> header will be added to the response object returned. Default value is C<undef>, i.e. no limit.

See also the C<threshold> option.

=item * C<medium>

This can be either C<file>, C<mmap> or C<memory>. This will be passed on to L<Promise::Me> as C<result_shared_mem_size> to store resulting data between processes. See L<Promise::Me> for more details.

It defaults to C<$Promise::Me::SHARE_MEDIUM>

=item * C<no_proxy>

Array reference. Do not proxy requests to the given domains.

=item * C<proxy>

The url of the proxy to use for the HTTP requests.

=item * C<requests_redirectable>

Array reference. This sets the list of http methods that are allowed to be redirected. Default to empty, which means that all methods can be redirected.

=item * C<serialiser>

String. Specify the serialiser to use for L<Promise::Me>. Possible values are: L<cbor|CBOR::XS>, L<sereal|Sereal> or L<storable|Storable::Improved>

By default it uses the value set in the global variable C<$SERIALISER>, which is a copy of the C<$SERIALISER> in L<Promise::Me>, which should be by default C<storable>

=item * C<shared_mem_size>

Integer. This will be passed on to L<Promise::Me>. See L<Promise::Me> for more details.

It defaults to C<$Promise::Me::RESULT_MEMORY_SIZE>

=item * C<ssl_opts>

Hash reference. Sets an hash reference of ssl options. The default values are set as follows:

=over 8

=item 1. C<verify_hostname>

When enabled, this ensures it connects to servers that have a valid certificate matching the expected hostname.

=over 12

=item 1.1. If environment variable C<PERL_LWP_SSL_VERIFY_HOSTNAME> is set, the ssl option property C<verify_hostname> takes its value.

=item 1.2. If environment variable C<HTTPS_CA_FILE> or C<HTTPS_CA_DIR> are set to a true value, then the ssl option property C<verify_hostname> is set to C<0> and option property C<SSL_verify_mode> is set to C<1>

=item 1.3 If none of the above applies, it defaults C<verify_hostname> to C<1>

=back

=item 2. C<SSL_ca_file>

This is the path to a file containing the Certificate Authority certificates.

If environment variable C<PERL_LWP_SSL_CA_FILE> or C<HTTPS_CA_FILE> is set, then the ssl option property C<SSL_ca_file> takes its value.

=item 3. C<SSL_ca_path>

This is the path to a directory of files containing Certificate Authority certificates.

If environment variable C<PERL_LWP_SSL_CA_PATH> or C<HTTPS_CA_DIR> is set, then the ssl option property C<SSL_ca_path> takes its value.

=back

Other options can be set and are processed directly by the SSL Socket implementation in use. See L<IO::Socket::SSL> or L<Net::SSL> for details.

=item * C<threshold>

Integer. Sets the content length threshold beyond which, the response content will be stored to a locale file. It can then be fetch with L</file>. Default to global variable C<$CONTENT_SIZE_THRESHOLD>, which is C<undef> by default.

See also the C<max_size> option.

=item * C<timeout>

Integer. Sets the timeout value. Defaults to 180 seconds, i.e. 3 minutes.

=item * C<use_content_file>

Boolean. Enables the use of a temporary local file to store the response content, no matter the size o the response content.

=item * C<use_promise>

Boolean. When true, this will have L<HTTP::Promise> HTTP methods return a L<HTTP::Promise|promise>, and when false, it returns directly the L<HTTP::Promise::Response|response object>. Defaults to true.

=back

=head1 METHODS

The following methods are available. This interface provides similar interface as L<LWP::UserAgent> while providing more granular control.

=head2 accept_encoding

String. Sets or gets whether we should accept compressed data.

You can set it to C<none> to disable it. By default, this is C<auto>, and it will set the C<Accept-Encoding> C<HTTP> header to all the supported encoding based on the availability of associated modules.

You can also set this to a comma-separated list of known encoding, typically: C<bzip2,deflate,gzip,rawdeflate,brotli>

See L<HTTP::Promise::Stream> for more details.

Returns a L<scalar object|Module::Generic::Scalar> of the current value.

=head2 accept_language

An array of acceptable language. This will be used to set the C<Accept-Language> header.

See also L<HTTP::Promise::Headers::AcceptLanguage>

=head2 agent

This is a string.

Sets or gets the agent id used to identify when making the server connection.

It defaults to C<HTTP-Promise/v0.1.0>

    my $p = HTTP::Promise->new( agent => 'MyBot/1.0' );
    $p->agent( 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:99.0) Gecko/20100101 Firefox/99.0' );

The C<User-Agent> header field is only set to this provided value if it is not already set.

=head2 accept_language

Sets or gets an array of acceptable response content languages.

For example:

    $http->accept_language( [qw( fr-FR ja-JP en-GB en )] );

Would result into an C<Accept-Language> header set to C<fr-FR;q=0.9,ja-JP;q=0.8,en-GB;q=0.7,en;q=0.6>

The C<Accept-Language> header would only be set if it is not set already.

=head2 auto_switch_https

Boolean. If set to a true value, or if left to C<undef> (default value), this will set the C<Upgrade-Insecure-Requests> header field to C<1>

=head2 buffer_size

The size of the buffer to use when reading data from the filehandle or socket.

=head2 connection_header

Sets or gets the value for the header C<Connection>. It can be C<close> or C<keep-alive>

If it is let C<undef>, this module will try to guess the proper value based on the L<HTTP::Promise::Request/protocol> and L<HTTP::Promise::Request/version> used.

For protocol C<HTTP/1.0>, C<Connection> value would be C<close>, but above C<HTTP/1.1> the connection can be set to C<keep-alive> and thus be re-used.

=head2 cookie_jar

Sets or gets the Cookie jar class object to use. This is typically L<Cookie::Jar> or maybe L<HTTP::Cookies>

This defaults to L<Cookie::Jar>

    use Cookie::Jar;
    my $jar = Cookie::Jar->new;
    my $p = HTTP::Promise->new( cookie_jar => $jar );
    $p->cookie_jar( $jar );

=for Pod::Coverage decodable

=head2 decodable

This calls L<HTTP::Promise::Stream/decodable> passing it whatever arguments that were provided.

=head2 default_header

Sets one more default headers. This is a shortcut to C<< $p->default_headers->header >>

    $p->default_header( $field );
    $p->default_header( $field => $value );
    $p->default_header( 'Accept-Encoding' => scalar( HTTP::Promise->decodable ) );
    $p->default_header( 'Accept-Language' => 'fr, en, ja' );

=head2 default_headers

Sets or gets the L<default header object|HTTP::Promise::Headers>, which is set to C<undef> by default.

This can be either an L<HTTP::Promise::Headers> or L<HTTP::Headers> object.

    use HTTP::Promise::Headers;
    my $headers = HTTP::Promise::Headers->new(
        'Accept-Encoding' => scalar( HTTP::Promise->decodable ),
        'Accept-Language' => 'fr, en, ja',
    );
    my $p = HTTP::Promise->new( default_headers => $headers );

=head2 default_protocol

Sets or gets the default protocol to use. For example: C<HTTP/1.1>

=head2 delete

Provided with an C<uri> and an optional hash of header name/value pairs, and this will issue a C<DELETE> http request to the given C<uri>.

It returns a L<promise|Promise::Me>, which can be used to call one or more L<then|Promise::Me/then> and L<catch|Promise::Me/catch>

    # or $p->delete( $uri, $field1 => $value1, $field2 => $value2 )
    $p->delete( $uri )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        # an HTTP::Promise::Response is returned
        my $resp = shift( @_ );
        # Do something with the $resp object
    })->catch(sub
    {
        my $ex = shift( @_ );
        # An HTTP::Promise::Exception object is passed with an error code
        say( "Error code; ", $ex->code, " and message: ", $ex->message );
    });

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

=head2 dnt

Boolean. If set to a true value, this will set the C<DNT> header to C<1>

=head2 expect_threshold

Sets or gets the body size threshold beyond which, this module will issue a conditional C<Expect> HTTP header in order to ensure the remote HTTP server is ok.

=head2 ext_vary

Boolean. When this is set to a true value, this will have the files use extensions that reflect not just their content, but also their encoding when applicable.

For example, if an HTTP response HTML content is gzip encoded into a file, the file extensions will be C<html.gz>

Default set to C<$EXTENSION_VARY>, which by default is true.

=head2 file

If a temporary file has been set, the response content file can be retrieved with this method.

    my $p = HTTP::Promise->new( threshold => 512000 ); # 500kb
    # If the response payload exceeds 500kb, HTTP::Promise will save the content to a 
    # temporary file
    # or
    my $p = HTTP::Promise->new( use_content_file => 1 ); # always use a temporary file
    # Returns a Module::Generic::File object
    my $f = $p->file;

=head2 from

Get or set the email address for the human user who controls the requesting user agent. The address should be machine-usable, as defined in L<RFC2822|https://tools.ietf.org/html/rfc2822>. The C<from> value is sent as the C<From> header in the requests

The default value is C<undef>, so no C<From> field is set by default.

    my $p = HTTP::Promise->new( from => 'john.doe@example.com' );
    $p->from( 'john.doe@example.com' );

=head2 get

Provided with an C<uri> and an optional hash of header name/value pairs, and this will issue a C<GET> http request to the given C<uri>.

It returns a L<promise|Promise::Me>, which can be used to call one or more L<then|Promise::Me/then> and L<catch|Promise::Me/catch>

    # or $p->get( $uri, $field1 => $value1, $field2 => $value2 )
    $p->get( $uri )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        # an HTTP::Promise::Response is returned
        my $resp = shift( @_ );
        # Do something with the $resp object
    })->catch(sub
    {
        my $ex = shift( @_ );
        # An HTTP::Promise::Exception object is passed with an error code
        say( "Error code; ", $ex->code, " and message: ", $ex->message );
    });

If you pass a special header name C<Content> or C<Query>, it will be used to set the query string of the L<URI>.

The value can be an hash reference, and L<query_form|URI/query_form> will be called.

If the value is a string or an object that stringifies, L<query|URI/query> will be called to set the value as-is. this option gives you direct control of the query string.

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

=head2 head

Provided with an C<uri> and an optional hash of header name/value pairs, and this will issue a C<HEAD> http request to the given C<uri>.

It returns a L<promise|Promise::Me>, which can be used to call one or more L<then|Promise::Me/then> and L<catch|Promise::Me/catch>

    # or $p->head( $uri, $field1 => $value1, $field2 => $value2 )
    $p->head( $uri )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        # an HTTP::Promise::Response is returned
        my $resp = shift( @_ );
        # Do something with the $resp object
    })->catch(sub
    {
        my $ex = shift( @_ );
        # An HTTP::Promise::Exception object is passed with an error code
        say( "Error code; ", $ex->code, " and message: ", $ex->message );
    });

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

=head2 httpize_datetime

Provided with a L<DateTime> or L<Module::Generic::DateTime> object, and this will ensure the C<DateTime> object stringifies to a valid HTTP datetime.

It returns the C<DateTime> object provided upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>

=head2 inactivity_timeout

Sets or gets the inactivity timeout in seconds. If timeout is reached, the connection is closed.

=head2 is_protocol_supported

Provided with a protocol, such as C<http>, or C<https>, and this returns true if the protocol is supported or false otherwise.

This basically returns true if the protocol is either C<http> or C<https> and false otherwise, because C<HTTP::Promise> supports only HTTP protocol.

=head2 languages

This is an alias for L</accept_language>

=head2 local_address

Get or set the local interface to bind to for network connections. The interface can be specified as a hostname or an IP address. This value is passed as the C<LocalHost> argument to L<IO::Socket>.

The default value is C<undef>.

    my $p = HTTP::Promise->new( local_address => 'localhost' );
    $p->local_address( '127.0.0.1' );

=head2 local_host

This is the same as L</local_address>. You can use either interchangeably.

=head2 local_port

Get or set the local port to use to bind to for network connections. This value is passed as the C<LocalPort> argument to L<IO::Socket>

=head2 max_body_in_memory_size

Sets or gets the maximum HTTP response body size beyond which the data will automatically be saved in a temporary file.

=head2 max_headers_size

Sets or gets the maximum HTTP response headers size, beyond which an error is triggered.

=head2 max_redirect

An integer. Sets or gets the maximum number of allowed redirection possible. Default is 7.

    my $p = HTTP::Promise->new( max_redirect => 5 );
    $p->max_redirect(12);
    my $max = $p->max_redirect;

=head2 max_size

Get or set the size limit for response content. The default is C<undef>, which means that there is no limit. If the returned response content is only partial, because the size limit was exceeded, then a C<Client-Aborted> header will be added to the response. The content might end up longer than C<max_size> as we abort once appending a chunk of data makes the length exceed the limit. The C<Content-Length> header, if present, will indicate the length of the full content and will normally not be the same as C<< length( $resp->content ) >>

    my $p = HTTP::Promise->max_size(512000); # 512kb
    $p->max_size(512000);
    my $max = $p->max_size;

=head2 mirror

Provided with an C<uri> and a C<filepath> and this will issue a conditional request to the remote server to return the remote content if it has been modified since the last modification time of the C<filepath>. Of course, if that file does not exists, then it is downloaded. If the remote resource has been changed since last time, it is downloaded again and its content stored into the C<filepath>

Just like other http methods, this returns a L<promise|Promise::Me> object.

It can then be used to call one or more L<then|Promise::Me/then> and L<catch|Promise::Me/catch>

    $p->mirror( $uri => '/some/where/file.txt' )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        # an HTTP::Promise::Response is returned
        my $resp = shift( @_ );
        # Do something with the $resp object
    })->catch(sub
    {
        my $ex = shift( @_ );
        # An HTTP::Promise::Exception object is passed with an error code
        say( "Error code; ", $ex->code, " and message: ", $ex->message );
    });

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

=head2 new_headers

    my $headers = $p->new_headers( Accept => 'text/html,application/xhtml+xml;q=0.9,*/*;q=0.8' );

This takes some key-value pairs as header name and value, and instantiate a new L<HTTP::Promise::Headers> object and returns it.

If an error occurs, this set an L<error object|HTTP::Promise::Exception> and return C<undef> in scalar context or an empty list in list context.

=head2 no_proxy

Sets or gets a list of domain names for which the proxy will not apply. By default this is empty.

This returns an L<array object|Module::Generic::Array>

    my $p = HTTP::Promise->new( no_proxy => [qw( example.com www2.example.net )] );
    $p->no_proxy( [qw( localhost example.net )] );
    my $ar = $p->no_proxy;
    say $ar->length, " proxy exception(s) set.";

=head2 options

Provided with an C<uri>, and this will issue an C<OPTIONS> http request to the given C<uri>.

It returns a L<promise|Promise::Me>, which can be used to call one or more L<then|Promise::Me/then> and L<catch|Promise::Me/catch>

    # or $p->head( $uri, $field1 => $value1, $field2 => $value2 )
    $p->options( $uri )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        # an HTTP::Promise::Response is returned
        my $resp = shift( @_ );
        # Do something with the $resp object
    })->catch(sub
    {
        my $ex = shift( @_ );
        # An HTTP::Promise::Exception object is passed with an error code
        say( "Error code; ", $ex->code, " and message: ", $ex->message );
    });

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

=head2 patch

Provided with an C<uri> and an optional hash of form data, followed by an hash of header name/value pairs and this will issue a C<PATCH> http request to the given C<uri>.

If a special header name C<Content> is provided, its value will be used to create the key-value pairs form data. That C<Content> value can either be an array reference, or an hash reference of key-value pairs. If if is just a string, it will be used as-is as the request body.

If a special header name C<Query> is provided, its value will be used to set the C<URI> query string. The query string thus provided must already be escaped.

It returns a L<promise|Promise::Me>, which can be used to call one or more L<then|Promise::Me/then> and L<catch|Promise::Me/catch>

    # or $p->patch( $uri, \@form, $field1 => $value1, $field2 => $value2 );
    # or $p->patch( $uri, \%form, $field1 => $value1, $field2 => $value2 );
    # or $p->patch( $uri, $field1 => $value1, $field2 => $value2 );
    # or $p->patch( $uri, $field1 => $value1, $field2 => $value2, Content => \@form, Query => $escaped_string );
    # or $p->patch( $uri, $field1 => $value1, $field2 => $value2, Content => \%form, Query => $escaped_string );
    # or $p->patch( $uri, $field1 => $value1, $field2 => $value2, Content => $content, Query => $escaped_string );
    $p->patch( $uri )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        # an HTTP::Promise::Response is returned
        my $resp = shift( @_ );
        # Do something with the $resp object
    })->catch(sub
    {
        my $ex = shift( @_ );
        # An HTTP::Promise::Exception object is passed with an error code
        say( "Error code; ", $ex->code, " and message: ", $ex->message );
    });

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

=head2 post

Provided with an C<uri> and an optional hash of form data, followed by an hash of header name/value pairs and this will issue a C<POST> http request to the given C<uri>.

If a special header name C<Content> is provided, its value will be used to create the key-value pairs form data. That C<Content> value can either be an array reference, or an hash reference of key-value pairs. If if is just a string, it will be used as-is as the request body.

If a special header name C<Query> is provided, its value will be used to set the C<URI> query string. The query string thus provided must already be escaped.

How the form data is formatted depends on the C<Content-Type> set in the headers passed. If the C<Content-Type> header is C<form-data> or C<multipart/form-data>, the form data will be formatted as a C<multipart/form-data> post, otherwise they will be formatted as a C<application/x-www-form-urlencoded> post.

It returns a L<promise|Promise::Me>, which can be used to call one or more L<then|Promise::Me/then> and L<catch|Promise::Me/catch>

    # or $p->post( $uri, \@form, $field1 => $value1, $field2 => $value2 );
    # or $p->post( $uri, \%form, $field1 => $value1, $field2 => $value2 );
    # or $p->post( $uri, $field1 => $value1, $field2 => $value2 );
    # or $p->post( $uri, $field1 => $value1, $field2 => $value2, Content => \@form, Query => $escaped_string );
    # or $p->post( $uri, $field1 => $value1, $field2 => $value2, Content => \%form, Query => $escaped_string );
    # or $p->post( $uri, $field1 => $value1, $field2 => $value2, Content => $content, Query => $escaped_string );
    $p->post( $uri )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        # an HTTP::Promise::Response is returned
        my $resp = shift( @_ );
        # Do something with the $resp object
    })->catch(sub
    {
        my $ex = shift( @_ );
        # An HTTP::Promise::Exception object is passed with an error code
        say( "Error code; ", $ex->code, " and message: ", $ex->message );
    });

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

=head2 prepare

This takes an HTTP method whose case does not matter, i.e. it could be C<get> or C<GET>, and C<URL>, and a set of HTTP headers or special parameters like C<Content> or C<Query>. You can refer to each standard method L</delete>, L</get>, L</head>, L</options>, L</patch>, L</post>, L</put> for more information.

You can also pass other methods, and your parameters will be passed through directly to L<HTTP::Promise::Request>

If successful, this returns an L<HTTP::Promise::Request> object, otherwise, it sets an L<HTTP::Promise::Exception> and returns C<undef> in scalar context, or an empty list in list context.

=head2 prepare_headers

Provided with an L<HTTP::Promise::Request> object, and this will set the following request headers, if they are not set already.

You can override this method if you create a module of your own that inherits from L<HTTP::Promise>.

It returns the L<HTTP::Promise::Request> received, or upon error, it sets an L<error|Module::Generic/error> and returns C<undef>

Headers set, if not set already are:

=over 4

=item * C<Accept>

This uses the values set with L</accept>

=item * C<Accept-Language>

This uses the values set with L</accept_language> or L</languages>

=item * C<Accept-Encoding>

This uses the value returned from L<HTTP::Promise::Stream/decodable> to find out the encoding installed and supported on your system.

=item * C<DNT>

This uses the value set with L</dnt>

=item * C<Upgrade-Insecure-Requests>

This uses the value set with L</auto_switch_https> or L</upgrade_insecure_requests>

=item * C<User-Agent>

This uses the value set with L</agent>

=back

=head2 proxy

Array reference. This sets the scheme and their proxy or proxies. Default to C<undef>. For example:

    my $p = HTTP::Promise->new( proxy => [ [qw( http ftp )] => 'https://proxy.example.com:8001' ] );
    my $p = HTTP::Promise->new( proxy => [ http => 'https://proxy.example.com:8001' ] );
    my $p = HTTP::Promise->new( proxy => [ ftp => 'http://ftp.example.com:8001/', 
                                           [qw( http https )] => 'https://proxy.example.com:8001' ] );
    my $proxy = $p->proxy( 'https' );

=head2 proxy_authorization

Sets or gets the proxy authorization string. This is computed automatically when you set a user and a password  to the proxy URI by setting the value to L</proxy>

=head2 put

Provided with an C<uri> and an optional hash of form data, followed by an hash of header name/value pairs and this will issue a C<PUT> http request to the given C<uri>.

If a special header name C<Content> is provided, its value will be used to create the key-value pairs form data. THat C<Content> value can either be an array reference, or an hash reference of key-value pairs. If if is just a string, it will be used as-is as the request body.

If a special header name C<Query> is provided, its value will be used to set the C<URI> query string. The query string thus provided must already be escaped.

How the form data is formatted depends on the C<Content-Type> set in the headers passed. If the C<Content-Type> header is C<form-data> or C<multipart/form-data>, the form data will be formatted as a C<multipart/form-data> post, otherwise they will be formatted as a C<application/x-www-form-urlencoded> put.

It returns a L<promise|Promise::Me>, which can be used to call one or more L<then|Promise::Me/then> and L<catch|Promise::Me/catch>

    # or $p->put( $uri, \@form, $field1 => $value1, $field2 => $value2 );
    # or $p->put( $uri, \%form, $field1 => $value1, $field2 => $value2 );
    # or $p->put( $uri, $field1 => $value1, $field2 => $value2 );
    # or $p->put( $uri, $field1 => $value1, $field2 => $value2, Content => \@form, Query => $escaped_string );
    # or $p->put( $uri, $field1 => $value1, $field2 => $value2, Content => \%form, Query => $escaped_string );
    # or $p->put( $uri, $field1 => $value1, $field2 => $value2, Content => $content, Query => $escaped_string );
    $p->put( $uri )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        # an HTTP::Promise::Response is returned
        my $resp = shift( @_ );
        # Do something with the $resp object
    })->catch(sub
    {
        my $ex = shift( @_ );
        # An HTTP::Promise::Exception object is passed with an error code
        say( "Error code; ", $ex->code, " and message: ", $ex->message );
    });

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

=head2 request

This method will issue the proper request in accordance with the request object provided. It will process redirects and authentication responses transparently. This means it may end up sending multiple request, up to the limit set with the object option L</max_redirect>

This method takes the following parameters:

=over 4

=item 1. a L<request object|HTTP::Promise::Request>, which is typically L<HTTP::Promise::Request>, or L<HTTP::Request>, but any class that implements a similar interface is acceptable

=item 2. an optional hash or hash reference of parameters:

=over 8

=item C<read_size>

Integer. If provided, this will instruct to read the response by that much bytes at a time.

=item C<use_content_file>

Boolean. If true, this will instruct the use of a temporary file to store the response content. That file may then be retrieved with the method L</file>.

You can also control the use of a temporary file to store the response content with the L</threshold> object option.

=back

=back

It returns a L<promise object|Promise::Me> just like other methods.

For example:

    use HTTP::Promise::Request;
    my $req = HTTP::Promise::Request->new( get => 'https://example.com' );
    my $p = HTTP::Promise->new;
    my $prom = $p->request( $req )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        # Get the HTTP::Promise::Response object
        my $resp = shift( @_ );
        # Do something with the response object
    })->catch(sub
    {
        # Get a HTTP::Promise::Exception object
        my $ex = shift( @_ );
        say "Got an error code ", $ex->code, " with message: ", $ex->message;
    });

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

=head2 requests_redirectable

Array reference. Sets or gets the list of http method that are allowed to be redirected. By default this is an empty list, i.e. all http methods are allowed to be redirected. Defaults to C<GET> and C<HEAD> as per L<rfc 2616|https://tools.ietf.org/html/rfc2616>

This returns an L<array object|Module::Generic::Array>

    my $p = HTTP::Promise->new( requests_redirectable => [qw( HEAD GET POST )] );
    $p->requests_redirectable( [qw( HEAD GET POST )] );
    my $ok_redir = $p->requests_redirectable;
    # Add put
    $ok_redir->push( 'PUT' );
    # Remove POST we just added
    $ok_redir->remove( 'POST' );

=head2 send

Provided with an L<HTTP::Promise::Request>, and an optional hash or hash reference of options and this will attempt to connect to the specified L<uri|HTTP::Promise::Request/uri>

Supported options:

=over 4

=item * C<expect_threshold>

A number specifying the request body size threshold beyond which, this will issue a conditional C<Expect> HTTP header.

=item * C<total_attempts>

Total number of attempts. This is a value that is decreased for each redirected requests it receives until the maximum is reached. The maximum is specified with L</max_redirect>

After connected to the remote server, it will send the request using L<HTTP::Promise::Request/print>, and reads the HTTP response, possibly C<chunked>.

It returns a new L<HTTP::Promise::Response> object, or upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=back

=head2 send_te

Boolean. Enables or disables the C<TE> http header. Defaults to true. If true, the C<TE> will be added to the outgoing http request.

    my $p = HTTP::Promise->new( send_te => 1 );
    $p->send_te(1);
    my $bool = $p->send_te;

=head2 serialiser

String. Sets or gets the serialiser to use for L<Promise::Me>. Possible values are: L<cbor|CBOR::XS>, L<sereal|Sereal> or L<storable|Storable::Improved>

By default, the value is set to the global variable C<$SERIALISER>, which is a copy of the C<$SERIALISER> in L<Promise::Me>, which should be by default C<storable>

=head2 simple_request

This method takes the same parameters as L</request> and differs in that it will not try to handle redirects or authentication.

It returns a L<promise object|Promise::Me> just like other methods.

For example:

    use HTTP::Promise::Request;
    my $req = HTTP::Promise::Request->new( get => 'https://example.com' );
    my $p = HTTP::Promise->new;
    my $prom = $p->simple_request( $req )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        # Get the HTTP::Promise::Response object
        my $resp = shift( @_ );
        # Do something with the response object
    })->catch(sub
    {
        # Get a HTTP::Promise::Exception object
        my $ex = shift( @_ );
        say "Got an error code ", $ex->code, " with message: ", $ex->message;
    });

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

=head2 ssl_opts

L<Hash reference object|Module::Generic::Hash>. Sets or gets the ssl options properties used when making requests over ssl. The default values are set as follows:

=over 8

=item 1. C<verify_hostname>

When enabled, this ensures it connects to servers that have a valid certificate matching the expected hostname.

=over 12

=item 1.1. If environment variable C<PERL_LWP_SSL_VERIFY_HOSTNAME> is set, the ssl option property C<verify_hostname> takes its value.

=item 1.2. If environment variable C<HTTPS_CA_FILE> or C<HTTPS_CA_DIR> are set to a true value, then the ssl option property C<verify_hostname> is set to C<0> and option property C<SSL_verify_mode> is set to C<1>

=item 1.3 If none of the above applies, it defaults C<verify_hostname> to C<1>

=back

=item 2. C<SSL_ca_file>

This is the path to a file containing the Certificate Authority certificates.

If environment variable C<PERL_LWP_SSL_CA_FILE> or C<HTTPS_CA_FILE> is set, then the ssl option property C<SSL_ca_file> takes its value.

=item 3. C<SSL_ca_path>

This is the path to a directory of files containing Certificate Authority certificates.

If environment variable C<PERL_LWP_SSL_CA_PATH> or C<HTTPS_CA_DIR> is set, then the ssl option property C<SSL_ca_path> takes its value.

=back

Other options can be set and are processed directly by the SSL Socket implementation in use. See L<IO::Socket::SSL> or L<Net::SSL> for details.

=head2 stop_if

Sets or gets a callback code reference (reference to a perl subroutine or an anonymous subroutine) that will be used to determine if we  should keep trying upon reading data from the filehandle and an C<EINTR> error occurs.

If the callback returns true, further attempts will stop and return an error. The default is to continue trying.

=head2 threshold

Integer. Sets the content length threshold beyond which, the response content will be stored to a locale file. It can then be fetch with L</file>. Default to global variable C<$CONTENT_SIZE_THRESHOLD>, which is C<undef> by default.

See also the L</max_size> option.

    my $p = HTTP::Promise->new( threshold => 512000 );
    $p->threshold(512000);
    my $limit = $p->threshold;

=head2 timeout

Integer. Sets the timeout value. Defaults to 180 seconds, i.e. 3 minutes.

The request is aborted if no activity on the connection to the server is observed for C<timeout> seconds. When a request times out, a L<response object|HTTP::Promise::Response> is still returned.  The response object will have a standard http status code of C<500>, i.e. server error. This response will have the C<Client-Warning> header set to the value of C<Internal response>.

Returns a L<number object|Module::Generic::Number>

    my $p = HTTP::Promise->new( timeout => 10 );
    $p->timeout(10);
    my $timeout = $p->timeout;

=head2 upgrade_insecure_requests

This is an alias for L</auto_switch_https>

=head2 uri_escape

URI-escape the given string using L<URI::Escape::XS/uri_escape>

=head2 uri_unescape

URI-unescape the given string using L<URI::Escape::XS/uri_unescape>

=head2 use_content_file

Boolean. Enables or disables the use of a temporary file to store the response content. Defaults to false.

When true, the response content will be stored into a temporary file, whose object is a L<Module::Generic::File> object and can be retrieved with L</file>.

=head2 use_promise

Boolean. When true, this will have L<HTTP::Promise> HTTP methods return a L<HTTP::Promise|promise>, and when false, it returns directly the L<HTTP::Promise::Response|response object>. Defaults to true.

=head1 CLASS FUNCTIONS

=head2 fetch

This method can be exported, such as:

    use HTTP::Promise qw( fetch );
    my $prom = fetch( 'http://example.com/something.json' );
    # or
    fetch( 'http://example.com/something.json' )->then(sub
    {
        my( $resolve, $reject ) = @$_;
        my $resp = shift( @_ );
        my $data = $resp->decoded_content;
    })->then(sub
    {
        my $json = shift( @_ );
        print( STDOUT "JSON data:\n$json\n" );
    });

You can also call it with an object, such as:

    my $http = HTTP::Promise->new;
    my $prom = $http->fetch( 'http://example.com/something.json' );

C<fetch> performs the same way as L</get>, by default, and accepts the same possible parameters. It sets an error and returns C<undef> upon error, or return a L<promise|Promise::Me>

However, if L</use_promise> is set to false, this will return an L<HTTP::Promise::Response> object directly.

You can, however, specify, another method by providing the C<method> option with value being an HTTP method, i.e. C<DELETE>, C<GET>, C<HEAD>, C<OPTIONS>, C<PATCH>, C<POST>, C<PUT>.

See also L<Mozilla documentation on fetch|https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 CREDITS

This module is inspired by the design and workflow of Gisle Aas and his implementation of L<HTTP::Message>, but built completely differently.

L<HTTP::Promise::Entity> and L<HTTP::Promise::Body> have been inspired by Erik Dorfman (a.k.a. Eryq) and Dianne Skoll's implementation of L<MIME::Entity>

=head1 BUGS

You can report bugs at <https://gitlab.com/jackdeguest/HTTP-Promise/issues>

=head1 SEE ALSO

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

L<Promise::Me>, L<Cookie::Jar>, L<Module::Generic::File>, L<Module::Generic::Scalar>, L<Module::Generic>

L<HTTP::XSHeaders>, L<File::MMagic::XS>, L<CryptX>, L<HTTP::Parser2::XS>, L<URI::Encode::XS>, L<URI::Escape::XS>, L<URL::Encode::XS>

L<IO::Compress::Bzip2>, L<IO::Compress::Deflate>, L<IO::Compress::Gzip>, L<IO::Compress::Lzf>, L<IO::Compress::Lzip>, L<IO::Compress::Lzma>, L<IO::Compress::Lzop>, L<IO::Compress::RawDeflate>, L<IO::Compress::Xz>, L<IO::Compress::Zip>, L<IO::Compress::Zstd>

L<rfc6266 on Content-Disposition|https://datatracker.ietf.org/doc/html/rfc6266>,
L<rfc7230 on Message Syntax and Routing|https://tools.ietf.org/html/rfc7230>,
L<rfc7231 on Semantics and Content|https://tools.ietf.org/html/rfc7231>,
L<rfc7232 on Conditional Requests|https://tools.ietf.org/html/rfc7232>,
L<rfc7233 on Range Requests|https://tools.ietf.org/html/rfc7233>,
L<rfc7234 on Caching|https://tools.ietf.org/html/rfc7234>,
L<rfc7235 on Authentication|https://tools.ietf.org/html/rfc7235>,
L<rfc7578 on multipart/form-data|https://tools.ietf.org/html/rfc7578>,
L<rfc7540 on HTTP/2.0|https://tools.ietf.org/html/rfc7540>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
