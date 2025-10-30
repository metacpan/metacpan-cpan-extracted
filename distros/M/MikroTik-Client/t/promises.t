#!/usr/bin/env perl

use warnings;
use strict;

BEGIN {
    $ENV{MIKROTIK_CLIENT_CONNTIMEOUT} = 0.5;
    $ENV{MOJO_NO_TLS}                 = 1;
}

use FindBin;
use lib './';
use lib "$FindBin::Bin/lib";

use Errno qw(ECONNREFUSED);
use MikroTik::Client;
use MikroTik::Client::Mockup;
use Mojo::IOLoop;
use Test::More;

my $mockup = MikroTik::Client::Mockup->new();
my $port   = Mojo::IOLoop->acceptor($mockup->server)->port;
my $api    = MikroTik::Client->new(
    user     => 'test',
    password => 'tset',
    host     => '127.0.0.1',
    port     => $port,
    tls      => 0,
);

my ($err, $p, $res);

# connection errors
$api->port(Mojo::IOLoop::Server::generate_port());
$p
    = $api->cmd_p('/resp')
    ->catch(sub { ($err, $res) = @_ })
    ->finally(sub { Mojo::IOLoop->stop() });
Mojo::IOLoop->start();
ok $!, 'connection error';
diag("Connection error (\$!) is " . int($!));
ok !$res, 'no error attributes';
$api->port($port);

# result type
isa_ok $p, 'Mojo::Promise', 'right result type';

# error
$api->cmd_p('/err')
    ->catch(sub { ($err, $res) = @_ })
    ->finally(sub { Mojo::IOLoop->stop() });
Mojo::IOLoop->start();
is $err, 'random error', 'right error';
is_deeply $res, [{message => 'random error', category => 0}], 'right error attributes';

# request
$api->cmd_p('/resp')->then(sub { $res = $_[0] })->finally(sub { Mojo::IOLoop->stop() });
Mojo::IOLoop->start();
is_deeply $res, _gen_result(), 'right result';

done_testing();

sub _gen_result {
    my $attr = MikroTik::Client::Mockup::_gen_attr(@_);
    return [$attr, $attr];
}

