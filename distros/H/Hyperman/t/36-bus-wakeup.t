#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Hyperman;

# The wakeup: a publish from one process reaches another PROMPTLY, because it
# was told rather than because it happened to look.
#
# Phase 1 proved the ring. This proves the poke - and the difference matters,
# because a polling reader passes every phase-1 test while delivering whenever
# it next wakes up anyway.

plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';
plan skip_all => 'no arena on this platform (no atomics)'
    unless Hyperman->bus_init(slots => 256, slot_size => 256, groups => 8);

# ---- subscriptions dispatch ---------------------------------------------------
{
    my @got;
    my $id = Hyperman->subscribe('room:lobby' => sub { push @got, [@_] });
    cmp_ok($id, '>=', 0, 'subscribe returns an id');

    Hyperman->publish('room:lobby', 'one');
    Hyperman->publish('other',      'ignored');
    Hyperman->publish('room:lobby', 'two');

    my $n = Hyperman->dispatch;
    is($n, 2, 'dispatch delivered both messages on the topic');
    is_deeply(\@got, [ ['room:lobby','one'], ['room:lobby','two'] ],
        'the callback got the topic and payload, and NOT the other topic');

    is(Hyperman->dispatch, 0, 'a second dispatch has nothing left');

    ok(Hyperman->unsubscribe($id), 'unsubscribe');
    Hyperman->publish('room:lobby', 'after');
    Hyperman->dispatch;
    is(scalar @got, 2, 'and nothing arrives after it');
}

# ---- a subscriber that dies does not take the process with it -----------------
# It runs from the event loop with nothing to unwind into. One bad handler must
# not silently remove a worker from the pool.
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $ok = 0;
    my $bad  = Hyperman->subscribe('bang' => sub { die "handler exploded\n" });
    my $good = Hyperman->subscribe('bang' => sub { $ok++ });

    Hyperman->publish('bang', 'x');
    my $lived = eval { Hyperman->dispatch; 1 };

    ok($lived, 'a dying subscriber does not propagate out of dispatch');
    is($ok, 1, 'and the OTHER subscriber on that topic still ran');
    ok(scalar(grep { /handler exploded/ } @warnings),
        'the death became a warning, so it is not silent either');

    Hyperman->unsubscribe($_) for $bad, $good;
}

# ---- a group subscription is load-balanced, a fanout one is not ---------------
{
    my (@fan, @grp);
    my $f = Hyperman->subscribe('work' => sub { push @fan, $_[1] });
    my $g = Hyperman->subscribe('work' => sub { push @grp, $_[1] },
                                group => 'workers');

    Hyperman->publish('work', $_) for 1 .. 5;
    Hyperman->dispatch;

    is_deeply(\@fan, [ 1 .. 5 ],
        'the fanout subscriber saw all five');
    is_deeply(\@grp, [ 1 .. 5 ],
        'and so did the group - it is the only member, and exactly-once '
      . 'across a pool of one is still exactly-once');

    Hyperman->unsubscribe($_) for $f, $g;
}

# ---- THE WAKEUP: prompt, across processes -------------------------------------
# A child subscribes and then blocks in select() on its own waker descriptor -
# exactly what the worker's event loop does. If the poke works it returns
# immediately; if it does not, it sits there until the timeout and the measured
# latency is the timeout.
{
    pipe my ($r, $w) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (!$pid) {
        close $r;
        my $fd = Hyperman->bus_waker_take(1);
        if ($fd < 0) { syswrite $w, "nofd\n"; close $w; exec $^X, '-e', '1'; }
        Hyperman->bus_reset;
        my $seen;
        Hyperman->subscribe('ping' => sub { $seen = $_[1] });

        # syswrite, NOT print. A buffered write sits in the child's stdio
        # buffer until it closes - which is after the select below - so the
        # parent blocks on its read for the whole timeout and only then
        # publishes. The child then reports a timeout it was never given a
        # chance to avoid, and the bus gets the blame.
        syswrite $w, "ready\n";

        my $rin = '';
        vec($rin, $fd, 1) = 1;
        my $n  = select my $rout = $rin, undef, undef, 5.0;   # BLOCK
        # Report the ABSOLUTE moment of waking, not the elapsed time: the
        # parent deliberately waits before publishing, so elapsed here is
        # mostly that wait and would report a 50ms wakeup for a 0.1ms one.
        my $woke = Time::HiRes::time();
        Hyperman->bus_waker_drained;
        Hyperman->dispatch;

        syswrite $w, sprintf("%s %.6f %s\n", ($n > 0 ? 'woken' : 'timeout'),
                             $woke, ($seen // '-'));
        close $w;
        exec $^X, '-e', '1';
    }

    close $w;
    my $ready = <$r>;
    chomp $ready if defined $ready;

    SKIP: {
        skip 'child could not take a waker slot', 3
            if !defined $ready || $ready ne 'ready';

        Time::HiRes::sleep(0.05);          # it is in select() by now
        my $t0 = Time::HiRes::time();
        Hyperman->publish('ping', 'hello');

        my $line = <$r>;
        chomp $line if defined $line;
        my ($how, $woke, $payload) = split ' ', ($line // 'timeout 0 -');
        my $el = $woke - $t0;          # publish -> wake, across processes

        is($how, 'woken',
            'the child came out of select() - it was TOLD, not left to poll');
        cmp_ok($el, '<', 1.0,
            'and promptly: a poll would have sat until the 5s timeout')
            or diag "took ${el}s";
        is($payload, 'hello', 'with the message already on the ring');
        note sprintf 'publish to wake: %.3f ms', $el * 1000;
    }
    close $r;
    waitpid $pid, 0;
}

# ---- the coalescing flag ------------------------------------------------------
# A burst of a thousand publishes must not become a thousand writes to each
# worker's descriptor. Without the flag the bus becomes its own thundering
# herd, and it does so exactly under the load where that hurts.
{
    pipe my ($r, $w) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (!$pid) {
        close $r;
        my $fd = Hyperman->bus_waker_take(2);
        if ($fd < 0) { syswrite $w, "0\n"; close $w; exec $^X, '-e', '1'; }
        Hyperman->bus_reset;
        # A raw descriptor number is not a filehandle; sysread needs one
        # opened onto it.
        open my $wake, '<&=', $fd or do {
            syswrite $w, "-1\n"; close $w; exec $^X, '-e', '1';
        };
        syswrite $w, "ready\n";
        Time::HiRes::sleep(0.5);           # never drain: let the pokes pile up
        # sysread on a NON-BLOCKING descriptor returns undef with EAGAIN when
        # it is drained, not 0, so the loop has to test definedness first.
        my ($bytes, $buf) = (0);
        for (;;) {
            my $n = sysread $wake, $buf, 65536;
            last unless defined $n && $n > 0;
            $bytes += $n;
        }
        syswrite $w, "$bytes\n";
        close $w;
        exec $^X, '-e', '1';
    }

    close $w;
    my $ready = <$r>;                       # it has taken its slot
    Hyperman->publish('flood', $_) for 1 .. 1000;

    my $bytes = <$r>;
    chomp $bytes if defined $bytes;
    close $r;
    waitpid $pid, 0;

    cmp_ok($bytes, '<', 50,
        'a thousand publishes produced only a handful of pokes - the '
      . 'coalescing flag is what stops the bus becoming its own thundering '
      . 'herd')
        or diag "bytes written to the sleeping worker: $bytes";
    note "pokes for 1000 publishes: $bytes";
}

# ---- the coalescing flag lets go again ---------------------------------------
# The flag above is what keeps a burst from becoming a thundering herd. The
# risk it carries is the opposite failure: a flag left SET with an empty pipe.
# Only the publisher that flips it from zero writes anything, so a stuck flag
# means nobody ever pokes that worker again - it goes permanently deaf, having
# been woken perfectly well for the first few messages.
#
# The way in was a publish landing between the flag being cleared and the pipe
# being emptied: its byte was swallowed by a read loop that had already
# decided it was done, leaving the flag set over an empty pipe.
#
# What makes that likely rather than exotic is the coalescing flag itself. A
# publisher only writes when it finds the flag clear, and the moment the flag
# is clear is the moment the reader has just cleared it - which under the old
# order is immediately BEFORE its read. The one publisher that gets to write is
# aimed at the window.
#
# So the shape of this test is not "publish a lot" but "publish STEADILY":
# each message wakes the child, and each has its own small chance of arriving
# in the next one's window. A few hundred of those is a near-certainty, which
# is why three CPAN Testers boxes reported it and a fast laptop at five
# milliseconds a message did not.
#
# The child is a worker: it blocks in select() and dispatches ONLY when it is
# woken. It never polls, so a lost poke is a message it never sees rather than
# one it picks up a moment later.
{
    my $WANT = 20000;
    pipe my ($r, $w) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if (!$pid) {
        close $r;
        my $fd = Hyperman->bus_waker_take(3);
        if ($fd < 0) { syswrite $w, "nofd\n"; close $w; exec $^X, '-e', '1'; }
        Hyperman->bus_reset;
        my $seen = 0;
        Hyperman->subscribe('steady' => sub { $seen++ });
        syswrite $w, "ready\n";

        my $rin = '';
        vec($rin, $fd, 1) = 1;
        # Leaves as soon as everything is accounted for, so a working bus
        # spends no time here. The timeout only decides how long a BROKEN one
        # takes to say so.
        my $idle = 0;
        while ($seen + Hyperman->bus_gaps < $WANT && $idle < 8) {
            my $n = select my $rout = $rin, undef, undef, 0.25;
            # A timeout is NOT a chance to look anyway. Dispatching here would
            # turn this into a polling reader, and a polling reader passes
            # this test with the bug still in place.
            if (!defined $n || $n <= 0) { $idle++; next }
            $idle = 0;
            Hyperman->bus_waker_drained;
            Hyperman->dispatch;
        }
        syswrite $w, sprintf("%d %d\n", $seen, Hyperman->bus_gaps);
        close $w;
        exec $^X, '-e', '1';
    }

    close $w;
    my $ready = <$r>;
    chomp $ready if defined $ready;

    SKIP: {
        skip 'child could not take a waker slot', 1
            if !defined $ready || $ready ne 'ready';

        # No pacing. A publisher that pauses between messages hands the child
        # its whole wakeup uncontested and the window never opens - which is
        # why a laptop at five milliseconds a message saw nothing wrong and
        # three CPAN Testers boxes did.
        Time::HiRes::sleep(0.05);              # it is in select() by now
        Hyperman->publish('steady', $_) for 1 .. $WANT;

        my $line = <$r>;
        chomp $line if defined $line;
        my ($seen, $gaps) = split ' ', ($line // '0 0');

        # Delivered plus dropped, because those are the only two honest
        # outcomes: this publisher outruns the reader, so most of these are
        # legitimately lapped, and a drop the bus counts is the bus working.
        #
        # A floor rather than equality, because the tail is ragged by design -
        # the reader stops on a slot still being written and waits to be told
        # again, so the last handful sit unread until the next publish, and
        # here there is no next publish. The floor is nowhere near that: a
        # reader that stops being poked at all comes back with well under one
        # percent, which is what this caught.
        cmp_ok($seen + $gaps, '>=', $WANT * 0.9,
            'the reader was still being poked at the end of the burst - a '
          . 'flag left set over an empty pipe silences a worker for good, '
          . 'and it goes quiet part way through rather than at the start')
            or diag "accounted for @{[ $seen + $gaps ]} of $WANT "
                  . "(seen $seen, gaps $gaps)";
        note "seen $seen, gaps $gaps";
    }
    close $r;
    waitpid $pid, 0;
}

# ---- what the documentation promises ----------------------------------------
# Two behaviours that are easy to change by accident and would make the POD a
# lie, which is worse than no POD.
{
    # bus_reset moves BOTH cursors. There are two - one for receive(), one for
    # the dispatcher - but a caller saying "from now on" means the process,
    # not one of its halves.
    Hyperman->publish('resettest', 'before');
    Hyperman->bus_reset;
    my $seen = 0;
    my $id = Hyperman->subscribe('resettest' => sub { $seen++ });
    is(Hyperman->dispatch, 0,
        'bus_reset moved the DISPATCHER cursor too, so nothing published '
      . 'before it is replayed');
    is_deeply([ Hyperman->receive ], [],
        'and the receive cursor, which is the other half of the same promise');
    Hyperman->unsubscribe($id);
}

{
    # a group begins at "from now on", not at the oldest message in the ring
    Hyperman->publish('late', 'sent-before-anyone-joined');
    my @got = Hyperman->claim('late', 'latecomers');
    is_deeply(\@got, [],
        'a group created AFTER a message was sent does not receive it - '
      . 'joining means from now on, or a worker restarting at 3am replays '
      . 'the whole ring at the moment it can least afford it');

    Hyperman->publish('late', 'sent-after');
    my @then = Hyperman->claim('late', 'latecomers');
    is(scalar @then, 1, 'and it does receive what comes after');
}

done_testing;
