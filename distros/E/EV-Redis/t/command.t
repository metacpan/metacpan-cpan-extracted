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

{
    $r->connect_unix( $connect_info{sock} );

    is $r->priority, 0, 'default priority is 0';

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

    $r->priority(100);
    is $r->priority, 2, 'priority 100 clamped to 2';

    $r->priority(-100);
    is $r->priority, -2, 'priority -100 clamped to -2';

    $r->priority(3);
    is $r->priority, 2, 'priority 3 clamped to 2';

    $r->priority(-3);
    is $r->priority, -2, 'priority -3 clamped to -2';

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

{
    my $r_prio = EV::Redis->new(
        path => $connect_info{sock},
        priority => 1,
    );
    is $r_prio->priority, 1, 'priority set via constructor';
    $r_prio->disconnect;
    EV::run;
}

{
    my $r_prio2 = EV::Redis->new(
        path => $connect_info{sock},
        priority => 99,
    );
    is $r_prio2->priority, 2, 'priority clamped via constructor';
    $r_prio2->disconnect;
    EV::run;
}

# a priority change must not reset or lose a running command timeout
{
    my $r_timeout = EV::Redis->new(
        path => $connect_info{sock},
        command_timeout => 200,
        on_error => sub { },
    );

    my $callback_called = 0;
    my $got_timeout = 0;
    my $start_time = EV::now;
    my $elapsed;

    $r_timeout->blpop('priority_timeout_test_key', 10, sub {
        my ($res, $err) = @_;
        $callback_called = 1;
        $elapsed = EV::now - $start_time;
        $got_timeout = 1 if defined($err);
        $r_timeout->disconnect;
    });

    $r_timeout->priority(1);
    $r_timeout->priority(-1);
    $r_timeout->priority(2);

    my $fallback = EV::timer 2, 0, sub {
        $r_timeout->disconnect unless $callback_called;
    };

    EV::run;

    ok $callback_called, 'callback was called after priority changes';
    ok $got_timeout, 'command timed out correctly after priority changes';
    ok $elapsed < 0.5, "timeout occurred within reasonable time (${elapsed}s < 0.5s)";
}

{
    my $r_zero = EV::Redis->new(
        path => $connect_info{sock},
        max_pending => 0,
        waiting_timeout => 0,
        priority => 0,
    );

    is $r_zero->max_pending, 0, 'max_pending explicitly set to 0';
    is $r_zero->priority, 0, 'priority explicitly set to 0';

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

{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->set('test:empty:value', '', sub {
        my ($res, $err) = @_;
        push @results, ['set_empty_value', $res, $err];

        $r->get('test:empty:value', sub {
            my ($res, $err) = @_;
            push @results, ['get_empty_value', $res, $err];

            $r->set('', 'empty_key_value', sub {
                my ($res, $err) = @_;
                push @results, ['set_empty_key', $res, $err];

                $r->get('', sub {
                    my ($res, $err) = @_;
                    push @results, ['get_empty_key', $res, $err];

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

{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

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

{
    my $r = EV::Redis->new(path => $connect_info{sock});

    my $died = 0;
    eval {
        $r->command(sub { });
    };
    $died = 1 if $@;

    ok $died, 'command() with only callback throws exception';
    like $@, qr/Usage:/, 'exception mentions usage';

    $r->disconnect;
}

# a non-CODE last argument is a command arg, not a callback
{
    my $r = EV::Redis->new(path => $connect_info{sock});

    eval { $r->command('SET', 'ff_test', 'value') };
    is $@, '', 'fire-and-forget command does not croak';

    my $got;
    $r->command('GET', 'ff_test', sub {
        ($got) = @_;
        $r->disconnect;
    });
    EV::run;
    is $got, 'value', 'fire-and-forget SET was executed by Redis';
}

{
    my $r = EV::Redis->new;

    $r->on_error(sub { });
    $r->on_error(undef);
    ok !defined($r->on_error), 'on_error cleared by undef';

    $r->on_connect(sub { });
    $r->on_connect(undef);
    ok !defined($r->on_connect), 'on_connect cleared by undef';

    $r->on_disconnect(sub { });
    $r->on_disconnect(undef);
    ok !defined($r->on_disconnect), 'on_disconnect cleared by undef';

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

{
    my $r = EV::Redis->new;

    for (1..5) {
        $r->on_error(sub { });
        $r->on_connect(sub { });
        $r->on_disconnect(sub { });
    }

    $r->on_error(undef);
    $r->on_connect(undef);
    $r->on_disconnect(undef);

    ok 1, 'repeatedly replacing callbacks does not crash';
}

{
    my $r = EV::Redis->new(
        connect_timeout => 5000,
        command_timeout => 3000,
    );

    is $r->connect_timeout(), 5000, 'connect_timeout getter returns set value';
    is $r->command_timeout(), 3000, 'command_timeout getter returns set value';

    $r->connect_timeout(7000);
    $r->command_timeout(4000);
    is $r->connect_timeout(), 7000, 'connect_timeout getter returns updated value';
    is $r->command_timeout(), 4000, 'command_timeout getter returns updated value';
}

{
    my $r = EV::Redis->new;

    ok !defined($r->connect_timeout()), 'connect_timeout returns undef when not set';
    ok !defined($r->command_timeout()), 'command_timeout returns undef when not set';
}

{
    my $r = EV::Redis->new;

    my $called = 0;
    $r->on_connect(sub { $called++ });

    $r->on_connect();

    my $new_called = 0;
    $r->on_connect(sub { $new_called++ });

    $r->connect_unix($connect_info{sock});
    my $t; $t = EV::timer 0.1, 0, sub { $r->disconnect; undef $t };
    EV::run;

    is $called, 0, 'old on_connect handler was cleared';
    is $new_called, 1, 'new on_connect handler works after clearing';
}

{
    $r->connect_unix($connect_info{sock});

    my @results;

    $r->del('empty_list_test', sub {
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

{
    my $r = EV::Redis->new;

    eval { $r->connect_timeout(2000000000) };
    ok !$@, 'large valid timeout accepted';
    is $r->connect_timeout, 2000000000, 'large timeout value preserved';

    eval { $r->connect_timeout(2000000001) };
    like $@, qr/timeout too large/, 'timeout exceeding max rejected';

    eval { $r->command_timeout(2000000001) };
    like $@, qr/timeout too large/, 'command_timeout exceeding max rejected';

    eval { $r->waiting_timeout(2000000001) };
    like $@, qr/waiting_timeout too large/, 'waiting_timeout exceeding max rejected';

    eval { $r->waiting_timeout(60000) };
    ok !$@, 'normal waiting_timeout accepted';
    is $r->waiting_timeout, 60000, 'waiting_timeout value preserved';
}

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

{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->del('tx_key1', 'tx_key2', 'tx_counter', sub {
        $r->multi(sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'multi', res => $res, err => $err };

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

SKIP: {
    skip 'WATCH requires Redis 2.2+', 8 if $redis_version < 2 || ($redis_version == 2 && $redis_minor < 2);

    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->set('watch_key', '100', sub {
        $r->watch('watch_key', sub {
            my ($res, $err) = @_;
            push @results, { cmd => 'watch', res => $res, err => $err };

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

SKIP: {
    skip 'EVAL requires Redis 2.6+', 6 if $redis_version < 2 || ($redis_version == 2 && $redis_minor < 6);

    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    my $script1 = q{return {KEYS[1], ARGV[1], ARGV[2]}};

    $r->eval($script1, 1, 'mykey', 'arg1', 'arg2', sub {
        my ($res, $err) = @_;
        push @results, { cmd => 'eval1', res => $res, err => $err };

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

SKIP: {
    skip 'SCAN requires Redis 2.8+', 4 if $redis_version < 2 || ($redis_version == 2 && $redis_minor < 8);

    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    my $unique_key = "scan_unique_$$";
    $r->set($unique_key, 'value', sub {
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

{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->del('list_test', sub {
        $r->lpush('list_test', 'c', 'b', 'a', sub {
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

{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    $r->del('set_test', sub {
        $r->sadd('set_test', 'a', 'b', 'c', 'a', sub {
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

# the undef first argument of an error callback is writable
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my ($from_reply, $from_skip);
    local $SIG{__WARN__} = sub {};
    $r->command('ev_redis_nosuchcommand', sub { $_[0] //= 'set'; $from_reply = $_[0]; EV::break });
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    $r->get('cmd_rw', sub { $_[0] //= 'set'; $from_skip = $_[0] });
    $r->skip_pending;
    is $from_reply, 'set', 'error reply: $_[0] is writable';
    is $from_skip, 'set', 'skipped command: $_[0] is writable';
    $r->disconnect;
}

# arguments go out as bytes
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my $s = "caf\xe9";
    utf8::upgrade($s);
    my $got;
    $r->set('cmd_bytes', $s, sub {});
    $r->strlen('cmd_bytes', sub { $got = $_[0]; EV::break });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is $got, 4, 'an upgraded string is sent as its Latin-1 bytes';
    eval { $r->set('cmd_bytes', "\x{263a}", sub {}) };
    like $@, qr/Wide character/, 'a wide character croaks';
    is $r->pending_count, 0, 'a croaked command leaves nothing pending';
    $r->disconnect;
}

# the callback is the code reference passed, not the caller's variable
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my (@pending, @waiting, $cb);
    for my $k (1 .. 2) {
        $cb = sub { push @pending, "cb$k:" . ($_[0] // $_[1]) };
        $r->echo("v$k", $cb);
    }
    $r->max_pending(1);
    for my $k (3 .. 4) {
        $cb = sub { push @waiting, "cb$k:" . ($_[0] // $_[1]) };
        $r->echo("v$k", $cb);
    }
    $cb = 'reassigned';
    $r->ping(sub { EV::break });
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is_deeply \@pending, ['cb1:v1', 'cb2:v2'], 'reassigning the callback variable leaves sent commands alone';
    is_deeply \@waiting, ['cb3:v3', 'cb4:v4'], '... and waiting ones';
    $r->disconnect;
}

# integer replies beyond 32 bits, as a 32-bit perl sees them too
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my %got;
    $r->set('cmd_big', 0);
    $r->incrby('cmd_big', 5000000000, sub { $got{five} = $_[0] });
    $r->incrby('cmd_big', -10000000000, sub { $got{neg} = $_[0] });
    $r->set('cmd_e15', '1125899906842623');
    $r->incrby('cmd_e15', 1, sub { $got{e15} = $_[0] });
    $r->set('cmd_2p53', '9007199254740991');
    $r->incrby('cmd_2p53', '-18014398509481983', sub { $got{n2p53} = $_[0] });
    $r->set('cmd_huge', '1152921504606846976');
    $r->incrby('cmd_huge', 1, sub { $got{huge} = $_[0]; EV::break });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is "$got{five}", '5000000000', 'an integer reply above 2**32';
    is $got{five} + 1, 5000000001, '... is a number';
    is "$got{neg}", '-5000000000', 'a negative one';
    is "$got{e15}", '1125899906842624', 'one of 16 digits keeps every digit';
    is "$got{n2p53}", '-9007199254740992', 'so does -2**53';
    is "$got{huge}", '1152921504606846977', 'one beyond 2**53 keeps every digit';
    $r->disconnect;
}

done_testing;
