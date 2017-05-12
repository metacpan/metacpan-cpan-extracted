package Geo::Coder::Many::Scheduler;

use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

=head1 NAME

Scheduler - Abstract base class for schedulers.

=head1 DESCRIPTION

Abstract base class for schedulers. Should not be instantiated directly.

=head1 METHODS

=head2 new

Should never be called; subclasses should override.

=cut

sub new {
    croak "Scheduler should not be instantiated directly: use a subclass.";
}

=head2 get_next_unique

get_next_unique should return the next scheduled item, according to whatever
scheduling scheme the subclass implements. The same item should *not* be
returned more than once between calls to reset_available.

=cut

sub get_next_unique {
    croak "get_next_unique must be overridden.";
}

=head2 next_available

If there are items in the scheduler that have not already been dispensed since
the last call to 'reset_available', next_available should return the minimum
amount of time (in floating seconds) until one of them might become available. 

If there will never be any such items available, it should return -1.

In Geo::Coder::Many, next_available is used to tell the result-picker
whether it is worth waiting for more results.

=cut

sub next_available {
    croak "next_available must be overridden.";
}

=head2 reset_available

This is called in order to indicate that all items should once more be made
available.

=cut

sub reset_available {
    croak "reset_available must be overridden.";
}

=head2 process_feedback

This is called to provide information about the performance of a geocoder. Does
nothing by default.

=cut

sub process_feedback {
    return;
}

1;

__END__

