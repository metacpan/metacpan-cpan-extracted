use strict; use warnings; use utf8; use 5.10.0;
use Test::More;
use Try::Tiny;

use lib qw[lib ../lib];
use HATX qw/hatx/;

my ($exp,$got,$msg,$tmp,$h);

{ ## Test to_href() method
$msg = 'hatx($aref)->to_href() works';
$tmp = [65,66,67];
$h = hatx($tmp)->to_href(sub { chr($_[0]), $_[0] })->to_obj();
$got = join(' ',$h->{A},$h->{B},$h->{C});
$exp = '65 66 67';
is($got, $exp, $msg);

}

{ ## Test to_aref() method
$msg = 'hatx($href)->to_aref() works';
$tmp = {A => 65, B => 66, C => 67};
$h = hatx($tmp)->to_aref(sub { $_[0].':'.$_[1] });
$got = join(' ',sort @{$h->to_obj});
$exp = 'A:65 B:66 C:67';
is($got, $exp, $msg);

$msg = 'hatx($href)->to_aref() with @args works';
$tmp = {A => 65, B => 66, C => 67};
$h = hatx($tmp)->to_aref(sub {
        my ($k,$v,$res) = @_;
        $k.':'.($v + $res);
    }, 10);
$got = join(' ',sort @{$h->to_obj});
$exp = 'A:75 B:76 C:77';
is($got, $exp, $msg);

$msg = 'hatx($aref)->to_aref() throws error';
try { $h = hatx([1,2,3])->to_aref(sub {}) }
catch { $tmp = $_ };
$got = $tmp =~ /^HATX\/to_aref: No hashref to transform./;
$exp = 1;
is($got, $exp, $msg);

}

done_testing;
