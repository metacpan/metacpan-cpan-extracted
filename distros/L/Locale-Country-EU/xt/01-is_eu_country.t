#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 'lib';
use Locale::Country::EU ':all';

subtest 'is_eu_country throws when no country argument is provided' => sub {
        throws_ok { is_eu_country } qr/Agrument country is required/, 'throws as expected';

    };

subtest 'is_eu_country returns falsey on invalid country argument' => sub {
        my $boolean = is_eu_country({ country => 'United States of Whatever'});
        ok(!$boolean, 'returned falsey value');
    };

subtest 'is_eu_country returns truthy on valid country argument' => sub {
        my $array = list_eu_countries;
        my $country = $array->[0]->{'ISO-name'};
        my $boolean = is_eu_country({ country => $country });

        ok($boolean, 'returned truthy value');
    };

subtest 'is_eu_country repects the include_efta argument' => sub {
        my $array = list_eu_countries({include_efta => 1});
        my $efta_country;

        foreach my $country ( @{$array} )
        {
            if ( $country->{'EFTA-member'} ) {
                $efta_country = $country->{'ISO-name'};
                last;
            }
        }

        diag "using $efta_country for is_country include_efta check";

        my $positive = is_eu_country({ country => $efta_country, include_efta => 1 });

        ok($positive, 'returned the correct result with include_efta agrument');

        my $negative = is_eu_country({ country => $efta_country });

        ok(!$negative, 'returned the correct result without include_efta agrument');
    };

subtest 'is_eu_country repects the exclude argument' => sub {
        my $array = list_eu_countries();
        my $country = $array->[0];
        my $c_name = $country->{'ISO-name'};
        my $c_exclude = $country->{'ISO-alpha2'};
        my $r_exclude = $array->[1]->{'ISO-name'};

        throws_ok { is_eu_country({ country => $c_name, exclude => $c_exclude }) } qr/Agrument exclude must be an ARRAY/, 'throws as expected';

        diag "using $c_name for is_country exclude check";

        my $positive = is_eu_country({ country => $c_name, exclude => [ $r_exclude ] });

        ok($positive, 'returned the correct result with non-matching exclude agrument');

        my $negative = is_eu_country({ country => $c_name, exclude => [ $c_exclude ] });

        ok(!$negative, 'returned the correct result with matching exclude agrument');
    };

done_testing();