# Test to see if a Geo::ReadGRIB object can return the 
# expected parameter data.
# 
# For this to work there needs to be a specific sample GRIB file
# and the module has to be able to find wgrib.exe 

BEGIN{ unshift @INC, '.'}


use Test::More tests => 7;



###########################################################################
# Object create test
###########################################################################

use Geo::ReadGRIB;

## Find path to test file
my $TEST_FILE;
foreach my $inc (@INC) {
   if (-e "$inc/Geo/Sample-GRIB/akw.HTSGW.grb") {
      $TEST_FILE = "$inc/Geo/Sample-GRIB/akw.HTSGW.grb";
      last;
   }  
}

ok(-e "$TEST_FILE") or
   diag("Path to sample GRIB file not found");

my $w = Geo::ReadGRIB->new("$TEST_FILE");

$w->getFullCatalog();

ok(  not $w->getError ) or 
    diag( $w->getError );

$tpit = $w->extractLaLo( "HTSGW", 56, 170, 55, 171, 1142218800 );
print $w->getError, "\n" if defined $w->getError;

ok( not $w->getError ) or
    diag( $w->getError );

ok( not defined $tpit->isSorted ) or
    diag( "PlaceIterator data should not be sorted at this point" );

use Data::Dumper; 
$tpit->first;
for ( 1 .. 4 ) {
    $tpit->next;
}

ok( $tpit->current->data('HTSGW') == 2.53) or
    diag( "5th data value should be 2.53" );

ok( $tpit->isSorted ) or
    diag( "PlaceIterator data should be sorted at this point" );

ok ( $tpit->{count_of_places} == 15 ) or
    diag( "count_of_places should be 15" );

