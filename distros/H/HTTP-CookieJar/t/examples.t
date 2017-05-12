use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use HTTP::CookieJar;

my $req  = "http://www.example.com/foo/bar";
my $sreq = "https://www.example.com/foo/bar";

my $jar = new_ok("HTTP::CookieJar");

subtest "just key & value" => sub {
    $jar->clear;
    $jar->add( $req, "SID=31d4d96e407aad42" );
    is( $jar->cookie_header($req), "SID=31d4d96e407aad42" );
};

subtest "secure" => sub {
    $jar->clear;
    $jar->add( $req, "SID=31d4d96e407aad42; Secure" );
    $jar->add( $req, "lang=en-US; Path=/; Domain=example.com" );
    is( $jar->cookie_header($sreq), "SID=31d4d96e407aad42; lang=en-US" );
    is( $jar->cookie_header($req),  "lang=en-US" );
};

subtest "not a subdomain" => sub {
    $jar->clear;
    $jar->add( $req, "SID=31d4d96e407aad42" );
    is( $jar->cookie_header("http://wwww.example.com/foo/baz"), "" );
};

subtest "wrong path" => sub {
    $jar->clear;
    $jar->add( $req, "SID=31d4d96e407aad42" );
    is( $jar->cookie_header("http://www.example.com/"), "" );
};

subtest "expiration" => sub {
    $jar->clear;
    $jar->add( $req, "lang=en-US; Expires=Wed, 09 Jun 2021 10:18:14 GMT" );
    is( $jar->cookie_header($req), "lang=en-US" );
    $jar->add( $req, "lang=; Expires=Sun, 06 Nov 1994 08:49:37 GMT" );
    is( $jar->cookie_header($req), "" );
};

done_testing;
#
# This file is part of HTTP-CookieJar
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
