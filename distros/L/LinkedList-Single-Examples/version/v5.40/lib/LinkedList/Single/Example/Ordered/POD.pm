package LinkedList::Single::Example::Ordered::POD v2.0.0;
use v5.40;

1
__END__

=head1 NAME

LinkedList::Single::Example::Ordered::POD - An ordered map in a linked list with a small index of markers

=head1 SYNOPSIS

    perl app/60-Ordered/ordered-index           # a short demonstration
    prove -r t/60-Ordered                       # the tests
    LLS_BUCKET_SIZE=8 prove -r t/60-Ordered     # the tests at another bucket size
    perl benchmarks/60-Ordered/compare          # average times (about ten minutes)
    perl benchmarks/60-Ordered/compare Memory   # memory only
    perl benchmarks/60-Ordered/latency          # every call timed (about fifteen minutes)
    perl benchmarks/60-Ordered/latency 400000   # the same at 400,000 entries

=head1 THE PROBLEM

A hash finds a key in one step but keeps no order. Many programs need
the order as well: the events between two times, the accounts in a
range of numbers, the next job due, everything in sequence for a
report. An I<ordered map> keeps its entries sorted by key and answers
these operations (keys are compared as numbers):

=over 4

=item C<< put( $key, $value ) >>, C<< get( $key ) >>, C<< delete( $key ) >>

Add or replace; the value or C<undef>; remove, returning the value.

=item C<< range( $lo, $hi ) >>, C<< cut( $lo, $hi ) >>

The entries with C<lo E<lt>= key E<lt>= hi>, in key order, as
C<[ $key, $value ]> pairs; C<cut> also removes them.

=item C<contents>, C<size>

All entries in order; how many there are.

=back

Whatever the data structure, the work is finding the place where a key
is or would go; everything else follows from that:

    find( key ):
        among the entries, kept in key order, find the first
        whose key is not below key (look in the middle, then in
        the half that must hold it, and so on)

    put( key, value ):     find; if the key is there replace the value,
                           otherwise insert a new entry at that place
    delete( key ):         find; if the key is there remove it
    range( lo, hi ):       find lo; read forward, in order, until a key
                           is above hi

The question is what "insert at that place" and "remove it" cost.
In a sorted array they cost moving everything after the place.

=head1 THE ATTEMPTS WITH ARRAYS AND HASHES

=head2 A hash

L<LinkedList::Single::Example::Ordered::Hash> keeps the entries in a
hash. A put, get or delete takes 0.3 to 0.9 microseconds at every size
measured. It has no order [3], so a range or the contents sorts every key,
every time: a range of 50 entries takes 1,531 microseconds at 10,000
entries and 111,001 at 200,000.

=head2 One sorted array

L<LinkedList::Single::Example::Ordered::Sorted> keeps C<[ $key, $value ]>
pairs in one sorted array. C<_lower> is a binary search (the halving in
the outline) for the first pair whose key is not below C<$key>:

    sub put( $self, $key, $value )
    {
        my $item    = $self->{ item };
        my $at      = $self->_lower( $key );

        if( $at < @$item && $item->[ $at ][ 0 ] == $key )
        {
            $item->[ $at ][ 1 ] = $value;
        }
        else
        {
            splice $item->@*, $at, 0, [ $key, $value ];
        }

        $self
    }

The search takes about as many steps as the number of times the size
can be halved, about 18 at 200,000 entries. The C<splice> moves every
pair after C<$at> along by one. Perl does that inside the one built-in
operation, and the measurements show it is cheap for a long while: 3.3 microseconds per insert at
1,000 entries, 4.2 at 10,000. Its cost is proportional to the size
(it I<grows linearly>), and it shows: a churn operation (half puts,
half deletes) takes 32.9 microseconds at 200,000, 49.8 at 400,000 and
87.7 at 800,000.

=head2 An array of small sorted arrays

The cure is to keep the splice short. L<LinkedList::Single::Example::Ordered::Buckets>
divides the entries into I<buckets>, each a small sorted array, and
keeps an index of the buckets with the lowest key each may hold. A
binary search of the index picks the bucket, a binary search inside it
finds the place, and the splice moves at most twice the bucket size. A
bucket that grows past twice its size is split in two (the second half
gets an index entry of its own); an empty one is removed from the index:

    splice $item->@*, $pos, 0, [ $key, $value ];

    if( @$item > 2 * $self->{ bucket } )
    {
        my @second  = splice $item->@*, $self->{ bucket };

        splice $self->{ index }->@*, $at + 1, 0
        , { low => $second[ 0 ][ 0 ], item => \@second };
    }

The index is an array too, and it is spliced on a split, but it has one
element per bucket, not per entry. This version takes 3 to 14
microseconds per operation from 1,000 to 800,000 entries. It is the
version the list is measured against, because it is the same two-level
design written for arrays.

=head1 THE LINKED-LIST SOLUTION

A linked list is a chain of nodes in which each node knows the next. An
entry can be put in or taken out by changing one link, and nothing else
moves, however long the list. What a list cannot do is jump to the
middle, so it cannot be searched by halving. The idea is to keep the
two levels of the array of buckets, with the entries in one list in key
order and a small array to jump into it:

    index[0]    index[1]               index[2]
       |           |                      |
    marker -> e -> e -> marker -> e -> e -> e -> marker -> e -> (end)

A I<marker> is a node that stays in place while its bucket has entries, holding the one datum C<'bucket'>,
that starts each bucket; an entry node holds a key and a value. Each
element of the index holds the lowest key its bucket may take (C<low>),
a I<cursor> on its marker, and how many entries the bucket has
(C<count>). L<LinkedList::Single> (version 2) supplies the list; the
terms it uses are:

=over 4

=item a I<cursor>

an object that marks one node of the list; it can read the node, read
the node after it, step forward, and change the list next to it;

=item the I<sentinel>

the empty node at the end of every list (C<(end)> above);

=item a I<Fragment>

a run of nodes taken out of a list, which owns them until they are put
somewhere or let go.

=back

=head2 Finding the place

The index search is the same binary search as the arrays'. The walk
inside the bucket is new. A list linked in one direction can change only
the link of the node I<before> a change, so the walk has to stop on the
node in front of the place, and it does that by looking one node ahead
(C<_before> in the module, nearly whole):

    my $entry   = $self->{ index }[ $at ];
    my $curs    = $entry->{ mark }->next( 0 );      # a copy of the marker's cursor

    for( 1 .. $entry->{ count } )
    {
        my( $found ) = $curs->next_data;            # the key one node ahead

        $found >= $key
        and return( $curs, $found == $key );

        $curs->advance;                             # one step along
    }

    ( $curs, 0 )

C<< next( $n ) >> returns a I<new> cursor C<$n> nodes on, so
C<< next( 0 ) >> is a copy: the walk moves the copy and the cursor kept
in the index never moves. C<next_data> reads the node after the cursor
without making a cursor for it, and C<advance> moves the cursor itself
one node. The walk is at most C<count> steps, which is at most twice
the bucket size, whatever the size of the map.

=head2 Putting and removing

With the cursor in front of the place, the list does each change in one
call (C<put>, with the split shown separately below):

    my $at              = $self->_locate( $key );    # the index search
    my( $curs, $found ) = $self->_before( $at, $key );

    if( $found )
    {
        $curs->next->set_data( $key, $value );       # replace in place
    }
    else
    {
        $curs->append( $key, $value );               # a new node after $curs

        ++$self->{ size };

        my $entry   = $self->{ index }[ $at ];

        ++$entry->{ count } > 2 * $self->{ bucket }
        and $self->_split( $at );
    }

C<append> links a new node in after the cursor's node; C<set_data>
overwrites a node's data. C<delete> does the same search and then
C<< $curs->drop >>, which unlinks the node after the cursor and returns
its data. A split walks a new cursor C<bucket> entries in from the
marker, C<append>s a new marker there, and splices an element for it
into the index; a bucket left empty has its marker C<drop>ped from the
last node of the bucket before. Each change to the list is one call,
and the reason is the markers; the split and the bucket removal around
it are longer (see L</READABILITY AND CHANGE>).

=head2 Why markers

In the LRU cache (L<LinkedList::Single::Example::LRU::POD>), the index
held a cursor on the node in front of every entry, and every unlink had
to repair the cursor of the entry behind it. Here the index points only
at markers, and a marker is never moved or removed while its bucket has
entries. No cursor in the index ever needs repair; only the counts
change, and the walk from the marker supplies the node in front for each
put and delete.

That holds because of which calls are used. C<append> after a node that
is not the sentinel, C<drop>, C<detach> and C<append_to> change links
and leave every other node where it is, so a cursor on a marker stays on
it. C<fragment>, C<delete> and C<insert> copy contents between nodes and
are not used.

=head2 Cutting whole buckets

A C<cut> that spans buckets lying wholly inside the range takes them
out, markers and all, in one piece, without looking at the keys in them;
the counts say how many nodes that is. The buckets at the two ends are
cut entry by entry with C<drop>. From C<_detach>, trimmed:

    my $before  = $index->[ $first - 1 ];
    my $nodes   = 0;

    $nodes  += 1 + $index->[ $_ ]{ count } for $first .. $last;

    my $piece   = $before->{ mark }->next( $before->{ count } )->detach( $nodes );

    my @entry
    = grep { @$_ > 1 }
      $piece->extract->@*;

    splice $index->@*, $first, $last - $first + 1;

C<< detach( $n ) >> cuts the C<$n> nodes after the cursor out of the
list, joins the nodes on either side, and returns them as a Fragment;
C<extract> returns the data of every node in it.

=head2 Where the module makes it awkward

Markers and entries are both nodes, so code that reads the list has to
tell them apart, here by the number of data in a node
(C<grep { @$_ E<gt> 1 }> above, and in C<range> and C<contents>). The counts
must be kept right by hand, since the walk and the bulk cut depend on
them. And every C<next>, C<append> or C<detach> that starts from a
stored cursor builds a new object, about 4 microseconds each, while a
walk step (C<advance> and a C<next_data>) costs about one.

=head1 CHECKING THAT IT IS RIGHT

=over 4

=item F<t/60-Ordered/20-vs-array.t>

Sends 3,000 random steps (put, delete, get, range, cut), at bucket sizes
of 1, 2, 4 and 16, to the list, the sorted array, the array of buckets
and the hash. The sorted array is the reference. What each call returns,
the whole contents in key order, and the size must agree after every
step. The test checks that the stream used every operation and, by
counting the calls, that it exercised the bulk detach of whole buckets.
Edge cases are run against all four.

=item F<t/60-Ordered/40-invariants.t>

After every operation checks that the list starts with a marker; that
the index has one element per marker, each cursor on its marker; that
each count is the number of entries behind its marker; that no bucket is
over twice the size and none but the first is empty; that keys strictly
increase and each lies within its bucket's bounds; and that the size is
the number of entries. Ascending and descending inserts are tried too,
since they always split in the same place. Four deliberate breakages of
the module (no count update on a split, no index splice after a bulk
detach, no marker removal, no split) each make the test fail.

=item F<t/60-Ordered/30-lifetime.t>

Uses payloads that record when they are destroyed: a replaced value is
destroyed at once; a deleted or cut value lives while the caller holds
it and goes with the caller's reference; the rest go with the map.

=item F<t/60-Ordered/50-bucket-default.t>

The bucket size is the argument, else C<$ENV{ LLS_BUCKET_SIZE }>, else 3,
for the list and the array of buckets, and a size that is not positive
is refused.

=back

=head1 WHAT IT COSTS

All the figures come from one machine.

=head2 Time

From F<benchmarks/60-Ordered/compare>, microseconds per operation. The
maps hold about n entries, with integer keys drawn from ten times n
values. These tables were taken with a bucket size of 16 for both the
list and the array of buckets (the default is now 3: see below).

    Build: n random inserts            n=1,000  10,000  100,000  200,000
      list                               29.6    30.4     34.7     43.0
      sorted array                        3.3     4.2     16.5     31.6
      array of buckets                    3.2     3.9      6.9      9.8
      hash                                0.5     0.5      0.8      0.9

    Lookup (get)
      list                               26.0    28.0     37.2     40.7
      sorted array                        2.4     3.1      5.9      8.2
      array of buckets                    3.0     3.8      8.4     10.0
      hash                                0.3     0.3      0.5      0.5

    Churn (half put, half delete)
      list                               29.0    30.8     41.2     45.7
      sorted array                        3.3     5.0     20.2     32.9
      array of buckets                    3.8     4.4      9.0     11.1
      hash                                0.4     0.4      0.6      0.7

    Range of about 50 entries (per range)
      list                              167     172      192      205
      sorted array                       16      17       34       48
      array of buckets                   18      19       45       60
      hash                              152    1531    50477   111001

    Cut the middle tenth (per entry cut)
      list                                2.6     1.1      2.7      4.0
      sorted array                        0.27    0.25     1.1      1.3
      array of buckets                    0.44    0.34     1.3      1.4
      hash                                1.9     2.3      8.7      9.7

    Contents, all entries in order (per entry)
      list                                0.5     0.6      3.0      3.7
      sorted array                        0.2     0.2      1.6      1.8
      array of buckets                    0.2     0.3      1.7      1.7
      hash                                0.6     0.8      3.1      3.1

    Larger maps, build / churn (20,000 churn operations, no hash; not
    in the program's default sizes, which stop at 200,000)
      n=400,000    list 39.2 / 41.6   sorted 52.8 / 49.8   buckets 10.9 / 11.9
      n=800,000    list 48.1 / 47.6   sorted 92.3 / 87.7   buckets 12.6 / 14.3

The hash was given 20 ranges, not 2,000, because each one sorts every
key. The range rows for the arrays and the list at 10,000 and larger
were measured again after the array of buckets' C<range> was changed to
walk its index by position instead of slicing it (the slice copied the
tail of the index on every call); the 1,000-entry range figures are from
the first run.

The list's point operations take 26 to 48 microseconds from 1,000 to
800,000 entries: they hardly grow. The sorted array's grow with the
splice, and the two cross between 200,000 and 400,000 entries (41.6
against 49.8 per churn operation at 400,000). The array of buckets has
the same two levels as the list and none of the per-operation objects;
it is ahead of the list throughout, by 7.6 to 9.3 times at 1,000 entries and
3.3 to 4.4 times from 200,000 up.

=head2 The bucket size

The default bucket size is 3, or C<$ENV{ LLS_BUCKET_SIZE }> if that is
set; an argument C<< bucket => $n >> to C<new> beats both. Microseconds
per insert / per get, map of 100,000:

    bucket       list      array of buckets
         4    22.1/18.3         7.5/ 7.3
         8    28.5/25.8         8.0/ 8.2
        16    38.0/36.9         7.7/ 7.6
        32    58.2/58.9         7.6/ 7.5
        64    98.2/102.5        7.3/ 7.2

The list's cost is the walk (about a microsecond a step), so smaller
buckets are faster for it, at the price of a larger index. The array of
buckets does not care: a splice of 64 pointers is as cheap as one of 8.
A second sweep of the smallest sizes (list only, run separately, so the
figures differ a little from the sweep above):

    n            1          2          3          4          6          8
     1,000    21.8/10.0  18.0/12.5  17.7/12.3  18.0/13.2  19.1/15.6  21.1/17.2
    10,000    23.0/11.0  20.3/12.5  19.9/13.7  20.2/14.7  20.8/17.1  22.4/20.2
   100,000    33.9/16.7  28.3/19.1  27.5/21.0  27.5/22.1  28.5/24.9  30.3/27.4

Builds are fastest at 2 to 4 and gets at 1; 3 is the compromise and the
default. At 200,000 entries with bucket 3 for both, the list takes 25.3
microseconds per build insert, 19.7 per get and 25.9 per churn
operation; the array of buckets 11.3, 9.9 and 12.7. The list is then
about twice as slow as the array, not three to four times: the walk is
shorter. Smaller buckets cost more index elements, which these timings
do not show; the memory below was measured with 16.

=head2 Bounded time

For some uses (queued messages, for one) what matters is the I<slowest>
call, and an average cannot show it. F<benchmarks/60-Ordered/latency>
times every call separately, in a fresh process for each case, and
reports the median (p50), the 99.9th percentile (the time that all but
one call in a thousand stayed under) and the slowest call. Each case is
run three times; the row shown is the run with the median slowest call,
and the range of the slowest calls over the three runs follows it. The
harness, F<lib/LinkedList/Single/Example/Latency.pm> (shared with
example 07), fills a pre-extended array so that it does not grow during
a measurement.

The clock matters more than anything else. On wall time the timing loop
around an empty call has a slowest call of up to 376 microseconds,
because the scheduler takes the processor away. The default clock is
the time the thread is running (C<CLOCK_THREAD_CPUTIME_ID>), which still
counts a page fault, a reallocation or a memory move, but not time spent
waiting; its empty loop has a median of 0.5 microseconds and a slowest
call of 17 to 275. C<LATENCY_CLOCK=wall> selects wall time. The 99.9th
percentile is the dependable bound; the slowest call has this noise in it.

Microseconds per call, 400,000 entries. C<put> builds the map from
nothing; C<churn> removes a random key and adds a new one in one call,
the map staying at 400,000:

    case          put p50  p99.9  slowest (3 runs)          churn p50  p99.9  slowest (3 runs)
    list b=3         31.1  126.8     432 (397 .. 537)            63.8  156.9   458 (397 .. 665)
    list b=16        45.3  135.5     455 (452 .. 501)            91.9  226.3   440 (369 .. 525)
    buckets b=3      13.9   59.5     373 (305 .. 703)            31.0  160.0   364 (360 .. 408)
    buckets b=16     11.4   30.5     253 (203 .. 8,645)          25.9   58.2   195 (160 .. 208)
    sorted array     46.1  242.5     765 (618 .. 807)            89.6  323.3   475 (467 .. 663)
    hash              1.2    8.8  24,797 (23,990 .. 25,375)       3.0   11.8   132  (73 .. 168)

At 100,000 entries, the slowest put: list b=3 305 (274 .. 414), list
b=16 307 (237 .. 420), buckets b=3 259 (164 .. 267), buckets b=16 221
(203 .. 281), sorted 371 (274 .. 488), hash 4,398 (4,031 .. 4,655).

=over 4

=item * The list's slowest put and churn are 0.3 to 0.7 milliseconds at
both sizes: bounded by the bucket, as the design says (a walk of at most
twice the bucket size, and a splice of an index with one element per
bucket). They grew a little from 100,000 to 400,000 entries (bucket 3,
from 305 to 432; the run ranges 274 .. 414 and 397 .. 537 do not
overlap), which is the index splice growing with the number of buckets,
not growth in proportion to the size, which was four times.

=item * The array of buckets is bounded in the same way and lower. Its
median and its 99.9th percentile are 2 to 4 times lower (except churn
with bucket 3, where the 99.9th percentiles are equal, 160 and 157), and
the slowest call of its median run is lower than the list's (253 against
455 with bucket 16, 373 against 432 with bucket 3), though with bucket 3
the three runs of each overlap. One run at bucket 16 had a slowest put
of 8,645 microseconds, where the other two had 203 and 281. It was not
repeated and its cause was not found; it is reported because it happened.

=item * The sorted array's slowest call is set by moving the whole array,
and grows with the size: 371 microseconds at 100,000 and 765 at 400,000,
with a 99.9th percentile that went from 86 to 243. At 400,000 the list is
better for put, 1.8 times at the slowest call (432 and 765) and 1.9 times
at the 99.9th percentile; for churn the slowest calls are equal (458 and
475) and the 99.9th percentile is 2 times better. At 100,000 the two
cannot be told apart at the slowest call (305 and 371, overlapping runs).

=item * The hash has the best typical call (1.2 microseconds, 99.9th
percentile 9) and by far the worst slowest call: 4.4 milliseconds at
100,000 entries and 24.8 at 400,000, while it doubles its tables. That
rehash is the only slowest call that grows in proportion to the size. A
hash is a poor choice where the slowest call must be bounded, whatever
it does for the average.

=item * A range of about 50 entries and a cut of about 1,000 cost in
proportion to what they return. Mean microseconds at 400,000: the list
(bucket 3) 245 and 3,662; the array of buckets 84 and 3,993 (bucket 3)
or 77 and 1,037 (bucket 16); the sorted array 62 and 867; the hash,
which sorts every key, 192,365 and 195,681.

=item * Freeing is one long call on every structure. Letting go of
400,000 entries took the list 470 milliseconds with bucket 3 and 265
with bucket 16, the array of buckets 468 and 328, the sorted array 296,
the hash 143. A map that must never pause that long has to be taken
apart a piece at a time, and that can be done to any of them.

=back

So for a bounded slowest call the list is a good answer and not a better
one than the array of buckets. The median runs of both stay under half a
millisecond (the worst of three runs reached 0.67 for the list and 0.70
for the array of buckets, leaving aside the one 8.6 millisecond put);
the sorted array and the hash are the ones that grow. The list's nodes
are allocated one at a time and never reallocated, but its index is a
perl array that grows by C<splice>, exactly as the array of buckets'
index does, so the list has no advantage there either.

=head2 Memory

Resident memory growth of a fresh process, measured in a forked child
before any timing, holding about 190,000 entries (integer key and value,
bucket 16):

    case        bytes        per entry
    list        52,944,896     278
    sorted      48,717,824     256
    buckets     52,322,304     275
    hash        43,192,320     227

B<List versus array.> A list entry is a three-element node (the link,
the key, the value); a sorted-array entry is a two-element pair in a
slot of a larger array. The difference is the link, plus the list's
markers and index: about 9% more than the sorted array, and about the
same as the array of buckets.

B<List versus hash.> The hash keeps no order and uses the least, 227
bytes an entry. The list pays 51 bytes an entry for the order, the
sorted array 29. Not measured here: a hash rehashes as it grows and an
array reallocates its slots, which can make a temporary rise in memory;
the list's entries are allocated one node at a time, and a node is
released as soon as its entry is deleted, where the sorted array and the
hash keep the memory they grew to. Where keys are far apart (here about
one value in ten is used), all four hold only the entries present; what
a hash used as a sparse array does not give is the order.

=head2 Code

Statements / branches / index operations on the path of each call,
helpers included (counted by C<LinkedList::Single::Example::Bench::complexity>):

                  put         get        delete        cut
    list        66/22/15    43/17/ 9    62/23/14    105/42/28
    sorted      30/12/ 9    27/11/ 7    28/12/ 7     30/12/ 8
    buckets     47/19/17    41/17/11    45/20/12     52/23/13
    hash        12/ 4/ 3    10/ 4/ 2    10/ 4/ 2     26/10/ 6

The list version is the longest, because of the markers: the counts to
keep, the split, the removal of an emptied bucket, and the whole-bucket
cut.

=head1 READABILITY AND CHANGE

Code is I<readable> here if a reader with everyday Perl can match each
line to a step of the outline in L</THE PROBLEM> without working out
positions by hand, and I<easy to change> if a new rule touches one sub.
The fair comparison is the array of buckets: the same two levels, and
the same 21-line index search, C<_locate>.

B<Removing an entry.> C<delete> after C<_locate>; the list (the C<size>
line left out):

    my( $curs, $found ) = $self->_before( $at, $key );

    $found
    or return undef;

    my( undef, $value ) = $curs->drop;

    my $entry   = $self->{ index }[ $at ];

    --$entry->{ count }
    or $at
    and $self->_remove_bucket( $at );

The array of buckets (the C<$item> line left out):

    my $pos     = _lower $item, $key;

    $pos < @$item && $item->[ $pos ][ 0 ] == $key
    or return undef;

    my $value   = ( splice $item->@*, $pos, 1 )[ 0 ][ 1 ];

    @$item
    or $at
    and splice $self->{ index }->@*, $at, 1;

C<< $curs->drop >> says "remove the node after this one", and C<_before>
(L</Finding the place>) is a forward walk; the C<splice> with a length
and C<[ 0 ][ 1 ]> must be decoded, and C<_lower> is a halving to get right.
But the list keeps C<count> and C<size> by hand, and its walk trusts
them (see below).

B<Splitting a bucket.> The array uses one C<splice> in C<put> (shown in
L</An array of small sorted arrays>). The list's C<_split> moves no
entry, but walks to the cut, C<append>s a marker, takes a cursor on it,
reads the next key for C<low> and sets both counts. The array is simpler.

B<Cutting a range.> Per bucket, the array (from C<cut>, C<$item> left out):

    my $from    = _lower $item, $lo;
    my $to      = $from;

    ++$to while $to < @$item && $item->[ $to ][ 0 ] <= $hi;

    push @found, splice $item->@*, $from, $to - $from;

The list's C<cut> reads as the plan, "take whole buckets in one piece
(C<detach>, in L</Cutting whole buckets>), cut the ends entry by entry",
but needs four helpers, a count of the markers to detach, and the test
C<< $index->[ $at ] == $entry >> to see whether C<_cut_bucket> removed
the bucket under it. The array uses positions, but far less code.

B<What must be kept in step.> The array of buckets stores nothing that
can disagree with its data: a bucket's length is C<@$item>, C<size> adds
the lengths (F<Buckets.pm> line 207), and a position from C<_lower> is
used in the sub that found it and then dropped. The list stores counts
beside the data. C<count> is written on five lines in four subs
(F<Ordered.pm>: C<put> 209, C<_split> 163 and 166, C<delete> 244,
C<_cut_bucket> 388), C<size> in four (205, 240, C<_detach> 355, 389).
And the counts steer: C<_before> (130) and C<_cut_bucket> (370) walk
C<count> nodes, and C<_remove_bucket> (179) and C<_detach> (349) reach
the node before a marker with C<< next( $before-E<gt>{ count } ) >>. One
missed update does not show where it is made: a later walk runs past the
marker into the next bucket, or C<_remove_bucket> drops an entry in place of
the marker, and the map stays wrong. The array's slips are in
arithmetic redone on every call (C<_lower>, the C<splice> lengths), with
no stored number to leave wrong. Only the list has an invariant test,
F<t/60-Ordered/40-invariants.t>, and it is there for this.

B<Markers in the data.> The markers that spare the index any repair
(L</Why markers>) are nodes every reader of the whole list must step
over: C<range> (265), C<_detach> (352) and C<contents> (412) each test
for more than one datum. A new walk that forgets the test returns a
C<'bucket'> as an entry. The walks bounded by C<count> never reach a
marker, which ties this back to the counts. The array keeps its buckets
apart, so a loop over C<item> sees only pairs. The hash has neither.

B<Stored cursors.> A walk must start from a copy of the marker's cursor
(C<< next( 0 ) >> in C<_before> 128, C<range> 256, C<_cut_bucket> 367);
one that C<advance>s the stored cursor moves the bucket's start, and
nothing complains until the invariant test. The cursors never go stale
as in the LRU cache: a marker leaves only with its index element
(C<_remove_bucket>, C<_detach>), and no entry is pointed at. The stale
C<whence> (L</A NOTE FOR LinkedList::Single>) costs only the last map's
prompt release. I did not check which node or cursor it holds.

B<Changing it.> To merge an under-half bucket into the one before (see
L</WHERE THE TECHNIQUE IS USED>), the list drops the marker between them
as C<_remove_bucket> does, adds the counts and splices the index, moving
no entry; the array pushes one bucket's pairs onto the other's and
splices the index; both must then split if it passes twice the size. To
split into thirds, each changes one block (the split in C<put>, or
C<_split>); the list's has more steps: a second walk, marker and count.

B<Where the list is not simpler.> Beyond L</Where the module makes it
awkward> and the three above: here the list has the larger surface to
keep correct at every step. What it never repairs, the index after
entries come and go, the array of buckets never repairs either, since
its index holds the buckets themselves.

B<Line counts> (C<sub> to closing brace, comments included) of the code
in this repository, not of the best possible code:

    step               list                              array of buckets
    search a bucket    _before 17                        _lower 20
    put and split      put 23, _split 24                 put 25
    delete             delete 20, _remove_bucket 11      delete 17
    cut                cut 41, _inside 9, _detach 20,    cut 34
                       _cut_bucket 33
    all subs           300 (sorted array 94, hash 47)    185

=head1 WHAT TO TAKE FROM IT

The design works, and the list is correct under every test. The list
provides a cost per operation that hardly depends on the size of the map
(26 to 30 microseconds at 1,000 entries, 48 at 800,000); in-order
traversal by walking, with no stack, no recursion and no rebalancing; an
index that never needs repair, because it points at markers; nodes
released as entries go; and whole buckets cut out as one piece without
examining their keys. The piece is a Fragment that could be handed to
another structure; this example only extracts it, which is what the
arrays do with a splice.

It does not provide speed. The array of buckets is 3.3 to 9.3 times faster
at every size measured, up to 800,000 entries, and the plain sorted
array is faster up to 200,000. Its ranges are not competitive (167 to
205 microseconds for 50 entries, against 16 to 60). Its slowest call is
bounded, but not lower than the array of buckets'. It does not use the
least memory, and it has the most code. With the default bucket of 3 it
is about twice as slow as the array of buckets at 200,000 entries
instead of three to four times; it still loses. The cost is the cursor
objects the walks create, where the arrays do the same work in a few
perl operations.

An array of small sorted arrays is the same idea without the objects.
The arguments for the list would be a use that needs what arrays cannot
do cheaply: keeping a position while others insert and delete around it,
or moving a range to another structure as nodes. This example exercises
neither.

=head1 WHERE THE TECHNIQUE IS USED

Python's C<sortedcontainers> keeps a sorted list as a list of sorted
sublists with each sublist's maximum beside it for a binary search,
splits a sublist that grows past twice its load (1,000 by default), and
merges one that falls to half; its documentation argues that this beats
tree-based designs in practice, though trees have the better big-O
bound [1]. That is the design of the array of buckets here, which only
removes empty buckets and does not merge.

This example stops at two levels. A third, an index over the index,
would shorten the splice into the index when a bucket is split; that
splice happens once in a bucket's worth of inserts and moves one pointer
per bucket, and it did not show in any of the averages (it is the likely
cause of the small rise in the slowest call above). A skip list, the
better-known way to add levels to a list, would not change the cost of
the walks either. A skip list puts the levels
into the linked list itself, each node carrying extra links that reach
further ahead, and is balanced by random choice: its worst case is bad,
but very unlikely [2]. Carried further, the levels of index become a
tree; in a B-tree every node but the root holds B to 2B children, is
split when it overflows, and borrows or merges when it falls short [7].

The other way to combine the list and the arrays is to put the array in
the node: an I<unrolled> list, each node holding a small block of
entries and one link, which spends less memory on links [5][6]. On CPAN,
L<Tree::RB> is an ordered map as a red-black tree, with lookups of the
nearest key and in-order iterators [8]. A linked list walked in memory
order costs less per node than one whose nodes are scattered, because the
processor can prefetch only the first [4]; where perl places these nodes
was not measured here.

=head1 A NOTE FOR LinkedList::Single

A walk step costs about a microsecond (C<advance> and a peek with
C<next_data>); every C<< next( $n ) >> or C<append> from a stored cursor
builds an object, about 4 microseconds. Peeking with C<next_data> rather
than making a cursor for the next node is why the walk is as fast as it
is. The example relies on C<detach> (new in the 31 October 2026 entry of the F<CHANGES> file of LinkedList::Single) for
the bulk cut, on C<append> after a node that is not the sentinel, on
C<drop>, and on C<< next( $n ) >> stopping at the sentinel.
C<ADJUST :params(:$whence)> keeps its last argument alive until the next
object of the class is built, so the lifetime test marks the
immediate-release assertion C<TODO>.

=head1 SEE ALSO

L<LinkedList::Single::Example::Ordered>, L<LinkedList::Single>,
L<LinkedList::Single::Example::LRU::POD>. The numbers are the references
in the text.

=over 4

=item [1] Grant Jenks, "Implementation Details", Sorted Containers

The list of sorted sublists, the C<_maxes> used for binary search, the
split at twice the load and the default load of 1,000 (read 2026-11-01).
L<https://grantjenks.com/docs/sortedcontainers/implementation.html>

=item [2] Pugh, "Skip Lists: A Probabilistic Alternative to Balanced Trees"

I<Communications of the ACM> 33(6), 1990, pp. 668-676. A sorted linked
list with extra forward links, balanced by a random number generator.
L<https://doi.org/10.1145/78973.78977>

=item [3] perlfunc, "keys"

Hash entries are returned in an apparently random order, specific to
each hash; its examples include C<sort keys %ENV>.
L<https://perldoc.perl.org/functions/keys>

=item [4] Ulrich Drepper, "Memory part 2: CPU caches", LWN.net, 1 October 2007

Times a linked list walked in memory order against random order: the
processor prefetches the next cache line only for the first.
L<https://lwn.net/Articles/252125/>

=item [5] Shao, Reppy and Appel, "Unrolling Lists"

Princeton TR-453-94 (March 1994; 1994 ACM Conf. on Lisp and Functional
Programming). Cells holding several data items and one link.
L<https://www.cs.princeton.edu/research/techreps/153>

=item [6] Pat Morin, I<Open Data Structures>, section 3.3, "SEList: A Space-Efficient Linked List"

A list whose nodes each hold a block of b-1 to b+1 elements, with its
running times; section 3.4 notes it is also called an unrolled linked list.
L<https://opendatastructures.org/ods-cpp/3_3_Space_Efficient_Linked_.html>

=item [7] Pat Morin, I<Open Data Structures>, section 14.2, "B-Trees"

Each node but the root has B to 2B children; full nodes split, short
ones borrow or merge. Motivated by external memory (a node per block).
L<https://opendatastructures.org/ods-cpp/14_2_B_Trees.html>

=item [8] Tree::RB

A Perl red-black tree with C<put>, C<get>, C<delete>, nearest-key
lookups (C<LUGTEQ>, C<LULTEQ>) and ascending and descending iterators.
L<https://metacpan.org/pod/Tree::RB>

=back
