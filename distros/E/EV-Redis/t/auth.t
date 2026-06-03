use strict;
use warnings;

use Test::More;
use Test::RedisServer;
use Test::TCP qw(empty_port);

use EV;
use EV::Redis;

# A password-protected server exercises the AUTH error/success paths, which
# are otherwise completely untested.
my $port = empty_port;
my $redis_server;
eval {
    $redis_server = Test::RedisServer->new(
        conf => { port => $port, requirepass => 'sekret' },
    );
} or plan skip_all => 'redis-server is required for this test';

plan tests => 5;

# 1. A command issued before AUTH is rejected with NOAUTH, delivered to the
#    command callback as an error (not via on_error).
{
    my $r = EV::Redis->new;
    $r->on_error(sub { });
    my ($res, $err);
    $r->connect('127.0.0.1', $port);
    $r->command('get', 'somekey', sub {
        ($res, $err) = @_;
        $r->disconnect;
        EV::break;
    });
    EV::run;
    ok !defined $res, 'no result before auth';
    like $err, qr/NOAUTH|authentication/i,
        'command before auth returns NOAUTH error';
}

# 2. AUTH with the correct password succeeds and unlocks subsequent commands.
{
    my $r = EV::Redis->new;
    $r->on_error(sub { });
    my ($auth_err, $set_err);
    $r->connect('127.0.0.1', $port);
    $r->command('auth', 'sekret', sub {
        (undef, $auth_err) = @_;
        $r->command('set', 'somekey', 'v', sub {
            (undef, $set_err) = @_;
            $r->disconnect;
            EV::break;
        });
    });
    EV::run;
    ok !$auth_err, 'auth with correct password: no error';
    ok !$set_err,  'command after successful auth succeeds';
}

# 3. AUTH with a wrong password is rejected.
{
    my $r = EV::Redis->new;
    $r->on_error(sub { });
    my $err;
    $r->connect('127.0.0.1', $port);
    $r->command('auth', 'wrongpass', sub {
        (undef, $err) = @_;
        $r->disconnect;
        EV::break;
    });
    EV::run;
    like $err, qr/WRONGPASS|invalid|ERR/i,
        'auth with wrong password returns error';
}
