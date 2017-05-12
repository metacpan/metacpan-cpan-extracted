use strict;
use warnings FATAL => "all";
use lib "t";
use testlib::PKLUtil qw(expect_pkl);
use Test::More;
use Test::Builder;
use Gnuplot::Builder::PartiallyKeyedList;

my $pkl = Gnuplot::Builder::PartiallyKeyedList->new;

$pkl->add("1");
$pkl->set(a => 2);
$pkl->add(3);
$pkl->add(4);
$pkl->set(b => 5);
is $pkl->size, 5;
expect_pkl $pkl,
    [[undef, 1], [a => 2], [undef, 3], [undef, 4], [b => 5]],
    "mixed add and set OK";
    
$pkl->set(a => "two");
is $pkl->size, 5;
expect_pkl $pkl,
    [[undef, 1], [a => "two"], [undef, 3], [undef, 4], [b => 5]],
    "partial change OK";
    
my $another = Gnuplot::Builder::PartiallyKeyedList->new;
$another->add(6);
$another->set(b => "five");
$pkl->merge($another);
is $pkl->size, 6;
expect_pkl $pkl,
    [[undef, 1], [a => "two"], [undef, 3], [undef, 4], [b => "five"], [undef, 6]],
    "merge OK";

done_testing;
