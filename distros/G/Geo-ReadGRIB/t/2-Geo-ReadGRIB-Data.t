# Test to see if a Geo::ReadGRIB object can return the 
# expected data.
# 
# For this to work there needs to be a specific sample GRIB file
# and the module has to be able to find wgrib.exe 


use Test::More tests => 6;

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

# try out of range value
my ($type, $lat, $long, $time) = ("HTSGW", 400, 160, 1142564400);
my $tpit = $w->extract($type, $lat, $long, $time); # $w->dumpit();

$err = $w->getError();
ok( $err )
   or diag("lat should be out of range: $err");


($type, $lat, $long, $time) = ("HTSGW", 45, 160, 1142564400);
$tpit = $w->extract($type, $lat, $long, $time); # $w->dumpit();

$err = $w->getError();

ok( not $err )
   or diag("ERROR: $err");

my $data = $w->getDataHash();

ok(defined $data->{$time}->{$lat}->{$long}->{$type})
   or diag("\$data->{$time}->{$lat}->{$long}->{$type} is not defined");


ok($data->{$time}->{$lat}->{$long}->{$type} == 3.43)
 or diag("\$data->{$time}->{$lat}->{$long}->{$type}: 
         \$data->{1142564400}->{45}->{160}->{\'HTSGW\'} should return 3.43");

#test show() method
   
my $show = $w->show();
#diag($show); 
ok($show =~  /lat: 75.25 to 44.75/ and
   $show =~ /Sat Mar 11 12:00:00 2006 \(1142078400\)/) 
   or diag("show() did not return expected string");
