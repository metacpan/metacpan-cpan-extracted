#!/usr/bin/perl
# t/takeput-4.t
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

my $fn = $tdir.'/takeput-4.txt'; # \n line endings
my $fn_1 = $tdir.'/takeput-4-1.txt';
my $fn_2 = $tdir.'/takeput-4-2.txt';
my $fn_3 = $tdir.'/takeput-4-3.txt';

unlink $fn_1;
copy $fn , $fn_1;
unlink $fn_2;
unlink $fn_3;

ok ( File::Takeput::set(
        create => 1 ,
        separator => "\n" ,
        newline => "\r\n" ,
        )
    ); # 2
my @a = grab($fn_1);
ok (plunk($fn_2)->(@a)); # 3
ok ("1\r\n2\r\n3\r\n4" eq join '' , @a); # 4

ok (File::Takeput::reset()); # 5
@a = grab($fn_2);
ok ("1\n2\n3\n4" eq join '' , @a); # 6

ok (plunk($fn_3 , create => 1)->("1\n2\r\n3\n4\r\n")); # 7

@a = grab($fn_3 , separator => "\r\n" , newline => "\n");
ok (scalar @a == 2); # 8
ok ("1\n2\n" eq $a[0]); # 9
ok ("3\n4\n" eq $a[1]); # 10

@a = grab($fn_3 , separator => "\n");
ok (scalar @a == 4); # 11
ok ("1\n" eq $a[0]); # 12
ok ("2\r\n" eq $a[1]); # 13
ok ("3\n" eq $a[2]); # 14
ok ("4\r\n" eq $a[3]); # 15

@a = grab($fn_3 , separator => undef);
ok (scalar @a == 1); # 16
(my $b) = @a;
ok ("1\n2\r\n3\n4\r\n" eq $b); # 17

__END__
