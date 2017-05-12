# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 04_floatvaltohex.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('Image::PBMlib') };

use strict;

use vars qw( $val );

$val = floatvaltohex(0.86666666, 15);
ok($val eq 'D/', "floatvaltohex 0.86666666, 15 : D");

$val = floatvaltohex("0.00001525902189,", 65535);
ok($val eq '1/', "floatvaltohex 0.00001525902189, 65535 : 1");

$val = floatvaltohex(0.00103766, 16383);
ok($val eq '11/', "floatvaltohex 0.00103766, 16383 : 11");
