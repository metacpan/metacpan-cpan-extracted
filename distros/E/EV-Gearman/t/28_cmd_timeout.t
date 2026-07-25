# command_timeout is per-request: the request at the head of the queue
# must be answered within its budget, independent of unrelated traffic.
# No gearmand needed — fake servers drive the two failure directions:
#  (i)  a large reply dribbled in continuously must NOT be killed while
#       its total time is within budget;
#  (ii) a genuinely stuck head request must time out on schedule even
#       while unrelated packets (NOOPs) keep arriving — pre-fix the
#       reset-on-any-packet timer was postponed indefinitely.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

sub make_server {
    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
    ) or plan skip_all => "cannot bind a listener: $!";
    $srv->blocking(0);
    return $srv;
}

# ===== (i) dribbled reply within budget survives =====
{
    my $srv = make_server();
    my $port = $srv->sockport;
    my @keep;

    my $payload = 'd' x (40 * 1024);
    my $accept = EV::io fileno($srv), EV::READ, sub {
        while (my $c = $srv->accept) {
            $c->blocking(0);
            my $st = { sock => $c, buf => '', reply => undef, sent => 0 };
            push @keep, $st;
            my $rw; $rw = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);
                if (!$n) { undef $rw; return }
                $st->{buf} .= $chunk;
                return if $st->{reply} || length($st->{buf}) < 12;
                my $blen = unpack('N', substr($st->{buf}, 8, 4));
                return if length($st->{buf}) < 12 + $blen;
                $st->{reply} = "\0RES" . pack('NN', 17, $blen)
                             . substr($st->{buf}, 12, $blen);
                # dribble the reply out 2 KiB at a time, continuously
                $st->{tw} = EV::timer 0.04, 0.04, sub {
                    return if $st->{sent} >= length $st->{reply};
                    my $wn = syswrite($c, substr($st->{reply}, $st->{sent}, 2048));
                    $st->{sent} += $wn if $wn;
                };
            };
            push @keep, $rw;
        }
    };
    push @keep, $accept;

    my @errs;
    my ($got, $gerr);
    my $g;
    $g = EV::Gearman->new(
        host => '127.0.0.1', port => $port,
        command_timeout => 3000,     # dribble takes ~0.8s — well within budget
        on_connect => sub {
            $g->echo($payload, sub { ($got, $gerr) = @_; EV::break });
        },
        on_error => sub { push @errs, $_[0] },
    );
    my $guard = EV::timer 8, 0, sub { fail 'dribble echo timeout'; EV::break };
    EV::run;

    is $gerr, undef, 'dribbled reply: no error';
    is $got, $payload, 'dribbled reply delivered in full';
    ok $g->is_connected, 'connection not killed by a slow continuous reply';
    is scalar(grep { $_ eq 'command timeout' } @errs), 0,
        'no command timeout fired';
}

# ===== (ii) stuck head times out on schedule despite NOOP traffic =====
{
    my $srv = make_server();
    my $port = $srv->sockport;
    my @keep;

    my $noop = "\0RES" . pack('NN', 6, 0);
    my $accept = EV::io fileno($srv), EV::READ, sub {
        while (my $c = $srv->accept) {
            $c->blocking(0);
            my $st = { sock => $c };
            push @keep, $st;
            # never answer anything; stream unrelated NOOPs forever
            $st->{noop_tw} = EV::timer 0.05, 0.05, sub {
                my $wn = syswrite($c, $noop);
                if (!$wn && $!{EBADF}) { undef $st->{noop_tw} }
            };
            my $rw; $rw = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);   # drain, never reply
                if (!$n) { undef $rw; undef $st->{noop_tw}; }
            };
            push @keep, $rw;
        }
    };
    push @keep, $accept;

    my @errs;
    my ($cb_err, $cb_fired);
    my $t0;
    my $elapsed;
    my $g;
    $g = EV::Gearman->new(
        host => '127.0.0.1', port => $port,
        command_timeout => 400,      # ms
        on_connect => sub {
            $t0 = EV::now();
            $g->echo('ping', sub { $cb_fired = 1; $cb_err = $_[1] });
        },
        on_error => sub {
            push @errs, $_[0];
            if ($_[0] eq 'command timeout') { $elapsed = EV::now() - $t0; EV::break }
        },
    );
    my $guard = EV::timer 4, 0, sub {
        diag 'command timeout never fired while NOOPs streamed';
        EV::break;
    };
    EV::run;

    ok defined $elapsed, 'stuck request timed out while NOOPs kept arriving';
    cmp_ok($elapsed || 99, '<', 1.5,
        'timeout fired on schedule despite unrelated NOOP traffic'
        . (defined $elapsed ? sprintf(' (%.2fs)', $elapsed) : ''));
    cmp_ok($elapsed || 0, '>=', 0.3, 'timeout not absurdly early');
    ok $cb_fired, 'stuck request callback was invoked';
    is $cb_err, 'disconnected', 'stuck request drained with "disconnected"';
    ok !$g->is_connected, 'connection torn down after command timeout';
}

done_testing;
