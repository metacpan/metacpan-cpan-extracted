use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw[lib ../lib];
use HATX qw/hatx/;

my ($exp,$got,$msg,$tmp,$h);

{ ## hatx($obj)->to_obj()
$msg = 'hatx($href)->to_obj() has ref of HASH';
$h = hatx({A=>65,B=>66,C=>67})->to_obj;
$got = ref($h);
$exp = 'HASH';
is($got, $exp, $msg);

$msg = 'hatx($href)->to_obj() works';
$h = hatx({A=>65,B=>66,C=>67})->to_obj;
$got = join(' ',$h->{A},$h->{B},$h->{C});
$exp = '65 66 67';
is($got, $exp, $msg);

$msg = 'hatx($aref)->to_obj() has ref of ARRAY';
$h = hatx([65,66,67])->to_obj;
$got = ref($h);
$exp = 'ARRAY';
is($got, $exp, $msg);

$msg = 'hatx($aref)->to_obj() works';
$h = hatx([65,66,67])->to_obj;
$got = join(' ',@$h);
$exp = '65 66 67';
is($got, $exp, $msg);

}

done_testing;
