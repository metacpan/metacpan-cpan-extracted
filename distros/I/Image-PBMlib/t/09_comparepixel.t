# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 09_comparepixel.t'

#########################

use Test::More tests => 9;
BEGIN { use_ok('Image::PBMlib') };

use strict;

use vars qw( $val $set );

$set = "comparepixelval";

$val = comparepixelval( "1/",255, "100:",25500);
ok($val == 0, "$set 1/255 == 100/25500");

# as floats these are about .00000089 different and *MATCH*
$val = comparepixelval( "257:", 4095, "1011/", 65535);
ok($val == -1, "$set 257/4095 < 4113/65535");

$val = comparepixelval( "0:", 65535, "1/", 65535);
ok($val == -1, "$set 0, < 1/65535");

$val = comparepixelval( "FFFF/", 65535, "65534:", 65535);
ok($val == 1, "$set 1, > 65534/65535");

$set = "comparepixeltriple";

$val = comparepixeltriple("0:5:0:", 5, [ "0/", "f/", "0/" ], 15);
ok($val == 0, "$set green 0:5:0(5) == [ 0/, f/, 0/ ](15)");

$val = comparepixeltriple("FF/33/17", 255, "1275:255:115", 1275);
ok($val == 0, "$set FF/33/17(255) == 1275:255:115(1275)");

$val = comparepixeltriple("e/0/2", 15, "14:0:1", 15);
ok($val == 1, "$set e/0/2(15) > 14:0:1(15)");

$val = comparepixeltriple("64:0:1", 128, "44/0/1", 128);
ok($val == -1, "$set 64:0:1(128) < 44/0/1(128)");

