package IBM::StorageSystem::Statistic::ClusterClientThroughput;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(start_time end_time bytes_received bytes_sent);

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

IBM::StorageSystem::Statistic::ClusterClientThroughput - Utility class for IBM::StorageSystem cluster client throughput statistics

=head1 SYNOPSIS

IBM::StorageSystem::Statistic::ClusterClientThroughput is a utility class for IBM::StorageSystem cluster client throughput statistics.

An IBM::StorageSystem::Statistic::iClusterClientThroughput object represents a collection of statistical measurements for
client throughput acorss all nodes in a cluster during the specified node during a single interval period.  

The interval period is defined by the interval parameter passed on invocation to the specific parent class.

=head1 METHODS

=head3 start_time 

The start time of the interval over which the data was collected in the format 'YYYY-MM-DD HH:MM:SS UTC+HH'.

=head3 end_time 

The end time of the interval over which the data was collected in the format 'YYYY-MM-DD HH:MM:SS UTC+HH'.

=head3 bytes_received

The total number of bytes received on all nodes in the cluster in the specified interval.

=head3 bytes_sent

The total number of bytes sent from all nodes in the cluster in the specified interval.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-statistic-clusterclientthroughput at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Statistic::ClusterClientThroughput>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Statistic::ClusterClientThroughput

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Statistic::ClusterClientThroughput>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Statistic::ClusterClientThroughput>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Statistic::ClusterClientThroughput>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Statistic::ClusterClientThroughput/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
