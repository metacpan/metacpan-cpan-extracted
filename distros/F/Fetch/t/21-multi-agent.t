#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use File::Spec ();
use Fetch;

# Two agents in one process. This used to hang outright: each Fetch->new made
# its own Standalone loop, and install_await wrote a *process global*, so the
# agent constructed last owned the await path for both. Awaiting the first
# agent's future then pumped the second agent's loop, which has no watcher for
# that socket, and the backend blocked in the kernel with no deadline - a stall
# no Perl-level alarm can even interrupt.
#
# The server forks per connection on purpose: with two loops in flight only one
# is being pumped at a time, so a serial accept loop would block reading the
# idle agent's socket and deadlock the test rather than the library.

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    open STDOUT, ">", File::Spec->devnull();
    open STDERR, ">", File::Spec->devnull();
    alarm 120;
    $SIG{TERM} = sub { exit 0 };
    $SIG{CHLD} = 'IGNORE';
    while (my $cli = $srv->accept) {
        my $kid = fork;
        if (defined $kid && !$kid) {
            while (my $l = <$cli>) { last if $l eq "\r\n" }
            my $out = "ok";
            print $cli "HTTP/1.1 200 OK\r\n"
                     . "Content-Type: text/plain\r\n"
                     . "Content-Length: " . length($out) . "\r\n"
                     . "Connection: close\r\n\r\n$out";
            close $cli;
            exit 0;
        }
        close $cli;
    }
    exit 0;
}
select(undef, undef, undef, 0.2);   # let the child bind/listen
END { kill 'TERM', $pid if $pid }

my $url = "http://127.0.0.1:$port/";

plan tests => 10;

# ---- the implicit loop is one per process --------------------------------
{
    my $a = Fetch->new;
    my $b = Fetch->new;
    is($a->loop, $b->loop, 'agents with no loop share one implicit loop');

    is($a->get($url)->get->{status}, 200, 'first agent');
    is($b->get($url)->get->{status}, 200, 'second agent');
    is($a->get($url)->get->{status}, 200, 'back to the first agent');
}

# ---- agents on deliberately separate loops -------------------------------
{
    my $a = Fetch->new(loop => Fetch::Loop::Standalone->new);
    my $b = Fetch->new(loop => Fetch::Loop::Standalone->new);
    isnt($a->loop, $b->loop, 'explicit loops stay separate');

    is($a->get($url)->get->{status}, 200, 'agent on its own loop');
    is($b->get($url)->get->{status}, 200, 'other agent on its own loop');

    # The one that actually hung: await B while A is still in flight, so the
    # global await hook (pointing at B) is wrong for A.
    my $fa = $a->get($url);
    my $fb = $b->get($url);
    is($fb->get->{status}, 200, 'awaited the younger loop first');
    is($fa->get->{status}, 200, 'older loop still awaitable afterwards');
}

# ---- the pin survives a then-chain ---------------------------------------
# ->get lands on the tail of the chain, but only the head knows which loop
# the socket is armed on.
{
    my $a = Fetch->new(loop => Fetch::Loop::Standalone->new);
    my $b = Fetch->new(loop => Fetch::Loop::Standalone->new);
    my $f = $a->get($url)->then(sub { "chained:" . $_[0]->{status} });
    is($f->get, 'chained:200', 'derived future inherits its upstream loop');
}
