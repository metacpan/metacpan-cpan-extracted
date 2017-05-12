# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 05_floatvaltodec.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('Image::PBMlib') };

use strict;

use vars qw( $val );

$val = floatvaltodec(0.93333333, 15);
ok($val eq '14:', "floatvaltodec 0.93333333, 15 : 14");

$val = floatvaltodec(".99607843,", 255);
ok($val eq '254:', "floatvaltodec .99607843, 255 : 254");

$val = floatvaltodec(0.00207532, 16383);
ok($val eq '34:', "floatvaltodec 0.00207532, 16383 : 34");
