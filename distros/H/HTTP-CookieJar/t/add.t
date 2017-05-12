use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep '!blessed';

use HTTP::CookieJar;

my @cases = (
    {
        label   => "no cookies",
        request => "http://example.com/",
        cookies => [],
        store   => {},
    },
    {
        label   => "simple key=value",
        request => "http://example.com/",
        cookies => ["SID=31d4d96e407aad42"],
        store   => {
            'example.com' => {
                '/' => {
                    SID => {
                        name             => "SID",
                        value            => "31d4d96e407aad42",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "example.com",
                        hostonly         => 1,
                        path             => "/",
                    }
                }
            },
        },
    },
    {
        label   => "invalid cookie not stored",
        request => "http://example.com/",
        cookies => [";"],
        store   => {},
    },
    {
        label   => "localhost treated as host only",
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
        label   => "single domain level treated as host only",
        request => "http://foobar/",
        cookies => ["SID=31d4d96e407aad42; Domain=foobar"],
        store   => {
            'foobar' => {
                '/' => {
                    SID => {
                        name             => "SID",
                        value            => "31d4d96e407aad42",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "foobar",
                        hostonly         => 1,
                        path             => "/",
                    }
                }
            },
        },
    },
    {
        label   => "different domain not stored",
        request => "http://example.com/",
        cookies => ["SID=31d4d96e407aad42; Domain=example.org"],
        store   => {},
    },
    {
        label   => "subdomain not stored",
        request => "http://example.com/",
        cookies => ["SID=31d4d96e407aad42; Domain=www.example.com"],
        store   => {},
    },
    {
        label   => "superdomain stored",
        request => "http://www.example.com/",
        cookies => ["SID=31d4d96e407aad42; Domain=example.com"],
        store   => {
            'example.com' => {
                '/' => {
                    SID => {
                        name             => "SID",
                        value            => "31d4d96e407aad42",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "example.com",
                        path             => "/",
                    }
                }
            },
        },
    },
    {
        label   => "path prefix /foo/ stored",
        request => "http://www.example.com/foo/bar",
        cookies => ["SID=31d4d96e407aad42; Path=/foo/"],
        store   => {
            'www.example.com' => {
                '/foo/' => {
                    SID => {
                        name             => "SID",
                        value            => "31d4d96e407aad42",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "www.example.com",
                        hostonly         => 1,
                        path             => "/foo/",
                    }
                }
            },
        },
    },
    {
        label   => "path prefix /foo stored",
        request => "http://www.example.com/foo/bar",
        cookies => ["SID=31d4d96e407aad42; Path=/foo"],
        store   => {
            'www.example.com' => {
                '/foo' => {
                    SID => {
                        name             => "SID",
                        value            => "31d4d96e407aad42",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "www.example.com",
                        hostonly         => 1,
                        path             => "/foo",
                    }
                }
            },
        },
    },
    {
        label   => "last cookie wins",
        request => "http://example.com/",
        cookies => [ "SID=31d4d96e407aad42", "SID=0000000000000000", ],
        store   => {
            'example.com' => {
                '/' => {
                    SID => {
                        name             => "SID",
                        value            => "0000000000000000",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "example.com",
                        hostonly         => 1,
                        path             => "/",
                    }
                }
            },
        },
    },
    {
        label   => "expired supercedes prior",
        request => "http://example.com/",
        cookies => [ "SID=31d4d96e407aad42", "SID=0000000000000000; Max-Age=-60", ],
        store   => { 'example.com' => { '/' => {}, }, },
    },
    {
        label   => "separated by path",
        request => "http://example.com/foo/bar",
        cookies => [ "SID=31d4d96e407aad42; Path=/", "SID=0000000000000000", ],
        store   => {
            'example.com' => {
                '/' => {
                    SID => {
                        name             => "SID",
                        value            => "31d4d96e407aad42",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "example.com",
                        hostonly         => 1,
                        path             => "/",
                    }
                },
                '/foo' => {
                    SID => {
                        name             => "SID",
                        value            => "0000000000000000",
                        creation_time    => ignore(),
                        last_access_time => ignore(),
                        domain           => "example.com",
                        hostonly         => 1,
                        path             => "/foo",
                    }
                }
            },
        },
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
