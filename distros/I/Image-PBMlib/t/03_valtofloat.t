# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 03_valtofloat.t'

#########################

use Test::More tests => 9;
BEGIN { use_ok('Image::PBMlib') };

# Note on value tests:
# 1/65535 is ~ 0.0000152590
# we look for a value that is right to 5 places even for max < 65535

use strict;

use vars qw( $set $test $val $min $max );

# does 2 tests
sub checkrange {
  chop $val;
  ok(($val > $min), "$set: $test as float > $min");
  ok(($val < $max), "$set: $test as float < $max");
}

$set = "hexvaltofloat";

$test = "Fe/255";	# 0.99607843,
$min  = 0.99607;	$max = 0.99608;
$val = hexvaltofloat("Fe/", 255);
checkrange();

$test = "D/15";		# 0.86666666,
$min  = 0.86666;	$max = 0.86667;
$val = hexvaltofloat("D/", 15);
checkrange();

$set = "decvaltofloat";

$test = "65500/65535";	# 0.99946593,
$min  = 0.99946;	$max = 0.99947;
$val = decvaltofloat("65500:", 65535);
checkrange();

$test = "17/16383";	# 0.00103766,
$min  = 0.00103;	$max = 0.00104;
$val = decvaltofloat("17", 16383);
checkrange();

