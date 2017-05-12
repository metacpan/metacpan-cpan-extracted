use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep '!blessed';

use HTTP::CookieJar;

my @cases = (
    {
        cookie => "",
        parse  => undef,
    },
    {
        cookie => "SID=",
        parse  => {
            name  => "SID",
            value => "",
        }
    },
    {
        cookie => "=31d4d96e407aad42",
        parse  => undef,
    },
    {
        cookie => "; Max-Age: 1360343635",
        parse  => undef,
    },
    {
        cookie => "SID=31d4d96e407aad42",
        parse  => {
            name  => "SID",
            value => "31d4d96e407aad42",
        }
    },
    {
        cookie => "SID=ID=31d4d96e407aad42",
        parse  => {
            name  => "SID",
            value => "ID=31d4d96e407aad42",
        }
    },
    {
        cookie => "SID=31d4d96e407aad42 ; ; ; ",
        parse  => {
            name  => "SID",
            value => "31d4d96e407aad42",
        }
    },
    {
        cookie => "SID=31d4d96e407aad42; Path=/; Secure; HttpOnly",
        parse  => {
            name     => "SID",
            value    => "31d4d96e407aad42",
            path     => "/",
            secure   => 1,
            httponly => 1,
        }
    },
    {
        cookie => "SID=31d4d96e407aad42; Domain=.example.com",
        parse  => {
            name   => "SID",
            value  => "31d4d96e407aad42",
            domain => "example.com",
        }
    },
    {
        cookie => "SID=31d4d96e407aad42; Path=/; Domain=example.com",
        parse  => {
            name   => "SID",
            value  => "31d4d96e407aad42",
            path   => "/",
            domain => "example.com",
        }
    },
    {
        cookie => "SID=31d4d96e407aad42; Path=/; Domain=",
        parse  => {
            name  => "SID",
            value => "31d4d96e407aad42",
            path  => "/",
        }
    },
    {
        cookie => "lang=en-US; Expires = Wed, 09 Jun 2021 10:18:14 GMT",
        parse  => {
            name    => "lang",
            value   => "en-US",
            expires => 1623233894,
        }
    },
    {
        cookie => "lang=en-US; Expires = Wed, 09 Jun 2021 10:18:14 GMT; Max-Age=3600",
        parse  => {
            name      => "lang",
            value     => "en-US",
            expires   => 1623233894,
            'max-age' => 3600,
        }
    },
);

for my $c (@cases) {
    my $got = HTTP::CookieJar::_parse_cookie( $c->{cookie} );
    cmp_deeply $got, $c->{parse}, $c->{cookie} || q{''};
}

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
