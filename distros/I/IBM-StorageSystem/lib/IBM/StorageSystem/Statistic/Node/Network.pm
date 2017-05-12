package IBM::StorageSystem::Statistic::Node::Network;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(start_time end_time ethX1_bytes_received ethX1_bytes_sent ethX1_packets_received ethX1_packets_sent ethX0_bytes_received ethX0_bytes_sent ethX0_packets_received ethX0_packets_sent ethX1_drops ethX0_drops);

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

IBM::StorageSystem::Statistic::Node::Network - Utility class for IBM::StorageSystem node Network statistics

=head1 SYNOPSIS

IBM::StorageSystem::Statistic::Node::CPU is a utility class for IBM::StorageSystem node CPU statistics.

An IBM::StorageSystem::Statistic::Node::CPU object represents a collection of statistical measurements for
CPU activity for the specified node during a single interval period.  

The interval period is defined by the interval parameter passed on invocation to the specific parent class.

=head1 METHODS

=head3 start_time 

The start time of the interval over which the data was collected in the format 'YYYY-MM-DD HH:MM:SS UTC+HH'.

=head3 end_time 

The end time of the interval over which the data was collected in the format 'YYYY-MM-DD HH:MM:SS UTC+HH'.

=head3 context_switches 

The number of CPU context switches in the interval period.

=head3 interrupts 

The number of CPU interrupts in the interval period.

=head3 avg_idle 

The average percentage of CPU time spent idle during the interval period.

=head3 avg_system

The average percentage of CPU time spent in kernel space during the interval period.

=head3 avg_user 

The average percentage of CPU time spent in user space during the interval period.

=head3 avg_iowait 

The average percentage of CPU time spent waiting on IO during the interval period.

=head3 avg_soft_interrupts 

The average percentage of CPU time spent handling software interrupts during the interval period.

=head3 avg_hard_interrupts 

The average percentage of CPU time spent handling hardware interrupts during the interval period.

=head3 avg_nice

The average percentage of CPU time spent on low priority processes during the interval period.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-statistic-node-cpu at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Statistic::Node::CPU>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Statistic::Node::CPU

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Statistic::Node::CPU>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Statistic::Node::CPU>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Statistic::Node::CPU>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Statistic::Node::CPU/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
