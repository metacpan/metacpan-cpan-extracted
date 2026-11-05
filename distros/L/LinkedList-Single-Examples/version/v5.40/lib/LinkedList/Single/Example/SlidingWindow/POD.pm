package LinkedList::Single::Example::SlidingWindow::POD v2.0.0;
use v5.40;

1
__END__

=head1 NAME

LinkedList::Single::Example::SlidingWindow::POD - A sliding window of events, held in a linked list

=head1 SYNOPSIS

    perl app/30-SlidingWindow/sliding-window    # a login throttle
    prove -r t/30-SlidingWindow                 # the tests
    perl benchmarks/30-SlidingWindow/compare    # the measurements below

=head1 THE PROBLEM

A login form that lets anyone guess passwords as fast as they can type
will, sooner or later, be guessed. Standards for authentication require
the server to limit failed attempts [1], and a common way to do it is to
count the attempts in the last few seconds or minutes: fail2ban, for
example, bans a host that has failed C<maxretry> times during the last
C<findtime> seconds [2]. Rate limiters ("no more than 100 requests a
minute") and counters ("requests in the last minute") work the same way.

All of them keep a I<sliding window>: the events of the last C<span>
seconds. New events arrive at the end. As time passes, the oldest events
fall out of the window at the front. Because events arrive in time order,
the expired ones are always a I<prefix>, a run at the front of the
window. When traffic comes in a burst the window grows, and when the
burst is over it shrinks again.

The window here has two operations:

=over 4

=item C<< record( $time, @payload ) >>

Adds an event at the end.

=item C<< expire( $now, $handler ) >>

Drops every event older than C<$now - span>, hands each one to the
handler (a logger, a counter, something that closes a handle), oldest
first, and returns how many were dropped.

=back

In outline, whatever the data structure:

    record( time, payload ):
        add [ time, payload ] at the end

    expire( now, handler ):
        cutoff = now - span
        find the first event whose time is not before cutoff
        remove everything in front of it
        give each removed event to handler, oldest first
        give the memory back

F<app/30-SlidingWindow/sliding-window> is the login throttle: it refuses
a user with three attempts in the last ten seconds, and says so as old
attempts are forgotten.

=head1 THE ARRAY VERSION

Perl's arrays are good at exactly this. C<push> adds at the end;
C<splice> takes a run off the front
(L<LinkedList::Single::Example::SlidingWindow::Array>):

    sub expire( $self, $now, $handler = sub {} )
    {
        my $window  = $self->{ window };
        my $cutoff  = $now - $self->{ span };

        my $count   = 0;

        ++$count
        while $count < $window->@*
        && $window->[ $count ][ 0 ] < $cutoff;

        $count
        or return 0;

        my @dead    = splice $window->@*, 0, $count;

        $handler->( $_->@* ) for @dead;

        $count
    }

This is short, correct and fast: taking items off the front of a perl
array moves a pointer inside the array rather than copying what is left [4].
It has two weaknesses. C<$count> is a position that the loop and the
C<splice> must agree on. And the array keeps the room it grew to: after a
burst of 200,000 events has expired, the array still holds space for
200,000 (the numbers are below). The program gets that memory back only
if it remembers to copy the survivors into a new array.

A hash is not a natural alternative here. The events come in order and
leave from the front, which is what an array already does; a hash keyed
by a sequence number would add a key to every event and still have to
count from the oldest. No hash version was built.

=head1 KEEPING THE WINDOW IN A LINKED LIST

A linked list is a chain of nodes in which each node knows the next one.
L<LinkedList::Single> (version 2) ends every chain with an empty node,
the I<sentinel>, which marks the end. The window uses three of its
pieces:

=over 4

=item a I<cursor>

marks a place in the list. C<< $cursor->push( @data ) >> on the sentinel
fills it and hangs a new sentinel after it; C<< $cursor->advance >>
moves the cursor to the next node.

=item a I<Fragment>

is a piece of chain that belongs to no list, so nothing else can reach
its nodes. C<< $list->fragment >> moves every node of a list into a new
Fragment and leaves the list empty; C<< $cursor->fragment >> does the
same from the cursor to the end.

=item C<< $fragment->first( $test ) >>, C<push_onto>, C<consume>

C<first> returns a cursor on the first node whose data pass the test.
C<< $fragment->push_onto( $list ) >> puts a Fragment's nodes on the end
of a list. C<< $fragment->consume( $handler ) >> gives each node's data
to the handler and moves past it; as it moves, the node, which nothing
else refers to, is freed.

=back

The window is a list and one cursor, C<tail>, parked on the sentinel,
much as a textbook linked-list queue keeps a link to its last node [5]:

    first event -> ... -> newest event -> sentinel
                                           ^ tail

=head2 Recording

    $self->{ tail }->push( $time, @payload )->advance;

C<push> at the sentinel turns it into an event node with a new sentinel
after it, and C<advance> steps the tail onto the new sentinel. Nothing is
searched. The obvious C<< $list->push >> is not used: it finds the end by
walking from the front every time, which makes building a window of
I<n> events take time in proportion to I<n> squared; 32,000 pushes took
30 seconds. Neither is C<< $tail->append >>, which at a sentinel stores a
spurious empty array in front of the data (see L</A NOTE FOR LinkedList::Single>).

=head2 Expiring

The list version has no positions to count. It cuts the window apart
where the first live event begins, keeps the live half and consumes the
rest (from the module; the handler wrapper that counts the dropped
events is shortened to C<$counting_handler>):

    $list
    and ( $list->data )[ 0 ] < $cutoff
    or return 0;                            # usually nothing has expired

    my $dead    = $list->fragment;          # every node; $list is empty

    my $live    = $dead->first( sub( $time, @ ) { $time >= $cutoff } );

    if( $live )
    {
        $live->fragment->push_onto( $list );    # the live nodes go back
    }
    else
    {
        $self->{ tail } = $list->cursor;        # everything expired
    }

    $dead->consume( $counting_handler );

This reads close to the outline: find the first event in the window,
take off everything in front of it, give each removed event to the
handler. C<< $live->fragment >> cuts at the cursor, so C<$dead> ends
where the live events began and the live nodes come back as their own
Fragment.

The cost is in the number of objects: two Fragments and a cursor per
sweep, and C<first> and C<consume> each make a method call and run a
C<try> block (perl's catching of errors) for every node they visit. That
is the reason for the times below.

=head2 Why the tail cursor stays valid

C<fragment>, C<first> and C<push_onto> relink or move the nodes in front
of the sentinel, but never the sentinel at the end of the chain. So when
some events survive, the tail is still on the list's sentinel and needs
no repair. When every event expires, the old sentinel leaves with C<$dead>,
and C<expire> parks a new cursor on the empty list. That is the one
piece of bookkeeping the list needs, and the one place it could go wrong.

=head2 Where the memory goes

C<consume> is what returns the memory. The Fragment holds the only
reference to each expired node, so when C<consume> moves past a node, the
node is freed, and with it the payload, before the next node is handed
to the handler. A payload that holds a file handle, a lock or a socket is
closed at that moment, and there is no capacity left behind to shrink.

=head1 CHECKING THAT IT IS RIGHT

The array version is simple enough to read and be sure of, so the tests
use it as the reference.

=over 4

=item F<t/30-SlidingWindow/20-vs-array.t>

Drives both windows through 2,000 random steps with a fixed seed: 70%
record, 30% expire, and a few expires jump far enough ahead to empty the
window. After every step the contents must be the same; the counts, the
sequence of handler calls and the final sizes must match.

=item F<t/30-SlidingWindow/30-lifetime.t>

Records events whose payload is a L<LinkedList::Single::Example::Probe>,
an object that notes when perl destroys it. Expiring shows each expired
payload destroyed by the time C<expire> returns, in order, after the
handler has seen it, and nothing live destroyed.

=item F<t/30-SlidingWindow/40-invariants.t>

Checks that the tail stands on the list's last node after a new window,
records, a partial expire, a full expire, a refill, 50 record and expire
cycles, and an expire on an empty window.

=back

=head1 WHAT IT COSTS

=head2 Time

From F<benchmarks/30-SlidingWindow/compare>, on one machine, best of 3,
in seconds:

    100,000 events, window of 1,000      expire every event   every 100 events
    list                                         3.78               0.86
    array                                        0.15               0.08

    burst of 200,000 events, expired down to 10
    list                                         1.67
    array                                        0.18

The array wins by a factor of ten or more. C<splice> at the front of a
perl array is done inside perl's C code; the list pays method calls, a
closure and a C<try> block for each node, plus the fixed cost of the
Fragments and cursors on each sweep. Fragments pay off for batches.
Expiring after every event drops about one event per sweep, the worst
case for them, and the first column shows it: sweeping a hundred times
less often cuts the list's time by more than four.

=head2 Memory

After the burst has expired down to 10 events, in bytes held by the
container (from C<Devel::Size>; the payload is not counted [6]):

    list     1,056          10 live nodes, about 106 bytes each
    array    1,754,784      the slots of the burst, still allocated

The list's figure is its ten nodes, each holding the link to the next
node, the time and the payload. The array's figure counts only the
array's own slots, about 8.8 bytes for each event of the burst; the ten
small arrays the survivors live in are not in it. However it is counted,
the array keeps the size of the largest burst it has seen, and the list
keeps only what is live. While a window is full the two hold about the
same per event, an array of the time and the payload, with one more slot
in the list's node for the link; this was not measured separately.

Why the array keeps the room: C<shift> does not move the elements, it moves
the array's start pointer past the one removed [4] [9], so the front of the
allocation is left empty while C<push> fills the other end. That empty space
is used again only when the array runs out of room at the back (or by an
C<unshift>); perl then moves the whole contents down to the start of the
allocation [9], a copy as long as the number of events held, made now and
then inside whichever call needed the room. The list has neither the idle
gap nor the move: each node is released when its event expires, and no call
copies the live events. What the list pays is the node itself, one more
slot per event, and the tail cursor. [9] was read in the current
development source of perl; the behaviour of the 5.40 source was not read.

No hash version was built (see above). For scale, the LRU example
(L<LinkedList::Single::Example::LRU::POD>) measured a plain hash of small
integers at about 195 bytes per entry of resident memory, a different
measurement from this one, and notes that perl's hashes, like its
arrays, keep the memory they grew to.

=head2 Code

Counting statements, branches and index operations in C<expire>
(C<complexity> in L<LinkedList::Single::Example::Bench>, a rough count
over the deparsed code):

            statements  branches  index ops
    list        23          8         3
    array       18          9         5

The list has fewer index operations and one branch fewer, but more
statements: cutting and rejoining Fragments takes lines. The difference
is in the kind of code more than the amount. The array's lines are
arithmetic on a position that has to stay right; the list's move whole
pieces that cannot be the wrong size, at the price of keeping the tail
cursor right.

=head1 READABILITY AND CHANGE

Readable here means that a reader who knows ordinary perl can check the
code against the outline in L</THE PROBLEM> without knowing anything
else: what each line does, and why it is there. Easy to change means a
new rule touches a few lines in one place and does not break something
elsewhere. In this example the array is the simpler of the two on both
counts; the list's one advantage is in finding where the window starts.

=head2 Adding an event

    $self->{ tail }->push( $time, @payload )->advance;    # list

    push $self->{ window }->@*, [ $time, @payload ];      # array

Both are one line, but the array's line is the outline ("add at the
end") and needs nothing else. The list's needs a tail cursor built in
C<new>, kept right in C<expire>, and a reader who knows why the obvious
C<< $list->push >> (it walks the list; the module's comment says so) and
C<< $tail->append >> (the spurious C<[]>; only this paper says so) are
not used.

=head2 Finding where the window starts

    # list
    my $live    = $dead->first( sub( $time, @ ) { $time >= $cutoff } );

    # array
    ++$count
    while $count < $window->@*
    && $window->[ $count ][ 0 ] < $cutoff;

Here the list reads closer to the outline: "the first event whose time is
not before cutoff" is the test passed to C<first>. The array loop says
the same thing through a position, with a bounds check and a subscript
that must agree with the C<splice> two lines later. In exchange, the
array's C<$count> is also the return value; the list counts separately.

=head2 Removing and handing over

    my @dead    = splice $window->@*, 0, $count;         # array
    $handler->( $_->@* ) for @dead;

The list's equivalent is the eleven lines from C<< $list->fragment >> to
C<< $dead->consume >> quoted in L</Expiring>, plus a wrapper sub to
count the dead events (trimmed there to C<$counting_handler>). The extra
lines are an C<if>/C<else> that either puts the live nodes back or, when
nothing survives, gives the tail a new cursor. That branch is the
bookkeeping a reader has to understand to trust the code; the C<splice>
has none, and the guard at the top of the list's C<expire> (is the first
event old?) exists only to skip building Fragments in the common case.

=head2 The array's position lasts one call

The only thing the array version keeps in step with the data is
C<$count>, used five times in C<expire> (F<SlidingWindow/Array.pm> lines
42-53: the bound, the subscript, the guard, the C<splice> length and the
return value). If the loop and the C<splice> disagreed, the wrong events
would go with no error. But C<$count> is a lexical that is born and dies
inside one call: it cannot go stale between calls, and no other sub has
to know about it. The array marks nothing: an expired event is gone from
C<< $self->{ window } >>, so C<record>, C<contents> and C<size> need no
test for it. The list does no better here; there is nothing to improve.

=head2 The list's tail cursor outlives the call

The list keeps a piece of state that crosses calls: the C<tail> cursor,
built in C<new> (F<SlidingWindow.pm> line 31), used by C<record> (line
50) and rebuilt in C<expire> (line 99) when every event expires and the
old sentinel leaves with C<$dead>. Any future sub that removes nodes, a
C<clear> or a cap on the number of events, has to repeat that repair.
Reasoning from the code (it was not tried): if one forgets, the tail is
left on a node outside the list, and later records would go there
instead of into the window, with no error. F<t/30-SlidingWindow/40-invariants.t>
guards it with seven checks that the tail stands on the list's last node.
Two more rules from L</A NOTE FOR LinkedList::Single> bind any such sub:
no cursor may be held on the first node across a C<fragment> call, and
the last C<whence> keeps a window's payloads alive until another object
is built. The array has none of these to honour.

Both versions take the expired events out of the window before the
handler sees any (C<splice> on line 49; the tail repair on line 99
precedes C<consume> on line 104), so a handler that dies leaves the
window consistent in both. What C<consume> does with the remaining
events after such a C<die> was not checked.

=head2 Changing it

Two plausible changes, reasoned from the code above:

=over 4

=item Keep the expired events instead of dropping them

The array replaces the handler line with C<< push $archive->@*, @dead >>.
The list replaces C<consume> with C<< $dead->push_onto( $archive ) >>,
which moves the nodes without copying them, but then the count must come
from elsewhere, since the C<consume> wrapper is what counts. Both are
local; neither is simpler by much.

=item Also cap the window at a maximum number of events

The array computes C<< $window->@* - $max >> and folds it into the same
C<splice>. The list code has no notion of position: it would have to walk
a cursor forward that many nodes before cutting, and repeat the tail
fix-up if the cut takes everything. The array is simpler here.

=back

=head2 Where the list is not simpler

Everywhere except the search. The list needs the tail cursor and its
repair when the window empties, state that every sub that removes nodes
must honour (above), where the array's only position is local; a guard to avoid making objects when
nothing has expired, a wrapper to count what C<consume> hands over, and
the C<< push( ... )->advance >> workaround for the module. Adding at the
end and removing from the front is what perl arrays do natively, so the
array version is close to the outline line for line.

Lines of code in this repository's C<.pm> files (sub to closing brace,
leaving out blank lines and comments), not counts of the best possible
code:

               new   record   expire
    list        15      5       28
    array       11      5       14

=head1 WHAT TO TAKE FROM IT

The list gives the memory of a burst back as the burst expires, destroys
each expired payload as soon as the handler is done with it, and has no
positions to count. It does not give speed: this is the array's best
case, adding at the end and removing from the front, and the array is
nine to twenty-five times faster in these runs. The code is not shorter either.
Choose the list when the window is bursty and the memory should come
back, or when expired events hold resources that need prompt release.
Choose the array when the window is steady, sweeps are small, and speed
matters most.

=head1 WHERE THE TECHNIQUE IS USED

fail2ban's jails are sliding windows of failures per host [2]. Cloudflare
describes the trade made in large rate limiters: storing the timestamp
of every request is more accurate but costs a great deal of processing and memory,
so they use an approximation that keeps two numbers per
counter and assumes a constant rate over the previous period [3]. The
window in this example is the exact kind, which is affordable when the
window is per user or per host and small. Simpler limiters keep no
events at all: the Redis documentation's rate-limiter pattern counts the
requests of each second in a key the server expires [7], and Stripe
reports using the token bucket algorithm [8].

=head1 A NOTE FOR LinkedList::Single

Building this example turned up two things in the module, both of them open
items for the module, not yet fixed and not in the F<CHANGES> file of
LinkedList::Single.

=over 4

=item C<< $cursor->append >> at the sentinel stores a spurious C<[]>

C<append> at a sentinel passes a new sentinel node to C<set_data>, which
already supplies the link to the next node, so the event's data begin
with an empty arrayref. C<push> at the sentinel is correct, so C<record>
uses C<< push( ... )->advance >>.

=item The last C<whence> is kept alive

The C<ADJUST> block keeps its C<:$whence> parameter until the next object
of the same class is built, so after the last reference to a window is
dropped its list and payloads stay allocated until another list, cursor
or Fragment is made. F<t/30-SlidingWindow/30-lifetime.t> marks the
assertion that depends on it C<TODO>, and passes it once an object of
each class has been built.

=back

C<< $list->fragment >> and C<< $cursor->fragment >> move the contents of
the first node they take into a new node, rather than relinking it. A
cursor held on that node across the call would see an empty node. The
expiry code holds no cursor across such a call except the tail, which is
on the sentinel at the far end.

=head1 SEE ALSO

The numbers are the references in the text.

=over 4

=item [1] NIST SP 800-63B, "Digital Identity Guidelines: Authentication and Lifecycle Management", section 5.2.2

Revision 3: verifiers shall limit consecutive failed authentication
attempts on one account to no more than 100 (read 2026-11-01). NIST's page
says this revision was superseded by SP 800-63-4 on 1 August 2025; the new
revision was not read, so check it before relying on the figure.
L<https://pages.nist.gov/800-63-3/sp800-63b.html>

=item [2] fail2ban, config/jail.conf

The default configuration: "A host is banned if it has generated
'maxretry' during the last 'findtime' seconds" (read 2026-11-01).
L<https://github.com/fail2ban/fail2ban/blob/master/config/jail.conf>

=item [3] Cloudflare, "How we built rate limiting capable of scaling to millions of domains"

Cloudflare blog, 7 June 2017. Exact timestamps against a two-counter
sliding-window approximation, with its measured error (read 2026-11-01).
L<https://blog.cloudflare.com/counting-things-a-lot-of-different-things/>

=item [4] perlguts, "Introduction to the Perl API"

The passage on the offset hack: perl arrays keep C<AvARRAY> (first
visible element) apart from C<AvALLOC> (real start) "to enable efficient
shifting and splicing off the beginning of the array"; the real start
matters only when the array is freed (read 2026-11-02).
L<https://perldoc.perl.org/perlguts>

=item [5] Sedgewick and Wayne, I<Algorithms>, 4th ed., section 1.3 "Bags, Queues, and Stacks"

Textbook FIFO queue on a linked list, adding at the end through a kept
link to the last node and removing from the front, beside a
resizing-array queue (read 2026-11-02).
L<https://algs4.cs.princeton.edu/13stacks/>

=item [6] Devel::Size

C<size> reports only the memory of the structure itself, not its
contents; C<total_size> follows the contents. Memory lost to
fragmentation and alignment is not counted (read 2026-11-02).
L<https://metacpan.org/pod/Devel::Size>

=item [7] Redis documentation, INCR, "Pattern: rate limiter"

Limits an API to ten requests a second per IP with a counter per second
that Redis expires, and a variant on Redis lists (read 2026-11-02).
L<https://redis.io/docs/latest/commands/incr/>

=item [8] Paul Tarjan, "Scaling your API with rate limiters"

Stripe blog, 30 March 2017. Stripe's API rate limiters; it reports using
the token bucket algorithm, implemented with Redis (read 2026-11-02).
L<https://stripe.com/blog/rate-limiters>

=item [9] perl source, F<av.c>: C<Perl_av_shift> and C<Perl_av_extend_guts>

C<av_shift> advances the array's start pointer by one and moves no element;
when a shifted array needs more room, C<av_extend_guts> moves the contents
back to the real start of the allocation (a C<Move> of C<AvFILLp + 1>
elements). Read from the main development branch on 2026-11-02.
L<https://github.com/Perl/perl5/blob/blead/av.c>

=back
