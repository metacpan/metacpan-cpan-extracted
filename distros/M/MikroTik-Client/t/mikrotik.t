#!/usr/bin/env perl

use warnings;
use strict;

BEGIN {
    $ENV{MIKROTIK_CLIENT_CONNTIMEOUT} = 0.5;
    $ENV{MOJO_NO_TLS}              = 1;
}

use FindBin;
use lib './';
use lib "$FindBin::Bin/lib";

use Test::More;

use MikroTik::Client;
use MikroTik::Client::Mockup;
use Mojo::IOLoop;
use Mojo::Util qw(steady_time);

# blocking
my $loop   = Mojo::IOLoop->new();
my $mockup = MikroTik::Client::Mockup->new()->ioloop($loop);
my $port   = $loop->acceptor($mockup->server)->port;

my $api = MikroTik::Client->new(
    user     => 'test',
    password => 'tset',
    host     => '127.0.0.1',
    port     => $port,
    tls      => 1,
    ioloop   => $loop,
);

# check connection
$api->tls(1);
my $res = $api->cmd('/resp');
like $api->error, qr/IO::Socket::SSL/, 'connection error';
$api->tls(0);

# check login
$api->password('');
$res = $api->cmd('/resp');
like $api->error, qr/cannot log/, 'login error';
$api->password('tset');

# timeouts
$api->timeout(1);
my $ctime = steady_time();
$res = $api->cmd('/nocmd');
ok((steady_time() - $ctime) < 1.1, 'timeout ok');
$api->timeout(0.5);
$ctime = steady_time();
$res   = $api->cmd('/nocmd');
ok((steady_time() - $ctime) < 0.6, 'timeout ok');
$api->timeout(1);

# close connection prematurely, next command should succeed
$res = $api->cmd('/close/premature');
ok !$res, 'no result';
is $api->error, 'closed prematurely', 'right error';

# also check previous test case on errors
$res = $api->cmd('/resp');
isa_ok $res, 'Mojo::Collection', 'right result type';
is_deeply $res, _gen_result(), 'right result';

$res = $api->cmd('/resp', {'.proplist' => 'prop0,prop2'});
is_deeply $res, _gen_result('prop0,prop2'), 'right result';

$res = $api->cmd('/resp', {'.proplist' => 'prop0,prop2', count => 3});
is_deeply $res, _gen_result('prop0,prop2', 3), 'right result';

$res = $api->cmd('/err');
is $api->error, 'random error', 'right error';
is_deeply $res, [{message => 'random error', category => 0}],
    'right error attributes';

# non-blocking
my $mockup_nb = MikroTik::Client::Mockup->new()
    ->fd($loop->acceptor($mockup->server)->handle->fileno);
$mockup_nb->server;

$api->cmd(
    '/resp',
    {'.proplist' => 'prop0,prop2', count => 1} => sub {
        is_deeply $_[2], _gen_result('prop0,prop2', 1), 'right result';
    }
);

# subscriptions
my ($err, $tag);
$res = undef;
$tag = $api->subscribe(
    '/subs',
    {key => 'nnn'} => sub {
        $res = $_[2] unless $err = $_[1];
        $api->cancel($tag);
    }
);

my ($err1, $err2);
$api->cmd('/err' => sub { $err1 = $_[1] . '1' });
$api->cmd('/err' => sub { $err2 = $_[1] . '2' });

Mojo::IOLoop->timer(1.3 => sub { Mojo::IOLoop->stop() });
Mojo::IOLoop->start();

is_deeply $res, {key => 'nnn'}, 'right result';
is $err,  'interrupted',   'right error';
is $err1, 'random error1', 'right error';
is $err2, 'random error2', 'right error';

done_testing();

sub _gen_result {
    my $attr = MikroTik::Client::Mockup::_gen_attr(@_);
    return [$attr, $attr];
}

