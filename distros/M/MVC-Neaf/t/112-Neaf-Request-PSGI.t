#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

my $capture_req;
neaf->route("/psgi" => sub {
    $capture_req = shift;
    return { -content =>
        $capture_req->param( "roundtrip" => '.*', "(empty)" ) };
}, path_info_regex => '.*');

my $reply = neaf->run->({ REQUEST_URI => '/psgi/foo/bar?roundtrip=42' });

is (scalar @$reply, 3, "PSGI return from run()");
like( $MVC::Neaf::Request::PSGI::VERSION, qr/^\d+\.\d+$/, "Autoload ok");

is ($capture_req->client_ip, "127.0.0.1", "localhost detected");

is ($capture_req->scheme, "http", "No https in fake req");
ok (!$capture_req->secure, "No https = no secure");
is ($capture_req->user_agent, undef, "no user agent");

is ($capture_req->method, 'GET', "get is default method");
ok (!$capture_req->is_post, "is_post is false");

is ($capture_req->upload_raw("masha"), undef, "No uploads");

done_testing;
