use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

{
    note("--- parent() is alias of get_parent()");
    my $builder = Gnuplot::Builder::Script->new;
    is $builder->parent, undef, "no parent";
    my $child = $builder->new_child;
    identical $child->parent, $builder, "parent is builder";
}

done_testing;

