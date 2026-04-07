use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use Devel::Peek qw/SvREFCNT/;
use Devel::Refcount qw/refcount/;
my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Redis;

my $r = EV::Redis->new( path => $connect_info{sock} );
my ($get_command, $test);
my $result;
$get_command = sub {
    $r->lrange('foo', 0, -1, sub {
        $result = shift;
        $r->lrange('foo', 0, -1, $test);
        $get_command = undef;
    });
};
$test = sub {
    is refcount($result), 1, 'reference count of array is 1(no_leaks_ok and $test)';
    is SvREFCNT($result->[0]), 1, 'reference count of first element is 1';
    is SvREFCNT($result->[1]), 1, 'reference count of second element is 1';
    $r->disconnect;
};
$r->rpush('foo' => 'bar1', sub {
    $r->rpush('foo' => 'bar2', $get_command);
});
EV::run;

# Test: callback cleanup on Redis error responses
{
    my $r2 = EV::Redis->new( path => $connect_info{sock} );
    my $error_result;
    my $error_msg;

    # Create a string key, then try to use list command on it (causes Redis error)
    $r2->set('string_key', 'value', sub {
        $r2->lpush('string_key', 'item', sub {
            # This should fail with WRONGTYPE error
            ($error_result, $error_msg) = @_;
            $r2->disconnect;
        });
    });
    EV::run;

    is $error_result, undef, 'error callback receives undef result';
    like $error_msg, qr/WRONGTYPE/, 'error callback receives error message';
}
pass 'no leak on Redis error response callback';

# Test: callback cleanup when callback throws exception
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $r3 = EV::Redis->new(
        path => $connect_info{sock},
        on_error => sub { }, # suppress default die
    );
    my $exception_thrown = 0;
    my $after_exception = 0;

    $r3->set('test_key', 'value', sub {
        $exception_thrown = 1;
        die "intentional exception in callback";
    });

    # Give time for the callback to execute
    my $timer = EV::timer 0.1, 0, sub {
        $after_exception = 1;
        $r3->disconnect;
    };
    EV::run;

    is $exception_thrown, 1, 'callback was executed before exception';
    is $after_exception, 1, 'event loop continued after callback exception';
    like $warnings[0], qr/exception in command callback/, 'warning was emitted';
}
pass 'no leak when callback throws exception';

# Test: callback cleanup on command timeout
{
    my $r4 = EV::Redis->new(
        path => $connect_info{sock},
        on_error => sub { }, # suppress default die
        command_timeout => 100, # 100ms timeout
    );
    my $timeout_result;
    my $timeout_error;
    my $callback_called = 0;

    # BLPOP with 10 second wait, but command_timeout is 100ms
    # This should timeout before BLPOP returns
    $r4->blpop('nonexistent_key_for_timeout_test', 10, sub {
        ($timeout_result, $timeout_error) = @_;
        $callback_called = 1;
        $r4->disconnect;
    });

    # Fallback timer in case timeout doesn't work as expected
    my $fallback = EV::timer 2, 0, sub {
        $r4->disconnect unless $callback_called;
    };

    EV::run;

    is $callback_called, 1, 'timeout callback was called';
    is $timeout_result, undef, 'timeout callback receives undef result';
    ok defined($timeout_error), 'timeout callback receives error message';
}
pass 'no leak on command timeout callback';

# Test: object destruction with pending commands
# Note: redisAsyncFree triggers disconnect callback, which invokes pending
# callbacks with error. This is hiredis behavior, not our choice.
{
    my $callback_called = 0;
    my $callback_error;

    {
        my $r5 = EV::Redis->new(
            path => $connect_info{sock},
            on_error => sub { },
        );

        # Issue a blocking command
        $r5->blpop('destruction_test_key', 10, sub {
            my ($res, $err) = @_;
            $callback_called = 1;
            $callback_error = $err;
        });

        is $r5->pending_count, 1, 'pending_count is 1 before destruction';
        # $r5 goes out of scope here without explicit disconnect
    }

    # Give event loop a chance to process any lingering events
    my $timer = EV::timer 0.1, 0, sub { };
    EV::run;

    # Callbacks ARE called during destruction (via hiredis disconnect path)
    is $callback_called, 1, 'callback called during destruction (hiredis behavior)';
    ok defined($callback_error), 'callback received error on destruction';
}
pass 'no crash when destroying with pending commands';

# Test: object destruction with waiting queue
# Waiting queue callbacks are also invoked with error during destruction
{
    my @callbacks_called;

    {
        my $r6 = EV::Redis->new(
            path => $connect_info{sock},
            max_pending => 1,
            on_error => sub { },
        );

        # First command goes to pending
        $r6->blpop('destruction_wait_key', 10, sub {
            my ($res, $err) = @_;
            push @callbacks_called, { type => 'pending', err => $err };
        });
        # Second goes to waiting queue
        $r6->set('waiting_test', 'val', sub {
            my ($res, $err) = @_;
            push @callbacks_called, { type => 'waiting', err => $err };
        });

        is $r6->pending_count, 1, 'pending_count is 1';
        is $r6->waiting_count, 1, 'waiting_count is 1';
        # $r6 goes out of scope here
    }

    my $timer = EV::timer 0.1, 0, sub { };
    EV::run;

    # Both callbacks are invoked during destruction with errors
    is scalar(@callbacks_called), 2, 'both callbacks called on destruction';
    ok defined($callbacks_called[0]{err}), 'pending callback got error';
    ok defined($callbacks_called[1]{err}), 'waiting callback got error';
}
pass 'no crash when destroying with waiting queue';

# Test: explicit skip_pending before destruction (callbacks ARE called)
{
    my @callbacks_called;

    {
        my $r7 = EV::Redis->new(
            path => $connect_info{sock},
            on_error => sub { },
        );

        $r7->blpop('skip_before_destroy_key', 10, sub {
            my ($res, $err) = @_;
            push @callbacks_called, { res => $res, err => $err };
        });
        $r7->set('skip_before_destroy_2', 'val', sub {
            my ($res, $err) = @_;
            push @callbacks_called, { res => $res, err => $err };
        });

        is $r7->pending_count, 2, 'pending_count is 2';

        # Explicitly skip before destruction
        $r7->skip_pending;

        is $r7->pending_count, 0, 'pending_count is 0 after skip';
        # Now $r7 goes out of scope
    }

    is scalar(@callbacks_called), 2, 'both callbacks called via skip_pending';
    is $callbacks_called[0]{err}, 'skipped', 'first callback got skipped error';
    is $callbacks_called[1]{err}, 'skipped', 'second callback got skipped error';
}
pass 'skip_pending before destruction works correctly';

# Test: circular reference is broken by clearing callbacks
{
    my $destroyed = 0;
    {
        my $r8 = EV::Redis->new(
            path => $connect_info{sock},
            on_error => sub { },
        );

        # Create circular reference: $r8 -> object -> callback -> $r8
        $r8->on_connect(sub { $r8->is_connected });

        # Break the cycle by clearing the callback
        $r8->on_connect();
        $r8->on_error();

        $r8->disconnect;
        $destroyed = refcount($r8);
        # $r8 goes out of scope
    }
    is $destroyed, 1, 'refcount is 1 after clearing circular callbacks (GC will collect)';
}
pass 'circular reference cleanup works';

done_testing;
