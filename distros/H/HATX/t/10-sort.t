use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw[lib ../lib];
use HATX qw/hatx/;

my ($exp,$got,$msg,$tmp,$h);

{
$msg = 'hatx($obj)->sort() for $href is no-op';
$tmp = {A=>65,B=>66,C=>67};
$h = hatx($tmp)->sort(sub { $b cmp $a});
$got = join(' ',$h->{H}{A},$h->{H}{B},$h->{H}{C});
$exp = '65 66 67';
is($got, $exp, $msg);

$msg = 'hatx($obj)->sort() numeric ascending (default) for $aref';
$tmp = [67,66,65];
$h = hatx($tmp)->sort();
$got = join(' ',@{$h->to_obj});
$exp = '65 66 67';
is($got, $exp, $msg);

$msg = 'hatx($obj)->sort() numeric descending for $aref';
$tmp = [65,66,67];
$h = hatx($tmp)->sort(sub ($$) { $_[1] <=> $_[0] });
$got = join(' ',@{$h->to_obj});
$exp = '67 66 65';
is($got, $exp, $msg);

$msg = 'hatx($obj)->sort() alphabetical ascending for $aref';
$tmp = ['cat','bee','ant'];
$h = hatx($tmp)->sort(sub ($$) { $_[0] cmp $_[1] });
$got = join(' ',@{$h->to_obj});
$exp = 'ant bee cat';
is($got, $exp, $msg);

$msg = 'hatx($obj)->sort() alphabetical descending for $aref';
$tmp = ['ant','bee','cat'];
$h = hatx($tmp)->sort(sub ($$) { $_[1] cmp $_[0] });
$got = join(' ',@{$h->to_obj});
$exp = 'cat bee ant';
is($got, $exp, $msg);

}

done_testing;
