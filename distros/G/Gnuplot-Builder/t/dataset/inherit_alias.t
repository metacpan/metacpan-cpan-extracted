use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

{
    note("--- parent() is alias of get_parent()");
    my $dataset = Gnuplot::Builder::Dataset->new;
    is $dataset->parent, undef, "no parent";
    my $child = $dataset->new_child;
    identical $child->parent, $dataset, "parent is dataset";
}

done_testing;

