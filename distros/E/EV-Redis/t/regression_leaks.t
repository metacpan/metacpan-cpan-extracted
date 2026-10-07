use strict;
use warnings;
use Test::More;
use EV;
use EV::Redis;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

# async connect failure with reconnect disabled clears both queues
{
    my $r = EV::Redis->new;
    $r->max_pending(1);
    $r->on_error(sub { });

    # refusal is usually async; on FreeBSD it is synchronous and command() croaks
    $r->connect("127.0.0.1", 65534);

    my $called = 0;
    my $queued = eval {
        $r->command('ping', sub { $called++; });
        $r->command('ping', sub { $called++; });
        1;
    };

    if ($queued) {
        is $r->waiting_count, 1, 'cmd queued in wait queue during connect';
        is $r->pending_count, 1, 'cmd in pending during connect';

        my $timer = EV::timer 0.5, 0, sub { EV::break };
        EV::run;

        is $called, 2, 'both callbacks invoked with error on connect failure';
    }
    else {
        like $@, qr/connection required/,
            'synchronous connect refusal croaks as documented';
    }

    is $r->waiting_count, 0, 'wait queue cleared after connect failure';
    is $r->pending_count, 0, 'pending queue cleared after connect failure';
}

# a skipped SUBSCRIBE frees its callback entry when the unsubscribe replies arrive
{
    my $r = EV::Redis->new;
    $r->connect_unix( $connect_info{sock} );

    my $called = 0;
    $r->command('subscribe', 'leak_ch1', 'leak_ch2', sub {
        $called++;
    });

    # Give it time to establish subscription
    my $t; $t = EV::timer 0.1, 0, sub {
        $r->skip_pending;
        
        $r->command('unsubscribe', 'leak_ch1', 'leak_ch2', sub { });
        undef $t;
    };

    my $t2; $t2 = EV::timer 0.3, 0, sub {
        $r->disconnect;
        undef $t2;
    };

    EV::run;
    pass 'Skipped persistent command unsubscription did not crash';
}

{
    my $r = EV::Redis->new;
    $r->connect_unix( $connect_info{sock} );

    $r->set('ff_key', 'ff_val');

    my $result;
    $r->get('ff_key', sub {
        ($result) = @_;
        $r->disconnect;
    });
    EV::run;

    is $result, 'ff_val', 'fire-and-forget SET succeeded';
}

{
    my $r = EV::Redis->new;
    eval {
        $r->set('foo', 'bar');
    };
    ok $@, 'fire-and-forget without connection throws exception';
    like $@, qr/connection required/, 'exception mentions connection required';
}

{
    eval { EV::Redis->new(host => undef) };
    like $@, qr/'host' must be a defined string/, 'host => undef croaks';

    eval { EV::Redis->new(path => undef) };
    like $@, qr/'path' must be a defined string/, 'path => undef croaks';
}

# connect/disconnect cycles on one object leave no residual state
{
    my $r = EV::Redis->new(on_error => sub { });
    for my $i (1..20) {
        $r->connect_unix($connect_info{sock});
        my $done = 0;
        $r->ping(sub { $done = 1; $r->disconnect });
        my $timer = EV::timer 1, 0, sub { EV::break };
        EV::run;
        ok $done, "cycle $i: ping completed";
        is $r->pending_count, 0, "cycle $i: pending_count is 0";
        is $r->waiting_count, 0, "cycle $i: waiting_count is 0";
        ok !$r->is_connected, "cycle $i: disconnected";
    }
}

done_testing;
