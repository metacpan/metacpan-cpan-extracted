# Test to see if a Geo::ReadGRIB object can be created
# For this to work there needs to be a sample GRIB file
# and the module has to be able to find wgrib.exe 


use Test::More tests => 2;

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


my $o = new Geo::ReadGRIB "$TEST_FILE";
ok(ref $o eq "Geo::ReadGRIB") or
   diag("Test for object creation FAILED: Not an object ref to Geo::ReadGRIB");


