use strict;
use warnings;

use Test::More;
use Test::RedisServer;
use Test::TCP;

use EV;
use EV::Redis;

my $port = empty_port;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new( conf => { port => $port });
} or plan skip_all => 'redis-server is required to this test';


my $r = EV::Redis->new;

my $connected = 0;
my $error = 0;

$r->on_error(sub { $error++ });
$r->on_connect(sub {
    $connected++;

    my $t; $t = EV::timer .1, 0, sub {
        $r->disconnect;
        undef $t;
    };
});

$r->connect('127.0.0.1', $port);

EV::run;

is $connected, 1;
is $error, 0;


# Test: constructor with on_error => undef still gets default handler (backward compat)
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $r_default = EV::Redis->new(on_error => undef);
    # Default handler is 'die @_', which XS catches and warns about
    $r_default->connect('127.0.0.1', 59999);  # Invalid port
    my $t; $t = EV::timer 0.5, 0, sub { undef $t };
    EV::run;

    # The default die handler should have been called and caught by XS
    like $warnings[0], qr/exception in error handler/,
        'on_error => undef in constructor still gets default die handler';
}

# Test: on_error() without arguments clears the handler
{
    my $error_count = 0;
    my $r = EV::Redis->new(on_error => sub { $error_count++ });
    $r->on_error();  # Clear the handler
    # Now errors should not call our handler
    $r->connect('127.0.0.1', 59999);  # Invalid port
    my $t; $t = EV::timer 0.5, 0, sub { undef $t };
    EV::run;
    is $error_count, 0, 'on_error() without args clears handler';
}


$r = EV::Redis->new(connect_timeout => 1000, command_timeout => 1000);

$connected = 0;
$error = 0;

$r->on_error(sub { $error++ });
$r->on_connect(sub {
    $connected++;

    my $t; $t = EV::timer .1, 0, sub {
        $r->disconnect;
        undef $t;
    };
});

$r->connect('127.0.0.1', $port);

EV::run;

is $connected, 1;
is $error, 0;


$redis_server->stop;

$r = EV::Redis->new;

$connected = 0;
$error = 0;

$r->on_error(sub {
    $error++;
});
$r->on_connect(sub {
    $connected++;

    my $t; $t = EV::timer .1, 0, sub {
        $r->disconnect;
        undef $t;
    };
});

$r->connect('127.0.0.1', $port);

EV::run;

is $connected, 0;
is $error, 1;


# Restart Redis for remaining tests
$redis_server = Test::RedisServer->new( conf => { port => $port });

# Test: disconnect() is idempotent (no error on double call)
{
    my $error_count = 0;
    my $r = EV::Redis->new(
        on_error => sub { $error_count++ },
    );

    $r->connect('127.0.0.1', $port);

    my $t; $t = EV::timer 0.1, 0, sub {
        $r->disconnect;
        $r->disconnect;  # Should not trigger error
        undef $t;
    };
    EV::run;

    is $error_count, 0, 'double disconnect does not trigger error';
}

# Test: disconnect() on never-connected instance is safe
{
    my $error_count = 0;
    my $r = EV::Redis->new(
        on_error => sub { $error_count++ },
    );

    $r->disconnect;  # Never connected - should be no-op
    $r->disconnect;  # Again - should still be no-op

    is $error_count, 0, 'disconnect on never-connected instance does not trigger error';
}

# Test: exception in on_disconnect handler is caught and warned
{
    my $disconnect_called = 0;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $r = EV::Redis->new(
        on_error => sub { },
        on_disconnect => sub {
            $disconnect_called = 1;
            die "intentional exception in disconnect handler";
        },
    );

    $r->connect('127.0.0.1', $port);

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        $r->disconnect;
    };

    EV::run;

    is $disconnect_called, 1, 'on_disconnect handler was called despite exception';
    like $warnings[0], qr/exception in disconnect handler/, 'warning was emitted';
}

# Test: exception in on_connect handler is caught and warned
{
    my $connect_called = 0;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $r = EV::Redis->new(
        on_error => sub { },
        on_connect => sub {
            $connect_called = 1;
            die "intentional exception in connect handler";
        },
    );

    $r->connect('127.0.0.1', $port);

    my $t; $t = EV::timer 0.2, 0, sub {
        undef $t;
        $r->disconnect;
    };

    EV::run;

    is $connect_called, 1, 'on_connect handler was called despite exception';
    like $warnings[0], qr/exception in connect handler/, 'warning was emitted';
}

# Test: exception in on_error handler is caught and warned
{
    my $error_called = 0;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $r = EV::Redis->new(
        on_error => sub {
            $error_called = 1;
            die "intentional exception in error handler";
        },
    );

    # Connect to invalid port to trigger error
    $r->connect('127.0.0.1', 59999);

    my $t; $t = EV::timer 0.5, 0, sub {
        undef $t;
    };

    EV::run;

    is $error_called, 1, 'on_error handler was called despite exception';
    like $warnings[0], qr/exception in error handler/, 'warning was emitted';
}

# Test: connect() when already connected throws exception
{
    my $r = EV::Redis->new;
    $r->on_error(sub { });

    $r->connect('127.0.0.1', $port);

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;

        my $died = 0;
        eval {
            $r->connect('127.0.0.1', $port);
        };
        $died = 1 if $@;

        ok $died, 'connect() when already connected throws exception';
        like $@, qr/already connected/, 'exception message mentions already connected';

        $r->disconnect;
    };

    EV::run;
}

# Test: skip_pending during disconnect callback (re-entrant safety)
{
    my @results;
    my $disconnect_called = 0;
    my $r = EV::Redis->new(
        on_error => sub { },
        on_disconnect => sub {
            $disconnect_called++;
            # This should be safe - skip_pending should no-op during cleanup
            $r->skip_pending();
        },
    );

    $r->connect('127.0.0.1', $port);

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        # Queue some commands
        $r->set('key1', 'value1', sub { push @results, ['set1', @_] });
        $r->set('key2', 'value2', sub { push @results, ['set2', @_] });
        $r->disconnect;
    };

    EV::run;

    is $disconnect_called, 1, 'disconnect callback was called';
    # Commands should have completed or received disconnect error - no crash
    ok 1, 'skip_pending during disconnect callback did not crash';
}

# Test: waiting queue is drained after on_connect without infinite loop
# This verifies the fix for the bug where the waiting queue drain loop
# could infinite-loop if connect_handler caused issues.
{
    my $connect_called = 0;
    my @results;
    my $r = EV::Redis->new(
        on_error => sub { },
        on_connect => sub {
            $connect_called++;
        },
        max_pending => 1,  # Force waiting queue usage
    );

    $r->connect('127.0.0.1', $port);

    # Queue commands after connect starts - they'll use waiting queue
    my $queue_timer; $queue_timer = EV::timer 0.1, 0, sub {
        undef $queue_timer;
        $r->set('key1', 'val1', sub { push @results, ['set1', $_[1] ? 'error' : 'ok'] });
        $r->set('key2', 'val2', sub { push @results, ['set2', $_[1] ? 'error' : 'ok'] });
    };

    my $done_timer; $done_timer = EV::timer 1, 0, sub {
        undef $done_timer;
        $r->disconnect;
    };

    EV::run;

    is $connect_called, 1, 'on_connect was called';
    is scalar(@results), 2, 'all queued commands executed (no infinite loop)';
}

# Test: disconnect() from on_connect prevents waiting queue drain
# This tests the intentional_disconnect check in the waiting queue drain loop
{
    my $connect_called = 0;
    my @results;
    my $r;
    $r = EV::Redis->new(
        on_error => sub { },
        on_connect => sub {
            $connect_called++;
            # Disconnect immediately in connect handler
            # This should prevent waiting queue commands from being sent
            $r->disconnect;
        },
        max_pending => 1,  # Force commands to wait queue
    );

    $r->connect('127.0.0.1', $port);

    # Queue commands - first goes to pending (sent immediately), rest to waiting
    $r->set('dc_connect_1', 'val1', sub { push @results, ['cmd1', $_[1] ? 'error' : 'ok'] });
    $r->set('dc_connect_2', 'val2', sub { push @results, ['cmd2', $_[1] ? 'error' : 'ok'] });
    $r->set('dc_connect_3', 'val3', sub { push @results, ['cmd3', $_[1] ? 'error' : 'ok'] });

    my $timer; $timer = EV::timer 0.5, 0, sub { undef $timer };
    EV::run;

    is $connect_called, 1, 'on_connect was called';
    is scalar(@results), 3, 'all callbacks were invoked';
    # First command may succeed (already sent), waiting commands should get errors
    # The key test is that waiting queue was NOT drained after disconnect
    my $errors = grep { $_->[1] eq 'error' } @results;
    ok $errors >= 2, 'waiting queue commands got errors (not drained after disconnect)';
    is $r->is_connected, 0, 'not connected after disconnect in on_connect';
}

# Test: disconnect() from inside a reply callback (deferred disconnect path)
{
    my @results;
    my $disconnect_called = 0;
    my $r = EV::Redis->new(
        on_error => sub { },
        on_disconnect => sub { $disconnect_called++ },
    );
    $r->connect('127.0.0.1', $port);

    $r->set('dc_reply_1', 'val1', sub {
        my ($res, $err) = @_;
        push @results, ['cmd1', $res, $err];
        $r->disconnect;
    });
    $r->set('dc_reply_2', 'val2', sub {
        my ($res, $err) = @_;
        push @results, ['cmd2', $res, $err];
    });
    $r->set('dc_reply_3', 'val3', sub {
        my ($res, $err) = @_;
        push @results, ['cmd3', $res, $err];
    });

    EV::run;

    is scalar(@results), 3, 'all 3 callbacks invoked after disconnect in callback';
    is $results[0][1], 'OK', 'first command succeeded before deferred disconnect';
    is $disconnect_called, 1, 'disconnect callback fired once';
    is $r->is_connected, 0, 'no longer connected after deferred disconnect';
}

# Test: constructor rejects both host and path
{
    eval {
        EV::Redis->new(
            host => '127.0.0.1',
            path => '/tmp/redis.sock',
            on_error => sub { },
        );
    };
    like $@, qr/Cannot specify both/, 'constructor rejects both host and path';
}

# Test: connect_timeout fires on unreachable host
# 192.0.2.1 (TEST-NET-1, RFC 5737) is reserved for documentation and should
# never be routed, causing SYN packets to be silently dropped on most networks.
# This test is skipped if the network returns an immediate error.
SKIP: {
    my $error_msg = '';
    my $error_time;
    my $start_time = EV::time;
    my $timer;

    my $r = EV::Redis->new(
        on_error => sub {
            $error_msg ||= $_[0];
            $error_time //= EV::time;
            undef $timer;
        },
        connect_timeout => 200,
    );

    $r->connect('192.0.2.1', 6379);

    $timer = EV::timer 2, 0, sub { $r->disconnect };
    EV::run;

    skip 'no error from unreachable host (network anomaly)', 2 unless $error_msg;

    my $elapsed = ($error_time || EV::time) - $start_time;
    skip 'immediate error (host reachable or refused)', 2 if $elapsed < 0.05;

    ok $elapsed < 1.0, sprintf 'connect_timeout fired within expected time (%.2fs)', $elapsed;
    like $error_msg, qr/./, "error message received: $error_msg";
}

done_testing;
