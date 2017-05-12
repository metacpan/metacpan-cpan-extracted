# Test to see if a Geo::ReadGRIB object can return the 
# expected parameter data.
# 
# For this to work there needs to be a specific sample GRIB file
# and the module has to be able to find wgrib.exe 

BEGIN{ unshift @INC, '.'}


use Test::More tests => 5;



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

$tpit = $w->extractLaLo( "WIND", 56, 170, 55, 171, 1255046400 );
print $w->getError, "\n" if defined $w->getError;

ok( not $w->getError ) or
    diag( $w->getError );

#use Data::Dumper; 
#print STDERR Dumper $tpit;


$tpit->first;
for ( 1 .. 3 ) {
    $tpit->next;
}

ok( $tpit->current->data('WIND') == 14.37) or
    diag( "4th data value should be 14.37 not ", $tpit->current->data('WIND') );


ok ( $tpit->{count_of_places} == 4 ) or
    diag( "count_of_places should be 4 not $tpit->{count_of_places} " );

