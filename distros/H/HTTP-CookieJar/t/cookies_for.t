use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep '!blessed';
use lib 't/lib';
use MockTime;

use HTTP::CookieJar;

my $url   = "http://example.com/foo/bar/";
my @input = (
    [ $url, "SID=2; Path=/" ],
    [ $url, "SID=1; Path=/foo" ],
    [ $url, "SID=0; Path=/foo/bar" ],
);

# MockTime keeps this constant
my $creation_time = time;

my $jar = HTTP::CookieJar->new;
$jar->add(@$_) for @input;

# Move up the clock for access time
MockTime->offset(10);
my $last_access_time = time;

# Check that cookies_for has expected times
for my $c ( $jar->cookies_for($url) ) {
    is( $c->{creation_time},    $creation_time,    "$c->{name}=$c->{value} creation_time" );
    is( $c->{last_access_time}, $last_access_time, "$c->{name}=$c->{value} last_access_time" );
}

# Modify cookies from cookies_for and verify they aren't changed
# from private originals.
for my $c ( $jar->cookies_for($url) ) {
    $c->{creation_time} = 0;
}
for my $c ( $jar->_cookies_for($url) ) {
    is( $c->{creation_time},    $creation_time,    "$c->{name}=$c->{value} creation_time" );
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
