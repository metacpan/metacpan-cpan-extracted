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

        # hiredis routes the unsubscribe confirmation to the subscribe callback above
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
undef $timeout;  # a leaked active timer would EV::break a later EV::run

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
    undef $timeout;

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

{
    my $subscriber = EV::Redis->new( path => $connect_info{sock} );
    my $publisher  = EV::Redis->new( path => $connect_info{sock} );

    my @received;

    $subscriber->psubscribe('test:*', sub {
        my ($r, $e) = @_;

        if ($e && !defined $r) {
            pass 'psubscribe callback received disconnect error';
            return;
        }

        push @received, $r;

        if ($r->[0] eq 'psubscribe') {
            is $r->[1], 'test:*', 'psubscribe pattern correct';
            is $r->[2], 1, 'psubscribe count correct';

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

{
    my $monitor = EV::Redis->new( path => $connect_info{sock} );
    my $client  = EV::Redis->new( path => $connect_info{sock} );

    my @received;
    my $monitor_started = 0;
    my $captured_set = 0;

    $monitor->monitor(sub {
        my ($r, $e) = @_;

        if ($e && !defined $r) {
            return;
        }

        push @received, $r;

        if ($r eq 'OK' && !$monitor_started) {
            $monitor_started = 1;
            $client->set('monitor_test_key', 'monitor_test_value', sub {
                $client->disconnect;
            });
        }
        elsif ($r =~ /SET.*monitor_test_key/i) {
            $captured_set = 1;
            $monitor->disconnect;
            EV::break;
        }
    });

    my $timeout; $timeout = EV::timer 2, 0, sub {
        undef $timeout;
        $monitor->disconnect;
        $client->disconnect;
        EV::break;
    };

    EV::run;
    undef $timeout;

    ok $monitor_started, 'monitor command acknowledged with OK';
    ok $captured_set, 'monitor captured SET command';
}

# skip_pending leaves a MONITOR stream running: the server has no off switch
{
    my $monitor = EV::Redis->new( path => $connect_info{sock} );
    my $client  = EV::Redis->new( path => $connect_info{sock} );

    my ($got_ok, $captured_set, $got_err);
    $monitor->monitor(sub {
        my ($r, $e) = @_;
        if (defined $e) { $got_err = $e; return; }
        $got_ok = 1 if $r eq 'OK' && !$got_ok;
        if ($r =~ /SET.*skip_mon_key/i) {
            $captured_set = 1;
            $client->disconnect;
            EV::break;
        }
    });
    my $s; $s = EV::timer 0.1, 0.1, sub {
        return unless $got_ok;
        undef $s;
        $monitor->skip_pending;
        $client->set('skip_mon_key', 'v', sub {});
    };

    my $timeout; $timeout = EV::timer 2, 0, sub {
        undef $timeout;
        $monitor->disconnect;
        $client->disconnect;
        EV::break;
    };
    EV::run;
    undef $timeout;

    ok !$got_err, 'skip_pending on a MONITOR connection spares the stream';
    ok $captured_set, '... and the stream still delivers';
    like do { local $@; eval { $monitor->command('ping', sub {}) }; $@ },
        qr/MONITOR/, '... while MONITOR stays active';
    $monitor->disconnect;
    $client->disconnect;
}

# (p)unsubscribe with nothing subscribed fails through the callback alone
{
    my $r = EV::Redis->new( path => $connect_info{sock} );
    my %got;
    $r->command('unsubscribe', sub { $got{bare} = $_[1] // 'no error' });
    $r->command('punsubscribe', sub { $got{bare_p} = $_[1] // 'no error' });
    $r->command('unsubscribe', 'ch1', sub { $got{named} = $_[1] // 'no error' });
    $r->command('punsubscribe', 'pat*', sub { $got{named_p} = $_[1] // 'no error' });
    my $t; $t = EV::timer 1, 0, sub { undef $t; EV::break };
    EV::run;
    undef $t;
    is $got{bare}, 'not subscribed', 'bare unsubscribe says why';
    is $got{bare_p}, 'not subscribed', 'bare punsubscribe says why';
    is $got{named}, 'not subscribed', 'named unsubscribe says why';
    is $got{named_p}, 'not subscribed', 'named punsubscribe says why';
    my $pong;
    $r->command('ping', sub { $pong = $_[0] // $_[1] });
    my $t2; $t2 = EV::timer 1, 0, sub { undef $t2; EV::break };
    EV::run;
    undef $t2;
    is $pong, 'PONG', '... and the connection survives';
    $r->disconnect;
}

# bare (p)unsubscribe drops every subscription and leaves a clean connection
{
    my $r = EV::Redis->new( path => $connect_info{sock} );
    my (@unsubs, $pong);
    $r->command('subscribe', 'r18_ch', sub { push @unsubs, $_[0] if defined $_[0] });
    $r->command('psubscribe', 'r18_pat*', sub { push @unsubs, $_[0] if defined $_[0] });
    my $t; $t = EV::timer 1, 0, sub { undef $t; EV::break };
    EV::run;
    undef $t;
    @unsubs = ();
    $r->command('unsubscribe', sub { });
    $r->command('punsubscribe', sub { });
    my $t2; $t2 = EV::timer 1, 0, sub { undef $t2; EV::break };
    EV::run;
    undef $t2;
    is_deeply [map { [$_->[0], $_->[1]] } @unsubs],
        [['unsubscribe', 'r18_ch'], ['punsubscribe', 'r18_pat*']],
        'bare unsubscribe acks every subscription';
    $r->command('ping', sub { $pong = $_[0] // $_[1] });
    my $t3; $t3 = EV::timer 1, 0, sub { undef $t3; EV::break };
    EV::run;
    undef $t3;
    is $pong, 'PONG', '... and PING is a regular command again';
    $r->disconnect;
}

# HELLO on a subscribed connection is refused, and the connection survives
{
    my $r = EV::Redis->new( path => $connect_info{sock} );
    $r->command('subscribe', 'r18_hello', sub { });
    my $t; $t = EV::timer 1, 0, sub { undef $t; EV::break };
    EV::run;
    undef $t;
    my $err;
    $r->command('hello', 3, sub { $err = $_[1] // 'no error' });
    my $t2; $t2 = EV::timer 1, 0, sub { undef $t2; EV::break };
    EV::run;
    undef $t2;
    like $err, qr/not supported on a subscribed/, 'HELLO refused once subscribed';
    is $r->is_connected, 1, '... and the connection survives';
    $r->disconnect;
}

# a HELLO that waits out a setup subscription fails through the callback alone
{
    my $err;
    my $r;
    $r = EV::Redis->new( path => $connect_info{sock},
        reconnect => 1, resume_waiting_on_reconnect => 1,
        on_connect => sub { $r->command('subscribe', 'r18_hello2', sub { }) } );
    $r->command('hello', 3, sub { $err = $_[1] // 'no error' });
    my $t; $t = EV::timer 2, 0, sub { undef $t; EV::break };
    EV::run;
    undef $t;
    like $err, qr/not supported on a subscribed/, 'waited HELLO refused';
    is $r->is_connected, 1, '... and the connection survives';
    $r->disconnect;
}

# hiredis cannot route smessage, so sharded subscribe is refused
{
    my ($redis_version) = get_redis_version($connect_info{sock});

    my $r = EV::Redis->new( path => $connect_info{sock} );

    eval { $r->ssubscribe('sharded_channel', sub {}) };
    like $@, qr/ssubscribe is not supported/, 'ssubscribe croaks';

    eval { $r->sunsubscribe('sharded_channel', sub {}) };
    like $@, qr/sunsubscribe is not supported/, 'sunsubscribe croaks';

    eval { $r->command('PMONITOR', sub {}) };
    like $@, qr/PMONITOR is not supported/, 'PMONITOR croaks';

    eval { $r->command("subscribe\0", 'x', sub {}) };
    like $@, qr/NUL byte/, 'a command name with a NUL byte croaks';
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
        undef $timeout;
        is $spublish_res, 0, 'spublish works as a regular command (0 receivers)';
    }
    $r->disconnect;
}

# mixing MONITOR with other commands would be a use-after-free in hiredis
{
    my $r = EV::Redis->new( path => $connect_info{sock} );

    $r->command('set', 'mon_guard_key', 1, sub { EV::break });
    eval { $r->monitor(sub {}) };
    like $@, qr/idle connection/, 'monitor with a pending command croaks';
    EV::run;

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
    undef $t1;
    ok $mon_ok, 'monitor on idle connection works';

    eval { $r->ping(sub {}) };
    like $@, qr/MONITOR is active/, 'command while monitoring croaks';

    $r->disconnect;
    $r->connect_unix($connect_info{sock});
    my $pong;
    $r->ping(sub { $pong = $_[0]; EV::break });
    my $t2; $t2 = EV::timer 2, 0, sub { undef $t2; EV::break };
    EV::run;
    undef $t2;
    is $pong, 'PONG', 'commands work again after reconnect clears monitor state';
    $r->disconnect;
}

{
    my $r = EV::Redis->new( path => $connect_info{sock} );
    eval { $r->subscribe(sub {}) };
    like $@, qr/subscribe requires at least one channel/, 'no-arg subscribe croaks';
    eval { $r->psubscribe(sub {}) };
    like $@, qr/psubscribe requires at least one channel/, 'no-arg psubscribe croaks';
    $r->disconnect;
}

# MONITOR inside MULTI fails through the callback, even from a reply callback
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my ($rv, $merr, $mcroak);
    $r->multi(sub {
        $rv = eval { $r->monitor(sub { $merr = $_[1] }) };
        $mcroak = $@ unless defined $rv;
        $r->exec(sub { EV::break });
    });
    my $t; $t = EV::timer 4, 0, sub { undef $t; EV::break };
    EV::run;
    undef $t;
    is $mcroak, undef, 'monitor in MULTI from a callback does not croak';
    is $rv, -1, '... and returns -1';
    is $merr, 'pub/sub and MONITOR are not supported inside MULTI',
        '... failing through the callback';
    $r->disconnect;
}

# outside MULTI the callback's own command still counts as outstanding
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my $croak;
    $r->ping(sub {
        eval { $r->monitor(sub {}) };
        $croak = $@;
        EV::break;
    });
    my $t; $t = EV::timer 4, 0, sub { undef $t; EV::break };
    EV::run;
    undef $t;
    like $croak, qr/idle connection/, 'monitor from a reply callback croaks idle';
    $r->disconnect;
}

# an idle MONITOR connection times out
{
    my (@events, @mon);
    my $r = EV::Redis->new(path => $connect_info{sock}, command_timeout => 300,
        on_error => sub { push @events, "error:$_[0]"; },
        on_disconnect => sub { push @events, 'disconnect'; EV::break; });
    $r->monitor(sub { push @mon, [@_]; });
    my $t; $t = EV::timer 4, 0, sub { push @events, 'TIMEOUT'; undef $t; EV::break };
    EV::run;
    undef $t;
    is scalar(@mon), 2, 'monitor callback ran twice';
    is $mon[0][0], 'OK', 'monitor acknowledged';
    is $mon[1][0], undef, 'idle monitor times out';
    is $mon[1][1], 'Timeout', '... with a Timeout error';
    is_deeply \@events, ['error:Timeout', 'disconnect'],
        'timeout reported, then disconnect';
    is $r->is_connected, 0, 'the connection is gone';
    $r->disconnect;
}

{
    my $sub = EV::Redis->new(path => $connect_info{sock});
    my @cb_calls;
    my $subscribed = 0;

    $sub->on_error(sub {});

    $sub->subscribe('disconnect_test_ch', sub {
        my ($result, $error) = @_;
        push @cb_calls, [$result, $error];
        if ($result && ref $result eq 'ARRAY' && $result->[0] eq 'subscribe') {
            $subscribed = 1;
            $sub->disconnect;
        }
    });

    my $t; $t = EV::timer 2, 0, sub { undef $t; EV::break };
    EV::run;
    undef $t;

    ok $subscribed, 'subscribed before disconnect';
    my @errors = grep { defined $_->[1] } @cb_calls;
    is scalar(@errors), 1, 'subscribe callback invoked exactly once with error on disconnect';
    ok $errors[0][1], 'error string is truthy (not empty)';
    like $errors[0][1], qr/disconnected/, 'error string is "disconnected"';
}

# teardown: at most one error per channel
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
    undef $t;

    is $sub_count, 2, 'both channels subscribed';
    my @errors = grep { defined $_->[1] } @cb_calls;
    for my $e (@errors) {
        ok $e->[1], 'error string is truthy (not empty)';
    }
    ok scalar(@errors) <= 2, 'no more than 2 error callbacks for 2-channel subscribe';
}

# on_disconnect may connect again into MONITOR from inside disconnect()
{
    my $r;
    $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my $t = EV::timer 0.3, 0, sub { EV::break };
    EV::run;
    undef $t;
    $r->on_disconnect(sub {
        $r->on_disconnect(undef);
        $r->connect_unix($connect_info{sock});
        $r->monitor(sub {});
    });
    $r->disconnect;
    eval { $r->ping(sub {}) };
    like $@, qr/MONITOR is active/, 'MONITOR opened by on_disconnect still refuses commands';
    $r->disconnect;
}

# disconnect() in the MONITOR callback, then on_disconnect connects again
{
    my ($r, $again, @mon);
    my $reconnected = 0;
    $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $r->on_disconnect(sub { $r->connect_unix($connect_info{sock}) unless $reconnected++ });
    $r->on_connect(sub {
        return unless $reconnected;
        $again = eval { $r->command('monitor', sub {}); 1 };
        EV::break;
    });
    $r->command('monitor', sub { push @mon, $_[0] // $_[1]; $r->disconnect if @mon == 1 });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok $again, 'MONITOR again after disconnect() in the MONITOR callback';
    is_deeply \@mon, ['OK', 'disconnected'], 'the first MONITOR callback gets one final error';
    $r->on_disconnect(undef);
    $r->disconnect;
}

# disconnect() outside the MONITOR callback: one final error
{
    my @mon;
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $r->command('monitor', sub { push @mon, $_[0] // $_[1]; EV::break if @mon == 1 });
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    $r->disconnect;
    is_deeply \@mon, ['OK', 'disconnected'], 'disconnect() of a MONITOR connection: one final error';
}

# hiredis delivers a channel to its latest subscriber's callback
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my $p = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my $log = sub { my $l = shift; sub { push @$l, $_[1] // $_[0][0] } };
    my $run = sub { my $g = EV::timer 3, 0, sub { EV::break }; EV::run };

    # unsubscribe + subscribe in one tick: the unsubscribe reply goes to the
    # new callback, which must survive it
    my (@a, @b);
    $r->subscribe('ps_resub', sub {
        $log->(\@a)->(@_);
        return unless @a == 1;
        $r->unsubscribe('ps_resub');
        $r->subscribe('ps_resub', sub {
            $log->(\@b)->(@_);
            $p->publish('ps_resub', 'x', sub {}) if @b == 2;
            EV::break if @b == 3;
        });
    });
    $run->();
    is_deeply \@b, ['unsubscribe', 'subscribe', 'message'],
        'resubscribe in one tick: the new callback keeps the channel';

    # a second subscribe to a channel replaces its callback
    my (@c, @d);
    $r->subscribe('ps_repl', $log->(\@c));
    $r->subscribe('ps_repl', sub {
        $log->(\@d)->(@_);
        $p->publish('ps_repl', 'x', sub {}) if @d == 2;
        EV::break if @d == 3;
    });
    $run->();
    is_deeply \@d, ['subscribe', 'subscribe', 'message'], 'second subscribe takes the channel';

    # replaced from inside its own callback
    my (@e, @f);
    $r->subscribe('ps_self', sub {
        $log->(\@e)->(@_);
        return unless @e == 1;
        $r->subscribe('ps_self', sub {
            $log->(\@f)->(@_);
            $p->publish('ps_self', 'x', sub {}) if @f == 1;
            EV::break if @f == 2;
        });
    });
    $run->();
    is_deeply \@f, ['subscribe', 'message'], 'replaced from its own callback';

    # losing one of two channels keeps the callback for the other
    my (@g, @h, @i);
    $r->subscribe('ps_m1', 'ps_m2', sub {
        $log->(\@g)->(@_);
        EV::break if @g == 3;
        return unless @g == 2;
        $r->subscribe('ps_m1', sub {
            $log->(\@h)->(@_);
            $p->publish('ps_m2', 'x', sub {}) if @h == 1;
        });
    });
    $r->psubscribe('ps_pat*', $log->(\@i));
    $r->psubscribe('ps_pat*', sub { push @i, 'new:' . ($_[1] // $_[0][0]) });
    $run->();
    is_deeply \@g, ['subscribe', 'subscribe', 'message'], 'the other channel stays with the first callback';
    is_deeply \@i, ['new:psubscribe', 'new:psubscribe'], 'second psubscribe takes the pattern';

    # duplicate names make one subscription
    my @j;
    $r->subscribe('ps_dup', 'ps_dup', sub {
        $log->(\@j)->(@_);
        $r->unsubscribe('ps_dup') if @j == 2;
        EV::break if @j == 3;
    });
    $run->();
    is_deeply \@j, ['subscribe', 'subscribe', 'unsubscribe'], 'subscribe a a, unsubscribe a';

    $r->disconnect;
    is_deeply \@a, ['subscribe'], 'replaced callbacks get no teardown error';
    is_deeply \@c, [], 'a callback replaced before any reply is never called';
    is_deeply \@e, ['subscribe'], 'a callback replaced from inside itself is not called again';
    is_deeply [@j[3 .. $#j]], [], 'fully unsubscribed callback gets no teardown error';
    is $b[-1], 'disconnected', 'current callbacks get the teardown error';
    is scalar(grep { $_ eq 'disconnected' } @g), 1, 'one teardown error for the one channel left';
    $p->disconnect;
}

done_testing;
