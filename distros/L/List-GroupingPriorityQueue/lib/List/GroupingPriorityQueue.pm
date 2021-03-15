# -*- Perl -*-
#
# based on List::PriorityQueue execpt that payloads with identical
# priorities are grouped together

package List::GroupingPriorityQueue;

use 5.6.0;
use strict;
use warnings;
our $VERSION = '0.01';

use parent qw(Exporter);
our @EXPORT_OK =
  qw(grpriq_add grpriq_min grpriq_min_values grpriq_max grpriq_max_values);

########################################################################
#
# FUNCTIONS

sub grpriq_add {
    my ( $qref, $priority, @rest ) = @_;
    # special cases
    unless (@$qref) {
        @$qref = [ [@rest], $priority ];
        return;
    }
    if ( $priority > $qref->[-1][1] ) {
        push @$qref, [ [@rest], $priority ];
        return;
    }
    if ( $priority < $qref->[0][1] ) {
        unshift @$qref, [ [@rest], $priority ];
        return;
    }
    if ( $priority == $qref->[-1][1] ) {
        push @{ $qref->[-1][0] }, @rest;
        return;
    }
    if ( $priority == $qref->[0][1] ) {
        push @{ $qref->[0][0] }, @rest;
        return;
    }
    my $lower = 0;
    my $midpoint;
    my $upper = $#$qref;
    while ( $lower <= $upper ) {
        $midpoint = ( $lower + $upper ) >> 1;
        if ( $priority < $qref->[$midpoint][1] ) {
            $upper = $midpoint - 1;
            next;
        }
        if ( $priority > $qref->[$midpoint][1] ) {
            $lower = $midpoint + 1;
            next;
        }
        push @{ $qref->[$midpoint][0] }, @rest;
        return;
    }
    splice @$qref, $lower, 0, [ [@rest], $priority ];
    return;
}

sub grpriq_min { shift @{ $_[0] } }

sub grpriq_min_values {
    my $ref = shift @{ $_[0] };
    return unless defined $ref;
    $ref->[0];
}

sub grpriq_max { pop @{ $_[0] } }

sub grpriq_max_values {
    my $ref = pop @{ $_[0] };
    return unless defined $ref;
    $ref->[0];
}

########################################################################
#
# METHODS

sub each {
    my ( $self, $callback ) = @_;
    while ( my $entry = shift @{ $self->{queue} } ) {
        $callback->(@$entry);
    }
}

sub new { bless { queue => [] }, $_[0] }

sub insert {
    my ( $self, $priority, @rest ) = @_;
    grpriq_add( $self->{queue}, $priority, @rest );
    return $self;
}

sub min { shift @{ $_[0]->{queue} } }

sub min_values {
    my $ref = shift @{ $_[0]->{queue} };
    return unless defined $ref;
    $ref->[0];
}
*pop = \&min_values;

sub max { pop @{ $_[0]->{queue} } }

sub max_values {
    my $ref = pop @{ $_[0]->{queue} };
    return unless defined $ref;
    $ref->[0];
}

1;
__END__

=head1 NAME

List::GroupingPriorityQueue - priority queue with grouping

=head1 SYNOPSIS

  use List::GroupingPriorityQueue
    qw(grpriq_add grpriq_min_values);

  my $queue = [];
  grpriq_add($queue, 2, 'cat');
  grpriq_add($queue, 4, 'dog');
  grpriq_add($queue, 2, 'mlatu');
  grpriq_min_values($queue);        # ['cat', 'mlatu']

  # fast iteration ($queue must not be modified mid-loop)
  for my $entry (@{$queue}) {
      my ($payload_r, $priority) = @{$entry};
      ...
  }

  # OO
  my $pq = List::GroupingPriorityQueue->new;
  $pq->insert(2, 'cat');
  $pq->insert(4, 'dog');
  $pq->insert(2, 'mlatu');
  $pq->pop;                         # ['cat', 'mlatu']

  # slow iteration (but allows new items to be added)
  while (my $payload_r = $pq->pop) {
      ...
  }
  # or instead via
  $pq->each(
    sub {
        my ($payload_r, $priority) = @_;
        ...
    }
  );

=head1 DESCRIPTION

This priority queue implementation provides grouping of elements with
the same priority. With a traditional priority queue multiple "pop"
calls would need to be made until the priority value changes; worse,
some implementations do not return the priority value. That information
would need to be encoded into and decoded from the payload under such
implementations. This module instead considers payloads with the same
priority as belonging to the same set and returns them together as an
array reference. The priority information is available to the caller,
if need be.

=head1 FUNCTIONS

The following functions are available for export. An array reference
I<qref> is operated on. Modification of the I<qref> in the calling code
may break this module in unexpected ways.

=over 4

=item B<grpriq_add> I<qref> I<priority> I<payload> ...

Adds the given payload(s) to the queue I<qref>. There is no
return value.

B<Note that the order of arguments differs from other priority queue
modules>; the difference allows multiple payload elements to be added
with a single call.

The priority should probably be an integer; floating point values are
more likely to run into compiler or platform wonkiness should the queue
be saved to disk and reloaded elsewhere.

=item B<grpriq_min> I<qref>

Pulls the lowest priority C<[[payload,...],priority]> array reference
from I<qref>, if any.

Use this if you need the priority value for some calculation.

=item B<grpriq_min_values> I<qref>

Pulls the lowest priority C<[payload,...]> array reference from I<qref>,
if any. Equivalent to B<pop> in the OO interface.

=item B<grpriq_max> I<qref>

Pulls the highest priority C<[[payload,...],priority]> array reference
from I<qref>, if any.

=item B<grpriq_max_values> I<qref>

Pulls the highest priority C<[payload,...]> array reference from
I<qref>, if any.

=back

=head1 METHODS

A simple OO interface is also provided. This hides the I<qref> but
adds overhead.

=over 4

=item B<each> I<callback>

Iterator that drains the queue by minimum value. The I<callback> code
reference is passed the payload array reference and priority value for
each element in the queue.

=item B<new>

Constructor.

=item B<insert> I<priority> I<payload> ...

Adds the payload(s) to the priority queue.

B<Note that the order of arguments differs from other priority queue
modules>; the difference allows multiple payload elements to be added
with a single call.

=item B<min>

Returns the lowest priority C<[[payload],priority]> array reference.

=item B<min_values>

Returns the payload (or payloads) with the lowest priority as an array
reference. Alias: B<pop>.

=item B<max>

Returns the lowest priority C<[[payload],priority]> array reference.

=item B<max_values>

Returns the payload (or payloads) with the highest priority as an array
reference.

=item B<pop>

Alias for B<min_values>. Makes the interface similar to that of
L<List::PriorityQueue>.

=back

=head1 BUGS

<https://github.com/thrig/List-GroupingPriorityQueue>

=head1 SEE ALSO

L<List::PriorityQueue> - what I used in L<Game::PlatformsOfPeril>, and
what this module is based on. Other priority queue modules on CPAN have
different features that may suit particular needs better, see e.g.
L<Array::Queue::Priority>, L<Hash::PriorityQueue>, and
L<Queue::Priority>, among others.

L<Music::RhythmSet> makes use of this module to record changes in beat
patterns across multiple musical voices.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
