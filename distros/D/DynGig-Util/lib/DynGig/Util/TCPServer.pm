=head1 NAME

DynGig::Util::TCPServer - A generic multithreaded TCP Server interface.

=cut
package DynGig::Util::TCPServer;

use warnings;
use strict;
use Carp;

use threads;
use Thread::Queue 2.11;

use Socket;
use IO::Select;
use File::Spec;
use Time::HiRes qw( sleep );

our %MAX = 
(
    listen => 50,   ## listen backlog
    thread => 100,  ## threads
    maxconn => 300, ## connections
);

sub new
{
    my ( $class, %config ) = @_;
    my $port = $config{port};

    croak 'invalid port/path definition' unless $port && ! ref $port
        && $port =~ /^\d+$/ && $port < 65536
        || File::Spec->file_name_is_absolute( $port );

    map { $config{$_} = $MAX{$_} unless $config{$_}
        && $config{$_} > 0 && $config{$_} < $MAX{$_} } keys %MAX;

    $config{thread} = $config{maxconn} if $config{thread} > $config{maxconn};

    my $this = bless \%config, ref $class || $class;

    croak "'_server' method not implemented" unless $this->can( '_server' );
    return $this;
}

=head1 DESCRIPTION

A server listens for and accepts incoming TCP connections on a port or a
Unix domain socket. And a pool of threads are created to handle the
connections in parallel. The server code handling the connections is to be
implemented in the inheriting class.

A more sophisticated implementation may require serialization in processing
requests, e.g. logging. There must be a dedicated worker thread that serially
processes requests from the server threads.

Hence _server() is the interface method to be implemented, and _worker() is an
optional interface method. If _worker() is inplemented, each _server() thread
needs to communicate with it via a pair of queues for two-way communication.
e.g.
 
 sub _server
 {
     my ( $this, $socket, @queue ) = @_;
     ...
 }

 sub _worker
 {
     my ( $this, @queue ) = @_;
     ...
 }

=head2 run()

Launches server.

=cut
sub run
{
    my $this = shift;
    my $port = $this->{port};
    my $listen = $this->{listen};
    my $thread = $this->{thread};
    my ( $domain, $addr );

    if ( $port =~ /^\d/ )
    {
        $addr = sockaddr_in( $port, INADDR_ANY );
        $domain = PF_INET;
    }
    else
    {
        $addr = sockaddr_un( $port );
        $domain = PF_UNIX;
        unlink $port;
    }

    croak "socket: $!" unless socket my $socket, $domain, SOCK_STREAM, 0;
    croak "setsockopt: $!"
        unless setsockopt $socket, SOL_SOCKET, SO_REUSEADDR, 1;

    croak "bind (port/path $port): $!" unless bind $socket, $addr;
    croak "listen: $!" unless listen $socket, $listen;

    my $select = new IO::Select( $socket );
    my @conn = map { Thread::Queue->new } 0 .. 1;
    my $server = sub
    {
        while ( my $fileno = $conn[0]->dequeue() )
        {
            if ( open my $socket, '+<&=', $fileno )
            {
                $this->_server( $socket, @_ );
                close $socket;
            }

            $conn[1]->enqueue( $fileno );
        }
    };

    if ( $this->can( '_worker' ) )
    {
        my @work;

        for ( 1 .. $thread )
        {
            my @queue = map { Thread::Queue->new } 0 .. 1;
            threads::async { &$server( @queue ) }->detach();
            push @work, \@queue;
        }

        threads::async
        {
            for ( my ( $nap, $active ) = 1 / $thread ; 1 ; $active = 0 )
            {
                for my $work ( @work )
                {
                    if ( $work->[0]->pending )
                    {
                        $active = 1;
                        $this->_worker( @$work );
                    }
                    elsif ( ! $active )
                    {
                        sleep $nap;
                    }
                }
            }
        }->detach();
    }
    else
    {
        map { threads::async{ &$server() }->detach() } 1 .. $thread;
    }

    my %conn;

    while ( 1 )
    {
        for ( my ( $drop, $count ); ( $count = $conn[1]->pending ) ||
            ( $drop = $conn[0]->pending > $this->{maxconn} ); $drop = 0 )
        {
            carp "connection limit reached" if $drop;
            map { delete $conn{$_} } $conn[1]->dequeue( $count || 1 );
        }

        if ( my ( $server, $client ) = $select->can_read( 0.1 ) )
        {
            accept $client, $server;
            my $fileno = fileno $client;

            $conn[0]->enqueue( $fileno );
            $conn{$fileno} = $client;
        }
    }
}

=head1 EXAMPLE
 
 ## an echo server module

 package Echo;
 
 use base DynGig::Util::TCPServer;
 use strict;
 
 use constant MAX_BUF => 2 ** 5;
 
 sub _server
 {
     my ( $this, $socket ) = @_;
     my $buffer;
 
     syswrite( $socket, $buffer ) if sysread( $socket, $buffer, MAX_BUF );
 }

 1;

 __END__


 ## echo server

 use strict;
 use Echo;

 my $server = Echo->new
 ( 
     port => 12345,
     thread => 30,
     listen => 10,
     maxconn => 300,
 );

 $server->run();

=head1 SEE ALSO

Socket, threads, Thread::Queue, and IO::Select,

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
