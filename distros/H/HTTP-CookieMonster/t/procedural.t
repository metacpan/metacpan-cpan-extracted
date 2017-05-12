#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use Data::Serializer;
use HTTP::CookieMonster qw( cookies );

# 1) my $cookie   = cookies( $jar ); -- first cookie (makes no sense)
# 2) my $session  = cookies( $jar, 'session' );
# 3) my @cookies  = cookies( $jar );
# 4) my @sessions = cookies( $jar, 'session' );

my $serializer = Data::Serializer->new;
my $jar        = $serializer->retrieve( 't/cookie_jar.txt' );

# case 1
dies_ok { my $cookies = cookies( $jar ) }
'cookie name required in scalar context';

# case 2
my $rmid = cookies( $jar, 'RMID' );
isa_ok( $rmid, 'HTTP::CookieMonster::Cookie' );

# case 3
my @all_cookies = cookies( $jar );
is( scalar @all_cookies, 2, "all cookies returns array in list context" );

# case 4
my @sessions = cookies( $jar, 'RMID' );
is( scalar @sessions, 1, "returns one RMID in array context" );
isa_ok( $sessions[0], 'HTTP::CookieMonster::Cookie' );

# now let's try 2 RMID cookies
my $new_cookie = HTTP::CookieMonster::Cookie->new(
    version   => 0,
    key       => 'RMID',
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

my $monster = HTTP::CookieMonster->new( $jar );
$monster->set_cookie( $new_cookie );

@sessions = cookies( $jar, 'RMID' );
is( scalar @sessions, 2, "returns two RMIDs in array context" );
foreach my $session ( @sessions ) {
    isa_ok( $sessions[0], 'HTTP::CookieMonster::Cookie' );
}

done_testing();
