use strict; use warnings; use utf8; use 5.10.0;
use Test::More;

use lib qw[lib ../lib];
use HATX qw/hatx/;

my ($exp,$got,$msg,$tmp,$tmp2,$h);

{
$msg = 'hatx($obj)->grep() for $href';
$tmp = {A=>65,B=>66,C=>67};
$h = hatx($tmp)->grep(sub {
        my ($k,$v) = @_;
        return $k eq 'B';
    });
$got = join('', values %{$h->to_obj});
$exp = 66;
is($got, $exp, $msg);

$msg = 'hatx($obj)->grep() with @args for $href';
$tmp = {A=>65,B=>66,C=>67};
$h = hatx($tmp)->grep(sub {
        my ($k,$v,$res) = @_;
        return $k eq $res;
    }, 'B');
$got = join('', values %{$h->to_obj});
$exp = 66;
is($got, $exp, $msg);

$msg = 'hatx($obj)->grep() for $aref';
$tmp = [65,66,67];
$h = hatx($tmp)->grep(sub {
        my ($v) = @_;
        return $v == 66;
    });
$got = join('',@{$h->to_obj});
$exp = 66;
is($got, $exp, $msg);

$msg = 'hatx($obj)->grep() with @args for $aref';
$tmp = [65,66,67];
$h = hatx($tmp)->grep(sub {
        my ($v,$res) = @_;
        return $v == $res;
    }, 66);
$got = join('',@{$h->to_obj});
$exp = 66;
is($got, $exp, $msg);

}

done_testing;
