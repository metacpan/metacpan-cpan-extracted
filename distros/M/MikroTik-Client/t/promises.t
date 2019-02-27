#!/usr/bin/env perl

use warnings;
use strict;

BEGIN {
    $ENV{MIKROTIK_CLIENT_CONNTIMEOUT} = 0.5;
}

use FindBin;
use lib './';
use lib "$FindBin::Bin/lib";

use AE;
use MikroTik::Client;
use MikroTik::Client::Mockup;
use Test::More;

plan skip_all => 'Promises v0.99+ required for this test.'
    unless MikroTik::Client->PROMISES;

my $mockup = MikroTik::Client::Mockup->new();
$mockup->server;
my $port   = $mockup->port;

my $api    = MikroTik::Client->new(
    user     => 'test',
    password => 'tset',
    host     => '127.0.0.1',
    port     => 0,
    tls      => 0,
);

my $p = $api->cmd_p('/resp');
isa_ok $p, 'Promises::Promise', 'right result type';

# connection errors
my ($cv, $err, $res);
$cv = AE::cv;
$p->catch(sub { ($err, $res) = @_ })->finally($cv);
$cv->recv;
like $err, qr/Connection refused/, 'connection error';
ok !$res, 'no error attributes';
$api->port($port);

# error
$cv = AE::cv;
$api->cmd_p('/err')->catch(sub { ($err, $res) = @_ })
    ->finally($cv);
$cv->recv;
is $err, 'random error', 'right error';
is_deeply $res, [{message => 'random error', category => 0}],
    'right error attributes';

# request
$cv  = AE::cv;
$api->cmd_p('/resp')->then(sub { $res = $_[0] })
    ->finally($cv);
$cv->recv;
is_deeply $res, _gen_result(), 'right result';

done_testing();

sub _gen_result {
    my $attr = MikroTik::Client::Mockup::_gen_attr(@_);
    return [$attr, $attr];
}
