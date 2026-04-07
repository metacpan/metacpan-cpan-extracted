use strict;
use warnings;
use Test::More;
use Test::RedisServer;

use EV;
use EV::Redis;
use lib 't/lib';
use RedisTestHelper qw(get_redis_version);

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

# --- keepalive ---

{
    my $r = EV::Redis->new;
    is $r->keepalive, 0, 'keepalive default is 0';
    $r->keepalive(15);
    is $r->keepalive, 15, 'keepalive setter/getter roundtrip';
    $r->keepalive(0);
    is $r->keepalive, 0, 'keepalive can be disabled';
}

{
    my $r = EV::Redis->new(keepalive => 30);
    is $r->keepalive, 30, 'keepalive via constructor';
}

{
    eval { EV::Redis->new->keepalive(-1) };
    like $@, qr/non-negative/, 'keepalive rejects negative';

    eval { EV::Redis->new->keepalive(2_000_001) };
    like $@, qr/too large/, 'keepalive rejects too large';
}

# keepalive set while connected
{
    my $r = EV::Redis->new(
        path     => $connect_info{sock},
        on_error => sub { },
    );
    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        $r->keepalive(10);
        is $r->keepalive, 10, 'keepalive set while connected';
        $r->disconnect;
    };
    EV::run;
}

# --- prefer_ipv4 / prefer_ipv6 ---

{
    my $r = EV::Redis->new;
    is $r->prefer_ipv4, 0, 'prefer_ipv4 default is 0';
    is $r->prefer_ipv6, 0, 'prefer_ipv6 default is 0';

    $r->prefer_ipv4(1);
    is $r->prefer_ipv4, 1, 'prefer_ipv4 set to 1';
    is $r->prefer_ipv6, 0, 'prefer_ipv6 cleared when ipv4 set';

    $r->prefer_ipv6(1);
    is $r->prefer_ipv6, 1, 'prefer_ipv6 set to 1';
    is $r->prefer_ipv4, 0, 'prefer_ipv4 cleared when ipv6 set';

    $r->prefer_ipv6(0);
    is $r->prefer_ipv6, 0, 'prefer_ipv6 cleared';
    is $r->prefer_ipv4, 0, 'prefer_ipv4 still 0';
}

{
    my $r = EV::Redis->new(prefer_ipv4 => 1);
    is $r->prefer_ipv4, 1, 'prefer_ipv4 via constructor';
    is $r->prefer_ipv6, 0, 'prefer_ipv6 not set';
}

{
    my $r = EV::Redis->new(prefer_ipv6 => 1);
    is $r->prefer_ipv6, 1, 'prefer_ipv6 via constructor';
    is $r->prefer_ipv4, 0, 'prefer_ipv4 not set';
}

# --- source_addr ---

{
    my $r = EV::Redis->new;
    ok !defined $r->source_addr, 'source_addr default is undef';

    $r->source_addr('192.168.1.1');
    is $r->source_addr, '192.168.1.1', 'source_addr setter/getter roundtrip';

    $r->source_addr('10.0.0.1');
    is $r->source_addr, '10.0.0.1', 'source_addr can be changed';

    $r->source_addr(undef);
    ok !defined $r->source_addr, 'source_addr cleared with undef';
}

{
    my $r = EV::Redis->new(source_addr => '127.0.0.1');
    is $r->source_addr, '127.0.0.1', 'source_addr via constructor';
}

# --- tcp_user_timeout ---

{
    my $r = EV::Redis->new;
    is $r->tcp_user_timeout, 0, 'tcp_user_timeout default is 0';

    $r->tcp_user_timeout(5000);
    is $r->tcp_user_timeout, 5000, 'tcp_user_timeout setter/getter roundtrip';

    $r->tcp_user_timeout(0);
    is $r->tcp_user_timeout, 0, 'tcp_user_timeout reset to 0';
}

{
    my $r = EV::Redis->new(tcp_user_timeout => 3000);
    is $r->tcp_user_timeout, 3000, 'tcp_user_timeout via constructor';
}

{
    eval { EV::Redis->new->tcp_user_timeout(-1) };
    like $@, qr/non-negative/, 'tcp_user_timeout rejects negative';

    eval { EV::Redis->new->tcp_user_timeout(3_000_000_000) };
    like $@, qr/too large/, 'tcp_user_timeout rejects too large';
}

# --- cloexec ---

{
    my $r = EV::Redis->new;
    is $r->cloexec, 1, 'cloexec default is 1 (enabled)';

    $r->cloexec(0);
    is $r->cloexec, 0, 'cloexec disabled';

    $r->cloexec(1);
    is $r->cloexec, 1, 'cloexec re-enabled';
}

{
    my $r = EV::Redis->new(cloexec => 0);
    is $r->cloexec, 0, 'cloexec => 0 via constructor';
}

{
    my $r = EV::Redis->new(cloexec => 1);
    is $r->cloexec, 1, 'cloexec => 1 via constructor';
}

# --- reuseaddr ---

{
    my $r = EV::Redis->new;
    is $r->reuseaddr, 0, 'reuseaddr default is 0 (disabled)';

    $r->reuseaddr(1);
    is $r->reuseaddr, 1, 'reuseaddr enabled';

    $r->reuseaddr(0);
    is $r->reuseaddr, 0, 'reuseaddr disabled';
}

{
    my $r = EV::Redis->new(reuseaddr => 1);
    is $r->reuseaddr, 1, 'reuseaddr => 1 via constructor';
}

# --- command_timeout runtime update ---

{
    my $r = EV::Redis->new(
        path     => $connect_info{sock},
        on_error => sub { },
    );
    my $done = 0;
    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        # Change command_timeout while connected - should not croak
        my $ret = $r->command_timeout(5000);
        is $ret, 5000, 'command_timeout set while connected returns new value';
        $r->ping(sub {
            $done = 1;
            $r->disconnect;
        });
    };
    EV::run;
    is $done, 1, 'command after runtime timeout change succeeds';
}

# --- on_push live registration/deregistration ---

SKIP: {
    my ($redis_version) = get_redis_version($connect_info{sock});
    skip 'on_push live test requires Redis 6+', 2 if $redis_version < 6;

    my $r = EV::Redis->new(path => $connect_info{sock});
    my @push_msgs;
    my $hello_ok = 0;

    my $timeout; $timeout = EV::timer 3, 0, sub {
        undef $timeout;
        $r->disconnect;
    };

    # Set on_push AFTER connecting (live registration path)
    my $setup; $setup = EV::timer 0.1, 0, sub {
        undef $setup;

        $r->hello(3, sub {
            my ($res, $err) = @_;
            if ($err) {
                $r->disconnect;
                undef $timeout;
                return;
            }
            $hello_ok = 1;

            # Register push handler WHILE connected
            $r->on_push(sub {
                my ($msg) = @_;
                push @push_msgs, $msg;
            });

            $r->command('CLIENT', 'TRACKING', 'ON', 'BCAST', sub {
                $r->get('push:live:key', sub {
                    my $r2 = EV::Redis->new(path => $connect_info{sock});
                    $r2->set('push:live:key', 'modified', sub {
                        $r2->disconnect;
                        my $wait; $wait = EV::timer 0.2, 0, sub {
                            undef $wait;
                            # Deregister push handler
                            $r->on_push(undef);
                            $r->disconnect;
                            undef $timeout;
                        };
                    });
                });
            });
        });
    };

    EV::run;

    skip 'RESP3 not available', 2 unless $hello_ok;

    ok scalar(@push_msgs) > 0, 'on_push live registration received push messages';
    is $push_msgs[0][0], 'invalidate', 'push message is invalidation';
}

done_testing;
