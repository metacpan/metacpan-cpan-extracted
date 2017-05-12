package Heap::Priority;
use Carp;
use strict;
use vars '$VERSION';
$VERSION = 0.01;

sub new {
    my $class    = shift;
    my $defaults = { '.priorities'    => [],
                     '.fifo'          => 1,
                     '.highest_first' => 1,
                     '.raise_error'   => 0,
                     '.error_message' => '' };
  return bless $defaults, $class;
}

sub fifo { $_[0]->{'.fifo'} = 1 }
sub lifo { $_[0]->{'.fifo'} = 0 }
sub highest_first { $_[0]->{'.highest_first'} = 1 }
sub lowest_first  { $_[0]->{'.highest_first'} = 0 }
sub raise_error   { $_[0]->{'.raise_error'} = shift || 0 }

sub add {
    my ($self, $item, $priority) = @_;
    $priority ||= 0;
    unless (defined $item) {
        $self->error("Need to supply an item to add to heap!\n");
      return undef;
    }
    push @{$self->{'.items'}->{$item}}, $priority;
    # we need to re-sort priorities if new priority level supplied with item
    $self->{'.priorities'} = [ sort { $a <=> $b } ( @{$self->{'.priorities'}}, $priority ) ]
        unless exists $self->{'.heap'}->{$priority};
    push @{$self->{'.heap'}->{$priority}}, $item;
}

sub pop {
    my $self = shift;
    my @priorities = @{$self->{'.priorities'}};
  return undef unless @priorities;
    my $priority = $self->{'.highest_first'} ? pop   @priorities :
                                               shift @priorities;
    my $item = $self->{'.fifo'} ? shift @{$self->{'.heap'}->{$priority}}:
                                  pop   @{$self->{'.heap'}->{$priority}};
    $self->delete_item($item, $priority, 1);
  return $item;
}

sub delete_priority_level {
    my ($self, $priority) = @_;
    if (exists $self->{'.heap'}->{$priority}) {
       my @items = @{$self->{'.heap'}->{$priority}};
       delete $self->{'.items'}->{$_} for @items;
       delete $self->{'.heap'}->{$priority};
       $self->{'.priorities'} = [ grep { $_ ne $priority } @{$self->{'.priorities'}} ];
    } else {
        $self->error("Priority level $priority does not exist in heap!\n");
    }
}

sub delete_item {
    my ($self, $item, $priority, $_off_heap) = @_;
    unless (exists $self->{'.items'}->{$item}) {
        $self->error("Item $item does not exist in heap!\n");
      return undef;
    }
    if (defined $priority) {
        # remove item from from appropriate priority level of .heap
        @{$self->{'.heap'}->{$priority}} = grep{$_ ne $item}@{$self->{'.heap'}->{$priority}}
            unless $_off_heap;
        # remove item priority level from .items
        @{$self->{'.items'}->{$item}} = grep {$_ ne $priority} @{$self->{'.items'}->{$item}};
        # remove item if it no longer exists on any priority levels
        delete $self->{'.items'}->{$item} unless @{$self->{'.items'}->{$item}};
        # remove priority level if it is now empty as a result or deleting item
        $self->delete_priority_level($priority) unless @{$self->{'.heap'}->{$priority}};
    } else {
        for my $priority (@{$self->{'.items'}->{$item}}) {
            # remove item from from appropriate priority level of .heap
            @{$self->{'.heap'}->{$priority}} = grep{$_ ne $item}@{$self->{'.heap'}->{$priority}};
            # remove priority level if empty
            $self->delete_priority_level($priority) unless @{$self->{'.heap'}->{$priority}};
        }
        # bye bye item, you are gone
        delete $self->{'.items'}->{$item};
    }
}

sub modify_priority {
    my ($self, $item, $priority) = @_;
    unless (exists $self->{'.items'}->{$item}) {
        $self->error("Item $item does not exist in heap!\n");
      return undef;
    }
    $self->delete_item($item);
    $self->add($item, $priority);
}

sub get_priority_levels {
    my $self = shift;
    my @levels = @{$self->{'.priorities'}};
    @levels = reverse @levels if $self->{'.highest_first'};
  return wantarray ? @levels : scalar @levels;
}

sub get_level {
    my ($self, $priority) = @_;
    unless (exists $self->{'.heap'}->{$priority}) {
        $self->error("Priority level $priority does not exist on heap!\n");
      return undef;
    }
    my @items = @{$self->{'.heap'}->{$priority}};
    @items = reverse @items unless $self->{'.fifo'};
  return wantarray ? @items : scalar @items;
}

sub get_heap {
    my $self = shift;
    my @heap = ();
    my @levels = $self->get_priority_levels();
    push @heap, $self->get_level($_) for @levels;
  return wantarray ? @heap : scalar @heap;
}

sub error {
    my ($self, $error) = @_;
    $self->{'.error_message'} .= $error;
    croak $self->{'.error_message'} if $self->{'.raise_error'} == 2;
    carp  $self->{'.error_message'} if $self->{'.raise_error'} == 1;
}

sub err_str { return $_[0]->{'.error_message'} }

1;
__END__
=head2 NAME

Heap::Priority - Implements a priority queue or stack

=head2 SYNOPSIS

    use Heap::Priority;
    my $h = new Heap::Priority;
    $h->add($item,[$priority]); # add an item to the heap
    $next_item = $h->pop;       # get an item back from heap
    $h->fifo;                   # set first in first out ie a queue (default)
    $h->lifo;                   # set last in first out ie a stack
    $h->highest_first;          # set pop() in high to low priority order (default)
    $h->lowest_first;           # set pop() in low to high priority order

    $h->modify_priority($item, $priority);
    $h->delete_item($item,[$priority]);
    $h->delete_priority_level($priority);
    @levels    = $h->get_priority_levels;
    @items     = $h->get_level($priority);
    @all_items = $h->get_heap;
    $h->raise_error(1);
    my $error_string = $h->err_str;

=head2 DESCRIPTION

This module implements a priority queue or stack. The main functions are add()
and pop() which add and remove from the heap according to the rules you
choose. When you add() an item to the heap you can assign a priority level to
the item or let the priority level default to 0.

What happens when you call pop() depends on the configuration you choose. By
default the highest priority values will be popped off in first in first
out order. fifo() and lifo() set First in First Out and Last In First Out
respectively. highest_first() and lowest_first() allow you to choose to pop()
the highest priority values first or the lowest priority values first.

The internal object model remains constant so you can modify the behavior of
pop() with impunity during the life of a heap object.

modify_priority() allows you to change the priority of a item already in
the heap. A range of other functions are also available to manipulate
the heap.

=head2 EFFICIENCY

The algorithm used in this module is only efficient where the number of
priority levels is either small in absolute terms or some small fraction
of the total number of items. Efficiency drops off over a few thousand
priority levels.

=head2 OBJECT INTERFACE

This is an OO module. You begin by creating a new heap object

    use Heap::Priority;
    my $h = new Heap::Priority;

You then simply call methods on your heap object:

    $h->add($item, $priority);      # add $item with $priority level
    $h->lifo;                       # set Last In First Out (ie stack)
    my $next_item = $h->pop;        # get the next item off the heap

=head2 METHODS

=head3 new()

    my $h = new Heap::Priority;

The constructor takes no arguments and simply returns an empty default heap.
The default configuration is FIFO (ie a queue) with highest integer priority
values popped first

=head3 add($item,[$priority])

    $h->add($item, [$priority]);

add() will add $item to the heap. Optionally a an integer $priority level may
be assigned (default priority level is 0).

=head3 pop()

    my $next_item = $h->pop;

pop() takes no arguments. In default configuration pop() will
return those values having the highest integer priority level first in FIFO
order. This behavior can be modified using the methods outlined below.

=head3 fifo()

    $h->fifo;

Set pop() to work on a First In First Out  basis, otherwise known as a queue.
This is the default configuration.

=head3 lifo()

    $h->lifo;

Set pop() to work on a Last In First Out  basis, otherwise known as a stack.

=head3 highest_first()

    $h->highest_first;

Set pop() to retrieve items in highest to lowest integer priority order. This
is the default configuration.

=head3 lowest_first()

    $h->lowest_first;

Set pop() to retrieve items in lowest to highest integer priority order

=head3 modify_priority($item,[$priority])

    $h->modify_priority($item, $priority);

This method allows you to modify the priority of an item in the queue/stack.
All it actually does is call delete_item($item) and then add($item,$priority)
so all the instances of $item in the heap will be removed and replaced with
a single instance of $item at $priority level

=head3 delete_item($item,[$priority])

    $h->delete_item($item,[$priority]);

This method will delete $item from the heap. If the optional $priority
is not supplied all instances $item will be removed from the heap. If
$priority is supplied then only instances of $item at that priority level
will be removed.

=head3 delete_priority_level($priority)

    $h->delete_priority_level($priority);

Delete all items of priority level $priority

=head3 get_priority_levels()

    my @levels = $h->get_priority_levels;

Returns list of priority levels in current pop() order in list context and
number of priority levels in scalar context

=head3 get_level($priority)

    my @items = $h->get_level($priority);

Returns entire priority level in pop() order in list context or number of
items at that level in scalar context

=head3 get_heap()

    my @all_items = $h->get_heap;

Returns entire heap in pop() order in list context or total number of items
on heap in scalar context

=head3 raise_error($n)

    $h->raise_error(1);

Set error level $n => 2 = croak, 1 = carp, 0 = silent (default)

=head3 err_str()

    $h->err_str;

Return error string if any.

=head2 EXPORT

Nothing: it's an OO module.

=head2 BUGS

Probably. If you find one let me know...

=head2 AUTHOR

Dr James Freeman E<lt>jfreeman@tassie.net.auE<gt>

=cut

