# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 06_explodetriple.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('Image::PBMlib') };

use strict;

use vars qw( $val );

$val = join('', explodetriple("FF/ff/0/"));
ok($val eq 'FF/ff/0/', "explodetriple FF/ff/0/");

$val = join('', explodetriple("1:12345:0"));
ok($val eq '1:12345:0:', "explodetriple 1:12345:0");

$val = join('', explodetriple("1.0,1.345,0.0"));
ok($val eq '1.0,1.345,0.0,', "explodetriple 1.0,1.345,0.0");
