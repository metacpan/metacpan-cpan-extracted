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

my $r = EV::Redis->new;

# Test max_pending limit with waiting queue
{
    $r->connect_unix( $connect_info{sock} );
    is $r->max_pending, 0, 'max_pending defaults to 0 (unlimited)';
    is $r->waiting_count, 0, 'waiting_count is 0 initially';

    $r->max_pending(2);
    is $r->max_pending, 2, 'max_pending set to 2';

    my @results;
    $r->command('blpop', 'key1', 10, sub { push @results, ['cmd1', @_] });
    is $r->pending_count, 1, 'pending_count is 1';
    is $r->waiting_count, 0, 'waiting_count is 0';

    $r->command('blpop', 'key2', 10, sub { push @results, ['cmd2', @_] });
    is $r->pending_count, 2, 'pending_count is 2';
    is $r->waiting_count, 0, 'waiting_count is 0';

    # Third command should be queued, not sent
    $r->command('blpop', 'key3', 10, sub { push @results, ['cmd3', @_] });
    is $r->pending_count, 2, 'pending_count still 2 (at limit)';
    is $r->waiting_count, 1, 'waiting_count is 1 (queued)';

    # Fourth command also queued
    $r->command('blpop', 'key4', 10, sub { push @results, ['cmd4', @_] });
    is $r->pending_count, 2, 'pending_count still 2';
    is $r->waiting_count, 2, 'waiting_count is 2';

    my $timer = EV::timer 0.1, 0, sub {
        $r->skip_pending;
        is $r->pending_count, 0, 'pending_count is 0 after skip';
        is $r->waiting_count, 0, 'waiting_count is 0 after skip';
        $r->disconnect;
    };
    EV::run;

    is scalar(@results), 4, 'all 4 callbacks called';
    # Waiting queue cleared first (FIFO: cmd3, cmd4), then pending (FIFO: cmd1, cmd2)
    my %seen = map { $_->[0] => $_->[2] } @results;
    is $seen{cmd1}, 'skipped', 'cmd1 was skipped';
    is $seen{cmd2}, 'skipped', 'cmd2 was skipped';
    is $seen{cmd3}, 'skipped', 'cmd3 was skipped';
    is $seen{cmd4}, 'skipped', 'cmd4 was skipped';

    $r->max_pending(0);
}

# Test waiting queue drain behavior
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;
    my $check_counts = sub {
        my ($exp_pending, $exp_waiting, $msg) = @_;
        is $r->pending_count, $exp_pending, "$msg: pending=$exp_pending";
        is $r->waiting_count, $exp_waiting, "$msg: waiting=$exp_waiting";
    };

    # Queue 4 SET commands - 2 should be pending, 2 waiting
    $r->command('set', 'drain_test_1', 'val1', sub { push @results, ['set1', @_] });
    $r->command('set', 'drain_test_2', 'val2', sub { push @results, ['set2', @_] });
    $check_counts->(2, 0, 'after 2 commands');

    $r->command('set', 'drain_test_3', 'val3', sub { push @results, ['set3', @_] });
    # Last command disconnects after verifying drain
    $r->command('set', 'drain_test_4', 'val4', sub {
        push @results, ['set4', @_];
        # pending_count is 1 (current) since it's decremented after callback
        is $r->pending_count, 1, 'pending_count is 1 in last callback (self)';
        is $r->waiting_count, 0, 'waiting_count is 0 in last callback';
        $r->disconnect;
    });
    $check_counts->(2, 2, 'after 4 commands');

    # Run event loop - responses should drain the waiting queue
    EV::run;

    # All commands should have completed
    is scalar(@results), 4, 'all 4 callbacks executed';

    # Verify all succeeded
    for my $res (@results) {
        is $res->[1], 'OK', "$res->[0] returned OK";
    }

    # Verify the values were actually set
    $r->connect_unix( $connect_info{sock} );
    my $verified = 0;
    $r->command('get', 'drain_test_4', sub {
        my ($res, $err) = @_;
        is $res, 'val4', 'drain_test_4 has correct value';
        $verified = 1;
        $r->disconnect;
    });
    EV::run;
    ok $verified, 'verification callback executed';

    $r->max_pending(0);
}

# Test pending_count and skip_pending
{
    my @results;
    $r->connect_unix( $connect_info{sock} );

    is $r->pending_count, 0, 'pending_count is 0 initially';

    $r->command('blpop', 'nonexistent_key', 10, sub {
        push @results, \@_;
    });
    is $r->pending_count, 1, 'pending_count is 1 after first command';

    $r->command('blpop', 'nonexistent_key2', 10, sub {
        push @results, \@_;
    });
    is $r->pending_count, 2, 'pending_count is 2 after second command';

    my $timer = EV::timer 0.1, 0, sub {
        $r->skip_pending;
        is $r->pending_count, 0, 'pending_count is 0 after skip_pending';
        $r->disconnect;
    };
    EV::run;

    is scalar(@results), 2, 'both callbacks called';
    is $results[0][0], undef, 'first result is undef';
    is $results[0][1], 'skipped', 'first error is skipped';
    is $results[1][0], undef, 'second result is undef';
    is $results[1][1], 'skipped', 'second error is skipped';
}

# Test skip_waiting (only waiting queue, not pending)
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;

    # 2 commands sent to Redis (pending)
    $r->command('set', 'sw_test_1', 'val1', sub { push @results, ['cmd1', @_] });
    $r->command('set', 'sw_test_2', 'val2', sub { push @results, ['cmd2', @_] });
    # 2 commands queued locally (waiting)
    $r->command('set', 'sw_test_3', 'val3', sub { push @results, ['cmd3', @_] });
    $r->command('set', 'sw_test_4', 'val4', sub {
        push @results, ['cmd4', @_];
        $r->disconnect;
    });

    is $r->pending_count, 2, 'pending_count is 2';
    is $r->waiting_count, 2, 'waiting_count is 2';

    # Skip only waiting - pending should complete normally
    $r->skip_waiting;

    is $r->pending_count, 2, 'pending_count still 2 after skip_waiting';
    is $r->waiting_count, 0, 'waiting_count is 0 after skip_waiting';

    EV::run;

    is scalar(@results), 4, 'all 4 callbacks executed';
    # Waiting commands skipped immediately
    my %seen = map { $_->[0] => $_ } @results;
    is $seen{cmd1}[1], 'OK', 'cmd1 completed normally';
    is $seen{cmd2}[1], 'OK', 'cmd2 completed normally';
    is $seen{cmd3}[2], 'skipped', 'cmd3 was skipped';
    is $seen{cmd4}[2], 'skipped', 'cmd4 was skipped';

    $r->max_pending(0);
}

# Test skip_pending from inside callback
{
    $r->connect_unix( $connect_info{sock} );

    my @results;
    my $skip_called = 0;

    # First command will call skip_pending
    $r->command('set', 'skip_test_1', 'val1', sub {
        push @results, ['cmd1', @_];
        $skip_called = 1;
        $r->skip_pending;
        $r->disconnect;
    });
    $r->command('set', 'skip_test_2', 'val2', sub {
        push @results, ['cmd2', @_];
    });
    $r->command('set', 'skip_test_3', 'val3', sub {
        push @results, ['cmd3', @_];
    });

    is $r->pending_count, 3, 'pending_count is 3 before run';
    EV::run;

    ok $skip_called, 'skip_pending was called from callback';
    is scalar(@results), 3, 'all 3 callbacks executed';
    is $results[0][0], 'cmd1', 'first result is cmd1';
    is $results[0][1], 'OK', 'cmd1 succeeded normally';
    is $results[1][0], 'cmd2', 'second result is cmd2';
    is $results[1][2], 'skipped', 'cmd2 was skipped';
    is $results[2][0], 'cmd3', 'third result is cmd3';
    is $results[2][2], 'skipped', 'cmd3 was skipped';
}

# Test waiting queue cleared on disconnect (default behavior)
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    is $r->resume_waiting_on_reconnect, 0, 'resume_waiting_on_reconnect defaults to 0';

    my @results;
    $r->command('set', 'dc_test_1', 'val1', sub {
        push @results, ['cmd1', @_];
        # Disconnect while cmd2 is waiting
        $r->disconnect;
    });
    $r->command('set', 'dc_test_2', 'val2', sub {
        push @results, ['cmd2', @_];
    });

    is $r->pending_count, 1, 'pending_count is 1';
    is $r->waiting_count, 1, 'waiting_count is 1';

    EV::run;

    is scalar(@results), 2, 'both callbacks executed';
    is $results[0][0], 'cmd1', 'first is cmd1';
    is $results[0][1], 'OK', 'cmd1 succeeded';
    is $results[1][0], 'cmd2', 'second is cmd2';
    is $results[1][2], 'disconnected', 'cmd2 got disconnect error';

    $r->max_pending(0);
}

# Test waiting_timeout
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    $r->waiting_timeout(100);  # 100ms timeout

    my @results;

    # First command goes to pending
    $r->command('blpop', 'wt_test_key', 10, sub {
        push @results, ['cmd1', @_];
    });
    # Second and third go to waiting queue
    $r->command('set', 'wt_test_2', 'val2', sub {
        push @results, ['cmd2', @_];
    });
    $r->command('set', 'wt_test_3', 'val3', sub {
        push @results, ['cmd3', @_];
    });

    is $r->pending_count, 1, 'pending_count is 1';
    is $r->waiting_count, 2, 'waiting_count is 2';

    # Wait for timeout to expire
    my $timer = EV::timer 0.2, 0, sub {
        # By now, waiting commands should have timed out
        is $r->waiting_count, 0, 'waiting_count is 0 after timeout';
        $r->skip_pending;
        $r->disconnect;
    };
    EV::run;

    is scalar(@results), 3, 'all 3 callbacks executed';
    my %seen = map { $_->[0] => $_ } @results;
    is $seen{cmd2}[2], 'waiting timeout', 'cmd2 got waiting timeout';
    is $seen{cmd3}[2], 'waiting timeout', 'cmd3 got waiting timeout';

    $r->max_pending(0);
    $r->waiting_timeout(0);
}

# Edge case: skip_pending/skip_waiting when queues are empty
{
    $r->connect_unix( $connect_info{sock} );

    my $done = 0;
    # Issue a command to ensure connection is established
    $r->command('ping', sub {
        my ($res, $err) = @_;

        # Note: pending_count is 1 inside callback (current command not yet decremented)
        is $r->pending_count, 1, 'pending_count is 1 inside callback (self)';
        is $r->waiting_count, 0, 'waiting_count is 0';

        # Should not crash or error when only current callback pending
        $r->skip_pending;
        $r->skip_waiting;

        # Current callback is not skipped (only others would be)
        is $r->pending_count, 1, 'pending_count still 1 (current cb not skipped)';
        is $r->waiting_count, 0, 'waiting_count still 0 after skip_waiting on empty';

        $done = 1;
        $r->disconnect;
    });
    EV::run;
    ok $done, 'skip on empty queues test completed';
}

# Edge case: changing max_pending while commands are queued
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    # First command goes to pending
    $r->command('set', 'mp_change_1', 'val1', sub { push @results, ['cmd1', @_] });
    # Second goes to waiting
    $r->command('set', 'mp_change_2', 'val2', sub { push @results, ['cmd2', @_] });
    # Third goes to waiting
    $r->command('set', 'mp_change_3', 'val3', sub { push @results, ['cmd3', @_] });

    is $r->pending_count, 1, 'pending_count is 1';
    is $r->waiting_count, 2, 'waiting_count is 2';

    # Increase max_pending - should immediately send waiting commands
    $r->max_pending(10);

    # All waiting commands should now be pending
    is $r->pending_count, 3, 'pending_count is 3 after increasing max_pending';
    is $r->waiting_count, 0, 'waiting_count is 0 after increasing max_pending';

    # Add final command to disconnect
    $r->command('set', 'mp_change_4', 'val4', sub {
        push @results, ['cmd4', @_];
        $r->disconnect;
    });

    EV::run;

    is scalar(@results), 4, 'all 4 callbacks executed';
    for my $res (@results) {
        is $res->[1], 'OK', "$res->[0] succeeded";
    }

    $r->max_pending(0);
}

# Edge case: decreasing max_pending while commands are pending
{
    $r->connect_unix( $connect_info{sock} );

    my @results;

    # Queue 3 commands (all pending since no limit)
    $r->command('set', 'mp_dec_1', 'val1', sub { push @results, ['cmd1', @_] });
    $r->command('set', 'mp_dec_2', 'val2', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'mp_dec_3', 'val3', sub { push @results, ['cmd3', @_] });

    is $r->pending_count, 3, 'pending_count is 3';

    # Set max_pending to 1 - should not affect already pending commands
    $r->max_pending(1);

    is $r->pending_count, 3, 'pending_count still 3 (already sent)';
    is $r->waiting_count, 0, 'waiting_count is 0';

    # New command should go to waiting since pending > max_pending
    $r->command('set', 'mp_dec_4', 'val4', sub {
        push @results, ['cmd4', @_];
        $r->disconnect;
    });

    is $r->waiting_count, 1, 'new command goes to waiting';

    EV::run;

    is scalar(@results), 4, 'all 4 callbacks executed';

    $r->max_pending(0);
}

# Edge case: skip_waiting from inside callback
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    # First command - will skip waiting queue from callback
    $r->command('set', 'sw_cb_1', 'val1', sub {
        push @results, ['cmd1', @_];
        # Skip waiting commands from inside callback
        $r->skip_waiting;
    });

    # These go to waiting queue
    $r->command('set', 'sw_cb_2', 'val2', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'sw_cb_3', 'val3', sub {
        push @results, ['cmd3', @_];
        $r->disconnect;
    });

    is $r->pending_count, 1, 'pending_count is 1';
    is $r->waiting_count, 2, 'waiting_count is 2';

    EV::run;

    is scalar(@results), 3, 'all 3 callbacks executed';
    is $results[0][0], 'cmd1', 'cmd1 executed first';
    is $results[0][1], 'OK', 'cmd1 succeeded';

    # cmd2 and cmd3 should be skipped
    my %seen = map { $_->[0] => $_ } @results;
    is $seen{cmd2}[2], 'skipped', 'cmd2 was skipped';
    is $seen{cmd3}[2], 'skipped', 'cmd3 was skipped';

    $r->max_pending(0);
}

# Edge case: multiple rapid skip calls
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;

    $r->command('blpop', 'rapid_key', 10, sub { push @results, ['cmd1', @_] });
    $r->command('blpop', 'rapid_key2', 10, sub { push @results, ['cmd2', @_] });
    $r->command('set', 'rapid_3', 'val', sub { push @results, ['cmd3', @_] });
    $r->command('set', 'rapid_4', 'val', sub { push @results, ['cmd4', @_] });

    is $r->pending_count, 2, 'pending_count is 2';
    is $r->waiting_count, 2, 'waiting_count is 2';

    # Multiple rapid skip calls
    $r->skip_waiting;
    $r->skip_waiting;  # Should be no-op
    $r->skip_pending;
    $r->skip_pending;  # Should be no-op

    is $r->pending_count, 0, 'pending_count is 0';
    is $r->waiting_count, 0, 'waiting_count is 0';

    $r->disconnect;
    EV::run;

    is scalar(@results), 4, 'all 4 callbacks executed';
    for my $res (@results) {
        is $res->[2], 'skipped', "$res->[0] was skipped";
    }

    $r->max_pending(0);
}

# Edge case: very short waiting_timeout (immediate expiry)
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    $r->waiting_timeout(1);  # 1ms - nearly immediate

    my @results;

    # First command blocks
    $r->command('blpop', 'short_timeout_key', 10, sub {
        push @results, ['cmd1', @_];
    });

    # These should timeout almost immediately
    $r->command('set', 'short_2', 'val', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'short_3', 'val', sub { push @results, ['cmd3', @_] });

    is $r->waiting_count, 2, 'waiting_count is 2';

    my $timer = EV::timer 0.1, 0, sub {
        is $r->waiting_count, 0, 'waiting_count is 0 after short timeout';
        $r->skip_pending;
        $r->disconnect;
    };
    EV::run;

    is scalar(@results), 3, 'all 3 callbacks executed';
    my %seen = map { $_->[0] => $_ } @results;
    is $seen{cmd2}[2], 'waiting timeout', 'cmd2 got waiting timeout';
    is $seen{cmd3}[2], 'waiting timeout', 'cmd3 got waiting timeout';

    $r->max_pending(0);
    $r->waiting_timeout(0);
}

# Edge case: disable waiting_timeout while commands are waiting
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    $r->waiting_timeout(50);  # 50ms

    my @results;

    $r->command('blpop', 'disable_timeout_key', 10, sub {
        push @results, ['cmd1', @_];
    });
    $r->command('set', 'disable_2', 'val', sub { push @results, ['cmd2', @_] });

    is $r->waiting_count, 1, 'waiting_count is 1';

    # Disable timeout before it expires
    $r->waiting_timeout(0);

    # Wait longer than original timeout
    my $timer = EV::timer 0.1, 0, sub {
        # Command should still be waiting (timeout disabled)
        is $r->waiting_count, 1, 'waiting_count still 1 after disabling timeout';
        $r->skip_pending;
        $r->skip_waiting;
        $r->disconnect;
    };
    EV::run;

    is scalar(@results), 2, 'both callbacks executed';

    $r->max_pending(0);
}

# Edge case: enable waiting_timeout while commands are already waiting
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    # No timeout initially

    my @results;

    $r->command('blpop', 'enable_timeout_key', 10, sub {
        push @results, ['cmd1', @_];
    });
    $r->command('set', 'enable_2', 'val', sub { push @results, ['cmd2', @_] });

    is $r->waiting_count, 1, 'waiting_count is 1';

    # Enable timeout after commands are queued
    $r->waiting_timeout(50);  # 50ms

    my $timer = EV::timer 0.15, 0, sub {
        # Command should have timed out
        is $r->waiting_count, 0, 'waiting_count is 0 after enabling timeout';
        $r->skip_pending;
        $r->disconnect;
    };
    EV::run;

    is scalar(@results), 2, 'both callbacks executed';
    my %seen = map { $_->[0] => $_ } @results;
    is $seen{cmd2}[2], 'waiting timeout', 'cmd2 got waiting timeout after enabling';

    $r->max_pending(0);
    $r->waiting_timeout(0);
}

# Edge case: nested commands from within callback with max_pending
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    $r->command('set', 'nested_1', 'val1', sub {
        push @results, ['cmd1', @_];

        # Issue more commands from within callback
        $r->command('set', 'nested_2', 'val2', sub {
            push @results, ['cmd2', @_];

            $r->command('set', 'nested_3', 'val3', sub {
                push @results, ['cmd3', @_];
                $r->disconnect;
            });
        });
    });

    EV::run;

    is scalar(@results), 3, 'all 3 nested callbacks executed';
    for my $res (@results) {
        is $res->[1], 'OK', "$res->[0] succeeded";
    }

    $r->max_pending(0);
}

# Edge case: disconnect with pending/waiting commands clears waiting
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    $r->command('set', 'dc_wait_1', 'val1', sub {
        push @results, ['cmd1', @_];
        # Disconnect while cmd2 is waiting
        $r->disconnect;
    });
    $r->command('set', 'dc_wait_2', 'val2', sub {
        push @results, ['cmd2', @_];
    });

    is $r->waiting_count, 1, 'cmd2 is waiting';

    EV::run;

    is scalar(@results), 2, 'both callbacks executed';
    is $results[0][0], 'cmd1', 'cmd1 first';
    is $results[0][1], 'OK', 'cmd1 succeeded';
    is $results[1][0], 'cmd2', 'cmd2 second';
    is $results[1][2], 'disconnected', 'cmd2 got disconnect error';

    $r->max_pending(0);
}

# Edge case: reconnect after disconnect (separate event loop iterations)
{
    $r->connect_unix( $connect_info{sock} );

    my @results;

    $r->command('set', 'recon_1', 'val1', sub {
        push @results, ['cmd1', @_];
        $r->disconnect;
    });

    EV::run;

    is $results[0][1], 'OK', 'cmd1 succeeded before disconnect';

    # Now reconnect in a new event loop iteration
    $r->connect_unix( $connect_info{sock} );
    $r->command('set', 'recon_2', 'val2', sub {
        push @results, ['cmd2', @_];
        $r->disconnect;
    });

    EV::run;

    is scalar(@results), 2, 'both callbacks executed';
    is $results[1][0], 'cmd2', 'cmd2 executed after reconnect';
    is $results[1][1], 'OK', 'cmd2 succeeded';
}

# Edge case: max_pending = 1 (single command at a time)
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;
    my @order;

    for my $i (1..5) {
        $r->command('set', "single_$i", "val$i", sub {
            push @order, $i;
            push @results, ["cmd$i", @_];
            $r->disconnect if $i == 5;
        });
    }

    is $r->pending_count, 1, 'only 1 pending';
    is $r->waiting_count, 4, '4 waiting';

    EV::run;

    is scalar(@results), 5, 'all 5 callbacks executed';
    is_deeply \@order, [1, 2, 3, 4, 5], 'commands executed in order';
    for my $res (@results) {
        is $res->[1], 'OK', "$res->[0] succeeded";
    }

    $r->max_pending(0);
}

# Edge case: command issued right after disconnect (before reconnect)
{
    $r->connect_unix( $connect_info{sock} );

    my @results;
    my $error_caught = 0;

    $r->on_error(sub {
        $error_caught = 1;
    });

    $r->command('set', 'after_dc_1', 'val1', sub {
        push @results, ['cmd1', @_];
        $r->disconnect;

        # Try to issue command after disconnect
        eval {
            $r->command('set', 'after_dc_2', 'val2', sub {
                push @results, ['cmd2', @_];
            });
        };
        like $@, qr/connection required/, 'command after disconnect croaks';
    });

    EV::run;

    is $results[0][1], 'OK', 'cmd1 succeeded';

    # Reset error handler
    $r->on_error(sub { die @_ });
}

# Edge case: waiting_timeout with commands added during expiration callback
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    $r->waiting_timeout(50);  # 50ms

    my @results;
    my $added_during_timeout = 0;

    # Blocking command
    $r->command('blpop', 'expire_add_key', 10, sub {
        push @results, ['cmd1', @_];
    });

    # This will timeout, but we'll add another command during the timeout callback
    $r->command('set', 'expire_add_2', 'val', sub {
        push @results, ['cmd2', @_];
        # Add a new command during the timeout callback
        if (!$added_during_timeout) {
            $added_during_timeout = 1;
            $r->command('set', 'expire_add_3', 'val', sub {
                push @results, ['cmd3', @_];
            });
        }
    });

    my $timer = EV::timer 0.5, 0, sub {
        $r->skip_pending;
        $r->skip_waiting;
        $r->disconnect;
    };
    EV::run;

    is scalar(@results), 3, 'all callbacks executed';
    my %seen = map { $_->[0] => $_ } @results;
    is $seen{cmd2}[2], 'waiting timeout', 'cmd2 got waiting timeout';
    ok defined $seen{cmd3}, 'cmd3 callback was executed';
    is $seen{cmd3}[2], 'waiting timeout', 'cmd3 got waiting timeout';

    $r->max_pending(0);
    $r->waiting_timeout(0);
}

# Edge case: skip_pending immediately after issuing commands (before any response)
{
    $r->connect_unix( $connect_info{sock} );

    my @results;

    $r->command('set', 'imm_skip_1', 'val1', sub { push @results, ['cmd1', @_] });
    $r->command('set', 'imm_skip_2', 'val2', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'imm_skip_3', 'val3', sub { push @results, ['cmd3', @_] });

    is $r->pending_count, 3, 'pending_count is 3';

    # Skip all pending immediately
    $r->skip_pending;

    is $r->pending_count, 0, 'pending_count is 0 after skip';

    $r->disconnect;
    EV::run;

    is scalar(@results), 3, 'all 3 callbacks executed';
    for my $res (@results) {
        is $res->[2], 'skipped', "$res->[0] was skipped";
    }
}

# Edge case: set max_pending to 0 (unlimited) with waiting commands
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    # First goes to pending
    $r->command('set', 'unlimit_1', 'val1', sub { push @results, ['cmd1', @_] });
    # Rest go to waiting
    $r->command('set', 'unlimit_2', 'val2', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'unlimit_3', 'val3', sub { push @results, ['cmd3', @_] });
    $r->command('set', 'unlimit_4', 'val4', sub {
        push @results, ['cmd4', @_];
        $r->disconnect;
    });

    is $r->pending_count, 1, 'pending_count is 1';
    is $r->waiting_count, 3, 'waiting_count is 3';

    # Remove limit - should send all waiting commands
    $r->max_pending(0);

    is $r->pending_count, 4, 'pending_count is 4 after removing limit';
    is $r->waiting_count, 0, 'waiting_count is 0 after removing limit';

    EV::run;

    is scalar(@results), 4, 'all 4 callbacks executed';
    for my $res (@results) {
        is $res->[1], 'OK', "$res->[0] succeeded";
    }
}

# Edge case: interleaved pending and waiting operations
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;
    my @order;

    # Issue commands that interleave pending/waiting states
    for my $i (1..6) {
        $r->command('set', "interleave_$i", "val$i", sub {
            push @order, $i;
            push @results, ["cmd$i", @_];
            $r->disconnect if $i == 6;
        });
    }

    is $r->pending_count, 2, 'pending_count is 2';
    is $r->waiting_count, 4, 'waiting_count is 4';

    EV::run;

    is scalar(@results), 6, 'all 6 callbacks executed';
    is_deeply \@order, [1, 2, 3, 4, 5, 6], 'commands executed in FIFO order';
    for my $res (@results) {
        is $res->[1], 'OK', "$res->[0] succeeded";
    }

    $r->max_pending(0);
}

# Edge case: alternating skip_waiting and command during event loop
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    $r->command('set', 'alt_skip_1', 'val1', sub {
        push @results, ['cmd1', @_];

        # Skip waiting, then add more commands
        $r->skip_waiting;

        $r->command('set', 'alt_skip_4', 'val4', sub {
            push @results, ['cmd4', @_];
            $r->disconnect;
        });
    });

    # These will be skipped
    $r->command('set', 'alt_skip_2', 'val2', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'alt_skip_3', 'val3', sub { push @results, ['cmd3', @_] });

    is $r->waiting_count, 2, 'waiting_count is 2';

    EV::run;

    is scalar(@results), 4, 'all 4 callbacks executed';
    my %seen = map { $_->[0] => $_ } @results;
    is $seen{cmd1}[1], 'OK', 'cmd1 succeeded';
    is $seen{cmd2}[2], 'skipped', 'cmd2 was skipped';
    is $seen{cmd3}[2], 'skipped', 'cmd3 was skipped';
    is $seen{cmd4}[1], 'OK', 'cmd4 succeeded (added after skip)';

    $r->max_pending(0);
}

# Edge case: persistent command with max_pending
# Persistent commands (subscribe) do NOT consume pending slots, so they
# never block normal commands from being sent.
# Note: Redis 6.0+ restricts commands in subscribe context to only
# (P|S)SUBSCRIBE/(P|S)UNSUBSCRIBE/PING/QUIT/RESET, so we use PING here
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;
    my $sub_count = 0;

    # Subscribe is persistent (callback called multiple times)
    $r->command('subscribe', 'edge_chan', sub {
        my ($r_msg, $e) = @_;
        $sub_count++;
        push @results, ['subscribe', $r_msg, $e];

        if ($r_msg && $r_msg->[0] eq 'subscribe') {
            # Persistent subscribe does not count toward pending
            is $r->pending_count, 2, 'pending_count excludes subscribe';
        }
    });

    # Use PING which is allowed in subscribe context (Redis 6.0+)
    $r->command('ping', sub {
        push @results, ['cmd1', @_];
    });

    # Both PINGs fit in max_pending since subscribe doesn't count
    $r->command('ping', sub {
        push @results, ['cmd2', @_];
    });

    is $r->pending_count, 2, 'pending_count is 2 (two PINGs, subscribe excluded)';
    is $r->waiting_count, 0, 'waiting_count is 0 (subscribe does not consume pending slot)';

    my $timer = EV::timer 0.1, 0, sub {
        $r->skip_pending;
        $r->skip_waiting;
        $r->disconnect;
    };
    EV::run;

    ok $sub_count >= 1, 'subscribe callback called at least once';

    $r->max_pending(0);
}

# Stress test: large waiting queue
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(5);

    my $num_commands = 100;
    my @results;
    my $completed = 0;

    for my $i (1..$num_commands) {
        $r->set("stress_test_$i", "value_$i", sub {
            my ($res, $err) = @_;
            push @results, { i => $i, res => $res, err => $err };
            $completed++;
            if ($completed == $num_commands) {
                $r->disconnect;
            }
        });
    }

    # With max_pending=5, most commands should be waiting
    ok $r->waiting_count > 0, "waiting_count > 0 with $num_commands commands";
    is $r->pending_count + $r->waiting_count, $num_commands, 'pending + waiting = total commands';

    EV::run;

    is scalar(@results), $num_commands, "all $num_commands callbacks executed";

    # Verify all succeeded
    my $all_ok = 1;
    for my $res (@results) {
        if ($res->{res} ne 'OK' || $res->{err}) {
            $all_ok = 0;
            last;
        }
    }
    ok $all_ok, 'all stress test commands succeeded';

    # Verify order was preserved
    my @order = map { $_->{i} } @results;
    my @expected = (1..$num_commands);
    is_deeply \@order, \@expected, 'commands executed in FIFO order';

    $r->max_pending(0);
}

# Stress test: rapid connect/disconnect cycles
{
    for my $cycle (1..5) {
        my $r_cycle = EV::Redis->new(
            path => $connect_info{sock},
            on_error => sub { },
        );

        my $done = 0;
        $r_cycle->ping(sub {
            my ($res, $err) = @_;
            is $res, 'PONG', "cycle $cycle: ping succeeded";
            $done = 1;
            $r_cycle->disconnect;
        });
        EV::run;
        ok $done, "cycle $cycle: completed";
    }
}
pass 'rapid connect/disconnect cycles completed';

# Stress test: alternating pending/waiting with skip
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;

    for my $round (1..3) {
        # Queue commands
        for my $i (1..5) {
            $r->set("alt_stress_${round}_$i", "val", sub {
                my ($res, $err) = @_;
                push @results, { name => "round${round}_$i", res => $res, err => $err };
            });
        }

        # Skip waiting after queueing
        $r->skip_waiting;
    }

    # Final command to disconnect
    $r->set("alt_stress_final", "val", sub {
        my ($res, $err) = @_;
        push @results, { name => "final", res => $res, err => $err };
        $r->disconnect;
    });

    EV::run;

    # Some callbacks should have completed (pending) and some skipped (waiting)
    my @skipped = grep { $_->{err} && $_->{err} eq 'skipped' } @results;
    my @completed = grep { $_->{res} && $_->{res} eq 'OK' } @results;

    ok scalar(@skipped) > 0, 'some commands were skipped';
    ok scalar(@completed) > 0, 'some commands completed successfully';
    is scalar(@results), scalar(@skipped) + scalar(@completed), 'all callbacks accounted for';

    $r->max_pending(0);
}

done_testing;
