#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman ();

# The request ceiling: headers plus body, buffered per connection before the
# app is called. Until 0.25 it was a 16MB literal with nothing reaching it
# from Perl - both un-raisable for a large upload and un-lowerable for a
# server that wants a tighter bound.
#
# This is the ONLY thing between a worker and an unbounded POST, since the
# body is fully resident before any app sees it. It is memory protection,
# not policy; a framework-level limit sits on top and cannot replace it.
#
# TEST METHOD, and the reason for it: an over-limit request must never be
# driven by writing the whole body from a single-threaded client. The server
# stops reading as soon as it decides to refuse, the client's send buffer
# fills, and the client blocks in write() before it ever reads the response -
# a deadlock in the TEST, not the server. So the large cases DECLARE a
# Content-Length and send a trickle: the ceiling check on a fixed-length
# request reads the header, so the answer arrives without the bytes.

# ---- the option is validated at run() --------------------------------------

# 0 must be refused rather than read as "unlimited": an unbounded read
# ceiling is a memory-exhaustion switch and must not be reachable by a
# config typo that happens to produce a falsy value.
{
    eval { Hyperman->run(app => sub { }, max_body => 0, port => 1) };
    my $err = $@ || '';
    like $err, qr/max_body must be a byte count/,
        'max_body => 0 croaks instead of meaning unlimited';
    like $err, qr/memory.exhaustion/i, '...and says why';
}

# ---- a server, a request, an answer ----------------------------------------

# Runs one request against a throwaway server. `declare` sends that
# Content-Length while writing only a few bytes (no deadlock possible);
# `body` writes a real body, and is only used for sizes that comfortably fit
# in a socket buffer. Returns the status, or 'accepted' when the server is
# still waiting for the rest of a body it was willing to take.
sub probe {
    my (%o) = @_;
    my ($port) = free_ports(1);
    return 'no-port' unless $port;
    my $kid = fork;
    die "fork: $!" unless defined $kid;
    if ($kid == 0) {
        open STDERR, '>', '/dev/null';
        require Hyperman;
        Hyperman->run(
            app => sub {
                my $env = shift;
                my $b = '';
                $env->{'psgi.input'}->read($b, $env->{CONTENT_LENGTH} || 0)
                    if $env->{'psgi.input'} && $env->{CONTENT_LENGTH};
                [ 200, ['Content-Type','text/plain'], [ 'got ' . length $b ] ];
            },
            (defined $o{max} ? (max_body => $o{max}) : ()),
            host => '127.0.0.1', port => $port, workers => 1,
        );
        exit 0;
    }

    my $status = 'no-conn';
    for (1 .. 40) {
        my $s = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp')
            or (Time::HiRes::sleep(0.1), next);
        binmode $s;
        $s->autoflush(1);
        my $body = defined $o{body} ? ('x' x $o{body}) : 'xxx';
        my $len  = defined $o{declare} ? $o{declare} : length $body;
        my $req  = $o{chunked}
            ? "POST / HTTP/1.1\r\nHost: x\r\nTransfer-Encoding: chunked\r\n"
              . "Connection: close\r\n\r\n"
              . sprintf("%x\r\n", length $body) . $body . "\r\n0\r\n\r\n"
            : "POST / HTTP/1.0\r\nHost: x\r\nContent-Length: $len\r\n\r\n$body";
        my $r = eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 5;
            $s->print($req);
            local $/;
            my $all = <$s>;
            alarm 0;
            $all;
        };
        alarm 0;
        $status = !defined $r        ? 'accepted'      # still awaiting body
                : $r =~ m{\AHTTP/1\.[01] (\d+)} ? $1
                : 'closed';
        last;
    }
    kill 'TERM', $kid;
    waitpid $kid, 0;
    return $status;
}

# ---- a lowered ceiling -----------------------------------------------------

is probe(max => 4096, body => 16),   200, 'a small body is served';
is probe(max => 4096, body => 3584), 200, 'a body under the ceiling is served';
is probe(max => 4096, body => 8192), 413,
   'a body over max_body is refused with 413 Payload Too Large';

# The buffer growth guard is the other enforcement site: a request larger
# than the initial 16KB read buffer used to be closed with NO response at
# all, which only ever happened to enormous requests while the ceiling was a
# hardcoded 16MB. Now that an operator can set it below 16KB it is the
# ordinary path, and a bare close would leave every such client on a
# timeout instead of a 413.
is probe(max => 4096, body => 32768), 413,
   'a body past the read buffer is answered, not silently dropped';

is probe(max => 4096, declare => 20 * 1024 * 1024), 413,
   'a declared length over the ceiling is refused without sending it';

# ---- chunked bodies have their own check -----------------------------------

is probe(max => 4096, body => 16, chunked => 1), 200,
   'a small chunked body is served';
is probe(max => 4096, body => 8192, chunked => 1), 413,
   'a chunked body over the ceiling is refused';

# ---- the default is unchanged ----------------------------------------------

# An existing deployment must not change behaviour because a knob now exists.
is probe(declare => 1024 * 1024), 'accepted',
   'with max_body unset a 1MB body is still accepted';
is probe(declare => 20 * 1024 * 1024), 413,
   '...and the default ceiling is still 16MB';

# ---- and it can now be raised past 16MB ------------------------------------

# The point of the knob: the old literal made a 20MB upload impossible at
# any configuration.
is probe(max => 64 * 1024 * 1024, declare => 20 * 1024 * 1024), 'accepted',
   'max_body can be raised above the old 16MB cap';
is probe(max => 64 * 1024 * 1024, declare => 70 * 1024 * 1024), 413,
   '...and the raised ceiling is itself enforced';

done_testing;
