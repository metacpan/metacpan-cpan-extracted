#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use File::Spec ();
use Fetch;

# Leaving a program from inside a loop callback, with a keep-alive connection
# still parked.
#
# `exit` inside a callback does not return through hm_loop_run: perl unwinds to
# the top and runs global destruction from there, so the agent, its pool and
# the loop are all torn down by perl rather than by anything of ours, in the
# order perl picks. A connection holds its native loop as a RAW POINTER - the
# loop object is the agent's, not the connection's - so if perl frees
# Fetch::Loop::Standalone first, a connection disarming itself on the way out
# reads a freed loop: it walks l->timers and calls l->be->remove_io on a
# backend that is gone.
#
# That is a use-after-free whose outcome is the allocator's business, which is
# why it was invisible here and a SIGSEGV on one 5.20.1 smoker (t/28-fork.t's
# callback-fork child, the only one of its children that tears down under
# global destruction rather than ordinary refcounting). Nothing needs
# disarming at that point anyway - the process is ending - so nothing here
# touches the loop once PL_dirty is set.
#
# A child per case, because the assertion is on how the process LEAVES: 0 for a
# clean exit, a signal for the fault.
#
# The agent has to be reachable from outside the frame that exits, or there is
# nothing to test: perl's unwind pops the sub's pad on the way out, so an agent
# in a `my` inside the callback is freed there, in the ordinary way, with the
# loop still up. Held in a package variable it survives to global destruction,
# which is where the order stops being ours to pick - and is why t/28-fork.t's
# file-scoped agent found this and its in_child cases did not.

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;

my $spid = fork;
plan skip_all => "cannot fork: $!" unless defined $spid;
if (!$spid) {
    open STDOUT, ">", File::Spec->devnull();
    open STDERR, ">", File::Spec->devnull();
    alarm 120;
    $SIG{TERM} = sub { exit 0 };
    $SIG{CHLD} = 'IGNORE';
    while (my $cli = $srv->accept) {
        my $kid = fork;
        if (defined $kid && !$kid) {
            alarm 60;
            close $srv;
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
select(undef, undef, undef, 0.2);
my $parent = $$;
END { kill 'TERM', $spid if $spid && $$ == $parent }

my $url = "http://127.0.0.1:$port/";

plan tests => 3;

# Runs $body in a child and returns how the child left: 0, or the wait status.
sub leaving {
    my ($body) = @_;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        alarm 30;
        $body->();
        exit 0;     # only reached if $body did not leave by itself
    }
    local $SIG{ALRM} = sub { kill 'KILL', $pid; die "child $pid hung\n" };
    alarm 60;
    waitpid $pid, 0;
    alarm 0;
    return $?;
}

our ($UA, $LOOP, @KEEP);

# ---- the implicit loop --------------------------------------------------
is(leaving(sub {
    $UA = Fetch->new;
    $UA->get($url)->get;                     # parks the connection, READ-armed
    $UA->loop->timer(0.01, sub { exit 0 });
    $UA->loop->run;
}), 0, 'exit from inside a callback with a parked connection');

# ---- an explicit loop, built before the agent ---------------------------
# Construction order is one of the things that decides the order global
# destruction picks, so the other one is worth a case of its own.
is(leaving(sub {
    $LOOP = Fetch::Loop::Standalone->new;
    $UA   = Fetch->new(loop => $LOOP);
    $UA->get($url)->get;
    $LOOP->timer(0.01, sub { exit 0 });
    $LOOP->run;
}), 0, 'the same with a loop built before the agent');

# ---- several loops and agents alive at once -----------------------------
is(leaving(sub {
    for (1 .. 4) {
        my $loop = Fetch::Loop::Standalone->new;
        my $ua   = Fetch->new(loop => $loop);
        $ua->get($url)->get;
        push @KEEP, [$loop, $ua];
    }
    $KEEP[0][0]->timer(0.01, sub { exit 0 });
    $KEEP[0][0]->run;
}), 0, 'the same with four loops and agents still alive');
