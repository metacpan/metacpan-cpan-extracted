#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Data::Serializer;
use HTTP::CookieMonster;
use Scalar::Util qw( reftype );

my $serializer = Data::Serializer->new;
my $jar        = $serializer->retrieve( 't/cookie_jar.txt' );

my $obj = HTTP::CookieMonster->new( cookie_jar => $jar );
ok( $obj, "can create object with 2 args" );

my $monster = HTTP::CookieMonster->new( $jar );
ok( $monster,              "got a monster" );
ok( $monster->all_cookies, "all cookies" );

is( reftype $monster->all_cookies,
    'ARRAY',
    "all cookies returns arrayref in scalar context"
);

my @all_cookies = $monster->all_cookies;
is( scalar @all_cookies, 2, "all cookies returns array in list context" );

my $all_cookies = $monster->all_cookies;
ok( $monster->get_cookie( 'RMID' ), "got a single cookie" );

my $rmid = $monster->get_cookie( 'RMID' );
$rmid->val( 'random' );
is $monster->set_cookie( $rmid ), 1, "can set cookie";

# try adding a new cookie to the jar

my %args = (
    version   => 0,
    key       => 'foo',
    val       => 'bar',
    path      => '/',
    domain    => '.metacpan.org',
    port      => 80,
    path_spec => 1,
    secure    => 1,
    expires   => 1376081877,
    discard   => undef,
    hash      => {},
);

my $cookie = HTTP::CookieMonster::Cookie->new( %args );

ok( $monster->set_cookie( $cookie ), "can set a cookie" );

my $cookie2
    = HTTP::CookieMonster::Cookie->new( %args, domain => 'foo.metacpan.org' );
ok( $monster->set_cookie( $cookie2 ), "can set a second cookie" );

my $first_cookie = $monster->get_cookie( 'foo' );
isa_ok( $first_cookie, 'HTTP::CookieMonster::Cookie' );

my @all_foo_cookies = $monster->get_cookie( 'foo' );
my $count           = @all_foo_cookies;
is( $count, 2, "there are 2 foo cookies" );

ok( $monster->delete_cookie( $cookie ), 'delete returns true' );

{
    my @all_foo_cookies = $monster->get_cookie( 'foo' );
    my $count           = @all_foo_cookies;
    is( $count, 1, '1 foo cookie deleted' );
}

done_testing();
