#
#===============================================================================
#
#         FILE:  11-Geo-ReadGRIB-times.t
#
#  DESCRIPTION:  test for correct start and end dates
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

use Test::More tests => 6;                      # last test to print

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


#print STDERR "first time: ", $w->{TIME};
#print STDERR "last time: ", $w->{LAST_TIME};

ok( $w->{TIME} == 1142078400 ) or
   diag("base time should be 1142078400");

ok( $w->{LAST_TIME} == 1142726400 ) or
   diag("last time should be 1142726400");

foreach my $inc (@INC) {
   if (-e "$inc/Geo/Sample-GRIB/2009100900_P000.grib") {
      $TEST_FILE = "$inc/Geo/Sample-GRIB/2009100900_P000.grib";
      last;
   }  
}

ok(-e "$TEST_FILE") or
   diag("Path to sample GRIB file not found");

$w = Geo::ReadGRIB->new("$TEST_FILE");


#print STDERR "first time: ", $w->{TIME};
#print STDERR "last time: ", $w->{LAST_TIME};
   
ok( $w->{TIME} == 1255046400 ) or
   diag("base time should be 1142078400");

ok( $w->{TIME} == 1255046400 ) or
   diag("last time should be 1255046400");
