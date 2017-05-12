package List::Priority;

use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
use Carp;
use List::Util qw/min max/;

$VERSION = '0.05';


# Constructor. Enables Inheritance
sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	if (@_) {
		my %options = @_;
		$self->{options} = \%options;
	}
	$self->{size} = 0;
	return $self;
}

# Insert an element into the list
sub insert {
	# Arguments check
	croak 'List::Priority - Expected 3 arguments!' if (scalar(@_) != 3);
	# Argument assignment
	(my $self, my $priority, my $object) = @_;
	# Check that priority is numeric - Thanks Randel/Joseph!
	croak 'List::Priority - Priority must be numeric!'
		if ((~$priority & $priority) ne '0');
	# If the list is full
	if (defined($self->{options}{capacity}) and
		$self->{options}{capacity} <= $self->{size}) {
		my ($bottom_priority) = min(keys %{$self->{queues}});
		# And the object's priority is higher than the lowest on the list
		# - remove the lowest one to insert it
		if ($priority > $bottom_priority) {
			$self->_extract($bottom_priority);
		}
		# Else, just return - the list is full.
		else {
			return 'List::Priority - Object denied, list is full';
		}
	}
	# Insert
	push(@{$self->{queues}{$priority}}, $object);
	++$self->{size};
	return 1;
}

# Helper method for pop() and shift()
# If $priority is defined, return the first-in element with that priority.
# Otherwise, use $minmax() to find the best priority in the set, and
# extract the first element with that priority.
sub _extract {
	my ($self, $priority) = @_;
	return undef if ($self->{size} == 0);
	return undef unless (defined ($priority));
	# Remove the queue's first element
	my $object = CORE::shift (@{$self->{queues}{$priority}});
	# If the queue is now empty - delete it
	delete $self->{queues}{$priority}
		if (scalar(@{$self->{queues}{$priority}}) == 0);
	# Return the object I just shifted out of the queue
	--$self->{size};
	return $object;
}

# Find out the extreme (top or bottom) priority
sub _extreme_priority {
	my ($self, $minmax) = @_;
	return $minmax->(keys %{$self->{queues}});
}

sub highest_priority {
	my $self = shift;
	return $self->_extreme_priority(\&max);
}

sub lowest_priority {
	my $self = shift;
	return $self->_extreme_priority(\&min);
}

sub pop {
	# Arguments check
	croak 'List::Priority - pop expected 1 argument' if (scalar(@_) != 1);
	my ($self) = @_;
	return $self->_extract($self->highest_priority);
}

sub shift {
	# Arguments check
	croak 'List::Priority - shift expected 1 argument' if (scalar(@_) != 1);
	my ($self) = @_;
	return $self->_extract($self->lowest_priority);
}

sub size {
	my ($self) = @_;
	return $self->{size};
}

sub capacity {
	my ($self, $new_capacity) = @_;
	if (@_ > 1) {
		$self->{options}{capacity} = $new_capacity;
		if (defined $new_capacity) { 
			while ($self->size > $new_capacity) {
				$self->shift;
			}
		}
	}
	return $self->{options}{capacity};
}

1;
__END__
# Documentation

=head1 NAME

List::Priority - Perl extension for a list that manipulates objects by their
priority


=head1 SYNOPSIS

  use List::Priority;

  # Create an instance
  my $list = List::Priority->new();

  # Insert some elements, each with a unique priority
  $list->insert(2,'World!');
  $list->insert(5,'Hello');
  $list->insert(3,' ');

  # Print
  print $list->size()			# prints 3
  while (my $element = $list->pop()) {
  	  print $element;
  }


=head1 DESCRIPTION

If you want to handle multiple data items by their order of importance,
this one's for you.

You may retrieve the highest-priority item from the list using C<pop()>, or the
lowest-priority item from the list using C<shift()>. If two items have the same
priority, they are returned in first-in, first-out order. New items are
inserted using C<insert()>.

You can constrain the capacity of the list using the C<capacity> parameter.
Low-priority items are automatically evicted once the specified capacity is
exceeded. By default the list's capacity is unlimited.

Currently insertion (in ordered or random order) is constant-time, but C<shift>
and C<pop> are linear in the number of priorities. Hence List::Priority is a
good choice if one of the following conditions is true:

=over

=item * you need one of its unusual features, like the ability to remove both
high- and low-priority items, or to constrain the list's capacity,

=item * you need to do a lot of inserting, but the list will never contain more
than a few thousand different priority levels.

=back

If neither of these describes your use case, another priority queue
implementation like L<POE::XS::Queue::Array> may perform better.

I'd like to thank Joseph N. Hall and Randal L. Schwartz for their
excellent book "Effective Perl Programming" for one of the code hacks.

=head1 METHODS

=over 4


=item B<new>

  $p_list = List::Priority->new();

B<new> is the constructor for List::Priority objects. It accepts a key-value
list with the list attributes.

=over 

=item * B<capacity>

The maximum size of the list.

Inserting after the capacity is reached will result either in a no-op, or the
removal of the most recent lowest priority objects, according to the
C<insert()>'s priority.

  $list = List::Priority->new(capacity => 10);

=back

=item B<insert>

  $result = $p_list->insert($priority, $scalar);

Inserts the scalar to the list. Time taken is approximately constant.

C<$priority> must be numeric. C<$scalar> can be any scalar, including
references (objects).

Returns 1 on success, and a string describing the error upon failure.

=item B<pop>

  $object = $p_list->pop();

Extracts the highest-priority scalar from the list.
Time taken is approximately linear in the number of I<priorities> already in
the list.

Returns the highest-priority object on success, and C<undef> on failure.

=item B<shift>

  $object = $p_list->shift();

Extracts the B<lowest>-priority scalar from the list.
Time taken is approximately linear in the number of I<priorities> already in
the list.

Returns the lowest-priority object on success, C<undef> on failure.

=item B<highest_priority>

  $priority = $p_list->highest_priority();

Returns the priority of the highest-priority item. Time taken is linear in the
number of priorities in the list.

=item B<lowest_priority>

  $priority = $p_list->lowest_priority();

Returns the priority of the lowest-priority item. Time taken is linear in the
number of priorities in the list.

=item B<size>

  $num_elts = $p_list->size();

Takes no arguments. Returns the number of elements in the priority queue.
Time taken is constant.

=item B<capacity>

  my $capacity = $l->capacity();  # get capacity
  $l->capacity($new_capacity);    # set capacity to $new_capacity
  $l->capacity(undef);            # set capacity to infinity

Get/set the list's capacity. If called with an argument, sets the capacity to
that value, discarding any excess low-priority items. To make the capacity
infinite (the default for new lists), call C<capacity()> with an explicit
undefined argument.
Time taken is O($old_capacity - $new_capacity) if $new_capacity <
$old_capacity, constant otherwise.

Returns the (new) capacity.

=back

=head1 EXPORT

None. All interfaces are OO.


=head1 TODO

More tests.


=head1 AUTHOR

Eyal Udassin, <eyaludassin@hotmail.com>

Currently maintained by Miles Gould, <miles@assyrian.org.uk>

Thanks to Maik Hentsche for bugfixes.

=head1 CONTRIBUTING

You can find the Git repository at L<http://github.com/pozorvlak/List-Priority>.

=head1 SEE ALSO

L<Heap::Priority>, L<List::PriorityQueue>, L<Hash::PriorityQueue>,
L<POE::Queue>, L<Timeout::Queue>, L<Data::PrioQ::SkewBinomial>.

=cut
