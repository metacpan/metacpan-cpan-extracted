#
#===============================================================================
#
#         FILE:  10-Geo-ReadGRIB-LaLoRange.t
#
#  DESCRIPTION:  test lo and la range methods
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Frank Lyon Cox (Dr), <frank@pwizardry.com>
#      COMPANY:  Practial Wizardry
#      VERSION:  1.0
#      CREATED:  11/18/2009 4:45:49 PM Pacific Standard Time
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 13;                      # last test to print

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

# try out of range values
my ($type, $lat, $long, $time) = ("HTSGW", 76, 160, 1142564400);
my $tpit = $w->extract($type, $lat, $long, $time);  
my $err = $w->getError();
ok( $err )
   or diag("lat should be out of range: $err");

($type, $lat, $long, $time) = ("HTSGW", 75.25, 160, 1142564400);
$tpit = $w->extract($type, $lat, $long, $time);  
$err = $w->getError();
ok( not $err )
   or diag("lat should be in range: $err");

($type, $lat, $long, $time) = ("HTSGW", 45, 44, 1142564400);
$tpit = $w->extract($type, $lat, $long, $time);  
$err = $w->getError();
ok( $err )
   or diag("lat should be out of range: $err");


($type, $lat, $long, $time) = ("HTSGW", 44.75, 160, 1142564400);
$tpit = $w->extract($type, $lat, $long, $time);  
$err = $w->getError();
ok( not $err )
   or diag("lat should be in range: $err");

($type, $lat, $long, $time) = ("HTSGW", 44.75, 237, 1142564400);
$tpit = $w->extract($type, $lat, $long, $time);  
$err = $w->getError();
ok( $err )
   or diag("long should be out of range: $err");

($type, $lat, $long, $time) = ("HTSGW", 44.75, 236.5, 1142564400);
$tpit = $w->extract($type, $lat, $long, $time);  
$err = $w->getError();
ok( not $err )
   or diag("lat should be in range: $err");

#-----------------------------------
# test for CMS files
#-----------------------------------
foreach my $inc (@INC) {
   if (-e "$inc/Geo/Sample-GRIB/2009100900_P000.grib") {
      $TEST_FILE = "$inc/Geo/Sample-GRIB/2009100900_P000.grib";
      last;
   }  
}

ok(-e "$TEST_FILE") or
   diag("Path to sample GRIB file not found");

$w = Geo::ReadGRIB->new("$TEST_FILE");

$w->getFullCatalog();

($type, $lat, $long, $time) = ("WIND", 91, 160, 1255046400);
$tpit = $w->extract($type, $lat, $long, $time);  
$err = $w->getError();
ok( $err )
   or diag("lat should be out of range: $err");

($type, $lat, $long, $time) = ("WIND", 90, 160, 1255046400);
$tpit = $w->extract($type, $lat, $long, $time);  
$err = $w->getError();
ok( not $err )
   or diag("lat should be in range: $err");

($type, $lat, $long, $time) = ("WIND", -91, 44, 1255046400);
$tpit = $w->extract($type, $lat, $long, $time);  
$err = $w->getError();
ok( $err )
   or diag("lat should be out of range: $err");


($type, $lat, $long, $time) = ("WIND", -90, 160, 1255046400);
$tpit = $w->extract($type, $lat, $long, $time);  
$err = $w->getError();
ok( not $err )
   or diag("lat should be in range: $err");

($type, $lat, $long, $time) = ("WIND", 0, 160, 1255046400);
$tpit = $w->extract($type, $lat, $long, $time);  
$err = $w->getError();
ok( not $err )
   or diag("long should be in range: $err");
