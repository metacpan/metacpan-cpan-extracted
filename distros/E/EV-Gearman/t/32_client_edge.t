# Client edge coverage against fake servers. Hermetic — no gearmand
# needed. Covers request paths the live suite never executes
# (priority background submits, set_client_id, all_yours, maxqueue
# success), kill-with-in-flight, and the queued+timeout interaction.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use IO::Socket::UNIX;
use Time::HiRes qw(time);
use EV;
use EV::Gearman;

my $dir = tempdir(CLEANUP => 1);

sub run_loop {
    my ($secs) = @_;
    my $t = EV::timer $secs, 0, sub { EV::break };
    EV::run;
}

# Fake binary server over TCP (so the client connects async and the
# test can script the accept side). Records client packets in @$pkts.
sub tcp_server {
    my ($on_pkt) = @_;
    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 16,
        ReuseAddr => 1,
    ) or die "bind: $!";
    $srv->blocking(0);
    my $st = { srv => $srv, port => $srv->sockport, conns => [],
               pkts => [] };
    my $send = sub {
        my ($conn, $cmd, $body) = @_;
        $body = '' unless defined $body;
        syswrite $conn->{sock}, "\0RES" . pack('N N', $cmd, length $body)
            . $body;
    };
    $st->{send} = $send;
    $st->{accept} = EV::io fileno($srv), EV::READ, sub {
        while (my $c = $srv->accept) {
            $c->blocking(0);
            my $conn = { sock => $c, rbuf => '' };
            $conn->{rw} = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);
                if (!$n) { close $c; $conn->{rw} = undef; return; }
                $conn->{rbuf} .= $chunk;
                while (length($conn->{rbuf}) >= 12) {
                    my (undef, $cmd, $len) =
                        unpack 'a4 N N', substr($conn->{rbuf}, 0, 12);
                    last if length($conn->{rbuf}) < 12 + $len;
                    my $body = substr($conn->{rbuf}, 12, $len);
                    substr($conn->{rbuf}, 0, 12 + $len) = '';
                    push @{$st->{pkts}}, [$cmd, $body];
                    $on_pkt->($st, $conn, $cmd, $body) if $on_pkt;
                }
            };
            push @{$st->{conns}}, $conn;
        }
    };
    $st;
}

my ($SUBMIT_HIGH_BG, $SUBMIT_LOW_BG) = (32, 34);
my ($SET_CLIENT_ID, $ALL_YOURS) = (22, 24);
my $JOB_CREATED = 8;

# 1. Priority background submits Reach the wire with the right command
# and deliver the JOB_CREATED handle.
for my $case (['submit_job_high_bg', $SUBMIT_HIGH_BG],
              ['submit_job_low_bg',  $SUBMIT_LOW_BG]) {
    my ($meth, $want) = @$case;
    my $st = tcp_server(sub {
        my ($st, $conn, $cmd, $body) = @_;
        $st->{send}->($conn, $JOB_CREATED, 'H:bg:1') if $cmd == $want;
    });
    my ($h, $e);
    my $g = EV::Gearman->new(host => '127.0.0.1', port => $st->{port},
                             on_error => sub { EV::break });
    $g->on_connect(sub {
        $g->$meth('pf', 'workload', { unique => 'u1' }, sub {
            ($h, $e) = @_; EV::break;
        });
    });
    run_loop(5);
    my @cmds = map { $_->[0] } @{$st->{pkts}};
    is_deeply \@cmds, [$want], "$meth: wire command";
    is $st->{pkts}[0][1], "pf\0u1\0workload", "$meth: body framing";
    is $h, 'H:bg:1', "$meth: handle delivered";
    is $e, undef,    "$meth: no error";
    undef $g;
}

# 2. set_client_id sends SET_CLIENT_ID while connected.
{
    my $st = tcp_server(undef);
    my $g = EV::Gearman->new(host => '127.0.0.1', port => $st->{port},
                             on_error => sub {});
    $g->on_connect(sub {
        $g->set_client_id('worker-7');
        my $t; $t = EV::timer 0.3, 0, sub { undef $t; EV::break };
    });
    run_loop(5);
    my @cmds = map { $_->[0] } @{$st->{pkts}};
    is_deeply \@cmds, [$SET_CLIENT_ID], 'set_client_id: wire command';
    is $st->{pkts}[0][1], 'worker-7', 'set_client_id: body';
    undef $g;
}

# 3. all_yours sends ALL_YOURS; the client survives the fire-and-forget.
{
    my $st = tcp_server(undef);
    my ($r, $e);
    my $g = EV::Gearman->new(host => '127.0.0.1', port => $st->{port},
                             on_error => sub {});
    $g->on_connect(sub {
        $g->all_yours;
        my $t; $t = EV::timer 0.3, 0, sub {
            undef $t;
            ($r, $e) = ($g->is_connected, undef);
            EV::break;
        };
    });
    run_loop(5);
    my @cmds = map { $_->[0] } @{$st->{pkts}};
    is_deeply \@cmds, [$ALL_YOURS], 'all_yours: wire command';
    ok $r, 'all_yours: still connected';
    undef $g;
}

# 4. maxqueue success path: "OK\n" reply arrives as ("OK", undef).
{
    my $path = "$dir/c32q.sock";
    unlink $path;
    my $srv = IO::Socket::UNIX->new(Local => $path, Listen => 16)
        or die "bind: $!";
    $srv->blocking(0);
    my @conns;
    my $accept = EV::io fileno($srv), EV::READ, sub {
        while (my $c = $srv->accept) {
            $c->blocking(0);
            my $conn = { sock => $c, rbuf => '' };
            $conn->{rw} = EV::io fileno($c), EV::READ, sub {
                my $n = sysread($c, my $chunk, 65536);
                if (!$n) { close $c; $conn->{rw} = undef; return; }
                $conn->{rbuf} .= $chunk;
                while ($conn->{rbuf} =~ s/^(.*)\n//) {
                    # Real gearmand terminates this reply with \r\n.
                    syswrite $c, "OK\r\n" if $1 =~ /^maxqueue /;
                }
            };
            push @conns, $conn;
        }
    };
    my ($text, $e);
    my $g = EV::Gearman->new(path => $path, on_error => sub {});
    $g->maxqueue('somefunc', 10, sub { ($text, $e) = @_; EV::break });
    run_loop(5);
    is $text, 'OK', 'maxqueue: reply text';
    is $e, undef,   'maxqueue: no error';
    undef $g;
}

# 5. Kill with a foreground job in flight: server sends JOB_CREATED
# then drops the connection; the terminal callback must fire with
# "disconnected" (not hang, not crash).
{
    my $st = tcp_server(sub {
        my ($st, $conn, $cmd, $body) = @_;
        if ($cmd == 7) {
            $st->{send}->($conn, $JOB_CREATED, 'H:kill:1');
            close $conn->{sock};
            $conn->{rw} = undef;
        }
    });
    my ($r, $e, $ndisc);
    my $g = EV::Gearman->new(host => '127.0.0.1', port => $st->{port},
                             on_error => sub {},
                             on_disconnect => sub { $ndisc++ });
    $g->on_connect(sub {
        $g->submit_job('kf', 'w', sub {
            ($r, $e) = @_;
            my $t; $t = EV::timer 0.2, 0, sub {
                undef $t; EV::break;
            };
        });
    });
    run_loop(5);
    is $r, undef,          'in-flight kill: no result';
    is $e, 'disconnected', 'in-flight kill: disconnect reported';
    is $ndisc, 1,          'in-flight kill: on_disconnect fired';
    undef $g;
}

# 6. Queued + command_timeout: a submit made while disconnected (with
# reconnect armed) is budgeted from the moment it is flushed, not
# from the submit call.
{
    my $rsrv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1,
        ReuseAddr => 1,
    ) or die "bind: $!";
    my $port = $rsrv->sockport;
    close $rsrv;

    my ($e, $t_submit, $t_flush, $t_fire, @errors);
    my $g = EV::Gearman->new(
        host => '127.0.0.1', port => $port,
        reconnect => 1, reconnect_delay => 100, command_timeout => 800,
        on_error => sub { push @errors, $_[0] },
    );
    $g->on_connect(sub { $t_flush = time });
    my $t0 = EV::timer 0.1, 0, sub {
        $t_submit = time;
        $g->submit_job('qf', 'w', sub {
            (undef, $e) = @_;
            $t_fire = time;
            EV::break;
        });
    };
    # Bring the server up long after the submit, then answer nothing.
    my ($srv, $accept_w, @conns);
    my $t1 = EV::timer 1.5, 0, sub {
        $srv = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1', LocalPort => $port, Listen => 16,
            ReuseAddr => 1,
        ) or die "bind $port: $!";
        $srv->blocking(0);
        $accept_w = EV::io fileno($srv), EV::READ, sub {
            while (my $c = $srv->accept) {
                $c->blocking(0);
                my $conn = { sock => $c };
                $conn->{rw} = EV::io fileno($c), EV::READ, sub {
                    my $n = sysread($c, my $chunk, 65536);
                    if (!$n) { close $c; $conn->{rw} = undef; }
                };
                push @conns, $conn;
            }
        };
    };
    run_loop(8);
    is $e, 'disconnected', 'queued timeout: drained with "disconnected"';
    is scalar(grep { $_ eq 'command timeout' } @errors), 1,
        'queued timeout: command timeout fired';
    ok defined($t_flush), 'queued timeout: flushed after reconnect';
    my $since_submit = $t_fire - $t_submit;
    my $since_flush = $t_fire - $t_flush;
    cmp_ok $since_submit, '>', 1.5, 'queued timeout: later than submit+budget';
    cmp_ok $since_flush, '>=', 0.5, 'queued timeout: honored after flush';
    cmp_ok $since_flush, '<', 2.5, 'queued timeout: not long after flush';
    undef $g;
}

done_testing;
