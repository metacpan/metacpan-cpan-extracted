use Test::More tests => 5;
use blib;
use strict;

BEGIN { use_ok('Geo::Fips55') };

open FIPS, "<t/fips-sample.txt"
    or die "Can't open t/sample-fips.txt: $!\n";

my @data = Geo::Fips55->parse_file(\*FIPS);

is( scalar(@data), 10, "correct number of FIPS-55 entries loaded" );
is( $data[2]->name, "Wynnefield", "Entry has correct name" );
is( $data[2]->class, "U6", "Entry has correct class" );
is( $data[2]->county_fips, 101, "Entry has correct FIPS county code" );
