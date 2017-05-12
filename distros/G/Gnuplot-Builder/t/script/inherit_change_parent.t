use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

{
    my @parents = (
        Gnuplot::Builder::Script->new,
        Gnuplot::Builder::Script->new
    );
    $parents[0]->set(a => "a0", b => "b0");
    $parents[1]->set(b => "b1", a => "a1");
    my $child = $parents[0]->new_child;
    identical $child->get_parent, $parents[0], "parent is now 0";

    $child->set(a => "A");
    is $child->to_string, <<EXP, "child is based on parent 0";
set a A
set b b0
EXP

    identical $child->set_parent($parents[1]), $child, "set_parent() should return the object";
    identical $child->get_parent, $parents[1], "parent is now 1";
    is $child->to_string, <<EXP, "child is based on parent 1";
set b b1
set a A
EXP
    identical $child->set_parent(undef), $child, "set_parent() should return the object";
    identical $child->get_parent, undef, "no parent";
    is $child->to_string, <<EXP, "child is now on its own";
set a A
EXP
}

done_testing;
