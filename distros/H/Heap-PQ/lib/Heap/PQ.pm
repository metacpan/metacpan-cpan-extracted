package Heap::PQ;
use strict;
use warnings;
our $VERSION = '0.03';
require XSLoader;
XSLoader::load('Heap::PQ', $VERSION);
1;

__END__

=head1 NAME

Heap::PQ - Binary heap (priority queue) 

=head1 SYNOPSIS

	use Heap::PQ 'import';

	# Create a min-heap (smallest element at top)
	my $min_heap = Heap::PQ::new('min');

	# Create a max-heap (largest element at top)
	my $max_heap = Heap::PQ::new('max');

	# Push values - O(log n)
	heap_push($min_heap, 5);
	heap_push($min_heap, 3);
	heap_push($min_heap, 7);
	heap_push($min_heap, 1);

	# Pop returns smallest (for min-heap) - O(log n)
	print heap_pop($min_heap);   # 1
	print heap_pop($min_heap);   # 3
	print heap_pop($min_heap);   # 5
	print heap_pop($min_heap);   # 7

	# Peek without removing - O(1)
	heap_push($min_heap, 10);
	print heap_peek($min_heap);  # 10

	# Peek top N elements in order
	my @top3 = heap_peek_n($min_heap, 3);

	# Search for elements matching a condition
	my @found = heap_search($min_heap, sub { $_ > 5 });

	# Delete elements matching a condition
	my $deleted = heap_delete($min_heap, sub { $_ > 8 });

	# Utility methods - O(1)
	my $size = heap_size($min_heap);
	my $empty = heap_is_empty($min_heap);
	my $type = heap_type($min_heap);  # 'min' or 'max'
	heap_clear($min_heap);

	# Custom comparator for complex objects
	my $heap = Heap::PQ::new('min', sub {
	    $a->{priority} <=> $b->{priority}
	});

	heap_push($heap, { name => 'low',    priority => 10 });
	heap_push($heap, { name => 'high',   priority => 1  });
	heap_push($heap, { name => 'medium', priority => 5  });

	print heap_pop($heap)->{name};  # 'high'

	# Key path comparator - comparison stays in C
	my $fast = Heap::PQ::new('min', 'priority');
	heap_push($fast, { name => 'low',    priority => 10 });
	heap_push($fast, { name => 'high',   priority => 1  });
	print heap_pop($fast)->{name};  # 'high'

	# Nested key paths with dot notation
	my $nested = Heap::PQ::new('min', 'meta.score');
	heap_push($nested, { id => 'a', meta => { score => 42 } });
	heap_push($nested, { id => 'b', meta => { score => 17 } });
	print heap_pop($nested)->{id};  # 'b'

=head1 DESCRIPTION

C<Heap::PQ> provides a binary heap implementation in C. A heap is a
tree-based data structure that satisfies the heap property: in a min-heap,
the parent is always smaller than its children; in a max-heap, the parent
is always larger.

This makes heaps ideal for priority queues where you need efficient access
to the minimum or maximum element.

C<Heap::PQ> provides both a functional interface (with C<heap_push>, C<heap_pop>, etc.),
an OO interface (with methods like C<push>, C<pop>, etc.) and a raw array interface
(with C<push_heap_min>, C<pop_heap_min>, etc.). The functional and array interfaces
uses custom ops for compile-time optimisation, while the OO interface provides a more 
traditional API using XSUBs. The decision was made with the OO interface to not optimise
into Ops as you cannot identify the class at compile time so if I did it could lead to hijacking 
calls to other classes that have the same method names (Slowing those down as all calls to the methods
would run through this code first).

=head1 METHODS

=head2 Heap::PQ::new($type, [$comparator])

Create a new heap.

	my $min_heap = Heap::PQ->new('min');              # Min-heap
	my $max_heap = Heap::PQ->new('max');              # Max-heap
	my $custom   = Heap::PQ->new('min', sub { ... }); # With comparator

Parameters:

=over 4

=item * C<$type> - Either C<'min'> or C<'max'>. Determines whether the
smallest or largest element is at the top.

=item * C<$comparator> - Optional. A code reference that receives two values
in C<$a> and C<$b> (like Perl's C<sort>) and returns -1, 0, or 1
(like C<< <=> >>). When provided, this is used instead of numeric comparison.
Alternatively, a string specifying a dot-separated key path into hash
references (e.g. C<'priority'> or C<'meta.score'>). The numeric value at
that path is extracted once at push time, so sift operations run at full
numeric speed.

=back

=head2 $heap->push($value)

Add an element to the heap. Returns the heap for method chaining.

	$heap->push(42);
	$heap->push($obj)->push($another);  # Chaining

=head2 $heap->push_all(@values)

Add multiple elements to the heap. Returns the heap for method chaining.

	$heap->push_all(1, 2, 3, 4, 5);

=head2 $heap->pop

Remove and return the top element (minimum for min-heap, maximum for
max-heap). Returns C<undef> if the heap is empty.

	my $min = $min_heap->pop;

=head2 $heap->peek

Return the top element without removing it. Returns C<undef> if empty.

	my $min = $min_heap->peek;

=head2 $heap->peek_n($n)

Return the top C<$n> elements in sorted order without removing them.
Returns an empty list if the heap is empty or C<$n> E<lt>= 0.
If C<$n> is greater than the heap size, returns all elements sorted.

	my @top3 = $heap->peek_n(3);
	my @top5 = $nv_heap->peek_n(5);

=head2 $heap->size

Returns the number of elements in the heap.

=head2 $heap->is_empty

Returns true if the heap has no elements.

=head2 $heap->clear

Remove all elements from the heap.

=head2 $heap->type

Returns the heap type as a string: C<'min'> or C<'max'>.

=head2 $heap->search(sub { ... })

Search the heap for elements matching a condition. Sets C<$_> and passes
the element as the first argument to the callback. Returns a list of
matching elements. Does not modify the heap.

	my @big = $heap->search(sub { $_ > 100 });
	my @urgent = $task_heap->search(sub { $_->{priority} < 3 });

=head2 $heap->delete(sub { ... })

Remove all elements matching a condition from the heap. Sets C<$_> and
passes the element as the first argument to the callback. Rebuilds the
heap after deletion using Floyd's algorithm. Returns the number of
deleted elements.

	my $count = $heap->delete(sub { $_ > 100 });
	my $removed = $task_heap->delete(sub { $_->{done} });

=head1 CUSTOM COMPARATORS

For objects or complex sorting, provide a comparator function. The two
elements are passed in C<$a> and C<$b>, exactly like Perl's C<sort>:

	# Sort by 'score' field, highest first (max-heap behavior)
	my $leaderboard = Heap::PQ::new('max', sub {
	    $a->{score} <=> $b->{score}
	});

	# Sort by string field
	my $alpha_heap = Heap::PQ::new('min', sub {
	    $a->{name} cmp $b->{name}
	});

The comparator should return:

=over 4

=item * C<-1> if C<$a> should come before C<$b>

=item * C<0> if they are equal

=item * C<1> if C<$b> should come before C<$a>

=back

=head1 KEY PATH COMPARATORS

When your heap contains hash references and you want to compare by a numeric
field, pass the field name as a string. The comparison happens entirely in C
with no Perl callback overhead:

	my $pq = Heap::PQ::new('min', 'priority');
	$pq->push({ name => 'low', priority => 10 });
	$pq->push({ name => 'high', priority => 1 });
	print $pq->pop->{name};  # 'high'

Dot-separated paths reach into nested hashes:

	my $pq = Heap::PQ::new('min', 'meta.score');
	$pq->push({ id => 'a', meta => { score => 42 } });
	$pq->push({ id => 'b', meta => { score => 17 } });
	print $pq->pop->{id};  # 'b'

The numeric value is extracted once at push time, so sift operations are as
fast as a plain numeric heap.

=head1 FUNCTIONAL INTERFACE

Import functional ops with C<use Heap::PQ 'import'>:

	use Heap::PQ 'import';

	my $h = Heap::PQ::new('min');

	heap_push($h, 5);
	heap_push($h, 3);
	heap_push($h, 1);

	my $size = heap_size($h);   # 3
	my $top = heap_peek($h);    # 1
	my $val = heap_pop($h);     # 1

These functions use custom ops for compile time optimisation.

=head2 heap_push($heap, $value)

Push a value onto the heap. Same as C<< $heap->push($value) >>.

=head2 heap_pop($heap)

Pop and return the top value. Same as C<< $heap->pop >>.

=head2 heap_peek($heap)

Return the top value without removing. Same as C<< $heap->peek >>.

=head2 heap_size($heap)

Return the heap size. Same as C<< $heap->size >>.

=head2 heap_peek_n($heap, $n)

Return the top C<$n> elements in sorted order without removing.
Same as C<< $heap->peek_n($n) >>.

=head2 heap_search($heap, sub { ... })

Search the heap for matching elements. Same as C<< $heap->search(sub { ... }) >>.

=head2 heap_delete($heap, sub { ... })

Delete matching elements from the heap. Same as C<< $heap->delete(sub { ... }) >>.

=head2 heap_is_empty($heap)

Return true if the heap has no elements. Same as C<< $heap->is_empty >>.

=head2 heap_clear($heap)

Remove all elements from the heap. Same as C<< $heap->clear >>.

=head2 heap_type($heap)

Return the heap type as C<'min'> or C<'max'>. Same as C<< $heap->type >>.

=head1 NUMERIC HEAP

For numeric-only data, C<new_nv> creates a heap that stores native doubles
directly, avoiding SV overhead:

	my $h = Heap::PQ::new_nv('min');

	$h->push(3.14);
	$h->push(2.71);
	$h->push(1.41);

	print $h->pop;  # 1.41
	print $h->pop;  # 2.71

Methods: C<push>, C<push_all>, C<pop>, C<peek>, C<peek_n>, C<search>, C<delete>, C<size>, C<is_empty>, C<clear>.

=head1 RAW ARRAY API

For maximum performance, operate directly on Perl arrays. Import with
C<use Heap::PQ 'raw'>:

	use Heap::PQ 'raw';

	my @arr = (5, 3, 7, 1, 4);

	# Convert array to heap in O(n)
	Heap::PQ::make_heap_min(\@arr);
	Heap::PQ::make_heap_max(\@arr);

	# Push/pop operations
	Heap::PQ::push_heap_min(\@arr, 2);
	my $min = Heap::PQ::pop_heap_min(\@arr);

	Heap::PQ::push_heap_max(\@arr, 8);
	my $max = Heap::PQ::pop_heap_max(\@arr);

=head2 Heap::PQ::make_heap_min(\@array)

Convert an array into a min-heap in O(n) time.

=head2 Heap::PQ::make_heap_max(\@array)

Convert an array into a max-heap in O(n) time.

=head2 Heap::PQ::push_heap_min(\@array, $value)

Push a value onto a min-heap array.

=head2 Heap::PQ::pop_heap_min(\@array)

Pop and return the minimum from a min-heap array.

=head2 Heap::PQ::push_heap_max(\@array, $value)

Push a value onto a max-heap array.

=head2 Heap::PQ::pop_heap_max(\@array)

Pop and return the maximum from a max-heap array.

=head1 EXAMPLES

=head2 Simple Priority Queue

	use Heap::PQ;

	my $pq = Heap::PQ::new('min');
	$pq->push(5);
	$pq->push(1);
	$pq->push(3);

	while (!$pq->is_empty) {
	    print $pq->pop, "\n";  # Prints: 1, 3, 5
	}

=head2 Task Scheduler

	use Heap::PQ 'import';

	my $tasks = Heap::PQ::new('min', sub {
	    $a->{due} <=> $b->{due}
	});

	heap_push($tasks, { name => 'Report',  due => 1706745600 });
	heap_push($tasks, { name => 'Meeting', due => 1706659200 });
	heap_push($tasks, { name => 'Review',  due => 1706832000 });

	# Process tasks in order of due date
	while (!heap_is_empty($tasks)) {
	    my $task = heap_pop($tasks);
	    print "Do: $task->{name}\n";
	}

=head2 Task Scheduler with Key Path

	use Heap::PQ 'import';

	# Same result, but comparison stays in C
	my $tasks = Heap::PQ::new('min', 'due');

	heap_push($tasks, { name => 'Report',  due => 1706745600 });
	heap_push($tasks, { name => 'Meeting', due => 1706659200 });
	heap_push($tasks, { name => 'Review',  due => 1706832000 });

	while (!heap_is_empty($tasks)) {
	    my $task = heap_pop($tasks);
	    print "Do: $task->{name}\n";
	}

=head2 Finding K Largest Elements

	use Heap::PQ 'raw';

	my @numbers = (3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5);
	my $k = 3;

	# Use min-heap of size k
	my @heap;
	for my $n (@numbers) {
	    push_heap_min(\@heap, $n);
	    if (@heap > $k) {
	        pop_heap_min(\@heap);  # Remove smallest
	    }
	}

	# Heap now contains k largest
	my @largest;
	while (@heap) {
	    push @largest, pop_heap_min(\@heap);
	}
	print "@largest\n";  # 5 6 9

=head1 BENCHMARK

	Test: Push 1000 random integers
	----------------------------------------
			 Rate Pure Perl Array::Heap Heap::PQ raw Heap::PQ OO Heap::PQ func Heap::PQ NV
	Pure Perl      1592/s        --        -88%         -89%        -89%          -93%        -96%
	Array::Heap   13301/s      735%          --          -9%        -11%          -43%        -69%
	Heap::PQ raw  14629/s      819%         10%           --         -2%          -37%        -66%
	Heap::PQ OO   14965/s      840%         13%           2%          --          -36%        -65%
	Heap::PQ func 23206/s     1357%         74%          59%         55%            --        -46%
	Heap::PQ NV   42796/s     2588%        222%         193%        186%           84%          --

	Test: Push 1000 random integers then pop all (heapsort)
	----------------------------------------
			 Rate Pure Perl Array::Heap Heap::PQ OO Heap::PQ raw Heap::PQ func Heap::PQ NV
	Pure Perl       296/s        --        -95%        -95%         -96%          -97%        -98%
	Array::Heap    6393/s     2061%          --         -1%          -6%          -43%        -62%
	Heap::PQ OO    6482/s     2091%          1%          --          -4%          -43%        -61%
	Heap::PQ raw   6786/s     2194%          6%          5%           --          -40%        -60%
	Heap::PQ func 11275/s     3711%         76%         74%          66%            --        -33%
	Heap::PQ NV   16770/s     5569%        162%        159%         147%           49%          --

	Test: Bulk insert 1000 items (push_all / make_heap)
	----------------------------------------
			     Rate Pure Perl Array::Heap make Heap::PQ push_all Heap::PQ make_min
	Pure Perl          1607/s        --             -96%              -96%              -97%
	Array::Heap make  43202/s     2588%               --               -6%              -28%
	Heap::PQ push_all 45787/s     2749%               6%                --              -24%
	Heap::PQ make_min 60111/s     3640%              39%               31%                --

	Test: Peek 10000 times on pre-built heap of 1000
	----------------------------------------
			Rate     Pure Perl   Heap::PQ OO   Array::Heap Heap::PQ func
	Pure Perl     2022/s            --          -38%          -66%          -78%
	Heap::PQ OO   3286/s           62%            --          -45%          -64%
	Array::Heap   6011/s          197%           83%            --          -34%
	Heap::PQ func 9130/s          352%          178%           52%            --

	Test: Mixed push/pop (priority queue simulation, 500 rounds)
	----------------------------------------
			 Rate     Pure Perl   Array::Heap   Heap::PQ OO Heap::PQ func
	Pure Perl       413/s            --          -95%          -96%          -97%
	Array::Heap    7700/s         1762%            --          -22%          -49%
	Heap::PQ OO    9817/s         2274%           27%            --          -35%
	Heap::PQ func 15036/s         3536%           95%           53%            --

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
