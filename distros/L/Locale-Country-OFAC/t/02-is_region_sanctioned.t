#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Locale::Country::OFAC qw( is_region_sanctioned );
use Readonly;

Readonly my $NON_SANCTIONED_STATUS => 0;
Readonly my $SANCTIONED_STATUS     => 1;

subtest 'Missing Zip Code' => sub {
    throws_ok {
        is_region_sanctioned( 'DE', '')
    } qr/is_region_sanctioned requires zip code/, 'Throws on missing zip code';
};

subtest 'Missing Country Code' => sub {
    throws_ok {
        is_region_sanctioned('', 123456)
    } qr/is_region_sanctioned requires country code/, 'Throws on missing country code';
};

subtest 'Country With No Sanctions' => sub {
    cmp_ok( is_region_sanctioned('DE', 12345), '==', $NON_SANCTIONED_STATUS,
        'Germany zip correctly not sanctioned' );
};

subtest 'Entire Country is Sanctioned' => sub {
    cmp_ok( is_region_sanctioned('IR', 12345), '==', $SANCTIONED_STATUS,
        'All regions report as sanctioned' );
};

subtest 'Country Has Region Specific Sanctions' => sub {
    subtest 'Unsanctioned Region' => sub {
        for my $country_code (qw( RU RUS UA UKR )) {
            subtest $country_code => sub {
                for my $test_case (
                    { zip_code => 94999,  name => 'Zip just below range not sanctioned '},
                    { zip_code => 100000, name => 'Zip just above range not sanctioned' },
                    { zip_code => 294999, name => 'Zip just below range not sanctioned '},
                    { zip_code => 300000, name => 'Zip just above range not sanctioned' },
                ) {

                    my $is_sanctioned;
                    lives_ok {
                        $is_sanctioned = is_region_sanctioned( $country_code, $test_case->{zip_code} );
                    } 'Lives through determination of sanction';

                    cmp_ok( $is_sanctioned, '==', $NON_SANCTIONED_STATUS, $country_code . ' - ' . $test_case->{name} );
                }
            };
        }
    };

    subtest 'Sanctioned Region' => sub {
        for my $country_code (qw( RU RUS UA UKR )) {
            subtest $country_code => sub {
                for my $zip_code (qw( 95001 99999 295001 299999 )) {
                    my $is_sanctioned;
                    lives_ok {
                        $is_sanctioned = is_region_sanctioned( $country_code, $zip_code );
                    } 'Lives through determination of sanction';

                    cmp_ok( $is_sanctioned, '==', $SANCTIONED_STATUS, "$country_code - $zip_code sanctioned" );
                }
            };
        }
    };
};

done_testing;
