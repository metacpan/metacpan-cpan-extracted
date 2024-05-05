use warnings;
use strict;
use Math::Ryu qw(:all);

use Test::More;

my $pvnv1 = 1.4 / 10;
my $buggery = "$pvnv1"; # $pvnv1 is now a PVNV.

my $dig = Math::Ryu::MAX_DEC_DIG;
my $nv_str = $dig == 17 ? '0.13999999999999999'
                        : $dig == 21 ? '0.14'
                                     : '0.13999999999999999999999999999999999';

cmp_ok(n2s($pvnv1), 'eq', $nv_str, "n2s(1.4/10) returns correct string");
cmp_ok(nv2s($pvnv1), 'eq', $nv_str, "nv2s(1.4/10) returns correctly");
cmp_ok(spanyf($pvnv1), 'eq', $nv_str, "spanyf(1.4/10) returns correctly");

my $pvnv2 = "1e5000";
$pvnv2 += 0; # $pvn2 is now a PVNV.

cmp_ok(n2s($pvnv2), 'eq', 'inf', "n2s() correctly returns 'inf'");
cmp_ok(nv2s($pvnv2), 'eq', 'inf', "nv2s() correctly returns 'inf'");
cmp_ok(spanyf($pvnv2), 'eq', 'inf', "spanyf() correctly returns 'inf'");

my $str = '1e5000';
$buggery = $str + 0;

cmp_ok(spanyf($str, ' ', $buggery), 'eq', "1e5000 inf" , "spanyf() correctly returns '1e5000 inf'");
cmp_ok(n2s($str), 'eq', 'inf', "n2s(str) evaluates string in numeric context, as expected");
cmp_ok(nv2s($str), 'eq', 'inf', "nv2s(str) evaluates string as NV, as expected");
cmp_ok(n2s($buggery), 'eq', 'inf', "n2s(pvnv) evaluates string in numeric context, as expected");
cmp_ok(nv2s($buggery), 'eq', 'inf', "nv2s(pvnv) returns 'inf' as expected");

done_testing();




