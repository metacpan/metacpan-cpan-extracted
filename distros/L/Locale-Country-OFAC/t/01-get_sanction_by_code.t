#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Locale::Country::OFAC qw( get_sanction_by_code );

use Readonly;
Readonly my $NON_SANCTIONED_STATUS  => 0;
Readonly my $SANCTIONED_STATUS      => 1;
Readonly my $UNSANCTIONED_COUNTRIES => [qw( DE US UA RU )]; # UA and RU are not COUNTRY level sanctioned
Readonly my $SANCTIONED_COUNTRIES   => [qw( IR CU KP SY IRN CUB PRK SYR )];

subtest 'Unsanctioned Countries' => sub {
    for my $country_code (@{ $UNSANCTIONED_COUNTRIES }) {
        cmp_ok( get_sanction_by_code( $country_code ), '==',
            $NON_SANCTIONED_STATUS, "Correctly considered $country_code unsanctioned" );
    }
};

subtest 'Sanctioned Countries' => sub {
    for my $country_code (@{ $SANCTIONED_COUNTRIES }) {
        cmp_ok( get_sanction_by_code( $country_code ), '==',
            $SANCTIONED_STATUS, "Correctly considered $country_code sanctioned" );
    }
};

done_testing;
