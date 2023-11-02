#!/usr/bin/perl
# t/takeput-5.t
use strict;
use experimental qw(signatures);

use Test::More 'no_plan';

my ($dir,$tdir);
BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    $tdir = dirname(abs_path($0));
    $dir = $tdir =~ s/[^\/]+$/lib/r;
    };

use File::Copy;
use lib $dir;

use_ok 'File::Takeput'; # 1

my $fn = $tdir.'/takeput-5.txt'; #

unlink $fn;

my (@a1 , @a2 , @a3);
my @b = qw(Uha sikke tider hundene er efter kattene kattene er efter fuglene fuglene er efter myggene og myggene er efter mig);
ok (@a1 = take($fn , create => 1)); # 2
ok (not append($fn)->(@b)); # 3
ok (not grab($fn)); # 4
ok (not plunk($fn)->(@b)); # 5
ok ('' eq join '' , @a1); # 6

my ($r1,$r2);
ok ($r1 = File::Takeput::ftake($fn)); # 7
ok (not $r1->(@b)); # 8
ok ($r2 = File::Takeput::fgrab($fn)); # 9
ok (not $r2->(@b)); # 10

ok (put($fn)->(@b)); # 11

my $p;
ok ($p = File::Takeput::fpass($fn)); # 12
ok (not $p->()); # 13

ok (append($fn)->(@b)); # 14
ok (@a2 = grab($fn)); # 15
ok ((join '' , @a2) eq (join '' , @b , @b)); # 16

my $rb = join '' , reverse @b;
ok (plunk($fn)->(reverse @b)); # 17
ok ((join '' , grab($fn)) eq (join '' , reverse @b)); # 18

ok ((join '' , $r1->()) eq $rb); # 19
ok (not $r2->()); # 20

my $w;
ok ($w = put($fn)); # 21
ok ($w->(@b)); # 22
ok (not $p->()); # 23

ok (@a3 = $r1->()); # 24
ok ($p->()); # 25
ok (not $w->(@b)); # 26

__END__
