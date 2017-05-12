use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::JoinDict;

{
    my $child = Gnuplot::Builder::JoinDict->new(
        separator => ":", content => [x => 10, y => 20]
    );
    my $parent = Gnuplot::Builder::JoinDict->new(
        separator => ", ", content => [X => $child, Y => 30]
    );
    is "$parent", "10:20, 30", "nested joindict stringification";
    isa_ok $parent->get("X"), "Gnuplot::Builder::JoinDict", "nested joindict object";
    is $parent->set(Y => $child)->to_string, "10:20, 10:20", "nested siblings";

    is($parent->set(X => $parent->get("X")->set(y => 22, z => 55))->to_string, "10:22:55, 30",
       "partial update to nested joindict");

    my $grandpa = Gnuplot::Builder::JoinDict->new(
        separator => "|", content => [x => "hoge", y => $parent]
    );
    is "$grandpa", "hoge|10:20, 30", "2 level nest";
}

done_testing;
