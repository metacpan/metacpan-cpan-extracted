=head1 NAME

DynGig::Multiplex::TCP - Multiplexed TCP Client

=cut
package DynGig::Multiplex::TCP;

use warnings;
use strict;
use Carp;

use Fcntl;
use Socket;
use Errno qw( :POSIX );
use Time::HiRes qw( time sleep );
use IO::Poll 0.04 qw( POLLIN POLLERR POLLHUP POLLOUT );

use constant { MAX_BUF => 2 ** 20, MULTIPLEX => 2 ** 5 }; 

=head1 SYNOPSIS
 
 use DynGig::Multiplex::TCP;

 ## imagine these servers are echo servers ..

 my @server = qw( host:port /unix/domain/socket ... );
 my %config = ( timeout => 30, buffer => 'bob loblaw' );
 my $client = DynGig::Multiplex::TCP->new( map { $_ => \%config } @server );

 my %option =
 (
     timeout => 300,     ## global timeout in seconds
     max_buf => 1024,    ## max number of bytes in each read buffer
     multiplex => 100,   ## max number of threads
     index => 'forward'  ## index results/errors by server
     verbose => *STDERR  ## report progress to STDERR
 );

 if ( $client->run( %option ) )
 {
     my $result = $client->result() || {};
     my $error = $client->error() || {};
 }
 else
 {
     print $client->error();
 }

=cut
sub new
{
    my ( $class, %config ) = @_;
    my ( %done, %host, %addr );

    for my $server ( keys %config )
    {
        my $error = "$server: invalid definition"; 

        croak "$error - duplicate server" if $addr{$server};

        if ( my ( $host, $port ) = $server =~ /^([^:]+):(\d+)$/o )
        {
            croak "$error for port" unless $port && ! ref $port
                && $port =~ /^\d+$/o && $port < 65536;

            for( 0..1 )
            {
                $host{$host} = inet_aton $host;
                last if defined $host{$host};
                sleep 0.2;
            }
            croak "$error for host $!" unless defined $host{$host};

            croak "$error for host:port"
                unless $addr{$server}[0] = sockaddr_in( $port, $host{$host} );

            $addr{$server}[1] = PF_INET;
        }
        else
        {
            croak "$error for unix domain socket"
                unless File::Spec->file_name_is_absolute( $server )
                    && ( $addr{$server}[0] = sockaddr_un( $server ) );

            $addr{$server}[1] = PF_UNIX;
        }

        my $config = $config{$server};

        next if $done{$config};
        croak $error unless $config && ref $config eq 'HASH';

        my $timeout = $config->{timeout};
        my $buffer = $config->{buffer};

        croak "$error for timeout"
            if $timeout && ( ref $timeout || $timeout !~ /^\d+$/o );

        croak "$error for buffer" if $buffer && ref $buffer;

        $config->{buffer} = '' unless defined $buffer;
        $config->{length} = length $config->{buffer};
        $done{$config} = 1;
    }

    bless +{ config => \%config, addr => \%addr }, ref $class || $class;
}

=head1 DESCRIPTION

=head2 run

Launches client with the following parameter.
Returns 1 if successful. Returns 0 otherwise.

 index     : index results/errors by server if set to 'forward'
 timeout   : global timeout in seconds
 max_buf   : max number of bytes in each read buffer
 multiplex : max number of threads
 verbose   : report progress to a file handle opened for write.

=cut
sub run
{
    my ( $this, %param ) = @_;
    my $config = $this->{config};

    return 1 unless my @server = keys %$config;

    map { delete $this->{$_} } qw( result error );

    for my $key ( qw( timeout max_buf multiplex ) )
    {
        my $value = $param{$key};
        croak "invalid definition for $key"
            if $value && ( ref $value || $value !~ /^\d+$/o );
    }

    my $poll = IO::Poll->new();

    unless ( $poll )
    {
        $this->{error} = "poll: $!";
        return 0;
    }

    my $inverted = $param{index} && $param{index} eq 'forward' ? 0 : 1;
    my $index = sub
    {
        my $hash = shift;

        if ( $inverted )
        {
            push @{ $hash->{ $_[0] } }, $_[1];
        } 
        else
        {
            $hash->{ $_[1] } = $_[0];
        }
    };

    my %mask =
    (
       in => POLLIN | POLLHUP | POLLERR,
       io => POLLIN | POLLOUT,
       out => POLLOUT,
    );

    my $addr = $this->{addr};
    my $timeout = $param{timeout};
    my $verbose = $param{verbose};
    my $multiplex = $param{multiplex} || MULTIPLEX;
    my $max_buf = $param{max_buf} || MAX_BUF;
    my ( %error, %result, %lookup );
    my $epoch = time;
    my $current = 0;

    $multiplex = @server if $multiplex > @server;
    $verbose = 0 unless $verbose && fileno $verbose && -w $verbose;

    while ( $poll->handles || @server )
    {
        my $time = time;

        if ( $timeout && $time - $epoch > $timeout )
        {
            $this->{error} = 'timeout';
            return 0;
        }

        while ( $current < $multiplex && @server )
        {
            my $server = shift @server;
            my $config = $config->{$server};
            my $addr = $addr->{$server};
            my $socket;

            unless ( socket $socket, $addr->[1], SOCK_STREAM, 0 )
            {
                &$index( \%error, "socket $!", $server );
                next;
            }

            my $flag = fcntl $socket, F_GETFL, 0;

            unless ( $flag && fcntl $socket, F_SETFL, $flag | O_NONBLOCK )
            {
                &$index( \%error, "fcntl $!", $server );
                next;
            }

            for ( 0..1 )
            {
                connect( $socket, $addr->[0] );
                last if $socket;
                sleep 0.2;
            }

            unless ( $socket )
            {
                &$index( \%error, "connect $!", $server );
                next;
            }

            $lookup{server}{$server} = +
            {
                socket => $socket,
                epoch => $time,
            };

            $lookup{socket}{$socket} = +
            {
                server => $server,
                read => '',
                write => \ $config->{buffer},
                length => $config->{length},
                offset => 0,
            };

            $current ++;
            $poll->mask( $socket => $mask{io} );
        }

        $poll->poll( 0.1 );

        for my $socket ( $poll->handles( $mask{in} ) )
        {
            my $buffer;
            my $lookup = $lookup{socket}{$socket};
            my $read = sysread $socket, $buffer, $max_buf;

            if ( $read )
            {
                $lookup->{read} .= $buffer;
                next;
            }

            my $server = $lookup->{server};

            if ( defined $read )
            {
                &$index( \%result, $lookup->{read}, $server );
            }
            else
            {
                next if $! == EAGAIN;
                &$index( \%error, "sysread: $!", $server );
            }

            delete $lookup{server}{$server};
            delete $lookup{socket}{$socket};

            $poll->remove( $socket );
            shutdown $socket, 0;
            $current --;

            print $verbose "$server complete.\n" if $verbose;
        }

        for my $socket ( $poll->handles( $mask{out} ) )
        {
            my $lookup = $lookup{socket}{$socket};
            my $length = $lookup->{length};
            my $wrote = syswrite $socket, ${ $lookup->{write} },
                $length, $lookup->{offset};

            if ( defined $wrote )
            {
                next if $length != ( $lookup->{offset} += $wrote );
            }
            else
            {
                next if $! == EAGAIN;
                &$index( \%error, "syswrite: $!", $lookup->{server} );
            }

            $poll->mask( $socket, $poll->mask( $socket ) & ~POLLOUT );
            shutdown $socket, 1;
        }

        for my $server ( keys %{ $lookup{server} } )
        {
            my $timeout = $config->{$server}{timeout};
            my $lookup = $lookup{server}{$server};

            next if ! $timeout || $timeout > $time - $lookup->{epoch};

            my $socket = $lookup->{socket};
            &$index( \%error, 'timeout', $server );

            delete $lookup{server}{$server};
            delete $lookup{socket}{$socket};

            $poll->remove( $socket );
            shutdown $socket, 2;
            $current --;

            print $verbose "$server timeout.\n" if $verbose;
        }
    }

    $this->{result} = \%result if %result;
    $this->{error} = \%error if %error;

    return 1;
}

=head2 result()

Returns undef if no result. Returns a HASH reference indexed either
by server or by result (see the I<index> parameter of run().)

=cut
sub result
{
    my $this = shift;
    return $this->{result};
}

=head2 error()

Returns undef if no error.
Returns a string if a global error occurred, else if errors occurred with
individual client/server connections, returns a HASH reference indexed either
by server or by result. (see the I<index> parameter of run().)


=cut
sub error
{
    my $this = shift;
    return $this->{error};
}

=head1 SEE ALSO

Socket and IO::Poll

=head1 NOTE

See DynGig::Multiplex

=cut

1;

__END__
