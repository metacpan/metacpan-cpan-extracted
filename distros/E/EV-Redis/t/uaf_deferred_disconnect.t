use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use Test::TCP qw(empty_port);
use EV;
use EV::Redis;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

# Test: disconnect() with in-flight commands from OUTSIDE any hiredis callback,
# then immediate destruction. redisAsyncDisconnect defers teardown whenever
# replies are pending (async.c: immediate only if !REDIS_IN_CALLBACK and
# replies.head == NULL), so the old context stays alive and draining while the
# object has already forgotten it (ac NULL, not inside a callback so the
# ac_saved path never armed). Without draining-context tracking, DESTROY frees
# self and all cbts that hiredis still references; the reply arriving later is
# a use-after-free (double free abort in practice).
{
    my @cb;
    my $r = EV::Redis->new(path => $connect_info{sock});
    $r->on_error(sub {});

    $r->command('ping', sub {
        my ($res, $err) = @_;
        is($res, 'PONG', 'deferred disconnect: connected');

        my $w; $w = EV::timer 0.01, 0, sub {
            undef $w;
            # Outside any hiredis callback now:
            $r->command('ping', sub { push @cb, [@_] });
            $r->disconnect;   # replies pending -> deferred teardown
            undef $r;         # DESTROY while old context still draining
        };
    });

    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    is(scalar @cb, 1, 'deferred disconnect: in-flight callback invoked exactly once');
    ok(!defined $cb[0][0], 'deferred disconnect: no result after destruction');
    ok(defined $cb[0][1], 'deferred disconnect: got error string');
}
pass('survived DESTROY after deferred disconnect with in-flight command');

# Test: disconnect() with in-flight commands, immediately connect() a new
# connection, then destruction. The old context is still draining; DESTROY
# must clean up the new context AND not free the old context's cbts/self.
{
    my @cb;
    my $connected = 0;
    my $r = EV::Redis->new(path => $connect_info{sock});
    $r->on_error(sub {});
    $r->on_connect(sub { $connected++ });

    $r->command('ping', sub {
        my ($res, $err) = @_;

        my $w; $w = EV::timer 0.01, 0, sub {
            undef $w;
            $r->command('ping', sub { push @cb, [@_] });
            $r->disconnect;                        # old context drains
            $r->connect_unix($connect_info{sock}); # new context
            undef $r;                              # DESTROY with both alive
        };
    });

    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    is(scalar @cb, 1, 'disconnect+reconnect+destroy: old in-flight callback invoked once');
    ok(defined $cb[0][1], 'disconnect+reconnect+destroy: got error string');
}
pass('survived DESTROY after disconnect+connect with old context draining');

# Test: destruction from inside on_error during a failed connect, with
# commands issued while connecting. hiredis order on connect failure is:
# connect callback first (REDIS_IN_CALLBACK set), then __redisAsyncFree fires
# every pending reply callback. connect_cb nulls self->ac before emit_error,
# so without draining-context tracking a DESTROY inside on_error frees all
# cbts that hiredis fires right after connect_cb returns.
{
    my @cb;
    my $errors = 0;
    my $port = empty_port();

    my $r = EV::Redis->new;
    $r->on_error(sub {
        $errors++;
        undef $r;   # drop last reference inside connect-failure error handler
    });
    $r->connect('127.0.0.1', $port);
    # Issued while connecting: buffered by hiredis, pending at failure time
    $r->command('ping', sub { push @cb, [@_] });

    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    ok($errors >= 1, 'connect failure: on_error fired');
    is(scalar @cb, 1, 'connect failure: pending callback invoked exactly once');
    ok(!defined $cb[0][0], 'connect failure: no result');
    ok(defined $cb[0][1], 'connect failure: got error string');
}
pass('survived DESTROY inside on_error during failed connect with pending command');

# Test: disconnect() of a still-connecting context with buffered commands,
# then the connect failure arrives. disconnect() tracks the context; the
# failure callback must NOT track it again (a duplicate drain node would
# dangle after dataCleanup reaps only one — UAF/double-free at DESTROY).
{
    my @cb;
    my $port = empty_port();
    for my $round (1, 2) {
        my $r = EV::Redis->new;
        $r->on_error(sub {});
        $r->connect('127.0.0.1', $port);
        $r->command('ping', sub { push @cb, [@_] });  # buffered while connecting
        $r->disconnect;                               # deferred: replies pending
        my $guard = EV::timer 2, 0, sub { EV::break };
        EV::run;   # connect failure arrives, teardown completes
        undef $r;  # pre-fix: stale duplicate node -> double free
    }
    is scalar @cb, 2, 'double-track guard: each round invoked its callback once';
    ok defined $cb[0][1] && defined $cb[1][1], 'double-track guard: callbacks got errors';
}
pass('survived disconnect-while-connecting followed by connect failure, twice');

# Test: reconnect from inside on_disconnect during a synchronous disconnect.
# disconnect() must not clobber self->ac when the handler re-established a
# new connection (the old code nulled it unconditionally, orphaning the new
# context: is_connected lied and the context leaked with data == self).
{
    my $srv2 = Test::RedisServer->new;
    my %ci2 = $srv2->connect_info;
    my $reconnected_alive = 0;
    my $pong2;

    my $r = EV::Redis->new(path => $ci2{sock});
    $r->on_error(sub {});
    $r->command('ping', sub {
        my $w; $w = EV::timer 0.01, 0, sub {
            undef $w;
            $r->on_disconnect(sub {
                $r->on_disconnect(undef);
                $r->connect_unix($ci2{sock});  # re-establish inside handler
            });
            $r->disconnect;   # synchronous: idle, outside hiredis callbacks
            $reconnected_alive = $r->is_connected;
            $r->ping(sub { $pong2 = $_[0]; EV::break });
        };
    });
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    is $reconnected_alive, 1, 'reconnect-in-on_disconnect: still connected after disconnect()';
    is $pong2, 'PONG', 'reconnect-in-on_disconnect: new connection works';
    $r->disconnect;
}
pass('survived reconnect inside on_disconnect');

# Test: DESTROY inside a failed-connect trailing callback while a
# re-established connection holds persistent subscribe cbts. DESTROY frees
# the new context synchronously; its per-channel teardown callbacks hit the
# FREED path in reply_cb, which must free the persist cbt on the last
# channel (it used to leave it in cb_queue for a sweep that never runs).
{
    my (@ping_cb, @sub_cb);
    my $port = empty_port();
    my $srv3 = Test::RedisServer->new;
    my %ci3 = $srv3->connect_info;

    my $r = EV::Redis->new;
    $r->on_error(sub {});
    $r->connect('127.0.0.1', $port);              # will be refused
    $r->command('ping', sub {
        push @ping_cb, [@_];
        undef $r;   # DESTROY inside the failed connect's trailing callback
    });
    $r->disconnect;                               # deferred: ping pending
    $r->connect_unix($ci3{sock});                 # new connection
    $r->command('subscribe', 'lk_ch1', 'lk_ch2', sub { push @sub_cb, [@_] });

    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    is scalar @ping_cb, 1, 'persist-leak: trailing ping callback fired once';
    ok defined $ping_cb[0][1], 'persist-leak: ping got error';
    my @sub_errors = grep { defined $_->[1] } @sub_cb;
    ok scalar(@sub_errors) <= 1, 'persist-leak: subscribe error callback at most once';
}
pass('survived DESTROY-in-trailing-callback with subscribed replacement connection');

done_testing;
