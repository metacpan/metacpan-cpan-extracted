use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use IO::Socket::INET;
use Socket qw(SOL_SOCKET SO_LINGER);
use Time::HiRes ();
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::KV;
use EV::Nats::ObjectStore;
use MockNats;

# Client-side guards and error-path regressions. No real nats-server needed:
# dead ports (connection refused), the forked MockNats, and plain objects.

sub run_guarded {
    my ($seconds) = @_;
    # EV::timer anchors `after` to the cached loop time, which goes stale
    # across out-of-loop mock waits; refresh it so the guard can't be born expired.
    EV::now_update;
    my $g = EV::timer $seconds, 0, sub { EV::break };
    EV::run;
}

# A port that is (almost certainly) closed: bind an ephemeral one, close it.
sub dead_port {
    my $s = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0,
        Proto => 'tcp', Listen => 1,
    ) or die "dead_port bind: $!";
    my $p = $s->sockport;
    close $s;
    return $p;
}

sub dead_nats {
    my (%extra) = @_;
    return EV::Nats->new(
        host => '127.0.0.1', port => dead_port(),
        reconnect => 1, on_error => sub {},
        %extra,
    );
}

subtest 'undef/empty subjects and headers croak instead of churning' => sub {
    plan tests => 10;
    my $nats = dead_nats();

    eval { $nats->publish(undef, 'x'); 1 };
    like $@, qr/subject/i, 'publish undef subject croaks';
    eval { $nats->publish('', 'x'); 1 };
    like $@, qr/subject/i, 'publish empty subject croaks';

    eval { $nats->hpublish(undef, "NATS/1.0\r\n\r\n", 'x'); 1 };
    like $@, qr/subject/i, 'hpublish undef subject croaks';
    eval { $nats->hpublish('s', undef, 'x'); 1 };
    like $@, qr/header/i, 'hpublish undef headers croak';
    eval { $nats->hpublish('s', '', 'x'); 1 };
    like $@, qr/header/i, 'hpublish empty headers croak';
    eval { $nats->hpublish('s', "GARBAGE\r\n\r\n", 'x'); 1 };
    like $@, qr/NATS\/1\.0/, 'hpublish without NATS/1.0 prefix croaks';

    eval { $nats->subscribe(undef, sub {}); 1 };
    like $@, qr/subject/i, 'subscribe undef subject croaks';
    eval { $nats->subscribe('', sub {}); 1 };
    like $@, qr/subject/i, 'subscribe empty subject croaks';

    eval { $nats->request(undef, 'x', sub {}); 1 };
    like $@, qr/subject/i, 'request undef subject croaks';
    eval { $nats->request('', 'x', sub {}); 1 };
    like $@, qr/subject/i, 'request empty subject croaks';

    $nats->disconnect;
};

subtest 'whitespace in subjects/reply/queue croaks instead of misrouting' => sub {
    plan tests => 7;
    my $nats = dead_nats();

    eval { $nats->publish('a b', 'x'); 1 };
    like $@, qr/whitespace/, 'publish spaced subject croaks';
    eval { $nats->publish('a', 'x', "r\rr"); 1 };
    like $@, qr/whitespace/, 'publish CR reply-to croaks';
    eval { $nats->hpublish("a\nb", "NATS/1.0\r\n\r\n", 'x'); 1 };
    like $@, qr/whitespace/, 'hpublish LF subject croaks';
    eval { $nats->subscribe("a\tb", sub {}); 1 };
    like $@, qr/whitespace/, 'subscribe tabbed subject croaks';
    eval { $nats->subscribe('a', sub {}, 'q q'); 1 };
    like $@, qr/whitespace/, 'subscribe spaced queue group croaks';
    eval { $nats->request('a b', 'x', sub {}); 1 };
    like $@, qr/whitespace/, 'request spaced subject croaks';

    eval { $nats->publish('ok.subj', 'spaces here are fine'); 1 };
    is $@, '', 'payload whitespace still accepted';

    $nats->disconnect;
};

subtest 'ping() requires a live connection' => sub {
    plan tests => 2;
    my $nats = dead_nats();   # connecting or reconnect-pending, never up
    eval { $nats->ping; 1 };
    like $@, qr/not connected/, 'ping while down croaks';

    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $buf = MockNats->read_until($c, qr/PING\r\n/, 5);
        print $report ($buf ? "PING-OK\n" : "NO-PING\n");
    })->start;
    my $up;
    $up = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error => sub { diag "error: $_[0]" },
        on_connect => sub { eval { $up->ping; 1 } or diag "ping: $@"; EV::break },
    );
    run_guarded(5);
    is $mock->report(5), 'PING-OK', 'ping while connected sends PING';
    $mock->stop;
};

subtest 'drain() while down or twice croaks instead of hanging' => sub {
    plan tests => 3;
    my $down = dead_nats();
    eval { $down->drain(sub {}); 1 };
    like $@, qr/not connected/, 'drain while down croaks';
    $down->disconnect;

    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        MockNats->read_until($c, qr/PING\r\n/, 5);
        syswrite($c, "PONG\r\n");
        select undef, undef, undef, 2.0;
    })->start;
    my ($up, $drained);
    $up = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error => sub { diag "error: $_[0]" },
        on_connect => sub {
            $up->drain(sub { $drained = $_[0]; EV::break });
            eval { $up->drain(sub {}); 1 };
            like $@, qr/already.*drain|drain.*progress/i,
                'second drain with a callback croaks';
            eval { $up->drain; 1 };
            ok !$@, 'second drain without a callback is a silent no-op';
        },
    );
    run_guarded(6);
    $mock->stop;
};

subtest 'drain_cb that disconnects fires once instead of recursing' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        MockNats->read_until($c, qr/PING\r\n/, 5);
        select undef, undef, undef, 3.0;   # never PONG: drain stays armed
    })->start;
    my ($up, $fires);
    $up = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error => sub {},
        on_connect => sub {
            $up->drain(sub { $fires++; $up->disconnect; });
            $up->disconnect;
            EV::break;
        },
    );
    run_guarded(6);
    is $fires, 1, 'drain_cb fired exactly once';
    ok !$up->is_connected, 'session tore down';
    $mock->stop;
};

subtest 'failed callback-free drain clears its state before reconnect' => sub {
    my $first = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        MockNats->read_until($c, qr/PING\r\n/) or return;
        close $c;
    })->start;
    my $second = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        MockNats->read_until($c, qr/PING\r\n/) or return;
        syswrite($c, "PONG\r\n");
        select undef, undef, undef, 0.2;
    })->start;
    my ($nats, $connects, $drained, $err);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $first->port,
        on_error => sub {},
        on_connect => sub {
            if (++$connects == 1) { $nats->drain; return; }
            eval { $nats->drain(sub { $drained = !defined $_[0]; EV::break }); 1 }
                or do { $err = $@; EV::break };
        },
        on_disconnect => sub {
            $nats->connect('127.0.0.1', $second->port) if $connects == 1;
        },
    );
    run_guarded(5);
    is $connects, 2, 'reconnected after the failed drain';
    ok !defined $err, 'fresh drain did not croak' or diag $err;
    ok $drained, 'fresh drain completed successfully';
    $nats->on_disconnect(undef);
    $nats->disconnect;
    $first->stop;
    $second->stop;
};

subtest 'priority outside -2..+2 croaks' => sub {
    plan tests => 4;
    # No EV::run here: with a bogus priority nothing must reach the loop.
    eval { EV::Nats->new(priority => 99, on_error => sub {}) };
    like $@, qr/priority/i, 'new(priority => 99) croaks';
    eval { EV::Nats->new(priority => -99, on_error => sub {}) };
    like $@, qr/priority/i, 'new(priority => -99) croaks';

    my $nats = EV::Nats->new(on_error => sub {});
    eval { $nats->priority(99); 1 };
    like $@, qr/priority/i, 'priority(99) setter croaks';
    eval { $nats->priority(2); 1 };
    ok !$@, 'priority(2) is accepted';
};

subtest 'loop option tolerates undef and rejects garbage' => sub {
    plan tests => 2;
    my $nats;
    eval { $nats = EV::Nats->new(loop => undef, on_error => sub {}); 1 };
    ok !$@ && defined $nats, 'loop => undef falls back to the default loop';
    eval { EV::Nats->new(loop => 123, on_error => sub {}) };
    like $@, qr/loop/i, 'loop => 123 croaks';
};

subtest 'reconnect buffer is capped' => sub {
    plan tests => 7;
    my $nats = dead_nats(reconnect_buf_size => 100);
    is $nats->reconnect_buf_size, 100, 'ctor opt stored';
    $nats->reconnect_buf_size(100);
    is $nats->reconnect_buf_size, 100, 'accessor round-trips';

    # "PUB s 50\r\n" + 50B + CRLF = 62B queued, under the 100B cap.
    eval { $nats->publish('s', 'x' x 50); 1 };
    ok !$@, 'first publish queues';
    is $nats->waiting_count, 1, 'one write waiting';
    eval { $nats->publish('s', 'x' x 50); 1 };
    like $@, qr/reconnect buffer/, 'second publish croaks when the cap is hit';
    is $nats->waiting_count, 1, 'failed publish did not queue';
    $nats->disconnect;

    my $def = EV::Nats->new(on_error => sub {});
    is $def->reconnect_buf_size, 8 * 1024 * 1024, 'default is 8 MiB';
};

subtest 'lowering the reconnect cap below queued bytes blocks further writes' => sub {
    my $nats = dead_nats();
    $nats->publish('s', 'x' x 100);
    $nats->reconnect_buf_size(10);
    for my $send (
        sub { $nats->publish('s', 'y') },
        sub { $nats->hpublish('s', "NATS/1.0\r\n\r\n", 'y') },
        sub { $nats->request('s', 'y', sub {}) },
        sub { $nats->subscribe('s', sub {}) },
    ) {
        eval { $send->(); 1 };
        like $@, qr/reconnect buffer/, 'write refused after lowering the cap';
    }
    is $nats->waiting_count, 1, 'existing backlog retained without new writes';
    is $nats->subscription_count, 0, 'refusals created no subscriptions';
    $nats->skip_waiting;
    $nats->reconnect_buf_size(100);
    $nats->publish('s', 'y');
    is $nats->waiting_count, 1, 'queue accepts writes after clearing the backlog';
    $nats->disconnect;
};

subtest 'reconnect(0) cancels a pending reconnect' => sub {
    plan tests => 2;
    my @errs;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => dead_port(),
        reconnect => 1, reconnect_delay => 100,
        on_error => sub { push @errs, $_[0]; EV::break if @errs == 1 },
    );
    run_guarded(5);             # first attempt fails, retry is now pending
    ok @errs == 1, 'one error so far' or diag explain \@errs;
    $nats->reconnect(0);        # must defuse the pending timer
    run_guarded(0.6);           # well past the 100ms retry
    is scalar @errs, 1, 'no further attempts after reconnect(0)';
};

subtest 'manual connect() resets the attempt budget' => sub {
    plan tests => 2;
    my @errs;
    my $port = dead_port();
    my $nats = EV::Nats->new(
        reconnect => 1, reconnect_delay => 50, max_reconnect_attempts => 1,
        on_error => sub { push @errs, $_[0] },
    );
    $nats->connect('127.0.0.1', $port);
    my $g = EV::timer 3, 0, sub { EV::break };
    my $w; $w = EV::timer 0.05, 0.05, sub {
        EV::break if grep { /max reconnect attempts/ } @errs;
    };
    EV::run;
    ok((grep { /max reconnect attempts/ } @errs), 'first connect exhausted the budget');

    @errs = ();
    $nats->connect('127.0.0.1', $port);
    run_guarded(2);
    # A manual connect always tries once synchronously; the budget only gates
    # the automatic retries that follow. Fresh budget => initial attempt plus
    # at least one scheduled retry; stale budget => attempt, then instant
    # "max reconnect attempts reached" with no retry.
    my $attempts = grep { !/max reconnect attempts/ } @errs;
    cmp_ok $attempts, '>=', 2,
        'second connect gets a fresh attempt budget';
};

subtest 'request() counts toward msgs_out/bytes_out' => sub {
    plan tests => 3;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        select undef, undef, undef, 2.0;   # never answer: timeout path
    })->start;
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error => sub { diag "error: $_[0]" },
        on_connect => sub {
            $nats->publish('s', 'x' x 10);
            $nats->request('s', 'y' x 20, sub { EV::break }, 500);
            my %s = $nats->stats;
            is $s{msgs_out}, 2, 'publish + request counted';
            is $s{bytes_out}, 30, 'payload bytes counted';
        },
    );
    run_guarded(5);
    $mock->stop;
    pass 'timeout path ran without incident';
};

subtest 'ping_interval takes effect live' => sub {
    plan tests => 3;
    # Mock counts PINGs in two consecutive 0.6s windows. The client starts
    # quiet (60s), drops to 50ms on connect, back to 0 after 0.4s.
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my @counts;
        for my $w (1, 2) {
            my ($pings, $buf) = (0, '');
            my $deadline = Time::HiRes::time() + 0.6;
            while (Time::HiRes::time() < $deadline) {
                my $rin = ''; vec($rin, fileno($c), 1) = 1;
                if (select(my $r = $rin, undef, undef, 0.05)) {
                    my $n = sysread($c, my $ch, 4096); last unless $n;
                    $buf .= $ch;
                    my $new = () = $buf =~ /PING\r\n/g;
                    if ($new) { $pings += $new; $buf = substr($buf, -5) }
                }
            }
            push @counts, $pings;
        }
        print $report "w1=$counts[0] w2=$counts[1]\n";
    })->start;

    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        ping_interval => 60000, max_pings_outstanding => 100,
        on_error => sub { diag "error: $_[0]" },
        on_connect => sub {
            $nats->ping_interval(50);
            my $off; $off = EV::timer 0.4, 0, sub {
                undef $off;
                $nats->ping_interval(0);
            };
            my $end; $end = EV::timer 1.8, 0, sub { undef $end; EV::break };
        },
    );
    run_guarded(6);
    my $rep = $mock->report(5);
    $mock->stop;
    my ($w1, $w2) = $rep =~ /w1=(\d+) w2=(\d+)/;
    ok defined $w1, "mock counted PINGs ($rep)";
    cmp_ok $w1, '>=', 3, 'live change to 50ms speeds up PINGs';
    cmp_ok $w2, '<=', 2, 'live change to 0 stops PINGs';
};

subtest 'failover parses bracketed IPv6 connect_urls' => sub {
    plan tests => 2;
    my $mock2 = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c, { server_id => 'mock2', version => '2.10.0',
                                  max_payload => 1048576 }) or return;
        select undef, undef, undef, 5.0;
    })->start;
    my $mock2port = $mock2->port;
    my $mock1 = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        # Garbage entries around the good one: an unbalanced '[' must
        # neither swallow the entry after it nor wedge the parser.
        MockNats->handshake($c, { server_id => 'mock1', version => '2.10.0',
            max_payload => 1048576,
            connect_urls => ["[unclosed", "[127.0.0.1]:$mock2port",
                             "[]", "bad_host!", "h:99999999999"] }) or return;
        select undef, undef, undef, 0.3;
        close $c;
    })->start;

    my ($connects, $final_info) = (0, '');
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock1->port,
        reconnect => 1, reconnect_delay => 100,
        on_error => sub { diag "error: $_[0]" },
        on_connect => sub {
            $connects++;
            $final_info = $nats->server_info // '';
            EV::break if $connects == 2;
        },
    );
    run_guarded(8);
    $mock1->stop; $mock2->stop;
    is $connects, 2, 'failed over to the bracketed connect_url';
    like $final_info, qr/mock2/, 'second connection landed on mock2';
};

subtest 'flush() without a callback keeps the pong FIFO 1:1' => sub {
    plan tests => 3;
    # Mock PONGs the 1st PING at once, but the 2nd and 3rd PONGs only after
    # the 3rd PING arrives. If the cb-less flush pushes no placeholder, its
    # PONG completes the NEXT flush early.
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my ($pings, $pongs, $buf) = (0, 0, '');
        my $deadline = time + 10;
        while (time < $deadline && $pongs < 3) {
            my $rin = ''; vec($rin, fileno($c), 1) = 1;
            if (select(my $r = $rin, undef, undef, 0.1)) {
                my $n = sysread($c, my $ch, 4096); last unless $n;
                $buf .= $ch;
                my $new = () = $buf =~ /PING\r\n/g;
                if ($new) { $pings += $new; $buf = substr($buf, -5) }
            }
            if ($pings >= 1 && $pongs == 0) {
                syswrite($c, "PONG\r\n"); $pongs = 1;
            } elsif ($pings >= 3 && $pongs == 1) {
                syswrite($c, "PONG\r\nPONG\r\n"); $pongs = 3;
            }
        }
    })->start;

    my ($f2, $e2, $f3, $e3);
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error => sub { diag "error: $_[0]" },
        on_connect => sub {
            $nats->flush();
            $nats->flush(sub { ($f2, $e2) = (1, $_[0]) });
            my $t1; $t1 = EV::timer 0.4, 0, sub {
                undef $t1;
                ok !$f2, 'cb-less flush PONG did not complete the next flush';
                $nats->flush(sub { ($f3, $e3) = (1, $_[0]); EV::break });
            };
        },
    );
    run_guarded(8);
    $mock->stop;
    ok $f2 && !defined $e2, 'second flush completed on its own PONG';
    ok $f3 && !defined $e3, 'third flush completed, FIFO stayed 1:1';
};

subtest 'flush cb fires on synchronous write failure' => sub {
    plan tests => 3;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        setsockopt($c, SOL_SOCKET, SO_LINGER, pack('ii', 1, 0));
        close $c;
    })->start;

    my @errs;
    my ($fired, $ferr);
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        ping_interval => 60000,
        on_error => sub { push @errs, $_[0] },
        on_connect => sub { EV::break },
    );
    run_guarded(5);
    sleep 1;   # RST arrives; loop idle so EOF stays unprocessed
    $nats->flush(sub { ($fired, $ferr) = (1, $_[0]) });
    ok @errs, 'write error surfaced (positive control)';
    is $fired, 1, 'flush cb fired on sync write failure';
    is $ferr, 'disconnected', 'flush cb got "disconnected"';
    $mock->stop;
};

subtest 'failed drain leaves no ghost marker behind' => sub {
    plan tests => 5;
    my $mock2 = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c, { server_id => 'mock2', version => '2.10.0',
                                  max_payload => 1048576 }) or return;
        select undef, undef, undef, 6.0;
    })->start;
    my $mock2port = $mock2->port;
    my $mock1 = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c, { server_id => 'mock1', version => '2.10.0',
            max_payload => 1048576,
            connect_urls => ["127.0.0.1:$mock2port"] }) or return;
        setsockopt($c, SOL_SOCKET, SO_LINGER, pack('ii', 1, 0));
        close $c;
    })->start;

    my (@errs, $connects, $disconnects, $drain_fired, $drain_err);
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock1->port,
        reconnect => 1, reconnect_delay => 100, ping_interval => 60000,
        on_error => sub { push @errs, $_[0] },
        on_connect => sub { $connects++; EV::break if $connects == 1 },
        on_disconnect => sub { $disconnects++ },
    );
    run_guarded(5);
    sleep 1;   # RST arrives; loop idle so EOF stays unprocessed
    $nats->drain(sub { $drain_fired = 1; $drain_err = $_[0] });
    is $drain_fired, 1, 'drain cb fired on sync write failure';
    is $drain_err, 'disconnected', 'drain cb got "disconnected"';
    run_guarded(6);   # reconnect to mock2 must survive its own handshake
    is $connects, 2, 'reconnected after the failed drain';
    is $disconnects, 1, 'no ghost teardown of the fresh connection';
    ok $nats->is_connected, 'still connected';
    $mock1->stop; $mock2->stop;
};

subtest 'KV delete/purge while down report async errors' => sub {
    plan tests => 8;
    my $nats = dead_nats();
    my $js = EV::Nats::JetStream->new(nats => $nats);
    my $kv = EV::Nats::KV->new(js => $js, bucket => 'bkt');

    for my $op (qw(delete purge)) {
        my ($after, $fired, $err);
        my $meth = $kv->can($op);
        eval { $kv->$meth('k1', sub {
            $fired = 1; $err = $_[1];   # ($ok, $err)
            ok $after, "$op cb fired async";
        }); 1 };
        ok !$@, "$op while down does not croak" or diag $@;
        $after = 1;
        run_guarded(2);
        ok $fired, "$op cb fired";
        like $err, qr/not connected/, "$op cb reports the outage";
    }
    $nats->disconnect;
};

subtest 'ObjectStore put checks chunk_size against max_payload' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c, { server_id => 'm', version => '2.10.0',
                                  max_payload => 100 }) or return;
        select undef, undef, undef, 3.0;
    })->start;
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error => sub { diag "error: $_[0]" },
        on_connect => sub {
            is $nats->max_payload, 100, 'server limit picked up from INFO';
            my $js = EV::Nats::JetStream->new(nats => $nats);
            my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'b');
            eval { $os->put('n', 'x' x 200, sub {}); 1 };
            like $@, qr/max_payload|chunk/, 'oversize chunks croak up front';
            EV::break;
        },
    );
    run_guarded(5);
    $mock->stop;
};

subtest 'ObjectStore validates bucket and chunk_size' => sub {
    plan tests => 4;
    my $js = bless { timeout => 100 }, 'EV::Nats::JetStream';
    eval { EV::Nats::ObjectStore->new(js => $js, bucket => 'bad bucket') };
    like $@, qr/invalid.*bucket/i, 'bucket with space dies';
    eval { EV::Nats::ObjectStore->new(js => $js, bucket => 'ok-bkt_1') };
    ok !$@, 'sane bucket accepted' or diag $@;
    eval { EV::Nats::ObjectStore->new(js => $js, bucket => 'b', chunk_size => -1) };
    like $@, qr/chunk_size/i, 'negative chunk_size dies';
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'b', chunk_size => 0);
    is $os->{chunk_size}, 128 * 1024, 'chunk_size 0 falls back to default';
};

subtest 'constructors warn on unknown options' => sub {
    plan tests => 4;
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    my $nats = EV::Nats->new(bogus_opt => 1, on_error => sub {});
    ok((grep { /unknown option.*bogus_opt/ } @w), 'EV::Nats warns');
    @w = ();
    my $js = EV::Nats::JetStream->new(nats => $nats, bogus_opt => 1);
    ok((grep { /unknown option.*bogus_opt/ } @w), 'JetStream warns');
    @w = ();
    EV::Nats::KV->new(js => $js, bucket => 'b', bogus_opt => 1);
    ok((grep { /unknown option.*bogus_opt/ } @w), 'KV warns');
    @w = ();
    EV::Nats::ObjectStore->new(js => $js, bucket => 'b', bogus_opt => 1);
    ok((grep { /unknown option.*bogus_opt/ } @w), 'ObjectStore warns');
};

subtest 'KV watch rejects a broken pattern' => sub {
    plan tests => 1;
    my $nats = dead_nats();
    my $js = EV::Nats::JetStream->new(nats => $nats);
    my $kv = EV::Nats::KV->new(js => $js, bucket => 'b');
    eval { $kv->watch('has space', sub {}); 1 };
    like $@, qr/invalid.*pattern|whitespace/i, 'watch pattern with space dies';
    $nats->disconnect;
};

subtest 'refused request leaves no stranded timer' => sub {
    plan tests => 3;
    my $nats = dead_nats(reconnect_buf_size => 100);
    $nats->publish('s', 'x' x 50);   # 62B accepted
    my $spurious = 0;
    # Inbox SUB (~33B) fits; the PUB on top exceeds the cap.
    eval { $nats->request('s', 'y', sub { $spurious++ }, 200); 1 };
    like $@, qr/reconnect buffer/, 'request past the cap croaks';
    run_guarded(0.6);   # past the 200ms timeout
    is $spurious, 0, 'no spurious timeout callback fired';
    is $nats->waiting_count, 2, 'publish and inbox SUB stayed queued';
    $nats->disconnect;
};

subtest 'refused inbox setup leaves no orphan subscription' => sub {
    plan tests => 2;
    my $nats = dead_nats(reconnect_buf_size => 20);
    eval { $nats->request('s', 'y', sub {}, 200); 1 };
    like $@, qr/reconnect buffer/, 'first request past the cap croaks';
    is $nats->subscription_count, 0, 'no orphaned inbox subscription';
    $nats->disconnect;
};

subtest 'refused subscribe leaves no ghost subscription' => sub {
    plan tests => 3;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $buf = MockNats->read_until($c, qr/[A-Z]/, 3);
        print $report ($buf =~ /SUB/ ? "GHOST-SUB\n" : "CLEAN\n");
    })->start;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        reconnect => 1, reconnect_buf_size => 10,
        on_error => sub { diag "error: $_[0]" },
    );
    # Still connecting: the 18-byte SUB exceeds the 10-byte cap.
    eval { $nats->subscribe('ghost.subj', sub {}); 1 };
    like $@, qr/reconnect buffer/, 'subscribe past the cap croaks';
    is $nats->subscription_count, 0, 'nothing registered';
    run_guarded(5);   # handshake; a ghost would resubscribe here
    is $mock->report(5), 'CLEAN', 'no ghost SUB reached the server';
    $mock->stop;
};

subtest 'refused publishes do not inflate stats' => sub {
    plan tests => 2;
    my $nats = dead_nats(reconnect_buf_size => 100);
    $nats->publish('s', 'x' x 50);
    eval { $nats->publish('s', 'x' x 50); 1 };
    my %s = $nats->stats;
    is $s{msgs_out}, 1, 'refused publish not counted';
    is $s{bytes_out}, 50, 'refused bytes not counted';
    $nats->disconnect;
};

subtest 'explicit undef handlers behave as unset' => sub {
    plan tests => 2;
    eval {
        EV::Nats->new(path => '/nonexistent-ev-nats-test/sock',
                      on_error => undef);
    };
    like $@, qr/^EV::Nats: /, 'connect failure croaks instead of calling undef';
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        print $report "UP\n";
    })->start;
    my $up = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_connect => undef, on_error => sub {},
    );
    run_guarded(2);
    is $mock->report(5), 'UP', 'undef on_connect is silently skipped';
    $mock->stop;
};

subtest 'zero reconnect delay cannot spin' => sub {
    plan tests => 1;
    my $errs = 0;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => dead_port(),
        reconnect => 1, reconnect_delay => 0,
        on_error => sub { $errs++ },
    );
    run_guarded(0.5);
    cmp_ok $errs, '<', 30, "attempts bounded ($errs errors)";
    $nats->disconnect;
};

subtest 'manual connect drops the stale server pool' => sub {
    plan tests => 2;
    my $mock2 = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        select undef, undef, undef, 4.0;
    })->start;
    my $mock2port = $mock2->port;
    my $mock1 = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c, { server_id => 'mock1', version => '2.10.0',
            max_payload => 1048576,
            connect_urls => ["127.0.0.1:$mock2port"] }) or return;
        select undef, undef, undef, 4.0;
    })->start;
    my $connects = 0;
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock1->port,
        reconnect => 1, reconnect_delay => 100,
        on_error => sub {},
        on_connect => sub { $connects++; EV::break if $connects == 1 },
    );
    run_guarded(5);
    is $connects, 1, 'up on mock1';
    $nats->disconnect;
    $nats->connect('127.0.0.1', dead_port());
    run_guarded(1.5);
    is $connects, 1, 'stale pool not used after manual connect';
    $mock1->stop; $mock2->stop;
};

subtest 'NKey seeds are validated up front' => sub {
    if (!EV::Nats::HAS_NKEY) { plan skip_all => 'no OpenSSL'; return; }
    plan tests => 3;
    my $nats = EV::Nats->new(on_error => sub {});
    eval { $nats->nkey_seed('garbage!!'); 1 };
    like $@, qr/invalid NKey seed/, 'setter rejects garbage';
    eval { EV::Nats->new(nkey_seed => 'garbage!!', on_error => sub {}) };
    like $@, qr/invalid NKey seed/, 'new() rejects garbage';
    my $seed = EV::Nats->nkey_generate_user_seed();
    eval { $nats->nkey_seed($seed); 1 };
    ok !$@, 'generated seed accepted' or diag $@;
};

subtest 'refused fetch tears down its inbox sub' => sub {
    plan tests => 3;
    my $nats = dead_nats(reconnect_buf_size => 100);
    $nats->publish('s', 'x' x 16);   # inbox SUB fits, fetch PUB will not
    my $js = EV::Nats::JetStream->new(nats => $nats);
    my $calls = 0;
    eval { $js->fetch('s', 'c', { batch => 1, expires => 100_000_000 }, sub { $calls++ }); 1 };
    like $@, qr/reconnect buffer/, 'fetch past the cap croaks';
    run_guarded(0.6);
    is $nats->subscription_count, 0, 'inbox sub torn down';
    is $calls, 0, 'no stray callback after the croak';
    $nats->disconnect;
};

subtest 'refused KV create tears down its inbox sub' => sub {
    plan tests => 3;
    my $nats = dead_nats(reconnect_buf_size => 100);
    $nats->publish('s', 'x' x 16);
    my $js = EV::Nats::JetStream->new(nats => $nats);
    my $kv = EV::Nats::KV->new(js => $js, bucket => 'bkt', timeout => 200);
    my $calls = 0;
    eval { $kv->create('k', 'v', sub { $calls++ }); 1 };
    like $@, qr/reconnect buffer/, 'create past the cap croaks';
    run_guarded(0.6);   # past the 200ms timer
    is $nats->subscription_count, 0, 'inbox sub torn down';
    is $calls, 0, 'no stray callback after the croak';
    $nats->disconnect;
};

subtest 'unsubscribe past the cap still removes the sub' => sub {
    plan tests => 2;
    my $nats = dead_nats(reconnect_buf_size => 100);
    my $sid = $nats->subscribe('s', sub {});
    $nats->publish('s', 'x' x 76);   # pack the cap: UNSUB will not fit
    eval { $nats->unsubscribe($sid); 1 };
    like $@, qr/reconnect buffer/, 'unsub past the cap croaks';
    is $nats->subscription_count, 0, 'sub removed despite the croak';
    $nats->disconnect;
};

subtest 'oversize CONNECT fields fail fast instead of truncating' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
    })->start;
    my $connected = 0;
    my @errs;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        name => 'x' x 9000,   # overflows even the 8KB CONNECT buffer
        reconnect => 1, reconnect_delay => 100,
        on_connect => sub { $connected++ },
        on_error => sub { push @errs, $_[0] },
    );
    run_guarded(1.5);
    is $connected, 0, 'never connects with a truncated name';
    is scalar(grep { /too long/ } @errs), 1, 'exactly one loud error, no retry storm';
    $nats->disconnect;
    $mock->stop;
};

subtest 'refused subscribe_max removes its partial subscription' => sub {
    my $subject = '_INBOX.test.123';
    my $nats = dead_nats(reconnect_buf_size => length("SUB $subject 1\r\n"));
    eval { $nats->subscribe_max($subject, sub {}, 1); 1 };
    like $@, qr/reconnect buffer/, 'auto-unsubscribe setup exceeded the cap';
    is $nats->subscription_count, 0, 'partial subscription removed';
    $nats->disconnect;
};

subtest 'reply inbox timeouts complete even when reconnect buffer is full' => sub {
    for my $op (qw(js_publish_h create update fetch)) {
        my $mock = MockNats->new(on_accept => sub {
            my ($c) = @_;
            MockNats->handshake($c);
            select undef, undef, undef, 3;
        })->start;
        my $nats = EV::Nats->new(
            host => '127.0.0.1', port => $mock->port, reconnect => 1,
            reconnect_buf_size => 100, on_error => sub {},
            on_connect => sub { EV::break },
        );
        run_guarded(3);
        my $js = EV::Nats::JetStream->new(nats => $nats, timeout => 50);
        my $kv = EV::Nats::KV->new(js => $js, bucket => 'b');
        my ($calls, $result, $err) = (0);
        my $cb = sub { $calls++; ($result, $err) = @_; EV::break };
        if ($op eq 'js_publish_h') {
            $js->js_publish_h('s', "NATS/1.0\r\n\r\n", 'x', $cb);
        } elsif ($op eq 'create') {
            $kv->create('key', 'x', $cb);
        } elsif ($op eq 'update') {
            $kv->update('key', 'x', 1, $cb);
        } else {
            $js->fetch('S', 'C', { expires => 10_000_000 }, $cb);
        }
        $nats->disconnect;
        $nats->connect('127.0.0.1', dead_port());
        $nats->publish('s', 'x' x 80);   # leaves no room for the UNSUB
        run_guarded(2);
        is $calls, 1, "$op callback fired exactly once";
        if ($op eq 'fetch') {
            is_deeply $result, [], 'fetch safety timeout completed with an empty batch';
            ok !defined $err, 'fetch cleanup did not replace its result with an error';
        } else {
            like $err, qr/timeout/, "$op reported its timeout";
        }
        is $nats->subscription_count, 0, "$op reply inbox removed locally";
        $nats->disconnect;
        $mock->stop;
    }
};

subtest 'JetStream and KV timers use the connection loop' => sub {
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c);
        select undef, undef, undef, 5;
    })->start;
    my $loop = EV::Loop->new;
    my $nats = EV::Nats->new(
        loop => $loop, host => '127.0.0.1', port => $mock->port,
        on_error => sub {}, on_connect => sub { $loop->break },
    );
    my $guard = $loop->timer(3, 0, sub { $loop->break });
    $loop->run;
    my $js = EV::Nats::JetStream->new(nats => $nats, timeout => 30);
    my $kv = EV::Nats::KV->new(js => $js, bucket => 'b');
    for my $op (qw(js_publish_h create update fetch)) {
        my ($calls, $err) = (0);
        my $cb = sub { $calls++; $err = $_[1]; $loop->break };
        if ($op eq 'js_publish_h') {
            $js->js_publish_h('s', "NATS/1.0\r\n\r\n", 'x', $cb);
        } elsif ($op eq 'create') {
            $kv->create('key', 'x', $cb);
        } elsif ($op eq 'update') {
            $kv->update('key', 'x', 1, $cb);
        } else {
            $js->fetch('S', 'C', { expires => 10_000_000 }, $cb);
        }
        $guard = $loop->timer(2, 0, sub { $loop->break });
        $loop->run;
        is $calls, 1, "$op timeout fired on the custom loop";
        like $err, qr/timeout/, "$op reported its timeout" unless $op eq 'fetch';
        is $nats->subscription_count, 0, "$op inbox cleaned up";
    }
    my $dead = EV::Nats->new(loop => $loop, on_error => sub {});
    $dead->connect('127.0.0.1', dead_port());
    my $dead_js = EV::Nats::JetStream->new(nats => $dead);
    my $dead_kv = EV::Nats::KV->new(js => $dead_js, bucket => 'b');
    my $fence_calls = 0;
    $dead_kv->delete('key', sub { $fence_calls++; $loop->break });
    $guard = $loop->timer(1, 0, sub { $loop->break });
    $loop->run;
    is $fence_calls, 1, 'KV fence error delivered on the custom loop';
    $dead->disconnect;
    $nats->disconnect;
    $mock->stop;
};

subtest 'refused js_publish_h tears down its inbox sub' => sub {
    plan tests => 3;
    my $nats = dead_nats(reconnect_buf_size => 100);
    $nats->publish('s', 'x' x 16);
    my $js = EV::Nats::JetStream->new(nats => $nats, timeout => 200);
    my $calls = 0;
    eval { $js->js_publish_h('s', "NATS/1.0\r\n\r\n", 'x', sub { $calls++ }); 1 };
    like $@, qr/reconnect buffer/, 'js_publish_h past the cap croaks';
    run_guarded(0.6);
    is $nats->subscription_count, 0, 'inbox sub torn down';
    is $calls, 0, 'no stray callback after the croak';
    $nats->disconnect;
};

subtest 'ObjectStore put mid-flight disconnect reports, never dies' => sub {
    plan tests => 3;
    my $miss = '{"error":{"code":10037,"description":"no message found"}}';
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        for (1..10) {
            my $buf = MockNats->read_until($c, qr/PUB (\S+) (\S+) \d+\r\n/, 5)
                or last;
            my ($subj, $reply) = $buf =~ /PUB (\S+) (\S+) \d+\r\n/;
            if ($subj =~ /STREAM\.MSG\.GET/) {
                syswrite($c, "MSG $reply 1 " . length($miss) . "\r\n$miss\r\n");
                next;
            }
            last;
        }
        select undef, undef, undef, 0.2;
        setsockopt($c, SOL_SOCKET, SO_LINGER, pack('ii', 1, 0));
        close $c;
    })->start;

    my ($fired, $err);
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        reconnect => 0,
        on_error => sub { },
        on_connect => sub {
            my $js = EV::Nats::JetStream->new(nats => $nats);
            my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'bkt',
                chunk_size => 64);
            $os->put('big', 'x' x 500, sub {
                ($fired, $err) = (1, $_[1]);
                EV::break;
            });
        },
    );
    run_guarded(8);
    $mock->stop;

    ok $fired, 'put cb fired after the RST';
    like $err, qr/chunk\(s\) failed/, 'chunk failure reported, process alive';
    ok !$nats->is_connected, 'connection down as expected';
};

done_testing;
