use strict;
use warnings;

use Test::More;
use Test::RedisServer;
use Test::TCP;

use EV;
use EV::Redis;

my $port = empty_port;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new( conf => { port => $port, bind => '127.0.0.1' });
} or plan skip_all => 'redis-server is required to this test';


my $r = EV::Redis->new;

my $connected = 0;
my $error = 0;

$r->on_error(sub { $error++ });
$r->on_connect(sub {
    $connected++;

    my $t; $t = EV::timer .1, 0, sub {
        $r->disconnect;
        undef $t;
    };
});

$r->connect('127.0.0.1', $port);

EV::run;

is $connected, 1;
is $error, 0;


{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $r_default = EV::Redis->new(on_error => undef);
    $r_default->connect('127.0.0.1', 59999);
    my $t; $t = EV::timer 0.5, 0, sub { undef $t };
    EV::run;

    like $warnings[0], qr/exception in error handler/,
        'on_error => undef in constructor still gets default die handler';
    unlike $warnings[0], qr/Redis\.pm line/, '... whose message names no line of the module';
}

{
    my $error_count = 0;
    my $r = EV::Redis->new(on_error => sub { $error_count++ });
    $r->on_error();
    $r->connect('127.0.0.1', 59999);
    my $t; $t = EV::timer 0.5, 0, sub { undef $t };
    EV::run;
    is $error_count, 0, 'on_error() without args clears handler';
}


$r = EV::Redis->new(connect_timeout => 1000, command_timeout => 1000);

$connected = 0;
$error = 0;

$r->on_error(sub { $error++ });
$r->on_connect(sub {
    $connected++;

    my $t; $t = EV::timer .1, 0, sub {
        $r->disconnect;
        undef $t;
    };
});

$r->connect('127.0.0.1', $port);

EV::run;

is $connected, 1;
is $error, 0;


$redis_server->stop;

$r = EV::Redis->new;

$connected = 0;
$error = 0;

$r->on_error(sub {
    $error++;
});
$r->on_connect(sub {
    $connected++;

    my $t; $t = EV::timer .1, 0, sub {
        $r->disconnect;
        undef $t;
    };
});

$r->connect('127.0.0.1', $port);

EV::run;

is $connected, 0;
is $error, 1;


$redis_server = Test::RedisServer->new( conf => { port => $port, bind => '127.0.0.1' });

{
    my $error_count = 0;
    my $r = EV::Redis->new(
        on_error => sub { $error_count++ },
    );

    $r->connect('127.0.0.1', $port);

    my $t; $t = EV::timer 0.1, 0, sub {
        $r->disconnect;
        $r->disconnect;
        undef $t;
    };
    EV::run;

    is $error_count, 0, 'double disconnect does not trigger error';
}

{
    my $error_count = 0;
    my $r = EV::Redis->new(
        on_error => sub { $error_count++ },
    );

    $r->disconnect;
    $r->disconnect;

    is $error_count, 0, 'disconnect on never-connected instance does not trigger error';
}

{
    my $disconnect_called = 0;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $r = EV::Redis->new(
        on_error => sub { },
        on_disconnect => sub {
            $disconnect_called = 1;
            die "intentional exception in disconnect handler";
        },
    );

    $r->connect('127.0.0.1', $port);

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        $r->disconnect;
    };

    EV::run;

    is $disconnect_called, 1, 'on_disconnect handler was called despite exception';
    like $warnings[0], qr/exception in disconnect handler/, 'warning was emitted';
}

{
    my $connect_called = 0;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $r = EV::Redis->new(
        on_error => sub { },
        on_connect => sub {
            $connect_called = 1;
            die "intentional exception in connect handler";
        },
    );

    $r->connect('127.0.0.1', $port);

    my $t; $t = EV::timer 0.2, 0, sub {
        undef $t;
        $r->disconnect;
    };

    EV::run;

    is $connect_called, 1, 'on_connect handler was called despite exception';
    like $warnings[0], qr/exception in connect handler/, 'warning was emitted';
}

{
    my $error_called = 0;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $r = EV::Redis->new(
        on_error => sub {
            $error_called = 1;
            die "intentional exception in error handler";
        },
    );

    $r->connect('127.0.0.1', 59999);

    my $t; $t = EV::timer 0.5, 0, sub {
        undef $t;
    };

    EV::run;

    is $error_called, 1, 'on_error handler was called despite exception';
    like $warnings[0], qr/exception in error handler/, 'warning was emitted';
}

{
    my $r = EV::Redis->new;
    $r->on_error(sub { });

    $r->connect('127.0.0.1', $port);

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;

        my $died = 0;
        eval {
            $r->connect('127.0.0.1', $port);
        };
        $died = 1 if $@;

        ok $died, 'connect() when already connected throws exception';
        like $@, qr/already connected/, 'exception message mentions already connected';

        $r->disconnect;
    };

    EV::run;
}

{
    my @results;
    my $disconnect_called = 0;
    my $r = EV::Redis->new(
        on_error => sub { },
        on_disconnect => sub {
            $disconnect_called++;
            $r->skip_pending();
        },
    );

    $r->connect('127.0.0.1', $port);

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        $r->set('key1', 'value1', sub { push @results, ['set1', @_] });
        $r->set('key2', 'value2', sub { push @results, ['set2', @_] });
        $r->disconnect;
    };

    EV::run;

    is $disconnect_called, 1, 'disconnect callback was called';
    ok 1, 'skip_pending during disconnect callback did not crash';
}

{
    my $connect_called = 0;
    my @results;
    my $r = EV::Redis->new(
        on_error => sub { },
        on_connect => sub {
            $connect_called++;
        },
        max_pending => 1,
    );

    $r->connect('127.0.0.1', $port);

    my $queue_timer; $queue_timer = EV::timer 0.1, 0, sub {
        undef $queue_timer;
        $r->set('key1', 'val1', sub { push @results, ['set1', $_[1] ? 'error' : 'ok'] });
        $r->set('key2', 'val2', sub { push @results, ['set2', $_[1] ? 'error' : 'ok'] });
    };

    my $done_timer; $done_timer = EV::timer 1, 0, sub {
        undef $done_timer;
        $r->disconnect;
    };

    EV::run;

    is $connect_called, 1, 'on_connect was called';
    is scalar(@results), 2, 'all queued commands executed (no infinite loop)';
}

{
    my $connect_called = 0;
    my @results;
    my $r;
    $r = EV::Redis->new(
        on_error => sub { },
        on_connect => sub {
            $connect_called++;
            $r->disconnect;
        },
        max_pending => 1,
    );

    $r->connect('127.0.0.1', $port);

    $r->set('dc_connect_1', 'val1', sub { push @results, ['cmd1', $_[1] ? 'error' : 'ok'] });
    $r->set('dc_connect_2', 'val2', sub { push @results, ['cmd2', $_[1] ? 'error' : 'ok'] });
    $r->set('dc_connect_3', 'val3', sub { push @results, ['cmd3', $_[1] ? 'error' : 'ok'] });

    my $timer; $timer = EV::timer 0.5, 0, sub { undef $timer };
    EV::run;

    is $connect_called, 1, 'on_connect was called';
    is scalar(@results), 3, 'all callbacks were invoked';
    # the first command may already have been sent
    my $errors = grep { $_->[1] eq 'error' } @results;
    ok $errors >= 2, 'waiting queue commands got errors (not drained after disconnect)';
    is $r->is_connected, 0, 'not connected after disconnect in on_connect';
}

{
    my @results;
    my $disconnect_called = 0;
    my $r = EV::Redis->new(
        on_error => sub { },
        on_disconnect => sub { $disconnect_called++ },
    );
    $r->connect('127.0.0.1', $port);

    $r->set('dc_reply_1', 'val1', sub {
        my ($res, $err) = @_;
        push @results, ['cmd1', $res, $err];
        $r->disconnect;
    });
    $r->set('dc_reply_2', 'val2', sub {
        my ($res, $err) = @_;
        push @results, ['cmd2', $res, $err];
    });
    $r->set('dc_reply_3', 'val3', sub {
        my ($res, $err) = @_;
        push @results, ['cmd3', $res, $err];
    });

    EV::run;

    is scalar(@results), 3, 'all 3 callbacks invoked after disconnect in callback';
    is $results[0][1], 'OK', 'first command succeeded before deferred disconnect';
    is $disconnect_called, 1, 'disconnect callback fired once';
    is $r->is_connected, 0, 'no longer connected after deferred disconnect';
}

{
    eval {
        EV::Redis->new(
            host => '127.0.0.1',
            path => '/tmp/redis.sock',
            on_error => sub { },
        );
    };
    like $@, qr/Cannot specify both/, 'constructor rejects both host and path';
}

# 192.0.2.1 (TEST-NET-1) is never routed, so most networks silently drop the SYN
SKIP: {
    my $error_msg = '';
    my $error_time;
    my $start_time = EV::time;
    my $timer;

    my $r = EV::Redis->new(
        on_error => sub {
            $error_msg ||= $_[0];
            $error_time //= EV::time;
            undef $timer;
        },
        connect_timeout => 200,
    );

    $r->connect('192.0.2.1', 6379);

    $timer = EV::timer 2, 0, sub { $r->disconnect };
    EV::run;

    skip 'no error from unreachable host (network anomaly)', 2 unless $error_msg;

    my $elapsed = ($error_time || EV::time) - $start_time;
    skip 'immediate error (host reachable or refused)', 2 if $elapsed < 0.05;

    ok $elapsed < 1.0, sprintf 'connect_timeout fired within expected time (%.2fs)', $elapsed;
    like $error_msg, qr/./, "error message received: $error_msg";
}

# disconnect while the connect is still in progress
SKIP: {
    my $closed_port = empty_port;
    my $r = EV::Redis->new(waiting_timeout => 200, max_pending => 1, on_error => sub {});
    $r->connect('127.0.0.1', $closed_port);
    skip 'loopback connect refused synchronously', 4 unless $r->is_connected;
    $r->command('ping', sub {});
    my $cb_err;
    $r->command('get', 'key', sub { $cb_err = $_[1] });

    $r->disconnect;
    is $r->is_connected, 0, 'disconnected';
    is $r->waiting_count, 0, 'waiting_count is 0 immediately after disconnect';
    is $cb_err, 'disconnected', 'waiting command received disconnected error';

    my $w; $w = EV::timer 0.3, 0, sub { undef $w; EV::break };
    EV::run;
    is $cb_err, 'disconnected', 'callback error was not overwritten by waiting timeout';
}

# disconnect on an established connection while a reply is still pending
{
    my $r = EV::Redis->new(
        max_pending => 1,
        on_error    => sub {},
        on_connect  => sub { EV::break },
    );
    $r->connect('127.0.0.1', $port);
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    my ($blpop_done, $blpop_err, $get_err);
    $r->command('blpop', 'connect_t_nokey', 1, sub {
        ($blpop_done, $blpop_err) = (1, $_[1]);
        EV::break;
    });
    $r->command('get', 'key', sub { $get_err = $_[1] });
    is $r->waiting_count, 1, 'get waits behind the pending blpop';

    $r->disconnect;
    is $r->waiting_count, 0, 'pending reply: waiting_count is 0 right after disconnect';
    is $get_err, 'disconnected', 'pending reply: waiting command failed right away';

    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok $blpop_done && !defined $blpop_err, 'pending reply: blpop still finishes normally';
}

done_testing;
