#!/usr/bin/perl
# t/takeput-6.t
use strict;
use experimental qw(signatures);

use Test::More 'no_plan';

our $dir;
my $tdir;
BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    $tdir = dirname(abs_path($0));
    $dir = $tdir =~ s/[^\/]+$/lib/r;
    };

use File::Spec;

use lib $dir;

use_ok 'File::Takeput' , qw(plunk grab fgrab take); # 1

our $fn = $tdir.'/takeput-6.txt';

unlink $fn;

ok (plunk($fn , create => 1)->('abgcdgabgefg')); # 2

ok (not take($fn , unique => 1)); # 3

ok (File::Takeput::set(separator => 'g' , newline => 'x')); # 4

package test_namespace;

use lib $main::dir;

use File::Takeput qw(grab fgrab);

my $fn = $main::fn;

main::ok (File::Takeput::set(separator => 'b' , newline => 'x')); # 5
my @content;
main::ok (@content = grab($fn)); # 6
main::ok ((join '' , @content) eq 'axgcdgaxgefg'); # 7
main::ok (scalar @content == 3); # 8

package main;

my @content;
ok (@content = grab($fn)); # 9
ok ((join '' , @content) eq 'abxcdxabxefx'); # 10
ok (scalar @content == 4); # 11

open STDERR , '>' , File::Spec->devnull();

ok (not grab($fn , error => 2)); # 12
ok (not grab($fn , patience => -5)); # 13
ok (not grab($fn , separator => '')); # 14
ok (not grab($fn , x => 1)); # 15
ok (not grab($fn , x => {y => 1})); # 16

my $read;
ok (not fgrab($fn , x => 1)); # 17
ok ($read = fgrab($fn.'x')); # 18
ok (not $read->()); # 19

__END__
