use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep '!blessed';
use Test::Requires 'Mozilla::PublicSuffix';

use HTTP::CookieJar;

my @cases = (
    {
        label   => "host is public suffix",
        request => "http://com.au/",
        cookies => ["SID=31d4d96e407aad42; Domain=com.au"],
        store   => {
            'com.au' => {
                '/' => {
                    SID => {
                        name             => "SID",
                        value            => "31d4d96e407aad42",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "com.au",
                        hostonly         => 1,
                        path             => "/",
                    }
                }
            },
        },
    },
    {
        label   => "host is suffix of public suffix",
        request => "http://au/",
        cookies => ["SID=31d4d96e407aad42; Domain=au"],
        store   => {
            'au' => {
                '/' => {
                    SID => {
                        name             => "SID",
                        value            => "31d4d96e407aad42",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "au",
                        hostonly         => 1,
                        path             => "/",
                    }
                }
            },
        },
    },
    {
        label   => "host is unrecognized single level",
        request => "http://localhost/",
        cookies => ["SID=31d4d96e407aad42; Domain=localhost"],
        store   => {
            'localhost' => {
                '/' => {
                    SID => {
                        name             => "SID",
                        value            => "31d4d96e407aad42",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "localhost",
                        hostonly         => 1,
                        path             => "/",
                    }
                }
            },
        },
    },
    {
        label   => "cookie is public suffix",
        request => "http://example.com.au/",
        cookies => ["SID=31d4d96e407aad42; Domain=com.au"],
        store   => {},
    },
    {
        label   => "cookie is suffix of public suffix",
        request => "http://example.com.au/",
        cookies => ["SID=31d4d96e407aad42; Domain=au"],
        store   => {},
    },
);

for my $c (@cases) {
    my $jar = HTTP::CookieJar->new;
    for my $cookie ( @{ $c->{cookies} } ) {
        $jar->add( $c->{request}, $cookie );
    }
    cmp_deeply $jar->{store}, $c->{store}, $c->{label} or diag explain $jar->{store};
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
