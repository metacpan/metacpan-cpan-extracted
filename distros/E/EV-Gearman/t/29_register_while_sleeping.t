# Registering a new ability WHILE ASLEEP (after NO_JOB -> PRE_SLEEP)
# must wake the worker to poll for already-queued jobs. gearmand only
# NOOPs a sleeping worker on a *fresh* submission — a CAN_DO for an
# ability that already has jobs queued gets no wakeup, stranding the
# backlog until the next submit or reconnect (confirmed against
# gearmand 1.1.x with a raw-socket probe).
#
# Hermetic: fake server, no gearmand. The test asserts the CLIENT's
# behaviour (GRAB_JOB right after the mid-sleep CAN_DO), so it does
# not depend on gearmand's NOOP policy. Pre-fix nothing follows the
# mid-sleep CAN_DO and the server-side read stalls; post-fix a GRAB
# arrives immediately.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

# ---- minimal fake gearmand (same as t/24) -----------------------------
package FakeGm {
    use IO::Socket::INET;
    use EV;

    sub new {
        my ($class, %opt) = @_;
        my $srv = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1', LocalPort => 0,
            Listen => 5, ReuseAddr => 1,
        ) or die "cannot bind listener: $!";
        $srv->blocking(0);
        my $self = bless {
            srv       => $srv,
            conns     => [],
            on_packet => $opt{on_packet} || sub {},
            on_conn   => $opt{on_conn}   || sub {},
        }, $class;
        $self->{accept_w} = EV::io(fileno($srv), EV::READ,
                                   sub { $self->_accept });
        return $self;
    }

    sub port { shift->{srv}->sockport }

    sub _accept {
        my ($self) = @_;
        while (my $c = $self->{srv}->accept) {
            $c->blocking(0);
            my $conn = { sock => $c, rbuf => '', wbuf => '', step => 0 };
            $conn->{rw} = EV::io(fileno($c), EV::READ,
                                 sub { $self->_read($conn) });
            push @{ $self->{conns} }, $conn;
            $self->{on_conn}->($conn);
        }
    }

    sub _close {
        my ($self, $conn) = @_;
        return if $conn->{closed};
        $conn->{closed} = 1;
        close $conn->{sock};
        $conn->{rw} = undef;
    }

    sub _read {
        my ($self, $conn) = @_;
        my $n = sysread($conn->{sock}, my $buf, 65536);
        if (!defined $n) { return if $!{EAGAIN} || $!{EWOULDBLOCK}; $self->_close($conn); return; }
        if ($n == 0)     { $self->_close($conn); return; }
        $conn->{rbuf} .= $buf;
        while (length($conn->{rbuf}) >= 12) {
            my (undef, $cmd, $len) = unpack "a4 N N", substr($conn->{rbuf}, 0, 12);
            last if length($conn->{rbuf}) < 12 + $len;
            my $body = substr($conn->{rbuf}, 12, $len);
            substr($conn->{rbuf}, 0, 12 + $len) = '';
            $self->{on_packet}->($conn, $cmd, $body);
            return if $conn->{closed};
        }
    }

    sub send {
        my ($self, $conn, $cmd, $data) = @_;
        $data //= '';
        $conn->{wbuf} .= "\0RES" . pack("N N", $cmd, length $data) . $data;
        while (length $conn->{wbuf}) {
            my $n = syswrite($conn->{sock}, $conn->{wbuf});
            last if !defined $n;
            substr($conn->{wbuf}, 0, $n) = '';
        }
    }
}

package main;

use constant {
    CAN_DO => 1, PRE_SLEEP => 4, NOOP => 6, GRAB_JOB => 9,
    NO_JOB => 10, JOB_ASSIGN => 11, WORK_COMPLETE => 13,
};

# Drive one scripted connection. $steps is a list of
# [expected_cmd, expected_body (or undef), reply(s)...]; the loop
# breaks when the final step is consumed.
sub run_scripted {
    my (%opt) = @_;
    my $steps     = $opt{steps};
    my @errs;
    my $srv;
    $srv = FakeGm->new(on_packet => sub {
        my ($conn, $cmd, $body) = @_;
        my $st = $steps->[ $conn->{step} ];
        if (!$st) { push @errs, "extra packet cmd=$cmd"; return; }
        push @errs, "step $conn->{step}: expected cmd $st->[0], got $cmd"
            if $cmd != $st->[0];
        push @errs, "step $conn->{step}: body mismatch (cmd $cmd): " .
                    "expected '$st->[1]', got '$body'"
            if defined $st->[1] && $body ne $st->[1];
        $conn->{step}++;
        for my $reply (@$st[2 .. $#$st]) {
            next unless $reply;
            $srv->send($conn, @$reply);
        }
        EV::break if $conn->{step} == @$steps;
    });
    my $w = EV::Gearman->new(
        host => '127.0.0.1', port => $srv->port,
        on_error => sub { push @errs, "on_error: $_[0]" },
    );
    $opt{client}->($w);
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    my $done = $srv->{conns}[0] && $srv->{conns}[0]{step} == @$steps;
    return (\@errs, $done);
}

my $fF = "rwsF_$$";
my $fG = "rwsG_$$";

# T-B5-1a: register_function() while asleep. work()'s on_idle callback
# fires right after NO_JOB -> PRE_SLEEP, so registering funcF there is
# a deterministic mid-sleep registration (no timers).
{
    my $got_workload;
    my ($errs, $done) = run_scripted(
        steps => [
            [CAN_DO,        $fG,            undef],
            [GRAB_JOB,      undef,          [NO_JOB, '']],
            [PRE_SLEEP,     undef,          undef],
            # on_idle fires here, client-side; it registers $fF.
            [CAN_DO,        $fF,            undef],
            # THE FIX: the wake-up poll. Pre-fix this GRAB never comes.
            [GRAB_JOB,      undef,          [JOB_ASSIGN, "H:1\0$fF\0payload-F"]],
            [WORK_COMPLETE, "H:1\0done-F",  undef],
            # sync dispatch grabs again; answer NO_JOB and let the
            # worker settle back to sleep for a deterministic end.
            [GRAB_JOB,      undef,          [NO_JOB, '']],
            [PRE_SLEEP,     undef,          undef],
        ],
        client => sub {
            my ($w) = @_;
            $w->register_function($fG => sub { return 'g-ok' });
            my $idle_once = 0;
            $w->work(sub {
                return if $idle_once++;
                $w->register_function($fF => sub {
                    my ($job) = @_;
                    $got_workload = $job->workload;
                    return 'done-F';
                });
            });
        },
    );

    is_deeply $errs, [], 'T-B5-1a: server saw the expected packet sequence';
    ok $done, 'T-B5-1a: GRAB_JOB followed the mid-sleep CAN_DO (no stall)';
    is $got_workload, 'payload-F',
        'T-B5-1a: funcF handler fired with the queued workload';
}

# T-B5-1b: can_do() entry point emits the same wake-up GRAB. Here the
# backlog is empty, so the poll gets NO_JOB and the worker goes straight
# back to sleep — a spurious poll is harmless.
{
    my ($errs, $done) = run_scripted(
        steps => [
            [CAN_DO,        "${fG}b",       undef],
            [GRAB_JOB,      undef,          [NO_JOB, '']],
            [PRE_SLEEP,     undef,          undef],
            [CAN_DO,        "${fF}b",       undef],
            # THE FIX: same wake via the can_do() entry point.
            [GRAB_JOB,      undef,          [NO_JOB, '']],
            [PRE_SLEEP,     undef,          undef],
        ],
        client => sub {
            my ($w) = @_;
            $w->register_function("${fG}b" => sub { return 'g-ok' });
            my $idle_once = 0;
            $w->work(sub {
                return if $idle_once++;
                $w->can_do("${fF}b");
            });
        },
    );

    is_deeply $errs, [], 'T-B5-1b: server saw the expected packet sequence';
    ok $done, 'T-B5-1b: can_do() while asleep also polled, then re-slept';
}

done_testing;
