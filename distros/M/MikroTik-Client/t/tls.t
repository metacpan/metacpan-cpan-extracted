#!/usr/bin/env perl

use warnings;
use strict;

use FindBin;
use lib './';
use lib "$FindBin::Bin/lib";

use Test::More;

plan skip_all => 'TLS tests. Set TEST_TLS to run.' unless $ENV{TEST_TLS} || $ENV{TEST_ALL};
plan skip_all => 'IO::Socket::SSL required for TLS support in Mojolicious.'
    unless eval { require Mojo::IOLoop::TLS; Mojo::IOLoop::TLS->TLS; };

# It won't work with an old built-in cert and I can't care less to find out why.
# It's tests only issue
plan skip_all => 'Mojolicious 8.18+ only.'
    unless eval { require Mojolicious; Mojolicious->VERSION('8.18'); 1 };

BEGIN {
    $ENV{MIKROTIK_CLIENT_CONNTIMEOUT} = 0.5;
}

use Errno qw(ECONNRESET);
use MikroTik::Client;
use MikroTik::Client::Mockup;

use constant MOJO_TLS_OPTS => eval { MikroTik::Client->MOJO_TLS_OPTS };

my $loop = Mojo::IOLoop->new();

my %tls_cert_bdl = (cert => "./t/certs/client-bundle.crt");

# my %tls_cert_ca  = (tls_ca   => "./t/certs/ca.crt");
my %tls_cert_clt = (
    ca   => "./t/certs/ca.crt",
    cert => "./t/certs/client.crt",
    key  => "./t/certs/client.key"
);
my %tls_cert_srv = (
    tls_ca   => "./t/certs/ca.crt",
    tls_cert => "./t/certs/server.crt",
    tls_key  => "./t/certs/server.key"
);

my %client_opts
    = (user => "test", password => "tset", host => "127.0.0.1", ioloop => $loop);
my %server_opts = (tls => 1);

# Non-TLS connection to TLS server
{
    my $mockup = _mockup($loop, %server_opts);
    my $port   = $loop->acceptor($mockup->server)->port;
    my $api    = MikroTik::Client->new(%client_opts, port => $port, tls => 0);

    $api->cmd("/resp");
    ok $! = ECONNRESET, "server requires TLS";
}

# Default server side certs
{
    my $mockup = _mockup($loop, %server_opts);
    my $port   = $loop->acceptor($mockup->server)->port;
    my $api    = MikroTik::Client->new(%client_opts, port => $port);

    my $res;

    # insecure
    $res = $api->cmd("/resp");
    is_deeply $res, _gen_result(), 'validation ignored';

    # secure
    $api->_cleanup;
    $api->insecure(0);

    $res = $api->cmd("/resp");
    like $api->error, qr/verify failed/, "validation failed";
};

# No server side validation
{
    my $mockup = _mockup($loop, %server_opts, %tls_cert_srv);
    my $port   = $loop->acceptor($mockup->server)->port;
    my $api    = MikroTik::Client->new(%client_opts, port => $port);

    my $res;

    # insecure
    $res = $api->cmd("/resp");
    is_deeply $res, _gen_result(), 'right result';

    # secure
    $api->_cleanup;
    $api->insecure(0);

    $res = $api->cmd("/resp");
    like $api->error, qr/verify failed/, "validation failed";

    $api->ca($tls_cert_clt{ca});
    $res = $api->cmd("/resp");
    is_deeply $res, _gen_result(), 'validation passed';
};

# /*
#  * use either SSL_VERIFY_NONE or SSL_VERIFY_PEER, the last 3 options are
#  * 'ored' with SSL_VERIFY_PEER if they are desired
#  */
# # define SSL_VERIFY_NONE                 0x00
# # define SSL_VERIFY_PEER                 0x01
# # define SSL_VERIFY_FAIL_IF_NO_PEER_CERT 0x02
# # define SSL_VERIFY_CLIENT_ONCE          0x04
# # define SSL_VERIFY_POST_HANDSHAKE       0x08

# With server side validation
{
    my $mode = 0x01 | 0x02;
    my %tls_opts
        = MOJO_TLS_OPTS
        ? (tls_options => {SSL_verify_mode => $mode})
        : (tls_verify => $mode);
    my $mockup = _mockup($loop, %server_opts, %tls_cert_srv, %tls_opts);
    my $port   = $loop->acceptor($mockup->server)->port;
    my $api    = MikroTik::Client->new(%client_opts, port => $port);

    my $res;

    # insecure
    $res = $api->cmd("/resp");
    like $api->error, qr/closed prematurely/, 'connection closed';

    # secure
    $api = MikroTik::Client->new(%client_opts, %tls_cert_clt, port => $port);
    $api->insecure(0);

    $res = $api->cmd("/resp");
    is_deeply $res, _gen_result(), 'validation passed';

    # cert bundle
    $api->_cleanup;
    $api->cert($tls_cert_bdl{cert});
    $api->key(undef);

    $res = $api->cmd("/resp");
    is_deeply $res, _gen_result(), 'validation passed';
};

done_testing();

sub _gen_result {
    my $attr = MikroTik::Client::Mockup::_gen_attr(@_);
    return [$attr, $attr];
}

sub _mockup { return MikroTik::Client::Mockup->new->ioloop(shift)->srv_opts({@_}) }
