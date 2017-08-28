#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");


use Test::More;
use Test::LMU;

my @list = reverse 0 .. 10000;
my ($min, $max) = minmax @list;
is($min, 0);
is($max, 10000);

# Even number of elements
push @list, 10001;
($min, $max) = minmax @list;
is($min, 0);
is($max, 10001);
$list[0] = 17;

# Some floats
@list = (0, -1.1, 3.14, 1 / 7, 10000, -10 / 3);
($min, $max) = minmax @list;

# Floating-point comparison cunningly avoided
is(sprintf("%.2f", $min), "-3.33");
is($max, 10000);

# Test with a single negative list value
my $input = -1;
($min, $max) = minmax $input;
is($min, -1);
is($max, -1);

# COW causes missing max when optimization for 1 argument is applied
@list = grep { defined $_ } map { my ($min, $max) = minmax(sprintf("%.3g", rand)); ($min, $max) } (0 .. 19);
is(scalar @list, 40, "minmax swallows max on COW");

# Confirm output are independant copies of input
$input = 1;
is($min, -1);
is($max, -1);
$min = 2;
is($max, -1);

# prove overrun
my $uvmax    = ~0;
my $ivmax    = $uvmax >> 1;
my $ivmin    = (0 - $ivmax) - 1;
my @low_ints = map { $ivmin + $_ } (0 .. 10);
($min, $max) = minmax @low_ints;
is($min, $ivmin,      "minmax finds ivmin");
is($max, $ivmin + 10, "minmax finds ivmin + 10");

my @high_ints = map { $ivmax - $_ } (0 .. 10);
($min, $max) = minmax @high_ints;
is($min, $ivmax - 10, "minmax finds ivmax-10");
is($max, $ivmax,      "minmax finds ivmax");

my @mixed_ints = map { ($ivmin + $_, $ivmax - $_) } (0 .. 10);
($min, $max) = minmax @mixed_ints;
is($min, $ivmin, "minmax finds ivmin");
is($max, $ivmax, "minmax finds ivmax");

my @high_uints = map { $uvmax - $_ } (0 .. 10);
($min, $max) = minmax @high_uints;
is($min, $uvmax - 10, "minmax finds uvmax-10");
is($max, $uvmax,      "minmax finds uvmax");

my @mixed_nums = map { ($ivmin + $_, $uvmax - $_) } (0 .. 10);
($min, $max) = minmax @mixed_nums;
is($min, $ivmin, "minmax finds ivmin");
is($max, $uvmax, "minmax finds uvmax");

leak_free_ok(
    minmax => sub {
        @list = (0, -1.1, 3.14, 1 / 7, 10000, -10 / 3);
        ($min, $max) = minmax @list;
    }
);

done_testing;


