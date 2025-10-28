#!/usr/bin/env perl

use warnings;
use strict;

use FindBin;
use lib './';
use lib "$FindBin::Bin/lib";

use Test::More;

plan skip_all => 'set TEST_AE to enable this test (developer only!)'
    unless $ENV{TEST_AE} || $ENV{TEST_ALL};
plan skip_all => 'AnyEvent 5.0+ required for this test!'
    unless eval { require AnyEvent; AnyEvent->VERSION('5.0'); 1 };

BEGIN {
    $ENV{MIKROTIK_CLIENT_CONNTIMEOUT} = 2;
    $ENV{MOJO_NO_TLS}                 = 1;
    $ENV{MOJO_REACTOR}                = "MikroTik::Client::Reactor::AE";
}

use AnyEvent;
use AnyEvent::Loop;
use Errno qw(ECONNREFUSED);
use MikroTik::Client;
use MikroTik::Client::Mockup;
use MikroTik::Client::Reactor::AE;
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
    tls      => 0,
    ioloop   => $loop,
);

my $guard = AnyEvent::post_detect {
    is $AnyEvent::MODEL, 'AnyEvent::Impl::Perl', 'right AE model';
};

my ($err, $res);

# check connection
$api->port(Mojo::IOLoop::Server::generate_port());
$res = $api->cmd('/resp');
ok $! == ECONNREFUSED, 'connection error';
$api->port($port);

# blocking
$res = $api->cmd('/resp');
isa_ok $res, 'Mojo::Collection', 'right result type';
is_deeply $res, _gen_result(), 'right result';

# non-blocking
my $mockup_nb
    = MikroTik::Client::Mockup->new()->fd($loop->acceptor($mockup->server)->handle->fileno);
$mockup_nb->server;

$api->_cleanup;

$api->cmd(
    '/resp',
    {'.proplist' => 'prop0,prop2', count => 1} => sub {
        is_deeply $_[2], _gen_result('prop0,prop2', 1), 'right result';
    }
);

# subscriptions
my ($tag);
$res = undef;
$tag = $api->subscribe(
    '/subs',
    {key => 'nnn'} => sub {
        $res = $_[2] unless $err = $_[1];
        $api->cancel($tag);
    }
);

# connection queue
my $c = $api->{connections}{Mojo::IOLoop->singleton};
is scalar @{$c->{queue}}, 2, 'correct queue length';

my ($err1, $err2);

$api->cmd('/err' => sub { $err1 = $_[1] . '1' });
$api->cmd('/err' => sub { $err2 = $_[1] . '2' });

my $cv = AE::cv;
my $w  = AE::timer(1.3, 0 => sub { $cv->send });
$cv->recv;

is $c->{queue},                undef, 'no queue';
is scalar %{$api->{requests}}, 0,     'no outstanding requests';

is_deeply $res, {key => 'nnn'}, 'right result';
is $err,  'interrupted',   'right error';
is $err1, 'random error1', 'right error';
is $err2, 'random error2', 'right error';

done_testing();

sub _gen_result {
    my $attr = MikroTik::Client::Mockup::_gen_attr(@_);
    return [$attr, $attr];
}
