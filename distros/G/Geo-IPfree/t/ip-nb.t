use strict;
use warnings;

use Test::More tests => 3;

use_ok( 'Geo::IPfree' );

{
    my $ip = '127.0.0.1';
    my $n  = 2130706433;

    is( Geo::IPfree::ip2nb( $ip ), $n, 'ip2nb()' );
    is( Geo::IPfree::nb2ip( $n ), $ip, 'nb2ip()' );
}
