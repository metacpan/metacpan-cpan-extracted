#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child);
use File::Temp ();
use Time::HiRes ();
use Hyperman;

# A REPLACEMENT WORKER CAN STILL HEAR THE POOL.
#
# A worker is woken through a pipe it claims by worker index, and two things
# used to conspire to leave a respawned one without any.
#
# The supervisor keeps its children packed, swapping the last entry down over
# a departed one, and it respawned with the next free POSITION in that array.
# Kill the worker at position 0 of three and the survivor from position 2 moves
# into it, so the position offered to the replacement was 2 - an index a LIVE
# sibling still held. And the slot its predecessor died holding stayed flagged
# taken, because nothing releases a slot for a process that was killed.
#
# So the replacement asked for a slot it could not have, was refused, installed
# no watch, and never read the ring again. It served requests perfectly well
# and was deaf to every publish for the rest of its life - no error, and a
# cache or a room reporting a healthy pool throughout.
#
# The publish here comes from THIS process rather than through a request,
# because a request lands on whichever worker the kernel chose and a test that
# cannot say which one it reached proves nothing about the one it cares about.

plan skip_all => 'prefork workers are POSIX-only' if $^O eq 'MSWin32';
plan skip_all => 'no arena on this platform (no atomics)'
    unless Hyperman->bus_init(slots => 256, slot_size => 256, wakers => 8);

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub slurp { my ($f) = @_; open my $h, '<', $f or return ''; local $/; my $d = <$h>; close $h; $d // '' }
sub workers_seen { map { m{/(\d+)\.up$} ? $1 : () } glob "$dir/*.up" }
sub workers_live { grep { kill 0, $_ } workers_seen() }
sub waker_of     { my ($p) = @_; slurp("$dir/$p.up") }
sub heard        { my ($p, $what) = @_; slurp("$dir/$p.recv") =~ /\Q$what\E/ ? 1 : 0 }

# Wait for a condition, or give up. Every wait here has a ceiling: a test that
# blocks for ever on a worker that never came up tells nobody anything.
sub until_ok {
    my ($secs, $cond) = @_;
    my $deadline = Time::HiRes::time() + $secs;
    while (Time::HiRes::time() < $deadline) {
        return 1 if $cond->();
        Time::HiRes::sleep(0.05);
    }
    return 0;
}

my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child();
    Hyperman->on_worker_start(sub {
        my $arena = Hyperman->arena;
        open my $fh, '>', "$dir/$$.up" or return;
        print $fh ($arena ? $arena->waker_fd : -1);
        close $fh;
        Hyperman->subscribe('pool:probe' => sub {
            open my $f, '>>', "$dir/$$.recv" or return;
            print $f "$_[1]\n";
            close $f;
        });
    });
    Hyperman->run(
        app  => sub { [ 200, ['Content-Type' => 'text/plain'], ["pid=$$"] ] },
        host => '127.0.0.1', port => $port, workers => 3,
    );
    exit 0;
}

ok(until_ok(20, sub { workers_seen() >= 3 }), 'the pool came up with three workers')
    or do { kill 'TERM', $pid; waitpid $pid, 0; done_testing; exit };

my @first = sort { $a <=> $b } workers_live();
is(scalar @first, 3, 'three workers are alive');
is(scalar(grep { waker_of($_) >= 0 } @first), 3,
    'and each holds a wakeup descriptor of its own');

Hyperman->publish('pool:probe', 'before');
ok(until_ok(10, sub { 3 == grep { heard($_, 'before') } @first }),
    'a publish reached every worker in the pool');

# ---- now kill one, and put the same question to its replacement -------------

my $victim = $first[0];
kill 'KILL', $victim;
ok(until_ok(30, sub { my @l = workers_live(); @l >= 3 && !grep { $_ == $victim } @l }),
    "worker $victim was killed and the supervisor respawned");

my @second = sort { $a <=> $b } workers_live();
my ($fresh) = grep { my $p = $_; !grep { $_ == $p } @first } @second;

SKIP: {
    skip 'no replacement worker appeared', 3 unless defined $fresh;

    cmp_ok(waker_of($fresh), '>=', 0,
        'THE REPLACEMENT HOLDS A WAKEUP DESCRIPTOR - spawned with a position '
      . 'rather than its predecessor\'s index it was handed a live sibling\'s '
      . 'slot, refused, and left with none');

    my %taken;
    $taken{ waker_of($_) }++ for @second;
    is(scalar(keys %taken), scalar @second,
        'and no two live workers share one - a reclaim takes over a dead '
      . "process's slot, never a live one's pipe");

    Hyperman->publish('pool:probe', 'after');
    ok(until_ok(10, sub { heard($fresh, 'after') }),
        'and a publish REACHES it - which is the whole point of the '
      . 'descriptor, and what a deaf worker silently stopped doing');
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
