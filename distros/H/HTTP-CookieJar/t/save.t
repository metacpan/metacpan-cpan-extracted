use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep '!blessed';

use HTTP::CookieJar;

my $jar = HTTP::CookieJar->new;
my $jar2;

my @cookies = ( 'SID=31d4d96e407aad42; Path=/; Secure; HttpOnly', );

my @persistent =
  ( 'lang=en_US; Path=/; Domain=example.com; Secure; HttpOnly; Max-Age = 3600', );

subtest "empty cookie jar" => sub {
    my $jar  = HTTP::CookieJar->new;
    my @list = $jar->dump_cookies;
    is( scalar @list, 0, "dumped zero cookies" );
    ok( my $jar2 = HTTP::CookieJar->new->load_cookies(@list), "load new cookie jar" );
    is( scalar $jar2->dump_cookies, 0, "second jar is empty" );
};

subtest "roundtrip" => sub {
    my $jar = HTTP::CookieJar->new;
    $jar->add( "http://www.example.com/", $_ ) for @cookies, @persistent;
    my @list = $jar->dump_cookies;
    is( scalar @list, @cookies + @persistent, "dumped correct number of cookies" );
    ok( my $jar2 = HTTP::CookieJar->new->load_cookies(@list), "load new cookie jar" );
    is(
        scalar $jar2->dump_cookies,
        @cookies + @persistent,
        "second jar has correct count"
    );
    cmp_deeply( $jar, $jar2, "old and new jars are the same" )
      or diag explain [ $jar, $jar2 ];
};

subtest "persistent" => sub {
    my $jar = HTTP::CookieJar->new;
    $jar->add( "http://www.example.com/", $_ ) for @cookies, @persistent;
    my @list = $jar->dump_cookies( { persistent => 1 } );
    is( scalar @list, @cookies, "dumped correct number of cookies" );
    ok( my $jar2 = HTTP::CookieJar->new->load_cookies(@list), "load new cookie jar" );
    is( scalar $jar2->dump_cookies, @cookies, "second jar has correct count" );
};

# can load raw cookies with both path and domain
subtest "liberal load" => sub {
    my $jar = HTTP::CookieJar->new;
    ok( $jar->load_cookies( @persistent, @cookies ), "load_cookies with raw cookies" );
    is( scalar $jar->dump_cookies, @persistent, "jar has correct count" );
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
# vim: ts=4 sts=4 sw=4 et:
