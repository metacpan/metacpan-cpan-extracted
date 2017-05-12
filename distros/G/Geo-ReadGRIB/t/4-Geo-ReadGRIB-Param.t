# Test to see if a Geo::ReadGRIB object can return the 
# expected parameter data.
# 
# For this to work there needs to be a specific sample GRIB file
# and the module has to be able to find wgrib.exe 


use Test::More tests => 3;

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

$p = $w->getParam("show");

ok($p =~ /La1/)
   or diag("getParam(\"show\") return value should include La1");

$p = $w->getParam("La1");

ok($p == 75.25)
   or diag("getParam(\"La1\") Must return 75.25");
