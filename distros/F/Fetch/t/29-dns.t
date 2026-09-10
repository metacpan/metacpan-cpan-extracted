#!perl
use strict;
use warnings;
use Test::More;
use Fetch;
use IO::Socket::IP;
use Time::HiRes ();

# Resolving a name without stopping the loop (include/fetch/ft_dns.h).
#
# ft_h1_start used to call getaddrinfo() inline. Everything else about a
# request is loop-driven, so that one call was the only thing that could stall
# every OTHER connection on the loop rather than just its own - a nameserver
# taking three seconds froze a loop serving hundreds of sockets. It was
# already wrong for HTTP/1.1 and HTTP/2 before QUIC made it unavoidable.
#
# The resolve now runs on a thread of its own and wakes the loop through a
# pipe. What is asserted below is not how fast that is - timing assertions are
# what fail on a loaded smoker - but WHERE it happens, which is exact: a call
# that starts a request must return before the name has been resolved.

plan skip_all => 'name resolution is inline in this build (no pthreads)'
    unless Fetch::_dns_async();

# ---- the decisive one: resolution is off the calling path --------------------
#
# A name that cannot resolve is what makes this exact. Resolving inline, the
# failure happens inside the call and the future comes back ALREADY FAILED.
# Off the loop thread it cannot: the call returns with nothing decided, and
# the failure arrives later, on the loop. There is no timing in that.
{
    my $ua = Fetch->new;
    my $f  = $ua->get('http://no-such-host.invalid./');
    ok(!$f->is_ready,
       'a request to a name returns before the name has been resolved');

    my $err = eval { $f->get; '' } || "$@";
    like($err, qr/resolve no-such-host\.invalid/,
         '...and the resolve failure arrives on the loop, naming the host');
    ok($f->is_failed, '...as a failed future');
}

# ---- an address literal still resolves inline, and costs nothing ------------
#
# AI_NUMERICHOST makes getaddrinfo a parse with no network in it, so a request
# by number starts no thread and takes no extra turn of the loop. Every other
# test in this dist is this case, which is why they did not need changing.
{
    my $ua = Fetch->new;
    my $f  = $ua->get('http://127.0.0.1:1/');
    # Either already failed (connect refused synchronously) or pending on the
    # connect - what matters is that it did not go near a resolver thread.
    my $err = eval { $f->get; '' } || "$@";
    unlike($err, qr/resolve/,
           'an address literal never reaches the resolver');
}

# ---- a name that resolves, end to end ---------------------------------------
#
# Bound through the name rather than the number, so the request has to go
# through the resolver to find it at all. IO::Socket::IP so that whichever
# family localhost prefers here is the one we listen on.
SKIP: {
    my $srv = IO::Socket::IP->new(LocalHost => 'localhost', LocalPort => 0,
                                  Listen => 5, ReuseAddr => 1);
    skip 'cannot bind localhost', 2 unless $srv;
    my $port = $srv->sockport;

    my $pid = fork;
    skip "fork: $!", 2 unless defined $pid;
    if (!$pid) {
        # Nothing in a forked child may hold the harness's TAP pipe, or the
        # harness reads until an EOF that never comes.
        close STDOUT;
        close STDERR;
        if (my $tb = eval { Test::Builder->new }) {
            for my $h (eval { $tb->output }, eval { $tb->failure_output },
                       eval { $tb->todo_output }) {
                close $h if defined $h;
            }
        }
        alarm 30;
        for (1 .. 6) {
            my $cl = $srv->accept or last;
            my $b = '';
            sysread $cl, $b, 8192;
            syswrite $cl, "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n"
                        . "Connection: close\r\n\r\nok";
            close $cl;
        }
        exit 0;
    }
    close $srv;

    my $ua = Fetch->new;
    my $res = eval { $ua->get("http://localhost:$port/")->get };
    ok($res && $res->status == 200, 'a name resolves and the request completes')
        or diag($@ || 'no response');

    # Several resolves in flight at once. Inline, these would have happened
    # one after another before any of them was a future at all; here they are
    # all outstanding together and the loop settles them as they land.
    my @f = map { $ua->get("http://localhost:$port/") } 1 .. 4;
    is(scalar(grep { $_->is_ready } @f), 0,
       'four concurrent requests are all still resolving after the calls return');
    my @ok = grep { my $r = eval { $_->get }; $r && $r->status == 200 } @f;
    is(scalar @ok, 4, 'and all four complete')
        or diag("only " . scalar(@ok) . " of 4 completed");

    kill 'TERM', $pid;
    waitpid $pid, 0;
}

done_testing;
