use Test::More tests => 12;
use blib;
use strict;

BEGIN { use_ok('Geo::GNIS') };

open GNIS, "<t/gnis-sample.txt"
    or die "Can't open t/gnis-sample.txt: $!\n";

my @data = Geo::GNIS->parse_file(\*GNIS);

is( scalar(@data), 20, "correct number of GNIS entries loaded" );
is( $data[2]->fid, 538, "Entry has correct fid" );
is( $data[2]->state, "AZ", "Entry has correct state" );
is( $data[2]->name, "Ajo", "Entry has correct name" );
is( $data[2]->type, "ppl", "Entry has correct type" );
is( $data[2]->county, "Pima", "Entry has correct county" );
is( $data[2]->cell, "Ajo South", "Entry has correct cell name" );
is( $data[2]->elev, 1760, "Entry has correct elevation" );
is( $data[2]->est_pop, 3705, "Entry has correct population" );
is( $data[2]->lat, 32.3716666666667, "Entry has correct lat" );
is( $data[2]->lon, -112.86, "Entry has correct lon" );
