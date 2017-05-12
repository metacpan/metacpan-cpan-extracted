use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;
use lib "t";
use testlib::DatasetUtil qw(get_data);

{
    note("--- change parent by set_parent()");
    my @parent = (
        Gnuplot::Builder::Dataset->new('cos(x)', title => q{'parent 0'}),
        Gnuplot::Builder::Dataset->new('sin(x)', title => q{'parent 1'}),
    );
    $parent[0]->set_data("0 100");
    $parent[1]->set_data("1 111");

    my $child = Gnuplot::Builder::Dataset->new(undef, with => "lines");
    is $child->get_parent, undef, "parent() returns undef it's not a child";
    is $child->to_string, "with lines", "no inheritance for params";
    is get_data($child), "", "no inheritance for data";

    identical $child->set_parent($parent[0]), $child, "set_parent() retunrs the dataset";
    identical $child->get_parent, $parent[0], "parent() returns the parent";
    is $child->to_string, "cos(x) title 'parent 0' with lines", "inherit params from parent0";
    is get_data($child), "0 100", "inherit data from parent0";

    $child->set_parent($parent[1]);
    identical $child->get_parent, $parent[1], "now parent is parent1";
    is $child->to_string, "sin(x) title 'parent 1' with lines", "inherit params from parent1";
    is get_data($child), "1 111", "inherit data from parent1";
}

done_testing;
