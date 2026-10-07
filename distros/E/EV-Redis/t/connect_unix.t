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

{
    my $r = EV::Redis->new;
    my $connected = 0;
    my $error = 0;
    my $disconnected = 0;

    $r->on_error(sub { $error++ });
    $r->on_disconnect(sub { $disconnected++ });
    $r->on_connect(sub {
        $connected++;
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

    $r->on_error(undef);
    $r->on_connect(undef);
    $r->on_disconnect(undef);
}

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

    $r->on_error(undef);
}

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

    $r->on_error(undef);
}

# hiredis would cut the path to fit sun_path
{
    my @errors;
    my $r = EV::Redis->new(on_error => sub { push @errors, $_[0] });
    my $long = '/tmp/' . ('x' x 300) . '.sock';
    ok !eval { $r->connect_unix($long); 1 }, 'connect_unix croaks on a path too long for a unix socket';
    like $@, qr/unix socket path too long/, '... saying why';
    ok !eval { EV::Redis->new(path => $long, on_error => sub {}); 1 }, 'so does new()';
    is_deeply \@errors, [], 'nothing reached on_error';

    my $pong;
    $r->connect_unix($connect_info{sock});
    $r->ping(sub { $pong = $_[0]; $r->disconnect; EV::break });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is $pong, 'PONG', 'the object connects afterwards';
}

done_testing;
