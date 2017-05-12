# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 07_rescale.t'

#########################

use Test::More tests => 11;
BEGIN { use_ok('Image::PBMlib') };

use strict;

use vars qw( $val $set );

$set = "rescaleval";
$val = rescaleval("F/", 255, 15);
ok($val eq '1/', "$set F/ 255 15");

$val = rescaleval("FE/", 255, 4080);
ok($val eq 'FE0/', "$set FE/ 255 4080");

$val = rescaleval("1000:", 10000, 1000);
ok($val eq '100:', "$set 1000: 10000 1000");

$val = rescaleval("0.31,", 287, 1492);
ok($val eq '0.31,', "$set 0.31, 287 1492");

$set = "array context rescaletriple";
$val = join('', rescaletriple("0.31,0.1,0.2", 287, 1492));
ok($val eq '0.31,0.1,0.2,', "$set 0.31,0.1,0.2 287 1492");

$val = join('', rescaletriple("22:21:23", 287, 287));
ok($val eq '22:21:23:', "$set 22:21:23 287 287");

$set = "string context rescaletriple";
$val = rescaletriple("22/21/23", 287, 287);
ok($val eq '22/21/23', "$set 22/21/23 287 287");

$val = rescaletriple("10/100/1000", 1024, 10240);
ok($val eq 'A0/A00/2800', "$set 10/100/1000 1024 10240");

$val = rescaletriple("20:200:2", 1024, 10240);
ok($val eq '200:2000:20', "$set 20:200:2 1024 10240");

$val = rescaletriple("60:1024:0", 1024, 512);
ok($val eq '30:512:0', "$set 60:1024:0 1024 512");

