package IBM::StorageSystem::Statistic::Node::DiskRead;

use strict;
use warnings;

use vars qw($AUTOLOAD);

use Carp qw(croak);

sub AUTOLOAD {
	my $self = shift or return undef;
	( my $method = $AUTOLOAD ) =~ s/.*:://;

	my $accessor = sub {
		my ( $t_self, $val ) = @_;
		$t_self->{$method} = $val if defined $val;
		return $t_self->{$method};
	};

	{
		no strict qw{refs};
		*$AUTOLOAD = $accessor;
	}

	unshift @_, $self;
	goto &$AUTOLOAD;
}

sub DESTROY {}

sub new {
        my( $class, @vals ) = @_; 
        my $self = bless {}, $class;
        return $self
}

sub _values { 
	{
		no strict 'refs';
		return grep { defined &{$_} and /(dm_|(start|end)_time)/ } keys %IBM::StorageSystem::Statistic::Node::DiskRead::
	}
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Statistic::Node::DiskRead - Utility class for IBM::StorageSystem node disk read statistics

=head1 SYNOPSIS

IBM::StorageSystem::Statistic::Node::DiskRead is a utility class for IBM::StorageSystem node DiskRead statistics.

An IBM::StorageSystem::Statistic::Node::DiskRead object represents a collection of statistical measurements for
disk read operations for the specified node during a single interval period.  

The interval period is defined by the interval parameter passed on invocation to the specific parent class.

=head1 METHODS

=head3 start_time 

The start time of the interval over which the data was collected in the format 'YYYY-MM-DD HH:MM:SS UTC+HH'.

=head3 end_time 

The end time of the interval over which the data was collected in the format 'YYYY-MM-DD HH:MM:SS UTC+HH'.

=head1 DATA METHODS

=head3 device_n 

Returns the read operations for the specified device.

B<Note> that the method name B<device_n> used above is a variable method name that is dynamically created
dependent on the system type and architecture.  

The device name will be the same as the system device name
to which GPFS disks are mapped - for example; for SONAS IBM storage system architectures, GPFS disks are 
mapped to multipath devices (/dev/dm-*) and so for each multipath devicemapper device, a new method will be 
created using the device name.

	# For example; to retrieve a list of the device names (and hence, the methods available),
	# invoke the 'values' method on the IBM::StorageSystem::StatisticsSet object retrieved
	# from a 'disk_reads' invocation;

	my $read_stats = $ibm->node('mgmt001st001')->disk_reads;
	print "Methods available:\n", join "\n", sort $read_stats->values;

	# Prints:
	# Methods available:
	# dm_0
	# dm_1
	# dm_10
	# dm_11
	# dm_12
	# dm_13
	# ...

B<Note> that any hyphens in the device name will be replaced by an underscore.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-statistic-node-diskread at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Statistic::Node::DiskRead>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Statistic::Node::DiskRead

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Statistic::Node::DiskRead>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Statistic::Node::DiskRead>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Statistic::Node::DiskRead>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Statistic::Node::DiskRead/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
