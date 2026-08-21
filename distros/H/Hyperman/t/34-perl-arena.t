#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# The Perl doors onto two things that were reachable only from C:
#
#   Hyperman->on_worker_start(\&cb)   - the v4 registry, from Perl
#   Hyperman->deny_add / deny_remove / deny_check / ratelimit_hit
#                                     - the fork-shared arena, from Perl
#
# The arena is the half that cannot be faked in Perl: it is mapped before the
# fork, so a counter written by one worker is read by the next. A hash in the
# worker would give a different denylist per worker and a limit of N per
# worker instead of N. So the test that matters is the one that writes from
# one request and reads the effect from another, which is served by whichever
# worker happens to pick it up.

plan skip_all => 'prefork workers are POSIX-only' if $^O eq 'MSWin32';

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;

# ---- outside a server: every call fails OPEN, and none of them die ---------
{
    is(Hyperman->deny_check('10.0.0.1'), 0,
        'deny_check with no arena mapped denies nothing');
    Hyperman->deny_add('10.0.0.1', 60);
    is(Hyperman->deny_check('10.0.0.1'), 0, 'and an add cannot change that');
    Hyperman->deny_remove('10.0.0.1');

    my ($ok, $rem, $reset) = Hyperman->ratelimit_hit('k', 1, 60);
    is($ok, 1, 'ratelimit_hit with no arena allows');
    cmp_ok($reset, '>', time() - 1, 'and still reports when the window rolls');

    my ($ok2) = Hyperman->ratelimit_hit('k', 0, 60);
    is($ok2, 1, 'a limit of 0 is unlimited');
}

# ---- registration checking, in the caller's own frame ----------------------
{
    my $err = '';
    eval { Hyperman->on_worker_start('not a coderef') } or $err = $@;
    like($err, qr/expects a code reference/, 'a non-coderef croaks');
}

# ---- a Perl callback in every worker, and the arena across them ------------
our $RAN = 0;
is(Hyperman->on_worker_start(sub { $RAN++ }), 1,
    'a Perl consumer registers through Hyperman->on_worker_start');

my $pid = fork // die "fork: $!";
if (!$pid) {
    # Both handles: the child inherits the TAP pipe on STDOUT, and a server
    # writing into it makes the harness see a corrupt stream.
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        app => sub {
            my ($env) = @_;
            my $path = $env->{PATH_INFO} || '/';
            my $out;
            if ($path eq '/ran') {
                # the callback ran in THIS worker, after the fork
                $out = "ran=$RAN pid=$$";
            }
            elsif ($path eq '/hit') {
                my ($ok, $rem, $reset)
                    = Hyperman->ratelimit_hit('shared-key', 3, 60);
                $out = "ok=$ok remaining=$rem pid=$$";
            }
            elsif ($path eq '/deny') {
                Hyperman->deny_add('127.0.0.9', 60);
                $out = 'added=' . Hyperman->deny_check('127.0.0.9');
            }
            elsif ($path eq '/undeny') {
                Hyperman->deny_remove('127.0.0.9');
                $out = 'still=' . Hyperman->deny_check('127.0.0.9');
            }
            else { $out = 'ok' }
            return [ 200, [ 'Content-Type' => 'text/plain',
                            'Content-Length' => length $out ], [$out] ];
        },
        host => '127.0.0.1', port => $port, workers => 2,
    );
    exit 0;
}

sub http_get {
    my ($path) = @_;
    for (1 .. 100) {
        my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                      Proto => 'tcp', Timeout => 2);
        if (!$s) { Time::HiRes::sleep(0.05); next }
        syswrite $s, "GET $path HTTP/1.0\r\nHost: x\r\n\r\n";
        local $/;
        my $body = <$s>;
        close $s;
        return $body if defined $body && length $body;
        Time::HiRes::sleep(0.05);
    }
    return '';
}

# the callback ran in the worker, not in the process that registered it
{
    # Collect first, assert afterwards: asserting inside the loop emitted one
    # test per DISTINCT worker that answered, so the plan moved with however
    # the kernel spread twelve connections. A count that moves cannot be
    # checked by count.
    my %ran;
    for (1 .. 12) {
        my $res = http_get('/ran');
        last unless $res =~ /ran=(\d+) pid=(\d+)/;
        $ran{$2} = $1;
    }
    my @pids = sort keys %ran;
    ok(scalar(@pids) >= 1, 'at least one worker answered');
    is_deeply([ grep { $ran{$_} != 1 } @pids ], [],
        'every worker that answered ran the Perl callback exactly once');
    isnt($pids[0], $$, 'and it is not the process that registered');
    is($RAN, 0, 'which never ran it here: this is a WORKER hook');
}

# The counter is ONE counter, however many workers answer: four hits against a
# limit of three, and the fourth is refused wherever it lands. A count kept per
# worker would let workers x 3 through, which is the whole reason the arena is
# mapped before the fork rather than being a hash in each child.
#
# The connections are opened together before any of them is written, so the
# accept race has something to spread; sequential HTTP/1.0 requests tend to be
# taken by whichever worker got back to accept() first, which is usually the
# same one. Note that "exactly three allowed" IS the cross-worker assertion
# whenever the run does spread - and when it does not, it still holds.
{
    my @socks = grep { defined }
        map { IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                    Proto => 'tcp', Timeout => 2) } 1 .. 4;
    is(scalar @socks, 4, 'four connections open at once');
    syswrite $_, "GET /hit HTTP/1.0\r\nHost: x\r\n\r\n" for @socks;

    my @seen;
    for my $s (@socks) {
        local $/;
        my $body = <$s>;
        close $s;
        push @seen, [$1, $2, $3]
            if defined $body && $body =~ /ok=(\d+) remaining=(-?\d+) pid=(\d+)/;
    }
    is(scalar @seen, 4, 'four requests counted');

    my $allowed = grep { $_->[0] } @seen;
    is($allowed, 3, 'exactly three of the four were allowed');

    my @rem = sort { $b <=> $a } map { $_->[1] } @seen;
    is_deeply(\@rem, [2, 1, 0, 0], 'and remaining counted down once per hit');

    my %workers = map { $_->[2] => 1 } @seen;
    note "answered by " . scalar(keys %workers) . " worker(s)"
       . (keys %workers > 1 ? " - the counter was shared ACROSS them"
                            : " - one worker took all four, so this run"
                            . " asserts persistence rather than sharing");
}

# a denylist entry written by one request is visible to the next, whichever
# worker serves it
{
    like(http_get('/deny'), qr/added=1/, 'deny_add from inside a request took');
    like(http_get('/deny'), qr/added=1/, 'and is still there for the next one');
    like(http_get('/undeny'), qr/still=0/, 'deny_remove takes it away again');
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing();
