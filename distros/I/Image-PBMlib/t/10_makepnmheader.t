# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 10_makepnmheader.t'

#########################

use Test::More tests => 7;
BEGIN { use_ok('Image::PBMlib') };

use strict;

use vars qw( $val $set $expect );

$set = "makepnmheader ints";

$val = makepnmheader(1, 37, 43);
$expect = "P1\n37 43\n";
ok($val eq $expect, "$set 37x43");

$val = makepnmheader(3, 9, 27, 99);
$expect = "P3\n9 27\n99\n";
ok($val eq $expect, "$set 9x27");

$set = "makepnmheader hash";
$val = makepnmheader({ type => 1, width => 17, height => 71, comments => "17x71" });
$expect = "P1\n#17x71\n17 71\n";
ok($val eq $expect, "$set 17x71");

$val = makepnmheader({ bgp => "g", width => 32, height => 32, max => 63, format => "raw" });
$expect = "P5\n32 32\n63\n";
ok($val eq $expect, "$set 32x32");

$val = makepnmheader({ bgp => "g", width => 64, height => 16, max => 1000, format => "ASCII" });
$expect = "P2\n64 16\n1000\n";
ok($val eq $expect, "$set 64x16");

$val = makepnmheader({ type => 6, width => 100, height => 50 });
$expect = "P6\n100 50\n255\n";
ok($val eq $expect, "$set 100x50");

