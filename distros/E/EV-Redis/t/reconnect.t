use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use Test::TCP qw(empty_port);

$SIG{PIPE} = 'IGNORE';

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Redis;
use lib 't/lib';
use RedisTestHelper qw(get_redis_version);

my ($redis_version) = get_redis_version($connect_info{sock});
my $no_client_id = $redis_version < 5 ? 'CLIENT ID needs Redis 5+' : '';

{
    my $r = EV::Redis->new(path => $connect_info{sock});

    is $r->reconnect_enabled, 0, 'reconnect disabled by default';

    $r->reconnect(1, 500, 3);
    is $r->reconnect_enabled, 1, 'reconnect enabled after call';

    $r->reconnect(0);
    is $r->reconnect_enabled, 0, 'reconnect disabled after call';

    $r->disconnect;
}

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

    $r->connect('127.0.0.1', 59999);

    my $timer = EV::timer 0.5, 0, sub {
    };
    EV::run;

    ok $error_count >= 1, 'error handler called on connection failure';
    is $r->is_connected, 0, 'not connected after failed reconnect attempts';
    $r->disconnect;
}

{
    my $disconnected = 0;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        on_error => sub { },
        on_disconnect => sub { $disconnected = 1 },
    );

    $r->ping(sub {
        my ($res, $err) = @_;
        ok $r->is_connected, 'initially connected';

        $r->reconnect(1, 100, 1);

        $r->disconnect;
    });

    my $timer = EV::timer 2, 0, sub { };
    EV::run;

    ok $disconnected, 'on_disconnect callback was called';
    is $r->is_connected, 0, 'disconnected after explicit disconnect (no reconnect)';
}

{
    my $r = EV::Redis->new(path => $connect_info{sock});

    is $r->resume_waiting_on_reconnect, 0, 'resume_waiting_on_reconnect defaults to 0';
    $r->resume_waiting_on_reconnect(1);
    is $r->resume_waiting_on_reconnect, 1, 'resume_waiting_on_reconnect set to 1';
    $r->resume_waiting_on_reconnect(0);
    is $r->resume_waiting_on_reconnect, 0, 'resume_waiting_on_reconnect set back to 0';

    $r->disconnect;
}

{
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        resume_waiting_on_reconnect => 1,
    );

    is $r->resume_waiting_on_reconnect, 1, 'resume_waiting_on_reconnect set via constructor';
    $r->disconnect;
}

# explicit disconnect with resume_waiting_on_reconnect=0
{
    my @results;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,
    );

    $r->set('key1', 'val1', sub { push @results, ['set1', $_[1] ? 'error' : 'ok'] });
    $r->set('key2', 'val2', sub { push @results, ['set2', $_[1] ? 'error' : 'ok'] });
    $r->set('key3', 'val3', sub { push @results, ['set3', $_[1] ? 'error' : 'ok'] });

    $r->disconnect;

    my $timer = EV::timer 0.5, 0, sub { };
    EV::run;

    is scalar(@results), 3, 'all callbacks were called on disconnect';
    my $errors = grep { $_->[1] eq 'error' } @results;
    ok $errors >= 1, 'at least pending command got error on disconnect';
}

# explicit disconnect still fails waiting commands with resume_waiting_on_reconnect=1
{
    my @results;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,
        resume_waiting_on_reconnect => 1,
    );

    $r->set('key1', 'val1', sub { push @results, ['set1', $_[1] ? 'error' : 'ok'] });
    $r->set('key2', 'val2', sub { push @results, ['set2', $_[1] ? 'error' : 'ok'] });
    $r->set('key3', 'val3', sub { push @results, ['set3', $_[1] ? 'error' : 'ok'] });

    $r->disconnect;

    my $timer = EV::timer 0.5, 0, sub { };
    EV::run;

    is scalar(@results), 3, 'all callbacks were called';
}

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

    $r->connect('127.0.0.1', 59999);

    my $timer = EV::timer 0.5, 0, sub { };
    EV::run;

    is $connect_count, 0, 'never connected to invalid port';
    ok $error_count >= 1, 'error callback called for failed connection';
    is $r->is_connected, 0, 'not connected after exhausting reconnect attempts';
    $r->disconnect;
}

{
    my $error_in_callback = 0;
    my $r;
    $r = EV::Redis->new(
        path => $connect_info{sock},
        on_error => sub { },
        on_disconnect => sub {
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

{
    my @results;
    my $skip_called = 0;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,
    );

    $r->set('key1', 'val1', sub { push @results, ['set1', $_[1] ? 'error' : 'ok'] });
    $r->set('key2', 'val2', sub {
        push @results, ['set2', $_[1] ? 'error' : 'ok'];
        $r->skip_waiting();
        $skip_called = 1;
    });
    $r->set('key3', 'val3', sub { push @results, ['set3', $_[1] ? 'error' : 'ok'] });

    $r->disconnect;

    my $timer = EV::timer 0.5, 0, sub { };
    EV::run;

    ok $skip_called, 'skip_waiting was called during waiting queue callback';
    is scalar(@results), 3, 'all callbacks were called despite skip_waiting re-entry';
}

{
    my $connect_count = 0;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        on_connect => sub { $connect_count++ },
        on_error => sub { },
    );

    $r->ping(sub {
        my ($res, $err) = @_;
        $r->disconnect;
    });

    my $stuck;
    # does not itself keep the loop running
    my $g = EV::timer 10, 0, sub { $stuck = 1; EV::break };
    $g->keepalive(0);
    EV::run;

    ok !$stuck, 'the loop comes to rest after disconnect() from a reply callback';
    is $connect_count, 1, 'on_connect called once on initial connection';
}

{
    my @results;
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,
    );

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

{
    my $error_count = 0;
    my $r = EV::Redis->new(
        on_error => sub { $error_count++ },
        reconnect => 1,
        reconnect_delay => 50,
        max_reconnect_attempts => 3,
    );

    $r->connect('127.0.0.1', 59998);

    my $timer; $timer = EV::timer 0.5, 0, sub { undef $timer };
    EV::run;

    ok $error_count >= 2, "reconnect timer fired multiple times (got $error_count errors)";
    is $r->is_connected, 0, 'not connected after exhausting reconnect attempts';
    $r->disconnect;
}

{
    my $r = EV::Redis->new(path => $connect_info{sock});

    $r->reconnect(1, 0, 3);
    is $r->reconnect_enabled, 1, 'reconnect enabled with zero delay';

    $r->disconnect;
}

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

{
    my $r = EV::Redis->new(path => $connect_info{sock});

    my $died = 0;
    eval {
        $r->reconnect(1, 2000000001, 3);
    };
    $died = 1 if $@;

    ok $died, 'reconnect_delay exceeding max throws exception';
    like $@, qr/reconnect_delay too large/, 'exception mentions reconnect_delay too large';

    eval {
        $r->reconnect(1, 2000000000, 3);
    };
    ok !$@, 'reconnect_delay at max limit accepted';
    is $r->reconnect_enabled, 1, 'reconnect enabled with max delay';

    $r->disconnect;
}

{
    my $r = EV::Redis->new(path => $connect_info{sock});

    # negative max_attempts clamps to 0 (unlimited)
    $r->reconnect(1, 100, -5);
    is $r->reconnect_enabled, 1, 'reconnect enabled with negative max_attempts';

    $r->reconnect(1, 100, -999);
    is $r->reconnect_enabled, 1, 'reconnect enabled with very negative max_attempts';

    $r->disconnect;
}

# undef delay/attempts leave the current values, like other numeric setters
{
    my $closed = empty_port();
    my @ts;
    my $r = EV::Redis->new(on_error => sub { push @ts, EV::now });
    $r->reconnect(1, 2000);
    $r->reconnect(1, undef);
    $r->connect('127.0.0.1', $closed);
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    my $gap = @ts >= 2 ? $ts[1] - $ts[0] : -1;
    cmp_ok $gap, '>=', 1.5, 'undef delay: keeps the configured 2000ms';
    $r->disconnect;
}
{
    my $closed = empty_port();
    my @ts;
    my $r = EV::Redis->new(on_error => sub { push @ts, EV::now });
    $r->reconnect(1, undef);
    $r->connect('127.0.0.1', $closed);
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    my $gap = @ts >= 2 ? $ts[1] - $ts[0] : -1;
    cmp_ok $gap, '>=', 0.5, 'fresh undef delay: keeps the 1000ms default';
    $r->disconnect;
}
{
    my $closed = empty_port();
    my @errs;
    my $r = EV::Redis->new(
        on_error => sub { push @errs, $_[0]; EV::break if $_[0] =~ /max attempts reached/ });
    $r->reconnect(1, 10, 2);
    $r->reconnect(1, 10, undef);
    $r->connect('127.0.0.1', $closed);
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    ok scalar(grep { /max attempts reached/ } @errs),
        'undef attempts: keeps the configured limit';
    $r->disconnect;
}

# omitted args restore the defaults, per the reconnect() pod
{
    my $closed = empty_port();
    my @errs;
    my $r = EV::Redis->new(
        on_error => sub { push @errs, 1; EV::break if @errs > 100 });
    $r->reconnect(1, 0, 0);
    $r->reconnect(1);
    $r->connect('127.0.0.1', $closed);
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    cmp_ok scalar(@errs), '<', 100, 'omitted delay: back to the 1000ms default';
    $r->disconnect;
}
{
    my $closed = empty_port();
    my @errs;
    my $r = EV::Redis->new(on_error => sub { push @errs, $_[0] });
    $r->reconnect(1, 10, 1);
    $r->reconnect(1, 1000);
    $r->connect('127.0.0.1', $closed);
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    ok !grep({ /max attempts reached/ } @errs),
        'omitted attempts: back to unlimited';
    $r->disconnect;
}

{
    my $r1 = EV::Redis->new(
        path => $connect_info{sock},
        reconnect => 1,
        reconnect_delay => 0,
        max_reconnect_attempts => 3,
    );
    is $r1->reconnect_enabled, 1, 'reconnect enabled via constructor with zero delay';
    $r1->disconnect;

    my $r2 = EV::Redis->new(
        path => $connect_info{sock},
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => -1,
    );
    is $r2->reconnect_enabled, 1, 'reconnect enabled via constructor with negative max_attempts';
    $r2->disconnect;
}

# auto-reconnect after CLIENT KILL (CLIENT ID needs Redis 5+)
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
    { my $g = EV::timer 10, 0, sub { EV::break }; $g->keepalive(0); EV::run }

    skip $skip_reason, 5 if $skip_reason;
    skip 'failed to get client ID', 5 unless defined $client_id;

    $connect_count = 0;
    $error_count = 0;

    $r->connect_unix($connect_info{sock});

    my $helper = EV::Redis->new(
        path => $connect_info{sock},
        on_error => sub { },
    );

    my $kill_timer; $kill_timer = EV::timer 0.2, 0, sub {
        undef $kill_timer;
        $r->command('CLIENT', 'ID', sub {
            my ($res, $err) = @_;
            return unless defined $res;
            $helper->command('CLIENT', 'KILL', 'ID', $res, sub {
            });
        });
    };

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

    my $stuck;
    my $g = EV::timer 15, 0, sub { $stuck = 1; EV::break };
    $g->keepalive(0);
    EV::run;

    ok !$stuck, 'the loop comes to rest after the reconnect test';
    ok $connect_count >= 2, "on_connect called at least twice (got $connect_count)";
    ok $error_count >= 1, 'error handler called during reconnect';
    is $ping_after_reconnect, 'PONG', 'successful ping after automatic reconnection';
    is $r->is_connected, 0, 'disconnected after test cleanup';
}

# resume_waiting_on_reconnect keeps waiting commands across an unexpected disconnect
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

    # BLPOP holds the only pending slot
    $r->blpop('resume_wait_nonexistent_key', 10, sub { });

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

    # delay so BLPOP is already blocking on the server
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

# orphaned transaction fragments fail instead of resuming across a reconnect
SKIP: {
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 2,
        resume_waiting_on_reconnect => 1,
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 10,
        on_error => sub { },
    );

    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});

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

    skip $skip_reason, 6 if $skip_reason;
    skip 'failed to get client ID', 6 unless defined $client_id;

    $helper->del('resume_txn_key');

    # BLPOP blocks the connection so the MULTI reply stays outstanding
    $r->blpop('resume_txn_nonexistent_key', 10, sub { });
    $r->multi(sub { });
    my ($set_err, $exec_err);
    $r->set('resume_txn_key', 'v', sub {
        my ($res, $err) = @_;
        $set_err = $err;
    });
    $r->exec(sub {
        my ($res, $err) = @_;
        $exec_err = $err;
        $r->disconnect;
    });

    is $r->waiting_count, 2, 'SET and EXEC wait behind BLPOP and MULTI';

    my $kill_res;
    my $kill_timer; $kill_timer = EV::timer 0.3, 0, sub {
        undef $kill_timer;
        $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {
            $kill_res = $_[0];
            $helper->disconnect;
        });
    };

    my $timeout; $timeout = EV::timer 5, 0, sub {
        undef $timeout;
        $r->disconnect;
    };
    EV::run;

    is $kill_res, 1, 'kill landed (errors came from the drop, not the timeout)';
    ok $set_err, 'orphaned SET fails instead of resuming standalone';
    ok $exec_err, 'orphaned EXEC fails instead of resuming standalone';
    unlike $exec_err, qr/without MULTI/i, '... from the drop, not as an orphan EXEC';
    my $check = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my ($final, $get_timer);
    $check->get('resume_txn_key', sub { $final = $_[0]; undef $get_timer; EV::break; });
    $get_timer = EV::timer 2, 0, sub { undef $get_timer; EV::break };
    EV::run;
    isnt $final, 'v', 'orphaned SET never applied server-side';
    $check->disconnect;
}

# a watched transaction in flight fails its waiting commands on reconnect
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

    skip $skip_reason, 5 if $skip_reason;
    skip 'failed to get client ID', 5 unless defined $client_id;

    $r->watch('resume_watch_key');
    $helper->set('resume_watch_key', 'orig');
    $r->blpop('resume_watch_nonexistent_key', 10, sub { });
    my ($set_err, $exec_err);
    $r->set('resume_watch_key', 'txn', sub {
        my ($res, $err) = @_;
        $set_err = $err;
    });
    $r->exec(sub {
        my ($res, $err) = @_;
        $exec_err = $err;
        $r->disconnect;
    });

    is $r->waiting_count, 3, 'BLPOP, SET and EXEC wait behind WATCH';

    my $kill_res;
    my $kill_timer; $kill_timer = EV::timer 0.3, 0, sub {
        undef $kill_timer;
        $helper->set('resume_watch_key', 'mid', sub {
            $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {
                $kill_res = $_[0];
                $helper->disconnect;
            });
        });
    };

    my $timeout; $timeout = EV::timer 5, 0, sub {
        undef $timeout;
        $r->disconnect;
    };
    EV::run;

    is $kill_res, 1, 'kill landed (errors came from the drop, not the timeout)';
    ok $set_err && $exec_err, 'watched txn fragments fail instead of resuming';
    unlike $exec_err, qr/without MULTI/i, '... from the drop, not as an orphan EXEC';
    my $check = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my ($final, $get_timer);
    $check->get('resume_watch_key', sub { $final = $_[0]; undef $get_timer; EV::break; });
    $get_timer = EV::timer 2, 0, sub { undef $get_timer; EV::break };
    EV::run;
    isnt $final, 'txn', 'aborted txn never applied server-side';
    $check->disconnect;
}

# a span kept across one reconnect still fails its fragments on the next
SKIP: {
    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});

    my ($gen, $set_res, $set_err, $exec_err, $final);
    my $skip_reason;
    my $to;
    my $r;
    $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,
        resume_waiting_on_reconnect => 1,
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 10,
        on_error => sub { },
        on_connect => sub {
            $gen++;
            my $g = $gen;
            $r->command('CLIENT', 'ID', sub {
                my ($id) = @_;
                if (!defined $id && $g == 1) {
                    $skip_reason = 'CLIENT ID not supported';
                    undef $to;
                    EV::break;
                    return;
                }
                return unless defined $id;
                if ($g == 1) {
                    my $t; $t = EV::timer 0.3, 0, sub {
                        undef $t;
                        $helper->command('CLIENT', 'KILL', 'ID', $id, sub {});
                    };
                }
                elsif ($g == 2) {
                    $r->max_pending(2);
                    $r->set('resume_span_key', 'orphan', sub {
                        ($set_res, $set_err) = @_;
                    });
                    $r->exec(sub {
                        (my $res, $exec_err) = @_;
                        $helper->get('resume_span_key', sub {
                            ($final) = @_;
                            undef $to;
                            EV::break;
                        });
                    });
                    my $t; $t = EV::timer 0.5, 0, sub {
                        undef $t;
                        $helper->command('CLIENT', 'KILL', 'ID', $id, sub {});
                    };
                }
            });
            if ($g == 2) {
                $r->blpop('resume_span_block', 30, sub {});
            }
        },
    );

    # MULTI stays waiting behind blpop#0, so kill#1 keeps the whole span
    $r->blpop('resume_span_pad', 30, sub {});
    $r->multi(sub {});

    $to = EV::timer 15, 0, sub {
        undef $to;
        EV::break;
    };
    EV::run;
    $r->disconnect;
    $helper->disconnect;

    skip $skip_reason, 4 if $skip_reason;
    skip 'failed to connect', 4 if $gen == 0;
    ok $set_err, 'kept-span SET fails on the second disconnect';
    ok $exec_err, 'kept-span EXEC fails on the second disconnect';
    unlike $exec_err, qr/without MULTI/i, '... from the drop, not as an orphan EXEC';
    isnt $final, 'orphan', 'kept-span SET never applied server-side';
}

# A command issued after a kept setup transaction's EXEC remains standalone.
SKIP: {
    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $helper->del('r19_setup_probe');

    my ($gen, $skip_reason, $kill1, $kill2, $probe_err, $final);
    my $to;
    my $r;
    $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 1,
        resume_waiting_on_reconnect => 1,
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 20,
        on_error => sub { },
        on_connect => sub {
            $gen++;
            my $g = $gen;
            $r->command('CLIENT', 'ID', sub {
                my ($id) = @_;
                if (!defined $id && $g == 1) {
                    $skip_reason = 'CLIENT ID not supported';
                    undef $to;
                    EV::break;
                    return;
                }
                return unless defined $id;
                # Both retained setup transactions already have their EXEC.
                if ($g == 2) {
                    $r->set('r19_setup_probe', 'p', sub { (undef, $probe_err) = @_; });
                }
                my $t; $t = EV::timer 0.3, 0, sub {
                    undef $t;
                    if ($g == 1) {
                        $helper->command('CLIENT', 'KILL', 'ID', $id, sub { $kill1 = $_[0] });
                    }
                    elsif ($g == 2) {
                        $helper->command('CLIENT', 'KILL', 'ID', $id, sub { $kill2 = $_[0] });
                    }
                    else {
                        # queued behind the probe, so its reply means it applied
                        $r->ping(sub {
                            $helper->get('r19_setup_probe', sub {
                                ($final) = @_;
                                undef $to;
                                EV::break;
                            });
                        });
                    }
                };
            });
            if ($g == 1) {
                $r->blpop('r19_setup_block', 30, sub {});
                $r->multi(sub {});
                # HELLO waits for MULTI's outstanding reply, freezing the setup
                $r->command('HELLO', 2, sub {});
                $r->set('r19_setup_key', 'txn', sub {});
                $r->exec(sub {});
                $r->multi(sub {});
                $r->set('r19_setup_key2', 'txn2', sub {});
                $r->exec(sub {});
            }
            elsif ($g == 2) {
                $r->blpop('r19_setup_block2', 30, sub {});
            }
        },
    );

    $to = EV::timer 15, 0, sub {
        undef $to;
        EV::break;
    };
    EV::run;
    $r->disconnect;
    $helper->disconnect;

    skip $skip_reason, 4 if $skip_reason;
    skip 'failed to connect', 4 if $gen == 0;
    is $kill1, 1, 'first kill landed';
    is $kill2, 1, 'second kill landed';
    is $probe_err, undef, 'probe issued after the retained EXEC replays';
    is $final, 'p', '... and applies server-side';
}

# a fully unsent later span replays whole while the oldest span fails
SKIP: {
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 2,
        resume_waiting_on_reconnect => 1,
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 10,
        on_error => sub { },
    );

    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});

    my $to;
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

    skip $skip_reason, 5 if $skip_reason;
    skip 'failed to get client ID', 5 unless defined $client_id;

    $r->blpop('resume_span2_block', 10, sub { });
    $r->multi(sub { });
    my $set1_err;
    $r->set('resume_span1_key', 'x', sub {
        my ($res, $err) = @_;
        $set1_err = $err;
    });
    my $exec1_err;
    $r->exec(sub {
        my ($res, $err) = @_;
        $exec1_err = $err;
    });
    $r->multi(sub { });
    $r->set('resume_span2_key', 'txn', sub { });
    my ($exec2_res, $exec2_err, $final);
    $r->exec(sub {
        ($exec2_res, $exec2_err) = @_;
        $helper->get('resume_span2_key', sub {
            ($final) = @_;
            undef $to;
            EV::break;
        });
    });

    is $r->waiting_count, 5, 'span1 SET/EXEC and span2 wait behind BLPOP and MULTI';

    my $kill_timer; $kill_timer = EV::timer 0.3, 0, sub {
        undef $kill_timer;
        $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {});
    };

    $to = EV::timer 8, 0, sub {
        undef $to;
        $r->disconnect;
        EV::break;
    };
    EV::run;
    $r->disconnect;
    $helper->disconnect;

    ok $set1_err, 'submitted span fails its SET';
    ok $exec1_err, 'submitted span fails its EXEC';
    is $exec2_err, undef, 'unsent span replays without error';
    is $final, 'txn', 'unsent span applied whole server-side';
}

# commands issued after a taken span stay standalone, not txn-marked
SKIP: {
    my ($discs, $conns) = (0, 0);
    my ($set_err, $ping_res, $ping_err);
    my $to;
    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my $r;
    $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 2,
        resume_waiting_on_reconnect => 1,
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 10,
        on_error => sub { },
        on_disconnect => sub {
            return if $discs++;
            # after disconnect_cb returns the reconnect is armed: queueing then
            # must see no span (the taken one is gone)
            my $qt; $qt = EV::timer 0, 0, sub {
                undef $qt;
                $r->command('ping', sub {
                    ($ping_res, $ping_err) = @_;
                    undef $to;
                    EV::break;
                });
            };
        },
        on_connect => sub {
            return if ++$conns != 2;
            $r->blpop('resume_nospan_block', 30, sub { });
            $r->multi(sub { });
            my $kt; $kt = EV::timer 0.3, 0, sub {
                undef $kt;
                $helper->command('client', 'list', sub {
                    my ($line) = grep { /cmd=blpop/ } split /\n/, $_[0];
                    my ($id) = $line =~ /id=(\d+)/;
                    $helper->command('client', 'kill', 'id', $id, sub {});
                });
            };
        },
    );

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

    $r->blpop('resume_nospan_pad', 30, sub { });
    $r->multi(sub { });
    $r->set('resume_nospan_key', 'x', sub {
        my ($res, $err) = @_;
        $set_err = $err;
    });

    my $kill_timer; $kill_timer = EV::timer 0.3, 0, sub {
        undef $kill_timer;
        $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {});
    };

    $to = EV::timer 15, 0, sub {
        undef $to;
        $r->disconnect;
        EV::break;
    };
    EV::run;
    $r->disconnect;
    $helper->disconnect;

    ok $set_err, 'first span fragment fails on the first disconnect';
    is $ping_err, undef, 'post-take PING replays without error';
    is $ping_res, 'PONG', '... and gets its reply';
}

# a refused WATCH watches nothing: later waiting commands still replay
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

    my ($watch_err, $set_res);
    $r->command('watch', sub {
        my ($res, $err) = @_;
        $watch_err = $err;
        $r->blpop('resume_watcherr_block', 10, sub { });
        $r->set('resume_watcherr_key', 'v', sub {
            my ($res, $err) = @_;
            $set_res = $err // $res;
            $r->disconnect;
        });
        is $r->waiting_count, 2, 'BLPOP and SET queue in the WATCH callback';
        my $kill_timer; $kill_timer = EV::timer 0.3, 0, sub {
            undef $kill_timer;
            $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {
                $helper->disconnect;
            });
        };
    });

    my $timeout; $timeout = EV::timer 5, 0, sub {
        undef $timeout;
        $r->disconnect;
    };
    EV::run;

    like $watch_err, qr/wrong number/, 'WATCH with no keys errors';
    is $set_res, 'OK', 'SET replays after reconnect despite refused WATCH';
}

# skip_waiting closes the span it clears: later issues stay standalone
SKIP: {
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 2,
        resume_waiting_on_reconnect => 1,
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 10,
        on_error => sub { },
    );
    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});

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

    skip $skip_reason, 4 if $skip_reason;
    skip 'failed to get client ID', 4 unless defined $client_id;

    $r->blpop('resume_skip_pad', 30, sub { });
    $r->multi(sub { });
    my $set_err;
    $r->set('resume_skip_key', 'x', sub {
        my ($res, $err) = @_;
        $set_err = $err;
    });
    is $r->waiting_count, 1, 'SET waits behind BLPOP and MULTI';
    $r->skip_waiting;
    is $set_err, 'skipped', '... and skip_waiting fails it';

    my ($ping_res, $ping_err, $to);
    $r->command('ping', sub {
        ($ping_res, $ping_err) = @_;
        undef $to;
        EV::break;
    });

    my $kt; $kt = EV::timer 0.3, 0, sub {
        undef $kt;
        $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {});
    };

    $to = EV::timer 10, 0, sub {
        undef $to;
        $r->disconnect;
        EV::break;
    };
    EV::run;
    $r->disconnect;
    $helper->disconnect;

    is $ping_err, undef, 'post-skip PING replays without error';
    is $ping_res, 'PONG', '... and gets its reply';
}

# a setup span split by a drop fails its stranded fragments
{
    my ($set_err, $exec_err, $final, $to);
    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my ($gen, $r);
    $r = EV::Redis->new(
        path => $connect_info{sock},
        resume_waiting_on_reconnect => 1,
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 5,
        on_error => sub { },
        on_connect => sub {
            return if $gen++;
            $r->blpop('resume_setup_block', 10, sub { });
            $r->multi(sub { });
            $r->command('HELLO', '2', sub { });
            $r->set('resume_setup_key', 'orphan', sub {
                my ($res, $err) = @_;
                $set_err = $err;
            });
            $r->exec(sub {
                my ($res, $err) = @_;
                $exec_err = $err;
            });
        },
    );

    my $poll; $poll = EV::timer 0.1, 0.1, sub {
        $helper->command('client', 'list', sub {
            my ($line) = grep { /cmd=blpop/ } split /\n/, $_[0];
            return unless $line;
            my ($id) = $line =~ /id=(\d+)/;
            undef $poll;
            $helper->command('client', 'kill', 'id', $id, sub {
                my $wt; $wt = EV::timer 1.5, 0, sub {
                    undef $wt;
                    $helper->get('resume_setup_key', sub {
                        ($final) = @_;
                        undef $to;
                        EV::break;
                    });
                };
            });
        });
    };
    $to = EV::timer 12, 0, sub { undef $to; undef $poll; EV::break };
    EV::run;
    $r->disconnect;
    $helper->disconnect;

    ok $set_err, 'stranded setup SET fails instead of replaying';
    ok $exec_err, 'stranded setup EXEC fails instead of replaying';
    isnt $final, 'orphan', '... and never applies server-side';
}

# command() in the reconnect window queues instead of croaking
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

    # next iteration: after disconnect_cb returns and the reconnect timer is armed
    $r->on_disconnect(sub {
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

    my $kill_timer; $kill_timer = EV::timer 0.2, 0, sub {
        undef $kill_timer;
        $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {});
    };

    my $check_timer; $check_timer = EV::timer 3, 0, sub {
        undef $check_timer;
        $r->on_disconnect(undef);
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

{
    my $r = EV::Redis->new(
        path => $connect_info{sock},
        on_error => sub { },
    );

    $r->ping(sub {
        $r->disconnect;
    });
    my $stuck;
    my $g = EV::timer 10, 0, sub { $stuck = 1; EV::break };
    $g->keepalive(0);
    EV::run;
    ok !$stuck, 'the loop comes to rest after disconnect() in a reply callback';

    my $croaked = 0;
    eval { $r->set('key', 'val', sub {}) };
    $croaked = 1 if $@;

    ok $croaked, 'command without reconnect still croaks when disconnected';
    like $@, qr/connection required/, 'croak message mentions connection required';
}

# auto-queued command under waiting_timeout during reconnect
SKIP: {
    my @results;

    my $r = EV::Redis->new(
        path => $connect_info{sock},
        reconnect => 1,
        reconnect_delay => 100,
        max_reconnect_attempts => 10,
        waiting_timeout => 300,
        on_error => sub { },
    );

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

    $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {
        $helper->disconnect;
    });

    # reconnect usually beats the waiting_timeout
    my $done_timer; $done_timer = EV::timer 2, 0, sub {
        undef $done_timer;
        $r->on_disconnect(undef);
        $r->disconnect;
    };

    EV::run;

    is scalar(@results), 1, 'auto-queued command callback fired';
    ok(defined($results[0][0]) || defined($results[0][1]),
       'callback got either result or error (no silent drop)');
    is $r->is_connected, 0, 'disconnected after cleanup';
}

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

    my $reconnect_count = 0;
    $r->on_connect(sub {
        $reconnect_count++;
        EV::break;
    });

    $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {});

    { my $wait = EV::timer 3, 0, sub { EV::break }; EV::run }

    ok $reconnect_count >= 1, "reconnected after first kill (got $reconnect_count)";

    $reconnect_count = 0;
    $r->command('CLIENT', 'ID', sub {
        my ($res, $err) = @_;
        return unless defined $res;
        $helper->command('CLIENT', 'KILL', 'ID', $res, sub {});
    });

    { my $wait = EV::timer 3, 0, sub { EV::break }; EV::run }

    ok $reconnect_count >= 1, "reconnected after second kill (counter was reset, got $reconnect_count)";

    $r->on_connect(undef);
    $r->disconnect;
    $helper->disconnect;
}

# manual reconnect in on_disconnect honours resume_waiting_on_reconnect=0
SKIP: {
    skip $no_client_id, 4 if $no_client_id;
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
        $r->connect_unix($connect_info{sock});
    });

    $r->command('GET', 'soak', sub { push @results, ['cmd1', @_]; });
    $r->command('GET', 'soak', sub { push @results, ['cmd2', @_]; });

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

SKIP: {
    skip $no_client_id, 4 if $no_client_id;
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
    ok defined $client_id, 'got client id for new connection test';

    my ($old_err, $new_res, $new_err);
    $r->command('GET', 'old_cmd1', sub {});
    $r->command('GET', 'old_cmd2', sub { $old_err = $_[1] });

    $r->on_disconnect(sub {
        $r->connect_unix($connect_info{sock});
        $r->command('SET', 'new_key', 'val', sub {});
        $r->command('GET', 'new_key', sub { ($new_res, $new_err) = @_; EV::break });
    });

    $helper->command('CLIENT', 'KILL', 'ID', $client_id, sub {});

    my $w = EV::timer 2, 0, sub { EV::break };
    EV::run;

    ok defined $old_err, 'old waiting command received error';
    is $new_err, undef, 'new command queued in on_disconnect was not aborted';
    is $new_res, 'val', 'new command executed on new connection and received result';

    $r->on_disconnect(undef);
    $r->disconnect;
    $helper->disconnect;
}

sub client_id_of {
    my ($r) = @_;
    my $id;
    $r->command('CLIENT', 'ID', sub { $id = $_[0]; EV::break });
    my $guard = EV::timer 2, 0, sub { EV::break };
    EV::run;
    return $id;
}

# the caller's callbacks stop the loop once the drop is handled
sub kill_client {
    my ($id) = @_;
    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $helper->command('CLIENT', 'KILL', 'ID', $id, sub {});
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    $helper->disconnect;
}

SKIP: {
    my (@order, @werr);
    my $r = EV::Redis->new(
        path          => $connect_info{sock},
        max_pending   => 1,
        on_error      => sub { push @order, 'on_error' },
        on_disconnect => sub { push @order, 'on_disconnect' },
    );
    my $id = client_id_of($r);
    skip 'CLIENT ID not supported', 2 unless $id;
    $r->command('BLPOP', 'rc_nokey', 10, sub {});
    for my $n (1 .. 3) {
        $r->command('GET', "w$n", sub {
            push @order, 'waiting';
            push @werr, $_[1];
            EV::break if @werr == 3;
        });
    }
    kill_client($id);

    is "@order", 'on_error on_disconnect waiting waiting waiting',
        'drop: handlers first, then the waiting commands';
    is scalar(grep { defined && length } @werr), 3,
        'drop: every waiting command got the error';
}

# a waiting command's callback may connect again inside the disconnect() failing it
SKIP: {
    my $r;
    $r = EV::Redis->new(
        path                        => $connect_info{sock},
        on_error                    => sub { EV::break },
        reconnect                   => 1,
        reconnect_delay             => 5000,
        resume_waiting_on_reconnect => 1,
        max_pending                 => 1,
    );
    my $id = client_id_of($r);
    skip 'CLIENT ID not supported', 1 unless $id;
    $r->command('BLPOP', 'rc_nokey', 10, sub {});
    $r->command('GET', 'x', sub { $r->connect_unix($connect_info{sock}) if defined $_[1] });
    kill_client($id);
    $r->on_error(sub {});

    $r->disconnect;
    ok $r->is_connected, 'disconnect: the connection its callback opened survives';
    $r->disconnect;
}

# on_error may connect again and queue past max_pending; those commands run
SKIP: {
    my ($r, $res, $err);
    $r = EV::Redis->new(
        path        => $connect_info{sock},
        max_pending => 1,
        on_error    => sub {
            return if $r->is_connected;
            $r->connect_unix($connect_info{sock});
            $r->command('SET', 'rc_onerr', 'v', sub {});
            $r->command('GET', 'rc_onerr', sub { ($res, $err) = @_; EV::break });
        },
    );
    my $id = client_id_of($r);
    skip 'CLIENT ID not supported', 2 unless $id;
    $r->command('BLPOP', 'rc_nokey', 10, sub {});
    $r->command('GET', 'old', sub {});
    kill_client($id);

    is $err, undef, 'on_error reconnect: queued command not failed';
    is $res, 'v', 'on_error reconnect: queued command ran on the new connection';
    $r->on_error(sub {});
    $r->disconnect;
}

# the same after a failed connect, inside the call and through the loop
sub reconnecting_on_error {
    my ($rref, $resref) = @_;
    return sub {
        return if $$rref->is_connected;
        $$rref->connect_unix($connect_info{sock});
        $$rref->command('SET', 'rc_onfail', 'v', sub {});
        $$rref->command('GET', 'rc_onfail', sub { $$resref = $_[0]; EV::break });
    };
}

{
    my ($r, $res);
    $r = EV::Redis->new(max_pending => 1, on_error => reconnecting_on_error(\$r, \$res));
    $r->connect_unix('/nonexistent/ev-redis-test.sock');
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is $res, 'v', 'connect failing inside the call: on_error reconnect runs its commands';
    $r->on_error(sub {});
    $r->disconnect;
}

SKIP: {
    my ($r, $res, $old_err, $fired);
    my $handler = reconnecting_on_error(\$r, \$res);
    $r = EV::Redis->new(max_pending => 1, on_error => sub { $fired++; $handler->(@_) });
    $r->connect('127.0.0.1', empty_port());
    skip 'loopback connect refused synchronously', 2 if $fired;
    $r->command('PING', sub {});
    $r->command('PING', sub { $old_err = $_[1] });
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    ok defined $old_err, 'refused connect: old waiting command failed';
    is $res, 'v', 'refused connect: on_error reconnect runs its commands';
    $r->on_error(sub {});
    $r->disconnect;
}

# an explicit disconnect() cancels waiting commands even when on_disconnect
# connects again; a subscribed PING lets it complete inside the call
{
    my ($r, $werr);
    $r = EV::Redis->new(
        path => $connect_info{sock}, on_error => sub {},
        max_pending => 1, resume_waiting_on_reconnect => 1,
    );
    $r->command('SUBSCRIBE', 'rc_dc_ch', sub { EV::break if $_[0] && $_[0][0] eq 'subscribe' });
    my $guard = EV::timer 2, 0, sub { EV::break };
    EV::run;
    $r->command('PING', sub {});
    $r->command('GET', 'rc_dc', sub { $werr = $_[1] });
    $r->on_disconnect(sub { $r->on_disconnect(undef); $r->connect_unix($connect_info{sock}) });
    $r->disconnect;
    is $werr, 'disconnected', 'explicit disconnect: waiting command cancelled despite a reconnect';
    $r->disconnect;
}

# on_connect's setup runs before commands that waited through the reconnect,
# even past max_pending
SKIP: {
    skip $no_client_id, 1 if $no_client_id;
    my ($r, $conns, $id, $name) = (undef, 0);
    $r = EV::Redis->new(
        path => $connect_info{sock}, reconnect => 1, reconnect_delay => 50,
        max_pending => 1,
        on_error   => sub {},
        on_connect => sub {
            $conns++;
            $r->command('client', 'setname', "rc_setup${conns}a", sub {});
            $r->command('client', 'setname', "rc_setup${conns}b", sub {});
            $r->command('client', 'id', sub { $id = $_[0] }) if $conns == 1;
        },
    );
    run_until(3, sub { defined $id });
    my $admin = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $admin->command('client', 'kill', 'id', $id, sub {});
    my $chk = EV::check sub {
        return if $r->is_connected || $r->waiting_count;
        $r->command('client', 'getname', sub { $name = $_[0] // $_[1] });
    };
    run_until(3, sub { defined $name });
    undef $chk;
    is $name, 'rc_setup2b', 'on_connect setup runs before commands waiting through a reconnect';
    $r->disconnect;
    $admin->disconnect;
}

# re-entered: an earlier test's leftover watcher may break the loop
sub run_until {
    my ($secs, $done) = @_;
    my $end = EV::time + $secs;
    my $tick = EV::timer 0.05, 0.05, sub { EV::break if $done->() || EV::time >= $end };
    EV::run until $done->() || EV::time >= $end;
}

# commands issued during a reconnect keep their order; check watchers run
# ahead of each iteration's I/O, so B goes out while the attempt is connecting
SKIP: {
    skip $no_client_id, 1 if $no_client_id;
    my ($r, $id, @order) = (undef);
    $r = EV::Redis->new(
        path => $connect_info{sock}, reconnect => 1, reconnect_delay => 100,
        on_error => sub {},
    );
    $r->command('client', 'id', sub { $id = $_[0] });
    run_until(3, sub { defined $id });
    my $admin = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $admin->command('client', 'kill', 'id', $id, sub {});
    my $state = 0;
    my $chk = EV::check sub {
        if ($state == 0 && !$r->is_connected) {
            $r->command('echo', 'A', sub { push @order, $_[0] // $_[1] });
            $state = 1;
        }
        elsif ($state == 1 && $r->is_connected) {
            $r->command('echo', 'B', sub { push @order, $_[0] // $_[1] });
            $state = 2;
        }
    };
    run_until(3, sub { @order == 2 });
    undef $chk;
    is_deeply \@order, ['A', 'B'], 'commands issued during a reconnect keep their order';
    $r->disconnect;
    $admin->disconnect;
}

# resume_waiting_on_reconnect: raising max_pending must not push waiting
# commands into an attempt that is still connecting
{
    my $closed = empty_port();
    my @log;
    my $r = EV::Redis->new(on_error => sub {});
    $r->reconnect(1, 5000);
    $r->resume_waiting_on_reconnect(1);
    $r->connect('127.0.0.1', $closed);
    $r->command('ping', sub { push @log, $_[1] // $_[0] });
    $r->max_pending(0);
    run_until(0.5, sub { 0 });
    is $r->waiting_count, 1, 'resume: max_pending during an attempt keeps the command waiting';
    is_deeply \@log, [], 'resume: the waiting command was not failed';
    $r->reconnect(0);
    $r->disconnect;
}

# resume_waiting_on_reconnect: a command issued while an attempt is still
# connecting waits like the others
for my $between (0, 1) {
  SKIP: {
    my $port = empty_port();
    my %conf = (port => $port, bind => '127.0.0.1');
    # a fresh hash each time: Test::RedisServer stores its temp dir in it
    my $srv = eval { Test::RedisServer->new(conf => {%conf}) }
        or skip "no TCP redis-server: $@", 2;
    EV::now_update;
    my (@log, $refused);
    my $r = EV::Redis->new(
        host => '127.0.0.1', port => $port,
        reconnect => 1, reconnect_delay => 100, resume_waiting_on_reconnect => 1,
        on_error   => sub { $refused = 1 if $_[0] =~ /refused/i },
        on_connect => sub { EV::break },
    );
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    $r->on_connect(undef);
    $srv->stop;
    my $state = 0;  # 0: until the drop is seen, 1: until an attempt is connecting
    my $chk = EV::check sub {
        if ($state == 0 && !$r->is_connected) {
            $r->get('rc_between', sub { push @log, 'between:' . ($_[1] // 'ok') }) if $between;
            $state = 1;
        }
        elsif ($state == 1 && $r->is_connected) {
            $r->get('rc_during', sub { push @log, 'during:' . ($_[1] // 'ok'); EV::break });
            $state = 2;
        }
    };
    run_until(0.5, sub { 0 });
    undef $chk;
    # FreeBSD may refuse inside connect(): attempts then never stay connecting
    if ($state < 2 && $refused) {
        $r->disconnect;
        skip 'loopback connect refused synchronously', 2;
    }
    is $state, 2, "resume, between=$between: a command issued while connecting";
    $srv = Test::RedisServer->new(conf => {%conf});
    run_until(5, sub { @log == ($between ? 2 : 1) });
    is_deeply \@log, [$between ? 'between:ok' : (), 'during:ok'],
        "resume, between=$between: a command issued mid-attempt survives it, in order";
    $r->disconnect;
  }
}

done_testing;
