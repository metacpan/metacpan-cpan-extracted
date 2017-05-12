use strict;
use warnings;
use Test::More;

use Graphviz::DSL;

subtest 'call outside graph function' => sub {
    my @funcs = qw/route add node edge nodes edges nodeset edgeset global rank
                   name type subgraph/;
    for my $method (@funcs) {
        eval {
            Graphviz::DSL->$method();
        };
        like $@, qr/Can't call $method/, "Can't call '$method'";
    }
};

done_testing;
