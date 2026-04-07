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

    ok $monitor_started, 'monitor command acknowledged with OK';
    ok $captured_set, 'monitor captured SET command';
}

# Test: ssubscribe (sharded pub/sub, Redis 7+)
# Note: spublish may trigger assertion failure in some hiredis versions
SKIP: {
    my ($redis_version) = get_redis_version($connect_info{sock});

    # Sharded pubsub requires Redis 7.0+
    skip 'ssubscribe requires Redis 7+', 5 if $redis_version < 7;

    # Testing only ssubscribe basic functionality (spublish may cause assertion failure)
    my $subscriber = EV::Redis->new( path => $connect_info{sock} );

    my $subscribed = 0;

    $subscriber->ssubscribe('sharded_channel', sub {
        my ($r, $e) = @_;

        if ($e && !defined $r) {
            return;
        }

        if (ref($r) eq 'ARRAY' && $r->[0] eq 'ssubscribe') {
            is $r->[1], 'sharded_channel', 'ssubscribe channel correct';
            is $r->[2], 1, 'ssubscribe count correct';
            $subscribed = 1;
            # Unsubscribe immediately to avoid state issues
            $subscriber->sunsubscribe('sharded_channel');
        } elsif (ref($r) eq 'ARRAY' && $r->[0] eq 'sunsubscribe') {
            $subscriber->disconnect;
            EV::break;
        }
    });

    my $timeout; $timeout = EV::timer 2, 0, sub {
        undef $timeout;
        $subscriber->disconnect;
        EV::break;
    };

    EV::run;

    ok $subscribed, 'ssubscribe basic functionality works';
    # Skip the spublish/smessage tests due to hiredis compatibility issues
    pass 'skipping spublish test due to hiredis compatibility';
    pass 'skipping smessage test due to hiredis compatibility';
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

    ok $subscribed, 'subscribed before disconnect';
    # Expect: subscribe confirmation + exactly one disconnect error
    my @errors = grep { defined $_->[1] } @cb_calls;
    is scalar(@errors), 1, 'subscribe callback invoked exactly once with error on disconnect';
    ok $errors[0][1], 'error string is truthy (not empty)';
    like $errors[0][1], qr/disconnected/, 'error string is "disconnected"';
}

# Test: multi-channel subscribe + disconnect — one error callback total
{
    my $sub = EV::Redis->new(path => $connect_info{sock});
    my @cb_calls;
    my $sub_count = 0;

    $sub->on_error(sub {}); # suppress

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

    my $t; $t = EV::timer 2, 0, sub { undef $t; EV::break };
    EV::run;

    is $sub_count, 2, 'both channels subscribed';
    my @errors = grep { defined $_->[1] } @cb_calls;
    # With multi-channel, hiredis fires once per channel on teardown.
    # Each should have a meaningful error, no duplicates from remove_cb_queue_sv.
    for my $e (@errors) {
        ok $e->[1], 'error string is truthy (not empty)';
    }
    # Total callbacks: 2 subscribe confirmations + N disconnect errors (one per channel)
    # No extra invocation from remove_cb_queue_sv
    ok scalar(@errors) <= 2, 'no more than 2 error callbacks for 2-channel subscribe';
}

done_testing;
