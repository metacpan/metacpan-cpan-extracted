use strict;
use warnings;
use Test::More;

use Graphviz::DSL;

subtest 'match node with regexp' => sub {
    my $graph = graph {
        add 'aa';
        add 'ab';
        add 'bb';
        add 'bd';

        node qr/^a.$/, color => 'red';
    };

    for my $node (@{$graph->{nodes}}) {
        my %attrs = map { $_->[0] => $_->[1] } @{$node->attributes};

        if ($node->id =~ m{^a.$}) {
            is $attrs{color}, 'red', "matched node:" . $node->id;
        } else {
            ok !exists $attrs{color}, "not matched node:" . $node->id;
        }
    }
};

done_testing;
