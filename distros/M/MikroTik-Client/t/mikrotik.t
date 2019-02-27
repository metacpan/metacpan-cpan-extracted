#!/usr/bin/env perl

use warnings;
use strict;

BEGIN {
    $ENV{MIKROTIK_CLIENT_CONNTIMEOUT} = 0.5;
}

use FindBin;
use lib './';
use lib "$FindBin::Bin/lib";

use Test::More;

use AE;
use MikroTik::Client;
use MikroTik::Client::Mockup;
use Time::HiRes;

# Check for monotonic clock support
use constant MONOTONIC =>
    eval { !!Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC()) };

*steady_time
    = MONOTONIC
    ? sub () { Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC()) }
    : \&Time::HiRes::time;

my $mockup = MikroTik::Client::Mockup->new();
$mockup->server;
my $port = $mockup->port;

my $api = MikroTik::Client->new(
        user     => "test",
        password => "tset",
        host     => "127.0.0.1",
        port     => 0,
        tls      => 0,
    );

# check connection
my $res = $api->cmd('/resp');
like $api->error, qr/Connection refused/, 'connection error';
$api->port($port);

# check login
$api->password('');
$res = $api->cmd('/resp');
like $api->error, qr/cannot log/, 'login error';

$api->new_login(1);
$res = $api->cmd('/resp');
like $api->error, qr/cannot log/, 'login error (new style)';
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
is_deeply $res, _gen_result(), 'right result';

$res = $api->cmd('/resp', {'.proplist' => 'prop0,prop2'});
is_deeply $res, _gen_result('prop0,prop2'), 'right result';

$res = $api->cmd('/resp', {'.proplist' => 'prop0,prop2', count => 3});
is_deeply $res, _gen_result('prop0,prop2', 3), 'right result';

$res = $api->cmd('/err');
is $api->error, 'random error', 'right error';
is_deeply $res, [{message => 'random error', category => 0}],
    'right error attributes';

# Non-blocking call
$api->cmd('/resp', {'.proplist' => 'prop0,prop2', count => 1} => sub {
            is_deeply $_[2], _gen_result('prop0,prop2', 1), 'right result';
});

# subscriptions
my ($err, $tag);
$res = undef;
$tag = $api->subscribe('/subs', {key => 'nnn'} => sub {
            $res = $_[2] unless $err = $_[1];
            $api->cancel($tag);
});

my ($err1, $err2);
$api->cmd('/err' => sub { $err1 = $_[1] . '1' });
$api->cmd('/err' => sub { $err2 = $_[1] . '2' });

my $done = AE::cv;
my $stop_g = AE::timer 1.3, 0, $done;
$done->recv;

is_deeply $res, {
        key => 'nnn'
    },
    'right result';
is $err,  'interrupted',   'right error';
is $err1, 'random error1', 'right error';
is $err2, 'random error2', 'right error';

done_testing();

sub _gen_result {
        my $attr = MikroTik::Client::Mockup::_gen_attr(@_);
        return [$attr, $attr];
}
