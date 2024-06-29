use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw[lib ../lib];
use HATX qw/hatx/;

my ($exp,$got,$msg,$tmp,$h);

{
$msg = 'hatx($obj)->map() for $href';
$tmp = {A=>65,B=>66,C=>67};
$h = hatx($tmp)->map(sub {
        my ($k,$v) = @_;
        return ($k.$k, $v+1);   # Concat the $key; Increment the $val
    });
$got = join(' ',$h->{H}{AA},$h->{H}{BB},$h->{H}{CC});
$exp = '66 67 68';
is($got, $exp, $msg);

$msg = 'hatx($obj)->map() with @args for $href';
$tmp = {A=>65,B=>66,C=>67};
$h = hatx($tmp)->map(sub {
        my ($k,$v,$res) = @_;
        return ($k.$k, $v*$res);   # Concat the $key; Increment the $val
    }, 10);
$got = join(' ',$h->{H}{AA},$h->{H}{BB},$h->{H}{CC});
$exp = '650 660 670';
is($got, $exp, $msg);

$msg = 'hatx($obj)->map() for $aref';
$tmp = [65,66,67];
$h = hatx($tmp)->map(sub { $_[0] + 1 });  # Increment the $val
$got = join(' ',@{$h->{A}});
$exp = '66 67 68';
is($got, $exp, $msg);

$msg = 'hatx($obj)->map() with @args for $aref';
$tmp = [65,66,67];
$h = hatx($tmp)->map(sub { $_[0] + $_[1] }, 10);  # Increment the $val
$got = join(' ',@{$h->{A}});
$exp = '75 76 77';
is($got, $exp, $msg);

}

done_testing;
