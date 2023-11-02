#!/usr/bin/perl
# t/takeput-1.t
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

my $fn = $tdir.'/takeput-1.txt';
my $fn_1 = $tdir.'/takeput-1-1.csv';
my $fn_2 = $tdir.'/takeput-1-2.log';
my $fn_3 = $tdir.'/takeput-1-3.html';

unlink $fn_1;
copy $fn , $fn_1;

unlink $fn_2;
copy $fn , $fn_2;

unlink $fn_3;
copy $fn , $fn_3;

# Lock some file and read its content.
my @content1;
ok (@content1 = take($fn_1)); # 2
ok (scalar @content1 == 2); # 3
ok ("1,yksi\n2,kaksi\n" eq join '' , @content1); # 4

my @content2;
ok (@content2 = grab($fn_2 , patience => 2.5)); # 5
ok (scalar @content2 == 2); # 6
ok ("1,yksi\n2,kaksi\n" eq join '' , @content2); # 7
ok (append($fn_2)->("3,kolme\n")); # 8

my $content3;
ok (($content3) = grab($fn_3 , separator => undef)); # 9
ok ("1,yksi\n2,kaksi\n" eq $content3); # 10
ok ($content3 = grab($fn_3 , separator => undef , flatten => 1)); # 11
ok ("1,yksi\n2,kaksi\n" eq $content3); # 12

$content1[$_] =~ s/,/;/g for (0..$#content1);
ok (put($fn_1)->(@content1)); # 13

ok ("1;yksi\n2;kaksi\n"          eq join '' , grab($fn_1)); # 14
ok ("1,yksi\n2,kaksi\n3,kolme\n" eq join '' , grab($fn_2)); # 15

__END__
