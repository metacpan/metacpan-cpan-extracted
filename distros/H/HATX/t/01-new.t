use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw[lib ../lib];
use HATX qw/hatx/;

my ($exp,$got,$msg,$tmp,$h);

{ ## Basic test
$msg = 'Basic test';
$got = 1;
$exp = 1;
is($got, $exp, $msg);
}

{ ## HATX->new() creates an appropriate object
$msg = 'HATX->new()';
$h = HATX->new();
$got = ref($h);
$exp = 'HATX';
is($got, $exp, $msg);

$msg = 'HATX->new([1,2,3])';
$h = HATX->new([1,2,3]);
$got = ref($h->{A});
$exp = 'ARRAY';
is($got, $exp, $msg);

$msg = 'HATX->new({A=>65,B=>66,C=>67})';
$h = HATX->new({A=>65,B=>66,C=>67});
$got = ref($h->{H});
$exp = 'HASH';
is($got, $exp, $msg);

}

done_testing;
