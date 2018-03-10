#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Locale::Country::OFAC qw( is_division_sanctioned );
use Readonly;

Readonly my $NON_SANCTIONED_STATUS => 0;
Readonly my $SANCTIONED_STATUS     => 1;

subtest 'Missing division' => sub {
    throws_ok {
        is_division_sanctioned( 'US', '' );
    } qr/is_division_sanctioned requires division/, 'Throws on missing division';
};

subtest 'Missing country' => sub {
    throws_ok {
        is_division_sanctioned( '', 'TX' );
    } qr/is_division_sanctioned requires country/, 'Throws on missing country';
};

subtest 'Country With No Sanctions' => sub {
    cmp_ok( is_division_sanctioned('DE', 'BE'), '==', $NON_SANCTIONED_STATUS,
        'Germany region correctly not sanctioned' );
};

subtest 'Entire country is sanctioned' => sub {
    cmp_ok( is_division_sanctioned('IR', '32'), '==', $SANCTIONED_STATUS,
        'All regions report as sanctioned' );
};

subtest 'Non Sanctioned Division' => sub {
    for my $country_code (qw( UA UKR RU RUS )) {
        cmp_ok( is_division_sanctioned( $country_code , '71'), '==', $NON_SANCTIONED_STATUS,
            "$country_code 71 division correctly not sanctioned" );
    }
};

subtest 'Sanctioned Division' => sub {
    for my $country_code (qw( UA UKR RU RUS )) {
        cmp_ok( is_division_sanctioned( $country_code, '43'), '==', $SANCTIONED_STATUS,
            "$country_code 43 division correctly sanctioned");
    }
};

done_testing;
