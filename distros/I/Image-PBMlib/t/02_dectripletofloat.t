# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 02_dectripletofloat.t'

#########################

use Test::More tests => 25;
BEGIN { use_ok('Image::PBMlib') };

# Note on value tests:
# 1/65535 is ~ 0.0000152590
# we look for a value that is right to 5 places even for max < 65535

use strict;

use vars qw( $rc @valset $rgb $set );

# does 8 tests
sub checkset {
  ok(($valset[0] > 0.99999), "$set: 300/255 as float > 0.99999");
  ok(($valset[0] < 1.00001), "$set: 300/255 as float < 1.00001");

  ok(($valset[1] > 0.00784), "$set: 2/255 as float > 0.00784");
  ok(($valset[1] < 0.00785), "$set: 2/255 as float < 0.00785");

  ok(($valset[2] > 0.78431), "$set: 200/255 as float > 0.78431");
  ok(($valset[2] < 0.78432), "$set: 200/255 as float < 0.78432");
}

$set = "string to array";
@valset = dectripletofloat("300:2:200:", 255);
# 1.0,  0.00784314,     0.78431373,
chop(@valset);
checkset();

$set = "array to array";
@valset = dectripletofloat([ 300, "2:", 200 ], 255);
# 1.0,  0.00784314,     0.78431373,
chop(@valset);
checkset();

$set = "string to string";
$rgb    = dectripletofloat("300:2:200", 255);
# 0.95834223,0.00003052,1.0
@valset = split(/,/, $rgb);
checkset();

$set = "array to string";
$rgb    = dectripletofloat([ 300, "2:", 200 ], 255);
# 0.95834223,0.00003052,1.0
@valset = split(/,/, $rgb);
checkset();


