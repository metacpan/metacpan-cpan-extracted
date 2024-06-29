use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw[lib ../lib];
use HATX qw/hatx/;

my ($exp,$got,$msg,$tmp,$tmp2,$h);

{
$msg = 'hatx($obj)->apply() works for $href';
$tmp = {A=>65,B=>66,C=>67};
$h = hatx($tmp)->apply(sub {
        my ($k,$v,$res) = @_;
        $res->{total} += $v;
    }, $tmp2 = {total => 0});
$got = $tmp2->{total};
$exp = 65 + 66 + 67;
is($got, $exp, $msg);

$msg = 'hatx($obj)->apply() works for $aref';
$tmp = [65,66,67];
$tmp2 = {total => 0};
$h = hatx($tmp)->apply(sub {
        my ($v,$res) = @_;
        $res->{total} += $v;
    }, $tmp2);
$got = $tmp2->{total};
$exp = 65 + 66 + 67;
is($got, $exp, $msg);

}

done_testing;
