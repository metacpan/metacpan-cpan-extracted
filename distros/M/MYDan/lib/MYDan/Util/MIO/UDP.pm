package MYDan::Util::MIO::UDP;

=head1 NAME

MYDan::Util::MIO::UDP - Send multiple UPD datagrams in parallel.

=head1 SYNOPSIS
 
 use MYDan::Util::MIO::UDP;

 my $udp = MYDan::Util::MIO::UDP->new( qw( host1:port1 host1:port2 ... ) );
 my $result = $udp->run( max => 128, log => \*STDERR, timeout => 300 );

 my $mesg = $result->{mesg};
 my $error = $result->{error};

=cut
use strict;
use warnings;

use Carp;
use IO::Socket;
use Time::HiRes qw( time );
use IO::Poll qw( POLLIN );

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

Send UDP datagrams in parallel.
The following parameters may be defined in I<%param>:

 max : ( default 128 ) number of datagrams sent in parallel.
 log : ( default STDERR ) a handle to report progress.
 timeout : ( default 300 ) number of seconds allotted for each response.
 input : ( default from STDIN ) input buffer.
 resp : ( default 1 ) want response.

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
    my ( %run, %result, %busy ) = ( resp => 1, %RUN, @_ );
    my ( $log, $max, $timeout, $input, $resp ) =
        @run{ qw( log max timeout input resp ) };

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
                Proto => 'udp', Type => SOCK_DGRAM,
            );

            my $sock = $self->{$node}
                ? IO::Socket::INET->new( %inet )
                : IO::Socket::UNIX->new( %inet );

            unless ( $sock )
            {
                push @{ $result{error}{ "socket: $!" } }, $node;
                next;
            }

            $sock->send( $input ) if defined $input;
            print $log "$node started.\n" if $run{verbose};

            if ( $resp )
            {
                $poll->mask( $sock => POLLIN );
                $busy{$sock} = $node;
            }
            else
            {
                eval { $sock->shutdown( 2 ) };
                print $log "$node done.\n" if $run{verbose};
            }
        }

        next unless $resp;
        $poll->poll( $MAX{period} );

        for my $sock ( $poll->handles( POLLIN ) ) ## read
        {
            my $buffer; $sock->recv( $buffer, $MAX{buffer} );
            my $node = delete $busy{$sock};

            push @{ $result{mesg}{$buffer} }, $node;
            $poll->remove( $sock );
            eval { $sock->shutdown( 2 ) };
            print $log "$node done.\n" if $run{verbose};
        }
    }

    push @{ $result{error}{'not run'} }, @node if @node;
    return wantarray ? %result : \%result;
}

1;
