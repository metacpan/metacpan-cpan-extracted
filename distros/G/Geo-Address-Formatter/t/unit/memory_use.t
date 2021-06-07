use strict;
use warnings;
use feature qw(say);
use File::Basename qw(dirname);
use Test::More;

## We used to have memory leak, 100.000 random could consume 300MB RAM
## due to Text::Hogan caching subroutines in template $context.
plan(skip_all => 'Skip long-running memory usage tests');


use lib 'lib';

my $af_path = dirname(__FILE__) . '/../../address-formatting';
my $conf_path = $af_path . '/conf/';

my $CLASS = 'Geo::Address::Formatter';
use_ok($CLASS);

my $GAF = $CLASS->new(conf_path => $conf_path);

my @a_components = qw(
    house_number
    road
    hamlet
    village
    neighbourhood
    postal_city    
    city
    municipality
    county
    postcode
    state
    region
);

foreach my $i (0..100_000) {
    note $i if (++$i % 5_000 == 0);

    my %h_address = ( country_code => 'de' );
    foreach my $k (@a_components) {
        $h_address{$k} = "$k-$i";
    }

    $GAF->format_address(\%h_address);
}

done_testing();

1;