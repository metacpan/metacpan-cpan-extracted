use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;

note("--- deep inheritance");

{
    my $origin = Gnuplot::Builder::Script->new;
    my $descendent = $origin->new_child;
    for (1..1000) {
        $descendent = $descendent->new_child;
    }
    $origin->set(a => "A");
    is_deeply [$descendent->get_option("a")], ["A"], "get value all the way from the origin OK";
    is $descendent->to_string, "set a A\n", "to_string all the way from the origin OK";
}

done_testing;
