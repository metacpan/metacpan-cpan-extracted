package LinkedList::Single::Example::POD v2.0.0;
use v5.40;

1
__END__

=head1 NAME

LinkedList::Single::Example::POD - what the LinkedList::Single examples are for, and how to read them

=head1 SYNOPSIS

    # the papers, in reading order, are the POD.pm of each example:
    perldoc LinkedList::Single::Example::LRU::POD
    perldoc LinkedList::Single::Example::SlidingWindow::POD
    perldoc LinkedList::Single::Example::Handoff::POD
    perldoc LinkedList::Single::Example::SortedMerge::POD
    perldoc LinkedList::Single::Example::Ordered::POD
    perldoc LinkedList::Single::Example::Timer::POD

    # from the source tree: tests, one program, one comparison
    prove -r t
    perl app/10-LRU/lru-cache
    perl benchmarks/10-LRU/compare

=head1 WHAT THE EXAMPLES ARE

L<LinkedList::Single> is a singly linked list for Perl. A Perl programmer
who has not needed one is right to ask what it is for: perl's arrays and
hashes are fast, built in, and already do most of what a list is used for
in other languages. This project answers by building the same small
program twice, once with the list and once with arrays or hashes, and
putting the two side by side: the code, the time, the memory, and what has
to be kept correct.

There are six examples. Each has

=over 4

=item * a module that does the job with the list, and a "twin" (or several) that does the same job with arrays and hashes, behind the same interface;

=item * tests that run the list and its twin on the same inputs and compare the answers, and check the invariants of the list and that nothing is kept alive or freed too early;

=item * a program that uses the module, and benchmarks that time the two, measure their memory, and where it matters their slowest single call;

=item * a paper (the C<POD.pm> of the example) that tells the story from the problem to the measurements, for a reader with average Perl and less computer science.

=back

The comparison is the point, not the list. The papers say where the list
wins and where it does not, and in most of the measured cases the array is
faster. What the list offers instead is described below, and each paper
states what it costs.

The bar is set high by Perl itself. Array operations are fast, and Perl is
optimized for handling lists through arrays and hashes: C<push>, C<pop>,
C<shift>, C<unshift>, C<splice>, slices, C<sort>, C<map> and C<grep> are
built-in operations, not code that the program has to supply. A linked list
in Perl is built from objects and method calls, so it has to make up that
difference before it does any better than an array, and the papers report
where, at what size, and for what kind of use it does. Where an array or
a hash does the job, it is the right choice.

Perl's speed has a price in space and in the slowest call. A shifted array
does not hand back the room at its front: it reuses it only by moving its
contents down when it runs out of room at the back [4] [8]. A large array
that grows is reallocated, and a hash that grows rehashes its table, each
now and then, inside whichever call happened to need the room. Pops from
an array and deletes from a hash do not necessarily give memory back
either; the examples did not measure those two. A list has none of this:
each node is allocated with its item and released with it, and the cost of
a call hardly depends on the size. So the trade is that a list may be slower
on average, with a more uniform worst call and a tighter hold on space.
The papers measured how far that goes. The array's growth spike was real
and small (a few hundred microseconds with 200,000 messages queued); a
hash rehash was the one slowest call that grew with the size (4.4
milliseconds at 100,000 entries, 24.8 at 400,000); a single sorted array
had to move the whole array. They also measured the limits: in steady
state the array's slowest calls were lower than the list's, an array of
small sorted arrays matched the list's slowest call, and a full list
holds more memory per item than an array, not less. The space is better
managed only where a structure shrinks, as when a burst has passed.

=head1 WHY THESE EXAMPLES

A linked list is not a faster array. It is a different set of operations
with different costs, and an honest comparison has to pick problems that
exercise those operations. The six were chosen to cover the ground, and
two of them to show where the list does not help:

=over 4

=item * B<LRU> (a least-recently-used cache) needs to move an entry to the front when it is used and to drop the oldest when the cache is full. In an array both move other elements or search for the entry; in a list both are a few pointer changes once the entry's place is known. This is the textbook use and the first thing to compare.

=item * B<SlidingWindow> (events kept for a period of time) is the control: events are added at the end and removed from the front, which is the array's best case. It is in the set to show that the list is I<not> better at everything and what the list still provides (memory returned as the burst ends, each event freed as it expires).

=item * B<Handoff> (a work queue passed from a producer to a consumer) needs to hand over the whole queue or a batch of it, to cancel an item from the middle by a handle, and to give back what was not done. Removing from the middle and cutting a run off are the two things arrays do by moving elements.

=item * B<SortedMerge> (merging and sorting) tests the one thing a list can do that a caller of an array cannot: relink nodes instead of copying them. It also tests the limit of the module: the relinking written on the public interface is slower than the array, though the module's own sort uses the technique to beat the array merge sort written in Perl.

=item * B<Ordered> (a map kept in key order) is the hardest case: the list as the building block of a larger structure, with a small index of markers in front of it. It is there to show a design that works, is correct, and loses on speed to an array of small sorted arrays, and to say what kind of use would change that.

=item * B<Timer> (messages dispatched when their start time has passed) needs a bounded batch cut off the queue, worked through for a limited time, and the unfinished rest put back at the front. It is the example for the Fragment: a run of nodes that is detached, owned by one piece of code, consumed, and reattached.

=back

Taken together they cover adding, removing from the end, from the middle and
from the front, moving, cutting a run, reattaching a run, merging, and
holding a position while the list changes around it. In the measurements
the best array or hash version of each example is faster than the list at
the sizes tried; the list beats only the variants whose cost grows with
the size (a search, or moving the elements behind a splice), and the papers give the sizes at which that
happens. On memory the list uses more per item while a structure is full,
and less after a burst has gone (SlidingWindow and Timer); the SortedMerge
figures are not the same measure for list and array, and the paper says so.
The examples are useful for exactly that reason: a reader can see which
properties the list has before deciding that a problem needs one.

=head1 WHAT EACH PAPER COVERS

The papers share an order, so that one can be compared with another:

=over 4

=item * THE PROBLEM, with a short outline of the general algorithm in pseudo-code, independent of any data structure.

=item * the attempts with arrays and hashes, and why they become slow or complicated.

=item * the linked-list version: the idea in words and a diagram, then real code from the module that uses C<LinkedList::Single>, with each call of the module explained.

=item * CHECKING THAT IT IS RIGHT: how the tests compare the list with the array, and what invariants and lifetime tests establish.

=item * WHAT IT COSTS: time (one machine, labelled as such), memory (list against array and, where it applies, hash), and code size.

=item * READABILITY AND CHANGE: whether the code is easier to read and to change. This is a section of side-by-side excerpts and line counts, followed by sub-topics that recur from paper to paper: what a removed or finished item has to leave behind in an array (a placeholder, a stamp, a position counter) and who has to honour it; what the list must keep in step instead (a count, a tail cursor, an index of cursors); what happens to the work that was in progress when a batch stops; and where the list is not simpler.

=item * WHAT TO TAKE FROM IT: what the list provides and does not, stated the same way for the wins and the losses.

=item * WHERE THE TECHNIQUE IS USED, where there is a source that says so, and A NOTE FOR LinkedList::Single, for what the example found in the module.

=item * SEE ALSO: the references, each a numbered footnote with its address.

=back

=head1 SOME FEATURES OF THE MODULE, AND WHAT THEY BUY

The examples use a sample of the module, not all of it. Each feature below
is a place where the list does something an array does by moving data.

=over 4

=item * B<A cursor stands on the node before an entry.> A cursor is a stored position that stays valid while other things change, so a program can keep "the place where this entry is" in a hash; given a
node, the node after it can be removed or a node inserted beside it in
constant time [1]. In L<LinkedList::Single::Example::LRU> the index maps a key to such a cursor, and C<detach> then C<append_to> moves the entry to the front without a search and without moving any other entry. The price is the rule that every removal must repair the cursor of the entry behind it, which the paper states and the tests check.

=item * B<C<detach> cuts a run off by relinking, and returns it as a Fragment.> The run keeps its nodes, its data and its order, and is now an object of its own. L<LinkedList::Single::Example::Timer> cuts the batch of due messages this way and owns it; L<LinkedList::Single::Example::Handoff> hands a batch or the whole queue to the consumer. An array does the same with C<splice> [5], which copies the elements out and moves those behind them down.

=item * B<C<append_to> reattaches a Fragment by relinking.> Putting the unfinished part of a batch back at the front of the queue (in Timer and Handoff) joins the pieces by pointer, without copying either one, and held cursors keep pointing at the same data. The cost is a walk to the end of the Fragment unless the caller already holds a cursor there.

=item * B<C<consume> hands each item to a callback and frees it.> Dispatch in L<LinkedList::Single::Example::Timer> is one call, in which the callback may stop the run by C<die "\n">; what is left is still the Fragment, ready to be put back, so there is no position variable to keep in step with the data. Each node and its payload is released as it is consumed.

=item * B<C<drop> removes the node after a cursor.> Cancel by handle in L<LinkedList::Single::Example::Handoff> is one C<drop>: the node and its payload are released at once, and nothing in the rest of the program sees a "cancelled" item, where an array that cannot remove from the middle cheaply must leave a placeholder that every reader has to skip.

=item * B<C<push> and a tail cursor add at the end without a walk.> L<LinkedList::Single::Example::SlidingWindow> keeps a cursor at the tail, so adding an event is constant time and the memory of the window follows what is in it. The tail cursor has to be repaired whenever the window empties, which is bookkeeping the array does not have.

=item * B<C<first> finds a node by a test.> The sliding window finds where the live events start with one call, in place of an index loop with a bounds check.

=item * B<The module's sort relinks nodes.> Inside C<LinkedList::Single>, sorting relinks the nodes in a merge sort that keeps equal nodes in order. The merge written on the public interface in L<LinkedList::Single::Example::SortedMerge> cannot do that, and the paper reports that it loses to the array.

=back

=head1 WHAT THE EXAMPLES SHOW, IN SHORT

For a reader deciding between an array and a list, the papers agree on a
few points, each with its numbers in the paper:

=over 4

=item * The cost of a list operation hardly depends on the size of the structure [1]. An array that searches, shifts or copies grows with it [2]. This matters when sizes are large or the worst case must be bounded.

=item * Memory follows what is queued, and each item is released as it goes. A list needs more memory per item than an array [2] [6]. An array that is shifted and pushed leaves empty room at its front, which it reuses only by moving its contents down when it runs out of room at the back [4] [8]; the list has no such gap and no such move.

=item * Moving, cutting and reattaching runs of items are single operations, and no position arithmetic is written. Where the array is already the best structure for the job (adding at the end, removing from the front [4], small structures [2]), it is faster and the code is shorter.

=item * A singly linked list has its own bookkeeping: cursors that go stale after a removal, counts and tail cursors kept in step, and one known quirk of the module that holds the last payload alive a little longer. The papers state these along with the benefits.

=back

Taken together, the lists have a mix of advantages and disadvantages in
speed and in size, and the mix differs from one example to the next; each
paper gives its own figures. Three things hold across all six. In each
there is an array or hash version that is faster on average than the list
(the best of them 3 to 50 times, depending on the example), and the code
for it is often shorter. The list beats the versions of the array or hash
whose cost grows with the size, such as a search through the queue, a
copy, or moving the elements behind a C<splice>. And what the list buys is
a cost per call that hardly changes with the size, and memory that is
released as the items go. It does not buy a lower average, and while it is
full it holds more memory per item. So the choice follows what the job
needs: the lowest average cost favours the array or hash; a bounded
slowest call, work that is mostly moving runs of items, or a structure
that grows and then shrinks favours the list.

Why an array usually wins on current hardware, even where counting
operations favours the list, is argued by Stroustrup [2] (list nodes are
scattered in memory, so walking them causes cache misses) and measured by
Drepper [3] (the time per element of walking a list laid out in memory
order against one in random order). Both work in C or C++; in Perl an
array element is itself a pointer to a scalar [4], so their figures do not
carry over to these examples. Lists that hold several items in each node,
to spend less memory on links, are described in [6] and [7].

=head1 THE EXAMPLE MODULES

=over 4

=item * L<LinkedList::Single::Example::LRU>, with C<::Array>, C<::Order> and C<::Lazy>

A least-recently-used cache with its order in a list. Illustrates stored cursors as handles, and moving an entry to the front by C<detach> and C<append_to>. The twins are an array of pairs, a hash with an order array, and a hash with a stamped queue.

=item * L<LinkedList::Single::Example::SlidingWindow>, with C<::Array>

Events kept for a period of time. Illustrates the array's best case as a control, a tail cursor, and memory that returns as a burst expires.

=item * L<LinkedList::Single::Example::Handoff>, with C<::Array> and C<::Marked>

A work queue passed to a consumer, with cancel by handle and a batch given back unfinished. Illustrates C<drop> against placeholders, and hand-over of the whole queue or a batch. L<LinkedList::Single::Example::Lock> is the stand-in lock it records time under.

=item * L<LinkedList::Single::Example::SortedMerge>, with C<::Array>

Merge and merge sort on lists. Illustrates relinking nodes against copying them, consuming inputs, and where the public interface gets slower than the module's own sort.

=item * L<LinkedList::Single::Example::Ordered>, with C<::Buckets>, C<::Sorted> and C<::Hash>

A map in key order, held in a list with an index of markers. Illustrates the list as the building block of a larger structure, cutting whole buckets out as Fragments, and a design that is correct but slower than an array of small sorted arrays.

=item * L<LinkedList::Single::Example::Timer>, with C<::Array>

Messages dispatched when their start time has passed. Illustrates cutting a batch off as a Fragment, C<consume> with a time limit, and putting the unfinished rest back at the front.

=item * L<LinkedList::Single::Example::Bench>, L<LinkedList::Single::Example::Latency> and L<LinkedList::Single::Example::Probe>

The helpers shared by the examples: timing, memory and code-complexity measurement; per-call timing with percentiles and the worst call; and a payload object that records when it is destroyed, used to check that nothing is freed too early or kept too long.

=back

=head1 SEE ALSO

L<LinkedList::Single::Examples>, the distribution and how to build and run it;
L<LinkedList::Single>, the module.

The numbers are the references in the text.

=over 4

=item [1] Morin, I<Open Data Structures>, chapter 3, "Linked Lists"

AU Press, 2013; free on line. Linked lists against array-based lists: no
constant-time access by index, but constant-time removal or insertion next
to a node already held; section 3.1 gives the O(1) push, pop, add at the
tail and remove at the head of a singly linked list.
L<https://opendatastructures.org/ods-python/3_Linked_Lists.html>

=item [2] Stroustrup, "Software Development for Infrastructure"

I<IEEE Computer>, January 2012. Inserts and removes at random positions
found by a linear walk: on the author's laptop a C++ vector beat a linked
list up to well past 500,000 elements, because the list's nodes are larger
and scattered in memory, causing cache misses.
L<https://www.stroustrup.com/Software-for-infrastructure.pdf>

=item [3] Drepper, "What Every Programmer Should Know About Memory"

Red Hat, November 2007. Section 3.3.2, "Measurements of Cache Effects",
times the walk of a singly linked list whose elements are laid out in
memory order and in random order, for growing working sets.
L<https://people.freebsd.org/~lstewart/articles/cpumemory.pdf>

=item [4] perlguts, "Working with AVs" and "Offsets"

A Perl array holds pointers to scalars; shifting off the front is done by
moving the start of the array (C<AvARRAY>) rather than the elements.
L<https://perldoc.perl.org/perlguts>

=item [5] perlfunc, C<splice>

Removes the elements given by an offset and length, replaces them with a
list, and grows or shrinks the array as necessary.
L<https://perldoc.perl.org/functions/splice>

=item [6] Shao, Reppy and Appel, "Unrolling Lists"

I<Proc. 1994 ACM Conference on Lisp and Functional Programming>; Princeton
technical report TR-453-94. Links take about half the storage of a list of
cons cells; an "unrolled" list stores several items in each cell.
L<https://www.cs.princeton.edu/research/techreps/153>

=item [7] Morin, I<Open Data Structures>, section 3.3, "SEList: A Space-Efficient Linked List"

A doubly linked list of blocks, each holding several elements, to reduce
the space spent on references between nodes.
L<https://opendatastructures.org/ods-python/3_3_SEList_Space_Efficient_.html>

=item [8] perl source, F<av.c>: C<Perl_av_shift> and C<Perl_av_extend_guts>

C<av_shift> advances the array's start pointer by one and moves no element;
when a shifted array needs more room, C<av_extend_guts> moves the contents
back to the real start of the allocation. Read from the main development
branch on 2026-11-02, not from the 5.40 source.
L<https://github.com/Perl/perl5/blob/blead/av.c>

=back
