package Doubly;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.12';

# Shared storage for refs that need to survive across threads
our %_ref_storage;
our $_ref_next_id;
our $_sharing_initialized;

# Initialize sharing at compile time if threads are already loaded
BEGIN {
	# Initialize variables here before any runtime code overwrites them
	$Doubly::_ref_next_id = 0;
	$Doubly::_sharing_initialized = 0;
	
	if ($INC{'threads.pm'}) {
		require threads::shared;
		# Use fully qualified function name with explicit refs
		&threads::shared::share(\%Doubly::_ref_storage);
		&threads::shared::share(\$Doubly::_ref_next_id);
		$Doubly::_sharing_initialized = 1;
	}

	# Minimal helpers for XS to store/retrieve from shared hash
	# (shared hashes need Perl-side assignment to work correctly)
	sub _xs_store_ref { $_ref_storage{$_[0]} = $_[1] }
	sub _xs_get_ref   { $_ref_storage{$_[0]} }
	sub _xs_clear_ref { delete $_ref_storage{$_[0]} }
}

require XSLoader;
XSLoader::load('Doubly', $VERSION);

1;

__END__

=head1 NAME

Doubly - Thread-safe doubly linked list

=head1 VERSION

Version 0.12

=head1 SYNOPSIS

	use Doubly;

	my $list = Doubly->new();

	$list->bulk_add(1..100000);

	$list->data; # 1;

	$list->length; # 100000;

	$list = $list->end;

	$list->data; # 100000;

	$list->prev->data; # 99999);

	$list->destroy(); # explicitly calling destroy is important

=head2 Thread-Safe Usage

	use Doubly;
	use threads;

	my $list = Doubly->new();

	# Can be safely used from multiple threads
	my @threads;
	for my $i (1..4) {
		push @threads, threads->create(sub {
			my $tid = shift;
			for my $j (1..10) {
				$list->add("thread_${tid}_item_$j");
			}
		}, $i);
	}
	$_->join for @threads;

	print "Length: ", $list->length, "\n";  # 40

	$list->destroy();

=head1 DESCRIPTION

This module provides a B<thread-safe> doubly linked list implemented in C with
XS bindings for Perl. It uses a global registry with mutex locking to ensure
safe concurrent access from multiple threads.

=head2 Architecture: Registry vs Raw Pointers

The key architectural difference between B<Doubly> and B<Doubly::Pointer> is how
they store list references in Perl:

B<Doubly> uses an B<ID-based registry>:

	┌─────────────────────────────────────────────────┐
	│              GLOBAL REGISTRY (C)                │
	│  list_registry[0] → List { head, tail, ... }    │
	│  list_registry[1] → List { head, tail, ... }    │
	│              (protected by mutex)               │
	└─────────────────────────────────────────────────┘
	            ↑                    ↑
	       Perl $list1           Perl $list2
	       holds ID = 0          holds ID = 1

Perl objects store an B<integer ID>, not a pointer. All lists live in a global
C registry. Every operation does: C<LOCK → lookup by ID → operate → UNLOCK>.
When Perl clones an SV across threads, it just copies the integer - the actual
list data stays in place and remains accessible from any thread.

B<Doubly::Pointer> uses B<raw pointers>:

	Perl $list ──→ DoublyLess* (C pointer)
	               { data, next, prev }

Perl objects store raw C pointers directly. No registry, no locking, no
indirection. This is simpler, but B<fatally flawed for threads>: when Perl
clones an SV across threads, it copies the pointer value - but that pointer
is only valid in the original interpreter's memory space. Accessing it from
another thread causes crashes or memory corruption.

=head2 Why Doubly is Fast

Despite the mutex overhead, Doubly outperforms Doubly::Pointer because:

=over 4

=item * Mutex operations are extremely fast when uncontended (nanoseconds)

=item * Hash lookup by integer key is O(1)

=item * Scalars and numbers are serialised to C strings, avoiding SV overhead

=item * Only references use the more complex shared storage mechanism

=back

=head2 Comparison with Other Modules

=over 4

=item * B<Doubly> (this module) - Thread-safe C implementation using a global
registry and mutex locks. Safe for use across threads and forks. The fastest
option while still providing full thread safety. Supports storing scalars,
strings, numbers, and references (hash/array refs are automatically cloned
using C<threads::shared::shared_clone> when threads are in use).

=item * L<Doubly::Pointer> - Non-thread-safe C implementation using raw pointers.
B<NOT> safe for use across threads or forks. Use this only if you need to
avoid the thread-safety machinery entirely.

=item * L<Doubly::Linked> - XS/C implementation that constructs a hash
structure to represent the linked list. Approximately 7x slower than Doubly.
When you inspect a Doubly::Linked variable, you see the full hash structure,
unlike Doubly and Doubly::Pointer which show only a memory address reference.

=item * L<Doubly::Linked::PP> - Pure Perl implementation requiring no XS
compilation. Approximately 18x slower than Doubly but portable and easy to
debug.

=back

=head2 What is a Doubly Linked List?

A doubly linked list is a data structure consisting of nodes where each node
contains three parts:

=over 4

=item 1. B<Data> - The value stored in the node

=item 2. B<Previous pointer> - A reference to the previous node in the list

=item 3. B<Next pointer> - A reference to the next node in the list

=back

Unlike a singly linked list (which only has next pointers), the doubly linked
list allows traversal in B<both directions> - forward and backward. This makes
operations like reverse iteration, insertion before a node, and deletion more
efficient, though at the cost of additional memory for the extra pointer.

=for html <img style="width:500px" src="https://raw.githubusercontent.com/ThisUsedToBeAnEmail/Doubly-Linked/master/doubly-linked.png" title="img-tag, local-dist" alt="Inlineimage" />

=head1 METHODS

=head2 new

Create a new list. Optionally takes an initial data value.

	my $list = Doubly->new();
	my $list = Doubly->new($initial_value);

=head2 length

Returns the length of the list.

	my $len = $list->length;

=head2 data

Get or set the data at the current position.

	my $value = $list->data;
	$list->data($new_value);

=head2 start

Move to the start of the list. Returns $self for chaining.

	$list->start;

=head2 end

Move to the end of the list. Returns $self for chaining.

	$list->end;

=head2 next

Move to the next node. Returns $self for chaining.

	$list->next;

=head2 prev

Move to the previous node. Returns $self for chaining.

	$list->prev;

=head2 is_start

Returns true if at the start of the list.

	if ($list->is_start) { ... }

=head2 is_end

Returns true if at the end of the list.

	if ($list->is_end) { ... }

=head2 add

Add an item to the end of the list.

	$list->add($value);

=head2 bulk_add

Add multiple items to the end of the list.

	$list->bulk_add(1, 2, 3, 4, 5);

=head2 remove_from_start

Remove and return the first item.

	my $value = $list->remove_from_start;

=head2 remove_from_end

Remove and return the last item.

	my $value = $list->remove_from_end;

=head2 remove

Remove and return the item at the current position. Current position moves
to the next node (or previous if at end).

	my $value = $list->remove;

=head2 remove_from_pos

Remove and return the item at the specified position (0-indexed).

	my $value = $list->remove_from_pos(2);  # Remove third item

=head2 insert_before

Insert an item before the current position. Current position moves to the
new node. Returns $self for chaining.

	$list->insert_before($value);

=head2 insert_after

Insert an item after the current position. Current position moves to the
new node. Returns $self for chaining.

	$list->insert_after($value);

=head2 insert_at_start

Insert an item at the start of the list. Returns $self for chaining.

	$list->insert_at_start($value);

=head2 insert_at_end

Insert an item at the end of the list. Same as C<add>. Returns $self for chaining.

	$list->insert_at_end($value);

=head2 insert_at_pos

Insert an item at the specified position (0-indexed). Returns $self for chaining.

	$list->insert_at_pos(2, $value);  # Insert at position 2

=head2 find

Find a node using a callback. The callback receives each node's data and should
return true when the desired node is found. Current position moves to the found
node. Returns $self if found, undef otherwise.

	my $found = $list->find(sub { $_[0] eq 'target' });
	if ($found) {
	    print "Found: ", $list->data, "\n";
	}

=head2 insert (with callback)

Find a position using a callback, then insert data before it. If the callback
never returns true, inserts at the end. Returns $self for chaining.

	# Insert 5 before the first value > 5
	$list->insert(sub { $_[0] > 5 }, 5);

=head2 destroy

Explicitly destroy the list and free all memory.

	$list->destroy;

=head1 THREAD SAFETY

This module is designed to be thread-safe. You can:

=over 4

=item * Create a list in one thread and use it in another

=item * Have multiple threads adding/removing items concurrently

=item * Share the list object across threads

=back

All operations are protected by a mutex.

=head1 NESTED LISTS

You can store Doubly lists inside other Doubly lists. When you navigate a nested
list via chained method calls, the inner list's current position is updated:

	my $outer = Doubly->new();
	my $inner = Doubly->new();
	$inner->bulk_add(qw/a b c d e f g/);

	my $inner2 = Doubly->new();
	$inner2->bulk_add(1..1000, $inner);  # inner list is last item

	$outer->bulk_add($inner, $inner2);

	# Navigate outer list
	$outer->start;
	is($outer->data->data, 'a');              # inner list, first item
	is($outer->data->next->data, 'b');        # navigates inner, returns 'b'
	
	# Navigate to inner2, then to its last item (which is $inner)
	is($outer->next->data->data, 1);          # inner2's first item
	is($outer->next->data->end->data->start->data, 'a');  # deeply nested!

B<Important:> Chained navigation calls like C<< $list->data->next >> modify the
nested list's position. The C<< ->next >> call operates on and updates the inner
list object itself. This is intentional - it allows natural traversal of nested
structures.

B<Difference from Doubly::Pointer:> In L<Doubly::Pointer>, when you retrieve a nested
list via C<< ->data >>, you get a fresh copy each time - so chained navigation
doesn't affect subsequent retrievals. In Doubly, you get the B<same shared object>,
so navigation state persists:

	# Doubly::Pointer - each ->data returns a fresh copy
	$list->data->next->data;              # Moves a temporary copy
	$list->data->data;                    # Still 'a' - fresh copy, at start
	
	# Doubly - ->data returns the same shared object  
	$list->data->next->data;              # Moves the actual nested list
	$list->data->data;                    # Now 'b' - position was updated!
	$list->data->start->data;             # Need ->start to get back to 'a'

This is why in the test files, Doubly needs C<< ->start >> to reset position:

	# 71-pointer-nested.t (Doubly::Pointer)
	is($list->next->data->end->data->data, 'a');        # No reset needed
	
	# 18-nested.t (Doubly)  
	is($list->next->data->end->data->start->data, 'a'); # Needs ->start

If you need copy-on-access behaviour, use Doubly::Pointer. If you prefer stateful
shared access to nested structures, use Doubly.

B<Note for threaded Perl:> When threads are enabled, nested Doubly lists stored
as data use C<threads::shared::shared_clone> to make them accessible across
threads. However, deeply nested access patterns with multiple lock acquisitions
can potentially cause deadlocks in complex scenarios. For simpler, safer usage
in threaded code, retrieve the nested list into a variable before navigating:

	my $nested = $list->data;    # Get the nested list
	$nested->start;              # Navigate it separately
	my $value = $nested->data;

=HEAD1 BENCHMARKS
	
	my $r = timethese(10000, {
		'Doubly::Linked' => sub {
			my $linked = Doubly::Linked->new(123);
			$linked->bulk_add(0..1000);
			$linked = $linked->end;
			$linked->is_end;
			$linked = $linked->start;
			$linked->is_start;
			$linked->add(789);
			$linked->destroy;
		},
		'Doubly::Linked::PP' => sub {
			my $linked = Doubly::Linked::PP->new(123);
			$linked->bulk_add(0..1000);
			$linked = $linked->end;
			$linked->is_end;
			$linked = $linked->start;
			$linked->is_start;
			$linked->add(789);
		},
		'Doubly' => sub {
			my $linked = Doubly->new(123);
			$linked->bulk_add(0..1000);
			$linked = $linked->end;
			$linked->is_end;
			$linked = $linked->start;
			$linked->is_start;
			$linked->add(789);
			$linked->destroy;
		},
		'Doubly::Pointer' => sub {
			my $linked = Doubly::Pointer->new(123);
			$linked->bulk_add(0..1000);
			$linked = $linked->end;
			$linked->is_end;
			$linked = $linked->start;
			$linked->is_start;
			$linked->add(789);
			$linked->destroy;
		},
	});

	cmpthese $r;

Docker perl:5.38-threaded - Threaded environment (where only Doubly is truly safe):

	Benchmark: timing 10000 iterations of Doubly, Doubly::Linked, Doubly::Linked::PP, Doubly::Pointer...
	    Doubly: 0.704658 wallclock secs ( 0.70 usr +  0.00 sys =  0.70 CPU) @ 14285.71/s (n=10000)
	Doubly::Linked: 4.71918 wallclock secs ( 3.10 usr +  1.61 sys =  4.71 CPU) @ 2123.14/s (n=10000)
	Doubly::Linked::PP: 12.1816 wallclock secs (10.76 usr +  1.39 sys = 12.15 CPU) @ 823.05/s (n=10000)
	Doubly::Pointer: 0.778561 wallclock secs ( 0.77 usr +  0.00 sys =  0.77 CPU) @ 12987.01/s (n=10000)
			      Rate Doubly::Linked::PP Doubly::Linked Doubly::Pointer Doubly
	Doubly::Linked::PP   823/s                 --           -61%            -94%   -94%
	Doubly::Linked      2123/s               158%             --            -84%   -85%
	Doubly::Pointer    12987/s              1478%           512%              --    -9%
	Doubly             14286/s              1636%           573%             10%     --

Docker perl:5.38 - None threaded environment:

	Benchmark: timing 10000 iterations of Doubly, Doubly::Linked, Doubly::Linked::PP, Doubly::Pointer...
	    Doubly: 0.712633 wallclock secs ( 0.70 usr +  0.01 sys =  0.71 CPU) @ 14084.51/s (n=10000)
	Doubly::Linked: 16.0794 wallclock secs ( 4.05 usr +  5.75 sys =  9.80 CPU) @ 1020.41/s (n=10000)
	Doubly::Linked::PP: 13.0293 wallclock secs (11.73 usr +  1.27 sys = 13.00 CPU) @ 769.23/s (n=10000)
	Doubly::Pointer: 0.775681 wallclock secs ( 0.77 usr +  0.00 sys =  0.77 CPU) @ 12987.01/s (n=10000)
			      Rate Doubly::Linked::PP Doubly::Linked Doubly::Pointer Doubly
	Doubly::Linked::PP   769/s                 --           -25%            -94%   -95%
	Doubly::Linked      1020/s                33%             --            -92%   -93%
	Doubly::Pointer    12987/s              1588%          1173%              --    -8%
	Doubly             14085/s              1731%          1280%              8%     --

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
