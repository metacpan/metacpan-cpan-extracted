package LinkedList::Single::Example::LRU::POD v2.0.0;
use v5.40;

1
__END__

=head1 NAME

LinkedList::Single::Example::LRU::POD - A least-recently-used cache, with the order kept in a linked list

=head1 SYNOPSIS

    perl app/10-LRU/lru-cache               # a short demonstration
    prove -r t/10-LRU                       # the tests
    perl benchmarks/10-LRU/compare          # the measurements below
                                            # (the time tables take about half an hour)

=head1 THE PROBLEM

A program often asks the same question more than once: the rows of a
database table, the answer to a name lookup, a page that took a while to
build. Working the answer out again is slow; keeping it is cheap, but
memory is finite. A I<cache> is a place with room for C<limit> answers.
When it is full and a new answer arrives, one old answer has to go.

The best one to throw out is the answer that will be asked for last, or
never. That is the optimal rule [1], and it needs to know the future. A
program cannot know, so it guesses from the past: the answer unused for
longest is the one least likely to be needed soon. This is the
I<least recently used> rule, LRU, and it can be shown to stay within a
known factor of the optimal rule [2].

The cache here has two operations:

=over 4

=item C<< get( $key ) >>

Returns the value stored for C<$key>, or C<undef> if there is none, and
makes that entry the I<newest>.

=item C<< put( $key, $value ) >>

Stores the value as the newest entry. If the cache then holds more than
C<limit> entries, the I<oldest> entry is removed and passed to an
C<on_evict> handler, which can write it back or log it.

=back

In outline, whatever the data structure:

    get( key ):
        find the entry for key, or answer "not there"
        make it the newest entry
        answer its value

    put( key, value ):
        if there is an entry for key:  replace its value
        otherwise:                     add an entry
        make it the newest entry
        if there are now more than limit entries:
            remove the oldest and hand it to the on_evict handler

Both have to answer two questions on every call. Where is the entry for
this key? And how is the order of the entries kept, so that "make it the
newest" and "find the oldest" are cheap? The first question is the one
Perl has an answer to. The second is the interesting one.

=head1 A FIRST ATTEMPT: AN ARRAY

The plainest answer keeps C<[ $key, $value ]> pairs in an array, newest
first. A hit finds the pair, takes it out and puts it back at the front;
a put at the front that makes the array too long drops the last pair
(L<LinkedList::Single::Example::LRU::Array>):

    sub get( $self, $key )
    {
        my $at  = $self->_find( $key )         # a loop over the array
        // return undef;

        my $item    = $self->{ item };

        unshift $item->@*, splice $item->@*, $at, 1;

        $item->[ 0 ][ 1 ]
    }

This is correct, and it is five lines. It is also slow when the cache is
large, for two reasons. C<_find> may look at every pair before it finds
the key. C<splice> and C<unshift> then slide the pairs after it along the
array. The work of one call grows in proportion to the size of the cache.
At 200,000 entries one call takes between 0.09 and 0.19 seconds.

=head1 ADDING A HASH

A hash finds a key in a single step however many keys it holds, so the
next attempt keeps the values in a hash and only the I<order> in an array
of keys (L<LinkedList::Single::Example::LRU::Order>). A miss is now fast
because the hash says at once that the key is not there. A hit is only a
little better: the hash returns the value, but to move the key to the front
of the order array the program has to find the key's place in it, and that
is the same search as before. At 200,000 entries a call takes between 11
and 55 milliseconds.

What is wanted is an order that can be changed at a known place without
sliding anything along. A hash cannot supply that, because it has no order,
and an array cannot, because its order is its positions.

=head1 KEEPING THE ORDER IN A LINKED LIST

A linked list is a chain of nodes in which each node knows the next one.
Moving a node to the front of the chain is changing two or three links;
nothing else moves, and the cost does not depend on how long the chain is.
L<LinkedList::Single> (version 2) provides such a list, with three things
this cache uses:

=over 4

=item a I<cursor>

marks a place in the list and can be asked what is next to it;

=item C<< $cursor->detach( $count ) >>

cuts C<$count> nodes after the cursor out of the list, joins the nodes on
either side of the gap, and returns the cut nodes as a I<Fragment>;

=item C<< $fragment->append_to( $cursor ) >>

puts a Fragment back into the list after a cursor.

=back

The cache keeps a hash from each key to the entry's place in the list, so
that a hit does not search. There is one difficulty. In a list where each
node knows only the I<next> one, a node can be cut out only from the node
I<before> it, because that is the node whose link has to change. So the
hash cannot hold a cursor on the entry; it holds a cursor on the node in
front of the entry. And the newest entry has to have a node in front of it
as well, which is why the list starts with a permanent I<anchor> node that
holds no entry (the I<dummy node> of textbook lists [10]):

    anchor -> newest -> ... -> oldest -> (end)

    index{ $key }  = a cursor on the node before $key's entry
    last           = a cursor on the node before the oldest entry

C<last> is there so that the oldest entry can be cut out without walking
the list to find it; without it, reaching the node before the end means
stepping from the head [9]. A new cache is built like this:

    my $list    = LinkedList::Single->new;

    $list->push( 'anchor' );

    my $anchor  = $list->cursor;     # last starts on the anchor too

=head2 A hit

Call the anchor C<A>, the entry that was asked for C<M>, the node in front
of it C<P>, the node after it C<T>, and the newest entry C<S>. A hit has to
change

    before:  A -> S ... P -> M -> T
    after:   A -> M -> S ... P -> T

In words, with the list as the only data structure:

    cut M out, joining P to T
    put M back directly after A, in front of S
    tell the entries whose front node changed (T, M and S)

LinkedList::Single has a call for each step, and the module reads very
nearly like that sentence (comments shortened; the declarations of C<$anchor> and C<$index>, the
test for "already the newest" and the repair of C<last> are left out here, and C<_key_after> and
C<_key_at> read the key of the entry next to or under a cursor):

    sub _promote( $self, $key )
    {
        my $pred    = $index->{ $key };                  # P
        my $newest  = _key_after $anchor;                # S

        my $entry   = $pred->detach( 1 );                # M comes out, P joins T

        my $after   = $pred->next;                       # T, if there is one

        $after
        and $index->{ _key_at $after } = $pred;          # T's front node is P now

        $entry->append_to( $anchor );                    # M goes behind A

        $index->{ $key }    = $anchor;                   # M's front node is A
        $index->{ $newest } = $anchor->next;             # S's front node is M
    }

C<detach> returns the cut-out node as a Fragment, an object that owns it
until it is attached somewhere, so there is no moment at which the node is
in the list twice or not at all. C<append_to> takes the Fragment and links
it in after the cursor. Neither call needs to know how long the list is.

The three assignments to C<$index> are the price of a list that is linked
in one direction. The nodes moved only a little, but three entries now
have a different node in front of them, and each of those entries has to
be told. A list linked both ways would not need them [10]. Getting them right,
and the repair of C<last>, is where the care in this module goes.

=head2 An eviction

When a C<put> leaves the cache over its limit, the oldest entry is cut out
at C<last>, its key is dropped from the hash, and C<last> moves to the node
in front of where it stood, which the hash knows (the declarations of
C<$last> and C<$index> left out):

    my $entry   = $last->detach( 1 );          # the oldest entry

    delete $index->{ _key_at $entry };

    --$self->{ size };

    $self->{ size }
    and $self->{ last } = $index->{ _key_at $last };    # one step back

    $entry->consume( $self->{ on_evict } );

C<consume> gives the key and value of the cut-out entry to the handler
and lets go of the node, so the entry's memory is freed at that moment.

=head2 The rule that makes the stored cursors safe

A cursor kept in the hash has to go on meaning the same node for as long as
it is kept. Operations that move the I<contents> of nodes along the list
(C<insert>, C<delete>, C<shift>, C<unshift>) would leave it standing on some
other entry's data. The cache therefore uses only C<append> after an
ordinary node, C<detach> and C<append_to>, which leave every other node
where it is, and it only ever steps off a stored cursor with C<next> or
C<detach>, which return new cursors, and never moves the stored one.

=head1 CHECKING THAT IT IS RIGHT

The array version is simple enough to read and be sure of, so the tests
use it as the reference.

=over 4

=item F<t/10-LRU/20-vs-array.t>

Runs 3,000 random gets and puts, at limits of 1, 2, 5 and 100, through all
four caches. After every step, what the call returned, the whole contents
in order, and the sequence of evictions must be the same.

=item F<t/10-LRU/40-invariants.t>

After each of 1,500 random operations at five limits, checks that the
anchor is on the first node, that the hash holds exactly the cached keys,
that every cursor in it stands on the node before its entry, that C<last>
stands on the node before the oldest entry, and that the size is what a
walk of the list counts. If any one of the three repairs above is removed,
this test fails.

=item F<t/10-LRU/30-lifetime.t>

Uses objects that record when they are destroyed, to show that an evicted
entry is destroyed as the C<put> returns, that a hit destroys nothing, and
that replacing a value destroys the old one.

=back

=head1 WHAT IT COSTS

One more version completes the comparison (L<LinkedList::Single::Example::LRU::Lazy>).
It is the best that can be done with arrays and a hash: the hash holds
C<key =E<gt> [ value, stamp ]>, every use pushes C<[ key, stamp ]> on the back of
a queue, and eviction takes from the front of the queue and skips any pair
whose stamp is no longer the key's. Nothing is searched for and nothing is
moved. Occasionally the stale pairs are swept out.

The benchmark (F<benchmarks/10-LRU/compare>) runs a cache that fetches a
missing answer and stores it, with the cache filled first. In the C<uniform>
workload, keys come evenly from twice the cache's limit, so about half of
the requests hit. The C<hot> and C<scan> workloads, in the program's
output, have the same shape. Microseconds per operation, on one machine:

    limit      list       array of pairs   hash + order array   hash + queue
    100        36.1            11.5               2.9                2.5
    10,000     36.8         1,915.7             182.4                2.8
    200,000    38.8       185,221             10,589                 4.1

The list's time hardly changes with the size of the cache: it is 32 to 42
microseconds in every workload and at every limit. The two versions that
search grow with it, and the list is faster than both from 10,000 entries
up. The version that never searches is faster than the list at every size,
by fifteen to twenty times. At 100 entries the plain arrays are faster too;
the documentation of a linked-list LRU cache on CPAN gives a similar
caution for small caches, without measurements [13].
The reason is that the list does its work with objects: creating a cursor
costs about 4 microseconds, a C<detach> and C<append_to> pair about 16, and
a hit creates several. An array operation costs a fraction of a
microsecond, so below a few thousand entries a search is cheaper than the
objects. (The 200,000-entry rows for the two searching arrays come from
2,000 operations, not 100,000, since the full run would take hours.)

=head2 Memory

Resident memory of a fresh process holding 200,000 entries with small
integer keys and values, in bytes per entry:

    a hash alone (no order, the floor)    195
    hash + order array                    231
    array of pairs (no hash)              250
    list (hash + nodes + cursors)         511
    hash + stamped queue                  534

The array of pairs holds each entry as a two-element array in one slot of
the main array. The list holds a node (an array with a slot more, for the
link), a hash entry and a cursor object for the index, and the cursor
objects take most of it: the list costs about twice the array of pairs per
entry. Against a plain hash, which keeps nothing in order, the list cache
needs 316 bytes more per entry for the order. When entries leave, the list
gives the node back at once, as the lifetime test checks. Perl's arrays and
hashes keep the memory they grew to, so a cache that stays at its limit
shows little difference; a cache that shrinks was not measured.

=head2 Code

Counting statements on the path of a hit: the list 35, the array of pairs
25, the hash with an order array 27, the stamped queue 38. The simplest
versions are the slowest at scale. The fastest needs its stamps, its test
for stale pairs and its rule for when to sweep, and it is easy to get
wrong. The list needs the repairs described above.

=head1 READABILITY AND CHANGE

Here I<readable> means that a reader with ordinary Perl can match each
line to a step of the outline in L</THE PROBLEM> without working out
positions or hidden rules, and I<easy to change> means that a new rule
touches one sub, not several. The verdict for this example is mixed. The
move of an entry reads like the outline in the list; the bookkeeping around
the move makes the list version the longest and the hash with an order
array the easiest to read. The excerpts below are copied from the modules,
with comments left out.

=head2 Moving an entry to the front

The hash with an order array (C<_touch>, after its test for "already
first") has to find the key's position before it can move it:

    my $at  = 0;

    ++$at while $order->[ $at ] ne $key;

    splice $order->@*, $at, 1;

    unshift $order->@*, $key;

The list's move is the two calls shown in L</A hit>, C<detach> and
C<append_to>, with no position and no offset: that part reads like
"cut M out, put it back behind A". What the earlier excerpt left out is
the repair of C<last> at the end of C<_promote>:

    if( ! $after )
    {
        $self->{ last } = $index->{ _key_at $pred };
    }
    elsif( ! $pred->next( 2 ) )
    {
        $self->{ last } = $pred;
    }

Together with the three index assignments, that is the price of the list:
the reader has to know which entries' front nodes moved. The array's search
is slow, but every line of it is plain.

=head2 Adding a new key

The order array adds a key with one line, C<< unshift $self->{ order }->@*, $key; >>. The list's C<put> needs the newest key before the
append, and two cases for C<last> (the cache was empty, or held one entry):

    my $newest  = $self->{ size } ? _key_after $anchor : undef;
    my $alone   = $self->{ size } == 1;

    $anchor->append( $key, $value );

    $index->{ $key }    = $anchor;

    if( defined $newest )
    {
        $index->{ $newest } = $anchor->next;

        $alone
        and $self->{ last } = $anchor->next;
    }
    else
    {
        $self->{ last } = $anchor;
    }

Here the array is plainly the simpler one; nothing in it depends on its
neighbours.

=head2 Evicting the oldest

The order array evicts with C<pop> and a C<delete>, two lines in C<put>.
The list (L</An eviction>) cuts out at C<last>, steps C<last> back through
the index, and hands the entry over with C<consume>: five steps, each one
named. The stamped queue, the only array version whose time does not grow
with the cache, evicts in a C<while> loop that C<shift>s pairs off the
queue and skips each one C<_current> calls stale; the reader has to know
the stamp rule to see why the loop is correct. Both the list and the
stamped queue carry rules that the code does not show on its face; for the
list, F<t/10-LRU/40-invariants.t> checks them.

=head2 One node per key, so nothing goes stale

The stamped queue avoids the search by never removing a key's old place in
the order: each use leaves a husk behind, and a key can stand in the queue
many times. The rule for telling them apart is a stamp kept twice, in the
hash entry and in each queue pair, written together in C<_touch> (lines 55,
58 and 60 of F<Lazy.pm>). Every reader of the queue has to ask C<_current>
first, and three do: the compaction at line 66, the eviction loop at line
92 and C<contents> at line 124. A new reader that forgets, such as a
"peek at the oldest" method, would see duplicate and evicted keys without
any error. Code that changed the hash's stamp without pushing a pair would
leave a key that the eviction loop never finds, so it is never evicted. In
the list a key has one node. A hit moves that node and an
eviction drops it, so there is no older copy to recognise, no stamp and no
sweep.

=head2 The hash and the order array must agree

The hash with an order array keeps each key in two places, and its subs
read whichever suits them: C<exists> asks the hash (line 86 of
F<Order.pm>), C<size> counts the array (line 91). The search in C<_touch>,
C<< ++$at while $order->[ $at ] ne $key >> (line 44), is only safe because
the hash says the key is in the array. A change that let the two disagree
would turn it into a loop that runs off the end of the array and never
stops. The list has the same pairing, hash and nodes, plus a third kept by
hand: the C<size> counter, changed at lines 168 and 240 of F<LRU.pm>, where
the two array versions count their hash or array instead.

=head2 Changing it

To I<evict a batch> once the cache is over its limit, each version changes
in one place: the list calls C<_evict> in a loop (C<_evict> repairs C<last>
itself), the order array loops on C<pop>, and the stamped queue changes the
condition of its C<while>. To I<insert new entries at a midpoint> instead of
the front, as 2Q-like policies do, the order array needs one C<splice> with
a computed offset; the list would need another stored cursor, kept correct
by every promote and every eviction, and more cases in C<put>. The list
gains nothing here; the array wins.

=head2 Where the list is not simpler

The index points at the node I<before> each entry, the anchor exists only
to give the newest entry such a node, and every unlink repairs the entry
behind it and possibly C<last>. A doubly linked list would not need these
repairs. They are code in this example, not calls to LinkedList::Single, and,
as L</A hit> says, where the care in this module goes.

That is the list's own state to keep in step, and it is larger than the
stamp. In F<LRU.pm> the index is changed in six places in three subs
(lines 126, 132 and 133 in C<_promote>, 224 and 228 in C<put>, 166 in
C<_evict>), and C<last> in five (145, 149, 174, 233, 237). If one of them is
wrong, a stored cursor stands on the wrong node and the next C<detach> from
it cuts out another key's entry: no error is raised, and the order and the
evictions are wrong from then on. The stamped queue has one rule that every
new reader must remember; the list has eleven writes that every change to a
move must keep right. F<t/10-LRU/40-invariants.t> walks the list after every step of
1,500 random operations to check the index, C<last> and C<size>. The stale
C<whence> slot that some LinkedList::Single operations leave behind was not
checked for this cache.

=head2 Line counts

Non-blank, non-comment lines from C<sub> to the closing brace, braces
included, of the code in this repository (not of the best code possible;
this is a different measure from the statement counts in L</Code>):

                            list   array of pairs   hash + order   hash + queue
    hit path                 40          18              17             18
    whole module            121          63              66             75

The hit path is C<get> and the sub it calls to move the entry (C<_promote>,
C<_find>, C<_touch>), with C<_key_after> and C<_key_at> for the list.

=head1 WHAT TO TAKE FROM IT

The list gives a time per operation that does not depend on the size of the
cache, no search, no moving of entries, no stale entries and no rule for
cleaning them up, and it releases an evicted entry at once. It does not
give the best speed (the stamped queue is faster at every size), the
smallest memory, or the simplest code, because a singly linked list needs
the index to point at predecessors and every unlink repairs the entry
behind it. It is a good choice when the alternative is an array that
searches. It is not a good choice against the array program that was
written to avoid the search.

=head1 WHERE LRU IS USED, AND WHERE IT IS NOT ENOUGH

Redis offers LRU eviction, and recommends it when a subset of keys is
accessed far more often than the rest; it does not keep an exact order but
samples a few keys and evicts the one idle longest, which its documentation
explains as a saving of memory [5]. Java's C<LinkedHashMap> can keep its
entries in access order for building LRU caches, as a hash table with a
doubly linked list through the entries [6]. Python's C<functools.lru_cache>
keeps the most recent calls of a function [7]; the pure-Python version of it
in CPython's F<Lib/functools.py> keeps a dict and a circular doubly linked
list [12]. memcached kept its LRU as a doubly linked list, and its
maintainer reports splitting it into hot, warm and cold segments to cut
lock contention [11]. For Perl there is C<Cache::LRU> [8], and
C<Tie::Cache::LRU> with array and linked-list versions [13].

LRU is a guess, and it guesses badly for a scan: one pass over a large
range of keys makes each of them the newest in turn and pushes out the
entries that were being reused. Policies that build on LRU lists, such as
2Q [3] and ARC [4], are designed to resist that. LRU-K keeps the times of
the last K references to each page, to tell frequently referenced pages
from infrequently referenced ones [14]. How their lists are kept
in order is the same problem this paper solved.

=head1 A NOTE FOR LinkedList::Single

C<ADJUST :params(:$whence)> in the module keeps its last argument alive
until the next object of the class is built, so dropping the last reference
to a cache does not destroy its payloads at once. The lifetime test marks
that one assertion C<TODO> and flushes the slot with an object of each
class (found in the work on this example, an open item for
the module, not yet fixed and not in the F<CHANGES> file of LinkedList::Single).

=head1 SEE ALSO

The numbers are the references in the text.

=over 4

=item [1] Belady, "A study of replacement algorithms for a virtual-storage computer"

I<IBM Systems Journal> 5(2), 1966, pp. 78-101. The optimal replacement rule
(evict the page used farthest in the future) and the study of practical ones.
L<https://doi.org/10.1147/sj.52.0078>

=item [2] Sleator and Tarjan, "Amortized efficiency of list update and paging rules"

I<Communications of the ACM> 28(2), 1985, pp. 202-208. LRU compared with
the optimal off-line rule; no on-line rule does better in amortized terms.
L<https://doi.org/10.1145/2786.2793>

=item [3] Johnson and Shasha, "2Q: A Low Overhead High Performance Buffer Management Replacement Algorithm"

I<VLDB> 1994, pp. 439-450. A replacement algorithm built from queues, with
constant overhead per request.
L<https://www.vldb.org/conf/1994/P439.PDF>

=item [4] Megiddo and Modha, "ARC: A Self-Tuning, Low Overhead Replacement Cache"

I<USENIX FAST '03>, 2003, pp. 115-130. Balances recency and frequency
as it runs; constant complexity per request, scan-resistant.
L<https://www.usenix.org/conference/fast-03/arc-self-tuning-low-overhead-replacement-cache>

=item [5] Redis, "Key eviction"

The eviction policies, and why Redis approximates LRU by sampling instead
of keeping an exact order (read 2026-10-31).
L<https://redis.io/docs/latest/develop/reference/eviction/>

=item [6] Java SE API, java.util.LinkedHashMap

Access-order mode for building LRU caches, a hash table with a
doubly-linked list through its entries, and C<removeEldestEntry>
(read 2026-10-31).
L<https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/LinkedHashMap.html>

=item [7] Python, functools.lru_cache

A memoizing decorator that keeps the most recent C<maxsize> calls, and
when an LRU cache is a good fit (read 2026-10-31).
L<https://docs.python.org/3/library/functools.html>

=item [8] Cache::LRU

A small LRU cache in pure perl, on MetaCPAN.
L<https://metacpan.org/pod/Cache::LRU>

=item [9] Morin, I<Open Data Structures>, section 3.1, "SLList: A Singly-Linked List"

Removal from the head is constant time; removal from the tail needs the
preceding node, which is found only by walking n-2 steps from the head.
Free textbook, CC BY (read 2026-11-02).
L<https://opendatastructures.org/ods-python/3_1_SLList_Singly_Linked_Li.html>

=item [10] Morin, I<Open Data Structures>, section 3.2, "DLList: A Doubly-Linked List"

With a link to the previous node, a node is removed by adjusting its two
neighbours, in constant time; a dummy node that holds no data removes the
special cases at the ends (read 2026-11-02).
L<https://opendatastructures.org/ods-python/3_2_DLList_Doubly_Linked_Li.html>

=item [11] Dormando, "Replacing the cache replacement algorithm in memcached"

memcached blog, 2018-10-15. The LRU of memcached 1.4 as a doubly linked
list, the lock cost of moving items on every hit, and the segmented
hot/warm/cold LRU of 1.5 (read 2026-11-02).
L<https://memcached.org/blog/modern-lru/>

=item [12] CPython, Lib/functools.py (v3.13.0)

The pure-Python C<_lru_cache_wrapper>: a dict from key to link and a
circular doubly linked list for the order. CPython uses its C version from
C<_functools> when that is available (read 2026-11-02).
L<https://github.com/python/cpython/blob/v3.13.0/Lib/functools.py>

=item [13] Tie::Cache::LRU and Tie::Cache::LRU::LinkedList

A tied-hash LRU cache, a thin subclass of its array version; the
linked-list version's documentation says it is theoretically efficient but
may lose out at small cache sizes because of a relatively high constant
(no threshold or measurements given) (read 2026-11-02).
L<https://metacpan.org/pod/Tie::Cache::LRU>
L<https://metacpan.org/pod/Tie::Cache::LRU::LinkedList>

=item [14] O'Neil, O'Neil and Weikum, "The LRU-K Page Replacement Algorithm For Database Disk Buffering"

I<SIGMOD> 1993, pp. 297-306. Tracks the last K references to each page;
the authors report it discriminates better than conventional algorithms
between frequently and infrequently referenced pages.
L<https://doi.org/10.1145/170035.170081>

=back
