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

$SIG{PIPE} = 'IGNORE';

my ($redis_version) = get_redis_version($connect_info{sock});
my $no_client_id = $redis_version < 5 ? 'CLIENT ID needs Redis 5+' : '';

my $r = EV::Redis->new;

# max_pending limit with waiting queue
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

    $r->command('blpop', 'key3', 10, sub { push @results, ['cmd3', @_] });
    is $r->pending_count, 2, 'pending_count still 2 (at limit)';
    is $r->waiting_count, 1, 'waiting_count is 1 (queued)';

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
    my %seen = map { $_->[0] => $_->[2] } @results;
    is $seen{cmd1}, 'skipped', 'cmd1 was skipped';
    is $seen{cmd2}, 'skipped', 'cmd2 was skipped';
    is $seen{cmd3}, 'skipped', 'cmd3 was skipped';
    is $seen{cmd4}, 'skipped', 'cmd4 was skipped';

    $r->max_pending(0);
}

# waiting queue drain
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;
    my $check_counts = sub {
        my ($exp_pending, $exp_waiting, $msg) = @_;
        is $r->pending_count, $exp_pending, "$msg: pending=$exp_pending";
        is $r->waiting_count, $exp_waiting, "$msg: waiting=$exp_waiting";
    };

    $r->command('set', 'drain_test_1', 'val1', sub { push @results, ['set1', @_] });
    $r->command('set', 'drain_test_2', 'val2', sub { push @results, ['set2', @_] });
    $check_counts->(2, 0, 'after 2 commands');

    $r->command('set', 'drain_test_3', 'val3', sub { push @results, ['set3', @_] });
    $r->command('set', 'drain_test_4', 'val4', sub {
        push @results, ['set4', @_];
        # the current command still counts as pending until its callback returns
        is $r->pending_count, 1, 'pending_count is 1 in last callback (self)';
        is $r->waiting_count, 0, 'waiting_count is 0 in last callback';
        $r->disconnect;
    });
    $check_counts->(2, 2, 'after 4 commands');

    EV::run;

    is scalar(@results), 4, 'all 4 callbacks executed';

    for my $res (@results) {
        is $res->[1], 'OK', "$res->[0] returned OK";
    }

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

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;

    $r->command('set', 'sw_test_1', 'val1', sub { push @results, ['cmd1', @_] });
    $r->command('set', 'sw_test_2', 'val2', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'sw_test_3', 'val3', sub { push @results, ['cmd3', @_] });
    $r->command('set', 'sw_test_4', 'val4', sub {
        push @results, ['cmd4', @_];
        $r->disconnect;
    });

    is $r->pending_count, 2, 'pending_count is 2';
    is $r->waiting_count, 2, 'waiting_count is 2';

    $r->skip_waiting;

    is $r->pending_count, 2, 'pending_count still 2 after skip_waiting';
    is $r->waiting_count, 0, 'waiting_count is 0 after skip_waiting';

    EV::run;

    is scalar(@results), 4, 'all 4 callbacks executed';
    my %seen = map { $_->[0] => $_ } @results;
    is $seen{cmd1}[1], 'OK', 'cmd1 completed normally';
    is $seen{cmd2}[1], 'OK', 'cmd2 completed normally';
    is $seen{cmd3}[2], 'skipped', 'cmd3 was skipped';
    is $seen{cmd4}[2], 'skipped', 'cmd4 was skipped';

    $r->max_pending(0);
}

{
    $r->connect_unix( $connect_info{sock} );

    my @results;
    my $skip_called = 0;

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

# waiting queue is cleared on disconnect by default
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    is $r->resume_waiting_on_reconnect, 0, 'resume_waiting_on_reconnect defaults to 0';

    my @results;
    $r->command('set', 'dc_test_1', 'val1', sub {
        push @results, ['cmd1', @_];
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

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    $r->waiting_timeout(100);

    my @results;

    $r->command('blpop', 'wt_test_key', 10, sub {
        push @results, ['cmd1', @_];
    });
    $r->command('set', 'wt_test_2', 'val2', sub {
        push @results, ['cmd2', @_];
    });
    $r->command('set', 'wt_test_3', 'val3', sub {
        push @results, ['cmd3', @_];
    });

    is $r->pending_count, 1, 'pending_count is 1';
    is $r->waiting_count, 2, 'waiting_count is 2';

    my $timer = EV::timer 0.2, 0, sub {
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

{
    $r->connect_unix( $connect_info{sock} );

    my $done = 0;
    $r->command('ping', sub {
        my ($res, $err) = @_;

        is $r->pending_count, 1, 'pending_count is 1 inside callback (self)';
        is $r->waiting_count, 0, 'waiting_count is 0';

        $r->skip_pending;
        $r->skip_waiting;

        is $r->pending_count, 1, 'pending_count still 1 (current cb not skipped)';
        is $r->waiting_count, 0, 'waiting_count still 0 after skip_waiting on empty';

        $done = 1;
        $r->disconnect;
    });
    EV::run;
    ok $done, 'skip on empty queues test completed';
}

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    $r->command('set', 'mp_change_1', 'val1', sub { push @results, ['cmd1', @_] });
    $r->command('set', 'mp_change_2', 'val2', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'mp_change_3', 'val3', sub { push @results, ['cmd3', @_] });

    is $r->pending_count, 1, 'pending_count is 1';
    is $r->waiting_count, 2, 'waiting_count is 2';

    $r->max_pending(10);

    is $r->pending_count, 3, 'pending_count is 3 after increasing max_pending';
    is $r->waiting_count, 0, 'waiting_count is 0 after increasing max_pending';

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

# lowering max_pending below the pending count
{
    $r->connect_unix( $connect_info{sock} );

    my @results;

    $r->command('set', 'mp_dec_1', 'val1', sub { push @results, ['cmd1', @_] });
    $r->command('set', 'mp_dec_2', 'val2', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'mp_dec_3', 'val3', sub { push @results, ['cmd3', @_] });

    is $r->pending_count, 3, 'pending_count is 3';

    $r->max_pending(1);

    is $r->pending_count, 3, 'pending_count still 3 (already sent)';
    is $r->waiting_count, 0, 'waiting_count is 0';

    $r->command('set', 'mp_dec_4', 'val4', sub {
        push @results, ['cmd4', @_];
        $r->disconnect;
    });

    is $r->waiting_count, 1, 'new command goes to waiting';

    EV::run;

    is scalar(@results), 4, 'all 4 callbacks executed';

    $r->max_pending(0);
}

# skip_waiting from inside a callback
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    $r->command('set', 'sw_cb_1', 'val1', sub {
        push @results, ['cmd1', @_];
        $r->skip_waiting;
    });

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

    my %seen = map { $_->[0] => $_ } @results;
    is $seen{cmd2}[2], 'skipped', 'cmd2 was skipped';
    is $seen{cmd3}[2], 'skipped', 'cmd3 was skipped';

    $r->max_pending(0);
}

# repeated skip calls
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

    $r->skip_waiting;
    $r->skip_waiting;
    $r->skip_pending;
    $r->skip_pending;

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

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    $r->waiting_timeout(1);

    my @results;

    $r->command('blpop', 'short_timeout_key', 10, sub {
        push @results, ['cmd1', @_];
    });

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

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    $r->waiting_timeout(50);

    my @results;

    $r->command('blpop', 'disable_timeout_key', 10, sub {
        push @results, ['cmd1', @_];
    });
    $r->command('set', 'disable_2', 'val', sub { push @results, ['cmd2', @_] });

    is $r->waiting_count, 1, 'waiting_count is 1';

    $r->waiting_timeout(0);

    # wait longer than the original timeout
    my $timer = EV::timer 0.1, 0, sub {
        is $r->waiting_count, 1, 'waiting_count still 1 after disabling timeout';
        $r->skip_pending;
        $r->skip_waiting;
        $r->disconnect;
    };
    EV::run;

    is scalar(@results), 2, 'both callbacks executed';

    $r->max_pending(0);
}

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    $r->command('blpop', 'enable_timeout_key', 10, sub {
        push @results, ['cmd1', @_];
    });
    $r->command('set', 'enable_2', 'val', sub { push @results, ['cmd2', @_] });

    is $r->waiting_count, 1, 'waiting_count is 1';

    $r->waiting_timeout(50);

    my $timer = EV::timer 0.15, 0, sub {
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

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    $r->command('set', 'nested_1', 'val1', sub {
        push @results, ['cmd1', @_];

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

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    $r->command('set', 'dc_wait_1', 'val1', sub {
        push @results, ['cmd1', @_];
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

{
    $r->connect_unix( $connect_info{sock} );

    my @results;

    $r->command('set', 'recon_1', 'val1', sub {
        push @results, ['cmd1', @_];
        $r->disconnect;
    });

    EV::run;

    is $results[0][1], 'OK', 'cmd1 succeeded before disconnect';

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

        eval {
            $r->command('set', 'after_dc_2', 'val2', sub {
                push @results, ['cmd2', @_];
            });
        };
        like $@, qr/connection required/, 'command after disconnect croaks';
    });

    EV::run;

    is $results[0][1], 'OK', 'cmd1 succeeded';

    $r->on_error(sub { die @_ });
}

# command queued from a waiting-timeout callback
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);
    $r->waiting_timeout(50);

    my @results;
    my $added_during_timeout = 0;

    $r->command('blpop', 'expire_add_key', 10, sub {
        push @results, ['cmd1', @_];
    });

    $r->command('set', 'expire_add_2', 'val', sub {
        push @results, ['cmd2', @_];
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

# skip_pending before any reply arrives
{
    $r->connect_unix( $connect_info{sock} );

    my @results;

    $r->command('set', 'imm_skip_1', 'val1', sub { push @results, ['cmd1', @_] });
    $r->command('set', 'imm_skip_2', 'val2', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'imm_skip_3', 'val3', sub { push @results, ['cmd3', @_] });

    is $r->pending_count, 3, 'pending_count is 3';

    $r->skip_pending;

    is $r->pending_count, 0, 'pending_count is 0 after skip';

    $r->disconnect;
    EV::run;

    is scalar(@results), 3, 'all 3 callbacks executed';
    for my $res (@results) {
        is $res->[2], 'skipped', "$res->[0] was skipped";
    }
}

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    $r->command('set', 'unlimit_1', 'val1', sub { push @results, ['cmd1', @_] });
    $r->command('set', 'unlimit_2', 'val2', sub { push @results, ['cmd2', @_] });
    $r->command('set', 'unlimit_3', 'val3', sub { push @results, ['cmd3', @_] });
    $r->command('set', 'unlimit_4', 'val4', sub {
        push @results, ['cmd4', @_];
        $r->disconnect;
    });

    is $r->pending_count, 1, 'pending_count is 1';
    is $r->waiting_count, 3, 'waiting_count is 3';

    $r->max_pending(0);

    is $r->pending_count, 4, 'pending_count is 4 after removing limit';
    is $r->waiting_count, 0, 'waiting_count is 0 after removing limit';

    EV::run;

    is scalar(@results), 4, 'all 4 callbacks executed';
    for my $res (@results) {
        is $res->[1], 'OK', "$res->[0] succeeded";
    }
}

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;
    my @order;

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

# new command right after skip_waiting inside a callback
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my @results;

    $r->command('set', 'alt_skip_1', 'val1', sub {
        push @results, ['cmd1', @_];

        $r->skip_waiting;

        $r->command('set', 'alt_skip_4', 'val4', sub {
            push @results, ['cmd4', @_];
            $r->disconnect;
        });
    });

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

# PING: one of the few commands Redis allows in subscribe context
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;
    my $sub_count = 0;

    $r->command('subscribe', 'edge_chan', sub {
        my ($r_msg, $e) = @_;
        $sub_count++;
        push @results, ['subscribe', $r_msg, $e];

        if ($r_msg && $r_msg->[0] eq 'subscribe') {
            is $r->pending_count, 2, 'pending_count excludes subscribe';
        }
    });

    $r->command('ping', sub {
        push @results, ['cmd1', @_];
    });

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

    ok $r->waiting_count > 0, "waiting_count > 0 with $num_commands commands";
    is $r->pending_count + $r->waiting_count, $num_commands, 'pending + waiting = total commands';

    EV::run;

    is scalar(@results), $num_commands, "all $num_commands callbacks executed";

    my $all_ok = 1;
    for my $res (@results) {
        if ($res->{res} ne 'OK' || $res->{err}) {
            $all_ok = 0;
            last;
        }
    }
    ok $all_ok, 'all stress test commands succeeded';

    my @order = map { $_->{i} } @results;
    my @expected = (1..$num_commands);
    is_deeply \@order, \@expected, 'commands executed in FIFO order';

    $r->max_pending(0);
}

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

# skip_waiting between batches of queued commands
{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(2);

    my @results;

    for my $round (1..3) {
        for my $i (1..5) {
            $r->set("alt_stress_${round}_$i", "val", sub {
                my ($res, $err) = @_;
                push @results, { name => "round${round}_$i", res => $res, err => $err };
            });
        }

        $r->skip_waiting;
    }

    $r->set("alt_stress_final", "val", sub {
        my ($res, $err) = @_;
        push @results, { name => "final", res => $res, err => $err };
        $r->disconnect;
    });

    EV::run;

    my @skipped = grep { $_->{err} && $_->{err} eq 'skipped' } @results;
    my @completed = grep { $_->{res} && $_->{res} eq 'OK' } @results;

    ok scalar(@skipped) > 0, 'some commands were skipped';
    ok scalar(@completed) > 0, 'some commands completed successfully';
    is scalar(@results), scalar(@skipped) + scalar(@completed), 'all callbacks accounted for';

    $r->max_pending(0);
}

{
    $r->connect_unix( $connect_info{sock} );
    $r->max_pending(1);

    my ($k1_err, $k2_called, $k2_err);
    $r->command('ping', sub {
        $r->command('get', 'wait_k1', sub {
            $k1_err = $_[1];
            $r->command('get', 'wait_k2', sub {
                (undef, $k2_err) = @_;
                $k2_called = 1;
                $r->disconnect;
                EV::break;
            });
        });
        $r->skip_waiting;
    });

    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is $k1_err, 'skipped', 'waiting command k1 was skipped';
    ok $k2_called, 'command k2 queued during k1 callback ran';
    is $k2_err, undef, 'command k2 queued during k1 callback was not skipped';
    $r->max_pending(0);
}

{
    my $r2 = EV::Redis->new(
        path => $connect_info{sock}, max_pending => 1, waiting_timeout => 200,
    );
    my $k2_err;
    $r2->command('BLPOP', 'fc_nokey', 2, sub {});
    $r2->command('GET', 'k1', sub {
        $r2->command('GET', 'k2', sub { $k2_err = $_[1]; EV::break });
    });
    my $t0 = EV::time;
    $r2->skip_waiting;
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is $k2_err, 'waiting timeout', 'requeued during skip_waiting: still times out';
    cmp_ok EV::time - $t0, '<', 1.5, 'requeued during skip_waiting: on time';
    $r2->disconnect;
}

# DESTROY inside a skip_waiting batch fails what an earlier callback of it queued
{
    my $r2;
    $r2 = EV::Redis->new(
        path => $connect_info{sock}, max_pending => 1, on_error => sub {},
    );
    my $err;
    $r2->command('ping', sub {});
    $r2->command('ping', sub { $r2->command('ping', sub { $err = $_[1] }) });
    $r2->command('ping', sub { undef $r2 });
    $r2->skip_waiting;
    is $err, 'disconnected', 'DESTROY during skip_waiting: requeued command failed';
}

# a command queued by a skipped callback at max_pending must still be sent
{
    my $r = EV::Redis->new(
        path => $connect_info{sock}, on_error => sub {}, on_connect => sub { EV::break },
    );
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    my ($c, $e);
    $r->max_pending(1);
    $r->command('blpop', 'fc_skip_nokey', 1, sub {});
    $r->command('ping', sub { $r->command('echo', 'C', sub { $c = $_[0] // $_[1] }) });
    $r->skip_pending;
    my $t = EV::timer 1.5, 0, sub { $r->command('echo', 'E', sub { $e = $_[0] // $_[1]; EV::break }) };
    my $g = EV::timer 4, 0, sub { EV::break };
    EV::run;
    is $c, 'C', 'skip_pending: a command queued by a skipped callback is sent';
    is $e, 'E', 'skip_pending: later commands are not stuck behind it';
    $r->disconnect;
}

# the waiting commands a lost connection cancels leave the queue before
# on_error and on_disconnect run, and fail once, after them
SKIP: {
    skip $no_client_id, 1 if $no_client_id;
    my $killer = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my (@seen, $r);
    $r = EV::Redis->new(
        path => $connect_info{sock}, max_pending => 1,
        on_error      => sub { push @seen, 'error ' . $r->waiting_count },
        on_disconnect => sub {
            push @seen, 'disconnect ' . $r->waiting_count;
            $r->skip_waiting;
        },
    );
    $r->command('client', 'id', sub {
        my $id = shift;
        $r->command('blpop', 'fc_handler_nokey', 5, sub {});
        for my $k (qw(w1 w2)) {
            $r->command('echo', $k, sub {
                push @seen, "$k " . (defined $_[1] && 'skipped' ne $_[1] ? 'connection error' : $_[1] // 'reply');
                EV::break if 'w2' eq $k;
            });
        }
        $killer->command('client', 'kill', 'id', $id, sub {});
    });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is_deeply \@seen, ['error 0', 'disconnect 0', 'w1 connection error', 'w2 connection error'],
        'waiting commands cancelled by a lost connection fail after on_error and on_disconnect';
    $r->on_error(undef);
    $r->on_disconnect(undef);
    $killer->disconnect;
}

# commands being cancelled are never sent: not by a cancelled callback that
# calls skip_pending ...
{
    my $r = EV::Redis->new(
        path => $connect_info{sock}, on_error => sub {}, on_connect => sub { EV::break },
    );
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    $r->command('del', 'fc_doomed', sub { EV::break });
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    my @incr;
    $r->max_pending(1);
    $r->command('blpop', 'fc_doomed_nokey', 1, sub {});
    $r->command('echo', 'w1', sub { $r->skip_pending });
    $r->command('incr', 'fc_doomed', sub { push @incr, $_[1] // "reply $_[0]" }) for 1, 2;
    $r->skip_waiting;
    is_deeply \@incr, ['skipped', 'skipped'],
        'skip_pending from a cancelled callback: the rest is still cancelled';
    my $value = 'no reply';
    $r->max_pending(0);
    $r->command('get', 'fc_doomed', sub { $value = $_[0]; EV::break });
    { my $g = EV::timer 4, 0, sub { EV::break }; EV::run }
    is $value, undef, 'skip_pending from a cancelled callback: nothing was sent';
    $r->disconnect;
}

# ... nor by an on_disconnect that connects again and lifts max_pending; the
# new connection is idle enough for MONITOR, and takes new commands
for my $then (qw(max_pending monitor command)) { SKIP: {
    skip $no_client_id, 'max_pending' eq $then ? 1 : 2 if $no_client_id;
    my $killer = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my (%got, $r, $seen, $monitor_err);
    $r = EV::Redis->new(
        path => $connect_info{sock}, max_pending => 1, on_error => sub {},
        on_disconnect => sub {
            return if $seen++;
            $r->connect_unix($connect_info{sock});
            if ('max_pending' eq $then) {
                $r->max_pending(0);
            }
            elsif ('monitor' eq $then) {
                eval { $r->command('monitor', sub {}); 1 } or $monitor_err = $@;
            }
            else {
                $r->max_pending(5);
                $r->command('echo', 'new', sub { $got{new} = $_[0] // $_[1] });
                my $t = EV::timer 0.3, 0, sub { EV::break };
                EV::run;
            }
        },
    );
    $r->command('client', 'id', sub {
        my $id = shift;
        $r->command('blpop', 'fc_cancel_nokey', 5, sub {});
        for my $k (qw(w1 w2)) {
            $r->command('incr', "fc_cancel_$k", sub {
                $got{$k} = defined $_[1] ? 'cancelled' : "reply $_[0]";
                EV::break if 'w2' eq $k;
            });
        }
        $killer->command('client', 'kill', 'id', $id, sub {});
    });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is_deeply [@got{qw(w1 w2)}], ['cancelled', 'cancelled'],
        "on_disconnect reconnects, then $then: waiting commands are cancelled, not sent";
    is $monitor_err, undef, 'on_disconnect reconnects: MONITOR is accepted' if 'monitor' eq $then;
    is $got{new}, 'new', 'on_disconnect reconnects: a new command is sent' if 'command' eq $then;
    $r->on_disconnect(undef);
    $r->disconnect;
    $killer->disconnect;
} }

# disconnect() inside a cancel batch also cancels what its callbacks queued
{
    my @log;
    my $r = EV::Redis->new(
        path => '/nonexistent/fc_batch.sock', on_error => sub {},
        reconnect => 1, reconnect_delay => 60_000,
    );
    $r->command('echo', 'w1', sub {
        $r->command('echo', 'x', sub { push @log, "x $_[1]" });
        $r->disconnect;
    });
    $r->command('echo', 'w2', sub { push @log, "w2 $_[1]" });
    $r->skip_waiting;
    is_deeply \@log, ['x disconnected', 'w2 skipped'],
        'disconnect() inside skip_waiting cancels what the callback queued';
    is $r->waiting_count, 0, 'disconnect() inside skip_waiting: nothing is left queued';
}

# the max_pending slot held by a command of an older, draining connection:
# when that connection dies, the waiting commands go out on the new one
SKIP: {
    skip $no_client_id, 1 if $no_client_id;
    my $killer = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my ($id, %got);
    my $r = EV::Redis->new(path => $connect_info{sock}, max_pending => 1, on_error => sub {});
    $r->command('client', 'id', sub { $id = $_[0]; EV::break });
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    $r->command('blpop', 'fc_drain_nokey', 0, sub {});
    { my $g = EV::timer 0.1, 0, sub { EV::break }; EV::run }
    $r->disconnect;
    $r->connect_unix($connect_info{sock});
    $r->command('echo', 'x', sub { $got{x} = $_[0] // $_[1]; EV::break });
    $killer->command('client', 'kill', 'id', $id, sub {});
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    is $got{x}, 'x', 'a command waiting on a dead older connection is sent on the new one';
    $r->disconnect;
    $killer->disconnect;
}

# a callback of the dying connection that lifts max_pending must not push the
# waiting commands into it: with resume_waiting_on_reconnect they are kept
SKIP: {
    skip $no_client_id, 1 if $no_client_id;
    my $killer = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my ($got, $r);
    $r = EV::Redis->new(
        path => $connect_info{sock}, max_pending => 1, on_error => sub {},
        reconnect => 1, reconnect_delay => 50, resume_waiting_on_reconnect => 1,
    );
    $r->command('client', 'id', sub {
        my $id = shift;
        $r->command('blpop', 'fc_dying_nokey', 5, sub { $r->max_pending(0) });
        $r->command('echo', 'w1', sub { $got = $_[0] // $_[1]; EV::break });
        $killer->command('client', 'kill', 'id', $id, sub {});
    });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is $got, 'w1', 'max_pending(0) from the dying connection: the waiting command survives';
    $r->reconnect(0);
    $r->disconnect;
    $killer->disconnect;
}

# MONITOR is refused while hiredis still owes the replies skip_pending skipped
for my $where (qw(after inside)) {
    my $r = EV::Redis->new(
        path => $connect_info{sock}, on_error => sub {}, on_connect => sub { EV::break },
    );
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    my $err;
    my $monitor = sub { eval { $r->command('monitor', sub {}); 1 } or $err = $@ };
    $r->command('blpop', 'fc_monitor_nokey', '0.2', sub { $monitor->() if 'inside' eq $where });
    $r->skip_pending;
    $monitor->() if 'after' eq $where;
    like $err // '', qr/idle connection/, "MONITOR $where skip_pending is refused";
    { my $g = EV::timer 0.5, 0, sub { EV::break }; EV::run }
    $r->disconnect;
}

# ... and on a subscribed connection whose subscribe callback skip_pending skipped
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $r->command('subscribe', 'fc_monitor_channel', sub { EV::break });
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    $r->skip_pending;
    eval { $r->command('monitor', sub {}) };
    like $@, qr/idle connection/, 'MONITOR on a subscribed connection after skip_pending is refused';
    $r->disconnect;
}

# a lost connection: commands the cancelled callbacks issue on a new
# connection are kept, also those that wait behind max_pending there
SKIP: {
    skip $no_client_id, 1 if $no_client_id;
    my $killer = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my (%got, $r);
    $r = EV::Redis->new(path => $connect_info{sock}, max_pending => 1, on_error => sub {});
    $r->command('client', 'id', sub {
        my $id = shift;
        $r->command('blpop', 'fc_lost_nokey', 5, sub {});
        $r->command('echo', 'w1', sub {
            $r->connect_unix($connect_info{sock});
            for my $k (qw(x y)) {
                $r->command('echo', $k, sub {
                    $got{$k} = $_[0] // $_[1];
                    EV::break if 'y' eq $k;
                });
            }
        });
        $killer->command('client', 'kill', 'id', $id, sub {});
    });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is_deeply \%got, { x => 'x', y => 'y' },
        'commands issued by callbacks a lost connection cancels are kept';
    $r->disconnect;
    $killer->disconnect;
}

# with resume_waiting_on_reconnect, the settings as the connection is lost
# decide: a handler changing them later does not undo that
for my $case ([1, 0, 'kept'], [0, 1, 'cancelled']) { SKIP: {
    skip $no_client_id, 1 if $no_client_id;
    my ($before, $after, $want) = @$case;
    my $killer = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my (@got, $r);
    $r = EV::Redis->new(
        path => $connect_info{sock}, max_pending => 1, on_error => sub {},
        reconnect => 1, reconnect_delay => 50, resume_waiting_on_reconnect => $before,
        on_disconnect => sub { $r->resume_waiting_on_reconnect($after) },
    );
    $r->command('client', 'id', sub {
        my $id = shift;
        $r->command('blpop', 'fc_toggle_nokey', 5, sub {});
        $r->command('echo', 'w1', sub { push @got, defined $_[1] ? 'cancelled' : 'kept'; EV::break });
        $killer->command('client', 'kill', 'id', $id, sub {});
    });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is_deeply \@got, [$want], "resume $before at the loss, $after from on_disconnect: $want";
    $r->on_disconnect(undef);
    $r->reconnect(0);
    $r->disconnect;
    $killer->disconnect;
} }

# resume_waiting_on_reconnect without reconnect: they are cancelled, and are
# off the queue before the handlers run
SKIP: {
    skip $no_client_id, 1 if $no_client_id;
    my $killer = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my (@seen, $r);
    $r = EV::Redis->new(
        path => $connect_info{sock}, max_pending => 1, resume_waiting_on_reconnect => 1,
        on_error      => sub { push @seen, 'error ' . $r->waiting_count },
        on_disconnect => sub { push @seen, 'disconnect ' . $r->waiting_count },
    );
    $r->command('client', 'id', sub {
        my $id = shift;
        $r->command('blpop', 'fc_noreconnect_nokey', 5, sub {});
        $r->command('echo', 'w1', sub { push @seen, defined $_[1] ? 'w1 cancelled' : 'w1 sent'; EV::break });
        $killer->command('client', 'kill', 'id', $id, sub {});
    });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is_deeply \@seen, ['error 0', 'disconnect 0', 'w1 cancelled'],
        'resume without reconnect: waiting commands cancelled after the handlers, off the queue before';
    $r->on_error(undef);
    $r->on_disconnect(undef);
    $killer->disconnect;
}

# a connection dying from command_timeout: its callbacks cannot push the
# waiting commands into it either
{
    my ($got, $r);
    $r = EV::Redis->new(
        path => $connect_info{sock}, max_pending => 1, on_error => sub {},
        command_timeout => 300,
        reconnect => 1, reconnect_delay => 50, resume_waiting_on_reconnect => 1,
    );
    $r->command('blpop', 'fc_timeout_nokey', 5, sub { $r->max_pending(0) });
    $r->command('echo', 'w1', sub { $got = $_[0] // $_[1]; EV::break });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is $got, 'w1', 'max_pending(0) from a timed-out connection: the waiting command survives';
    $r->reconnect(0);
    $r->disconnect;
}

# skip_pending leaves the commands its skipped callbacks issue alone
{
    my $r = EV::Redis->new(
        path => $connect_info{sock}, max_pending => 1, on_error => sub {},
        on_connect => sub { EV::break },
    );
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    my %got;
    $r->command('blpop', 'fc_issued_nokey', '0.3', sub {});
    $r->command('echo', 'w1', sub {
        for my $k (qw(x y)) {
            $r->command('echo', $k, sub { $got{$k} = $_[0] // $_[1]; EV::break if 'y' eq $k });
        }
        $r->max_pending(0);
    });
    $r->skip_pending;
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is_deeply \%got, { x => 'x', y => 'y' }, 'skip_pending: commands its skipped callbacks issue are sent';
    $r->disconnect;
}

# a nested loop inside a callback does not spin while a reply for the same
# connection waits; that reply comes once the callback has returned
{
    my $r = EV::Redis->new(
        path => $connect_info{sock}, on_error => sub {}, on_connect => sub { EV::break },
    );
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    my ($iterations, $second);
    $r->command('ping', sub {
        $r->command('ping', sub { $second = defined $iterations ? 'after' : 'inside'; EV::break });
        my $i0 = EV::iteration;
        my $t = EV::timer 0.3, 0, sub { EV::break };
        EV::run;
        $iterations = EV::iteration - $i0;
    });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    cmp_ok $iterations, '<', 100, 'a nested loop in a callback does not spin on a waiting reply';
    is $second, 'after', 'the waiting reply comes after the callback returns';
    $r->disconnect;
}

done_testing;
