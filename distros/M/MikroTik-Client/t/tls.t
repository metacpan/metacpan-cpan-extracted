#!/usr/bin/env perl

use warnings;
use strict;

use FindBin;
use lib './';
use lib "$FindBin::Bin/lib";

use Test::More;

use AE;
use Errno qw(EPROTO);
use MikroTik::Client;
use MikroTik::Client::Mockup;
use Time::HiRes;


plan skip_all => 'TLS with PKI tests. Set MIKROTIK_CLIENT_PKI to run.'
    unless $ENV{MIKROTIK_CLIENT_PKI};

my $mockup = MikroTik::Client::Mockup->new();
$mockup->tls_opts({
    ca_file                    => "./t/certs/ca.crt",
    cert_file                  => "./t/certs/server.crt",
    key_file                   => "./t/certs/server.key",
    verify                     => 1,
    verify_require_client_cert => 1
});
$mockup->server;
my $port = $mockup->port;

my %client_opts = (
    user     => "test",
    password => "tset",
    host     => "127.0.0.1",
    port     => $port,

);
my $api = MikroTik::Client->new(%client_opts, tls => 0);

# Non-TLS connection to TLS server
$api->cmd("/resp");
ok $api->error eq "closed prematurely", "server requires TSL";
$api->tls(1);

# TLS without certs
$api->cmd("/resp");
ok $! == EPROTO, "can't negotiate TLS";
ok $api->error, "has error";

# TLS certs without CA
$api->cert("./t/certs/client.crt");
$api->key("./t/certs/client.key");
$api->cmd("/resp");
ok $! == EPROTO, "can't negotiate TLS";
ok $api->error, "has error";

# Insecure TLS
$api->insecure(1);
my $res = $api->cmd("/resp");
is_deeply $res, _gen_result(), 'right result';
ok !$api->error, 'no error';

# TLS certs with CA
$api = MikroTik::Client->new(
    %client_opts,
    tls  => 1,
    ca   => "./t/certs/ca.crt",
    cert => "./t/certs/client.crt",
    key  => "./t/certs/client.key"
);
$res = $api->cmd("/resp");
is_deeply $res, _gen_result(), 'right result';
ok !$api->error, 'no error';

# TLS certs bundle
$api = MikroTik::Client->new(
    %client_opts,
    tls  => 1,
    ca   => "./t/certs/ca.crt",
    cert => "./t/certs/client-bundle.crt",
);
$res = $api->cmd("/resp");
is_deeply $res, _gen_result(), 'right result';
ok !$api->error, 'no error';

done_testing();

sub _gen_result {
    my $attr = MikroTik::Client::Mockup::_gen_attr(@_);
    return [$attr, $attr];
}
