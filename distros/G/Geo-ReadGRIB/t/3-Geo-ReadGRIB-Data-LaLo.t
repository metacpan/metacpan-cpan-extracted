# Test to see if a Geo::ReadGRIB object can return the 
# expected data.
# 
# For this to work there needs to be a specific sample GRIB file
# and the module has to be able to find wgrib.exe 
#
# 3/18/2010 - added test for backflip()


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

#$w->getCatalog();
#$w->getCatalogVerbose();

$w->getFullCatalog();

my ($type, $lat1, $long1, $lat2, $long2, $time) = 
   ("HTSGW", 50, 160, 45, 165, 1142564400);
$w->extractLaLo($type, $lat1, $long1, $lat2, $long2, $time); 

$err = $w->getError();

diag("ERRORx: $err") if defined $err;

my $data = $w->getDataHash();

ok( not defined $data->{$time}->{$lat2}->{$long2}->{$type})
   or diag("\$data->{$time}->{$lat2}->{$long2}->{$type} should not be defined");

$w->backflip(1);

$w->extractLaLo($type, $lat1, $long1, $lat2, $long2, $time); 

$err = $w->getError();

diag("ERRORx: $err") if defined $err;

$data = $w->getDataHash();

ok( defined $data->{$time}->{$lat2}->{$long2}->{$type})
   or diag("\$data->{$time}->{$lat2}->{$long2}->{$type} not defined");

ok($data->{$time}->{$lat2}->{$long2}->{$type} == 3.71)
 or diag("\$data->{$time}->{$lat2}->{$long2}->{$type}: 
         \$data->{1142564400}->{$lat2}->{$long2}->{\'HTSGW\'} should return 3.71
          got: $data->{$time}->{$lat2}->{$long2}->{$type}");

ok(defined $data->{$time}->{$lat1}->{$long1}->{$type})
   or diag("\$data->{$time}->{$lat1}->{$long1}->{$type} is not defined");


ok($data->{$time}->{$lat1}->{$long1}->{$type} == 3.38)
 or diag("\$data->{$time}->{$lat1}->{$long1}->{$type}: 
         \$data->{1142564400}->{$lat1}->{$long1}->{\'HTSGW\'} should return 3.38
          got: $data->{$time}->{$lat1}->{$long1}->{$type}");




#test show() method

my $show = $w->show();
 
ok($show =~  /lat: 75.25 to 44.75/ and
   $show =~ /Sat Mar 11 12:00:00 2006 \(1142078400\)/) 
   or diag("show() did not return expected string");
