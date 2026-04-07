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

# Test Case 1: Memory leak on asynchronous connection failure with reconnect disabled.
# When a connection fails asynchronously (e.g., TCP timeout or refused), and
# reconnect is disabled, the waiting queue MUST be cleared to prevent leaks.
{
    my $r = EV::Redis->new;
    $r->max_pending(1);
    $r->on_error(sub { }); # silence error
    
    # connect to closed TCP port which fails asynchronously
    $r->connect("127.0.0.1", 65534);

    my $called = 0;
    $r->command('ping', sub { $called++; }); # pending
    $r->command('ping', sub { $called++; }); # wait_queue

    is $r->waiting_count, 1, 'cmd queued in wait queue during connect';
    is $r->pending_count, 1, 'cmd in pending during connect';

    my $timer = EV::timer 0.5, 0, sub { EV::break };
    EV::run;

    is $r->waiting_count, 0, 'wait queue cleared on connect failure';
    is $r->pending_count, 0, 'pending queue cleared on connect failure';
    is $called, 2, 'both callbacks invoked with error on connect failure';
}

# Test Case 2: Memory leak for skipped persistent commands upon unsubscription.
# If a persistent command (SUBSCRIBE) is skipped via skip_pending, and then
# an unsubscribe reply arrives, the command callback entry MUST be freed.
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
        
        # Manually trigger unsubscription from same connection to force 
        # unsubscribe replies back to the skipped subscribe entry.
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

# Test Case 3: Fire-and-forget commands (no callback).
{
    my $r = EV::Redis->new;
    $r->connect_unix( $connect_info{sock} );

    # Fire-and-forget SET
    $r->set('ff_key', 'ff_val');

    # Verify with a callback-based GET
    my $result;
    $r->get('ff_key', sub {
        ($result) = @_;
        $r->disconnect;
    });
    EV::run;

    is $result, 'ff_val', 'fire-and-forget SET succeeded';
}

# Test Case 4: Fire-and-forget without connection croaks.
{
    my $r = EV::Redis->new;
    eval {
        $r->set('foo', 'bar');
    };
    ok $@, 'fire-and-forget without connection throws exception';
    like $@, qr/connection required/, 'exception mentions connection required';
}

# Test Case 5: Constructor with undef host/path croaks.
{
    eval { EV::Redis->new(host => undef) };
    like $@, qr/'host' must be a defined string/, 'host => undef croaks';

    eval { EV::Redis->new(path => undef) };
    like $@, qr/'path' must be a defined string/, 'path => undef croaks';
}

done_testing;
