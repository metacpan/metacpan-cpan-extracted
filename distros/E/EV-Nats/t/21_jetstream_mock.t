use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::KV;
use EV::Nats::ObjectStore;
use JSON::PP ();
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
        for my $n (1 .. 6) {
            my $buf = $rd->(qr/(?:.*?$req){$n}/s) or return;
            my ($sid) = values %{ MockNats->subs_in($buf) };
            my ($api, $reply) = ($buf =~ /$req/g)[-2, -1];
            syswrite $c, MockNats->msg_frame($reply, $sid, undef,
                  $api =~ /^STREAM\.INFO\./    ? '{"config":{"name":"KV_b"}}'
                : $api =~ /^STREAM\.MSG\.GET\./ ? '{"message":{"subject":"$KV.b.k","seq":7,"data":"dg=="}}'
                : '{"error":{"code":404,"err_code":10014,"description":"consumer not found"}}');
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

subtest 'get_msg reads raw bytes with Direct Get and falls back without it' => sub {
    plan tests => 6;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $req = qr/PUB \$JS\.API\.(\S+) (\S+) \d+\r\n([^\r]*)\r\n/;
        my @apis;
        for my $n (1 .. 6) {
            my $buf = $rd->(qr/(?:.*?$req){$n}/s) or last;
            my ($sid) = values %{ MockNats->subs_in($buf) };
            my ($api, $reply, $body) = ($buf =~ /$req/g)[-3 .. -1];
            push @apis, $api =~ /^(\w+\.\w+)/ ? $1 : $api;
            my $frame;
            if ($api eq 'STREAM.INFO.D') {
                $frame = MockNats->msg_frame($reply, $sid, undef, '{"config":{"name":"D","allow_direct":true}}');
            } elsif ($api eq 'STREAM.MSG.GET.D') {
                $frame = MockNats->msg_frame($reply, $sid, undef,
                    '{"message":{"subject":"D.gone","seq":9,"data":"AHJhd/8=","hdrs":"TkFUUy8xLjANClg6IDENCg0K"}}');
            } elsif ($body =~ /D\.k/) {
                $frame = MockNats->hmsg_frame($reply, $sid, undef,
                    "NATS/1.0\r\nX-Orig: 1\r\nNats-Stream: D\r\nNats-Subject: D.k\r\nNats-Sequence: 5\r\n"
                    . "Nats-Time-Stamp: 2026-11-26T00:00:00Z\r\n\r\n", "\x00raw\xff");
            } elsif ($body =~ /D\.none/) {
                $frame = MockNats->hmsg_frame($reply, $sid, undef, "NATS/1.0 404 Message Not Found\r\n\r\n");
            } elsif ($body eq '{}') {
                $frame = MockNats->hmsg_frame($reply, $sid, undef, "NATS/1.0 408 Empty Request\r\n\r\n");
            } else {
                $frame = MockNats->hmsg_frame($reply, $sid, undef, "NATS/1.0 503\r\n\r\n");
            }
            syswrite $c, $frame;
        }
        print $report join(',', @apis), "\n";
    })->start;

    my ($nats, $js, @k, @none, @bad, @gone);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $js->get_msg('D', { last_by_subj => 'D.k' }, sub {
                @k = @_;
                $js->direct_get('D', { last_by_subj => 'D.none' }, sub {
                    @none = @_;
                    $js->direct_get('D', {}, sub {
                        @bad = @_;
                        $js->get_msg('D', { last_by_subj => 'D.gone' }, sub { @gone = @_; EV::break });
                    });
                });
            });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats);
    run_guarded(5);
    is_deeply [@{ $k[0] }{qw(subject seq time data)}], ['D.k', 5, '2026-11-26T00:00:00Z', "\x00raw\xff"],
        'Direct Get: raw payload and parsed Nats-* headers';
    like $k[0]{headers}, qr/^X-Orig: 1\r$/m, 'the stored headers are kept';
    is_deeply \@none, [undef, undef], '404 is a clean miss';
    is $bad[1], 'direct get failed: NATS/1.0 408 Empty Request', 'other statuses are errors';
    is_deeply [@{ $gone[0] }{qw(subject seq data headers)}], ['D.gone', 9, "\x00raw\xff", "NATS/1.0\r\nX: 1\r\n\r\n"],
        'no responders falls back to STREAM.MSG.GET, decoded';
    is $mock->report(5), 'STREAM.INFO,DIRECT.GET,DIRECT.GET,DIRECT.GET,DIRECT.GET,STREAM.MSG',
        'stream info asked once, then Direct Get until it stopped answering';
    $nats->disconnect;
    $mock->stop;
};

subtest 'concurrent get_msg calls share one stream info lookup' => sub {
    plan tests => 4;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $req = qr/PUB \$JS\.API\.(\S+) (\S+) \d+\r\n[^\r]*\r\n/;
        my %seen;
        for my $n (1 .. 4) {
            my $buf = $rd->(qr/(?:.*?$req){$n}/s) or last;
            my ($sid) = values %{ MockNats->subs_in($buf) };
            # coalesced requests share a read: answer the n-th, not the last
            my ($api, $reply) = ($buf =~ /$req/g)[2 * $n - 2, 2 * $n - 1];
            $seen{$api =~ /^(\w+\.\w+)/ ? $1 : $api}++;
            syswrite $c, MockNats->msg_frame($reply, $sid, undef, $api =~ /INFO/
                ? '{"config":{"name":"E"}}'
                : '{"message":{"subject":"E.x","seq":1,"data":"eA=="}}');
        }
        print $report join(',', map { "$_=$seen{$_}" } sort keys %seen), "\n";
    })->start;

    my ($nats, $js, @got);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $js->get_msg('E', { seq => 1 }, sub { push @got, $_[0]{data}; EV::break if @got == 3 }) for 1 .. 3;
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats);
    run_guarded(5);
    is_deeply \@got, [qw(x x x)], 'all three answered';
    is $mock->report(5), 'STREAM.INFO=1,STREAM.MSG=3', 'one lookup for three reads';
    $nats->disconnect;
    my $js2 = EV::Nats::JetStream->new(nats => $nats);
    ok !eval { $js2->get_msg('F', { seq => 1 }, sub { }); 1 }, 'croaks while down';
    ok !eval { $js2->get_msg('F', { seq => 1 }, sub { }); 1 }, 'and again: no stranded lookup';
    $mock->stop;
};

subtest 'ack_sync waits for the server to confirm' => sub {
    plan tests => 4;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        my $ack = qr/PUB ack\.s1 (\S+) 4\r\n\+ACK\r\n/;
        my $buf = MockNats->reader($c)->($ack) or return;
        my ($inbox) = $buf =~ $ack;
        my ($sid) = values %{ MockNats->subs_in($buf) };
        syswrite $c, MockNats->msg_frame($inbox, $sid, undef, '');
        sleep 3;
    })->start;

    my ($nats, $js, @ok, @silent);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            $js->ack_sync({ reply => 'ack.s1' }, sub {
                @ok = @_;
                $js->ack_sync('ack.s2', sub { @silent = @_; EV::break }, 200);
            });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats);
    run_guarded(5);
    is_deeply \@ok, [1, undef], 'confirmed';
    is_deeply \@silent, [undef, 'request timeout'], 'no answer times out';
    $nats->disconnect;
    my @down;
    is $js->ack_sync('ack.s3', sub { @down = @_ }), 0, 'returns false when it cannot send';
    EV::run(EV::RUN_NOWAIT) for 1 .. 3;
    is_deeply \@down, [undef, 'not connected'], 'and reports it from the loop';
    $mock->stop;
};

subtest 'with_status reports no responders as 503' => sub {
    plan tests => 1;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        my $pub = qr/PUB s\.x (\S+) \d+\r\n/;
        my $buf = MockNats->reader($c)->($pub) or return;
        my ($inbox) = $buf =~ $pub;
        my ($sid) = values %{ MockNats->subs_in($buf) };
        syswrite $c, MockNats->hmsg_frame($inbox, $sid, undef, "NATS/1.0 503\r\n\r\n");
        sleep 2;
    })->start;

    my ($nats, $js, @got);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub { $js->js_publish('s.x', 'p', sub { @got = @_; EV::break }) },
    );
    $js = EV::Nats::JetStream->new(nats => $nats, with_status => 1);
    run_guarded(5);
    is_deeply \@got, [undef, 'no responders', { code => 503, description => '' }], 'status';
    $nats->disconnect;
    $mock->stop;
};

subtest 'a cancelled fetch on a silent server lets go at its timer' => sub {
    plan tests => 1;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $buf = $rd->(qr/$NEXT.*PING\r\n/s) or return;
        my ($inbox) = $buf =~ $NEXT;
        my $sid = MockNats->subs_in($buf)->{$inbox};
        syswrite $c, "PONG\r\n";
        print $report ($rd->(qr/UNSUB $sid\r\n/, 4) ? "unsub\n" : "no-unsub\n");
    })->start;

    my $nats;
    my $js;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            my $h = $js->fetch('S', 'C', { batch => 1, expires => 100_000_000 }, sub { });
            $nats->flush(sub { $h->cancel });
        },
    );
    $js = EV::Nats::JetStream->new(nats => $nats);
    run_guarded(3);
    is $mock->report(5), 'unsub', 'the inbox was dropped after expires + 1 s';
    $nats->disconnect;
    $mock->stop;
};

subtest 'KV and ObjectStore apply their own timeout to every request' => sub {
    plan tests => 4;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        sleep 5;
    })->start;
    my ($nats, %err, %took);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            my $js = EV::Nats::JetStream->new(nats => $nats, timeout => 3000);
            my $kv = EV::Nats::KV->new(js => $js, bucket => 'b', timeout => 300);
            my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'b', timeout => 300);
            my $t0 = mono();
            my $done = sub { my $k = shift; ($err{$k}, $took{$k}) = ($_[1], mono() - $t0);
                             EV::break if keys %err == 2 };
            $kv->get('k', sub { $done->(kv => @_) });
            $os->info('o', sub { $done->(os => @_) });
        },
    );
    run_guarded(4);
    for my $k (qw(kv os)) {
        like $err{$k} // '', qr/timeout/, "$k timed out";
        cmp_ok $took{$k} // 99, '<', 1.5, "$k used its own 300 ms, not the 3 s of \$js";
    }
    $nats->disconnect;
    $mock->stop;
};

subtest 'a fetch batch passed as a string goes out as a JSON number' => sub {
    plan tests => 1;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $buf = MockNats->read_until($c, $NEXT) or return;
        my ($body) = $buf =~ /CONSUMER\.MSG\.NEXT\.S\.C \S+ \d+\r\n([^\r]*)\r\n/;
        print $report "$body\n";
    })->start;
    my ($nats, $js);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub { $js->fetch('S', 'C', { batch => '2', expires => '100000000' }, sub {}) },
    );
    $js = EV::Nats::JetStream->new(nats => $nats);
    run_guarded(1);
    like $mock->report(5), qr/"batch":2[,}]/, 'batch is a number';
    $nats->disconnect;
    $mock->stop;
};

# answers the first $n requests with $answer->($subject, $body): a payload,
# or [$headers, $payload]; reports the subjects asked
sub api_mock {
    my ($answer, $n) = @_;
    MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $req = qr/PUB (\S+) (\S+) \d+\r\n([^\r]*)\r\n/;
        my @seen;
        for my $i (1 .. $n) {
            # atomic: a plain (?:.*?$req){$i} backtracks combinatorially
            my $buf = $rd->(qr/\A(?>.*?$req){$i}/s) or last;
            my ($sid) = values %{ MockNats->subs_in($buf) };
            my ($subj, $reply, $body) = ($buf =~ /$req/g)[3 * $i - 3 .. 3 * $i - 1];
            push @seen, $subj;
            my $a = $answer->($subj, $body);
            syswrite $c, ref $a ? MockNats->hmsg_frame($reply, $sid, undef, @$a)
                                : MockNats->msg_frame($reply, $sid, undef, $a);
        }
        print $report join(',', @seen), "\n";
    })->start;
}

sub with_js {   # $then->($js) once connected; JetStream options in %opt
    my ($mock, $then, %opt) = @_;
    my $nats;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub { $then->(EV::Nats::JetStream->new(nats => $nats, %opt)) },
    );
    run_guarded(3);
    $nats->disconnect;
}

subtest 'KV writes through a JetStream domain go under its API prefix' => sub {
    plan tests => 1;
    my $mock = api_mock(sub { '{"stream":"KV_B","seq":1}' }, 1);
    with_js($mock, sub {
        EV::Nats::KV->new(js => $_[0], bucket => 'B')->put('k', 'v', sub { EV::break });
    }, prefix => '$JS.hub.API');
    is $mock->report(5), '$JS.hub.API.$KV.B.k', 'as nats.go sends them';
    $mock->stop;
};

subtest 'a server TTL marker reads as a deleted key' => sub {
    plan tests => 1;
    my $mock = api_mock(sub {
        return '{"config":{"name":"KV_B","allow_direct":true}}' if $_[0] =~ /STREAM\.INFO/;
        ["NATS/1.0\r\nNats-Marker-Reason: MaxAge\r\nNats-Stream: KV_B\r\n"
         . "Nats-Subject: \$KV.B.k\r\nNats-Sequence: 3\r\n\r\n", ''];
    }, 2);
    my @got = ('unset');
    with_js($mock, sub {
        EV::Nats::KV->new(js => $_[0], bucket => 'B')->get_entry('k', sub { @got = @_; EV::break });
    });
    is_deeply \@got, [undef, undef], 'a clean miss, not an empty value';
    $mock->stop;
};

# a server list paged as nats-server does: sorted by name, sliced at the
# asked offset, 3 per page; $churn->($names, $n) may change it before answer $n
sub listing_mock {
    my ($kind, $names, $churn) = @_;
    my $n = 0;
    api_mock(sub {
        my (undef, $body) = @_;
        $churn->($names, ++$n) if $churn;
        my $offset = length $body ? JSON::PP::decode_json($body)->{offset} // 0 : 0;
        my @sorted = sort @$names;
        my @page = grep { defined } @sorted[$offset .. $offset + 2];
        my %reply = (total => scalar @sorted, offset => $offset, limit => 3);
        if    ($kind eq 'keys')      { $reply{state}{subjects} = { map { ("\$KV.B.$_" => 1) } @page } }
        elsif ($kind eq 'streams')   { $reply{streams} = [ map { { config => { name => $_ } } } @page ] }
        else                         { $reply{consumers} = [ map { { name => $_ } } @page ] }
        JSON::PP::encode_json(\%reply);
    }, 40);
}

subtest 'paged lists come back whole while they change' => sub {
    my @names = map { sprintf 'c%02d', $_ } 1 .. 8;
    my %calls = (
        keys      => sub { EV::Nats::KV->new(js => $_[0], bucket => 'B')->keys($_[1]) },
        streams   => sub { my ($js, $done) = @_; $js->stream_list(sub {
                               $done->($_[0] && [ map { $_->{config}{name} } @{ $_[0]{streams} } ], $_[1]) }) },
        consumers => sub { my ($js, $done) = @_; $js->consumer_list('S', sub {
                               $done->($_[0] && [ map { $_->{name} } @{ $_[0]{consumers} } ], $_[1]) }) },
    );
    my @cases = (
        [consumers => 'unchanged'],
        [consumers => 'one deleted ahead of the offset', sub { @{ $_[0] } = grep { $_ ne 'c01' } @{ $_[0] } if $_[1] == 2 }],
        [consumers => 'one created ahead of the offset', sub { push @{ $_[0] }, 'a01' if $_[1] == 2 }],
        [streams   => 'one deleted, one created', sub {
            if ($_[1] == 3) { @{ $_[0] } = grep { $_ ne 'c02' } @{ $_[0] }; push @{ $_[0] }, 'b01' } }],
        [keys      => 'one deleted ahead of the offset', sub { @{ $_[0] } = grep { $_ ne 'c03' } @{ $_[0] } if $_[1] == 2 }],
    );
    # every answer moves the list: the relists run out and plain offsets finish it
    push @cases, [consumers => 'changing before every answer', sub { push @{ $_[0] }, sprintf 'a%02d', $_[1] }];
    plan tests => scalar @cases;
    for my $case (@cases) {
        my ($kind, $label, $churn) = @$case;
        my $mock = listing_mock($kind, [@names], $churn);
        my ($got, $err);
        with_js($mock, sub { my $js = shift; $calls{$kind}->($js, sub { ($got, $err) = @_; EV::break }) });
        # the mock churns in its own process: replay it for what existed when
        my %ever = map { $_ => 1 } @names;
        my @list = @names;
        for my $n (1 .. 40) { $churn->(\@list, $n) if $churn; $ever{$_} = 1 for @list }
        my %n; $n{$_}++ for @{ $got || [] };
        my @lasting = grep { my $x = $_; grep { $_ eq $x } @list } @names;
        my @bad = ((grep { ($n{$_} // 0) != 1 } @lasting), (grep { !$ever{$_} } keys %n),
                   (grep { $n{$_} > 1 } keys %n));
        ok $got && !@bad, "$kind, $label: every lasting entry once, nothing invented"
            or diag "got @{ $got || [] }; bad @bad; error " . ($err // 'none') . '; asked ' . $mock->report(5);
        $mock->stop;
    }
};

subtest 'a reply that is not a JSON object reaches the callback' => sub {
    plan tests => 1;
    my $mock = api_mock(sub { '[1]' }, 1);
    my @got;
    with_js($mock, sub { $_[0]->consumer_info('S', 'C', sub { @got = @_; EV::break }) });
    is_deeply \@got, [[1], undef], 'passed through, no die';
    $mock->stop;
};

subtest 'decode_json_or_error' => sub {
    plan tests => 7;
    my $d = \&EV::Nats::JetStream::decode_json_or_error;
    my ($r, $e) = $d->(qq({"t":true,"f":false,"n":null,"s":"\xc3\xa9\\u00e9"}));
    ok !defined $e && $r->{t} && !$r->{f} && !defined $r->{n}, 'booleans and null';
    is $r->{s}, "\x{e9}\x{e9}", 'UTF-8 bytes and escapes decode to characters';
    for my $json ('null', '0', 'false', '""') {
        my (undef, $err) = $d->($json);
        ok !defined $err, "$json is valid";
    }
    (undef, $e) = $d->('{bad');
    like $e, qr/\AJSON decode error: /, 'malformed input reports an error';
};

done_testing;
