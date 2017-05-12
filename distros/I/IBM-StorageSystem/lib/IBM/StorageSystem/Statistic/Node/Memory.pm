package IBM::StorageSystem::Statistic::Node::Memory;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(start_time end_time avg_memory avg_cache_memory avg_swap_memory avg_swap_free_memory avg_free_memory avg_buffer_memory avg_dirty_memory avg_swap_cache_memory);

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

IBM::StorageSystem::Statistic::Node::Memory - Utility class for IBM::StorageSystem node memory statistics

=head1 SYNOPSIS

IBM::StorageSystem::Statistic::Node::Memory is a utility class for IBM::StorageSystem node memory statistics.

An IBM::StorageSystem::Statistic::Node::Memory object represents a collection of statistical measurements for
memory activity during a single interval period for the specified node.  

The interval period is defined by the interval parameter passed on invocation to the specific parent class.

start_time end_time avg_memory avg_cache_memory avg_swap_memory avg_swap_free_memory avg_free_m    emory avg_buffer_memory avg_dirty_memory avg_swap_cache_memory

=head1 METHODS

=head3 start_time 

The start time of the interval over which the data was collected in the format 'YYYY-MM-DD HH:MM:SS UTC+HH'.

=head3 end_time 

The end time of the interval over which the data was collected in the format 'YYYY-MM-DD HH:MM:SS UTC+HH'.

=head3 avg_memory

The average memory available (in KB) during the interval period.  B<Note> that this appears to always be
equal to the total amount of memory for the specified node.

=head3 avg_cache_memory

The average memory (in KB) dedicated to cache in the interval period.

=head3 avg_swap_memory

The average memory (in KB) dedicated to swap during the interval period.  B<Note> that this value always
appears to be equal to the total amount of memory dedicated to swap on the specified node.

=head3 avg_swap_free_memory

The average amount of free swap memory (in KB) during the interval specified.

=head3 avg_free_memory

The average amount of free memory (in KB) during the interval period.

=head3 avg_buffer_memory

The average amount of memory (in KB) dedicated to buffers during the interval period.

=head3 avg_dirty_memory

The average amount of memory (in KB) marked as dirty (in KB) during the interval period.

=head3 avg_swap_cache_memory

The average amount of memory (in KB) dedicated to swap cache during the interval period.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-statistic-node-memory at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Statistic::Node::Memory>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Statistic::Node::Memory

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Statistic::Node::Memory>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Statistic::Node::Memory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Statistic::Node::Memory>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Statistic::Node::Memory/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
