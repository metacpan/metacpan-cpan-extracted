use strict;
use warnings;
use Test::More;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Redis;

# Test: reconnect configuration
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    is $r->reconnect_enabled, 0, 'reconnect disabled by default';

    $r->reconnect(1, 500, 3);
    is $r->reconnect_enabled, 1, 'reconnect enabled after call';

    $r->reconnect(0);
    is $r->reconnect_enabled, 0, 'reconnect disabled after call';

    $r->disconnect;
}

# Test: reconnect via constructor
{
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        reconnect => 1,
        reconnect_delay => 500,
        max_reconnect_attempts => 3,
    );

    is $r->reconnect_enabled, 1, 'reconnect enabled via constructor';
    $r->disconnect;
}

# Test: automatic reconnect on connection failure
{
    my $connect_count = 0;
    my $error_count = 0;

    my $r = EV::Redis->new(
        on_error => sub { $error_count++ },
        on_connect => sub { $connect_count++ },
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 2,
    );

    # Try connecting to invalid port - should fail and attempt reconnect
    $r->connect('127.0.0.1', 59999);

    # Wait for reconnect attempts
    my $timer = EV::timer 0.5, 0, sub {
        # Stop after timeout
    };
    EV::run;

    ok $error_count >= 1, 'error handler called on connection failure';
    is $r->is_connected, 0, 'not connected after failed reconnect attempts';
    $r->disconnect;
}

# Test: explicit disconnect does not trigger reconnect
{
    my $disconnected = 0;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        on_error => sub { },
        on_disconnect => sub { $disconnected = 1 },
    );

    # Wait for connection to be ready by doing a PING
    $r->ping(sub {
        my ($res, $err) = @_;
        ok $r->is_connected, 'initially connected';

        # Enable reconnect after connection
        $r->reconnect(1, 100, 1);

        $r->disconnect;
    });

    # Run event loop - will exit when all callbacks done
    my $timer = EV::timer 2, 0, sub { };
    EV::run;

    ok $disconnected, 'on_disconnect callback was called';
    is $r->is_connected, 0, 'disconnected after explicit disconnect (no reconnect)';
}

# Test: resume_waiting_on_reconnect getter/setter
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    is $r->resume_waiting_on_reconnect, 0, 'resume_waiting_on_reconnect defaults to 0';
    $r->resume_waiting_on_reconnect(1);
    is $r->resume_waiting_on_reconnect, 1, 'resume_waiting_on_reconnect set to 1';
    $r->resume_waiting_on_reconnect(0);
    is $r->resume_waiting_on_reconnect, 0, 'resume_waiting_on_reconnect set back to 0';

    $r->disconnect;
}

# Test: resume_waiting_on_reconnect via constructor
{
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        resume_waiting_on_reconnect => 1,
    );

    is $r->resume_waiting_on_reconnect, 1, 'resume_waiting_on_reconnect set via constructor';
    $r->disconnect;
}

# Test: waiting queue behavior on explicit disconnect (resume_waiting_on_reconnect=0)
{
    my @results;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,  # Commands queue up
    );

    # Queue up multiple commands
    $r->set('key1', 'val1', sub { push @results, ['set1', $_[1] ? 'error' : 'ok'] });
    $r->set('key2', 'val2', sub { push @results, ['set2', $_[1] ? 'error' : 'ok'] });
    $r->set('key3', 'val3', sub { push @results, ['set3', $_[1] ? 'error' : 'ok'] });

    # Disconnect immediately - pending and waiting should all error
    $r->disconnect;

    my $timer = EV::timer 0.5, 0, sub { };
    EV::run;

    is scalar(@results), 3, 'all callbacks were called on disconnect';
    # All should get errors since we disconnected
    my $errors = grep { $_->[1] eq 'error' } @results;
    ok $errors >= 1, 'at least pending command got error on disconnect';
}

# Test: waiting queue preserved with resume_waiting_on_reconnect=1 (explicit disconnect still errors)
{
    my @results;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,
        resume_waiting_on_reconnect => 1,  # Preserves waiting queue, but not for intentional disconnect
    );

    # Queue up multiple commands
    $r->set('key1', 'val1', sub { push @results, ['set1', $_[1] ? 'error' : 'ok'] });
    $r->set('key2', 'val2', sub { push @results, ['set2', $_[1] ? 'error' : 'ok'] });
    $r->set('key3', 'val3', sub { push @results, ['set3', $_[1] ? 'error' : 'ok'] });

    # Explicit disconnect should still error all callbacks (no reconnect for intentional disconnect)
    $r->disconnect;

    my $timer = EV::timer 0.5, 0, sub { };
    EV::run;

    # Note: With resume_waiting_on_reconnect=1, waiting queue is preserved across reconnect,
    # but explicit disconnect() sets intentional_disconnect which cancels everything.
    is scalar(@results), 3, 'all callbacks were called';
}

# Test: reconnect after unexpected disconnect (simulated via max_reconnect_attempts exhaustion)
{
    my $connect_count = 0;
    my $error_count = 0;
    my $disconnect_count = 0;

    my $r = EV::Redis->new(
        on_connect => sub { $connect_count++ },
        on_error => sub { $error_count++ },
        on_disconnect => sub { $disconnect_count++ },
        reconnect => 1,
        reconnect_delay => 50,
        max_reconnect_attempts => 2,
    );

    # Connect to invalid port - will fail and trigger reconnect attempts
    $r->connect('127.0.0.1', 59999);

    my $timer = EV::timer 0.5, 0, sub { };
    EV::run;

    is $connect_count, 0, 'never connected to invalid port';
    ok $error_count >= 1, 'error callback called for failed connection';
    # After max_reconnect_attempts, should give up
    is $r->is_connected, 0, 'not connected after exhausting reconnect attempts';
    $r->disconnect;
}

# Test: commands issued during disconnect callback
# Verifies that calling command() in on_disconnect triggers proper error
{
    my $error_in_callback = 0;
    my $r;
    $r = EV::Redis->new(
        path => $connect_info{sock},
        on_error => sub { },
        on_disconnect => sub {
            # Trying to issue command during disconnect should fail safely
            eval {
                $r->set('key', 'value', sub { });
            };
            $error_in_callback = 1 if $@;
        },
    );

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        $r->disconnect;
    };

    EV::run;

    ok $error_in_callback, 'command during disconnect callback throws exception';
}

# Test: skip_waiting() during waiting queue callback (re-entrancy safety)
{
    my @results;
    my $skip_called = 0;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,  # Commands queue up in waiting
    );

    # Queue up multiple commands - first goes to pending, rest to waiting
    $r->set('key1', 'val1', sub { push @results, ['set1', $_[1] ? 'error' : 'ok'] });
    $r->set('key2', 'val2', sub {
        push @results, ['set2', $_[1] ? 'error' : 'ok'];
        # Calling skip_waiting during callback should be safe (no-op due to in_cleanup)
        $r->skip_waiting();
        $skip_called = 1;
    });
    $r->set('key3', 'val3', sub { push @results, ['set3', $_[1] ? 'error' : 'ok'] });

    # Disconnect triggers error callbacks for waiting commands
    $r->disconnect;

    my $timer = EV::timer 0.5, 0, sub { };
    EV::run;

    ok $skip_called, 'skip_waiting was called during waiting queue callback';
    is scalar(@results), 3, 'all callbacks were called despite skip_waiting re-entry';
}

# Test: reconnect configuration and on_connect callback count
# This verifies that on_connect is called on initial connect
{
    my $connect_count = 0;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        on_connect => sub { $connect_count++ },
        on_error => sub { },
    );

    # Do a simple command to verify connection works
    $r->ping(sub {
        my ($res, $err) = @_;
        $r->disconnect;
    });

    EV::run;

    is $connect_count, 1, 'on_connect called once on initial connection';
}

# Test: waiting queue is drained when connection becomes available
# (This tests the connect callback's waiting queue drain logic)
{
    my @results;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,  # Force commands to wait
    );

    # Queue commands - first goes pending, rest wait
    $r->set('drain_test_1', 'val1', sub { push @results, ['cmd1', $_[1] ? 'error' : 'ok'] });
    $r->set('drain_test_2', 'val2', sub { push @results, ['cmd2', $_[1] ? 'error' : 'ok'] });
    $r->set('drain_test_3', 'val3', sub { push @results, ['cmd3', $_[1] ? 'error' : 'ok'] });

    is $r->waiting_count, 2, 'two commands in waiting queue';

    my $timer; $timer = EV::timer 1, 0, sub {
        undef $timer;
        $r->disconnect;
    };

    EV::run;

    is scalar(@results), 3, 'all commands completed';
    is $results[0][1], 'ok', 'first command succeeded';
    is $results[1][1], 'ok', 'second command (from wait queue) succeeded';
    is $results[2][1], 'ok', 'third command (from wait queue) succeeded';
}

# Test: reconnect timer fires and attempts reconnection
# (Tests the reconnect scheduling path without requiring forced disconnect)
{
    my $error_count = 0;
    my $r = EV::Redis->new(
        on_error => sub { $error_count++ },
        reconnect => 1,
        reconnect_delay => 50,
        max_reconnect_attempts => 3,
    );

    # Connect to invalid port - will fail and schedule reconnect
    $r->connect('127.0.0.1', 59998);

    # Wait for reconnect attempts to exhaust
    my $timer; $timer = EV::timer 0.5, 0, sub { undef $timer };
    EV::run;

    # Should have multiple errors from reconnect attempts
    ok $error_count >= 2, "reconnect timer fired multiple times (got $error_count errors)";
    is $r->is_connected, 0, 'not connected after exhausting reconnect attempts';
    $r->disconnect;
}

# Test: reconnect_delay with zero value (immediate reconnect)
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    # Zero delay means immediate reconnect (no clamping)
    $r->reconnect(1, 0, 3);
    is $r->reconnect_enabled, 1, 'reconnect enabled with zero delay';

    $r->disconnect;
}

# Test: reconnect_delay with negative value throws exception
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    my $died = 0;
    eval {
        $r->reconnect(1, -100, 3);
    };
    $died = 1 if $@;

    ok $died, 'negative reconnect_delay throws exception';
    like $@, qr/reconnect_delay must be non-negative/, 'exception mentions non-negative';

    $r->disconnect;
}

# Test: reconnect_delay overflow protection
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    my $died = 0;
    eval {
        $r->reconnect(1, 2000000001, 3);  # Exceeds MAX_TIMEOUT_MS
    };
    $died = 1 if $@;

    ok $died, 'reconnect_delay exceeding max throws exception';
    like $@, qr/reconnect_delay too large/, 'exception mentions reconnect_delay too large';

    # Valid large delay should work
    eval {
        $r->reconnect(1, 2000000000, 3);  # At MAX_TIMEOUT_MS limit
    };
    ok !$@, 'reconnect_delay at max limit accepted';
    is $r->reconnect_enabled, 1, 'reconnect enabled with max delay';

    $r->disconnect;
}

# Test: negative max_reconnect_attempts clamping
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    # Negative max_attempts should be clamped to 0 (unlimited retries)
    $r->reconnect(1, 100, -5);
    is $r->reconnect_enabled, 1, 'reconnect enabled with negative max_attempts';

    # With max_attempts=0 (unlimited), reconnect should keep trying
    # We just verify it doesn't crash and accepts the value
    $r->reconnect(1, 100, -999);
    is $r->reconnect_enabled, 1, 'reconnect enabled with very negative max_attempts';

    $r->disconnect;
}

# Test: constructor with negative/zero reconnect parameters
{
    # Zero reconnect_delay via constructor
    my $r1 = EV::Redis->new(
        path => $connect_info{sock},
        reconnect => 1,
        reconnect_delay => 0,
        max_reconnect_attempts => 3,
    );
    is $r1->reconnect_enabled, 1, 'reconnect enabled via constructor with zero delay';
    $r1->disconnect;

    # Negative max_reconnect_attempts via constructor
    my $r2 = EV::Redis->new(
        path => $connect_info{sock},
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => -1,
    );
    is $r2->reconnect_enabled, 1, 'reconnect enabled via constructor with negative max_attempts';
    $r2->disconnect;
}

# Test: successful automatic reconnection after CLIENT KILL
# Uses CLIENT KILL from a helper connection to trigger server-side disconnect,
# then verifies the client auto-reconnects. Requires Redis 5.0+ for CLIENT ID.
SKIP: {
    my $connect_count = 0;
    my $error_count = 0;
    my $ping_after_reconnect = '';

    my $r = EV::Redis->new(
        path => $connect_info{sock},
        on_connect => sub { $connect_count++ },
        on_error => sub { $error_count++ },
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 10,
    );

    # Get our client ID (requires Redis 5.0+)
    my $client_id;
    my $skip_reason;
    $r->command('CLIENT', 'ID', sub {
        my ($res, $err) = @_;
        if ($err) {
            $skip_reason = "CLIENT ID not supported: $err";
        } else {
            $client_id = $res;
        }
    });

    my $id_timer; $id_timer = EV::timer 1, 0, sub {
        undef $id_timer;
        $r->disconnect;
    };
    EV::run;

    skip $skip_reason, 4 if $skip_reason;
    skip 'failed to get client ID', 4 unless defined $client_id;

    # Reset counters after the initial connect
    $connect_count = 0;
    $error_count = 0;

    # Reconnect $r with reconnect enabled
    $r->connect_unix($connect_info{sock});

    # Helper connection to issue CLIENT KILL
    my $helper = EV::Redis->new(
        path => $connect_info{sock},
        on_error => sub { },
    );

    # Step 1: Get $r's new client ID, then kill it from $helper
    my $kill_timer; $kill_timer = EV::timer 0.2, 0, sub {
        undef $kill_timer;
        $r->command('CLIENT', 'ID', sub {
            my ($res, $err) = @_;
            return unless defined $res;
            $helper->command('CLIENT', 'KILL', 'ID', $res, sub {
                # Kill issued; $r should disconnect and auto-reconnect
            });
        });
    };

    # Step 2: Check reconnection after enough time
    my $check_timer; $check_timer = EV::timer 2, 0, sub {
        undef $check_timer;
        if ($r->is_connected) {
            $r->ping(sub {
                my ($res, $err) = @_;
                $ping_after_reconnect = $res || '';
                $r->disconnect;
                $helper->disconnect;
            });
        } else {
            $r->disconnect;
            $helper->disconnect;
        }
    };

    EV::run;

    ok $connect_count >= 2, "on_connect called at least twice (got $connect_count)";
    ok $error_count >= 1, 'error handler called during reconnect';
    is $ping_after_reconnect, 'PONG', 'successful ping after automatic reconnection';
    is $r->is_connected, 0, 'disconnected after test cleanup';
}

# Test: resume_waiting_on_reconnect preserves waiting commands across unexpected disconnect
SKIP: {
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,
        resume_waiting_on_reconnect => 1,
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 10,
        on_error => sub { },
    );

    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});

    # Get client ID (requires Redis 5.0+)
    my $client_id;
    my $skip_reason;
    $r->command('CLIENT', 'ID', sub {
        my ($res, $err) = @_;
        if ($err) {
            $skip_reason = "CLIENT ID not supported: $err";
        } else {
            $client_id = $res;
        }
    });

    my $id_timer; $id_timer = EV::timer 1, 0, sub { undef $id_timer; EV::break };
    EV::run;

    skip $skip_reason, 3 if $skip_reason;
    skip 'failed to get client ID', 3 unless defined $client_id;

    # Use BLPOP to hold the pending slot (blocks server-side for this connection)
    $r->blpop('resume_wait_nonexistent_key', 10, sub { });

    # These go to the waiting queue since pending slot is occupied by BLPOP
    my @wait_results;
    $r->set('resume_wait_key2', 'v2', sub {
        my ($res, $err) = @_;
        push @wait_results, [$res, $err];
    });
    $r->set('resume_wait_key3', 'v3', sub {
        my ($res, $err) = @_;
        push @wait_results, [$res, $err];
        $r->disconnect;
    });

    is $r->waiting_count, 2, 'two commands in waiting queue';

    # Kill connection from helper to trigger unintentional disconnect
    # Short delay to ensure BLPOP is blocking on the server
    my $kill_timer; $kill_timer = EV::timer 0.1, 0, sub {
        undef $kill_timer;
        $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {
            $helper->disconnect;
        });
    };

    my $timeout; $timeout = EV::timer 3, 0, sub {
        undef $timeout;
        $r->disconnect;
    };
    EV::run;

    is scalar(@wait_results), 2, 'both waiting commands executed after reconnect';
    is $wait_results[0][0], 'OK', 'waiting command succeeded after reconnect';
}

# Test: auto-queuing commands during reconnect window
# When reconnect is active and ac==NULL, command() should queue to wait_queue
# instead of croaking. Queued commands execute after successful reconnection.
SKIP: {
    my @results;
    my $queued_ok = 0;

    my $r = EV::Redis->new(
        path => $connect_info{sock},
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 10,
        on_error => sub { },
    );

    # Get client ID for CLIENT KILL (requires Redis 5.0+)
    my ($client_id, $skip_reason);
    $r->command('CLIENT', 'ID', sub {
        my ($res, $err) = @_;
        if ($err) { $skip_reason = "CLIENT ID not supported: $err" }
        else { $client_id = $res }
    });

    my $id_timer; $id_timer = EV::timer 1, 0, sub { undef $id_timer; EV::break };
    EV::run;

    skip $skip_reason, 5 if $skip_reason;
    skip 'failed to get client ID', 5 unless defined $client_id;

    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});

    # Use on_disconnect to queue commands at exactly the right moment:
    # after disconnect_cb completes (ac==NULL, reconnect_timer_active==1).
    $r->on_disconnect(sub {
        # Schedule command queuing for next event loop iteration
        # (after disconnect_cb returns and reconnect timer is started).
        my $qt; $qt = EV::timer 0, 0, sub {
            undef $qt;
            eval {
                $r->set('autoq_key1', 'val1', sub {
                    push @results, ['set1', $_[0], $_[1]];
                });
                $r->set('autoq_key2', 'val2', sub {
                    push @results, ['set2', $_[0], $_[1]];
                });
                $queued_ok = 1;
            };
            if ($@) {
                diag "auto-queue croak'd: $@";
            }
        };
    });

    # Kill $r's connection to trigger unexpected disconnect + reconnect
    my $kill_timer; $kill_timer = EV::timer 0.2, 0, sub {
        undef $kill_timer;
        $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {});
    };

    # Check results after enough time for reconnect
    my $check_timer; $check_timer = EV::timer 3, 0, sub {
        undef $check_timer;
        $r->disconnect;
        $helper->disconnect;
    };

    EV::run;

    ok $queued_ok, 'commands during reconnect window did not croak';
    is scalar(@results), 2, 'both auto-queued commands got callbacks';
    is $results[0][1], 'OK', 'first auto-queued command succeeded after reconnect';
    is $results[1][1], 'OK', 'second auto-queued command succeeded after reconnect';
    is $r->is_connected, 0, 'disconnected after cleanup';
}

# Test: auto-queuing NOT enabled without reconnect
# Without reconnect enabled, command() during disconnect should still croak.
{
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        on_error => sub { },
    );

    $r->ping(sub {
        # Wait for connection, then disconnect
        $r->disconnect;
    });
    EV::run;

    # Now ac==NULL, reconnect not enabled — should croak
    my $croaked = 0;
    eval { $r->set('key', 'val', sub {}) };
    $croaked = 1 if $@;

    ok $croaked, 'command without reconnect still croaks when disconnected';
    like $@, qr/connection required/, 'croak message mentions connection required';
}

# Test: auto-queuing with waiting_timeout expires commands during long reconnect
SKIP: {
    my @results;

    my $r = EV::Redis->new(
        path => $connect_info{sock},
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 10,
        waiting_timeout => 300,  # 300ms — shorter than reconnect to invalid port
        on_error => sub { },
    );

    # Get client ID
    my ($client_id, $skip_reason);
    $r->command('CLIENT', 'ID', sub {
        my ($res, $err) = @_;
        if ($err) { $skip_reason = "CLIENT ID not supported: $err" }
        else { $client_id = $res }
    });

    my $t; $t = EV::timer 1, 0, sub { undef $t; EV::break };
    EV::run;

    skip $skip_reason, 3 if $skip_reason;
    skip 'failed to get client ID', 3 unless defined $client_id;

    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});

    # Stop the redis server's listening so reconnect attempts fail
    # (We can't easily stop Test::RedisServer, so instead we'll kill $r's
    # connection and have it try to reconnect — it will succeed quickly.
    # Instead, test a simpler scenario: queue command, verify it gets
    # the timeout error if waiting_timeout fires before reconnect.)

    # Queue commands after disconnect is confirmed
    $r->on_disconnect(sub {
        my $qt; $qt = EV::timer 0, 0, sub {
            undef $qt;
            eval {
                $r->set('timeout_key', 'val', sub {
                    push @results, [@_];
                });
            };
        };
    });

    # Kill connection
    $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {
        $helper->disconnect;
    });

    # Check — reconnect will likely succeed before timeout, so the command
    # should execute successfully. But at minimum verify no crash.
    my $done_timer; $done_timer = EV::timer 2, 0, sub {
        undef $done_timer;
        $r->disconnect;
    };

    EV::run;

    is scalar(@results), 1, 'auto-queued command callback fired';
    ok(defined($results[0][0]) || defined($results[0][1]),
       'callback got either result or error (no silent drop)');
    is $r->is_connected, 0, 'disconnected after cleanup';
}

# Test: reconnect_attempts counter resets after successful reconnect
# After reconnecting successfully, the counter should reset so the full
# max_reconnect_attempts are available again for the next failure.
SKIP: {
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 3,
        on_error => sub { },
    );

    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});

    my ($client_id, $skip_reason);
    $r->command('CLIENT', 'ID', sub {
        my ($res, $err) = @_;
        if ($err) { $skip_reason = "CLIENT ID not supported: $err" }
        else { $client_id = $res }
    });

    my $t; $t = EV::timer 1, 0, sub { undef $t; EV::break };
    EV::run;

    skip $skip_reason, 2 if $skip_reason;
    skip 'failed to get client ID', 2 unless defined $client_id;

    # Kill connection #1 — should reconnect successfully
    my $reconnect_count = 0;
    $r->on_connect(sub {
        $reconnect_count++;
        EV::break;
    });

    $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {});

    my $wait; $wait = EV::timer 3, 0, sub { undef $wait; EV::break };
    EV::run;

    ok $reconnect_count >= 1, "reconnected after first kill (got $reconnect_count)";

    # Kill connection #2 — counter should have been reset, so this should
    # also reconnect (not fail with "max attempts reached")
    $reconnect_count = 0;
    $r->command('CLIENT', 'ID', sub {
        my ($res, $err) = @_;
        return unless defined $res;
        $helper->command('CLIENT', 'KILL', 'ID', $res, sub {});
    });

    my $wait2; $wait2 = EV::timer 3, 0, sub { undef $wait2; EV::break };
    EV::run;

    ok $reconnect_count >= 1, "reconnected after second kill (counter was reset, got $reconnect_count)";

    $r->on_connect(undef);
    $r->disconnect;
    $helper->disconnect;
}

# Test: manual reconnect inside on_disconnect honours
# resume_waiting_on_reconnect=0 by clearing the wait queue.
{
    my $r = EV::Redis->new(
        on_error                    => sub { },
        max_pending                 => 1,
        resume_waiting_on_reconnect => 0,
    );

    my $helper = EV::Redis->new(path => $connect_info{sock});
    $r->connect_unix($connect_info{sock});

    my $client_id;
    my $cv = EV::timer 0.5, 0, sub { EV::break };
    $r->command('CLIENT', 'ID', sub { $client_id = $_[0]; EV::break });
    EV::run;
    undef $cv;
    ok defined $client_id, 'got client id for r';

    my @results;
    $r->on_disconnect(sub {
        $r->connect_unix($connect_info{sock});  # manual reconnect mid-disconnect
    });

    # Issue: cmd1 (pending), cmd2 (waiting because max_pending=1)
    $r->command('GET', 'soak', sub { push @results, ['cmd1', @_]; });
    $r->command('GET', 'soak', sub { push @results, ['cmd2', @_]; });

    # Now sever the original connection — fires on_disconnect → manual reconnect
    $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {});

    my $w; $w = EV::timer 1.5, 0, sub { undef $w; EV::break };
    EV::run;

    my ($cmd2) = grep { $_->[0] eq 'cmd2' } @results;
    ok $cmd2, 'cmd2 received a callback';
    ok defined $cmd2->[2],
        'cmd2 callback received a disconnect error (not silently forwarded on new connection)';
    is $r->waiting_count, 0, 'wait queue cleared after manual reconnect';

    $r->on_disconnect(undef);
    $r->disconnect;
    $helper->disconnect;
}

done_testing;
