package List::Permutor;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '0.022';

sub new {
    my $class = shift;
    my $items = [ @_ ];
    bless [ $items, [ 0..$#$items ] ], $class;
}

sub reset {
    my $self = shift;
    my $items = $self->[0];
    $self->[1] = [ 0..$#$items ];
    1;		# No useful return value
}

sub peek {
    my $self = shift;
    my $items = $self->[0];
    my $rv = $self->[1];
    @$items[ @$rv ];
}

sub next {
    my $self = shift;
    my $items = $self->[0];
    my $rv = $self->[1];	# return value array
    return unless @$rv;
    my @next = @$rv;
    # The last N items in @next (for 1 <= N <= @next) are each
    # smaller than the one before. Move those into @tail.
    my @tail = pop @next;
    while (@next and $next[-1] > $tail[-1]) {
        push @tail, pop @next;
    }
    # Then there's one more. Right?
    if (defined(my $extra = pop @next)) {
	# The extra one exchanges with the next larger one in @tail
	my($place) = grep $extra < $tail[$_], 0..$#tail;
	($extra, $tail[$place]) = ($tail[$place], $extra);
	# And the next order is what you get by assembling the three
	$self->[1] = [ @next, $extra, @tail ];
    } else {
        # Guess that's all....
	$self->[1] = [];
    }
    return @$items[ @$rv ];
}

1;
__END__

=head1 NAME

List::Permutor - Process all possible permutations of a list

=head1 SYNOPSIS

  use List::Permutor;
  my $perm = new List::Permutor qw/ fred barney betty /;
  while (my @set = $perm->next) {
      print "One order is @set.\n";
  }

=head1 DESCRIPTION

Make the object by passing a list of the objects to be
permuted. Each time that next() is called, another permutation
will be returned. When there are no more, it returns the empty
list.

=head1 METHODS

=over 4

=item new LIST

Returns a permutor for the given items. 

=item next

Returns a list of the items in the next permutation. Permutations are
returned "in order". That is, the permutations of (1..5) will be
sorted numerically: The first is (1, 2, 3, 4, 5) and the last is (5,
4, 3, 2, 1).

=item peek

Returns the list of items which would be returned by next(), but
doesn't advance the sequence. Could be useful if you wished to skip
over just a few unwanted permutations.

=item reset

Resets the iterator to the start. May be used at any time, whether the
entire set has been produced or not. Has no useful return value.

=back

=head1 AUTHOR

Tom Phoenix <rootbeer@redcat.com>

=cut
