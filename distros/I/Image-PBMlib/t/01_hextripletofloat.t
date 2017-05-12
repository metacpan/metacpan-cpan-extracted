# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 01_hextripletofloat.t'

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
  ok(($valset[0] > 0.95834), "$set: 7AAA/32767 as float > 0.95834");
  ok(($valset[0] < 0.95835), "$set: 7AAA/32767 as float < 0.95835");

  ok(($valset[1] > 0.00003), "$set: 1/32767 as float > 0.00003");
  ok(($valset[1] < 0.00004), "$set: 1/32767 as float < 0.00004");

  ok(($valset[2] > 0.99999), "$set: bbbb/32767 as float > 0.99999");
  ok(($valset[2] < 1.00001), "$set: bbbb/32767 as float < 1.00001");
}

$set = "string to array";
@valset = hextripletofloat("7AAA/1/bbbb/", 32767);
# 0.95834223,   0.00003052,     1.0,
chop(@valset);
checkset();

$set = "array to array";
@valset = hextripletofloat([ "7AAA/", "1", "bbbb" ], 32767);
# 0.95834223,   0.00003052,     1.0,
chop(@valset);
checkset();

$set = "string to string";
$rgb    = hextripletofloat("7AAA/1/bbbb", 32767);
# 0.95834223,0.00003052,1.0
@valset = split(/,/, $rgb);
checkset();

$set = "array to string";
$rgb    = hextripletofloat([ "7AAA/", "1", "bbbb" ], 32767);
# 0.95834223,0.00003052,1.0
@valset = split(/,/, $rgb);
checkset();

