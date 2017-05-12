use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep '!blessed';
use lib 't/lib';
use MockTime;

use HTTP::CookieJar;

my @cases = (
    {
        label   => "path length",
        request => "http://example.com/foo/bar/",
        cookies => [
            [ "http://example.com/foo/bar/", "SID=2; Path=/" ],
            [ "http://example.com/foo/bar/", "SID=1; Path=/foo" ],
            [ "http://example.com/foo/bar/", "SID=0; Path=/foo/bar" ],
        ],
    },
    {
        label   => "creation time",
        request => "http://foo.bar.baz.example.com/",
        cookies => [
            [ "http://foo.bar.baz.example.com/", "SID=0; Path=/; Domain=bar.baz.example.com" ],
            [ "http://foo.bar.baz.example.com/", "SID=1; Path=/; Domain=baz.example.com" ],
            [ "http://foo.bar.baz.example.com/", "SID=2; Path=/; Domain=example.com" ],
        ],
    },
);

for my $c (@cases) {
    my $jar    = HTTP::CookieJar->new;
    my $offset = 0;
    for my $cookie ( @{ $c->{cookies} } ) {
        MockTime->offset($offset);
        $jar->add(@$cookie);
        $offset += 10;
    }
    my @cookies = $jar->cookies_for( $c->{request} );
    my @vals = map { $_->{value} } @cookies;
    cmp_deeply \@vals, [ 0 .. $#vals ], $c->{label} or diag explain \@cookies;
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
