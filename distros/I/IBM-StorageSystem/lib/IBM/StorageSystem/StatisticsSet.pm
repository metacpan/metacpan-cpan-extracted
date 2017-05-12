package IBM::StorageSystem::StatisticsSet;

use strict;
use warnings;

our $VERSION = '0.01';
our $ITERATOR= 0;

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	return $self
}

sub next {
	my $self = shift;
	defined @{ $self->{stats} }[$ITERATOR] or return undef;
	$ITERATOR++;
	return @{ $self->{stats} }[$ITERATOR - 1]
}

sub __push {
	my( $self, @vals ) = @_;
	push @{ $self->{stats} }, @vals;
}

sub count {
	my $self = shift;
	return scalar @{ $self->{stats} }
}

sub first {
	my $self = shift;
	return @{ $self->{stats} }[0]
}

sub last {
	my $self = shift;
	return @{ $self->{stats} }[-1]
}

sub min {
	my( $self, $value ) = @_;
	grep { /$value/ } $self->first->_values or return undef;
	defined $self->{_data}->{$value} or $self->_sort( $value );

	return wantarray	? @{ $self->{_data}->{$value} }
				: @{ $self->{_data}->{$value} }[0]
}

sub max {
	my( $self, $value ) = @_;
	$self->min( $value );
	return wantarray	? reverse @{ $self->{_data}->{$value} } 
				: @{ $self->{_data}->{$value} }[-1]
}

sub avg {
	my $self = shift;
	my $d = {};
	my $c = 0;

	foreach my $s ( @{ $self->{stats} } ) {

		foreach my $v ( keys %{ $s } ) {
			next if $s->{$v} =~ /[a-zA-Z]/;
			$s->{$v} =~ /\d+(\.{1}\d+)?/ or next;
			$d->{$v} += $s->{$v};
		}

		$c++
	}
	
	foreach my $v ( keys %{ $d } ) {
		next unless $d->{$v};
		$d->{$v} /= $c 
	}

	my $ref = ref( @{ $self->{stats} }[0]);
	my $s = $ref->new;

	for ( keys %{ $d } ) {
		$s->$_( $d->{$_} )
	}

	return $s
}

sub _sort {
	my( $self, $value ) = @_;
	@{ $self->{_data}->{$value} }	= map { $_->[0] }
					  sort { $a->[1] <=> $b->[1] }
					  map { [ $_, $_->$value ] } @{ $self->{stats} };
}

sub values {
	my $self = shift;
	return $self->first->_values;
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::StatisticsSet - Utility class for handling groups of IBM::StorageSystem statistics objects

=head1 SYNOPSIS

IBM::StorageSystem::StatisticsSet is utility class for handling groups of IBM::StorageSystem statistics objects

Note that you should not need to create a IBM::StorageSystem::StatisticsSet object manually under normal conditions,
rather one will be created automatically for you on invocation to otrher method in <IBM::StorageSystem> packages.

IBM::StorageSystem::StatisticsSet provides some basic utility functions for manipulating and working with 
sets of statistics objects.

A StatisticsSet object is an nothing more than an array of homogenous statistics objects with the ability
to perform some basic operations.  The StatisticsSet is necessary to performing higher level functions
and adding syntactical sugar.

Methods that return IBM::StorageSystem::StatisticsSet objects accept a single optional parameter; the interval
period name - one of minute, hour, day, week, month, quarter or year.  If you do not specify this parameter then
the default value of minute will be used.

For example, to retrieve a StatisticsSet of L<IBM::StorageSystem::Statistic::Node::CPU> objects for a 
L<IBM::StorageSystem::Node> object, the following invocations are equivalent;

	my @statistics_set = $node->cpu('minute')

	my @statistics_set = $node->cpu;

=head1 METHODS

=head3 count

Returns the number of results in the statistics set.

=head3 values

Returns the attributes of the objects in the set - as all objects in a set are homogenous, the attributes
returned are valid for all members of the set.

=head3 min( $attribute )

	# Get the minimum monthly average memory value for the first node in our cluster
	my $min_monthly_avg_memory = $ibm->nodes[0]->memory('month')->min('avg_memory')->avg_memory;

	# In detail:
	#    On the first node
	#           |   Get the memory stats
	#           |         |   For the year
	#           |         |       |  Get the maximum value
	#           |         |       |      |   Of this variable
	#           |         |       |      |       |       And display it
	#           V         V       V      V       V             V
	#  $ibm->$nodes[0]->memory('year')->min('avg_memory')->avg_memory

	# Get a list of all memory statistics for the previous day sorted by ascending
	# value of average swap free memory
	my @vals = $ibm->nodes[0]->memory->('day')->avg_swap_free_memmory;

In scalar context, this method returns the object having the minimum recorded value for the specified
attribute parameter, where the parameter is a valid attribute name for the specified object type 
(i.e. the attribute parameter exists in the array returned by the B<values> method).

In list context, this method returns a list of objects of the specified statistic type
sorted by the attribute parameter.

=head3 max( $attribute )

This method is the logical complement of the B<min> method - the method returns either a 
scalar or list as per the B<min> method but sorted via maximum value.
Function 

=head3 avg

	# Print the average number of read operations for all disks

	foreach $node ( $ibm->nodes ) {

		my $stats = node->disk_reads->avg;

		foreach my $v ( sort $node->disk_reads->values ) {
			print "Disk $v average read operations: ", $stats->$v, "\n"
		}
	}

	# Prints:
	#
	# Disk dm_0 average read operations: 0.0333333333333333
	# Disk dm_1 average read operations: 0.0333333333333333
	# Disk dm_10 average read operations: 0.0333333333333333
	# Disk dm_11 average read operations: 0.0333333333333333
	# Disk dm_12 average read operations: 0.0333333333333333
	# ... etc.

Returns a single IBM::StorageSystem statistics object containing averaged values for all objects
in the StatisticsSet.  The returned object is blessed into the class of the objects of the set.

=head3 first

Returns the first object in the set.

=head3 last

Returns the last object in the set.

=head3 next

	# Print disk read operations for device 'dm-1'
	my $read_stats = $node->disk_reads;

	while ( my $stat = $read_stats->next ) {
		printf("%-20s: %-10s\n", $stat->start_time, $stat->dm_1 )
	}

On initial invocation, returns the first object in the statistics set. On subsequent invocations, 
returns the next statistic object in set.  Returns undef if no items remain.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-statisticsset at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-StatisticsSet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::StatisticsSet

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-StatisticsSet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-StatisticsSet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-StatisticsSet>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-StatisticsSet/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
