#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use File::Spec ();
use Fetch;

# A Fetch created before a fork is copied into the child, loop and all, and
# the loop's kernel object is SHARED with the parent rather than copied. An
# epoll instance is one interest list for both processes; an io_uring is a
# submission ring in shared memory with per-process cursors. A child that
# touched the inherited loop - even just by exiting, through global
# destruction of a Fetch it never used - deregistered the parent's sockets
# (epoll) or wedged the parent in an endless io_uring_enter loop that ate the
# machine (io_uring). That was Open-API's t/16-security.t on the Linux
# smokers. On macOS the inherited kqueue is dead and its number is reused by
# the child's own kqueue, so destroying the old loop there shut the new one.
#
# The loop now notices the pid changed and disowns itself: the inherited
# backend is released without touching it and a fresh one is built only if
# the child needs one. Each case below is a child that does something with
# the inherited agent, and the parent must still be working afterwards.

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;

my $spid = fork;
plan skip_all => "cannot fork: $!" unless defined $spid;
if (!$spid) {
    # keep-alive server, one process per connection, so the parent's parked
    # connection does not block a child's fresh one
    open STDOUT, ">", File::Spec->devnull();
    open STDERR, ">", File::Spec->devnull();
    alarm 120;
    $SIG{TERM} = sub { exit 0 };
    $SIG{CHLD} = 'IGNORE';
    while (my $cli = $srv->accept) {
        my $kid = fork;
        if (defined $kid && !$kid) {
            alarm 60;
            close $srv;   # or the port outlives the accept loop
            $cli->autoflush(1);
            while (1) {
                my $seen = 0;
                while (my $l = <$cli>) { $seen++; last if $l eq "\r\n" }
                last unless $seen;
                my $out = "ok";
                print $cli "HTTP/1.1 200 OK\r\n"
                         . "Content-Type: text/plain\r\n"
                         . "Content-Length: " . length($out) . "\r\n\r\n$out";
            }
            close $cli;
            exit 0;
        }
        close $cli;
    }
    exit 0;
}
close $srv;
select(undef, undef, undef, 0.2);   # let the child start accepting
my $parent = $$;   # the test's own children exit through this END too
END { kill 'TERM', $spid if $spid && $$ == $parent }

my $url = "http://127.0.0.1:$port/";

plan tests => 11;

my $ua = Fetch->new;
is($ua->get($url)->get->{status}, 200, 'parent: first request');
diag('loop backend: ' . $ua->loop->backend);

# Runs $body in a forked child; returns its exit status. A child that hangs
# is killed by its own alarm, which shows up as a signal.
sub in_child {
    my ($body) = @_;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        alarm 30;
        my $code = eval { $body->() } ? 0 : ($@ ? 2 : 1);
        print STDERR "# child: $@" if $code == 2;
        exit $code;   # a real exit: global destruction runs in the child
    }
    local $SIG{ALRM} = sub { kill 'KILL', $pid; die "child $pid hung\n" };
    alarm 60;
    waitpid $pid, 0;
    alarm 0;
    return $?;
}

# ---- 1. a child that only exits ------------------------------------------
# The inherited agent, its parked connection and the loop are destroyed in
# the child's global destruction. Nothing of that may reach the parent's
# backend.
is(in_child(sub { 1 }), 0, 'child that merely exits: clean exit');
is($ua->get($url)->get->{status}, 200,
   'parent still served after a child exited');

# ---- 2. a child that builds its own agent -------------------------------
# The implicit loop is rebuilt per process, so the new agent gets its own.
# Destroying the OLD agent afterwards must not take the new loop with it
# (the kqueue-number-reuse case).
is(in_child(sub {
    my $c = Fetch->new;
    $c->get($url)->get->{status} == 200 or die "child request 1\n";
    undef $ua;   # the inherited agent + loop go now, not at exit
    $c->get($url)->get->{status} == 200 or die "child request 2\n";
    1;
}), 0, 'child with its own agent: both requests served');
is($ua->get($url)->get->{status}, 200,
   'parent still served after a child destroyed its inherited agent');

# ---- 3. a child that drives the inherited agent -------------------------
# The old agent's loop disowns the parent's backend on first use and builds
# one for this process.
is(in_child(sub {
    $ua->get($url)->get->{status} == 200 or die "child request\n";
    $ua->get($url)->get->{status} == 200 or die "child request 2\n";
    1;
}), 0, 'child driving the inherited agent: served');
is($ua->get($url)->get->{status}, 200,
   'parent still served after a child drove its agent');

# ---- 4. a fork from inside a callback -----------------------------------
# The child continues from inside hm_loop_run; the per-turn check must hand
# it a backend of its own rather than the parent's.
{
    my ($cpid, $fired);
    $ua->loop->timer(0.01, sub {
        $fired = 1;
        $cpid = fork;
        die "fork: $!" unless defined $cpid;
        if (!$cpid) {
            alarm 30;
            my $ok = eval { $ua->get($url)->get->{status} == 200 };
            print STDERR "# child: $@" if $@;
            exit($ok ? 0 : 1);
        }
        $ua->loop->stop;
    });
    $ua->loop->run;
    ok($fired, 'timer callback ran and forked');
    waitpid $cpid, 0;
    is($?, 0, 'child forked from a loop callback: served');
    is($ua->get($url)->get->{status}, 200,
       'parent still served after a callback fork');
}

# ---- the explicit loop reports a backend after disowning ----------------
is(in_child(sub {
    my $name = $ua->loop->backend;
    $ua->get($url)->get;
    $ua->loop->backend eq $name or die "backend changed name\n";
    1;
}), 0, 'a rebuilt loop reports the same backend');
