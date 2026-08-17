#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan skip_all => 'the worker pool and fork tests need fork(2); Windows runs a single worker'
    if $^O eq 'MSWin32';
use Hyperman;

# A loop belongs to the process that created it, and so does every descriptor
# in it. A loop inherited across a fork must be freed WITHOUT closing any of
# them.
#
# On kqueue this is not a tidiness point but a correctness one: kqueue
# descriptors do not survive fork(2) - the kernel invalidates the child's copy,
# which frees the number, and the child's own kqueue() is then handed it
# straight back. Freeing the inherited loop used to close that number, shutting
# the queue the child was actually using, and nothing it watched fired again.
#
# The shape below is exactly what a preforking server does: the child builds
# its own loop and lets the inherited one go.

sub fires_in_child {
    my ($backend) = @_;
    my $parent = $backend ? Hyperman::Loop->new($backend) : Hyperman::Loop->new;

    my $pid = open my $rd, '-|';
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $child = $backend ? Hyperman::Loop->new($backend)
                             : Hyperman::Loop->new;
        undef $parent;                 # the inherited loop goes here

        pipe(my $r, my $w) or die "pipe: $!";
        syswrite $w, 'x';
        my $f = $child->readable_f($r);
        $child->run_until($f);
        print(($f->is_ready ? "fired" : "silent"), "\n");
        exit 0;
    }
    chomp(my $out = <$rd> // '');
    close $rd;
    return $out;
}

is(fires_in_child('poll'), 'fired',
   "poll: a child's own loop still fires after the inherited one is freed");

# and the platform default, which is the one a real server uses
is(fires_in_child(undef), 'fired',
   'default backend: likewise, and this is the kqueue case on the BSDs');

# The other direction: a child MUTATING an inherited loop must not reach
# the parent. On Linux an epoll instance is a shared kernel object across
# fork - both processes' epoll_ctl calls edit the same interest list - so
# before the HM_LOOP_INHERITED guard a child calling remove() on watchers
# it inherited silently deregistered the PARENT's fds, and the parent
# waited on an empty set forever (Punk t/39, via DBIx::Loop's pool
# disown). kqueue passes either way: the child's copy is dead. The epoll
# case is the one this exists for - it fails on Linux without the guard.
sub parent_survives_child_remove {
    my ($backend) = @_;
    my $loop = $backend ? Hyperman::Loop->new($backend) : Hyperman::Loop->new;
    pipe(my $r, my $w) or die "pipe: $!";
    my $f = $loop->readable_f($r);        # the parent's registration

    my $pid = open my $rd, '-|';
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        # what a disown does: drop the inherited watcher by fd. No eval:
        # if the API moves, this test must fail loudly, not pass by
        # silently doing nothing.
        $loop->unwatch_io($r, 'r');
        print "removed\n";
        exit 0;
    }
    chomp(my $ack = <$rd> // '');
    close $rd;
    return 'child failed' unless $ack eq 'removed';

    syswrite $w, 'x';
    $loop->run_until($f);
    return $f->is_ready ? 'fired' : 'silent';
}

is(parent_survives_child_remove('poll'), 'fired',
   "poll: a child's remove on the inherited loop cannot unwatch the parent");
is(parent_survives_child_remove(undef), 'fired',
   'default backend: likewise - the epoll interest list is shared across '
 . 'fork, and only the guard keeps a child out of it');

done_testing();
