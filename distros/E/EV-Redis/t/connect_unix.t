use strict;
use warnings;

use Test::More;
use Test::RedisServer;
use Test::TCP;

use EV;
use EV::Redis;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

# Test: connect via unix socket
{
    my $r = EV::Redis->new;
    my $connected = 0;
    my $error = 0;
    my $disconnected = 0;

    $r->on_error(sub { $error++ });
    $r->on_disconnect(sub { $disconnected++ });
    $r->on_connect(sub {
        $connected++;
        # Schedule disconnect after brief delay
        my $t; $t = EV::timer 0.1, 0, sub {
            undef $t;
            $r->disconnect;
        };
    });

    $r->connect_unix( $connect_info{sock} );
    EV::run;

    is $connected, 1, 'connected via unix socket';
    is $error, 0, 'no errors during unix socket connection';
    is $disconnected, 1, 'disconnect callback was called';

    # Clear handlers before object destruction to break reference cycles
    $r->on_error(undef);
    $r->on_connect(undef);
    $r->on_disconnect(undef);
}

# Test: connect_unix() when already connected throws exception
{
    my $r = EV::Redis->new;
    $r->on_error(sub { });

    $r->connect_unix($connect_info{sock});

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;

        my $died = 0;
        eval {
            $r->connect_unix($connect_info{sock});
        };
        $died = 1 if $@;

        ok $died, 'connect_unix() when already connected throws exception';
        like $@, qr/already connected/, 'exception message mentions already connected';

        $r->disconnect;
    };

    EV::run;

    # Clear handlers before object destruction
    $r->on_error(undef);
}

# Test: connect_unix() then connect() throws exception
{
    my $r = EV::Redis->new;
    $r->on_error(sub { });

    $r->connect_unix($connect_info{sock});

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;

        my $died = 0;
        eval {
            $r->connect('127.0.0.1', 6379);
        };
        $died = 1 if $@;

        ok $died, 'connect() after connect_unix() throws exception';
        like $@, qr/already connected/, 'exception message mentions already connected';

        $r->disconnect;
    };

    EV::run;

    # Clear handlers before object destruction
    $r->on_error(undef);
}

done_testing;
