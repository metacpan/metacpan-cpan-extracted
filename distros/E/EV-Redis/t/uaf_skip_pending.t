use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use EV;
use EV::Redis;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

# skip_pending survives DESTROY inside the first skipped callback
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    
    my $cb_count = 0;

    $r->command('set', 'key1', 'val1', sub {
        $cb_count++;
        undef $r;
    });

    $r->command('set', 'key2', 'val2', sub {
        $cb_count++;
    });

    $r->command('set', 'key3', 'val3', sub {
        $cb_count++;
    });

    $r->skip_pending();

    is($cb_count, 3, "All callbacks invoked despite destruction in the first one");
}

# DESTROY inside a reply callback (hiredis deferred free path)
{
    my @results;
    my $r = EV::Redis->new(path => $connect_info{sock});

    $r->command('set', 'uaf_key1', 'val1', sub {
        my ($res, $err) = @_;
        push @results, [$res, $err];
        undef $r;
    });

    $r->command('set', 'uaf_key2', 'val2', sub {
        my ($res, $err) = @_;
        push @results, [$res, $err];
    });

    $r->command('set', 'uaf_key3', 'val3', sub {
        my ($res, $err) = @_;
        push @results, [$res, $err];
    });

    EV::run;

    is(scalar @results, 3, "all 3 callbacks invoked despite DESTROY in first");
    is($results[0][0], 'OK', "first command succeeded");
    ok(!defined $results[1][0], "second command got undef result (destroyed)");
    ok(defined $results[1][1], "second command got error string");
    ok(!defined $results[2][0], "third command got undef result (destroyed)");
    ok(defined $results[2][1], "third command got error string");
}

# __redisAsyncFree fires reply_cb once per channel with the same cbt
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my $subscribed = 0;

    $r->on_error(sub {});
    $r->command('subscribe', 'mc_ch1', 'mc_ch2', 'mc_ch3', sub {
        my ($res, $err) = @_;
        return if $err;
        if ($res->[0] eq 'subscribe') {
            $subscribed++;
            EV::break if $subscribed == 3;
        }
    });

    EV::run;
    is($subscribed, 3, "multi-channel: subscribed to all 3 channels");
    # DESTROY at scope exit, outside any callback
}
pass("Survived multi-channel subscribe FREED path");

# undef inside a subscribe callback: reply_cb then fires per channel with self==NULL
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my $cb_count = 0;

    $r->on_error(sub {});
    $r->command('subscribe', 'mc_ch4', 'mc_ch5', 'mc_ch6', sub {
        my ($res, $err) = @_;
        $cb_count++;
        return if $err;
        if ($res->[0] eq 'subscribe' && $res->[2] == 3) {
            undef $r;
        }
    });

    EV::run;
    ok($cb_count >= 3, "multi-channel self==NULL: callback invoked at least 3 times (got $cb_count)");
}
pass("Survived multi-channel subscribe self==NULL path");

# hiredis calls reply_cb once per channel with reply=NULL on the skipped cbt
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my $skip_cb_count = 0;

    $r->on_error(sub {});
    $r->command('subscribe', 'skip_ch1', 'skip_ch2', 'skip_ch3', sub {
        my ($res, $err) = @_;
        $skip_cb_count++;
        return unless defined $res;
        if ($res->[0] eq 'subscribe' && $res->[2] == 3) {
            $r->skip_pending();
            $r->disconnect;
        }
    });

    EV::run;
    ok($skip_cb_count >= 3, "multi-channel skip_pending: callback invoked at least 3 times (got $skip_cb_count)");
}
pass("Survived multi-channel subscribe skip_pending path");

# on_disconnect drops the last reference inside a synchronous disconnect()
{
    my $disconnected = 0;
    my $r = EV::Redis->new(path => $connect_info{sock});
    $r->on_error(sub {});

    # wait until connected and idle
    $r->command('ping', sub {
        my ($res, $err) = @_;
        is($res, 'PONG', 'disconnect uaf: connected');

        $r->on_disconnect(sub {
            $disconnected = 1;
            undef $r;
        });

        # outside any hiredis callback
        my $w; $w = EV::timer 0.01, 0, sub {
            undef $w;
            $r->disconnect;
        };
    });

    EV::run;
    is($disconnected, 1, 'disconnect uaf: on_disconnect fired');
}
pass("Survived disconnect() UAF with undef in on_disconnect");

# after a nested event loop, skip_pending must not re-invoke the running callback
{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my $cb_calls = 0;
    my @errors;

    $r->command('ping', sub {
        my ($res, $err) = @_;
        $cb_calls++;
        push @errors, $err;
        if ($cb_calls == 1) {
            $r->disconnect;
            $r->connect_unix($connect_info{sock});
            $r->command('ping', sub { EV::break });
            EV::run;
            $r->skip_pending;
            EV::break;
        }
    });

    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is($cb_calls, 1, 'running callback invoked exactly once (current_cb not clobbered by nested loop)');
    is($errors[0], undef, 'first call succeeded with undef error');
}

{
    my $r = EV::Redis->new(path => $connect_info{sock});
    my $calls = 0;
    $r->command('ping', sub {
        return if $calls++;
        $r->disconnect;
        $r->connect_unix($connect_info{sock});
        $r->command('ping', sub { $r->skip_pending; EV::break });
        my $inner = EV::timer 2, 0, sub { EV::break };
        EV::run;
        EV::break;
    });
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is($calls, 1, 'skip_pending inside a nested loop: outer callback invoked once');
    $r->disconnect;
}

# a running subscribe callback's entry must stay registered
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my ($t, $skipped) = (undef, 0);
    $r->command('ping', sub {
        $t = EV::timer 0, 0, sub {
            $r->command('blpop', 'usp_nolist', 1, sub { $r->skip_pending; EV::break });
            $r->disconnect;
            $r->connect_unix($connect_info{sock});
            $r->command('subscribe', 'usp_ch', sub {
                $skipped++ if defined $_[1] && $_[1] eq 'skipped';
                return unless $_[0] && $_[0][0] eq 'subscribe';
                EV::run;
                EV::break;
            });
        };
    });
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    undef $t;
    undef $r;
    is($skipped, 0, 'skip_pending in a nested loop leaves the running subscribe callback alone');
}

done_testing;
