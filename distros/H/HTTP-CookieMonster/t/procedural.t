#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::CookieMonster qw( cookies );
use HTTP::Cookies ();
use Test::Fatal qw( exception );
use Test::More;

my $jar = HTTP::Cookies->new( file => 't/cookie_jar.txt' );

# 1) my $cookie   = cookies( $jar ); -- first cookie (makes no sense)
# 2) my $session  = cookies( $jar, 'session' );
# 3) my @cookies  = cookies( $jar );
# 4) my @sessions = cookies( $jar, 'session' );

# case 1
ok(
    exception { my $cookies = cookies($jar) },
    'cookie name required in scalar context'
);

# case 2
my $rmid = cookies( $jar, 'nyt-geo' );
isa_ok( $rmid, 'HTTP::CookieMonster::Cookie' );

# case 3
my @all_cookies = cookies($jar);
is( scalar @all_cookies, 4, 'all cookies returns array in list context' );

# case 4
my @sessions = cookies( $jar, 'nyt-geo' );
is( scalar @sessions, 1, 'returns one nyt-geo in array context' );
isa_ok( $sessions[0], 'HTTP::CookieMonster::Cookie' );

# now let's try 2 nyt-geo cookies
my $new_cookie = HTTP::CookieMonster::Cookie->new(
    version   => 0,
    key       => 'nyt-geo',
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

my $monster = HTTP::CookieMonster->new($jar);
$monster->set_cookie($new_cookie);

ok(
    exception { $monster->set_cookie() },
    'cookie required when calling set_cookie()'
);

@sessions = cookies( $jar, 'nyt-geo' );
is( scalar @sessions, 2, 'returns two nyt-geos in array context' );
foreach my $session (@sessions) {
    isa_ok( $sessions[0], 'HTTP::CookieMonster::Cookie' );
}

done_testing();
