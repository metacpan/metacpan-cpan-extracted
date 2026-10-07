use strict;
use warnings;

use Test::More;
use IO::Socket::INET;

use EV;
use EV::Redis;

# a command every 50 ms while it has a context; returns the first command error and its time
sub steady_traffic {
    my ($r, $limit, @cmd) = @_;
    @cmd = ('GET', 'k') unless @cmd;
    my ($err, $at, $done);
    EV::now_update;
    my $t0   = EV::time;
    my $tick = EV::timer 0.05, 0.05, sub {
        return unless $r->is_connected;
        $r->command(@cmd, sub {
            return if $done || defined $err || !defined $_[1];
            ($err, $at) = ($_[1], EV::time - $t0);
            EV::break;
        });
    };
    my $guard = EV::timer $limit, 0, sub { EV::break };
    EV::run;
    $done = 1;
    return ($err, $at);
}

# a server that accepts and never answers
{
    my $l = IO::Socket::INET->new(
        Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
    ) or die "listen: $!";
    my @held;
    my $accept = EV::io $l, EV::READ, sub { push @held, scalar $l->accept };

    my $r = EV::Redis->new(on_error => sub {}, command_timeout => 300);
    $r->connect('127.0.0.1', $l->sockport);
    my ($err, $at) = steady_traffic($r, 3);

    is $err, 'Timeout', 'silent server: commands time out despite steady traffic';
    cmp_ok $at // 99, '<', 1.5, 'silent server: within about command_timeout';
    $r->disconnect if $r->is_connected;

    # once subscribed, hiredis keeps command replies in a separate list
    my $s = EV::Redis->new(on_error => sub {}, command_timeout => 300);
    $s->connect('127.0.0.1', $l->sockport);
    $s->command('SUBSCRIBE', 'tt_ch', sub {});
    ($err, $at) = steady_traffic($s, 3, 'PING');
    is $err, 'Timeout', 'silent server, subscribed: commands time out';
    cmp_ok $at // 99, '<', 1.5, 'silent server, subscribed: within about command_timeout';
    $s->disconnect if $s->is_connected;

    # SUBSCRIBE-type commands keep no reply record of their own
    my $p = EV::Redis->new(on_error => sub {}, command_timeout => 300);
    $p->connect('127.0.0.1', $l->sockport);
    my ($perr, $pat);
    my $t0 = EV::time;
    $p->command('PING', sub { ($perr, $pat) = ($_[1], EV::time - $t0); EV::break });
    my $n = 0;
    my $tick = EV::timer 0.05, 0.05, sub {
        $p->command('SUBSCRIBE', 'tt_ch' . $n++, sub {}) if $p->is_connected;
    };
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is $perr, 'Timeout', 'silent server, SUBSCRIBE traffic: pending PING times out';
    cmp_ok $pat // 99, '<', 1.5, 'silent server, SUBSCRIBE traffic: within about command_timeout';
    $p->disconnect if $p->is_connected;
    undef $_ for $tick, $guard;

    # a command sent from a slow reply callback still gets its full timeout
    {
        my $answering = IO::Socket::INET->new(
            Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
        ) or die "listen: $!";
        my ($peer, $pw);
        my $acc2 = EV::io $answering, EV::READ, sub {
            $peer = $answering->accept or return;
            my $n = 0;
            $pw = EV::io $peer, EV::READ, sub {
                # at EOF the peer stays readable: stop, or the loop spins
                sysread $peer, my $buf, 4096 or return $_[0]->stop;
                syswrite $peer, "+PONG\r\n" unless $n++;
            };
        };
        my $q = EV::Redis->new(on_error => sub {}, command_timeout => 500);
        $q->connect('127.0.0.1', $answering->sockport);
        my ($t0, $gerr, $gat);
        # made up front: an allocation in the callback would take the freed reply record
        my $on_get = sub { ($gerr, $gat) = ($_[1], EV::time - $t0); EV::break };
        $q->command('PING', sub {
            select undef, undef, undef, 0.3;
            $t0 = EV::time;
            $q->command('GET', 'k', $on_get);
        });
        my $qguard = EV::timer 3, 0, sub { EV::break };
        EV::run;
        is $gerr, 'Timeout', 'command after a slow callback: times out';
        cmp_ok $gat // 0, '>', 0.4, 'command after a slow callback: not before command_timeout';
        $q->disconnect if $q->is_connected;
    }

    # pipelined GET a, GET b: +A arrives, the server never answers b
    my $pipelined = sub {
        my ($after_a) = @_;
        my ($peer, $pw);
        my $srv = IO::Socket::INET->new(
            Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
        ) or die "listen: $!";
        my $acc3 = EV::io $srv, EV::READ, sub {
            $peer = $srv->accept or return;
            $pw = EV::io $peer, EV::READ, sub { sysread $peer, my $buf, 4096 or $_[0]->stop };
        };
        my ($ta, $berr, $bat, $up);
        my $q = EV::Redis->new(command_timeout => 2000, on_error => sub {});
        $q->on_connect(sub {
            $up = 1;
            $q->command('GET', 'a', sub { $ta = EV::time });
            $q->command('GET', 'b', sub { ($berr, $bat) = ($_[1], EV::time); EV::break });
        });
        $q->connect('127.0.0.1', $srv->sockport);
        {
            my $end = EV::time + 3;
            my $tick = EV::timer 0.01, 0.01, sub { EV::break if ($up && $peer) || EV::time >= $end };
            EV::run until ($up && $peer) || EV::time >= $end;
        }
        my @w = $after_a->($q, sub { syswrite $peer, "+A\r\n" });
        my $qguard = EV::timer 8, 0, sub { EV::break };
        EV::run;
        $q->disconnect if $q->is_connected;
        return ($berr, defined $ta && defined $bat ? $bat - $ta : undef);
    };

    # another watcher blocks the loop just before +A is read; it must end well
    # before the first deadline, or the expired timer runs ahead of the read
    my ($berr, $bgap) = $pipelined->(sub {
        my ($q, $send_a) = @_;
        my $slow;
        return EV::timer 0.1, 0, sub {
            $send_a->();
            $slow = EV::timer 0, 0, sub { select undef, undef, undef, 0.8 };
        };
    });
    is $berr, 'Timeout', 'pipelined, loop blocked before a read: times out';
    cmp_ok $bgap // 0, '>', 1.6, 'pipelined, loop blocked before a read: full timeout after the read';

    # a SUBSCRIBE sent while b waits does not extend its deadline
    ($berr, $bgap) = $pipelined->(sub {
        my ($q, $send_a) = @_;
        return (
            EV::timer(0.1, 0, $send_a),
            EV::timer(1.5, 0, sub { $q->command('SUBSCRIBE', 'tt_ext', sub {}) }),
        );
    });
    is $berr, 'Timeout', 'SUBSCRIBE while a reply waits: times out';
    cmp_ok $bgap // 99, '<', 2.7, 'SUBSCRIBE while a reply waits: deadline not extended';

    # command_timeout set after a pause outside the loop counts from the call
    {
        my ($qerr, $qat, $t1);
        my $q = EV::Redis->new(on_error => sub {}, on_connect => sub { EV::break });
        $q->connect('127.0.0.1', $l->sockport);
        { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
        $q->command('PING', sub { ($qerr, $qat) = ($_[1], EV::time - $t1); EV::break });
        select undef, undef, undef, 0.5;
        $t1 = EV::time;
        $q->command_timeout(300);
        { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
        is $qerr, 'Timeout', 'command_timeout set after a pause: times out';
        cmp_ok $qat // 0, '>', 0.2, 'command_timeout set after a pause: counts from the call';
        $q->disconnect if $q->is_connected;
    }

    # the loop blocks past the deadline with the reply already received
    {
        my ($peer, $pw);
        my $srv = IO::Socket::INET->new(
            Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
        ) or die "listen: $!";
        my $acc4 = EV::io $srv, EV::READ, sub {
            $peer = $srv->accept or return;
            $pw = EV::io $peer, EV::READ, sub {
                sysread $peer, my $buf, 4096 or return $_[0]->stop;
                syswrite $peer, "+PONG\r\n";
                select undef, undef, undef, 0.6;
            };
        };
        my ($res, $err);
        my $q = EV::Redis->new(
            command_timeout => 300,
            on_error        => sub {},
            on_connect      => sub { EV::break },
        );
        $q->connect('127.0.0.1', $srv->sockport);
        { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
        $q->ping(sub { ($res, $err) = @_; EV::break });
        { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
        is $res, 'PONG', 'loop blocked past command_timeout: the waiting reply wins';
        $q->disconnect if $q->is_connected;
    }

    # the loop blocks past connect_timeout while the connect completes
    {
        my ($up, $cerr);
        my $q = EV::Redis->new(
            connect_timeout => 300,
            on_connect      => sub { $up = 1; EV::break },
            on_error        => sub { $cerr = $_[0]; EV::break },
        );
        $q->connect('127.0.0.1', $l->sockport);
        select undef, undef, undef, 0.6;
        { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
        ok $up, 'loop blocked past connect_timeout: the finished connect wins'
            or diag $cerr;
        $q->disconnect if $q->is_connected;
    }

    # priority() from a watcher that runs just before the expired timeout
    {
        my ($err, $at, $t0, $tw, $q);
        $q = EV::Redis->new(
            command_timeout => 300, priority => -1,
            on_error   => sub {},
            on_connect => sub {
                $t0 = EV::time;
                $q->get('k', sub { ($err, $at) = ($_[1], EV::time - $t0); EV::break });
                # same deadline, higher priority: runs first in that iteration
                $tw = EV::timer 0.3, 0, sub { $q->priority(0) };
            },
        );
        $q->connect('127.0.0.1', $l->sockport);
        my $g = EV::timer 3, 0, sub { EV::break };
        EV::run;
        is $err, 'Timeout', 'priority() as the timeout expires: times out';
        cmp_ok $at // 99, '<', 0.5, 'priority() as the timeout expires: not delayed a period';
        $q->disconnect if $q->is_connected;
    }

    # an idle connection stops its timer, and a later command re-arms it
    {
        my ($up, $err, $at);
        my $q = EV::Redis->new(
            command_timeout => 100, on_error => sub {},
            on_connect => sub { $up = 1; EV::break },
        );
        $q->connect('127.0.0.1', $l->sockport);
        { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
        my $i0 = EV::iteration;
        { my $g = EV::timer 1, 0, sub { EV::break }; EV::run }
        # repeating every 100ms would be about 10
        cmp_ok EV::iteration - $i0, '<', 6, 'idle connection: the timeout timer does not keep waking the loop';
        my $t0 = EV::time;
        $q->get('k', sub { ($err, $at) = ($_[1], EV::time - $t0); EV::break });
        { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
        is $err, 'Timeout', 'idle connection: a later command still times out';
        cmp_ok $at // 99, '<', 1, 'idle connection: within about command_timeout';
        $q->disconnect if $q->is_connected;
    }

    # a command larger than the socket buffers, drained slowly by the server:
    # the bytes going out are progress
    {
        my $size = 32 * 1024 * 1024;
        my ($peer, $rd, $got, $replied) = (undef, undef, 0, 0);
        my $srv = IO::Socket::INET->new(
            Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
        ) or die "listen: $!";
        # small in-flight buffer: the client sees the slow drain as slow writes
        $srv->sockopt(Socket::SO_RCVBUF(), 65536);
        my $acc5 = EV::io $srv, EV::READ, sub {
            $peer = $srv->accept or return;
            $peer->blocking(0);
            $rd = EV::timer 0.01, 0.01, sub {
                my $budget = 1024 * 1024;
                while ($budget > 0) {
                    my $n = sysread $peer, my $buf, 65536;
                    return $_[0]->stop if defined $n && 0 == $n;
                    last unless $n;
                    $got += $n;
                    $budget -= $n;
                }
                syswrite $peer, "+OK\r\n" if !$replied && $got >= $size && ($replied = 1);
            };
        };
        my ($res, $err);
        my $q = EV::Redis->new(
            command_timeout => 200, on_error => sub {},
            on_connect => sub { EV::break },
        );
        $q->connect('127.0.0.1', $srv->sockport);
        { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
        $q->set('k', 'x' x $size, sub { ($res, $err) = @_; EV::break });
        { my $g = EV::timer 20, 0, sub { EV::break }; EV::run }
        is $err, undef, 'a large command going out slowly does not time out';
        is $res, 'OK', 'a large command going out slowly gets its reply';
        $q->disconnect if $q->is_connected;
    }

    # a connect started long after the loop last ran still gets its full timeout
    select undef, undef, undef, 0.5;
    my $up;
    my $c = EV::Redis->new(
        connect_timeout => 200,
        on_connect      => sub { $up = 1; EV::break },
        on_error        => sub { EV::break },
    );
    $c->connect('127.0.0.1', $l->sockport);
    my $cguard = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok $up, 'connect after a pause outside the loop: not timed out at once';
    $c->disconnect if $c->is_connected;
}

# a unix socket whose listen backlog is full: the connect never completes
{
    require File::Temp;
    require IO::Socket::UNIX;
    my $dir  = File::Temp::tempdir(CLEANUP => 1);
    my $path = "$dir/full.sock";
    my $srv  = IO::Socket::UNIX->new(Local => $path, Listen => 0) or die "listen: $!";
    my @fill;
    # non-blocking before connect(): older IO::Socket connects first and
    # would block on the full queue
    for (1 .. 8) {
        socket(my $s, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0) or last;
        $s->blocking(0);
        connect($s, Socket::pack_sockaddr_un($path)) or last;
        push @fill, $s;
    }
    my ($err, $up);
    my $r = EV::Redis->new(
        connect_timeout => 300,
        on_error   => sub { $err = $_[0]; EV::break },
        on_connect => sub { $up = 1; EV::break },
    );
    $r->connect_unix($path);
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run unless defined $err;
  SKIP: {
        skip 'the listen backlog did not fill up', 1 if $up;
        ok defined $err, 'unix socket with a full backlog: the connect fails in time'
            or diag 'no on_error within 3s';
    }
    $r->disconnect if $r->is_connected;
}

# the loop blocks past connect_timeout while the server accepts, answers with
# an error and closes: that error is reported, not a timeout
{
    require File::Temp;
    require IO::Socket::UNIX;
    my $dir  = File::Temp::tempdir(CLEANUP => 1);
    my $path = "$dir/closing.sock";
    my $srv  = IO::Socket::UNIX->new(Local => $path, Listen => 5) or die "listen: $!";
    my @ev;
    my $r = EV::Redis->new(
        connect_timeout => 100,
        on_error   => sub { push @ev, "error:$_[0]" },
        on_connect => sub { push @ev, 'connect' },
    );
    $r->connect_unix($path);
    my $peer = $srv->accept;
    syswrite $peer, "-ERR max number of clients reached\r\n";
    close $peer;
    select undef, undef, undef, 0.3;
    my $g = EV::timer 1, 0, sub { EV::break };
    EV::run;
    ok !(grep { $_ eq 'error:Timeout' } @ev), 'connect done while the loop was blocked: no timeout'
        or diag "@ev";
    ok((grep { /max number of clients/ } @ev), 'connect done while the loop was blocked: the server error is reported')
        or diag "@ev";
    $r->disconnect if $r->is_connected;
}

# 192.0.2.1 (TEST-NET-1) is never routed, so most networks silently drop the SYN
SKIP: {
    my ($conn_err, $up);
    my $r = EV::Redis->new(
        on_error   => sub { $conn_err //= $_[0] },
        on_connect => sub { $up = 1 },
        connect_timeout => 300,
    );
    $r->connect('192.0.2.1', 6379);
    skip 'connect to 192.0.2.1 failed inside the call', 2 unless $r->is_connected;
    my ($err, $at) = steady_traffic($r, 3);
    skip '192.0.2.1 accepted the connection', 2 if $up;
    skip "network answered 192.0.2.1: $conn_err", 2
        if defined $conn_err && $conn_err ne 'Timeout';

    is $err, 'Timeout', 'hanging connect: commands time out despite steady traffic';
    cmp_ok $at // 99, '<', 1.5, 'hanging connect: within about connect_timeout';
    $r->disconnect if $r->is_connected;
}

done_testing;
