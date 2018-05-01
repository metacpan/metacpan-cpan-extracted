#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 'lib';

use Locale::Country::EU ':all';

subtest 'list_countries returns an ARRAY of hashes w/ no arguments' => sub {
        my $array = list_eu_countries;
        isa_ok($array, 'ARRAY');
        isa_ok($array->[0], 'HASH');
    };

subtest 'list_countries repects the include_efta argument' => sub {
        my $array = list_eu_countries({ include_efta => 1 });
        my $no_efta_country;

        foreach my $country ( @{$array} )
        {
            if ( $country->{'EFTA-member'} ) {
                $no_efta_country = 1;
                last;
            }
        }

        ok($no_efta_country, 'returned the correct result with include_efta agrument');

        my $array_alt = list_eu_countries();
        my $efta_country;

        foreach my $country ( @{$array_alt} )
        {
            if ( $country->{'EFTA-member'} ) {
                $efta_country = 1;
                last;
            }
        }

        ok(!$efta_country, 'returned the correct result with include_efta agrument');
    };

subtest 'list_countries repects the exclude argument' => sub {
        my $array = list_eu_countries();
        my $r_exclude = $array->[0]->{'ISO-name'};

        throws_ok { list_eu_countries({ exclude => 'fake' }) } qr/Agrument exclude must be an ARRAY/
            , 'throws as expected';

        my $countries = list_eu_countries({ exclude => [ $r_exclude ] });

        isa_ok($countries, 'ARRAY');
        isa_ok($countries->[0], 'HASH');

        my $has_excluded;
        foreach my $country ( @{$countries} )
        {
            my @country_values = values $country;
            if ( grep /$r_exclude/, @country_values ) {
                $has_excluded = 1;
                last;
            }
        }

        ok(!$has_excluded, 'returned the correct result without the excluded country with the exclude agrument');
    };

subtest 'list_countries returns an ARRAY of STRINGS w/ iso_code argument' => sub {

        throws_ok { list_eu_countries({ iso_code => 'fake' }) } qr/Argument iso_code must be one of/
            , 'throws as expected';

        my $iso_code = 'ISO-name';
        my $compare_to = list_eu_countries;
        my $compare_value = $compare_to->[0]->{$iso_code};

        my $array = list_eu_countries({ iso_code => $iso_code });
        isa_ok($array, 'ARRAY');

        my $has_value;
        if ( grep /$compare_value/, @{$array} ) {
            $has_value = 1;
        }

        ok($has_value, 'returned the correct result without the excluded country with the exclude agrument');
    };

done_testing();