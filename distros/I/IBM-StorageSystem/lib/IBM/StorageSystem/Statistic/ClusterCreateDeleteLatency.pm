package IBM::StorageSystem::Statistic::ClusterCreateDeleteLatency;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(start_time end_time avg_create_latency avg_delete_latency);

foreach my $attr ( @ATTR ) { 
        {   
                no strict 'refs';
                *{ __PACKAGE__ .'::'. $attr } = sub {
                        my( $self, $val ) = @_; 
                        $self->{$attr} = $val if $val;
                        return $self->{$attr}
                }   
        }
}

sub new {
        my( $class, @vals ) = @_; 
        my $self = bless {}, $class;
        my $c = 0;

        foreach my $attr ( @ATTR ) { $self->{$attr} = $vals[$c]; $c++ }

        return $self
}

sub _values { return @ATTR }

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Statistic::ClusterCreateDeleteLatency - Utility class for IBM::StorageSystem cluster create and delete
operation latency performance data.

=head1 SYNOPSIS

IBM::StorageSystem::Statistic::ClusterCreateDeleteLatency is a utility class for IBM::StorageSystem cluster create and delete
operation latency performance data.

An IBM::StorageSystem::Statistic::ClusterCreateDeleteLatency object represents a collection of averaged statistical 
measurements for creation and deletion operation latency across all nodes in the target cluster during a single interval 
period.  

The interval period is defined by the interval parameter passed on invocation to the specific parent class.

=head1 METHODS

=head3 start_time 

The start time of the interval over which the data was collected in the format 'YYYY-MM-DD HH:MM:SS UTC+HH'.

=head3 end_time 

The end time of the interval over which the data was collected in the format 'YYYY-MM-DD HH:MM:SS UTC+HH'.

=head3 avg_create_latency

The average latency of a creation operation (in milliseconds/operation) across all nodes in the target cluster.

=head3 avg_delete_latency

The average latency of a deletion operation (in milliseconds/operation) across all nodes in the target cluster.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-statistic-clustercreatedeletelatency at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Statistic::ClusterCreateDeleteLatency>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Statistic::ClusterCreateDeleteLatency

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Statistic-ClusterCreateDeleteLatency>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Statistic-ClusterCreateDeleteLatency>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Statistic-ClusterCreateDeleteLatency>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Statistic-ClusterCreateDeleteLatency/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
