#!/usr/bin/perl

use JCM::Net::Patricia;
use Storable qw(thaw nfreeze);
use Test::More tests => 4;

my @result;
my @expected;
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

    @result = ();
    $pt->climb( sub { push @result, \@_ } );

    @expected = (
        [ 'zero',  '::/0' ],
        [ 'one',   '2000::/3' ],
        [ 'two',   '2000:2000:2000:2000:3000:3000:3000:3000/128' ],
        [ 'three', 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128' ],
    );

    is_deeply( \@result, \@expected, 'IPv6 climb' );
    # use Data::Dumper;
    # print Dumper \@result;

    @result = ();

    $pt->climb_inorder( sub { push @result, \@_ } );

    @expected = (
        [ 'two',   '2000:2000:2000:2000:3000:3000:3000:3000/128' ],
        [ 'one',   '2000::/3' ],
        [ 'zero',  '::/0' ],
        [ 'three', 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128' ],
    );

    is_deeply( \@result, \@expected, 'IPv6 climb in order' );
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

@result = ();
$pt->climb( sub { push @result, \@_ } );

@expected = (
    [ 'two',   '0.0.0.0/0' ],
    [ 'four',  '8.8.0.0/16' ],
    [ 'five',  '8.8.8.0/24' ],
    [ 'three', '8.8.8.8/32' ],
    [ 'six',   '8.8.8.9/32' ],
    [ 'seven', '8.8.9.0/24' ],
    [ 'zero',  '127.0.0.0/8' ],
    [ 'one',   '127.0.0.0/32' ],
    [ 'eight', '255.255.255.255/32' ],
);

is_deeply( \@result, \@expected, 'IPv4 climb' );

@result = ();
$pt->climb_inorder( sub { push @result, \@_ } );

@expected = (
    [ 'three', '8.8.8.8/32' ],
    [ 'six',   '8.8.8.9/32' ],
    [ 'five',  '8.8.8.0/24' ],
    [ 'seven', '8.8.9.0/24' ],
    [ 'four',  '8.8.0.0/16' ],
    [ 'one',   '127.0.0.0/32' ],
    [ 'zero',  '127.0.0.0/8' ],
    [ 'two',   '0.0.0.0/0' ],
    [ 'eight', '255.255.255.255/32' ],
);

is_deeply( \@result, \@expected, 'IPv4 climb' );

done_testing;

