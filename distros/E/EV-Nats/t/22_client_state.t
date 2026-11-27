use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EV;
use EV::Nats;
use MockNats;
use IO::Socket::INET;
use Scalar::Util ();
use Time::HiRes ();

# Timers, file descriptors and flush across connection states, against a
# forked mock server.

sub run_guarded {
    my ($seconds) = @_;
    EV::now_update;
    my $g = EV::timer $seconds, 0, sub { EV::break };
    EV::run;
}

subtest 'a request armed after a blocking callback keeps its full timeout' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $buf = $rd->(qr/PUB echo (\S+) 4\r\nping\r\n/) or return;
        my ($reply) = $buf =~ /PUB echo (\S+) /;
        my $sid = (values %{ MockNats->subs_in($buf) })[0];
        select undef, undef, undef, 0.3;
        syswrite $c, MockNats->msg_frame($reply, $sid, undef, 'pong');
        sleep 2;
    })->start;

    my ($nats, @got);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            my $t; $t = EV::timer 0, 0, sub {
                undef $t;
                Time::HiRes::sleep(1.5);
                $nats->request('echo', 'ping', sub { @got = @_; EV::break }, 1000);
            };
        },
    );
    run_guarded(6);
    is $got[0], 'pong', 'the reply arrived';
    is $got[1], undef, 'no spurious request timeout';
    $nats->disconnect;
    $mock->stop;
};

subtest 'connect_timeout armed after blocking work is not born expired' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        sleep 2;
    })->start;

    EV::run(EV::RUN_NOWAIT);
    Time::HiRes::sleep(1.5);
    my ($up, $err);
    my $nats = EV::Nats->new(
        connect_timeout => 1000,
        on_connect => sub { $up = 1; EV::break },
        on_error   => sub { $err = $_[0]; EV::break },
    );
    $nats->connect('127.0.0.1', $mock->port);
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    ok $up, 'connected';
    is $err, undef, 'no connect timeout';
    $nats->disconnect;
    $mock->stop;
};

subtest 'the connection socket is close-on-exec' => sub {
    plan skip_all => 'needs /proc/self/fdinfo' unless -d '/proc/self/fdinfo';
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        sleep 2;
    })->start;

    my $sockets = sub {
        my %s;
        for my $fd (map { m{/(\d+)\z} ? $1 : () } glob '/proc/self/fd/*') {
            my $link = readlink "/proc/self/fd/$fd";
            $s{$fd} = $link if defined $link && $link =~ /^socket:/;
        }
        return \%s;
    };
    my $before = $sockets->();
    my $up;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_connect => sub { $up = 1; EV::break },
        on_error   => sub { diag "error: $_[0]"; EV::break },
    );
    run_guarded(5);
    ok $up, 'connected';
    my $after = $sockets->();
    my @mine = grep { !defined $before->{$_} || $before->{$_} ne $after->{$_} } keys %$after;
    my @leaky;
    for my $fd (@mine) {
        open my $fi, '<', "/proc/self/fdinfo/$fd" or next;
        my ($flags) = map { /^flags:\s*([0-7]+)/ ? $1 : () } <$fi>;
        push @leaky, $fd if defined $flags && !(oct($flags) & 02000000);
    }
    is scalar(@mine) . " leaky=@leaky", '1 leaky=', 'the client socket does not survive exec';
    $nats->disconnect;
    $mock->stop;
};

subtest 'flush while connecting fences the queued writes after the handshake' => sub {
    plan tests => 3;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->send_info($c);
        my $rd = MockNats->reader($c);
        $rd->(qr/PING\r\n/) or return;
        select undef, undef, undef, 0.3;
        syswrite $c, "PONG\r\n";
        my $buf = $rd->(qr/PING\r\n.*PING\r\n/s) or return;
        syswrite $c, "PONG\r\n";
        print $report ($buf =~ /PUB q 1\r\nx\r\nPING\r\n\z/ ? "ordered\n" : "unordered\n");
        sleep 2;
    })->start;

    my ($nats, @flushed);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error => sub { diag "error: $_[0]" },
    );
    $nats->publish('q', 'x');
    ok eval { $nats->flush(sub { @flushed = (1, $_[0]); EV::break }); 1 },
        'flush before on_connect does not croak';
    run_guarded(5);
    is_deeply \@flushed, [1, undef], 'it completed after the handshake';
    is $mock->report(5), 'ordered', 'its PING followed the queued publish';
    $nats->disconnect;
    $mock->stop;
};

subtest 'flush when down reports through the callback' => sub {
    plan tests => 4;
    my $nats = EV::Nats->new;
    my @got;
    ok eval { $nats->flush(sub { push @got, $_[0] }); 1 }, 'no croak with a callback';
    is scalar @got, 0, 'not called from inside flush';
    EV::run(EV::RUN_NOWAIT) for 1 .. 3;
    is_deeply \@got, ['not connected'], 'called from the loop with the error';
    ok !eval { $nats->flush; 1 }, 'flush without a callback still croaks';
};

subtest 'a flush queued during reconnect fails when the attempt fails' => sub {
    plan tests => 2;
    my $mock = MockNats->new(run => sub {
        my ($l) = @_;
        my $c = $l->accept or return;
        $c->autoflush(1);
        MockNats->handshake($c) or return;
        close $l;
        select undef, undef, undef, 0.2;
        close $c;
        sleep 3;
    })->start;
    close $mock->{srv};    # the parent's copy would still accept the retry

    my ($nats, @got, $croaked, $armed);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        reconnect => 1, reconnect_delay => 300, max_reconnect_attempts => 1,
        on_error      => sub { },
        on_disconnect => sub {
            return if $armed++;
            my $t; $t = EV::timer 0, 0, sub {
                undef $t;
                $croaked = !eval { $nats->flush(sub { push @got, $_[0]; EV::break }); 1 };
            };
        },
    );
    run_guarded(5);
    ok !$croaked, 'flush while reconnecting queued';
    is_deeply \@got, ['disconnected'], 'and failed with the attempt';
    $nats->disconnect;
    $mock->stop;
};

subtest 'a queued flush fails when reconnecting gives up' => sub {
    plan tests => 2;
    my @got;
    my $nats = EV::Nats->new(
        path => "/nonexistent-ev-nats-$$.sock",
        reconnect => 1, reconnect_delay => 100, max_reconnect_attempts => 1,
        on_error => sub { },
    );
    ok eval { $nats->flush(sub { push @got, $_[0]; EV::break }); 1 }, 'queued';
    run_guarded(3);
    is_deeply \@got, ['disconnected'], 'failed once no attempt was left';
};

subtest 'reconnect(0) fails a flush waiting for the reconnect' => sub {
    plan tests => 2;
    my @got;
    my $nats = EV::Nats->new(
        path => "/nonexistent-ev-nats-$$.sock",
        reconnect => 1, reconnect_delay => 10_000,
        on_error => sub { },
    );
    $nats->flush(sub { push @got, $_[0] });
    is scalar @got, 0, 'queued';
    $nats->reconnect(0);
    is_deeply \@got, ['disconnected'], 'failed once reconnecting stopped';
};

subtest 'inbox_prefix' => sub {
    plan tests => 5;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $buf = $rd->(qr/PUB svc (\S+) 1\r\nq\r\n/) or return;
        my ($reply) = $buf =~ /PUB svc (\S+) /;
        my ($wild, $sid) = %{ MockNats->subs_in($buf) };
        print $report "$wild $reply\n";
        syswrite $c, MockNats->msg_frame($reply, $sid, undef, 'a');
        sleep 2;
    })->start;

    my ($nats, @got);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        inbox_prefix => '_INBOX_w1',
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub { $nats->request('svc', 'q', sub { @got = @_; EV::break }, 3000) },
    );
    like $nats->new_inbox, qr/\A_INBOX_w1\.[0-9a-f]{16}\.\d+\z/, 'new_inbox';
    run_guarded(5);
    like $mock->report(5), qr/\A_INBOX_w1\.[0-9a-f]{16}\.\* _INBOX_w1\.[0-9a-f]{16}\.\d+\z/,
        'request inbox subscription and reply subject';
    is $got[0], 'a', 'the reply was routed';
    my @bad = grep { !eval { EV::Nats->new(inbox_prefix => $_); 1 } }
        ('', 'a.*', 'a.>', 'a..b', '.a', 'a.', 'a b', 'x' x 65);
    is scalar @bad, 8, 'invalid prefixes croak';
    like(EV::Nats->new(inbox_prefix => undef)->new_inbox, qr/\A_INBOX\./, 'undef keeps the default');
    $nats->disconnect;
    $mock->stop;
};

subtest 'new_inbox is outside the request wildcard' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $buf = MockNats->read_until($c, qr/SUB \S+\.\* \d+\r\n/) or return;
        my ($wild) = $buf =~ /SUB (\S+\.\*) \d+\r\n/;
        print $report "$wild\n";
    })->start;
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub { $nats->request('svc', 'x', sub {}, 1000) },
    );
    run_guarded(1);
    my $wild = $mock->report(5);
    like $wild, qr/\A_INBOX\.\S+\.\*\z/, 'the request wildcard was seen';
    (my $re = quotemeta $wild) =~ s/\\\*\z/[^.]+/;
    unlike $nats->new_inbox, qr/\A$re\z/, "a new_inbox subject is not matched by $wild";
    $nats->disconnect;
    $mock->stop;
};

subtest 'a request made while connecting survives a failed attempt' => sub {
    plan tests => 2;
    my $mock = MockNats->new(run => sub {
        my ($srv) = @_;
        my $first = $srv->accept or return;
        close $first;
        my $c = $srv->accept or return;
        $c->autoflush(1);
        my $hs = MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $buf = $rd->(qr/PUB svc (\S+) 1\r\nx\r\n/) or return;
        my ($reply) = $buf =~ /PUB svc (\S+) /;
        my ($sid) = values %{ MockNats->subs_in($hs . $buf) };
        syswrite $c, MockNats->msg_frame($reply, $sid, undef, 'pong');
        sleep 2;
    })->start;
    my @got;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        reconnect => 1, reconnect_delay => 100,
        on_error => sub {},
    );
    $nats->request('svc', 'x', sub { push @got, [@_]; EV::break }, 5000);
    run_guarded(4);
    is scalar @got, 1, 'answered once';
    is_deeply [ @{ $got[0] || [] }[0, 1] ], ['pong', undef], 'with the reply, not "disconnected"';
    $nats->disconnect;
    $mock->stop;
};

subtest 'a completed drain drops its subscriptions' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        MockNats->read_until($c, qr/UNSUB \d+\r\nPING\r\n/) or return;
        syswrite $c, "PONG\r\n";
        sleep 2;
    })->start;
    my ($nats, $drained);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $nats->subscribe('d', sub {});
            $nats->drain(sub { $drained = 1; EV::break });
        },
    );
    run_guarded(3);
    ok $drained, 'drained';
    is $nats->subscription_count, 0, 'nothing left to resubscribe on a later connect';
    $mock->stop;
};

subtest 'a subscription dropped during an outage is not resurrected' => sub {
    plan tests => 2;
    my $mock = MockNats->new(run => sub {
        my ($srv, $report) = @_;
        my $c1 = $srv->accept or return;
        MockNats->send_info($c1);
        MockNats->read_until($c1, qr/PING\r\n/) or return;   # CONNECT sent, never PONGed
        print $report (MockNats->read_until($c1, qr/SUB ghost/, 2) ? "sent\n" : "held\n");
        close $c1;
        my $c2 = $srv->accept or return;
        $c2->autoflush(1);
        my $buf = MockNats->handshake($c2) or return;
        $buf .= MockNats->read_until($c2, qr/SUB ghost/, 1) // '';
        print $report ($buf =~ /SUB ghost/ ? "ghost\n" : "clean\n");
        sleep 1;
    })->start;
    my ($nats, $sid);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port, reconnect => 1, reconnect_delay => 100,
        on_error      => sub {},
        on_disconnect => sub { $nats->unsubscribe($sid) if defined $sid; undef $sid },
    );
    my $t = EV::timer 0.3, 0, sub { $sid = $nats->subscribe('ghost.subj', sub {}, 'grp') };
    run_guarded(4);
    is $mock->report(5), 'sent', 'a SUB made after CONNECT follows it';
    is $mock->report(5), 'clean', 'and is not replayed once unsubscribed';
    $nats->disconnect;
    $mock->stop;
};

subtest 'queued requests fail when no attempt is left to carry them' => sub {
    plan tests => 3;
    my $mock = MockNats->new(on_accept => sub { close $_[0] })->start;
    my @got;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port, reconnect => 0,
        on_error => sub {},
    );
    $nats->request('svc', 'x', sub { push @got, $_[1]; EV::break }, 0);
    run_guarded(2);
    is_deeply \@got, ['disconnected'], 'reported at once';
    is $nats->waiting_count, 0, 'its PUB left the queue';
    ok !$nats->is_connected, 'down';
    $mock->stop;
};

subtest 'a flush awaited in a nested loop inside on_connect completes' => sub {
    plan tests => 1;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        $rd->(qr/PING\r\n/) and syswrite $c, "PONG\r\n";
        sleep 3;
    })->start;
    my ($nats, $flushed, $in_time);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $nats->flush(sub { $flushed = 1; EV::break });
            my $g = EV::timer 2, 0, sub { EV::break };
            EV::run;   # as a synchronous wait on AnyEvent's EV backend does
            $in_time = $flushed;
            EV::break;
        },
    );
    run_guarded(4);
    ok $in_time, 'its PONG was matched to it inside on_connect, not to the handshake';
    $nats->disconnect;
    $mock->stop;
};

subtest 'a callback that dies leaves the client consistent' => sub {
    plan tests => 4;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        my $buf = MockNats->read_until($c, qr/SUB d \d+\r\n/) or return;
        my ($sid) = $buf =~ /SUB d (\d+)/;
        syswrite $c, join '', map { MockNats->msg_frame('d', $sid, undef, $_) } 1 .. 3;
        sleep 3;
    })->start;
    my ($nats, @got);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $nats->subscribe('d', sub { push @got, $_[1]; die "boom\n" if $_[1] eq '1' });
        },
    );
    eval { run_guarded(2) };
    like $@, qr/\Aboom/, 'the die reaches the caller of EV::run';
    run_guarded(0.5);
    is_deeply \@got, [1, 2, 3], 'each message delivered once';
    ok $nats->is_connected, 'still connected';
    Scalar::Util::weaken(my $weak = $nats);
    $nats->disconnect;
    undef $nats;
    ok !$weak, 'and the object can still be freed';
    $mock->stop;
};

subtest 'a dying on_disconnect does not stop the reconnect' => sub {
    plan tests => 2;
    my $mock = MockNats->new(run => sub {
        my ($srv) = @_;
        my $c1 = $srv->accept or return;
        MockNats->handshake($c1) or return;
        close $c1;
        my $c2 = $srv->accept or return;
        MockNats->handshake($c2) or return;
        sleep 3;
    })->start;
    my ($connects, $died) = (0, 0);
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port, reconnect => 1, reconnect_delay => 100,
        on_error      => sub {},
        on_connect    => sub { EV::break if ++$connects == 2 },
        on_disconnect => sub { die "down\n" unless $died++ },
    );
    eval { run_guarded(3) };
    like $@, qr/\Adown/, 'the die surfaced';
    run_guarded(3) if $connects < 2;
    is $connects, 2, 'and the reconnect still happened';
    $nats->disconnect;
    $mock->stop;
};

subtest 'CONNECT carries encoded credentials as given' => sub {
    plan tests => 1;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        my $buf = MockNats->handshake($c) or return;
        my ($pass) = $buf =~ /"pass":"([^"]*)"/;
        print $report unpack('H*', $pass // ''), "\n";
    })->start;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port, user => 'u',
        pass => "p\xc3\xa4ss",   # UTF-8 bytes, as from %ENV or a file
        on_error => sub {},
    );
    run_guarded(1);
    is $mock->report(5), '70c3a47373', 'not encoded twice';
    $nats->disconnect;
    $mock->stop;
};

subtest 'what callbacks publish while draining goes out before the disconnect' => sub {
    plan tests => 9;
    for my $sub_ends (qw(no self max1)) {
        my $mock = MockNats->new(on_accept => sub {
            my ($c, $report) = @_;
            MockNats->handshake($c) or return;
            my $rd = MockNats->reader($c);
            my $buf = $rd->(qr/SUB svc \d+\r\n.*PING\r\n/s) or return;
            my ($sid) = $buf =~ /SUB svc (\d+)/;
            # the in-flight request arrives in the same read as the drain's PONG
            syswrite $c, MockNats->msg_frame('svc', $sid, 'reply.1', 'q1') . "PONG\r\n";
            my $all = $rd->(qr/PUB reply\.1 5\r\nre:q1\r\n.*PING\r\n/s, 3);
            syswrite $c, "PONG\r\n" if $all;
            print $report ($all ? "reply sent\n" : "reply lost\n");
            sleep 1;
        })->start;
        my ($nats, $sid, $handled, $drained);
        $nats = EV::Nats->new(
            host => '127.0.0.1', port => $mock->port,
            on_error   => sub { diag "error: @_" },
            on_connect => sub {
                $sid = $nats->subscribe('svc', sub {
                    $handled++;
                    $nats->publish($_[2], "re:$_[1]");
                    $nats->unsubscribe($sid) if $sub_ends eq 'self';
                });
                $nats->unsubscribe($sid, 1) if $sub_ends eq 'max1';
                $nats->drain(sub { $drained = $_[0] // 'ok'; EV::break });
            },
        );
        run_guarded(5);
        is $handled, 1, "unsubscribed $sub_ends: the in-flight request reached its callback";
        is $drained, 'ok', "unsubscribed $sub_ends: drain completed";
        is $mock->report(5), 'reply sent', "unsubscribed $sub_ends: its reply went out first";
        $mock->stop;
    }
};

subtest 'a die in a callback run by a failing write does not stop the reconnect' => sub {
    plan tests => 9;
    require Socket;
    local $SIG{PIPE} = 'IGNORE';
    for my $method (qw(flush ping drain)) {
        my $mock = MockNats->new(run => sub {
            my ($srv) = @_;
            my $c = $srv->accept or return;
            MockNats->handshake($c) or return;
            select undef, undef, undef, 0.3;
            setsockopt($c, Socket::SOL_SOCKET(), Socket::SO_LINGER(), pack('ii', 1, 0));
            close $c;   # RST
            my $c2 = $srv->accept or return;
            MockNats->handshake($c2) or return;
            sleep 3;
        })->start;
        my ($connects, @got) = (0);
        my $nats = EV::Nats->new(
            host => '127.0.0.1', port => $mock->port, reconnect => 1, reconnect_delay => 100,
            on_error   => sub {},
            on_connect => sub { $connects++; EV::break },
        );
        run_guarded(2);
        $nats->request('a', 'x', sub { push @got, 'a'; die "boom\n" }, 0);
        $nats->request('b', 'x', sub { push @got, 'b' }, 0);
        select undef, undef, undef, 0.8;   # the RST lands while the loop is not running
        eval { $method eq 'ping' ? $nats->ping : $nats->$method(sub {}) };
        like $@, qr/\Aboom/, "$method: the die reached the caller";
        is_deeply \@got, ['a', 'b'], "$method: the other request was still failed";
        my $t = EV::timer 0.05, 0.05, sub { EV::break if $connects >= 2 };
        run_guarded(3);
        is $connects, 2, "$method: and the client reconnected";
        $nats->disconnect;
        $mock->stop;
    }
};

subtest 'a die in a callback run by disconnect() still lets it finish' => sub {
    plan tests => 3;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        sleep 3;
    })->start;
    my (@got, $disconnects);
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error      => sub {},
        on_disconnect => sub { $disconnects++ },
        on_connect    => sub { EV::break },
    );
    run_guarded(2);
    $nats->request('a', 'x', sub { push @got, 'a'; die "boom\n" }, 0);
    $nats->request('b', 'x', sub { push @got, 'b' }, 0);
    eval { $nats->disconnect };
    like $@, qr/\Aboom/, 'the die reached the caller';
    is_deeply \@got, ['a', 'b'], 'the other request was still failed';
    is $disconnects, 1, 'and on_disconnect ran';
    $mock->stop;
};

subtest 'a refused attempt reports through on_error, not on_disconnect' => sub {
    plan tests => 2;
    my $port = do {
        my $s = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, Proto => 'tcp');
        my $p = $s->sockport;
        close $s;
        $p;
    };
    my ($errors, $disconnects) = (0, 0);
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $port, reconnect => 1, reconnect_delay => 100,
        on_error => sub { $errors++ }, on_disconnect => sub { $disconnects++ },
    );
    run_guarded(1);
    ok $errors > 1, 'several attempts failed';
    is $disconnects, 0, 'none of them was a drop';
    $nats->disconnect;
};

subtest 'on_error may replace the connection inline' => sub {
    plan tests => 2;
    my $mock = MockNats->new(run => sub {
        my ($srv) = @_;
        my $first = $srv->accept or return;
        MockNats->send_info($first);
        MockNats->read_until($first, qr/PING\r\n/) or return;
        syswrite $first, "-ERR 'Unknown Protocol Operation'\r\n";
        my $c = $srv->accept or return;
        MockNats->handshake($c) or return;
        sleep 2;
    })->start;
    my ($nats, $connects, $disconnects) = (undef, 0, 0);
    my $port = $mock->port;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $port, reconnect => 0,
        on_error => sub {
            return unless $_[0] =~ /Unknown Protocol/;
            $nats->disconnect;
            $nats->connect('127.0.0.1', $port);
        },
        on_connect    => sub { $connects++; EV::break },
        on_disconnect => sub { $disconnects++ },
    );
    run_guarded(3);
    is $connects, 1, 'the replacement connected';
    ok $nats->is_connected, 'and was not torn down behind the handler';
    $nats->disconnect;
    $mock->stop;
};

done_testing;
