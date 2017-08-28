package MYDan::Util::MIO::TCP;

=head1 NAME

MYDan::Util::MIO::TCP - Make multiple TCP connections in parallel.

=head1 SYNOPSIS
 
 use MYDan::Util::MIO::TCP;

 my $tcp = MYDan::Util::MIO::TCP->new( qw( host1:port1 host1:port2 ... ) );
 my $result = $tcp->run( max => 128, log => \*STDERR, timeout => 300 );

 my $mesg = $result->{mesg};
 my $error = $result->{error};

=cut
use strict;
use warnings;

use Carp;
use IO::Socket;
use Time::HiRes qw( time );
use IO::Poll qw( POLLIN POLLHUP POLLOUT );

use base qw( MYDan::Util::MIO );

our %RUN = %MYDan::Util::MIO::RUN;
our %MAX = %MYDan::Util::MIO::MAX;

sub new
{
    my $self = shift;
    $self->net( @_ );
}

=head1 METHODS

=head3 run( %param )

Make TCP connections in parallel.
The following parameters may be defined in I<%param>:

 max : ( default 128 ) number of connections in parallel.
 log : ( default STDERR ) a handle to report progress.
 timeout : ( default 300 ) number of seconds allotted for each connection.
 input : ( default from STDIN ) input buffer.

Returns HASH of HASH of nodes. First level is indexed by type
( I<mesg> or I<error> ). Second level is indexed by message.

=cut
sub run
{
    confess "poll: $!" unless my $poll = IO::Poll->new();

    local $| = 1;
    local $/ = undef;

    my $self = shift;
    my @node = keys %$self;
    my ( %run, %result, %buffer, %busy ) = ( %RUN, @_ );
    my ( $log, $max, $timeout, $input ) = @run{ qw( log max timeout input ) };

    $input ||= -t STDIN ? '' : <STDIN>;

    for ( my $time = time; @node || $poll->handles; )
    {
        if ( time - $time > $timeout ) ## timeout
        {
            for my $sock ( keys %busy )
            {
                $poll->remove( $sock );
                eval { $sock->shutdown( 2 ) };
                push @{ $result{error}{timeout} }, delete $busy{$sock};
            }

            print $log "timeout!\n";
            last;
        }

        while ( @node && keys %busy < $max )
        {
            my $node = shift @node;
            my %inet =
            (
                PeerAddr => $node, Blocking => 0, Timeout => $timeout,
                Proto => 'tcp', Type => SOCK_STREAM,
            );

            my $sock = $self->{$node}
                ? IO::Socket::INET->new( %inet )
                : IO::Socket::UNIX->new( %inet );

            unless ( $sock )
            {
                push @{ $result{error}{ "socket: $!" } }, $node;
                next;
            }

            $poll->mask( $sock => POLLIN | POLLOUT );
            $busy{$sock} = $node;
            print $log "$node started.\n" if $run{verbose};
        }

        $poll->poll( $MAX{period} );

        for my $sock ( $poll->handles( POLLIN ) ) ## read
        {
            my $buffer; $sock->recv( $buffer, $MAX{buffer} );
            $buffer{$sock} .= $buffer;
        }

        for my $sock ( $poll->handles( POLLOUT ) ) ## write
        {
            $sock->send( $input ) if defined $input;
            $poll->mask( $sock, $poll->mask( $sock ) & ~POLLOUT );
            eval { $sock->shutdown( 1 ) };
        }

        for my $sock ( $poll->handles( POLLHUP ) ) ## done
        {
            my $node = delete $busy{$sock};

            push @{ $result{mesg}{ delete $buffer{$sock} } }, $node;
            $poll->remove( $sock );
            eval { $sock->shutdown( 0 ) };
            print $log "$node done.\n" if $run{verbose};
        }
    }

    push @{ $result{error}{'not run'} }, @node if @node;
    return wantarray ? %result : \%result;
}

1;
