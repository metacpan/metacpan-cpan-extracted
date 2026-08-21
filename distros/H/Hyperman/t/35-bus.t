#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Hyperman;

# The cross-worker message bus.
#
# Every property that matters here is a property ACROSS PROCESSES: fanout
# reaching every worker, a queue group handing each message to exactly one of
# them, and a lapped reader being told how much it lost. None of it can be
# shown in a single process, so this file forks for real.

plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';

# A small arena, so lapping can be forced deliberately rather than by waiting
# for four megabytes to fill.
plan skip_all => 'no arena on this platform (no atomics): the bus is '
               . 'local-only here, which is the documented behaviour'
    unless Hyperman->bus_init(slots => 64, slot_size => 256, groups => 8);

ok(Hyperman->bus_live, 'there is a shared ring');

# ---- one process -------------------------------------------------------------
{
    Hyperman->bus_reset;
    is(Hyperman->publish('room:lobby', 'hello'), 1, 'publish reaches the ring');
    my @got = Hyperman->receive;
    is(scalar @got, 1, 'received one');
    is($got[0][0], 'room:lobby', 'the topic came back');
    is($got[0][1], 'hello',      'and the payload');
    is(Hyperman->bus_gaps, 0, 'with no gaps');

    is_deeply([ Hyperman->receive ], [],
        'receiving again yields nothing: the cursor moved');
}

# ---- oversize is refused, never truncated ------------------------------------
# A truncated WebSocket frame is a protocol violation delivered to every member
# of a room. Failing where the caller can see it is the better outcome.
{
    is(Hyperman->publish('t', 'x' x 4096), -1,
        'an oversize message is REFUSED, and says so distinctly from "sent"');
    Hyperman->bus_reset;
    is_deeply([ Hyperman->receive ], [], 'and nothing of it reached the ring');
}

# ---- binary payloads survive -------------------------------------------------
{
    my $bin = join '', map { chr } 0 .. 127;   # the slot here is only 256B
    Hyperman->bus_reset;
    is(Hyperman->publish('bin', $bin), 1, 'a binary payload publishes');
    my @got = Hyperman->receive;
    is($got[0][1], $bin, 'and comes back byte for byte, NUL and all');
}

# ---- FANOUT across real processes -------------------------------------------
# Every child must see every message. This is exactly what Punk::WebSocket::Room
# cannot do today, and the reason this whole thing exists.
{
    my $NKIDS = 4;
    my $NMSG  = 20;
    my (@pipes, @kids);

    for my $k (1 .. $NKIDS) {
        pipe my ($r, $w) or die "pipe: $!";
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            close $r;
            Hyperman->bus_reset;          # a worker starts from now
            my (@seen, $spins);
            $spins = 0;
            # Stop on the sentinel, not on a timeout. A timeout that expires
            # while the parent is still publishing loses messages, and looks
            # exactly like the bus dropping them.
            OUTER: while ($spins++ < 5000) {
                for my $m (Hyperman->receive) {
                    last OUTER if $m->[1] eq 'END';
                    push @seen, $m->[1];
                }
                select undef, undef, undef, 0.002;
            }
            print $w join(',', @seen), "\n";
            close $w;
            exec $^X, '-e', '1';    # leave without running Test::More's END
        }
        close $w;
        push @pipes, $r;
        push @kids, $pid;
    }

    select undef, undef, undef, 0.2;         # let them all reach receive()
    Hyperman->publish('room:lobby', $_) for 1 .. $NMSG;
    Hyperman->publish('room:lobby', 'END');

    my @results;
    for my $r (@pipes) {
        my $line = <$r>;
        close $r;
        chomp $line if defined $line;        # or the last id keeps the newline
        push @results, [ split /,/, ($line // '') ];
    }
    waitpid $_, 0 for @kids;

    is(scalar @results, $NKIDS, 'every child reported');
    is_deeply([ grep { scalar @{ $results[$_] } != $NMSG } 0 .. $#results ], [],
        'FANOUT: every child received every message - which is the thing a '
      . 'per-worker room cannot do')
        or diag 'counts: ' . join(',', map { scalar @$_ } @results);
    is_deeply($results[0], [ 1 .. $NMSG ], 'and in publish order');
}

# ---- QUEUE GROUP: exactly once across the pool -------------------------------
# The load-balanced mode. One atomic add on a SHARED cursor is the whole
# mechanism, and the balancing is a consequence of it rather than a scheduler.
#
# Two runs, because there are two things to prove and they need different
# conditions. The first stays well inside the ring, so nothing can lap and the
# arithmetic is exact. The second deliberately overruns it.
sub run_group {
    my ($topic, $nmsg, $nkids, $gap_ms) = @_;
    my (@pipes, @kids);

    for my $k (1 .. $nkids) {
        pipe my ($r, $w) or die "pipe: $!";
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            close $r;
            Hyperman->bus_reset;
            my (@mine, $spins);
            $spins = 0;
            # The stop signal goes over FANOUT, not over the group: a sentinel
            # published to the group would be claimed by ONE child, and the
            # other three would sit waiting for a message never coming.
            OUTER: while ($spins++ < 20000) {
                push @mine, map { $_->[1] } Hyperman->claim($topic);
                for my $m (Hyperman->receive) {
                    last OUTER if $m->[0] eq 'stop';
                }
                select undef, undef, undef, 0.0005;
            }
            push @mine, map { $_->[1] } Hyperman->claim($topic);   # the tail
            print $w join(',', @mine), "\n";
            close $w;
            exec $^X, '-e', '1';
        }
        close $w;
        push @pipes, $r;
        push @kids, $pid;
    }

    select undef, undef, undef, 0.2;         # let them all reach claim()
    for my $i (1 .. $nmsg) {
        Hyperman->publish($topic, $i);
        select undef, undef, undef, $gap_ms if $gap_ms;
    }
    select undef, undef, undef, 0.2;         # let the claimers catch up
    Hyperman->publish('stop', 'END');

    my (%count, @per_worker);
    for my $r (@pipes) {
        my $line = <$r>;
        close $r;
        chomp $line if defined $line;
        my @mine = grep { length } split /,/, ($line // '');
        push @per_worker, scalar @mine;
        $count{$_}++ for @mine;
    }
    waitpid $_, 0 for @kids;
    return (\%count, \@per_worker);
}

# ---- inside the ring: the arithmetic is exact --------------------------------
{
    my $NMSG = 40;                            # the ring holds 64
    my ($count, $per) = run_group('thumbs', $NMSG, 4, 0.001);
    my $total = 0; $total += $_ for @$per;

    my %gs = Hyperman->bus_stats('thumbs');
    is($total, $NMSG,
        'QUEUE GROUP: the pool handled every message, and only once each')
        or diag "per worker: @$per  total=$total gaps=$gs{group_gaps} "
              . "missing=" . join(',', grep { !$count->{$_} } 1 .. $NMSG);
    is_deeply([ sort { $a <=> $b } grep { $count->{$_} != 1 } keys %$count ], [],
        'no message was handled twice');
    is_deeply([ grep { !$count->{$_} } 1 .. $NMSG ], [], 'and none was missed');

    my %stats = Hyperman->bus_stats('thumbs');
    is($stats{group_gaps}, 0, 'and nothing lapped, well inside the ring');

    cmp_ok(scalar(grep { $_ } @$per), '>', 1,
        'the work spread over more than one worker - balancing falls out of '
      . 'the claim, with no scheduler to tune')
        or diag "per worker: @$per";
    note "per worker: @$per";
}

# ---- past the ring: lost is COUNTED, and nothing is handled twice ------------
# 200 messages through a 64-slot ring, published as fast as they can go. Some
# WILL be lapped - that is the drop-oldest rule doing its job, not a defect -
# and the contract is that every message is either handled exactly once or
# counted as lost. A bus that quietly handled one twice under pressure would
# be far worse than one that admits to dropping.
{
    my $NMSG = 200;
    my ($count, $per) = run_group('burst', $NMSG, 4, 0);
    my $total = 0; $total += $_ for @$per;
    my %stats = Hyperman->bus_stats('burst');

    is_deeply([ sort { $a <=> $b } grep { $count->{$_} != 1 } keys %$count ], [],
        'under overload, still nothing handled twice');
    is($total + $stats{group_gaps}, $NMSG,
        'and handled plus lost accounts for EVERY message - which is what '
      . 'makes the loss a diagnosis rather than a mystery')
        or diag "handled=$total gaps=$stats{group_gaps} per worker: @$per";
    note "handled=$total lapped=$stats{group_gaps}";
}

# ---- BOTH MODES ON ONE TOPIC, AT ONCE ---------------------------------------
# The two are not alternatives and nothing stops a topic having both. A room
# might fan out to every worker's WebSocket members while a group of workers
# also takes one message each to write to a log. The claim consumes the
# group's own cursor and nobody else's, so the fanout readers must still see
# everything.
{
    my $NMSG = 12;
    my (@pipes, @kids);

    # two fanout readers and two group members, on the same topic
    for my $role (qw(fan fan grp grp)) {
        pipe my ($r, $w) or die "pipe: $!";
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            close $r;
            Hyperman->bus_reset;
            my (@mine, $spins);
            $spins = 0;
            OUTER: while ($spins++ < 20000) {
                push @mine, map { $_->[1] } Hyperman->claim('both', 'loggers')
                    if $role eq 'grp';
                for my $m (Hyperman->receive) {
                    last OUTER if $m->[0] eq 'stop';
                    push @mine, $m->[1] if $role eq 'fan' && $m->[0] eq 'both';
                }
                select undef, undef, undef, 0.0005;
            }
            push @mine, map { $_->[1] } Hyperman->claim('both', 'loggers')
                if $role eq 'grp';
            print $w "$role " . join(',', @mine) . "\n";
            close $w;
            exec $^X, '-e', '1';
        }
        close $w;
        push @pipes, $r;
        push @kids, $pid;
    }

    select undef, undef, undef, 0.2;
    for my $i (1 .. $NMSG) {
        Hyperman->publish('both', $i);
        select undef, undef, undef, 0.001;
    }
    select undef, undef, undef, 0.2;
    Hyperman->publish('stop', 'END');

    my (@fan, @grp);
    for my $r (@pipes) {
        my $line = <$r>;
        close $r;
        chomp $line if defined $line;
        my ($role, $list) = split ' ', ($line // ''), 2;
        my @got = grep { length } split /,/, ($list // '');
        push @{ $role eq 'fan' ? \@fan : \@grp }, \@got;
    }
    waitpid $_, 0 for @kids;

    is_deeply([ map { scalar @$_ } @fan ], [ $NMSG, $NMSG ],
        'the FANOUT readers each saw every message, even though a group was '
      . 'claiming the same topic at the same time');

    my $grp_total = 0; $grp_total += scalar @$_ for @grp;
    is($grp_total, $NMSG,
        'and the GROUP still split exactly one copy between its members');
}

# ---- lapping is COUNTED, not silently skipped --------------------------------
# A gap with a number beside it is a diagnosis. A gap without one is a mystery,
# and indistinguishable from a quiet room.
{
    Hyperman->bus_reset;
    my $before = Hyperman->bus_gaps;
    Hyperman->publish('t', 'x') for 1 .. 200;    # the ring holds 64
    my @got = Hyperman->receive;

    is(scalar @got, 64, 'a lapped reader gets the newest ring-full');
    is(Hyperman->bus_gaps - $before, 200 - 64,
        'and is told EXACTLY how many it lost');
}

# ---- the stats are reachable -------------------------------------------------
{
    my %s = Hyperman->bus_stats;
    cmp_ok($s{published}, '>', 0, 'the published counter is reachable');
    Hyperman->publish('t', 'y');
    my %after = Hyperman->bus_stats;
    is($after{published}, $s{published} + 1, 'and counts a publish');
    ok(!exists $s{group_gaps}, 'group_gaps is absent when no group was named');
}

done_testing;
