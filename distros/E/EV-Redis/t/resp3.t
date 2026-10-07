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

sub run_with_timeout {
    my ($timeout, $code) = @_;
    # a guard that outlived an early EV::break would break a later test's loop
    my $timer = EV::timer $timeout, 0, sub { EV::break };
    $code->();
    EV::run;
}

my ($redis_version, $redis_minor) = get_redis_version($connect_info{sock});
diag "Redis version: $redis_version.$redis_minor";

{
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

                $r->get('push:test:key', sub {
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

# DESTROY in on_push on a subscribed connection: the next message must not free
# a subscription hiredis still holds
SKIP: {
    skip 'RESP3 client tracking needs Redis 6+', 1 if $redis_version < 6;
    my $r;
    $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $r->on_push(sub { undef $r });
    $r->hello(3, sub {});
    $r->client('tracking', 'on', sub {});
    $r->get('r3_push_k', sub {});
    $r->subscribe('r3_push_ch', sub {});
    my $b = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my $t = EV::timer 0.2, 0, sub {
        $b->set('r3_push_k', 1, sub {});
        $b->publish('r3_push_ch', 'x', sub {});
    };
    my $guard = EV::timer 1, 0, sub { EV::break };
    EV::run;
    ok !defined $r, 'DESTROY in on_push on a subscribed RESP3 connection';
    $b->disconnect;
}

# DESTROY in on_push must still close the connection
SKIP: {
    skip 'RESP3 client tracking needs Redis 6+', 1 if $redis_version < 6;
    my ($r, $id, $gone);
    $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $r->on_push(sub { undef $r });
    $r->hello(3, sub {});
    $r->client('id', sub { $id = $_[0] });
    $r->client('tracking', 'on', 'bcast', sub {});
    my $b = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my $t = EV::timer 0.2, 0, sub { $b->set('r3_free_k', 1, sub {}) };
    my $poll = EV::timer 0.4, 0.2, sub {
        $b->client('list', sub {
            my %ids = map { /\bid=(\d+)/ ? ($1 => 1) : () } split /\n/, $_[0] // '';
            if (defined $id && !$ids{$id}) { $gone = 1; EV::break }
        });
    };
    my $deadline = EV::time + 3;
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run while !$gone && EV::time < $deadline;
    ok $gone, 'DESTROY in on_push closes the connection';
    $b->disconnect;
}

# DESTROY in on_push must not wait for an outstanding blocking command
SKIP: {
    skip 'RESP3 client tracking needs Redis 6+', 3 if $redis_version < 6;
    my ($r, $id, $gone);
    my @calls;
    $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $r->on_push(sub { undef $r });
    $r->hello(3, sub {});
    $r->client('id', sub { $id = $_[0] });
    $r->client('tracking', 'on', 'bcast', sub { EV::break });
    run_with_timeout(3, sub {});

    $r->blpop('r3_free_pending_empty', 0, sub { push @calls, [@_] });
    $r->echo('pending', sub { push @calls, [@_] });
    my $b = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my $t = EV::timer 0.1, 0, sub { $b->set('r3_free_pending_k', 1, sub {}) };
    my $poll = EV::timer 0.2, 0.05, sub {
        $b->client('list', sub {
            my %ids = map { /\bid=(\d+)/ ? ($1 => 1) : () } split /\n/, $_[0] // '';
            if (defined $id && !$ids{$id}) { $gone = 1; EV::break }
        });
    };
    my $deadline = EV::time + 3;
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run while !$gone && EV::time < $deadline;
    ok !defined $r, 'DESTROY in on_push with commands pending';
    is_deeply \@calls, [[undef, 'disconnected'], [undef, 'disconnected']],
        'DESTROY in on_push fails all pending commands once';
    ok $gone, 'DESTROY in on_push closes a connection with a blocking command';
    $b->disconnect;
}

# a nested loop in on_push: the connection reads again once the handler has
# returned, with no new command on it
SKIP: {
    skip 'RESP3 client tracking needs Redis 6+', 2 if $redis_version < 6;
    my $w = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my (@push, $r, $ready);
    $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {}, on_push => sub {
        push @push, $_[0][0];
        if (1 == @push) {
            $w->set('r3_nest_k2', 'v', sub {});
            my $t = EV::timer 0.2, 0, sub { EV::break };
            EV::run;
        }
    });
    $r->hello(3, sub {
        $r->client('tracking', 'on', sub {
            $r->get($_, sub {}) for qw(r3_nest_k1 r3_nest_k2 r3_nest_k3);
            $r->ping(sub { $ready = 1; EV::break });
        });
    });
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    ok $ready, 'client tracking on';
    my $wait_pushes = sub {
        my ($n) = @_;
        my $deadline = EV::time + 3;
        my $g = EV::timer 3, 0, sub { EV::break };
        my $c = EV::prepare sub { EV::break if @push >= $n };
        EV::run while @push < $n && EV::time < $deadline;
    };
    $w->set('r3_nest_k1', 'v', sub {});
    $wait_pushes->(2);
    $w->set('r3_nest_k3', 'v', sub {});
    $wait_pushes->(3);
    is scalar(@push), 3, 'pushes arriving during and after a nested loop in on_push are delivered';
    $r->on_push(undef);
    $r->disconnect;
    $w->disconnect;
}

done_testing;
