# Response/request pairing: a reply whose command cannot answer the
# head request must tear the connection down with a "protocol desync"
# error — never deliver forged data, never silently drop a callback,
# never wedge the worker. Fake server throughout; no gearmand needed.
#
# T-D2-5 and T-D2-6 are tolerance locks: they pass before AND after the
# fix (they pin behavior the fix must not change). Every other test
# here fails pre-fix.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

# ---- minimal fake gearmand -------------------------------------------
# Speaks the binary protocol, scriptable per connection. Packets from
# the client are dispatched to on_packet($conn, $cmd, $body); replies
# are queued with $srv->send($conn, $cmd, $data).
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

# Protocol command numbers used by the scripts.
use constant {
    CAN_DO => 1, PRE_SLEEP => 4, NOOP => 6, SUBMIT_JOB => 7,
    JOB_CREATED => 8, GRAB_JOB => 9, NO_JOB => 10, JOB_ASSIGN => 11,
    WORK_COMPLETE => 13, ECHO_REQ => 16, ECHO_RES => 17, ERROR => 19,
};

my $func = "desync_$$";

# T-D2-1: server answers SUBMIT_JOB with ECHO_RES — forged result must
# NOT reach the submit callback; connection dies with a desync error.
{
    my $srv;
    $srv = FakeGm->new(on_packet => sub {
        my ($conn, $cmd, $body) = @_;
        if ($cmd == SUBMIT_JOB) { $srv->send($conn, ECHO_RES, "forged-result") }
    });
    my ($err, $cb_called, $res, $cb_err);
    my $g = EV::Gearman->new(
        host => '127.0.0.1', port => $srv->port,
        on_error => sub { $err //= $_[0]; EV::break },
    );
    $g->on_connect(sub {
        $g->submit_job($func, "wl", sub { $cb_called++; ($res, $cb_err) = @_ });
    });
    my $guard = EV::timer 4, 0, sub { EV::break };
    EV::run;

    like $err, qr/protocol desync/, 'T-D2-1: desync reported on_error';
    ok $cb_called, 'T-D2-1: submit callback was invoked (with error)';
    ok !defined($res) || $res ne 'forged-result',
        'T-D2-1: forged payload never delivered as a result';
    is $cb_err, 'disconnected', 'T-D2-1: submit callback got "disconnected"';
    ok !$g->is_connected, 'T-D2-1: connection torn down';
}

# T-D2-2: server answers ECHO_REQ with JOB_CREATED — must not silently
# drop the echo callback into a permanent hang.
{
    my $srv;
    $srv = FakeGm->new(on_packet => sub {
        my ($conn, $cmd, $body) = @_;
        if ($cmd == ECHO_REQ) { $srv->send($conn, JOB_CREATED, "H:x:1") }
    });
    my ($err, $cb_called, $cb_err);
    my $g = EV::Gearman->new(
        host => '127.0.0.1', port => $srv->port,
        on_error => sub { $err //= $_[0]; EV::break },
    );
    $g->on_connect(sub {
        $g->echo("ping", sub { $cb_called++; $cb_err = $_[1] });
    });
    my $guard = EV::timer 2, 0, sub { EV::break };
    EV::run;

    like $err, qr/protocol desync/, 'T-D2-2: desync reported on_error';
    ok $cb_called, 'T-D2-2: echo callback fired instead of hanging';
    is $cb_err, 'disconnected', 'T-D2-2: echo callback got "disconnected"';
}

# T-D2-3: server answers GRAB_JOB with ECHO_RES — pre-fix this pops the
# grab request and strands worker_grab_inflight: the worker wedges
# permanently. Post-fix: desync disconnect, then (reconnect => 1) the
# worker comes back and takes a real job.
{
    my $conns_seen = 0;
    my $srv;
    $srv = FakeGm->new(
        on_conn => sub { $conns_seen++ },
        on_packet => sub {
            my ($conn, $cmd, $body) = @_;
            my $first_conn = $conns_seen == 1;
            if ($cmd == CAN_DO) { return }
            if ($cmd == GRAB_JOB) {
                if ($first_conn) {
                    $srv->send($conn, ECHO_RES, "bogus");   # the wedge
                } else {
                    $srv->send($conn, JOB_ASSIGN, "H:1\0$func\0payload");
                }
            }
        },
    );
    my ($err, $dispatched);
    my $w = EV::Gearman->new(
        host => '127.0.0.1', port => $srv->port,
        reconnect => 1, reconnect_delay => 50,
        on_error => sub { $err //= $_[0] },
    );
    $w->register_function($func => sub {
        $dispatched = $_[0]->workload;
        EV::break;
        return 'ok';
    });
    $w->work;
    my $guard = EV::timer 4, 0, sub { EV::break };
    EV::run;

    like $err, qr/protocol desync/, 'T-D2-3: desync reported on_error';
    is $dispatched, 'payload', 'T-D2-3: worker recovered and dispatched a job';
    cmp_ok $conns_seen, '>=', 2, 'T-D2-3: worker reconnected after desync';
}

# T-D2-4: the non-hostile wedge. Async worker calls complete() twice;
# the second earns an ERROR JOB_NOT_FOUND, which arrives while the head
# request is the in-flight GRAB_JOB. Pre-fix the ERROR arm pops the
# grab request, the inflight flag sticks, and the worker never grabs
# again. Post-fix the ERROR surfaces at connection level and the worker
# keeps going.
{
    my @steps = (
        # [expected cmd, reply-to-send (or undef)]
        [CAN_DO,         undef],
        [GRAB_JOB,       [JOB_ASSIGN, "H:9\0$func\0wl-one"]],
        [GRAB_JOB,       undef],                       # async grabs next
        [WORK_COMPLETE,  undef],                       # first complete()
        [WORK_COMPLETE,  [ERROR, "JOB_NOT_FOUND\0no such job"],
                         [NO_JOB, '']],                # answer grab #2 after the ERROR
        [PRE_SLEEP,      [NOOP, '']],                  # worker sleeps, wake it
        [GRAB_JOB,       [JOB_ASSIGN, "H:10\0$func\0wl-two"]],
        [GRAB_JOB,       undef],                       # async grabs next immediately
        [WORK_COMPLETE,  undef],                       # job two completed (0.05s timer)
    );
    my (@script_errs, $final_wc);
    my $srv;
    $srv = FakeGm->new(on_packet => sub {
        my ($conn, $cmd, $body) = @_;
        my $st = $steps[ $conn->{step} ];
        if (!$st) { push @script_errs, "extra packet cmd=$cmd"; return; }
        push @script_errs, "step $conn->{step}: expected cmd $st->[0], got $cmd"
            if $cmd != $st->[0];
        $conn->{step}++;
        $final_wc = 1 if $conn->{step} == @steps && $cmd == WORK_COMPLETE;
        for my $reply (@$st[1 .. $#$st]) {
            next unless $reply;
            $srv->send($conn, @$reply);
        }
    });
    my ($err, @seen_wl);
    my $w = EV::Gearman->new(
        host => '127.0.0.1', port => $srv->port,
        on_error => sub { $err //= $_[0] },
    );
    my $job1;
    $w->register_function($func => { async => 1 }, sub {
        my ($job) = @_;
        push @seen_wl, $job->workload;
        if ($job->workload eq 'wl-one') {
            $job1 = $job;
            my $t; $t = EV::timer 0.1, 0, sub {
                $job1->complete('r1');
                $job1->complete('r1');   # double complete -> JOB_NOT_FOUND
                undef $t;
            };
        } else {
            my $j2 = $job;
            my $t; $t = EV::timer 0.05, 0, sub { $j2->complete('r2'); undef $t };
        }
    });
    $w->work;
    my $guard = EV::timer 6, 0, sub { EV::break };
    my $watcher = EV::timer 0, 0.05, sub { EV::break if $final_wc };
    EV::run;

    is_deeply \@script_errs, [], 'T-D2-4: server script saw the expected packet sequence';
    like $err, qr/JOB_NOT_FOUND/, 'T-D2-4: JOB_NOT_FOUND surfaced at connection level';
    is_deeply \@seen_wl, ['wl-one', 'wl-two'],
        'T-D2-4: worker kept grabbing after the ERROR (no wedge)';
}

# T-D2-5: ERROR that genuinely answers the head request still fails it
# fast. (Tolerance lock: passes before and after the fix.)
{
    my $srv;
    $srv = FakeGm->new(on_packet => sub {
        my ($conn, $cmd, $body) = @_;
        if ($cmd == ECHO_REQ) { $srv->send($conn, ERROR, "BAD\0boom") }
    });
    my ($cb_err, $cb_called);
    my $g = EV::Gearman->new(
        host => '127.0.0.1', port => $srv->port,
        on_error => sub { },
    );
    $g->on_connect(sub {
        $g->echo("x", sub { $cb_called++; $cb_err = $_[1]; EV::break });
    });
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    ok $cb_called, 'T-D2-5: head request callback fired on ERROR';
    is $cb_err, 'BAD: boom', 'T-D2-5: head request failed fast with server error';
    ok $g->is_connected, 'T-D2-5: connection survives an answered ERROR';
}

# T-D2-6: unsolicited ERROR with an empty queue is a connection-level
# event, not a teardown. (Tolerance lock: passes before and after.)
{
    my $srv;
    $srv = FakeGm->new(on_conn => sub {
        my ($conn) = @_;
        my $t; $t = EV::timer 0.2, 0, sub {
            $srv->send($conn, ERROR, "SOME\0unsolicited");
            undef $t;
        };
    });
    my $err;
    my $g = EV::Gearman->new(
        host => '127.0.0.1', port => $srv->port,
        on_error => sub { $err //= $_[0]; EV::break },
    );
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    is $err, 'SOME: unsolicited', 'T-D2-6: unsolicited ERROR reported at connection level';
    ok $g->is_connected, 'T-D2-6: connection survives unsolicited ERROR';
}

# T-D2-7: FIFO sanity. Two echoes get their own replies; an extra
# unsolicited ECHO_RES with an empty queue is ignored; a later ECHO_RES
# arriving while a SUBMIT sits at the head is a desync.
{
    my $echo_n = 0;
    my $srv;
    $srv = FakeGm->new(on_packet => sub {
        my ($conn, $cmd, $body) = @_;
        if ($cmd == ECHO_REQ) {
            $echo_n++;
            if ($echo_n == 1) { $srv->send($conn, ECHO_RES, "ra") }
            else {
                $srv->send($conn, ECHO_RES, "rb1");
                $srv->send($conn, ECHO_RES, "rb2");   # extra, must be ignored
            }
        } elsif ($cmd == SUBMIT_JOB) {
            $srv->send($conn, ECHO_RES, "forged");
        }
    });
    my ($err, $ra, $rb, $sub_res, $sub_err);
    my $g = EV::Gearman->new(
        host => '127.0.0.1', port => $srv->port,
        on_error => sub { $err //= $_[0]; EV::break },
    );
    $g->on_connect(sub {
        $g->echo("a", sub { $ra = $_[0] });
        $g->echo("b", sub {
            $rb = $_[0];
            $g->submit_job($func, "wl", sub { ($sub_res, $sub_err) = @_ });
        });
    });
    my $guard = EV::timer 4, 0, sub { EV::break };
    EV::run;

    is $ra, 'ra', 'T-D2-7: first echo paired correctly';
    is $rb, 'rb1', 'T-D2-7: second echo paired correctly (extra reply ignored)';
    like $err, qr/protocol desync/, 'T-D2-7: later mismatch still detected';
    ok !defined($sub_res) || $sub_res ne 'forged',
        'T-D2-7: forged payload never delivered as a result';
    is $sub_err, 'disconnected', 'T-D2-7: submit callback got "disconnected"';
}

done_testing;
