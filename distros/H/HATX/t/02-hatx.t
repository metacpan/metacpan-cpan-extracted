use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw[lib ../lib];
use HATX qw/hatx/;

my ($exp,$got,$msg,$tmp,$h);

{ ## hatx() creates an appropriate object
$msg = 'hatx()';
$h = hatx();
$got = ref($h);
$exp = 'HATX';
is($got, $exp, $msg);

$msg = 'hatx([1,2,3])';
$h = hatx([1,2,3]);
$got = ref($h->{A});
$exp = 'ARRAY';
is($got, $exp, $msg);

$msg = 'hatx({A=>65,B=>66,C=>67})';
$h = hatx({A=>65,B=>66,C=>67});
$got = ref($h->{H});
$exp = 'HASH';
is($got, $exp, $msg);

$msg = 'hatx({A=>65,B=>66,C=>67}) No-clobber';
$tmp = {A=>65,B=>66,C=>67};
$h = hatx($tmp);
$h->{H}{A} = 100;
$got = $h->{H}{A} . '-' . $tmp->{A};
$exp = '100-65';
is($got, $exp, $msg);

}

done_testing;
