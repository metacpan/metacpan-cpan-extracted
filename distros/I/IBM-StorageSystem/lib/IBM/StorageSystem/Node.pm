package IBM::StorageSystem::Node;

use strict;
use warnings;

use IBM::StorageSystem::Statistic::Node::Memory;
use IBM::StorageSystem::Statistic::Node::CPU;
use IBM::StorageSystem::Statistic::Node::DiskRead;
use IBM::StorageSystem::Statistic::Node::DiskWrite;
use Carp qw(croak);
use Scalar::Util qw(weaken);

our $VERSION = '0.02';
our @ATTR = qw(	CTDB_status	connection_status	CTDB_IP_address		daemon_IP_address 
		daemon_version	description		GPFS_status		hostname
		IP		is_cache		is_manager		is_quorum 
		last_updated	monitoring_enabled	OS_family		OS_name
		product_version	recovery_master 	role			serial_number 
		username 	version
	     );

foreach my $attr ( @ATTR ) { 
	{   
		no strict 'refs';
		*{ __PACKAGE__ .'::'. $attr } =	sub {
			my( $self, $val ) = @_;
			$val =~ s/\#/no/ if $val;
			$self->{$attr} = $val if $val;
			return $self->{$attr}
		}   
	}   
}

our $STATS = {
		memory => {
			cmd	=> '-g memory_stats',
			class	=> 'IBM::StorageSystem::Statistic::Node::Memory'
			},
		cpu => {
			cmd	=> '-g cpu_stats',
			class	=> 'IBM::StorageSystem::Statistic::Node::CPU'
			}
};

foreach my $stat ( keys %{ $STATS } ) {
	{
		no strict 'refs';
		*{ __PACKAGE__ .'::'. $stat } = sub {
			my( $self, $t ) = @_;
			$t ||= 'minute';
			my $stats = $self->{__ibm}->__lsperfdata( 
						cmd   => "$STATS->{$stat}->{cmd} -t $t -n $self->{hostname}",
						class => $STATS->{$stat}->{class}
							);
			return $stats
		}
	}
}

foreach my $m ( qw(reads writes) ) {
	{
	no strict 'refs';
	*{ __PACKAGE__ .'::disk_'. $m } = sub {
		my( $self, $t ) = @_;
		$t ||= 'minute';
		my $stats = IBM::StorageSystem::StatisticsSet->new;
		my( $headers, @stats ) = split( /\n/, 
			$self->{__ibm}->__cmd( "lsperfdata -g disk_$m -t $t -n $self->{hostname}" ) );
		# disk_reads and disk_writes perfdata stats use non-parsable CSV for the column headers
		# This neccesitates the ugliness below
		pop @stats;
		my @cols = split /\[#\]/, $headers;
		my @f = ( split /,/, shift @cols )[0,1,3];
		
		for ( @cols ) { push @f, ( split /,/ )[2] }

		@cols = map {	s/^ *//; 
				s/ *$//; 
				s/ /_/g; 
				s/-/_/g; 
				lc($_) 
			} @f;

		foreach my $stat ( @stats ) {
			my @values = split /,/, $stat;
			( my $m = 'IBM::StorageSystem::Statistic::Node::Disk' . ucfirst $m ) =~ s/s$//;
			my $s = $m->new;
			my $c = 0;

			foreach my $col ( @cols ) {
				$s->$col( $values[$c++] ); 
			}

			$stats->__push( $s )
		}

		return $stats
	}
	}
}

sub new {
        my( $class, $ibm, %args ) = @_; 
        my $self = bless {}, $class;
	weaken( $self->{__ibm} = $ibm );

        defined $args{Hostname} or croak 'Constructor failed: mandatory Hostname argument not supplied';

	# Modify the passed arg attribute names for nicer formatting - lower cased except for acronyms
	foreach my $attr ( keys %args ) {
		my $mattr = lc $attr;

		foreach my $s ( qw(ctdb gpfs ip os) ) {
			my $u = uc $s;
			$mattr =~ s/(^|_)($s)/$1$u/g
		}

		$self->{$mattr} = $args{$attr} 
	}

	return $self;
}

1;

__END__

=head1 NAME

IBM::StorageSystem::Node - Class for operations with a IBM StorageSystem node

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Node is a utility class for operations with a IBM StorageSystem node.

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      
					user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";
	
	# Get node mgmt001st001 as an IBM::StorageSystem::Node object
	my $node = $ibm->node( mgmt001st001 );
	
	# Print the node description
	print "Description: " . $node->description . "\n";

	# Prints something like: "Description: active management node"
	# Or alternately;
	print "Description: " . $ibm->node( mgmt001st001 )->description . "\n";
	
	# Print the GPFS status of all nodes
	foreach my $node ( $ibm->get_nodes ) {
		print "GPFS status: " . $node->GPFS_status . "\n"
	}

	# Print the node product version
	print $node->product_version;

	# Print the node connection status
	print $node->connection_status;


=head1 METHODS

=head3 CTDB_status

Returns the Clustered Trivial Database Status (CTDB) status of the specified node.

=head3 connection_status

Returns the connection status of the specified node.

=head3 CTDB_IP_address

Returns the CTDB IP address of the specified node.

=head3 cpu( $timeperiod )

Returns a L<IBM::StorageSystem::Statistic::Node::CPU> object containing CPU statistics
and performance data for the specified node for the specified time period.

Valid values for the timeperiod parameter are one of minute, hour, day, week, month, quarter 
and year - if the timeperiod parameter is not specified it will default to minute.

=head3 daemon_IP_address

Returns the daemon IP address of the specified node.

=head3 daemon_version

Returns the daemon version number.

=head3 description

Returns the node description.

=head3 disk_reads( $time_period )

Returns a L<IBM::StorageSystem::StatisticsSet> object containing a chronological set of 
L<IBM::StorageSystem::Statistic::Node::DiskRead> objects, each of which represent a single
performance measurement of read operations for all GPFS disks on the target node.

The optional time period parameter specifies the period over which the performance data was 
measured and may be one of minute, hour, day, week, month, quarter or year - if no time
period is specified this value will default to minute.

=head3 disk_writes( $time_period )

Returns a L<IBM::StorageSystem::StatisticsSet> object containing a chronological set of 
L<IBM::StorageSystem::Statistic::Node::DiskRead> objects, each of which represent a single
performance measurement of write operations for all GPFS disks on the target node.

The optional time period parameter specifies the period over which the performance data was 
measured and may be one of minute, hour, day, week, month, quarter or year - if no time
period is specified this value will default to minute.

=head3 GPFS_status

Returns the General Paralell File System (GPFS) status of the specified node.

=head3 hostname

Returns the hostname of the specified node.

=head3 IP

Returns the IP address of the specified node.

=head3 is_cache

Returns the cache status of the specified node.

=head3 is_manager

Returns the manager status of the specified node.

=head3 is_quorum

Returns the quorum status of the specified node.

=head3 last_updated

Returns the time at which the CTDB status of the node was last updated.

=head3 memory( $timperiod )

Returns a L<IBM::StorageSystem::Statistics::Node::Memory> object containing memory
statistics and performance data for the specified node for the specified time period.

Valid values for the timeperiod parameter are one of minute, hour, day, week, month, quarter 
and year - if the timeperiod parameter is not specified it will default to minute.

=head3 monitoring_enabled

Returns the monitoring enablement status of the specified node.

=head3 OS_family

Returns the operating system family type of the specified node.

=head3 OS_name

Returns the operating system name of the specified node.

=head3 product_version

Returns the product version number of the specified node.

=head3 recovery_master

Returns the recovery master status of the specified node.

=head3 role

Returns the role of the specified node.

=head3 serial_number

Returns the serial number of the specified node.

=head3 username

Returns the username used for management of the specified node.

=head3 version

Returns the version of the specified node.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-node at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Node>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Node

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Node>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Node>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Node>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Node/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

