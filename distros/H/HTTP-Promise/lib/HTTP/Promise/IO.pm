##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/IO.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/02
## Modified 2022/05/02
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::IO;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $CRLF $IS_WIN32 $INIT_PARAMS $VERSION );
    use Errno qw( EAGAIN ECONNRESET EINPROGRESS EINTR EWOULDBLOCK ECONNABORTED EISCONN );
    use Fcntl qw( F_GETFL F_SETFL O_NONBLOCK O_RDONLY O_RDWR SEEK_SET SEEK_END );
    use Socket qw(
        PF_INET SOCK_STREAM
        IPPROTO_TCP
        TCP_NODELAY
        pack_sockaddr_in
    );
    use Time::HiRes qw( time );
    use constant ERROR_EINTR => ( abs( Errno::EINTR ) * -1 );
    our $CRLF = "\015\012";
    our $IS_WIN32 = ( $^O eq 'MSWin32' );
    # This is for connect() so it knows
    our $INIT_PARAMS = [qw( buffer debug inactivity_timeout last_delimiter max_read_buffer ssl_opts stop_if timeout )];
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    return( $self->error( "No filehandle was provided." ) ) if( !scalar( @_ ) );
    my $fh   = shift( @_ );
    return( $self->error( "Filehandle provided (", overload::StrVal( $fh ), ") is not a proper filehandle." ) ) if( !$self->_is_glob( $fh ) );
    # This needs to be set to empty string and not undef to make chaining work with Module::Generic::Scalar
    $self->{buffer}             = '';
    $self->{inactivity_timeout} = 600;
    $self->{last_delimiter}     = '';
    $self->{max_read_buffer}    = 0;
    $self->{ssl_opts}           = {};
    $self->{stop_if}            = sub{};
    $self->{timeout}            = 5;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    # Ensure O_NONBLOCK is set so that calls to select in can_read() would not report ok 
    # although no data is available. See select in perlfunc for more details.
    my $dummy = '';
    if( $self->_can( $fh => 'fcntl' ) )
    {
        my $flags = $fh->fcntl( F_GETFL, $dummy );
        return( $self->error({ code => 500, message => "Unable to get flags from filehandle '$fh': $!" }) ) if( !defined( $flags ) );
        my $rv = $fh->fcntl( F_SETFL, ( $flags | O_NONBLOCK ) );
        return( $self->error({ code => 500, message => "Unable to set flags to filehandle '$fh': $!" }) ) if( !defined( $rv ) );
    }
    else
    {
        my $flags = fcntl( $fh, F_GETFL, $dummy );
        return( $self->error({ code => 500, message => "Unable to get flags from filehandle '$fh': $!" }) ) if( !defined( $flags ) );
        my $rv = fcntl( $fh, F_SETFL, ( $flags | O_NONBLOCK ) );
        return( $self->error({ code => 500, message => "Unable to set flags to filehandle '$fh': $!" }) ) if( !defined( $rv ) );
    }
    $self->{_fh} = $fh;
    return( $self );
}

sub buffer { return( shift->_set_get_scalar_as_object( 'buffer', @_ ) ); }

sub can_read
{
    my $self = shift( @_ );
    my $fh = $self->filehandle;
    my $opts = $self->_get_args_as_hash( @_ );
    return(1) unless( defined( fileno( $fh ) ) );
    return(1) if( $fh->isa( 'IO::Socket::SSL' ) && $fh->pending );
    return(1) if( $fh->isa( 'Net::SSL' ) && $fh->can('pending') && $fh->pending );
    
    # If this is an in-memory scalar filehandle
    # check that it is opened so we can read from it
    if( fileno( $fh ) == -1 )
    {
        if( $self->_can( $fh => 'can_read' ) )
        {
            return( $fh->can_read );
        }
        else
        {
            my( $dummy, $flags );
            if( $self->_can( $fh => 'fcntl' ) )
            {
                $flags = $fh->fcntl( F_GETFL, $dummy );
            }
            else
            {
                $flags = fcntl( $fh, F_GETFL, $dummy );
            }
            return( $self->error({ code => 500, message => "Unable to get flags from filehandle '$fh': $!" }) ) if( !defined( $flags ) );
            return( ( $flags == O_RDONLY ) || ( $flags & ( O_RDONLY | O_RDWR ) ) );
        }
    }

    # With no timeout, wait forever. An explicit timeout of 0 can be used to just check
    # if the socket is readable without waiting.
    my $timeout = $opts->{timeout} ? $opts->{timeout} : $self->timeout;

    my $fbits = '';
    vec( $fbits, fileno( $fh ), 1 ) = 1;
    SELECT:
    {
        my $before;
        $before = time() if( $timeout );
        my $nfound = select( $fbits, undef, undef, $timeout );
        if( $nfound < 0 )
        {
            if( $!{EINTR} || $!{EAGAIN} || $!{EWOULDBLOCK} )
            {
                # don't really think EAGAIN/EWOULDBLOCK can happen here
                if( $timeout )
                {
                    $timeout -= time() - $before;
                    $timeout = 0 if( $timeout < 0 );
                }
                redo( SELECT );
            }
            return( $self->error({ code => 500, message => "select failed: $!" }) );
        }
        return( $nfound > 0 );
    }
}

sub close
{
    my $self = shift( @_ );
    my $fh = $self->filehandle;
    $fh->close if( $self->_can( $fh, 'close' ) );
    $self->filehandle( undef );
    $self->DESTROY;
}

sub connect
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $host = $opts->{host} || return( $self->error( "No host to connect to was provided." ) );
    my $port = $opts->{port} || return( $self->error( "No port to connect to was provided." ) );
    return( $self->error( "Port provided ($port) is not a number" ) ) if( $port !~ /^\d+$/ );
    return( $self->error( "No timeout was provided to connect." ) ) if( !exists( $opts->{timeout} ) || !length( $opts->{timeout} ) );
    my $sock;

    my $stop_if = $self->_is_code( $opts->{stop_if} ) ? $opts->{stop_if} : sub{};
    $opts->{stop_if} = $stop_if;
    my $timeout = $opts->{timeout};
    my( $sock_addr );
    eval
    {
        local $SIG{ALRM} = sub{ die( "timeout\n" ); };
        alarm( $timeout ) if( defined( $timeout ) && $timeout > 0 );
        my $ipbin = Socket::inet_aton( $host ) || 
            return( $self->error( "Cannot resolve host name: ${host} (port: ${port}): $!" ) );
        $sock_addr = Socket::pack_sockaddr_in( $port, $ipbin ) || 
            return( $self->error( "Cannot resolve host name: ${host} (port: ${port}): $!" ) );
        alarm(0);
    };
    return( $self->error( "Failed to resolve host name '$host': timeout" ) ) if( $@ =~ /timeout/i );

    RETRY:
    CORE::socket( $sock, Socket::sockaddr_family( $sock_addr ), SOCK_STREAM, 0 ) ||
        return( $self->error( "Unable to create socket: $!" ) );
    $self->_set_sockopts( $sock ) || return( $self->pass_error );
    my $params = {};
    if( $self->_is_array( $INIT_PARAMS ) )
    {
        for( @$INIT_PARAMS )
        {
            $params->{ $_ } = $opts->{ $_ } if( exists( $opts->{ $_ } ) );
        }
    }
    my $new = $self->new( $sock, $params ) || return( $self->pass_error );
    if( CORE::connect( $sock, $sock_addr ) )
    {
        # connected
    }
    elsif( $! == EINPROGRESS || ( $IS_WIN32 && $! == EWOULDBLOCK ) )
    {
        my $rv = $new->make_select_timeout( write => 1, timeout => $opts->{timeout} );
        return( $self->error( "Cannot connect to ${host}:${port}: ", $new->error->message ) ) if( !defined( $rv ) );
        return( $self->error( "Select timeout on socket." ) ) if( !$rv );
    }
    # connected
    else
    {
        if( $! == EINTR && !$stop_if->() )
        {
            CORE::close( $sock );
            goto( RETRY );
        }
        return( $self->error( "Cannot connect to ${host}:${port}: $!" ) );
    }
    return( $new );
}

# connect SSL socket.
# You can override this method in your child class, if you want to use Crypt::SSLeay or some other library.
# Returns file handle like object
sub connect_ssl
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $host = $opts->{host} || return( $self->error( "No host to connect to was provided." ) );
    my $port = $opts->{port} || return( $self->error( "No port to connect to was provided." ) );
    return( $self->error( "Port provided ($port) is not a number" ) ) if( $port !~ /^\d+$/ );
    return( $self->error( "No timeout was provided to connect." ) ) if( !exists( $opts->{timeout} ) || !length( $opts->{timeout} ) );
    
    $self->_load_class( 'IO::Socket::SSL' ) || return( $self->pass_error );

    my $params = {};
    if( $self->_is_array( $INIT_PARAMS ) )
    {
        for( @$INIT_PARAMS )
        {
            $params->{ $_ } = $opts->{ $_ } if( exists( $opts->{ $_ } ) );
        }
    }
    $params->{host} = $host;
    $params->{port} = $port;
    my $new = $self->connect( %$params ) ||
        return( $self->pass_error );
    my $sock = $new->filehandle;

    my $timeout = $opts->{timeout} // $self->timeout // 5;
    # my $timeout = ( $opts->{timeout} - time() );
    # return( $self->error( "Cannot create SSL connection: timeout" ) ) if( $timeout <= 0 );

    my $ssl_opts = $new->_ssl_opts;
    IO::Socket::SSL->start_SSL(
        $sock,
        PeerHost => $host,
        PeerPort => $port,
        Timeout  => $timeout,
        %$ssl_opts,
    ) or return( $self->error( "Cannot create SSL connection: " . IO::Socket::SSL::errstr() ) );
    $new->_set_sockopts( $sock );
    return( $new );
}

sub connect_ssl_over_proxy
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $proxy_host = $opts->{proxy_host} || return( $self->error( "No proxy host to connect to was provided." ) );
    my $proxy_port = $opts->{proxy_port} || return( $self->error( "No proxy port to connect to was provided." ) );
    my $host = $opts->{host} || return( $self->error( "No host to connect to was provided." ) );
    my $port = $opts->{port} || return( $self->error( "No port to connect to was provided." ) );
    return( $self->error( "Proxy port provided ($proxy_port) is not a number" ) ) if( $proxy_port !~ /^\d+$/ );
    return( $self->error( "Host port provided ($port) is not a number" ) ) if( $port !~ /^\d+$/ );
    return( $self->error( "Port provided ($port) is not a number" ) ) if( $port !~ /^\d+$/ );
    return( $self->error( "No timeout was provided to connect." ) ) if( !exists( $opts->{timeout} ) || !length( $opts->{timeout} ) );
    my $proxy_authorization = $opts->{proxy_authorization};
    $self->_load_class( 'IO::Socket::SSL' ) || return( $self->pass_error );

    my $params = {};
    if( $self->_is_array( $INIT_PARAMS ) )
    {
        for( @$INIT_PARAMS )
        {
            $params->{ $_ } = $opts->{ $_ } if( exists( $opts->{ $_ } ) );
        }
    }
    $params->{host} = $proxy_host;
    $params->{port} = $proxy_port;
    my $new = $self->connect( %$params ) ||
        return( $self->pass_error );
    my $sock = $new->filehandle;

    my $p = "CONNECT ${host}:${port} HTTP/1.0${CRLF}Server: ${host}${CRLF}";
    if( defined( $proxy_authorization ) )
    {
        $p .= "Proxy-Authorization: ${proxy_authorization}${CRLF}";
    }
    $p .= $CRLF;
    $new->_write_all( $sock, $p, $opts->{timeout} ) ||
        return( $self->error({
            code => 500,
            message => "Failed to send HTTP request to proxy: " . ( $! != 0 ? "$!" : 'timeout' )
        }) );
    my $buf = '';
    my $read = $new->read( \$buf, $new->buffer_size, length( $buf ), $opts->{timeout} );
    if( !defined( $read ) )
    {
        return( $self->error( "Cannot read proxy response: " . ( $! != 0 ? "$!" : 'timeout' ) ) );
    }
    # eof
    elsif( $read == 0 )
    {
        return( $self->error( "Unexpected EOF while reading proxy response" ) );
    }
    elsif( $buf !~ /^HTTP\/1\.[0-9] 200 .+\015\012/ )
    {
        return( $self->error( "Invalid HTTP Response via proxy" ) );
    }

    my $timeout = ( $opts->{timeout} - time() );
    return( $self->error( "Cannot start SSL connection: timeout" ) ) if( $opts->{timeout} <= 0 );

    my $ssl_opts = $new->_ssl_opts;
    unless( exists( $ssl_opts->{SSL_verifycn_name} ) )
    {
        $ssl_opts->{SSL_verifycn_name} = $host;
    }
    IO::Socket::SSL->start_SSL(
        $sock,
        PeerHost => "$host",
        PeerPort => "$port",
        Timeout  => "$timeout",
        %$ssl_opts
    ) or return( $self->error( "Cannot start SSL connection: " . IO::Socket::SSL::errstr() ) );
    $new->_set_sockopts( $sock );
    return( $new );
}

sub filehandle { return( shift->_set_get_glob( '_fh', @_ ) ); }

# Credits: Olaf Alders in Net::HTTP
sub getline
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{chomp} = 0 if( !CORE::exists( $opts->{chomp} ) );
    $opts->{max_read_buffer} = 0;
    my $fh = $self->filehandle || return( $self->error( "No filehandle currently set." ) );
    my $buff = $self->buffer;
    my $max  = $opts->{max_read_buffer} || $self->max_read_buffer;
    my $pos;
    my $is_object = $self->_can( $fh => 'sysread' ) ? 1 : 0;
    while(1)
    {
        # Get the position of line ending. \015 might not be there, but \012 will
        $pos = $buff->index( "\012" );
        last if( $pos >= 0 );
        # 413 Entity too large
        return( $self->error({ code => 413, message => "Line too long (limit is $max)" }) ) if( $max && $buff->length > $max );
        # need to read more data to find a line ending
        my $new_bytes = 0;
        READ:
        {
            my $rv = $self->can_read;
            return( $self->pass_error ) if( !defined( $rv ) );
            return( $self->error( "Cannot read from filehandle '$fh'" ) ) if( !$rv );
            # consume all incoming bytes
            my $bytes_read = $is_object
                ? $fh->sysread( $$buff, 1024, $buff->length )
                : sysread( $fh, $$buff, 1024, $buff->length );
            if( defined( $bytes_read ) )
            {
                $new_bytes += $bytes_read;
            }
            elsif( $!{EINTR} || $!{EAGAIN} || $!{EWOULDBLOCK} )
            {
                redo READ;
            }
            else
            {
                $self->mesage( 4, "$bytes_read bytes read from filehandle '$fh' with total read so far of ", $buff->length );
                # if we have already accumulated some data let's at
                # least return that as a line
                $buff->length or return( $self->error( "read() failed: $!" ) );
            }
            # no line-ending, no new bytes
            return(
                $buff->length
                    ? $buff->substr( 0, $buff->length, '' )
                    # : undef
                    : ''
            ) if( $new_bytes == 0 );
        };
    }
    return( $self->error( "Line too long ($pos; limit is $max)" ) ) if( $max && $pos > $max );
    my $line = $buff->substr( 0, $pos + 1, '' );
    # $line =~ s/(\015?\012)\z// || return( $self->error( 'No end-of-line found' ) );
    # return( wantarray() ? ($line, $1) : $line;
    $$line =~ s/(\015?\012)\z// if( $opts->{chomp} );
    return( $$line );
}

sub inactivity_timeout { return( shift->_set_get_number_as_scalar( 'inactivity_timeout', @_ ) ); }

sub last_delimiter { return( shift->_set_get_scalar_as_object( 'last_delimiter', @_ ) ); }

sub make_select
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $fh = $self->filehandle || return( $self->error( "No filehandle set to read from." ) );
    my $timeout = $opts->{timeout} // $self->timeout;
    return( $self->error( 'No timeout was provided.' ) ) if( !defined( $timeout ) );
    my $is_write = $opts->{write} ? 1 : 0;
    my( $rfd, $wfd );
    my $efd = '';
    vec( $efd, fileno( $fh ), 1 ) = 1;
    if( $is_write )
    {
        $wfd = $efd;
    }
    else
    {
        $rfd = $efd;
    }
    my $nfound = select( $rfd, $wfd, $efd, $timeout );
    return( $self->error( $! ) ) if( $nfound < 0 && $! );
    return( $nfound );
}

# returns true if the socket is ready to read, false if timeout has occurred ($! will be cleared upon timeout)
sub make_select_timeout
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $is_write = $opts->{write} ? 1 : 0;
    my $fh = $self->filehandle || return( $self->error( "No filehandle currently set." ) );
    my $timeout;
    $timeout = $opts->{timeout} if( exists( $opts->{timeout} ) && length( $opts->{timeout} ) );
    $timeout //= $self->timeout;
    my $timeout_at = time() + $timeout;
    return( $self->error( "No timeout option was provided nor is it defined with timeout()." ) ) if( !defined( $timeout ) );
    # Time::HiRes time()
    my $now = time();
    my $inactivity_timeout = $self->inactivity_timeout // $opts->{inactivity_timeout} // 600;
    my $inactivity_timeout_at = ( $now + $inactivity_timeout );
    $timeout_at = $inactivity_timeout_at if( $timeout_at > $inactivity_timeout_at );
    my $stop_if = $self->stop_if;
    # wait for data
    while(1)
    {
        my $timeout2 = ( $timeout_at - $now );
        if( $timeout2 <= 0 )
        {
            $! = 0;
            return(0);
        }
        my $nfound = $self->make_select( write => $is_write, timeout => $timeout2 );
        return( $self->pass_error ) if( !defined( $nfound ) );
        return(1) if( $nfound > 0 );
        return(0) if( $nfound == -1 && $! == EINTR && $stop_if->() );
        # Time::HiRes time()
        $now = time();
    }
    return( $self->error( 'Error checking for readiness of socket. Should not get here.' ) );
}

# Maximum size of read buffer, beyond which, if still nothing is found, then we give up
sub max_read_buffer { return( shift->_set_get_number_as_scalar( 'max_read_buffer', @_ ) ); }

sub print { return( defined( shift->write( @_ ) ) ? 1 : 0 ); }

sub read
{
    my $self = $_[0];
    return( $self->error({ code => 500, message => "Wrong number of arguments. Usage: \$reader->read( \$buffer, \$length, \$offset )" }) ) unless( @_ > 2 && @_ < 5 );
    my $len = $_[2];
    return( $self->error( "Length provided (${len}) is not a positive integer." ) ) if( !defined( $len ) || $len !~ /^\d+$/ );
    my $off = $_[3];
    return( $self->error( "Offset provided (${off}) is not an integer." ) ) if( defined( $off ) && $off !~ /^-?\d+$/ );
    my $is_scalar = $self->_is_scalar( $_[1] ) ? 1 : 0;
    return( $self->error( "scalar provided as first argument to read() is a reference (", overload::StrVal( $_[1] ), "). You need to first dereference it." ) ) if( ref( $_[1] ) && !$is_scalar );
    $off //= 0;
    my $fh  = $self->filehandle || return( $self->error( "No filehandle set to read from." ) );
    my $buff = $self->buffer;
    my $buff_len = $buff->length->scalar;
    my $is_object = $self->_can( $fh => 'sysread' ) ? 1 : 0;
    my $stop_if = $self->stop_if;
    
    my $sysread = sub
    {
        while(1)
        {
            my $n = $is_object
                ? $fh->sysread( $_[0], $_[1], ( @_ > 2 ? $_[2] : () ) )
                : sysread( $fh, $_[0], $_[1], ( @_ > 2 ? $_[2] : () ) );
            if( defined( $n ) )
            {
                return( $n );
            }
    
            if( $! == EAGAIN || $! == EWOULDBLOCK || ( $IS_WIN32 && $! == EISCONN ) )
            {
                # passthru
            }
            elsif( $! == EINTR )
            {
                return( $self->error({ code => $!+0, message => "Received interruption signal: $!" }) ) if( $stop_if->() );
                # otherwise passthru
            }
            else
            {
                return( $self->error({ code => $!+0, message => "Unable to read from filehandle: $!" }) );
            }
            # on EINTER/EAGAIN/EWOULDBLOCK
            my $rv = $self->make_select_timeout( write => 0 );
            return( $self->pass_error ) if( !defined( $rv ) );
            return( $self->error( "Unable to select the filehandle." ) ) if( !$rv );
        }
    };
    
    if( $buff_len )
    {
        # if our buffer is less than that is required, attempt to read the difference from the filehandle
        if( $buff_len < $len )
        {
            return( $self->pass_error ) unless( defined( $self->can_read ) );
            my $n = $sysread->( $$buff, ( $len - $buff_len ), $buff_len );
            return( $self->pass_error ) if( !defined( $n ) );
        }
        
        # What we will return
        my $bytes = ( $buff->length > $len ? $len : $buff->length );
        # "A positive OFFSET greater than the length of SCALAR results in the string being 
        # padded to the required size with "\0" bytes before the result of the read is 
        # appended."
        # (perlfunc)
        if( $is_scalar )
        {
            if( $off > length( $$_[1] ) )
            {
                $$_[1] .= \0 x ( $off - length( $$_[1] ) );
            }
            substr( $$_[1], $off, 0, $buff->substr( 0, $bytes, '' )->scalar );
            # Truncate
            substr( $$_[1], ( $off + $bytes ), length( $$_[1] ), '' );
        }
        else
        {
            if( $off > length( $_[1] ) )
            {
                $_[1] .= \0 x ( $off - length( $_[1] ) );
            }
            substr( $_[1], $off, 0, $buff->substr( 0, $bytes, '' )->scalar );
            # Truncate
            substr( $_[1], ( $off + $bytes ), length( $_[1] ), '' );
        }
        return( $bytes );
    }
    else
    {
        return( $sysread->( $_[1], $len, ( defined( $off ) ? $off : () ) ) );
    }
}

sub read_until
{
    my $self = $_[0];
    return( $self->error({ code => 500, message => "Wrong number of arguments. Usage: \$reader->read_until( \$buffer, \$length, \$offset, { string => 'something', exclude => 1, include => 1, chunk_size => 2048 } )" }) ) unless( @_ > 2 );
    my $len = $_[2];
    return( $self->error( "Length provided (${len}) is not an integer." ) ) if( $len !~ /^\d+$/ );
    return( $self->error( "scalar provided as first argument to read_until() is a reference (", overload::StrVal( $_[1] ), "). You need to first dereference it." ) ) if( ref( $_[1] ) );
    my $off = ( $_[3] =~ /^\-?\d+$/ ? $_[3] : 0 );
    my $opts = {};
    $opts = $_[-1] if( ref( $_[-1] ) eq 'HASH' );
    my $what = $opts->{string};
    return( $self->error({ code => 500, message => "Nothing was provided to look for." }) ) if( !defined( $what ) || !CORE::length( $what ) );
    $what = qr/\Q${what}\E/ unless( ref( $what ) eq 'Regexp' );
    my $fh = $self->filehandle || return( $self->error( "No filehandle set to read from." ) );
    $opts->{ignore} //= 0;
    $opts->{exclude} = 0 if( !exists( $opts->{exclude} ) );
    $opts->{inlude} = !$opts->{exclude} if( !exists( $opts->{include} ) );
    # Should we capture the delimiter?
    # This is useful for debugging, or in case of boundary for HTTP message multipart to know
    # if we have reached the trailing delimiter for example.
    $opts->{capture} //= 0;
    my $re;
    if( $opts->{ignore} )
    {
        $re = $opts->{capture} ? qr/(.*?)(?<__reader_delimiter>${what})/s : qr/(.*?)${what}/s;
    }
    elsif( $opts->{include} )
    {
        $re = $opts->{capture} ? qr/((?:.*?)(?<__reader_delimiter>${what}))/s : qr/((?:.*?)${what})/s;
    }
    else
    {
        $re = qr/(.*?)(?=${what})/s;
    }
    my $chunk_size = $opts->{chunk_size} // 2048;
    $chunk_size = $len if( $len > $chunk_size );
    my $buff = $self->buffer;
    my $n = -1;
    my $sliding_buffer_size = $chunk_size * 2;
    my $is_object = $self->_can( $fh => 'sysread' ) ? 1 : 0;
    my $buff_len = $buff->length->scalar;
    my $stop_if = $self->stop_if;
    if( !$buff_len || $$buff !~ /$re/ )
    {
        if( $buff_len < $sliding_buffer_size )
        {
            return( $self->pass_error ) unless( defined( $self->can_read ) );
            while(1)
            {
                my $n = $is_object
                    ? $fh->sysread( $$buff, ( $sliding_buffer_size - $buff_len ), $buff_len )
                    : sysread( $fh, $$buff, ( $sliding_buffer_size - $buff_len ), $buff_len );
                if( !defined( $n ) )
                {
                    if( $! == EAGAIN || $! == EWOULDBLOCK || ( $IS_WIN32 && $! == EISCONN ) )
                    {
                        # passthru
                    }
                    elsif( $! == EINTR )
                    {
                        return( $self->error({ code => $!+0, message => "Received interruption signal: $!" }) ) if( $stop_if->() );
                        # otherwise passthru
                    }
                    else
                    {
                        return( $self->error({ code => $!+0, message => "Unable to read from filehandle: $!" }) );
                    }
                    # on EINTER/EAGAIN/EWOULDBLOCK
                    my $rv = $self->make_select_timeout( write => 0 );
                    return( $self->pass_error ) if( !defined( $rv ) );
                    return( $self->error( "Unable to select the filehandle." ) ) if( !$rv );
                }
                # 0, meaning there is no more data to read
                # If our buffer still has some data, we'll return whatever we have left
                elsif( !$n && $buff->is_empty )
                {
                    return( $n );
                }
                else
                {
                    last;
                }
            }
        }
    }
    
    $_[1] //= '';
    # "A positive OFFSET greater than the length of SCALAR results in the string being 
    # padded to the required size with "\0" bytes before the result of the read is 
    # appended."
    # (perlfunc)
    if( $off > length( $_[1] ) )
    {
        $_[1] .= \0 x ( $off - length( $_[1] ) );
    }
    
    if( $$buff =~ s/^$re// )
    {
        my $trail = $1;
        if( exists( $+{__reader_delimiter} ) )
        {
            $self->last_delimiter( $+{__reader_delimiter} );
        }
        else
        {
            $self->last_delimiter->reset;
        }
        my $bytes = length( $trail );
        substr( $_[1], $off, 0, $trail );
        # Truncate
        substr( $_[1], ( $off + $bytes ), length( $_[1] ), '' );
        # < 0 means in our API there is a match and this is what was returned.
        # The caller can simply use abs() to get the bytes value.
        # 0 means no more data, and 
        # undef means there is an error
        # > 0 is returned when no match was found, but only data
        return( $bytes * -1 );
    }
    else
    {
        my $bytes = $buff->length > $len ? $len : $buff->length;
        substr( $_[1], $off, 0, $buff->substr( 0, $bytes, '' ) );
        # Truncate
        substr( $_[1], ( $off + $bytes ), length( $_[1] ), '' );
        return( $bytes );
    }
}

sub read_until_in_memory
{
    my $self = shift( @_ );
    my $what = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error({ code => 500, message => "Nothing was provided to look for." }) ) if( !defined( $what ) || !CORE::length( $what ) );
    $what = qr/\Q${what}\E/ unless( ref( $what ) eq 'Regexp' );
    $opts->{ignore} //= 0;
    $opts->{exclude} = 0 if( !exists( $opts->{exclude} ) );
    $opts->{inlude} = !$opts->{exclude} if( !exists( $opts->{include} ) );
    # Should we capture the delimiter?
    # This is useful for debugging, or in case of boundary for HTTP message multipart to know
    # if we have reached the trailing delimiter for example.
    $opts->{capture} //= 0;
    my $re;
    if( $opts->{ignore} )
    {
        $re = $opts->{capture} ? qr/(.*?)(?<__reader_delimiter>${what})/s : qr/(.*?)${what}/s;
    }
    elsif( $opts->{include} )
    {
        $re = $opts->{capture} ? qr/((?:.*?)(?<__reader_delimiter>${what}))/s : qr/((?:.*?)${what})/s;
    }
    else
    {
        $re = qr/(.*?)(?=${what})/s;
    }
    my $chunk_size = $opts->{chunk_size} // 2048;
    my $max = $self->max_read_buffer;
    my $buff = '';
    while( $buff !~ /$re/ )
    {
        my $n = $self->read( $buff, $chunk_size, CORE::length( $buff ) );
        return( $self->pass_error ) if( !defined( $n ) );
        return( '' ) if( !$n );
        
        if( $max && CORE::length( $buff ) > $max )
        {
            $self->unread( $buff );
            return( $self->error({ code => 413, message => "Maximum read buffer limit ($max) reached." }) );
        }
    }
    if( $buff =~ s/^$re// )
    {
        my $match = $1;
        if( exists( $+{__reader_delimiter} ) )
        {
            $self->last_delimiter( $+{__reader_delimiter} );
        }
        else
        {
            $self->last_delimiter->reset;
        }
        $self->unread( $buff );
        return( $match );
    }
    else
    {
    }
    $self->unread( $buff );
    return( '' );
}

# NOTE: request parameter
sub ssl_opts { return( shift->_set_get_hash_as_mix_object( 'ssl_opts', @_ ) ); }

sub stop_if { return( shift->_set_get_code( 'stop_if', @_ ) ); }

# sub timeout { return( shift->_set_get_number_as_scalar( 'timeout', @_ ) ); }
sub timeout
{
    my $self = shift( @_ );
    $self->{timeout} = shift( @_ ) if( @_ );
    return( $self->{timeout} );
}

sub unread
{
    my $self = shift( @_ );
    my $buff = $self->buffer;
    if( $buff->is_empty )
    {
        $buff->set( shift( @_ ) );
    }
    else
    {
        $buff->prepend( shift( @_ ) );
    }
    return( $self );
}

# returns (positive) number of bytes written, or undef if the filehandle is to be closed
sub write
{
    my $self = $_[0];
    return( $self->error( "Invalid number of arguments. Usage: \$self->write( \$buffer, \$length, \$offset )" ) ) unless( @_ > 1 && @_ < 6 );
    # Buffer is #1
    my $len = @_ > 2 ? $_[2] : length( $_[1] );
    my $off = @_ > 3 ? $_[3] : 0;
    my $timeout = @_ > 4 ? $_[4] : $self->timeout;
    my $fh = $self->filehandle || return( $self->error( "No filehandle set to read from." ) );
    my $is_object = $self->_can( $fh => 'syswrite' ) ? 1 : 0;
    while(1)
    {
        my $bytes = $is_object
            ? $fh->syswrite( $_[1], $len, $off )
            : syswrite( $fh, $_[1], $len, $off );
        if( defined( $bytes ) )
        {
            return( $bytes );
        }
        if( $! == EAGAIN || $! == EWOULDBLOCK || ( $IS_WIN32 && $! == EISCONN ) )
        {
            # passthru
        }
        # Could not write because of an interruption
        elsif( $! == EINTR )
        {
            return( $self->error({ code => ERROR_EINTR, message => "Interruption prevented writing to filehandle '$fh': $!" }) ) if( $self->stop_if->() );
            # otherwise passthru
        }
        else
        {
            return( $self->error( "Error writing ${len} bytes at offset ${off} from buffer (size: ", length( $_[2] ), " bytes) to filehandle '$fh': $!" ) );
        }
        my $rv = $self->make_select_timeout( write => 1, timeout => $timeout );
        return( $self->pass_error ) if( !defined( $rv ) );
        return( $self->error( "Unable to select the filehandle." ) ) if( !$rv );
    }
}

sub write_all
{
    my $self = $_[0];
    return( $self->error( "Invalid number of arguments. Usage: \$self->_write_all( \$buffer )" ) ) unless( @_ > 1 && @_ < 4 );
    # Buffer is #1
    my $timeout = @_ > 2 ? $_[2] : $self->timeout;
    my $off = 0;
    while( my $len = length( $_[1] ) - $off )
    {
        my $bytes = $self->write( $_[1], $len, $off, $timeout );
        return( $self->pass_error ) if( !defined( $bytes ) );
        return( $bytes ) if( !$bytes );
        $off += $bytes;
        # Should never happen
        last if( $len < 0 );
    }
    # Return total bytes sent
    return( $off );
}

sub _set_sockopts
{
    my $self = shift( @_ );
    my $sock = shift( @_ ) ||
        return( $self->error( "No socket was provided." ) );

    setsockopt( $sock, IPPROTO_TCP, TCP_NODELAY, 1 ) or
        return( $self->error( "Failed to setsockopt(TCP_NODELAY): $!" ) );
    if( $IS_WIN32 )
    {
        if( ref( $sock ) ne 'IO::Socket::SSL' )
        {
            my $tmp = 1;
            ioctl( $sock, 0x8004667E, \$tmp ) or
                return( $self->error( "Cannot set flags for the socket: $!" ) );
        }
    }
    else
    {
        my $flags = fcntl( $sock, F_GETFL, 0 ) or
            return( $self->error( "Cannot get flags for the socket: $!" ) );
        $flags = fcntl( $sock, F_SETFL, $flags | O_NONBLOCK ) or
            return( $self->error( "Cannot set flags for the socket: $!" ) );
    }

    {
        # no buffering
        my $orig = select();
        select( $sock ); $| = 1;
        select( $orig );
    }
    binmode( $sock );
    return( $sock );
}

sub _ssl_opts
{
    my $self = shift( @_ );
    my $ssl_opts = $self->ssl_opts;
    unless( exists( $ssl_opts->{SSL_verify_mode} ) )
    {
        # set SSL_VERIFY_PEER as default.
        $ssl_opts->{SSL_verify_mode} = IO::Socket::SSL::SSL_VERIFY_PEER();
        unless( exists( $ssl_opts->{SSL_verifycn_scheme} ) )
        {
            $ssl_opts->{SSL_verifycn_scheme} = 'www'
        }
    }
    if( $ssl_opts->{SSL_verify_mode} )
    {
        unless( exists( $ssl_opts->{SSL_ca_file} ) || exists( $ssl_opts->{SSL_ca_path} ) )
        {
            $self->_load_class( 'Mozilla::CA' ) || return( $self->pass_error );
            $ssl_opts->{SSL_ca_file} = Mozilla::CA::SSL_ca_file();
        }
    }
    return( $ssl_opts );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::IO - I/O Handling Class for HTTP::Promise

=head1 SYNOPSIS

    use HTTP::Promise::IO;
    my $this = HTTP::Promise::IO->new( $fh ) || 
        die( HTTP::Promise::IO->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class implements a filehandle reader and writer with a twist.

First off, it does not rely on lines, since data stream or in general data from HTTP requests and responses do not necessarily always contain lines. Binary data are sent without necessarily any line at all.

Second, it is easy on memory by implementing L</read>, which uses a shared L</buffer>, and you can use L</unread> to return data to it (they would be prepended).

Last, but not least, it implements 2 methods to read in chunks of data from the filehandle until some string pattern specified is found: L</read_until> and L</read_until_in_memory>

=head1 CONSTRUCTOR

=head2 new

This takes a proper filehandle and will ensure the C<O_NONBLOCK> bit is set, so that it can timeout if there is no more data streamed from the filehandle.

It returns the newly instantiated object upon success, and upon error, sets an L<error|Module::Generic/error> and return C<undef>

Possible optional parameters are:

=over 4

=item C<buffer>

You can pass some data that will set the initial read buffer, from which other methods in this class access before reading from the filehandle.

=item C<max_read_buffer>

An integer. You can set this a default value for the maximum size of the read buffer.

This is used by L</getline> and L</read_until_in_memory> to limit how much data can be read into the buffer until it returns an error. Hopefully a line or a match specified with C<read_until> would be found and returned before this limit is reached.

If this is greater than 0 and the amount of data loaded exceeds this limit, and error is returned.

=item C<timeout>

AN integer. This is the read timeout. It defaults to 10.

=back

=head1 METHODS

=head2 buffer

Sets or gets the buffer.

This is used by those class methods to get leftover data from the buffer, if any, or from the filehandle if necessary.

This returns a L<scalar object|Module::Generic::Scalar>

=head2 can_read

Returns true if it can read from the filehandle or false otherwise.

It takes an optional hash or hash reference of options, of which, C<timeout> is the only one.

=head2 close

Close the filehandle and destroys the current object.

=head2 connect

Provided with an hash or hash reference of options and this will connect to the remote server.

It returns a new L<HTTP::Promise::IO> object, or upon error, it sets an L<error|Module::Generic/error> and returns C<undef>

Supported options are:

All the options used for object instantiation. See L</CONSTRUCTOR> and the following ones:

=over 4

=item * C<debug>

Integer representing the level of debug.

=item * C<host>

The remote host to connect to.

=item * C<port>

An integer representing the remote port to connect to.

=item * C<stop_if>

A code reference that serves as a callback and that is called where there is an C<EINTR> error. If the callback returns true, the connection attempts stop there and returns an error. This default to return false.

=item * C<timeout>

An integer or a decimal representing a timeout to be used when resolving the host, or when making remote connection.

=back

=head2 connect_ssl

This takes the same options has L</connect>, but performs an SSL connection.

Like L</connect>, this returns a new L<HTTP::Promise::IO> object, or upon error, it sets an L<error|Module::Generic/error> and returns C<undef>

=head2 connect_ssl_over_proxy

Provided with an hash or hash reference of options and this will connect to the remote server.

It returns a new L<HTTP::Promise::IO> object, or upon error, it sets an L<error|Module::Generic/error> and returns C<undef>

Supported options are:

All the options used for object instantiation. See L</CONSTRUCTOR> and the following ones:

=over 4

=item * C<debug>

Integer representing the level of debug.

=item * C<host>

The remote host to connect to.

=item * C<port>

An integer representing the remote port to connect to.

=item * C<proxy_authorization>

The proxy authorisation string to use for authentication.

=item * C<proxy_host>

The remote proxy host to connect to.

=item * C<proxy_port>

An integer representing the remote proxy port to connect to.

=item * C<stop_if>

A code reference that serves as a callback and that is called where there is an C<EINTR> error. If the callback returns true, the connection attempts stop there and returns an error. This default to return false.

=item * C<timeout>

An integer or a decimal representing a timeout to be used when resolving the host, or when making remote connection.

=back

=head2 filehandle

Sets or gets the filehandle being used. This is the same filehandle that was passed upon object instantiation.

=head2 getline

Reads from the buffer, if there is enough data left over, or from the filehandle and returns the first line found.

A line is a string that ends with C<\012> which is portable and universal. This would be the equivalent of C<\n>.

It returns the line found, if any, or C<undef> if there was an error that you can retrieve with L<error|Module::Generic/error>.

it takes an optional hash or hash reference of options:

=over 4

=item C<chomp>

If true, this will chomp any trailing sequence of C<\012> possibly preceded by C<\015>

=item C<max_read_buffer>

An integer that limits how much cumulative data can be read until it exceeds this allowed maximum. When that happens, an error is returned.

=back

=head2 inactivity_timeout

Integer representing the amount of second to wait until a connection is deemed idle and closed.

=head2 last_delimiter

Sets or gets the last delimiter found. A delimiter is some pattern that is provided to L</read_until> and L</read_until_in_memory> with the option C<capture> set to a true value.

This returns the last delimited found as a L<scalar object|Module::Generic::Scalar>

=head2 make_select

Provided with an hash or hash reference of options and this L<perlfunc/select> the filehandle or socket using the C<timeout> provided.

It returns a positive integer upon success, and upon error, this sets an L<error|Module::Generic/error> and returns C<undef>.

Supported options are:

=over 4

=item * C<timeout>

Integer representing the timeout.

=item * C<write>

Boolean. When true, this will check the filehandle or socket for write capability, or if false for read capability.

=back

=head2 make_select_timeout

This takes the same options as L</make_select>, and it will retry selecting the filehandle or socket until success or a timeout occurs. If an C<EINTR> error occurs, it will query the callback provided with L</stop_if>. If the callback returns true, it will return an error, or keep trying otherwise.

Returns true upon success, and upon error, this sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 max_read_buffer

Sets or gets the maximum bytes amount of the read buffer.

This is used by L</getline> and L</read_until_in_memory> to limit how much data can be read into the buffer until it returns an error. Hopefully a line or a match specified with C<read_until> would be found and returned before this limit is reached.

If this is greater than 0 and the amount of data loaded exceeds this limit, and error is returned.

=head2 print

Provided with some data to print to the underlying filehandle or socket, and this will call L</write> and return true upon success, or false otherwise.

=head2 read

    my $bytes = $r->read( $buffer, $length );
    my $bytes = $r->read( $buffer, $length, $offset );

This reads C<$length> bytes from either the internal buffer if there are leftover data, or the filehandle, or even both if the internal buffer is not big enough to meet the C<$length> requirement.

It returns how many bytes actually were loaded into the caller's C<$buffer>. It returns C<undef> after having set an L<error|Module::Generic/error> if an error occurred.

Just like the perl core L<perlfunc/read> function, this one too will pad with C<\0> the caller's buffer if the offset specified is greater than the actual size of the caller's buffer.

Note that there is no guarantee that you can read from the filehandle the desired amount of bytes in just one time, especially if the filehandle is a socket, so you may need to do:

    my $bytes;
    my $total_to_read = 102400;
    my $total_bytes;
    while( $bytes = $r->read( $buffer, $chunk_size ) )
    {
        $out-print( $buffer ) || die( $! );
        # If you want to make sure you do not read more than necessary, otherwise, you can discard this line
        $chunk_size = ( $total_to_read - $total_bytes ) if( ( $total_bytes < $total_to_read ) && ( ( $total_bytes + $chunk_size ) > $total_to_read ) );
        $total_bytes += $bytes;
        last if( $total_bytes == $total_to_read );
    }
    # Check if something bad happened
    die( "Something wrong happened: ", $r->error ) if( !defined( $bytes ) );

=head2 read_until

    my $bytes = $r->read_until( $buffer, $length, $options_hashref );
    my $bytes = $r->read_until( $buffer, $length, $offset, $options_hashref );

This is similar to L</read>, but will read data from either the buffer, the filehandle or a combination of both until the specified C<string>, passed as an option, is found.

It loads data in chunks specified with the option C<chunk_size> or by default 2048 bytes. If the specified string is not found within that buffer, it returns how many bytes where read and sets the caller's buffer with the data collected.

Upon the last call when the C<string> is finally found, this will return the number of bytes read, but as a negative number. This will tell you it has found the match. You can consider the number is negative because those are the last n bytes.

When no more data at all can be read, this will return 0.

If an error occurred, this will set an L<error|Module::Generic/error> and return C<undef>

The possible options that can be passed as an hash reference B<only> are:

=over 4

=item C<capture>

Boolean. When set to true, this will capture the match specified with C<string>. The resulting would then be retrievable using L</last_delimiter>

=item C<chunk_size>

An integer. This is the maximum bytes this will read per each iteration.

=item C<exclude>

Boolean. If this is true, this will exclude the C<string> sought from the buffer allocation.

=item C<include>

Boolean. If this is true, this will set the buffer including the C<string> sought after.

=item C<string>

This is the C<string> to read data until it is found. The C<string> can be a simple string, or a regular expression.

=back

=head2 read_until_in_memory

    my $data = $r->read_until_in_memory( $string );
    my $data = $r->read_until_in_memory( $string, $options_hash_or_hashref );
    die( "Error: ", $r->error ) if( !defined( $data ) );

Provided with a C<string> to be found, this will load data from the internal buffer, the filehandle, or a combination of both into memory until the specified C<string> is found.

Upon success, it returns the data read, which could be an empty string if nothing matched.

If an error occurred, this will set an L<error|Module::Generic/error> and return C<undef>.

It takes the following possible options, either as an hash or hash reference:

=over

=item C<capture>

Boolean. When set to true, this will capture the match specified with C<string>. The resulting would then be retrievable using L</last_delimiter>

=item C<chunk_size>

An integer. This is the maximum bytes this will read per each iteration.

=item C<exclude>

Boolean. If this is true, this will exclude the C<string> sought from the buffer allocation.

=item C<include>

Boolean. If this is true, this will set the buffer including the C<string> sought after.

=back

=head2 ssl_opts

Sets or gets an hash reference of ssl options to be used with L<IO::Socket::SSL/start_SSL>

=head2 stop_if

Sets or gets a code reference acting as a callback when an error C<EINTR> if encountered. If the callback returns true, the method using it, will stop and return an error, otherwise, it will keep trying.

=head2 timeout

Sets or gets the timeout threshold. This returns a L<number object|Module::Generic::Number>

=head2 unread

Provided with some data and this will put it back into the internal buffer, at its beginning.

This returns the current object for chaining.

=head2 write

This write to the filehandle set, and takes a buffer to write, an optional length, an optional offset, and an optional timeout value.

If no length is provided, this default to the length of the buffer.

If no offset is provided, this default to C<0>.

If no timeout is provided, this default to the value set with L</timeout>

It returns the number of bytes written or, upon error, sets an L<error|Module::Generic/error> and returns C<undef>

=head2 write_all

Provided with some data an an optional timeout, and this will write the data to the filehandle set.

It returns the number of bytes written or, upon error, sets an L<error|Module::Generic/error> and returns C<undef>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
