#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
require "LightTCP/Server.pm";

ok(defined \&LightTCP::Server::validate_config, 'validate_config function exists');

my %valid_config = (
    server_addr  => '0.0.0.0:8080',
    server_type  => 'single',
    verbose      => 1,
);
my $err = LightTCP::Server::validate_config(\%valid_config);
is($err, undef, 'valid single server config');

%valid_config = (
    server_addr  => '0.0.0.0:8080',
    server_type  => 'thread',
    max_threads  => 5,
    verbose      => 2,
);
$err = LightTCP::Server::validate_config(\%valid_config);
is($err, undef, 'valid thread server config');

%valid_config = (
    server_addr  => '127.0.0.1:8888',
    server_type  => 'fork',
    verbose      => 0,
);
$err = LightTCP::Server::validate_config(\%valid_config);
is($err, undef, 'valid fork server config');

my %config = (server_type => 'single');
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/server_addr/, 'rejects missing server_addr');

%config = (server_addr => '', server_type => 'single');
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/server_addr/, 'rejects empty server_addr');

%config = (server_addr => 'invalid', server_type => 'single');
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/server_addr.*format/, 'rejects invalid IP:port format');

%config = (server_addr => '0.0.0.0:8080', server_type => 'invalid');
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/server_type/, 'rejects invalid server_type');

%config = (
    server_addr  => '0.0.0.0:8080',
    server_type  => 'thread',
    max_threads  => 0,
);
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/max_threads/, 'rejects zero max_threads in thread mode');

%config = (
    server_addr  => '0.0.0.0:8080',
    server_type  => 'thread',
    max_threads  => -1,
);
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/max_threads/, 'rejects negative max_threads in thread mode');

%config = (server_addr => '0.0.0.0:8080', server_type => 'single', verbose => -1);
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/verbose/, 'rejects verbose < 0');

%config = (server_addr => '0.0.0.0:8080', server_type => 'single', verbose => 5);
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/verbose/, 'rejects verbose > 3');

%config = (server_addr => '0.0.0.0:8080', server_type => 'single', http_postlimit => -1);
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/http_postlimit/, 'rejects negative http_postlimit');

%config = (
    server_addr => '0.0.0.0:8080',
    server_type => 'single',
    server_deny => 1,
    server_etc  => '',
);
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/server_etc.*server_deny/, 'rejects server_deny without server_etc');

%config = (
    server_addr  => '0.0.0.0:8080',
    server_type  => 'single',
    server_auth  => 1,
    server_keys  => 'not_an_array',
);
$err = LightTCP::Server::validate_config(\%config);
like($err, qr/server_keys.*server_auth/, 'rejects server_auth without arrayref server_keys');

%config = (
    server_addr  => '0.0.0.0:8080',
    server_type  => 'single',
    server_auth  => 1,
    server_keys  => ['key1', 'key2'],
);
$err = LightTCP::Server::validate_config(\%config);
is($err, undef, 'accepts server_auth with valid arrayref keys');

for my $type (qw(single fork thread)) {
    if ($type eq 'thread') {
        %config = (server_addr => '0.0.0.0:8080', server_type => $type, max_threads => 10);
    } else {
        %config = (server_addr => '0.0.0.0:8080', server_type => $type);
    }
    $err = LightTCP::Server::validate_config(\%config);
    is($err, undef, "accepts server_type = '$type'");
}

for my $v (0, 1, 2, 3) {
    %config = (server_addr => '0.0.0.0:8080', server_type => 'single', verbose => $v);
    $err = LightTCP::Server::validate_config(\%config);
    is($err, undef, "accepts verbose = $v");
}

done_testing();
