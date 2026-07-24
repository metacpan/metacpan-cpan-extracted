use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EV;
use EV::Nats;
use MockNats;

# Protocol and memory-safety regressions against a forked mock server
# (t/lib/MockNats.pm). No nats-server needed; each mock listens on an
# ephemeral 127.0.0.1 port and cannot collide with a real server.

# Run EV::run with a hard cap so no assertion can hang the suite.
sub run_guarded {
    my ($seconds) = @_;
    my $g = EV::timer $seconds, 0, sub { EV::break };
    EV::run;
}

subtest 'MSG split across two reads keeps subject and payload' => sub {
    plan tests => 4;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $buf = MockNats->read_until($c, qr/SUB\s+\S+\s+(\d+)\r\n/) or return;
        my ($sid) = $buf =~ /SUB\s+\S+\s+(\d+)\r\n/;
        syswrite($c, "MSG my.subject $sid 5\r\n");  # protocol line only...
        select undef, undef, undef, 0.25;           # ...force a second read()
        syswrite($c, "hello\r\n");                  # ...for the body
        select undef, undef, undef, 1.0;
    })->start;

    my ($subj, $pay, $reply);
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $nats->subscribe('my.subject', sub {
                ($subj, $pay, $reply) = @_;
                EV::break;
            });
        },
    );
    run_guarded(6);
    $mock->stop;

    ok defined $subj, 'message delivered';
    is $subj,  'my.subject', 'subject correct across split reads';
    is $pay,   'hello',      'payload correct across split reads';
    is $reply, undef,        'no reply-to';
};

subtest 'malformed frames are dropped, well-formed ones delivered intact' => sub {
    plan tests => 3;
    # %SID% is substituted with the real sid by the mock.
    my @cases = (
        ['hmsg hdr_len > total',  "HMSG s.a %SID% 999 3\r\nabc\r\n"],
        ['hmsg hdr_len == total', "HMSG s.a %SID% 4 4\r\nabcd\r\n"],
        ['hmsg zero hdr',         "HMSG s.a %SID% 0 3\r\nabc\r\n"],
        ['hmsg reply + hdr',      "HMSG s.a %SID% rep 4 8\r\nHDR\nbody\r\n"],
        ['msg empty payload',     "MSG s.a %SID% 0\r\n\r\n"],
        ['msg with reply',        "MSG s.a %SID% my.reply 3\r\nabc\r\n"],
        ['msg tab after op',      "MSG\ts.a\t%SID%\t3\r\nabc\r\n"],
        ['msg trailing spaces',   "MSG s.a %SID% 3   \r\nabc\r\n"],
        ['msg huge decimal',      "MSG s.a %SID% 99999999999999999999999\r\n"],
        ['msg negative-looking',  "MSG s.a %SID% -1\r\n"],
        ['msg no sid',            "MSG s.a\r\n"],
        ['msg empty subject',     "MSG  %SID% 3\r\nabc\r\n"],
        ['bare CRLF',             "\r\n"],
        ['unknown op',            "ZORK blah\r\n"],
        ['+OK',                   "+OK\r\n"],
        ['PING',                  "PING\r\n"],
        ['split msg header/body', "MSG s.a %SID% 5\r\n\x00SPLIT\x00hello\r\n"],
        ['info no keys',          qq(INFO {"server_id":"x"}\r\n)],
        ['info truncated nonce',  qq(INFO {"nonce":"abc\r\n)],
        ['info connect_urls odd', qq(INFO {"connect_urls":["a:1",",,,","b"]}\r\n)],
        ['info ldm',              qq(INFO {"ldm":true}\r\n)],
        ['info max_payload huge', qq(INFO {"max_payload":99999999999999999999}\r\n)],
    );
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $buf = MockNats->read_until($c, qr/SUB\s+\S+\s+(\d+)\r\n/) or return;
        my ($sid) = $buf =~ /SUB\s+\S+\s+(\d+)\r\n/;
        for my $case (@cases) {
            my ($name, $frame) = @$case;
            $frame =~ s/%SID%/$sid/g;
            if ($frame =~ /\x00SPLIT\x00/) {
                my ($a, $b) = split /\x00SPLIT\x00/, $frame, 2;
                syswrite($c, $a);
                select undef, undef, undef, 0.12;
                syswrite($c, $b);
            } else {
                syswrite($c, $frame);
            }
            select undef, undef, undef, 0.06;
        }
        # The PING case proves the client is still protocol-responsive
        # after everything above: it must answer with PONG.
        my $after = MockNats->read_until($c, qr/PONG\r\n/, 3);
        print $report 'pong=' . ($after ? 1 : 0) . "\n";
    })->start;

    my (@delivered, @errs);
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { push @errs, $_[0] },
        on_connect => sub {
            $nats->subscribe('s.>', sub {
                push @delivered, [ @_ ];
                EV::break if @delivered == 8;
            });
        },
    );
    run_guarded(8);
    my $pong = $mock->report(5);
    $mock->stop;

    # Exactly the well-formed frames, in order; everything malformed must
    # be dropped without disturbing the frames around it.
    is_deeply \@delivered, [
        ['s.a', 'abc',   undef],                    # hmsg hdr_len > total: raw payload
        ['s.a', '',      undef, 'abcd'],            # hmsg hdr_len == total: empty body
        ['s.a', 'abc',   undef],                    # hmsg zero hdr_len
        ['s.a', 'body',  'rep', "HDR\n"],           # hmsg reply + headers
        ['s.a', '',      undef],                    # msg empty payload
        ['s.a', 'abc',   'my.reply'],               # msg with reply
        ['s.a', 'abc',   undef],                    # msg trailing spaces
        ['s.a', 'hello', undef],                    # split msg header/body
    ], 'well-formed frames delivered exactly, malformed ones dropped'
        or diag explain \@delivered;
    is $pong, 'pong=1', 'client still answered PING after the fuzz';
    is_deeply \@errs, [], 'no errors raised by malformed frames'
        or diag explain \@errs;
};

subtest 'inbound control line is capped' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        # Never send a newline again: rbuf must not grow without bound.
        my $sent = 0;
        for (1 .. 400) {
            my $n = syswrite($c, 'A' x 65536);
            last unless $n;
            $sent += $n;
            select undef, undef, undef, 0.01;
        }
        print $report "sent=$sent\n";
    })->start;

    my @errs;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        reconnect => 0,
        on_error  => sub { push @errs, $_[0] },
    );
    run_guarded(8);
    $mock->stop;

    ok((grep { /maximum control line exceeded/ } @errs),
       'peer that never sends a newline is cut off')
        or diag "errors: @errs";
    ok !$nats->is_connected, 'connection torn down';
};

subtest 'tls_required server never sees a plaintext CONNECT' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->send_info($c,
            '{"server_id":"fake","max_payload":1048576,"tls_required":true}');
        my $buf = MockNats->read_until($c, qr/CONNECT/, 3);
        print $report ($buf ? 'LEAKED' : 'NO-CONNECT') . "\n";
    })->start;

    my @errs;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        user => 'u', pass => 'secret',   # credentials that must not leak
        reconnect => 0,
        on_error  => sub { push @errs, $_[0] },
    );
    run_guarded(6);
    my $verdict = $mock->report(5);
    $mock->stop;

    is $verdict, 'NO-CONNECT', 'no CONNECT on the wire for a tls_required server';
    ok((grep { /requires TLS/ } @errs), 'error explains the refusal')
        or diag "errors: @errs";
};

subtest 'flush() is not satisfied by a keepalive PONG' => sub {
    plan tests => 4;
    # The keepalive ping and flush() share one pong FIFO. The mock answers
    # the handshake PING, then holds back: PONG #1 only after TWO further
    # PINGs (one keepalive + one from flush), PONG #2 only after SIX. If a
    # keepalive PING pushes no FIFO placeholder, PONG #1 pops flush's
    # callback and it reports success on someone else's PONG.
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my ($pings, $pongs, $buf) = (0, 0, '');
        my $deadline = time + 12;
        while (time < $deadline && $pongs < 2) {
            my $rin = ''; vec($rin, fileno($c), 1) = 1;
            if (select(my $r = $rin, undef, undef, 0.1)) {
                my $n = sysread($c, my $ch, 4096); last unless $n;
                $buf .= $ch;
                my $new = () = $buf =~ /PING\r\n/g;
                if ($new) { $pings += $new; $buf = substr($buf, -5) }
            }
            if    ($pings >= 2 && $pongs == 0) { syswrite($c, "PONG\r\n"); $pongs = 1 }
            elsif ($pings >= 6 && $pongs == 1) { syswrite($c, "PONG\r\n"); $pongs = 2 }
        }
        print $report "pongs=$pongs\n";
    })->start;

    my ($flush_fired, $flush_err) = (0, 'unset');
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        ping_interval => 1000, max_pings_outstanding => 100,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            my $f; $f = EV::timer 1.4, 0, sub {
                undef $f;
                $nats->flush(sub {
                    ($flush_fired, $flush_err) = (1, $_[0]);
                    EV::break;
                });
            };
        },
    );
    # Phase 1: PONG #1 lands at ~+1.4s; the 6th PING (which unlocks
    # PONG #2) is not sent before +5s. 2.5s after arming, flush must
    # still be waiting for its own PONG.
    my $phase1 = EV::timer 3.9, 0, sub { EV::break };
    run_guarded(8);
    ok !$flush_fired, 'one PONG for two PINGs did not complete flush()';

    # Phase 2: the mock answers the backlog; flush must now complete.
    run_guarded(6);
    my $pongs = $mock->report(5);
    $mock->stop;
    ok $flush_fired, 'flush() completed once its own PONG arrived';
    is $flush_err, undef, 'flush() reported success';
    is $pongs, 'pongs=2', 'mock sent exactly the two scripted PONGs';
};

for my $mode ('die', 'ok') {
    subtest "batch { $mode } does not wedge the writer" => sub {
        plan tests => 2;
        my $mock = MockNats->new(on_accept => sub {
            my ($c, $report) = @_;
            MockNats->handshake($c) or return;
            my $buf = MockNats->read_until($c, qr/PUB after\.batch/, 5);
            print $report ($buf ? 'GOT' : 'MISSING') . "\n";
        })->start;

        my $batch_err = '';
        my $nats;
        $nats = EV::Nats->new(
            host => '127.0.0.1', port => $mock->port,
            on_error   => sub { diag "error: $_[0]" },
            on_connect => sub {
                if ($mode eq 'die') {
                    eval { $nats->batch(sub { die "boom\n" }); 1 }
                        or $batch_err = $@;
                } else {
                    $nats->batch(sub { 1 });
                }
                $nats->publish('after.batch', 'payload');
            },
        );
        run_guarded(6);
        my $verdict = $mock->report(6);
        $mock->stop;

        if ($mode eq 'die') {
            like $batch_err, qr/^boom/, 'exception still propagates to the caller';
        } else {
            is $batch_err, '', 'batch completed normally';
        }
        is $verdict, 'GOT', 'server received the post-batch PUB';
    };
}

{   # Rides along inside a connection handler closure; reports when the
    # connection object is really freed, and whether that happened while
    # the dropping callback was still on the stack.
    package DestroyProbe;
    sub new {
        my ($class, $cb_done, $destroyed, $sync) = @_;
        bless { cb_done => $cb_done, destroyed => $destroyed, sync => $sync }, $class;
    }
    sub DESTROY {
        my ($self) = @_;
        ${$self->{destroyed}} = 1;
        ${$self->{sync}}      = ${$self->{cb_done}} ? 0 : 1;
    }
}

for my $ctx (qw(connect message nested disconnect)) {
    subtest "destroy from inside a $ctx callback is deferred and completes" => sub {
        plan tests => 2;
        my $mock = MockNats->new(on_accept => sub {
            my ($c, $report) = @_;
            MockNats->handshake($c) or return;
            if ($ctx eq 'disconnect') {
                select undef, undef, undef, 0.3;
                close $c;   # server goes away: client sees EOF
                return;
            }
            # Drain client output; answer each SUB with one message.
            my $buf = '';
            my $deadline = time + 4;
            while (time < $deadline) {
                my $rin = ''; vec($rin, fileno($c), 1) = 1;
                if (select(my $r = $rin, undef, undef, 0.2)) {
                    my $n = sysread($c, my $x, 65536); last unless $n;
                    $buf .= $x;
                    if ($buf =~ /SUB\s+\S+\s+(\d+)\r\n/) {
                        syswrite($c, "MSG s.a $1 5\r\nhello\r\n");
                        $buf = '';
                    }
                }
            }
        })->start;

        my ($destroyed, $sync_destroy, $cb_done) = (0, 0, 0);
        my $obs = DestroyProbe->new(\$cb_done, \$destroyed, \$sync_destroy);
        my $n;
        my $drop = sub {
            undef $n;        # last strong reference, mid-callback
            $cb_done = 1;    # a synchronous DESTROY would have run before this
            EV::break;
        };
        my %args = (host => '127.0.0.1', port => $mock->port, on_error => sub { });
        if ($ctx eq 'connect') {
            $n = EV::Nats->new(%args, on_connect => $drop);
        } elsif ($ctx eq 'message') {
            $n = EV::Nats->new(%args, on_connect => sub {
                $n->subscribe('s.>', $drop);
            });
        } elsif ($ctx eq 'nested') {
            # Re-enter the write path before dropping the reference.
            $n = EV::Nats->new(%args, on_connect => sub {
                $n->publish('x.y', 'z' x 100) for 1 .. 50;
                $n->flush(sub { });
                $drop->();
            });
        } else {
            $n = EV::Nats->new(%args, reconnect => 0, on_disconnect => $drop);
        }
        # The observer is now held only by the connection's own handler
        # (the do-block gives the closure a lexical of its own; a plain
        # sub { $obs } would share the pad slot and die at undef);
        # its DESTROY marks the connection's real free.
        $n->on_error(do { my $keep = $obs; sub { $keep } });
        undef $obs;

        run_guarded(6);
        $mock->stop;

        ok $destroyed, 'connection object actually freed';
        ok !$sync_destroy, 'free deferred until the callback returned';
    };
}

subtest 'hostile INFO max_payload cannot poison the size guard' => sub {
    plan tests => 4;
    # max_payload 4294967295 wraps a signed 32-bit int to -1; the message
    # size below must still be rejected, not measured against (size_t)-1.
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c, '{"server_id":"fake","max_payload":4294967295}')
            or return;
        my $buf = MockNats->read_until($c, qr/SUB\s+\S+\s+(\d+)\r\n/) or return;
        my ($sid) = $buf =~ /SUB\s+\S+\s+(\d+)\r\n/;
        syswrite($c, "MSG s.a $sid 4294967295\r\nX");
        select undef, undef, undef, 1.0;
    })->start;

    my (@errs, @delivered);
    my $reported;
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        reconnect => 0,
        on_error   => sub { push @errs, $_[0] },
        on_connect => sub {
            $reported = $nats->max_payload;
            $nats->subscribe('s.>', sub { push @delivered, [ @_ ] });
        },
    );
    run_guarded(6);
    $mock->stop;

    is $reported, 2147483647, 'hostile max_payload clamped to INT_MAX';
    ok((grep { /exceeding max_payload/ } @errs),
       'oversized frame rejected with an error')
        or diag "errors: @errs";
    is scalar(@delivered), 0, 'hostile MSG never delivered';
    ok !$nats->is_connected, 'connection torn down after the violation';
};

subtest 'NKey seed handling' => sub {
    if (!EV::Nats::HAS_NKEY()) {
        plan skip_all => 'built without OpenSSL: no NKey support';
    }
    plan tests => 6;
    eval { EV::Nats->nkey_public_from_seed('A' x 500) };
    like $@, qr/invalid NKey seed/, 'over-long seed croaks cleanly (no overflow)';
    eval { EV::Nats->nkey_public_from_seed('junk!!!') };
    like $@, qr/invalid NKey seed/, 'garbage seed croaks cleanly';

    my $seed = EV::Nats->nkey_generate_user_seed;
    like $seed, qr/\ASU[A-Z2-7]{56}\z/, 'generated seed is a user seed';
    my $pub = eval { EV::Nats->nkey_public_from_seed($seed) };
    is $@, '', 'generated seed round-trips through nkey_public_from_seed';
    like $pub, qr/\AU[A-Z2-7]{55}\z/, 'derived key is a user public key';
    is(EV::Nats->nkey_public_from_seed($seed), $pub, 'derivation is deterministic');
};

done_testing;
