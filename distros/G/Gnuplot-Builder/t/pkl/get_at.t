use strict;
use warnings FATAL => "all";
use Test::More;
use lib "t";
use testlib::PKLUtil qw(expect_pkl);
use Gnuplot::Builder::PartiallyKeyedList;

my $list = Gnuplot::Builder::PartiallyKeyedList->new();
$list->add(10);
$list->set(a => 20);
$list->set(b => 30);
$list->add(40);
$list->add(50);
$list->set(c => 60);

expect_pkl($list, [[undef, 10], [a => 20], [b => 30], [undef, 40], [undef, 50], [c => 60]], "PKL ok");

foreach my $case (
    { index => 0, exp => [undef, 10] },
    { index => 1, exp => [a => 20] },
    { index => 2, exp => [b => 30] },
    { index => 3, exp => [undef, 40] },
    { index => 4, exp => [undef, 50] },
    { index => 5, exp => [c => 60] },
) {
    is_deeply [$list->get_at($case->{index})], $case->{exp}, "get_at($case->{index}) list context OK";
    is scalar($list->get_at($case->{index})), $case->{exp}[1], "get_at($case->{index}) scalar context OK";
}

done_testing;
