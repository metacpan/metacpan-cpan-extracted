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

my ($redis_version, $redis_minor) = get_redis_version($connect_info{sock});
diag "Redis version: $redis_version.$redis_minor";

my $r = EV::Redis->new;
$r->connect_unix( $connect_info{sock} );

my $called = 0;
$r->command('get', 'foo', sub {
    my ($res, $err) = @_;

    $called++;
    ok !defined($res), 'nonexistent key returns undef';
    ok !defined $err, 'no error';

    $r->disconnect;
});
EV::run;
ok $called;

$called = 0;
$r->connect_unix( $connect_info{sock} );
$r->command('set', 'foo', 'bar', sub {
    my ($res, $err) = @_;

    $called++;
    is $res, 'OK';
    ok !defined $err, 'no error';

    $r->command('get', 'foo', sub {
        my ($res, $err) = @_;

        $called++;
        is $res, 'bar';
        ok !defined $err, 'no error';

        $r->disconnect;
    });
});
EV::run;
is $called, 2;

$called = 0;
$r->connect_unix( $connect_info{sock} );
$r->command('set', '1', 'one', sub {
    $r->command('set', '2', 'two', sub {
        $r->command('keys', '*', sub {
            my ($res) = @_;

            $called++;
            cmp_deeply($res, bag('foo', '1', '2'));

            $r->disconnect;
        });
    });
});
EV::run;
is $called, 1;

$called = 0;
$r->connect_unix( $connect_info{sock} );
$r->command('set', 'foo', sub {
    my ($res, $err) = @_;

    $called++;

    ok !defined $res, 'result is undef on error';
    ok defined $err, 'error message is set';

    $r->disconnect;
});
EV::run;
is $called, 1;

# Test: priority validation and clamping
{
    $r->connect_unix( $connect_info{sock} );

    # Default priority is 0
    is $r->priority, 0, 'default priority is 0';

    # Valid priorities
    $r->priority(-2);
    is $r->priority, -2, 'priority set to -2 (minimum)';

    $r->priority(2);
    is $r->priority, 2, 'priority set to 2 (maximum)';

    $r->priority(0);
    is $r->priority, 0, 'priority set back to 0';

    $r->priority(-1);
    is $r->priority, -1, 'priority set to -1';

    $r->priority(1);
    is $r->priority, 1, 'priority set to 1';

    # Out-of-range values should be clamped
    $r->priority(100);
    is $r->priority, 2, 'priority 100 clamped to 2';

    $r->priority(-100);
    is $r->priority, -2, 'priority -100 clamped to -2';

    $r->priority(3);
    is $r->priority, 2, 'priority 3 clamped to 2';

    $r->priority(-3);
    is $r->priority, -2, 'priority -3 clamped to -2';

    # Verify commands still work with different priorities
    my $done = 0;
    $r->priority(2);
    $r->ping(sub {
        my ($res, $err) = @_;
        is $res, 'PONG', 'ping works with high priority';
        $done = 1;
        $r->disconnect;
    });
    EV::run;
    ok $done, 'high priority command completed';
}

# Test: priority setting via constructor
{
    my $r_prio = EV::Redis->new(
        path => $connect_info{sock},
        priority => 1,
    );
    is $r_prio->priority, 1, 'priority set via constructor';
    $r_prio->disconnect;
    EV::run;
}

# Test: priority clamping via constructor
{
    my $r_prio2 = EV::Redis->new(
        path => $connect_info{sock},
        priority => 99,
    );
    is $r_prio2->priority, 2, 'priority clamped via constructor';
    $r_prio2->disconnect;
    EV::run;
}

# Test: priority change with active command timeout timer
# This verifies that changing priority while a timeout timer is active
# preserves the timeout behavior (tests ev_timer_again fix)
{
    my $r_timeout = EV::Redis->new(
        path => $connect_info{sock},
        command_timeout => 200,  # 200ms timeout
        on_error => sub { },
    );

    my $callback_called = 0;
    my $got_timeout = 0;
    my $start_time = EV::now;
    my $elapsed;

    # Issue a blocking command that will timeout
    $r_timeout->blpop('priority_timeout_test_key', 10, sub {
        my ($res, $err) = @_;
        $callback_called = 1;
        $elapsed = EV::now - $start_time;
        $got_timeout = 1 if defined($err);
        $r_timeout->disconnect;
    });

    # Change priority while timeout timer is active
    # This exercises the ev_timer_again code path
    $r_timeout->priority(1);
    $r_timeout->priority(-1);
    $r_timeout->priority(2);

    # Fallback timer in case timeout doesn't work
    my $fallback = EV::timer 2, 0, sub {
        $r_timeout->disconnect unless $callback_called;
    };

    EV::run;

    ok $callback_called, 'callback was called after priority changes';
    ok $got_timeout, 'command timed out correctly after priority changes';
    # Timeout should still occur around 200ms, not be reset or lost
    # Allow some slack for timing variations
    ok $elapsed < 0.5, "timeout occurred within reasonable time (${elapsed}s < 0.5s)";
}

# Test: constructor with explicit zero values
{
    my $r_zero = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 0,        # explicit 0 (unlimited)
        waiting_timeout => 0,    # explicit 0 (unlimited)
        priority => 0,           # explicit default
    );

    is $r_zero->max_pending, 0, 'max_pending explicitly set to 0';
    is $r_zero->priority, 0, 'priority explicitly set to 0';

    # connect_timeout => 0 means "immediate timeout" in hiredis, so test
    # it separately as a getter only (connecting with 0 timeout is flaky)
    $r_zero->connect_timeout(0);
    is $r_zero->connect_timeout, 0, 'connect_timeout 0 accepted';

    my $done = 0;
    $r_zero->ping(sub {
        $done = 1;
        $r_zero->disconnect;
    });
    EV::run;
    ok $done, 'connection with zero values works';
}

# Test: zero-length (empty) string arguments
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    # Test empty value
    $r->set('test:empty:value', '', sub {
        my ($res, $err) = @_;
        push @results, ['set_empty_value', $res, $err];

        $r->get('test:empty:value', sub {
            my ($res, $err) = @_;
            push @results, ['get_empty_value', $res, $err];

            # Test empty key (Redis allows this)
            $r->set('', 'empty_key_value', sub {
                my ($res, $err) = @_;
                push @results, ['set_empty_key', $res, $err];

                $r->get('', sub {
                    my ($res, $err) = @_;
                    push @results, ['get_empty_key', $res, $err];

                    # Test both empty
                    $r->set('', '', sub {
                        my ($res, $err) = @_;
                        push @results, ['set_both_empty', $res, $err];

                        $r->get('', sub {
                            my ($res, $err) = @_;
                            push @results, ['get_both_empty', $res, $err];
                            $r->disconnect;
                        });
                    });
                });
            });
        });
    });

    EV::run;

    is $results[0][1], 'OK', 'SET with empty value succeeds';
    is $results[1][1], '', 'GET returns empty string value';
    is $results[2][1], 'OK', 'SET with empty key succeeds';
    is $results[3][1], 'empty_key_value', 'GET with empty key returns correct value';
    is $results[4][1], 'OK', 'SET with empty key and empty value succeeds';
    is $results[5][1], '', 'GET with empty key returns empty value';
}

# Test: binary strings with embedded NUL bytes
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    # Create binary string with embedded NUL bytes
    my $binary_value = "hello\x00world\x00end";

    $r->set('test:binary:simple', $binary_value, sub {
        my ($res, $err) = @_;
        push @results, ['set_binary', $res, $err];

        $r->get('test:binary:simple', sub {
            my ($res, $err) = @_;
            push @results, ['get_binary', $res, $err];
            $r->disconnect;
        });
    });

    EV::run;

    is $results[0][1], 'OK', 'SET with binary value containing NUL succeeds';
    is $results[1][1], $binary_value, 'GET returns binary value with embedded NUL intact';
    is length($results[1][1]), length($binary_value), 'Binary value length preserved';
}

# Test: negative max_pending validation
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    my $died = 0;
    eval {
        $r->max_pending(-1);
    };
    $died = 1 if $@;

    ok $died, 'negative max_pending throws exception';
    like $@, qr/non-negative/, 'exception message mentions non-negative';

    $r->disconnect;
}

# Test: negative waiting_timeout validation
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    my $died = 0;
    eval {
        $r->waiting_timeout(-1);
    };
    $died = 1 if $@;

    ok $died, 'negative waiting_timeout throws exception';
    like $@, qr/non-negative/, 'exception message mentions non-negative';

    $r->disconnect;
}

# Test: negative connect_timeout validation
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    my $died = 0;
    eval {
        $r->connect_timeout(-1);
    };
    $died = 1 if $@;

    ok $died, 'negative connect_timeout throws exception';
    like $@, qr/non-negative/, 'exception message mentions non-negative';

    $r->disconnect;
}

# Test: negative command_timeout validation
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    my $died = 0;
    eval {
        $r->command_timeout(-1);
    };
    $died = 1 if $@;

    ok $died, 'negative command_timeout throws exception';
    like $@, qr/non-negative/, 'exception message mentions non-negative';

    $r->disconnect;
}

# Test: command() with insufficient arguments
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    # Only callback, no command name
    my $died = 0;
    eval {
        $r->command(sub { });
    };
    $died = 1 if $@;

    ok $died, 'command() with only callback throws exception';
    like $@, qr/Usage:/, 'exception mentions usage';

    $r->disconnect;
}

# Test: command() without callback (fire-and-forget)
# Non-CODE last argument is treated as a regular command arg, not a callback.
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    # Fire-and-forget: string args only, no callback
    eval { $r->command('SET', 'ff_test', 'value') };
    is $@, '', 'fire-and-forget command does not croak';

    # Verify the SET took effect
    my $got;
    $r->command('GET', 'ff_test', sub {
        ($got) = @_;
        $r->disconnect;
    });
    EV::run;
    is $got, 'value', 'fire-and-forget SET was executed by Redis';
}

# Test: clearing callbacks (both no-arg and undef work)
{
    # Don't auto-connect - just test the setter behavior
    my $r = EV::Redis->new;

    # Set callbacks and verify clearing with undef works
    $r->on_error(sub { });
    $r->on_error(undef);
    ok !defined($r->on_error), 'on_error cleared by undef';

    $r->on_connect(sub { });
    $r->on_connect(undef);
    ok !defined($r->on_connect), 'on_connect cleared by undef';

    $r->on_disconnect(sub { });
    $r->on_disconnect(undef);
    ok !defined($r->on_disconnect), 'on_disconnect cleared by undef';

    # Verify clearing with no-arg also works
    $r->on_error(sub { });
    $r->on_error();
    ok !defined($r->on_error), 'on_error cleared by no-arg call';

    $r->on_connect(sub { });
    $r->on_connect();
    ok !defined($r->on_connect), 'on_connect cleared by no-arg call';

    $r->on_disconnect(sub { });
    $r->on_disconnect();
    ok !defined($r->on_disconnect), 'on_disconnect cleared by no-arg call';
}

# Test: replacing callbacks (memory management)
{
    # Don't auto-connect - just test the setter behavior
    my $r = EV::Redis->new;

    # Set and replace callbacks multiple times
    for (1..5) {
        $r->on_error(sub { });
        $r->on_connect(sub { });
        $r->on_disconnect(sub { });
    }

    # Clear them
    $r->on_error(undef);
    $r->on_connect(undef);
    $r->on_disconnect(undef);

    ok 1, 'repeatedly replacing callbacks does not crash';
}

# Test: timeout getter methods return current value
{
    my $r = EV::Redis->new(
        connect_timeout => 5000,
        command_timeout => 3000,
    );

    is $r->connect_timeout(), 5000, 'connect_timeout getter returns set value';
    is $r->command_timeout(), 3000, 'command_timeout getter returns set value';

    # Modify and verify getter reflects change
    $r->connect_timeout(7000);
    $r->command_timeout(4000);
    is $r->connect_timeout(), 7000, 'connect_timeout getter returns updated value';
    is $r->command_timeout(), 4000, 'command_timeout getter returns updated value';
}

# Test: timeout getters return undef when not set
{
    my $r = EV::Redis->new;

    ok !defined($r->connect_timeout()), 'connect_timeout returns undef when not set';
    ok !defined($r->command_timeout()), 'command_timeout returns undef when not set';
}

# Test: callback clearing via no-argument call
{
    my $r = EV::Redis->new;

    my $called = 0;
    $r->on_connect(sub { $called++ });

    # Clear the handler by calling without arguments
    $r->on_connect();

    # Verify handler was cleared by setting a new one and checking it works
    my $new_called = 0;
    $r->on_connect(sub { $new_called++ });

    # The new handler should work (old one was cleared)
    $r->connect_unix($connect_info{sock});
    my $t; $t = EV::timer 0.1, 0, sub { $r->disconnect; undef $t };
    EV::run;

    is $called, 0, 'old on_connect handler was cleared';
    is $new_called, 1, 'new on_connect handler works after clearing';
}

# Test: empty array reply (LRANGE on empty/nonexistent list)
{
    $r->connect_unix($connect_info{sock});

    my @results;

    # First ensure key doesn't exist
    $r->del('empty_list_test', sub {
        # Now LRANGE should return empty array
        $r->lrange('empty_list_test', 0, -1, sub {
            my ($res, $err) = @_;
            push @results, [$res, $err];
            $r->disconnect;
        });
    });

    EV::run;

    ok !$results[0][1], 'no error for LRANGE on empty list';
    ok ref($results[0][0]) eq 'ARRAY', 'LRANGE returns array';
    is scalar(@{$results[0][0]}), 0, 'LRANGE returns empty array for nonexistent list';
}

# Test: timeout overflow protection
{
    my $r = EV::Redis->new;

    # Valid large timeout should work (about 23 days)
    eval { $r->connect_timeout(2000000000) };
    ok !$@, 'large valid timeout accepted';
    is $r->connect_timeout, 2000000000, 'large timeout value preserved';

    # Timeout exceeding max should croak
    eval { $r->connect_timeout(2000000001) };
    like $@, qr/timeout too large/, 'timeout exceeding max rejected';

    # Same for command_timeout
    eval { $r->command_timeout(2000000001) };
    like $@, qr/timeout too large/, 'command_timeout exceeding max rejected';

    # Same for waiting_timeout
    eval { $r->waiting_timeout(2000000001) };
    like $@, qr/waiting_timeout too large/, 'waiting_timeout exceeding max rejected';

    # Valid waiting_timeout should work
    eval { $r->waiting_timeout(60000) };
    ok !$@, 'normal waiting_timeout accepted';
    is $r->waiting_timeout, 60000, 'waiting_timeout value preserved';
}

# Test: command() without connection throws exception
{
    my $r = EV::Redis->new;

    my $died = 0;
    eval {
        $r->command('GET', 'key', sub { });
    };
    $died = 1 if $@;

    ok $died, 'command() without connection throws exception';
    like $@, qr/connection required/, 'exception mentions connection required';
}

# Test: AUTOLOAD command without connection throws exception
{
    my $r = EV::Redis->new;

    my $died = 0;
    eval {
        $r->get('key', sub { });
    };
    $died = 1 if $@;

    ok $died, 'AUTOLOAD command without connection throws exception';
    like $@, qr/connection required/, 'AUTOLOAD exception mentions connection required';
}

# Test: Redis transactions (MULTI/EXEC)
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    # Clean up test keys
    $r->del('tx_key1', 'tx_key2', 'tx_counter', sub {
        # Start transaction
        $r->multi(sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'multi', res => $res, err => $err };

            # Queue commands
            $r->set('tx_key1', 'value1', sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'set1', res => $res, err => $err };
            });

            $r->set('tx_key2', 'value2', sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'set2', res => $res, err => $err };
            });

            $r->incr('tx_counter', sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'incr', res => $res, err => $err };
            });

            $r->get('tx_key1', sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'get', res => $res, err => $err };
            });

            # Execute transaction
            $r->exec(sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'exec', res => $res, err => $err };
                $r->disconnect;
            });
        });
    });

    EV::run;

    is scalar(@results), 6, 'all transaction callbacks called';
    is $results[0]{res}, 'OK', 'MULTI returns OK';
    is $results[1]{res}, 'QUEUED', 'SET returns QUEUED inside transaction';
    is $results[2]{res}, 'QUEUED', 'second SET returns QUEUED';
    is $results[3]{res}, 'QUEUED', 'INCR returns QUEUED';
    is $results[4]{res}, 'QUEUED', 'GET returns QUEUED';
    ok !$results[5]{err}, 'EXEC has no error';
    is ref($results[5]{res}), 'ARRAY', 'EXEC returns array';
    is scalar(@{$results[5]{res}}), 4, 'EXEC returns 4 results';
    is $results[5]{res}[0], 'OK', 'first SET result is OK';
    is $results[5]{res}[1], 'OK', 'second SET result is OK';
    is $results[5]{res}[2], 1, 'INCR result is 1';
    is $results[5]{res}[3], 'value1', 'GET result is value1';
}

# Test: DISCARD aborts transaction
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->set('discard_test', 'original', sub {
        $r->multi(sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'multi', res => $res };

            $r->set('discard_test', 'changed', sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'set', res => $res };
            });

            $r->discard(sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'discard', res => $res };

                # Verify value unchanged
                $r->get('discard_test', sub {
                    my ($res, $err) = @_;
                    push @results, { cmd => 'get', res => $res };
                    $r->disconnect;
                });
            });
        });
    });

    EV::run;

    is scalar(@results), 4, 'all discard test callbacks called';
    is $results[0]{res}, 'OK', 'MULTI returns OK';
    is $results[1]{res}, 'QUEUED', 'SET returns QUEUED';
    is $results[2]{res}, 'OK', 'DISCARD returns OK';
    is $results[3]{res}, 'original', 'value unchanged after DISCARD';
}

# Test: WATCH for optimistic locking (Redis 2.2+)
SKIP: {
    skip 'WATCH requires Redis 2.2+', 8 if $redis_version < 2 || ($redis_version == 2 && $redis_minor < 2);

    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    # Setup: set initial value
    $r->set('watch_key', '100', sub {
        # Watch the key
        $r->watch('watch_key', sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'watch', res => $res, err => $err };

            # Start transaction
            $r->multi(sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'multi', res => $res };

                $r->incr('watch_key', sub {
                    my ($res, $err) = @_;
                    push @results, { cmd => 'incr', res => $res };
                });

                $r->exec(sub {
                    my ($res, $err) = @_;
                    push @results, { cmd => 'exec', res => $res, err => $err };

                    # Verify result
                    $r->get('watch_key', sub {
                        my ($res, $err) = @_;
                        push @results, { cmd => 'get', res => $res };
                        $r->disconnect;
                    });
                });
            });
        });
    });

    EV::run;

    is scalar(@results), 5, 'all WATCH test callbacks called';
    is $results[0]{res}, 'OK', 'WATCH returns OK';
    is $results[1]{res}, 'OK', 'MULTI returns OK';
    is $results[2]{res}, 'QUEUED', 'INCR returns QUEUED';
    ok !$results[3]{err}, 'EXEC has no error';
    is ref($results[3]{res}), 'ARRAY', 'EXEC returns array (not aborted)';
    is $results[3]{res}[0], 101, 'INCR result is 101';
    is $results[4]{res}, '101', 'final value is 101';
}

# Test: EVAL Lua scripting (Redis 2.6+)
SKIP: {
    skip 'EVAL requires Redis 2.6+', 6 if $redis_version < 2 || ($redis_version == 2 && $redis_minor < 6);

    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    # Simple script: return arguments
    my $script1 = q{return {KEYS[1], ARGV[1], ARGV[2]}};

    $r->eval($script1, 1, 'mykey', 'arg1', 'arg2', sub {
        my ($res, $err) = @_;
        push @results, { cmd => 'eval1', res => $res, err => $err };

        # Script with computation
        my $script2 = q{return tonumber(ARGV[1]) + tonumber(ARGV[2])};
        $r->eval($script2, 0, '10', '25', sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'eval2', res => $res, err => $err };
            $r->disconnect;
        });
    });

    EV::run;

    is scalar(@results), 2, 'both EVAL callbacks called';
    ok !$results[0]{err}, 'first EVAL has no error';
    is ref($results[0]{res}), 'ARRAY', 'EVAL returns array';
    is_deeply $results[0]{res}, ['mykey', 'arg1', 'arg2'], 'EVAL returns correct values';
    ok !$results[1]{err}, 'second EVAL has no error';
    is $results[1]{res}, 35, 'EVAL arithmetic works';
}

# Test: SCAN cursor iteration (Redis 2.8+)
SKIP: {
    skip 'SCAN requires Redis 2.8+', 4 if $redis_version < 2 || ($redis_version == 2 && $redis_minor < 8);

    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    # Setup a unique key for this test, then scan for it specifically
    my $unique_key = "scan_unique_$$";
    $r->set($unique_key, 'value', sub {
        # SCAN returns [cursor, [keys...]]
        $r->scan(0, 'MATCH', $unique_key, 'COUNT', 1000, sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'scan', res => $res, err => $err };
            $r->del($unique_key, sub { $r->disconnect; });
        });
    });

    EV::run;

    is scalar(@results), 1, 'SCAN callback called';
    ok !$results[0]{err}, 'SCAN has no error';
    is ref($results[0]{res}), 'ARRAY', 'SCAN returns array [cursor, keys]';
    is ref($results[0]{res}[1]), 'ARRAY', 'SCAN second element is array of keys';
}

# Test: HGETALL returns flat array
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->del('hash_test', sub {
        $r->hset('hash_test', 'field1', 'value1', sub {
            $r->hset('hash_test', 'field2', 'value2', sub {
                $r->hgetall('hash_test', sub {
                    my ($res, $err) = @_;
                    push @results, { cmd => 'hgetall', res => $res, err => $err };
                    $r->disconnect;
                });
            });
        });
    });

    EV::run;

    is scalar(@results), 1, 'HGETALL callback called';
    ok !$results[0]{err}, 'HGETALL has no error';
    is ref($results[0]{res}), 'ARRAY', 'HGETALL returns array';
    is scalar(@{$results[0]{res}}), 4, 'HGETALL returns 4 elements (2 field-value pairs)';
    my %hash = @{$results[0]{res}};
    is $hash{field1}, 'value1', 'HGETALL field1 correct';
    is $hash{field2}, 'value2', 'HGETALL field2 correct';
}

# Test: SETEX with expiry (Redis 2.0+)
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->setex('expiry_test', 10, 'temporary', sub {
        my ($res, $err) = @_;
        push @results, { cmd => 'setex', res => $res, err => $err };

        $r->ttl('expiry_test', sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'ttl', res => $res, err => $err };
            $r->disconnect;
        });
    });

    EV::run;

    is scalar(@results), 2, 'SETEX/TTL callbacks called';
    is $results[0]{res}, 'OK', 'SETEX returns OK';
    ok $results[1]{res} > 0 && $results[1]{res} <= 10, 'TTL returns valid expiry';
}

# Test: MSET/MGET multiple keys
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->mset('mkey1', 'mval1', 'mkey2', 'mval2', 'mkey3', 'mval3', sub {
        my ($res, $err) = @_;
        push @results, { cmd => 'mset', res => $res, err => $err };

        $r->mget('mkey1', 'mkey2', 'mkey3', 'nonexistent', sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'mget', res => $res, err => $err };
            $r->disconnect;
        });
    });

    EV::run;

    is scalar(@results), 2, 'MSET/MGET callbacks called';
    is $results[0]{res}, 'OK', 'MSET returns OK';
    is ref($results[1]{res}), 'ARRAY', 'MGET returns array';
    is_deeply $results[1]{res}, ['mval1', 'mval2', 'mval3', undef], 'MGET returns correct values (including nil)';
}

# Test: LPUSH/LRANGE list operations
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->del('list_test', sub {
        $r->lpush('list_test', 'c', 'b', 'a', sub {  # Results in: a, b, c
            my ($res, $err) = @_;
            push @results, { cmd => 'lpush', res => $res, err => $err };

            $r->lrange('list_test', 0, -1, sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'lrange', res => $res, err => $err };
                $r->disconnect;
            });
        });
    });

    EV::run;

    is scalar(@results), 2, 'LPUSH/LRANGE callbacks called';
    is $results[0]{res}, 3, 'LPUSH returns list length';
    is_deeply $results[1]{res}, ['a', 'b', 'c'], 'LRANGE returns list in order';
}

# Test: SADD/SMEMBERS set operations
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->del('set_test', sub {
        $r->sadd('set_test', 'a', 'b', 'c', 'a', sub {  # 'a' duplicate ignored
            my ($res, $err) = @_;
            push @results, { cmd => 'sadd', res => $res, err => $err };

            $r->smembers('set_test', sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'smembers', res => $res, err => $err };
                $r->disconnect;
            });
        });
    });

    EV::run;

    is scalar(@results), 2, 'SADD/SMEMBERS callbacks called';
    is $results[0]{res}, 3, 'SADD returns number of added elements';
    is ref($results[1]{res}), 'ARRAY', 'SMEMBERS returns array';
    is scalar(@{$results[1]{res}}), 3, 'SMEMBERS returns 3 unique elements';
}

# Test: ZADD/ZRANGE sorted set operations
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->del('zset_test', sub {
        $r->zadd('zset_test', 3, 'three', 1, 'one', 2, 'two', sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'zadd', res => $res, err => $err };

            $r->zrange('zset_test', 0, -1, sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'zrange', res => $res, err => $err };
                $r->disconnect;
            });
        });
    });

    EV::run;

    is scalar(@results), 2, 'ZADD/ZRANGE callbacks called';
    is $results[0]{res}, 3, 'ZADD returns number of added elements';
    is_deeply $results[1]{res}, ['one', 'two', 'three'], 'ZRANGE returns sorted order';
}

# Test: EXISTS and DEL
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->set('exists_test', 'value', sub {
        $r->exists('exists_test', sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'exists1', res => $res };

            $r->del('exists_test', sub {
                my ($res, $err) = @_;
                push @results, { cmd => 'del', res => $res };

                $r->exists('exists_test', sub {
                    my ($res, $err) = @_;
                    push @results, { cmd => 'exists2', res => $res };
                    $r->disconnect;
                });
            });
        });
    });

    EV::run;

    is $results[0]{res}, 1, 'EXISTS returns 1 for existing key';
    is $results[1]{res}, 1, 'DEL returns number of deleted keys';
    is $results[2]{res}, 0, 'EXISTS returns 0 after DEL';
}

# Test: TYPE command
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->set('type_string', 'value', sub {
        $r->lpush('type_list', 'item', sub {
            $r->sadd('type_set', 'member', sub {
                $r->type('type_string', sub {
                    push @results, shift;
                    $r->type('type_list', sub {
                        push @results, shift;
                        $r->type('type_set', sub {
                            push @results, shift;
                            $r->type('nonexistent', sub {
                                push @results, shift;
                                $r->disconnect;
                            });
                        });
                    });
                });
            });
        });
    });

    EV::run;

    is $results[0], 'string', 'TYPE returns string';
    is $results[1], 'list', 'TYPE returns list';
    is $results[2], 'set', 'TYPE returns set';
    is $results[3], 'none', 'TYPE returns none for nonexistent';
}

done_testing;
