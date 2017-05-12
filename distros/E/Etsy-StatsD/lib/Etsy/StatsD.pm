package Etsy::StatsD;
use strict;
use warnings;
use IO::Socket;
use Carp;

our $VERSION = 1.002002;

# The CPAN verion at https://github.com/sanbeg/Etsy-Statsd should be kept in
# sync with the version distributed with StatsD, at
# https://github.com/etsy/statsd (in the exmaples directory), so you can get
# it from either location.

=head1 NAME

Etsy::StatsD - Object-Oriented Client for Etsy's StatsD Server

=head1 SYNOPSIS

    use Etsy::StatsD;

    # Increment a counter
    my $statsd = Etsy::StatsD->new();
    $statsd->increment( 'app.method.success' );


    # Time something
    use Time::HiRes;

    my $start_time = time;
    $app->do_stuff;
    my $done_time = time;

    # Timers are expected in milliseconds
    $statsd->timing( 'app.method', ($done_time - $start_time) * 1000 );

    # Send to two StatsD Endpoints simultaneously
    my $repl_statsd = Etsy::StatsD->new(["statsd1","statsd2"]);

    # On two different ports:
    my $repl_statsd = Etsy::StatsD->new(["statsd1","statsd1:8126"]);

    # Use TCP to a collector (you must specify a port)
    my $important_stats = Etsy::StatsD->new(["bizstats1:8125:tcp"]);


=head1 DESCRIPTION

=cut

=over

=item new (HOST, PORT, SAMPLE_RATE)

Create a new instance.

=over

=item HOST


If the argument is a string, it must be a hostname or IP only.  The default is
'localhost'.  The argument may also be an array reference of strings in the
form of "<host>", "<host>:<port>", or "<host>:<port>:<proto>".  If the port is
not specified, the default port specified by the PORT argument will be used.
If the protocol is not specified, or is not "tcp" or "udp", "udp" will be set.
The only way to change the protocol, is to specify the host, port and protocol.

=item PORT

Default is 8125.  Will be used as the default port for any HOST argument not explicitly defining port.

=item SAMPLE_RATE

Default is undefined, or no sampling performed.  Specify a rate as a decimal between 0 and 1 to enable
sampling. e.g. 0.5 for 50%.

=back

=cut

sub new {
	my ( $class, $host, $port, $sample_rate ) = @_;
	$host = 'localhost' unless defined $host;
	$port = 8125        unless defined $port;

    # Handle multiple connections and
    #  allow different ports to be specified
    #  in the form of "<host>:<port>:<proto>"
    my %protos = map { $_ => 1 } qw(tcp udp);
    my @connections = ();

    if( ref $host eq 'ARRAY' ) {
        foreach my $addr ( @{ $host } ) {
            my ($addr_host,$addr_port,$addr_proto) = split /:/, $addr;
            $addr_port  ||= $port;
            # Validate the protocol
            if( defined $addr_proto ) {
                $addr_proto = lc $addr_proto;  # Normalize to lowercase
                # Check validity
                if( !exists $protos{$addr_proto} ) {
                    croak sprintf("Invalid protocol  '%s', valid: %s", $addr_proto, join(', ', sort keys %protos));
                }
            }
            else {
                $addr_proto = 'udp';
            }
            push @connections, [ $addr_host, $addr_port, $addr_proto ];
        }
    }
    else {
        push @connections, [ $host, $port, 'udp' ];
    }

    my @sockets = ();
    foreach my $conn ( @connections ) {
        my $sock = new IO::Socket::INET(
            PeerAddr => $conn->[0],
            PeerPort => $conn->[1],
            Proto    => $conn->[2],
        ) or carp "Failed to initialize socket: $!";

        push @sockets, $sock if defined $sock;
    }
    # Check that we have at least 1 socket to send to
    croak "Failed to initialize any sockets." unless @sockets;

	bless { sockets => \@sockets, sample_rate => $sample_rate }, $class;
}

=item timing(STAT, TIME, SAMPLE_RATE)

Log timing information

=cut

sub timing {
	my ( $self, $stat, $time, $sample_rate ) = @_;
	$self->send( { $stat => "$time|ms" }, $sample_rate );
}

=item increment(STATS, SAMPLE_RATE)

Increment one of more stats counters.

=cut

sub increment {
	my ( $self, $stats, $sample_rate ) = @_;
	$self->update( $stats, 1, $sample_rate );
}

=item decrement(STATS, SAMPLE_RATE)

Decrement one of more stats counters.

=cut

sub decrement {
	my ( $self, $stats, $sample_rate ) = @_;
	$self->update( $stats, -1, $sample_rate );
}

=item update(STATS, DELTA, SAMPLE_RATE)

Update one of more stats counters by arbitrary amounts.

=cut

sub update {
	my ( $self, $stats, $delta, $sample_rate ) = @_;
	$delta = 1 unless defined $delta;
	my %data;
	if ( ref($stats) eq 'ARRAY' ) {
		%data = map { $_ => "$delta|c" } @$stats;
	}
	else {
		%data = ( $stats => "$delta|c" );
	}
	$self->send( \%data, $sample_rate );
}

=item send(DATA, SAMPLE_RATE)

Sending logging data; implicitly called by most of the other methods.

=back

=cut

sub send {
	my ( $self, $data, $sample_rate ) = @_;
	$sample_rate = $self->{sample_rate} unless defined $sample_rate;

	my $sampled_data;
	if ( defined($sample_rate) and $sample_rate < 1 ) {
		while ( my ( $stat, $value ) = each %$data ) {
			$sampled_data->{$stat} = "$value|\@$sample_rate" if rand() <= $sample_rate;
		}
	}
	else {
		$sampled_data = $data;
	}

	return '0 but true' unless keys %$sampled_data;

	#failures in any of this can be silently ignored
	my $count  = 0;
	foreach my $socket ( @{ $self->{sockets} } ) {
        # calling keys() resets the each() iterator
        keys %$sampled_data;
        while ( my ( $stat,$value ) = each %$sampled_data ) {
            _send_to_sock($socket, "$stat:$value\n", 0);
            ++$count;
        }
    }
	return $count;
}

sub _send_to_sock( $$ ) {
    my ($sock,$msg) = @_;
    CORE::send( $sock, $msg, 0 );
}

=head1 SEE ALSO

L<http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/>

=head1 AUTHOR

Steve Sanbeg L<http://www.buzzfeed.com/stv>

=head1 LICENSE

Same as perl.

=cut

1;
