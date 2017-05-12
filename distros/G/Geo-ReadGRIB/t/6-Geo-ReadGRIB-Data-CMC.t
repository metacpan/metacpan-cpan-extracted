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
   if (-e "$inc/Geo/Sample-GRIB/2009100900_P000.grib") {
      $TEST_FILE = "$inc/Geo/Sample-GRIB/2009100900_P000.grib";
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
my ($type, $lat, $long, $time) = ("WIND", 600, 160, 1255046400);
my $tpit = $w->extract($type, $lat, $long, $time); # $w->dumpit();

$err = $w->getError();
ok( $err )
   or diag("lat should be out of range: $err");


($type, $lat, $long, $time) = ("WIND", 90, -59, 1255046400);
$tpit = $w->extract($type, $lat, $long, $time); # $w->dumpit();

$err = $w->getError();

ok( not $err )
   or diag("ERROR: $err");

my $data = $w->getDataHash();

ok(defined $data->{$time}->{$lat}->{$long}->{$type})
   or diag("\$data->{$time}->{$lat}->{$long}->{$type} is not defined");

my $value = $data->{$time}->{$lat}->{$long}->{$type};

ok($data->{$time}->{$lat}->{$long}->{$type} == 13.22)
 or diag("\$data->{$time}->{$lat}->{$long}->{$type}: 
         \$data->{1255046400}->{45}->{160}->{\'$type\'} should return 13.22 not $value");

#test show() method
   
my $show = $w->show();
#diag($show); 
ok($show =~  /lat: -90 to 90/ and
   $show =~ /Fri Oct  9 00:00:00 2009 \(1255046400\)/) 
   or diag("show() did not return expected string");
