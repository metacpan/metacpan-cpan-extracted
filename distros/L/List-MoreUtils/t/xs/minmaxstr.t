#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 0; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use List::MoreUtils (":all");
use lib ("t/lib");


use Test::More;
use Test::LMU;

my @list = reverse 'AA' .. 'ZZ';
my ($min, $max) = minmaxstr @list;
is($min, 'AA');
is($max, 'ZZ');

# Odd number of elements
push @list, 'ZZ Top';
($min, $max) = minmaxstr @list;
is($min, 'AA');
is($max, 'ZZ Top');

# COW causes missing max when optimization for 1 argument is applied
@list = grep { defined $_ } map { my ($min, $max) = minmaxstr(sprintf("%s", rand)); ($min, $max) } (0 .. 19);
is(scalar @list, 40, "minmaxstr swallows max on COW");

# Test with a single list value
my $input = 'foo';
($min, $max) = minmaxstr $input;
is($min, 'foo');
is($max, 'foo');

# Confirm output are independant copies of input
$input = 'bar';
is($min, 'foo');
is($max, 'foo');
$min = 'bar';
is($max, 'foo');

leak_free_ok(
    minmaxstr => sub {
        @list = reverse 'AA' .. 'ZZ', 'ZZ Top';
        ($min, $max) = minmaxstr @list;
    }
);

done_testing;



