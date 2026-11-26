use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::KV;
use MockNats;
use Scalar::Util ();
use Time::HiRes ();

# JetStream fetch, acks and API errors against a forked mock server.

sub run_guarded {
    my ($seconds) = @_;
    EV::now_update;
    my $g = EV::timer $seconds, 0, sub { EV::break };
    EV::run;
}

sub mono { Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC()) }

my $NEXT = qr/PUB \$JS\.API\.CONSUMER\.MSG\.NEXT\.S\.C (\S+) \d+\r\n[^\r]*\r\n/;

subtest 'with_status passes the ending server status as code and description' => sub {
    plan tests => 9;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $n = 0;
        my $next = sub {
            $n++;
            my $buf = $rd->(qr/(?:.*?$NEXT){$n}/s) or return;
            my @inboxes = $buf =~ /$NEXT/g;
            return ($inboxes[-1], MockNats->subs_in($buf)->{ $inboxes[-1] });
        };
        my ($inbox, $sid) = $next->() or return;
        syswrite $c, MockNats->hmsg_frame($inbox, $sid, undef, "NATS/1.0 404 No Messages\r\n\r\n");
        ($inbox, $sid) = $next->() or return;
        syswrite $c, MockNats->msg_frame($inbox, $sid, 'ack.r1', 'm1');
        syswrite $c, MockNats->hmsg_frame($inbox, $sid, undef, "NATS/1.0 409 Server Shutdown\r\n\r\n");
        print $report ($rd->(qr/PUB ack\.r1 4\r\n-NAK\r\n/) ? "nak\n" : "no-nak\n");
        for my $st ("404 No Messages", "409 Consumer Deleted") {
            ($inbox, $sid) = $next->() or return;
            syswrite $c, MockNats->hmsg_frame($inbox, $sid, undef, "NATS/1.0 $st\r\n\r\n");
        }
    })->start;

    my ($nats, $js, $plain, @got, @plain);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $js->fetch('S', 'C', { batch => 1 }, sub {
                push @got, [@_];
                $js->fetch('S', 'C', { batch => 2 }, sub {
                    push @got, [@_];
                    $plain->fetch('S', 'C', { batch => 1 }, sub {
                        push @plain, scalar @_;
                        $plain->fetch('S', 'C', { batch => 1 }, sub {
                            push @plain, scalar @_;
                            $nats->flush(sub { EV::break });
                        });
                    });
                });
            });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats, with_status => 1);
    $plain = EV::Nats::JetStream->new(nats => $nats);
    run_guarded(10);
    is scalar @got, 2, 'both fetches answered';
    is_deeply $got[0][0], [], '404: empty batch';
    is_deeply $got[0][2], { code => 404, description => 'No Messages' }, '404: status';
    is $got[1][0], undef, '409: no messages';
    is $got[1][1], 'fetch failed: NATS/1.0 409 Server Shutdown', '409: error string unchanged';
    is_deeply $got[1][2], { code => 409, description => 'Server Shutdown' }, '409: status';
    is $mock->report(5), 'nak', 'message received before the 409 was -NAKed';
    is scalar @plain, 2, 'without with_status: answered';
    is_deeply \@plain, [2, 2], 'without with_status: callbacks get two arguments';
    $mock->stop;
};

subtest 'a dropped connection fails the fetch and -NAKs late deliveries' => sub {
    plan tests => 5;
    my $mock = MockNats->new(run => sub {
        my ($l, $report) = @_;
        my $c1 = $l->accept or return;
        $c1->autoflush(1);
        MockNats->handshake($c1) or return;
        my $buf = MockNats->reader($c1)->($NEXT) or return;
        my ($inbox) = $buf =~ $NEXT;
        my $sid = MockNats->subs_in($buf)->{$inbox};
        close $c1;
        my $c2 = $l->accept or return;
        $c2->autoflush(1);
        my $hs = MockNats->handshake($c2) or return;
        my $resub = MockNats->subs_in($hs)->{$inbox} // 'none';
        print $report ($resub eq $sid ? "resub\n" : "resub=$resub\n");
        syswrite $c2, MockNats->msg_frame($inbox, $sid, 'ack.late', 'late');
        my $rd = MockNats->reader($c2);
        print $report ($rd->(qr/PUB ack\.late 4\r\n-NAK\r\n/) ? "nak\n" : "no-nak\n");
        sleep 3;
    })->start;

    my ($nats, $js, @events, $started);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        reconnect => 1, reconnect_delay => 100,
        on_error      => sub { },
        on_disconnect => sub { push @events, 'on_disconnect' },
        on_connect    => sub {
            return if $started++;
            $js->fetch('S', 'C', { batch => 1, expires => 20_000_000_000 }, sub {
                push @events, 'cb:' . (defined $_[0] ? 'msgs' : 'undef') . ':' . ($_[1] // '');
            });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats);
    my $t0 = mono();
    my $first;
    my $w = EV::timer 0.05, 0.05, sub { $first //= mono() if @events > 1 };
    run_guarded(3);
    is_deeply \@events, ['on_disconnect', 'cb:undef:disconnected'],
        'the fetch failed once, from the loop after on_disconnect';
    ok defined $first && $first - $t0 < 2, 'without waiting for the fetch timer';
    is $mock->report(5), 'resub', 'the inbox was resubscribed after the reconnect';
    is $mock->report(5), 'nak', 'a message that still arrived was -NAKed';
    is scalar @events, 2, 'the callback did not fire again';
    $nats->disconnect;
    $mock->stop;
};

subtest 'cancel suppresses the callback and keeps -NAKing until the pull ends' => sub {
    plan tests => 4;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $buf = $rd->(qr/$NEXT.*PING\r\n/s) or return;
        my ($inbox) = $buf =~ $NEXT;
        my $sid = MockNats->subs_in($buf)->{$inbox};
        syswrite $c, "PONG\r\n";
        select undef, undef, undef, 0.3;
        syswrite $c, MockNats->msg_frame($inbox, $sid, 'ack.c1', 'c1');
        print $report ($rd->(qr/PUB ack\.c1 4\r\n-NAK\r\n/) ? "nak\n" : "no-nak\n");
        syswrite $c, MockNats->hmsg_frame($inbox, $sid, undef, "NATS/1.0 408 Request Timeout\r\n\r\n");
        print $report ($rd->(qr/UNSUB $sid\r\n/) ? "unsub\n" : "no-unsub\n");
    })->start;

    my ($nats, $js, $called);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            my $h = $js->fetch('S', 'C', { batch => 2, expires => 20_000_000_000 }, sub { $called++ });
            isa_ok $h, 'EV::Nats::JetStream::Fetch';
            $nats->flush(sub { $h->cancel; $h->cancel });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats);
    run_guarded(2.5);
    is $mock->report(5), 'nak', 'a message arriving after cancel was -NAKed';
    is $mock->report(5), 'unsub', 'the inbox was dropped once the server ended the pull';
    ok !$called, 'the callback never fired';
    $nats->disconnect;
    $mock->stop;
};

subtest 'ack helpers publish the JetStream ack protocol' => sub {
    plan tests => 6;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $buf = MockNats->reader($c)->(qr/PING\r\n/) or return;
        syswrite $c, "PONG\r\n";
        my @pubs;
        push @pubs, "$1=$2" while $buf =~ /^PUB (\S+) \d+\r\n([^\r]*)\r$/mg;
        print $report join('|', @pubs), "\n";
    })->start;

    my ($nats, $js, @ret);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            push @ret, $js->ack({ reply => 'r.1' });
            push @ret, $js->nak({ reply => 'r.2' });
            push @ret, $js->nak('r.3', 5_000_000_000);
            push @ret, $js->in_progress({ reply => 'r.4' });
            push @ret, $js->term({ reply => 'r.5' }, 'bad input');
            push @ret, $js->term('r.6');
            $nats->flush(sub { EV::break });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats);
    run_guarded(5);
    is_deeply \@ret, [1, 1, 1, 1, 1, 1], 'each helper reported the ack sent';
    is $mock->report(5),
        'r.1=+ACK|r.2=-NAK|r.3=-NAK {"delay":5000000000}|r.4=+WPI|r.5=+TERM bad input|r.6=+TERM',
        'wire bodies';
    ok !eval { $js->ack({}); 1 }, 'a message without a reply subject dies';
    ok !eval { $js->nak('r.7', '1.5s'); 1 }, 'a non-integer delay dies';
    $nats->disconnect;
    is $js->ack('r.8'), 0, 'an ack that cannot be sent returns false';
    like $@, qr/not connected/, '... with the reason in $@';
    $mock->stop;
};

subtest 'a no_wait fetch nobody answers ends after the API timeout' => sub {
    plan tests => 4;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        MockNats->reader($c)->(qr/\A(?!)/, 4);
    })->start;

    my ($nats, $js, $got, $t0, $dt);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $t0 = mono();
            $js->fetch('S', 'C', { batch => 1, no_wait => 1 }, sub {
                ($got, $dt) = ([@_], mono() - $t0);
                EV::break;
            });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats, timeout => 300);
    run_guarded(5);
    is_deeply $got->[0], [], 'empty batch';
    ok !defined $got->[1] && !defined $got->[2], 'no error and no status';
    ok $dt >= 0.25, 'waited for the API timeout';
    ok $dt < 2, 'and no longer';
    $nats->disconnect;
    $mock->stop;
};

subtest 'js_publish_h and KV writes fail with disconnected, not a timeout' => sub {
    plan tests => 3;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        MockNats->reader($c)->(qr/HPUB .*HPUB /s) or return;
        close $c;
    })->start;

    my ($nats, $js, @got, $t0);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { },
        on_connect => sub {
            $t0 = mono();
            $js->js_publish_h('s.x', "NATS/1.0\r\nX: 1\r\n\r\n", 'p', sub { push @got, $_[1] });
            EV::Nats::KV->new(js => $js, bucket => 'b')->create('k', 'v', sub { push @got, $_[1] });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats, timeout => 4000);
    my $w = EV::timer 0.05, 0.05, sub { EV::break if @got == 2 };
    run_guarded(6);
    is $got[0], 'disconnected', 'js_publish_h';
    is $got[1], 'disconnected', 'KV create';
    ok mono() - $t0 < 2, 'without waiting for the timeout';
    $mock->stop;
};

subtest 'a write that croaks leaves no reference cycle' => sub {
    plan tests => 3;
    my $nats = EV::Nats->new(on_error => sub { });
    my $js = EV::Nats::JetStream->new(nats => $nats);
    my $kv = EV::Nats::KV->new(js => $js, bucket => 'b');
    ok !eval { $js->js_publish_h('s', "NATS/1.0\r\n\r\n", 'x', sub { }); 1 }, 'js_publish_h croaks while down';
    ok !eval { $kv->update('k', 'v', 1, sub { }); 1 }, 'KV update croaks while down';
    Scalar::Util::weaken(my $weak = $nats);
    undef $_ for $kv, $js, $nats;
    ok !defined $weak, 'the connection was freed';
};

subtest 'js_publish_h reports a 503 as no responders' => sub {
    plan tests => 1;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        my $hpub = qr/HPUB s\.x (\S+) \d+ \d+\r\n/;
        my $buf = MockNats->reader($c)->($hpub) or return;
        my ($inbox) = $buf =~ $hpub;
        my ($sid) = values %{ MockNats->subs_in($buf) };
        syswrite $c, MockNats->hmsg_frame($inbox, $sid, undef, "NATS/1.0 503\r\n\r\n");
        sleep 2;
    })->start;

    my ($nats, $js, @got);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $js->js_publish_h('s.x', "NATS/1.0\r\nX: 1\r\n\r\n", 'p', sub { @got = @_; EV::break });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats);
    run_guarded(5);
    is_deeply \@got, [undef, 'no responders'], 'error';
    $nats->disconnect;
    $mock->stop;
};

subtest 'API errors carry the server error object; KV get_entry has the revision' => sub {
    plan tests => 7;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $req = qr/PUB \$JS\.API\.(\S+) (\S+) \d+\r\n[^\r]*\r\n/;
        my $buf = $rd->($req) or return;
        my $sid = (values %{ MockNats->subs_in($buf) })[0];
        my ($api, $reply) = $buf =~ $req;
        syswrite $c, MockNats->msg_frame($reply, $sid, undef,
            '{"error":{"code":404,"err_code":10014,"description":"consumer not found"}}');
        for my $n (2 .. 5) {
            $buf = $rd->(qr/(?:.*?$req){$n}/s) or return;
            my @r = $buf =~ /$req/g;
            syswrite $c, MockNats->msg_frame($r[-1], $sid, undef, $n == 2 || $n == 5
                ? '{"error":{"code":404,"err_code":10014,"description":"consumer not found"}}'
                : '{"message":{"subject":"$KV.b.k","seq":7,"data":"dg=="}}');
        }
        sleep 2;
    })->start;

    my ($nats, $js, $plain, @info, @plain_info, @entry, @get, @bucket);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $js->consumer_info('S', 'C', sub {
                @info = @_;
                $plain->consumer_info('S', 'C', sub {
                    @plain_info = @_;
                    my $kv = EV::Nats::KV->new(js => $plain, bucket => 'b');
                    $kv->get_entry('k', sub {
                        @entry = @_;
                        $kv->get('k', sub {
                            @get = @_;
                            EV::Nats::KV->new(js => $js, bucket => 'b')->delete_bucket(sub {
                                @bucket = @_;
                                EV::break;
                            });
                        });
                    });
                });
            });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats, with_status => 1);
    $plain = EV::Nats::JetStream->new(nats => $nats);
    run_guarded(5);
    is $info[1], 'consumer not found (code 404)', 'error string unchanged';
    is_deeply $info[2], { code => 404, err_code => 10014, description => 'consumer not found' },
        'error object';
    is scalar @plain_info, 2, 'without with_status: two arguments';
    is_deeply $entry[0], { value => 'v', revision => 7 }, 'KV entry';
    is $get[0], 'v', 'KV get value';
    is scalar @get, 2, 'KV get: two arguments';
    is scalar @bucket, 2, 'KV bucket callbacks get two arguments even with with_status';
    $nats->disconnect;
    $mock->stop;
};

done_testing;
