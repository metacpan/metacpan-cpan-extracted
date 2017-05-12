# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 08_comparefloat.t'

#########################

use Test::More tests => 9;
BEGIN { use_ok('Image::PBMlib') };

use strict;

use vars qw( $val $set );

$set = "comparefloatval";

$val = comparefloatval( (1/255), (100/25500));
ok($val == 0, "$set 1/255 == 100/25500");

# these are about .00000089 different
$val = comparefloatval( (257/4095), (4113/65535));
ok($val == 0, "$set 257/4095 == 4113/65535");

$val = comparefloatval( "0,", (1/65535));
ok($val == -1, "$set 0, < 1/65535");

$val = comparefloatval( "1,", (65534/65535));
ok($val == 1, "$set 1, > 65534/65535");

$set = "comparefloattriple";

$val = comparefloattriple("0.0,1,0,", [ 0, 1.0, 0.0 ]);
ok($val == 0, "$set 0.0,1,0, == [ 0, 1.0, 0.0 ] ");

$val = comparefloattriple([ 0.5, 0.1, 0.9 ], ".500001,0.099999,0.90000");
ok($val == 0, "$set [ 0.5, 0.1, 0.9 ] == .500001,0.099999,0.90000");

$val = comparefloattriple([ 0.5, 0.2, 0.9 ], [ 0.5, 0.20001, 0.9 ]);
ok($val == -1, "$set [ 0.5, 0.2, 0.9 ] < [ 0.5, 0.20001, 0.9 ]");

$val = comparefloattriple([ 0.5, 0.2, 0.8 ], [ 0.5, 0.2, 0.79 ]);
ok($val == 1, "$set [ 0.5, 0.2, 0.8 ] > [ 0.5, 0.2, 0.79 ]");

