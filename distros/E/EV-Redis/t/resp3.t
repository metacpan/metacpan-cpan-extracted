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
use lib 't/lib';
use RedisTestHelper qw(get_redis_version);

# Helper to run a test with timeout
sub run_with_timeout {
    my ($timeout, $code) = @_;
    my $timer; $timer = EV::timer $timeout, 0, sub {
        undef $timer;
        EV::break;
    };
    $code->();
    EV::run;
}

my ($redis_version, $redis_minor) = get_redis_version($connect_info{sock});
diag "Redis version: $redis_version.$redis_minor";

{
    # Test: REDIS_REPLY_DOUBLE via HINCRBYFLOAT
    {
        my $r = EV::Redis->new(path => $connect_info{sock});
        my $result;

        run_with_timeout(2, sub {
            $r->del('test:resp3:double', sub {
                $r->hset('test:resp3:double', 'field', '10.5', sub {
                    $r->hincrbyfloat('test:resp3:double', 'field', '0.1', sub {
                        my ($res, $err) = @_;
                        $result = $res;
                        $r->disconnect;
                        EV::break;
                    });
                });
            });
        });

        ok abs($result - 10.6) < 0.01, 'HINCRBYFLOAT returns float value';
    }

    # Test: REDIS_REPLY_BOOL via SET ... GET with NX (Redis 6.2+)
    SKIP: {
        skip 'SET GET NX requires Redis 6.2+', 2 if $redis_version < 6 || ($redis_version == 6 && $redis_minor < 2);

        my $r = EV::Redis->new(path => $connect_info{sock});
        my @results;

        run_with_timeout(2, sub {
            $r->del('test:resp3:bool', sub {
                $r->set('test:resp3:bool', 'value1', 'NX', sub {
                    my ($res, $err) = @_;
                    push @results, ['first_set', $res, $err];

                    $r->set('test:resp3:bool', 'value2', 'NX', sub {
                        my ($res, $err) = @_;
                        push @results, ['second_set', $res, $err];
                        $r->disconnect;
                        EV::break;
                    });
                });
            });
        });

        is $results[0][1], 'OK', 'SET NX returns OK when key does not exist';
        ok !defined($results[1][1]) || $results[1][1] eq '', 'SET NX returns nil when key exists';
    }

    # Test: RESP3 protocol negotiation via HELLO 3
    SKIP: {
        my $r = EV::Redis->new(path => $connect_info{sock});
        my $hello_result;
        my $hello_error;

        run_with_timeout(2, sub {
            $r->hello(3, sub {
                my ($res, $err) = @_;
                $hello_result = $res;
                $hello_error = $err;
                $r->disconnect;
                EV::break;
            });
        });

        skip 'HELLO 3 not supported', 5 if $hello_error;

        ok ref($hello_result) eq 'ARRAY', 'HELLO 3 returns array (RESP3 map)';
        ok @$hello_result >= 2, 'HELLO response has key-value pairs';

        my %hello_map = @$hello_result;
        ok exists $hello_map{server}, 'HELLO response contains server field';
        ok exists $hello_map{version}, 'HELLO response contains version field';
        is $hello_map{proto}, 3, 'HELLO confirms RESP3 protocol';
    }

    # Test: REDIS_REPLY_MAP via HGETALL with RESP3
    SKIP: {
        my $r = EV::Redis->new(path => $connect_info{sock});
        my $hello_ok = 0;
        my $result;

        run_with_timeout(3, sub {
            $r->hello(3, sub {
                my ($res, $err) = @_;
                $hello_ok = !$err;
                if ($err) {
                    $r->disconnect;
                    EV::break;
                    return;
                }

                $r->del('test:resp3:map', sub {
                    $r->hset('test:resp3:map', 'field1', 'value1', 'field2', 'value2', sub {
                        $r->hgetall('test:resp3:map', sub {
                            my ($res, $err) = @_;
                            $result = $res;
                            $r->disconnect;
                            EV::break;
                        });
                    });
                });
            });
        });

        skip 'RESP3 not available', 2 unless $hello_ok;

        ok ref($result) eq 'ARRAY', 'HGETALL returns array (RESP3 MAP is flattened)';
        my %hash = @$result;
        is_deeply \%hash, { field1 => 'value1', field2 => 'value2' }, 'HGETALL map contents correct';
    }

    # Test: REDIS_REPLY_SET via SMEMBERS with RESP3
    SKIP: {
        my $r = EV::Redis->new(path => $connect_info{sock});
        my $hello_ok = 0;
        my $result;

        run_with_timeout(3, sub {
            $r->hello(3, sub {
                my ($res, $err) = @_;
                $hello_ok = !$err;
                if ($err) {
                    $r->disconnect;
                    EV::break;
                    return;
                }

                $r->del('test:resp3:set', sub {
                    $r->sadd('test:resp3:set', 'member1', 'member2', 'member3', sub {
                        $r->smembers('test:resp3:set', sub {
                            my ($res, $err) = @_;
                            $result = $res;
                            $r->disconnect;
                            EV::break;
                        });
                    });
                });
            });
        });

        skip 'RESP3 not available', 2 unless $hello_ok;

        ok ref($result) eq 'ARRAY', 'SMEMBERS returns array (RESP3 SET)';
        my @sorted = sort @$result;
        is_deeply \@sorted, ['member1', 'member2', 'member3'], 'SMEMBERS set contents correct';
    }

    # Test: REDIS_REPLY_BIGNUM via DEBUG PROTOCOL BIGNUM (if available)
    SKIP: {
        my $r = EV::Redis->new(path => $connect_info{sock});
        my $result;
        my $error;

        run_with_timeout(2, sub {
            $r->debug('protocol', 'bignum', sub {
                my ($res, $err) = @_;
                $result = $res;
                $error = $err;
                $r->disconnect;
                EV::break;
            });
        });

        skip 'DEBUG PROTOCOL BIGNUM not available', 1 if $error;

        ok defined($result), 'DEBUG PROTOCOL BIGNUM returns a value';
    }

    # Test: REDIS_REPLY_VERB via DEBUG PROTOCOL VERBATIM (if available)
    SKIP: {
        my $r = EV::Redis->new(path => $connect_info{sock});
        my $result;
        my $error;

        run_with_timeout(2, sub {
            $r->debug('protocol', 'verbatim', sub {
                my ($res, $err) = @_;
                $result = $res;
                $error = $err;
                $r->disconnect;
                EV::break;
            });
        });

        skip 'DEBUG PROTOCOL VERBATIM not available', 1 if $error;

        ok defined($result), 'DEBUG PROTOCOL VERBATIM returns a value';
    }
}

# Test: Basic RESP2 types work (baseline verification)
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my @results;

    run_with_timeout(2, sub {
        $r->set('test:resp2:string', 'hello', sub {
            my ($res, $err) = @_;
            push @results, ['set', $res, $err];

            $r->get('test:resp2:string', sub {
                my ($res, $err) = @_;
                push @results, ['get', $res, $err];

                $r->incr('test:resp2:int', sub {
                    my ($res, $err) = @_;
                    push @results, ['incr', $res, $err];

                    $r->lpush('test:resp2:list', 'a', 'b', 'c', sub {
                        my ($res, $err) = @_;
                        push @results, ['lpush', $res, $err];

                        $r->lrange('test:resp2:list', 0, -1, sub {
                            my ($res, $err) = @_;
                            push @results, ['lrange', $res, $err];
                            $r->disconnect;
                            EV::break;
                        });
                    });
                });
            });
        });
    });

    is $results[0][1], 'OK', 'RESP2 SET returns status OK';
    is $results[1][1], 'hello', 'RESP2 GET returns string';
    ok $results[2][1] > 0, 'RESP2 INCR returns integer';
    ok $results[3][1] > 0, 'RESP2 LPUSH returns integer';
    ok ref($results[4][1]) eq 'ARRAY', 'RESP2 LRANGE returns array';
}

# Test: RESP3 PUSH callback via client-side caching invalidation
SKIP: {
    skip 'Requires Redis >= 6.0 for RESP3 push', 3 if $redis_version < 6;

    my $r = EV::Redis->new(path => $connect_info{sock});
    my @push_msgs;
    my $hello_ok = 0;

    $r->on_push(sub {
        my ($msg) = @_;
        push @push_msgs, $msg;
    });

    run_with_timeout(3, sub {
        # Switch to RESP3
        $r->hello(3, sub {
            my ($res, $err) = @_;
            if ($err) {
                $r->disconnect;
                EV::break;
                return;
            }
            $hello_ok = 1;

            # Enable client tracking (BCAST mode for simplicity)
            $r->command('CLIENT', 'TRACKING', 'ON', 'BCAST', sub {
                my ($res, $err) = @_;
                if ($err) {
                    $r->disconnect;
                    EV::break;
                    return;
                }

                # Read a key to track it
                $r->get('push:test:key', sub {
                    # Use a second connection to modify the key
                    my $r2 = EV::Redis->new(path => $connect_info{sock});
                    $r2->set('push:test:key', 'modified', sub {
                        $r2->disconnect;
                        # Give time for invalidation to arrive
                        my $t; $t = EV::timer 0.2, 0, sub {
                            undef $t;
                            $r->on_push(undef);
                            $r->disconnect;
                            EV::break;
                        };
                    });
                });
            });
        });
    });

    skip 'RESP3 not available', 3 unless $hello_ok;

    ok scalar(@push_msgs) > 0, 'received PUSH message(s)';
    ok ref($push_msgs[0]) eq 'ARRAY', 'PUSH message is array ref';
    is $push_msgs[0][0], 'invalidate', 'PUSH message type is invalidate';
}

# Test: exception in on_push handler is caught and warned
SKIP: {
    skip 'Requires Redis >= 6.0 for RESP3 push', 2 if $redis_version < 6;

    my $r = EV::Redis->new(path => $connect_info{sock});
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $hello_ok = 0;

    $r->on_push(sub {
        die "intentional exception in push handler";
    });

    run_with_timeout(3, sub {
        $r->hello(3, sub {
            my ($res, $err) = @_;
            if ($err) {
                $r->disconnect;
                EV::break;
                return;
            }
            $hello_ok = 1;

            $r->command('CLIENT', 'TRACKING', 'ON', 'BCAST', sub {
                my ($res, $err) = @_;
                if ($err) {
                    $r->disconnect;
                    EV::break;
                    return;
                }

                $r->get('push:exception:key', sub {
                    my $r2 = EV::Redis->new(path => $connect_info{sock});
                    $r2->set('push:exception:key', 'modified', sub {
                        $r2->disconnect;
                        my $t; $t = EV::timer 0.2, 0, sub {
                            undef $t;
                            $r->on_push(undef);
                            $r->disconnect;
                            EV::break;
                        };
                    });
                });
            });
        });
    });

    skip 'RESP3 not available', 2 unless $hello_ok;

    ok scalar(@warnings) > 0, 'warning emitted for exception in push handler';
    like $warnings[0], qr/exception in push handler/, 'warning message is correct';
}

done_testing;
