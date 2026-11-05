package LinkedList::Single::Example::SortedMerge::POD v2.0.0;
use v5.40;

1
__END__

=head1 NAME

LinkedList::Single::Example::SortedMerge::POD - Merging sorted lists, and sorting by merging

=head1 SYNOPSIS

    perl app/50-SortedMerge/sorted-merge        # a short demonstration
    prove -r t/50-SortedMerge                   # the tests
    perl benchmarks/50-SortedMerge/compare      # the measurements below
                                                # (about four minutes)
    perl benchmarks/50-SortedMerge/raw-nodes    # a pointer merge sort that
                                                # looks inside the nodes

=head1 THE PROBLEM

Two services each write a log in time order, and one report is wanted in
time order. The logs are already sorted, so there is no need to sort them
again: look at the first event of each, take the earlier, and repeat. This
is a I<merge>. It reads each item once, so its cost grows in proportion to
the number of items.

A merge is also the working part of a sort. Cut a list in half, sort each
half the same way, and merge the two sorted halves. A list of one item is
already sorted, so the cutting stops there. This is a I<merge sort>. The
halving goes about log2(n) levels deep (17 levels for 100,000 items) and
each level merges every item once, so the work grows as n log n [7]: a little
faster than the number of items, much slower than its square.

In outline, whatever the data structure:

    merge( x, y ):
        out = empty
        while x and y both have items:
            if key( front of x ) <= key( front of y ):  move front of x to end of out
            else:                                       move front of y to end of out
        move whatever is left of x or y to end of out

    merge_sort( list ):
        if list has fewer than two items:  return list
        split list into left and right halves
        return merge( merge_sort( left ), merge_sort( right ) )

The C<< <= >> matters. When the keys are equal the item from the left
input goes first, so items with equal keys keep the order they came in.
A sort that does this is called I<stable>: two events at the same second
stay in the order they were logged.

Here an item is C<[ $key, @payload ]>, the comparator sees only the keys
and returns a negative, zero or positive number like C<< <=> >>, and the
default is numeric.

The textbook argument for doing this on a linked list is that "move the
front of x to the end of out" changes a link and copies nothing, so the
merge builds nothing new [8]. Whether L<LinkedList::Single>'s public
operations let a program do that, and what it costs, is what this example
measures.

=head1 WITH ARRAYS

On arrays the merge keeps one index into each input and pushes the smaller
item onto a new array (L<LinkedList::Single::Example::SortedMerge::Array>):

    while( $i < $x->@* && $j < $y->@* )
    {
        push @out
        , $cmp->( $x->[ $i ][ 0 ], $y->[ $j ][ 0 ] ) <= 0
        ? $x->[ $i++ ]
        : $y->[ $j++ ]
        ;
    }

    push @out, $x->@[ $i .. $x->$#* ];
    push @out, $y->@[ $j .. $y->$#* ];

The merge sort splits with two slices and merges the sorted halves. Every
level of the recursion builds new arrays [7], but an array slot is cheap and
the code is short and clear. This is the reference the tests compare
against.

Nobody writing Perl would sort this way, though. Perl's own C<sort> is a
merge sort, stable since 5.8.0 [1] [5] [6], written in C [9]. With a comparator
block that calls a sub for every pair, as the merge sorts here must, it
sorts 100,000 items in 0.42 seconds; the array merge sort written in perl
takes 1.1. The practical rival for any list sort is therefore: take the
items out, C<sort> them, build a new list. The module does that as
C<sort_via_array>.

=head1 ON THE LIST

L<LinkedList::Single> (version 2) is a chain of nodes, each holding one
item and a link to the next. Every list ends in a I<sentinel>, an empty
node that marks the end; adding to the end of a list fills the sentinel
and puts a new one after it. The calls this example uses:

=over 4

=item a I<cursor>

marks a node; C<< $cursor->advance >> moves it one node on, C<< ->data >>
returns the item there, C<< ->next( $n ) >> returns a new cursor C<$n>
nodes on, and C<< ->push( @item ) >> adds an item after the end of the
list;

=item C<< $cursor->fragment >>

cuts the list at the cursor and returns the node there and everything
after it as a I<Fragment>, a piece of list that belongs to no list;

=item C<< $fragment->push_onto( $target ) >>

adds the Fragment's nodes at the end of the target's list.

=back

=head2 The tail cursor

C<push_onto> walks its target to the sentinel before it adds. Given a
list, that is a walk of the whole output on every item, and the merge
would grow as the square of n. So the output is built at a cursor parked
on its own sentinel: C<push_onto> finds itself already at the end, adds,
and C<< $tail->advance >> steps onto the new sentinel. Each addition is
then a fixed amount of work. Both list merges below are built this way.

=head2 Merging by copying

The plainer merge reads both inputs with cursors and pushes a copy of
each item onto the output (C<< how => 'copy' >>; the loop for what is
left over is omitted):

    my $out     = LinkedList::Single->new;
    my $tail    = $out->cursor;
    my $xc      = $x->cursor;
    my $yc      = $y->cursor;

    while( $xc && $yc )
    {
        my $from
        = $cmp->( ( $xc->data )[ 0 ], ( $yc->data )[ 0 ] ) <= 0
        ? $xc
        : $yc
        ;

        $tail->push( $from->data )->advance;

        $from->advance;
    }

That is the pseudo-code almost word for word, with no index variables:
a cursor that has walked off its list tests false and ends the loop.
Afterwards C<< $x->fragment >> and C<< $y->fragment >> empty the inputs,
so that both merges leave their inputs consumed.

=head2 Merging by relinking

The second merge (C<< how => 'relink' >>, the default) tries to move the
nodes themselves. Taking the front node off C<$src> takes four calls,
because the public operations cut a list only "from here to the end":

    my $rest    = $src->cursor->next->fragment;   # everything after the first node
    my $one     = $src->fragment;                 # the first node alone; $src is empty

    $rest
    and $rest->push_onto( $src );                 # the rest goes back

    $one->push_onto( $tail );                     # the node joins the output

    $tail->advance;                               # onto the new sentinel

When one input runs out, the other is moved whole with one C<fragment>
and one C<push_onto>. The merge sort splits a list with one walk of half
its length and one cut, C<< $list->cursor->next( $n )->fragment >>, and
passes the lengths down the recursion so that no list is counted twice.

=head2 It is not a relink

The point of relinking is that nothing is built. With these calls that
does not happen. A Fragment takes a node's I<contents> into a new array,
and C<push_onto> moves them again into the output's sentinel, so every
node moved builds an array and leaves the old node behind as a sentinel.
One move costs about four object constructions (two Fragments, a cursor
and the cursor C<next> returns), about 30 microseconds. The code reads
like a relink and performs like a copy with extra steps: it is the
slowest version measured.

Since these measurements the module has gained C<detach>, which cuts a
counted run of nodes out after a cursor, and a C<append_to> that splices a
Fragment in after a cursor by relinking (both in the 31 October 2026 entry of the F<CHANGES> file of
LinkedList::Single; L<LinkedList::Single::Example::LRU> uses them).
This example does not use them and they were not measured here. By the
module's documentation C<detach> still moves the contents of the first
node it removes, and C<append_to> will not add at a sentinel, so a merge
built on them would need an anchor node at the front of each list.

=head2 What the module's own sort does

C<< $list->sort >> works inside the module, where it may change the links
of the nodes directly. When this example was written it was an insertion
sort, whose work grows as the square of n; the measurements below are the
evidence for changing it, and it is now a stable merge sort that
relinks the nodes, using perl's C<sort> on the nodes when no comparator is
given. Code outside the module cannot do the same, because no public
operation changes where a node is linked from.

F<benchmarks/50-SortedMerge/raw-nodes> measures how fast that can be. It
breaks the rule the other examples keep: it looks inside the nodes (a node
is C<[ $next, @data ]>, the sentinel is C<[]>) and merge sorts a real list
by assigning links. It is not a proposal to expose the nodes; it is there
to show the ceiling for a list sort, which only code inside the module can
reach.

=head1 CHECKING THAT IT IS RIGHT

=over 4

=item F<t/50-SortedMerge/20-vs-array.t>

Merges 300 pairs of lists (every pair of sizes from 0 to 9, then 200 pairs
of random sizes up to 59, with keys from a small range so there are many
ties), and merge sorts lists of every length from 0 to 40 and 60 random
lengths up to 399, through both list versions and the array. Each result
is compared with perl's C<sort> on the key with a sequence number as the
tie-break, so an unstable merge fails; that was checked by making one.
It also covers a descending string comparator, C<split_half> and
C<sort_via_array>.

=item F<t/50-SortedMerge/30-lifetime.t>

Puts L<LinkedList::Single::Example::Probe> objects, which record when they
are destroyed, in the items, and shows that a merge, a merge sort or
C<sort_via_array> destroys none of them, that the result holds them in key
order, and that letting the result go destroys each exactly once.

=item F<t/50-SortedMerge/40-invariants.t>

Checks the item count, the order, that no node is in two lists, that the
consumed inputs test false, and that every list left over is still a
proper list: an item can be added at its end. (The test looks at node
addresses to find shared nodes; tests may.)

=back

=head1 WHAT IT COSTS

From F<benchmarks/50-SortedMerge/compare> on one machine (the author's
workstation, perl 5.40, 2026-10-30); the ratios are what matter. Times
are seconds, the best of 3 runs, 1 run at 100,000.

=head2 Sorting n random numbers

    n                1,000     10,000    100,000
    list-relink     0.3278     4.3994    54.9826
    list-copy       0.1041     1.2524    14.7549
    array           0.0062     0.0774     1.1062
    via-array(cmp)  0.0037     0.0460     0.8318
    perl sort(cmp)  0.0019     0.0278     0.4236
    via-array       0.0025     0.0290     0.5751
    perl sort       0.0005     0.0074     0.1303
    core ->sort     0.0008     0.0118     0.3854    (merge sort)

The first five rows call a comparator sub for every comparison and are
like for like. The last three use perl's built-in C<< <=> >> (the module's
sort uses its default comparison); they show what the default costs and are
not like for like with the merge sorts.

All the merge sorts grow as n log n. The array merge sort is 2.6 times
slower than perl's C<sort> with the same comparator sub at 100,000 items,
and extracting, sorting and rebuilding (C<via-array(cmp)>) beats it at
every size, because the sorting is done in C. The list merge sorts are 13
and 50 times slower than the array's: the cost is per item moved, and a
cursor or Fragment call costs far more than an array slot. The module's
own sort, at 0.39 seconds (0.2 in a fresh process; 1.8 with a comparator
generator, from the measurement of the sort change), beats the array merge sort written
in perl at every size.

=head2 The core sort, before and after the merge sort

Seconds; each ratio is against the row above:

    before (insertion sort)               after (merge sort in the module)
    n      core_sort ratio list_copy ratio    core_sort ratio list_copy ratio
    500       0.1678    -     0.0489    -        0.0004    -     0.0505    -
    1000      0.6474  3.9     0.1055  2.2        0.0008  2.0     0.1088  2.2
    2000      2.5269  3.9     0.2202  2.1        0.0019  2.5     0.2230  2.0
    4000     10.3912  4.1     0.4657  2.1        0.0037  2.0     0.4742  2.1
    8000     41.9175  4.0     0.9735  2.1        0.0080  2.2     0.9934  2.1

The old sort quadrupled with each doubling of n, as a quadratic sort does;
a merge sort a little more than doubles. At 8,000 items the new sort is
5,000 times faster than the old one.

=head2 Merging two sorted lists of n/2

    n                1,000     10,000    100,000
    list-relink     0.0335     0.3420     3.4080
    list-copy       0.0060     0.0607     0.6622
    array           0.0004     0.0040     0.0720

At 100,000 items the array merge is 9 times faster than the copying list
merge and 47 times faster than the relinking one.

=head2 The ceiling: a pointer merge sort on the nodes

From F<raw-nodes>:

    n          pointer_sec  perl_sort
    1000            0.0049     0.0002
    10000           0.0384     0.0019
    100000          0.4522     0.0188
    500000          3.0579     0.1349

At 100,000 that is 120 times faster than the relinking merge sort and 33
times faster than the copying one, with no change to how the list is
stored. Its C<perl_sort> column sorts plain numbers, not items, so it is
faster than the C<perl sort> row above. The earlier comparison of this
figure (0.45) with C<sort_via_array> (0.57, including the release of the
consumed input) is what the design of the new core sort was chosen from.

=head2 Memory

The merged result of 100,000 items, in bytes:

    list (either merge)    9,600,000     96 per item
    array                 16,046,272    160 per item

These are not the same measure. The list figure is the sum of
C<Devel::Size::size> over the nodes; the array figure is C<total_size> of
the result, which counts the array of references, a reference to each
item and each item's own array. Both list merges give the same figure
because the nodes are the same size. Neither list merge was measured for
peak memory; the copying merge, and C<sort_via_array>, hold the inputs and
the output at the same time until they finish. A hash is not compared: it
keeps no order, and order is the whole of this problem.

=head2 Code

Statements, branches and index operations in the merge
(C<LinkedList::Single::Example::Bench::complexity>): the relinking merge
16/9/3, plus 15/5/2 in the move it calls; the copying merge 22/9/3; the
array 18/7/11. The list versions index only the C<[ 0 ]> that picks the
key out of an item; the array indexes both inputs. The relinking merge,
with its four-call move, is the longest.

=head1 READABILITY AND CHANGE

Here "readable" means that a reader who knows ordinary Perl can match each
line to a step of the outline in L</THE PROBLEM> without working out what
an index or an offset holds. "Easy to change" means that a plausible new
requirement touches few lines, and that those lines are in one place.

=head2 Choosing the next item

The copying list merge and the array merge choose the next item the same
way; both loops are listed above, the array's in L</WITH ARRAYS> and the
list's in L</Merging by copying>. The list loop has no indexes: "while
both have items" is C<< $xc && $yc >>, and "move it to the end of out" is
a C<push> and an C<advance>. The array loop is shorter and is ordinary
Perl. Neither is much harder to follow; the list spares the reader two
index variables and the C<< $i < $x->@* >> bounds.

=head2 What is left over

The list (from C<_merge_copy>):

    for my $rest ( $xc, $yc )
    {
        while( $rest )
        {
            $tail->push( $rest->data )->advance;

            $rest->advance;
        }
    }

    $x->fragment;
    $y->fragment;

The array:

    push @out, $x->@[ $i .. $x->$#* ];
    push @out, $y->@[ $j .. $y->$#* ];

Here the array is simpler: a slice from the index to the end is the
outline's "move whatever is left". The copying merge needs a second loop
and two calls that empty the inputs. The relinking merge does it in one
line, C<< $rest->fragment->push_onto( $tail ) >>, but pays for that in
the move of a single node.

=head2 Where each merge stopped is kept by whom

The array keeps "how far each input has got" in C<$i> and C<$j>. Each
appears four times in C<merge> (F<Array.pm> lines 33-46: set, the bound
in the C<while>, the C<++> in the branch that takes the item, and the
start of the slice). They must agree: a C<++> on the wrong branch, or
C<$i> in the slice of C<$y>, gives an output with an item repeated or
missing and no error. Only a comparison such as
F<t/50-SortedMerge/20-vs-array.t> would notice.

The relinking merge has no such variable: the inputs I<are> what is left.
C<< while( $x && $y ) >> (F<SortedMerge.pm> line 79) and
C<< $rest->fragment >> (line 93) ask the lists themselves. The copying merge has cursors, but a cursor is
tied to its list and tests false when it walks off the end, so there is
no bound to keep in step (line 134).

The price is that the list merges consume their inputs. Afterwards the
caller's C<$x>, C<$y> or C<$unsorted> is empty and a caller who keeps
using it gets nothing back, also without an error. The copying merge
has to empty them by hand (lines 159-160); if those lines are lost the
results stay right but the contract of the module breaks, which
F<t/50-SortedMerge/40-invariants.t> checks. The array leaves its
arguments as they were, so it has nothing that can go stale.

=head2 Moving one item, and cutting a list in half

The array moves one item with C<< $x->[ $i++ ] >>. The relinking merge
needs C<_move_front> (14 lines, shown in L</Merging by relinking>):
cut off the rest, cut off the first node, put the rest back, add the
node, step the tail. None of those steps is in the problem statement;
they exist because the public operations cut only "from here to the end".
The split goes the other way. The list cuts with one line in C<_split>:

    $list->cursor->next( $n )->fragment->push_onto( $right );

which reads "walk C<$n> nodes on, cut, give the rest to C<$right>". The
array C<split_half> builds two slices whose bounds, C<0 .. $half - 1> and
C<< $half .. $list->$#* >>, the reader has to check for an off-by-one.

=head2 Changing it

=over 4

=item Leave the inputs intact.

The array merge already does. The copying merge drops its two
C<fragment> lines. The relinking merge cannot: moving the nodes is what
empties the inputs, so it would have to become the copying merge.

=item Drop items whose key repeats the previous one.

The array merge can compare with C<$out[ -1 ]> in its loop, but its two
slices for what is left over have to become loops or C<grep>s. The
copying list merge already has a loop for what is left over, but its
output is built at a cursor on the sentinel, and a singly linked list
cannot look back, so it has to keep the last key in a new variable and
test it in both loops. The relinking merge would also have to cut the
dropped node out of its input, another C<_move_front>-like step, and its
one-line move of what is left over would become a loop.

=back

=head2 Where the list is not simpler

The list versions carry bookkeeping the arrays do not: the tail cursor,
needed because C<push_onto> given a list walks it to the end (only a
comment says that passing C<$out> instead would make the merge
quadratic; the code would look the same); the counts passed down
C<_sort>, because counting a list is a walk and C<_split> needs a count
less than the length; and the explicit emptying of consumed inputs. The
relinking merge's four-call move is the largest of these.

Two of these have to be kept in step with the data by hand. The
counts in C<_sort> (C<$count>, C<$half> and C<$count - $half>,
F<SortedMerge.pm> lines 205-216) must match the lists they travel
with; the array asks C<< $list->@* >> each time (F<Array.pm> lines 53
and 68). A count that is too small makes C<< $count > 1 or return $list >>
hand back a longer list unsorted, with no error; the order tests would
catch that. Every C<push> or C<push_onto> at the tail is followed by
C<< $tail->advance >> (lines 118, 142, 151). If one is missed the result
is still right, since both walk from the cursor to the end before they
add; the slip would show only in the timings, never in the output.

What the list does not need here: every cursor is a lexical inside one
sub and none outlives a removal, so there is no stored cursor to repair
and no index of cursors. Whether a cut leaves a payload held by the
Fragment's C<whence> slot was not checked; F<30-lifetime.t> shows only
that no payload is destroyed early or twice. On this lens, as on the line
counts, the array has the smaller surface for the merge sort as a whole;
the list's advantage is confined to not tracking positions in the merge.

=head2 Line counts

Lines from C<sub> to the closing brace, including blank lines, of the
code in this repository (not of the shortest code possible):

    step               list                              lines    array lines
    merge (copy)       _merge_copy                         37        21
    merge (relink)     _merge_relink 24 + _move_front 14   38        21
    split              _split 8 + split_half 9             17        14
    merge sort         merge_sort 4 + _sort 14             18        13

The array column is the array C<merge>, C<split_half> and C<merge_sort>.
The array is shorter for every step. The list reads closer to the
outline in choosing the next item and in the cut; the array reads closer
in what is left over and in moving one item, and needs no counts or tail
cursor.

=head1 WHAT TO TAKE FROM IT

The list gives a stable merge that consumes its inputs and destroys no
payload early or twice, a merge and a sort with no position arithmetic,
and a split in one cut after walking half the length. The copying merge
reads cleanly, almost line for line with the pseudo-code.

It does not give speed: at every size measured the array merge and
perl's C<sort> are faster, and on the public API the list merge sort is
13 to 50 times slower than the array one. It does not give a merge that
builds nothing, which was the reason to merge on a list at all; the
"relink" written with Fragments is the slowest version. Inside the module
the story is different: the node relinking that outside code cannot do
made the module's own sort fast enough to beat the array merge sort
written in perl. For a program holding a list that wants it sorted, the
answer is C<< $list->sort >>, or C<sort_via_array>, not a merge sort
written on top of the list.

=head1 WHERE MERGING IS USED

Perl's C<sort> is a merge sort [1], and so is the Linux kernel's
C<list_sort>, a stable sort of its linked lists [2]. Python's list sort,
timsort, is an adaptive, stable merge sort that finds runs already in
order and merges them [3]. GNU C<sort --merge> combines files that are
each already sorted, and when there are too many inputs it merges them in
groups through temporary files [4]: the merge of two logs in this
example's demonstration, at the size of a file system.

=head1 A NOTE FOR LinkedList::Single

This example found that C<< $list->sort >> was quadratic and is the
evidence for the merge sort that replaced it. It also relies on two facts about the
module: Fragments move node contents (how the module works today),
which is why the Fragment relink rebuilds an array per node; and
C<_split> relies on the count being less than the length, which the merge
sort guarantees by passing its own counts down (C<< next( $n ) >> past the
end, now returns a cursor on the sentinel).

=head1 SEE ALSO

L<LinkedList::Single::Example::SortedMerge>,
L<LinkedList::Single::Example::SortedMerge::Array>, L<LinkedList::Single>.
The numbers are the references in the text.

=over 4

=item [1] perldoc, sort

Perl's C<sort> is implemented with a merge sort and has been stable since
v5.8.0 (read 2026-11-01).
L<https://perldoc.perl.org/functions/sort>

=item [2] Linux kernel, lib/list_sort.c

A stable merge sort of the kernel's linked lists (read 2026-11-01).
L<https://github.com/torvalds/linux/blob/master/lib/list_sort.c>

=item [3] CPython, Objects/listsort.txt

Describes timsort, "an adaptive, stable, natural mergesort" (read 2026-11-01).
L<https://github.com/python/cpython/blob/main/Objects/listsort.txt>

=item [4] GNU coreutils manual, sort invocation

C<--merge> merges files that are each already sorted; large merges go
through temporary files (read 2026-11-01).
L<https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html>

=item [5] perldoc, perl58delta

Perl 5.8.0 changed C<sort> to use primarily a stable mergesort instead of
quicksort, citing quicksort's N**2 worst case against mergesort's
O(N log N); quicksort stayed selectable through a pragma (read 2026-11-02).
L<https://perldoc.perl.org/perl58delta>

=item [6] perldoc, sort (the pragma)

The C<sort> pragma is now a no-op whose use is discouraged; the default
sort has been stable since v5.8.0, and the C<_mergesort> and C<_qsort>
options croak from v5.28 (read 2026-11-02).
L<https://perldoc.perl.org/sort>

=item [7] Sedgewick and Wayne, Algorithms, 4th ed., section 2.2 Mergesort

Mergesort on arrays sorts N items in time proportional to N log N for any
input; its main disadvantage is extra space proportional to N for the
auxiliary array (read 2026-11-02).
L<https://algs4.cs.princeton.edu/22mergesort/>

=item [8] Mergesort For Linked Lists (chiark.greenend.org.uk/~sgtatham)

On a linked list mergesort avoids the usual O(N) auxiliary storage, needs
only forward links, is stable and is O(N log N) in the worst case; with C
code (read 2026-11-02; the page names no author).
L<https://www.chiark.greenend.org.uk/~sgtatham/algorithms/listsort.html>

=item [9] Perl source, pp_sort.c

Perl's C<sort> in C: Peter McIlroy's stable mergesort, which looks for
natural runs first, after his "Optimistic Sorting and Information Theoretic
Complexity", SODA 1993, pp. 467-474 (read 2026-11-02).
L<https://github.com/Perl/perl5/blob/blead/pp_sort.c>

=back
