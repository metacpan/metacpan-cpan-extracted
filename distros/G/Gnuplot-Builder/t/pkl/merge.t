use strict;
use warnings FATAL => "all";
use lib "t";
use testlib::PKLUtil qw(expect_pkl);
use Test::More;
use Gnuplot::Builder::PartiallyKeyedList;

note("tests for merge()");

{
    my $pkl = Gnuplot::Builder::PartiallyKeyedList->new;
    $pkl->add(1);
    $pkl->set(a => 2);
    $pkl->set(b => 3);

    my $another = Gnuplot::Builder::PartiallyKeyedList->new;
    $another->set(a => 20);
    $another->add(4);
    $another->set(c => 5);
    $another->add(6);

    is $pkl->size, 3;
    expect_pkl $pkl, [[undef, 1], [a => 2], [b => 3]],
        "before merge OK";
    $pkl->merge($another);
    is $pkl->size, 6;
    expect_pkl $pkl, [[undef, 1], [a => 20], [b => 3],
                      [undef, 4], [c => 5], [undef, 6]],
                          "after merge OK";
}

done_testing;
