use strict;
use warnings FATAL => "all";
use lib "t";
use testlib::PKLUtil qw(expect_pkl);
use Test::More;
use Gnuplot::Builder::PartiallyKeyedList;

note("basic hash operations");

{
    my $pkl = Gnuplot::Builder::PartiallyKeyedList->new;
    expect_pkl $pkl, [], "at first, it's empty";
    $pkl->size, 0;
    $pkl->set(a => "foobar");
    expect_pkl $pkl, [[a => "foobar"]], "new entry OK";
    $pkl->size, 1;

    is $pkl->get("a"), "foobar", "get existing entry OK";
    is $pkl->get("b"), undef, "get non-existing entry OK";
    ok $pkl->exists("a"), "exists() true OK";
    ok !$pkl->exists("b"), "exists() false OK";

    $pkl->add(1);
    $pkl->add(2);
    $pkl->set(b => "hoge");
    is $pkl->size, 4;
    expect_pkl $pkl, [[a => "foobar"],[undef, 1],[undef, 2], [b => "hoge"]],
        "mixed non-keyed and keyed entries";
    is $pkl->get("a"), "foobar", "still accessible by key";
    is $pkl->get("b"), "hoge", "accessble by key";
    ok $pkl->exists("a"), "exists() works for mixed PKL";
    ok $pkl->exists("b"), "exists() works for b, too";
    ok !$pkl->exists("c"), "c does not exist, of course";

    $pkl->add(3);
    is $pkl->size, 5;
    expect_pkl $pkl, [[a => "foobar"],[undef, 1],[undef, 2], [b => "hoge"], [undef, 3]],
        "another non-keyed at the tail";

    is $pkl->delete("a"), "foobar", "delete existing entry OK";
    is $pkl->delete("c"), undef, "delete non-existing entry OK";
    is $pkl->size, 4;
    expect_pkl $pkl, [[undef, 1], [undef, 2], [b => "hoge"], [undef, 3]], "first entry deleted";
    
    $pkl->set(a => "tail");
    is $pkl->size, 5;
    expect_pkl $pkl, [[undef, 1], [undef, 2], [b => "hoge"], [undef, 3], [a => "tail"]],
        "key a is re-inserted to the tail";
}

done_testing;

