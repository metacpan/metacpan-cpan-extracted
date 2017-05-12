#!/usr/bin/perl

use JCM::Net::Patricia;
use Storable qw(thaw nfreeze);
use Test::More;

my @tests;
my $pt;

#
# IPv6 testing of climb
#

# Do we have IPv6?
SKIP: {
    skip "No IPv6", 2 if !JCM::Net::Patricia::have_ipv6();
    diag "We have IPv6";

    $pt = new JCM::Net::Patricia AF_INET6;
    $pt->add_string( '::/0',                                        'zero' );
    $pt->add_string( '2000::/3',                                    'one' );
    $pt->add_string( '2000:2000:2000:2000:3000:3000:3000:3000/128', 'two' );
    $pt->add_string( 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128', 'three' );

    @tests = (
        [ '::',                                      '::/0' ],
        [ '2001:1234::',                             '2000::/3' ],
        [ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe', '::/0' ],
        [ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128' ],
    );

    foreach my $test (@tests) {
        my $result = $pt->matching_prefix_string($test->[0]);
        is( $result, $test->[1], $test->[0] . ' lookup' );
    }

}

#
# IPv4 testing of climb
#

$pt = new JCM::Net::Patricia;

$pt->add_string( '127.0.0.0/8',        'zero' );
$pt->add_string( '127.0.0.0/32',       'one' );
$pt->add_string( '0.0.0.0/0',          'two' );
$pt->add_string( '8.8.8.8/32',         'three' );
$pt->add_string( '8.8.0.0/16',         'four' );
$pt->add_string( '8.8.8.0/24',         'five' );
$pt->add_string( '8.8.8.9/32',         'six' );
$pt->add_string( '8.8.9.0/24',         'seven' );
$pt->add_string( '255.255.255.255/32', 'eight' );

@tests = (
    [ '127.0.0.1', '127.0.0.0/8' ],
    [ '8.8.8.8',   '8.8.8.8/32'  ],
    [ '15.1.2.3',  '0.0.0.0/0'   ],
);

foreach my $test (@tests) {
    my $result = $pt->matching_prefix_string($test->[0]);
    is( $result, $test->[1], $test->[0] . ' lookup' );
}

# Validate null matches
$pt = new JCM::Net::Patricia;
my $result = $pt->matching_prefix_string('192.0.2.1');
is( $result, undef, 'Null match returns undef (1)' );
$result = $pt->match_string('192.0.2.1');
is( $result, undef, 'Null match returns undef (2)' );

done_testing;

