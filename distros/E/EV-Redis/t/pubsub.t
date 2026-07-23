use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Redis;
use lib 't/lib';
use RedisTestHelper qw(get_redis_version);

my $subscriber = EV::Redis->new( path => $connect_info{sock} );
my $publisher  = EV::Redis->new( path => $connect_info{sock} );

$subscriber->command('subscribe', 'foo', sub {
    my ($r, $e) = @_;

    # Handle disconnect error callback (expected after disconnect)
    if ($e && !defined $r) {
        pass 'subscription callback received disconnect error';
        return;
    }

    if ($r->[0] eq 'subscribe') {
        is $r->[1], 'foo';

        $publisher->command('publish', 'foo', 'bar', sub {
            my ($r, $e) = @_;
            ok !defined $e, 'no publish error';
            is $r, 1;

            $publisher->disconnect;
        });

    } elsif ($r->[0] eq 'message') {
        is $r->[1], 'foo';
        is $r->[2], 'bar';

        # Unsubscribe callback is silently discarded — hiredis routes the
        # confirmation through the original subscribe callback above.
        $subscriber->unsubscribe('foo');
    } elsif ($r->[0] eq 'unsubscribe') {
        is $r->[1], 'foo';

        $subscriber->disconnect;
    }
});

my $timeout; $timeout = EV::timer 5, 0, sub {
    undef $timeout;
    $subscriber->disconnect;
    $publisher->disconnect;
    EV::break;
};

EV::run;
undef $timeout;  # kill pending timeout: an active leaked timer would EV::break a later EV::run

# Test: multi-channel subscribe
{
    my $subscriber = EV::Redis->new( path => $connect_info{sock} );
    my $publisher  = EV::Redis->new( path => $connect_info{sock} );

    my @received;

    $subscriber->command('subscribe', 'mchan1', 'mchan2', sub {
        my ($r, $e) = @_;

        if ($e && !defined $r) {
            return;
        }

        push @received, $r;

        if ($r->[0] eq 'subscribe' && $r->[2] == 2) {
            $publisher->publish('mchan1', 'msg1', sub {
                $publisher->publish('mchan2', 'msg2', sub {
                    $publisher->disconnect;
                });
            });
        }
        elsif ($r->[0] eq 'message' && $r->[1] eq 'mchan2') {
            $subscriber->unsubscribe('mchan1', 'mchan2');
        }
        elsif ($r->[0] eq 'unsubscribe' && $r->[2] == 0) {
            $subscriber->disconnect;
        }
    });

    my $timeout; $timeout = EV::timer 3, 0, sub {
        undef $timeout;
        $subscriber->disconnect;
        $publisher->disconnect;
        EV::break;
    };

    EV::run;
    undef $timeout;  # kill pending timeout (see above)

    my @subscribe_msgs = grep { $_->[0] eq 'subscribe' } @received;
    is scalar(@subscribe_msgs), 2, 'multi-subscribe: got 2 subscribe confirmations';
    is $subscribe_msgs[0][1], 'mchan1', 'multi-subscribe: first is mchan1';
    is $subscribe_msgs[1][1], 'mchan2', 'multi-subscribe: second is mchan2';

    my @messages = grep { $_->[0] eq 'message' } @received;
    is scalar(@messages), 2, 'multi-subscribe: got 2 messages';
    my %msg_map = map { $_->[1] => $_->[2] } @messages;
    is $msg_map{mchan1}, 'msg1', 'multi-subscribe: mchan1 received msg1';
    is $msg_map{mchan2}, 'msg2', 'multi-subscribe: mchan2 received msg2';

    my @unsub_msgs = grep { $_->[0] eq 'unsubscribe' } @received;
    is scalar(@unsub_msgs), 2, 'multi-subscribe: got 2 unsubscribe confirmations';
}

# Test: psubscribe (pattern subscribe)
{
    my $subscriber = EV::Redis->new( path => $connect_info{sock} );
    my $publisher  = EV::Redis->new( path => $connect_info{sock} );

    my @received;

    $subscriber->psubscribe('test:*', sub {
        my ($r, $e) = @_;

        # Handle disconnect error callback
        if ($e && !defined $r) {
            pass 'psubscribe callback received disconnect error';
            return;
        }

        push @received, $r;

        if ($r->[0] eq 'psubscribe') {
            is $r->[1], 'test:*', 'psubscribe pattern correct';
            is $r->[2], 1, 'psubscribe count correct';

            # Publish to a matching channel
            $publisher->publish('test:foo', 'hello', sub {
                my ($res, $err) = @_;
                is $res, 1, 'publish to pattern-matched channel returned 1 subscriber';
                $publisher->disconnect;
            });

        } elsif ($r->[0] eq 'pmessage') {
            is $r->[1], 'test:*', 'pmessage pattern correct';
            is $r->[2], 'test:foo', 'pmessage channel correct';
            is $r->[3], 'hello', 'pmessage data correct';

            $subscriber->punsubscribe('test:*');
        } elsif ($r->[0] eq 'punsubscribe') {
            is $r->[1], 'test:*', 'punsubscribe pattern correct';
            $subscriber->disconnect;
        }
    });

    EV::run;
}

# Test: monitor command
{
    my $monitor = EV::Redis->new( path => $connect_info{sock} );
    my $client  = EV::Redis->new( path => $connect_info{sock} );

    my @received;
    my $monitor_started = 0;
    my $captured_set = 0;

    $monitor->monitor(sub {
        my ($r, $e) = @_;

        # Handle disconnect error
        if ($e && !defined $r) {
            return;
        }

        push @received, $r;

        if ($r eq 'OK' && !$monitor_started) {
            $monitor_started = 1;
            # Issue a command from another client to see it in monitor
            $client->set('monitor_test_key', 'monitor_test_value', sub {
                $client->disconnect;
            });
        }
        # Check if we captured the SET command
        elsif ($r =~ /SET.*monitor_test_key/i) {
            $captured_set = 1;
            $monitor->disconnect;
            EV::break;
        }
    });

    # Timeout in case monitor doesn't capture command
    my $timeout; $timeout = EV::timer 2, 0, sub {
        undef $timeout;
        $monitor->disconnect;
        $client->disconnect;
        EV::break;
    };

    EV::run;
    undef $timeout;  # kill pending timeout (see above)

    ok $monitor_started, 'monitor command acknowledged with OK';
    ok $captured_set, 'monitor captured SET command';
}

# Test: sharded pub/sub is refused. hiredis has no ssubscribe/smessage
# support: an incoming smessage would abort the process (RESP2 assert) or be
# misrouted to on_push (RESP3), so command() croaks instead of crashing.
# SPUBLISH is a regular command and stays allowed.
{
    # Fetch the version BEFORE creating $r: get_redis_version runs a timerless
    # EV::run that only returns when no active watchers remain; an idle
    # connected $r would keep its read watcher active and hang it forever.
    # (Previously this was masked by a leaked block-4 guard timer whose
    # EV::break ended the helper's loop after ~2s.)
    my ($redis_version) = get_redis_version($connect_info{sock});

    my $r = EV::Redis->new( path => $connect_info{sock} );

    eval { $r->ssubscribe('sharded_channel', sub {}) };
    like $@, qr/ssubscribe is not supported/, 'ssubscribe croaks';

    eval { $r->sunsubscribe('sharded_channel', sub {}) };
    like $@, qr/sunsubscribe is not supported/, 'sunsubscribe croaks';
    SKIP: {
        skip 'spublish requires Redis 7+', 1 if $redis_version < 7;
        my $spublish_res;
        $r->spublish('sharded_channel', 'msg', sub {
            my ($res, $err) = @_;
            $spublish_res = defined $res ? $res : "err:$err";
            EV::break;
        });
        my $timeout; $timeout = EV::timer 2, 0, sub { undef $timeout; EV::break };
        EV::run;
        undef $timeout;  # kill pending timeout (see above)
        is $spublish_res, 0, 'spublish works as a regular command (0 receivers)';
    }
    $r->disconnect;
}

# Test: MONITOR mixing guards — monitor needs an idle connection, and no
# commands may follow while it is active (hiredis repushes callback records
# in monitor mode; mixing would be a use-after-free).
{
    my $r = EV::Redis->new( path => $connect_info{sock} );

    $r->command('set', 'mon_guard_key', 1, sub { EV::break });
    eval { $r->monitor(sub {}) };
    like $@, qr/idle connection/, 'monitor with a pending command croaks';
    EV::run;  # drain the pending SET

    is $r->pending_count, 0, 'connection idle again';
    my $mon_ok;
    $r->monitor(sub {
        my ($res, $err) = @_;
        if (!$mon_ok && defined $res && $res eq 'OK') {
            $mon_ok = 1;
            EV::break;
        }
    });
    my $t1; $t1 = EV::timer 2, 0, sub { undef $t1; EV::break };
    EV::run;
    undef $t1;  # kill pending timeout (see above)
    ok $mon_ok, 'monitor on idle connection works';

    eval { $r->ping(sub {}) };
    like $@, qr/MONITOR is active/, 'command while monitoring croaks';

    # Flag clears with the connection
    $r->disconnect;
    $r->connect_unix($connect_info{sock});
    my $pong;
    $r->ping(sub { $pong = $_[0]; EV::break });
    my $t2; $t2 = EV::timer 2, 0, sub { undef $t2; EV::break };
    EV::run;
    undef $t2;  # kill pending timeout (see above)
    is $pong, 'PONG', 'commands work again after reconnect clears monitor state';
    $r->disconnect;
}

# Test: subscribe with no channels croaks (server would reject it and the
# persistent tracking entry would strand until disconnect).
{
    my $r = EV::Redis->new( path => $connect_info{sock} );
    eval { $r->subscribe(sub {}) };
    like $@, qr/subscribe requires at least one channel/, 'no-arg subscribe croaks';
    eval { $r->psubscribe(sub {}) };
    like $@, qr/psubscribe requires at least one channel/, 'no-arg psubscribe croaks';
    $r->disconnect;
}

# Test: disconnect with active subscription — callback should fire exactly once
# with a meaningful error (not empty string), and not be double-invoked.
{
    my $sub = EV::Redis->new(path => $connect_info{sock});
    my @cb_calls;
    my $subscribed = 0;

    $sub->on_error(sub {}); # suppress

    $sub->subscribe('disconnect_test_ch', sub {
        my ($result, $error) = @_;
        push @cb_calls, [$result, $error];
        if ($result && ref $result eq 'ARRAY' && $result->[0] eq 'subscribe') {
            $subscribed = 1;
            # Disconnect without unsubscribing
            $sub->disconnect;
        }
    });

    my $t; $t = EV::timer 2, 0, sub { undef $t; EV::break };
    EV::run;
    undef $t;  # kill pending timeout (see above)

    ok $subscribed, 'subscribed before disconnect';
    # Expect: subscribe confirmation + exactly one disconnect error
    my @errors = grep { defined $_->[1] } @cb_calls;
    is scalar(@errors), 1, 'subscribe callback invoked exactly once with error on disconnect';
    ok $errors[0][1], 'error string is truthy (not empty)';
    like $errors[0][1], qr/disconnected/, 'error string is "disconnected"';
}

# Test: multi-channel subscribe + disconnect — one error callback total.
# (Historically flaky here: guard timers leaked by earlier blocks — kept
# alive by their self-capturing callbacks — fired their deferred EV::break
# inside this block's run, ending it before the subscriber's read interest
# was registered. Fixed by the undef-after-EV::run lines above; a failure
# here now means a real regression.)
{
    my $sub = EV::Redis->new(path => $connect_info{sock});
    my @cb_calls;
    my $sub_count = 0;

    $sub->on_error(sub { warn "MULTIDC on_error: @_\n" if $ENV{EV_REDIS_DIAG} });

    $sub->subscribe('multi_dc_ch1', 'multi_dc_ch2', sub {
        my ($result, $error) = @_;
        push @cb_calls, [$result, $error];
        if ($result && ref $result eq 'ARRAY' && $result->[0] eq 'subscribe') {
            $sub_count++;
            if ($sub_count == 2) {
                $sub->disconnect;
            }
        }
    });

    my $t; $t = EV::timer 5, 0, sub { undef $t; EV::break };
    EV::run;
    undef $t;  # kill pending timeout (see above)

    is $sub_count, 2, 'both channels subscribed';
    my @errors = grep { defined $_->[1] } @cb_calls;
    # With multi-channel, hiredis fires once per channel on teardown.
    for my $e (@errors) {
        ok $e->[1], 'error string is truthy (not empty)';
    }
    # 2 subscribe confirmations + at most one error per channel;
    # no extra invocation from remove_cb_queue_sv
    ok scalar(@errors) <= 2, 'no more than 2 error callbacks for 2-channel subscribe';
}

done_testing;
