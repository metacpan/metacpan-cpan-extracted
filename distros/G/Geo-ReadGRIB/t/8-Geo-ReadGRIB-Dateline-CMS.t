# Test to see if a Geo::ReadGRIB object can return the 
# expected parameter data.
#
# In this case there are two 180 degree places for each lat,
# one on each edge of the flat grid, and 
# this test makes sure they are the same value
# 
# For this to work there needs to be a specific sample GRIB file
# and the module has to be able to find wgrib.exe 

BEGIN{ unshift @INC, '.'}


use Test::More tests => 305;
use strict;
use warnings;


###########################################################################
# Object create test
###########################################################################

use Geo::ReadGRIB;

## Find path to test file
my $TEST_FILE;
foreach my $inc (@INC) {
   if (-e "$inc/Geo/Sample-GRIB/2009100900_P000.grib") {
      $TEST_FILE = "$inc/Geo/Sample-GRIB/2009100900_P000.grib";
      last;
   }  
}

ok(-e "$TEST_FILE") or
   diag("Path to sample GRIB file not found");

my $w = Geo::ReadGRIB->new("$TEST_FILE");

$w->getFullCatalog();

ok(  not $w->getError ) or 
    diag( $w->getError );

my $plit = $w->extractLaLo( "WIND", 90, -180, -90, -180, 1255046400 );
print $w->getError, "\n" if defined $w->getError;

ok( not $w->getError ) or
    diag( $w->getError );

my $plit2 = $w->extractLaLo( "WIND", 90, 180, -90, 180, 1255046400 );
print $w->getError, "\n" if defined $w->getError;

ok( not $w->getError ) or
    diag( $w->getError );

#use Data::Dumper; 
#print STDERR Dumper $plit;


while ( (my $place = $plit->current and $plit->next ) 
        and ( my $place2 = $plit2->current and $plit2->next ) ) {

    ok( $place->data( 'WIND' ) == $place2->data( 'WIND' ) )
        or diag("Not equal with extractLaLo() for lat ",$place->lat," got: ",$place->data('WIND')," and ",$place2->data('WIND') );
}

