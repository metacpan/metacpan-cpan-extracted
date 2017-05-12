use strict;
use warnings;
use Test::More;

use Graphviz::DSL;

sub _any {
    my ($got, $expecteds) = @_;

    for my $e (@{$expecteds}) {
        if ($got->[0] eq $e->[0] && $got->[1] eq $e->[1]) {
            return 1;
        }
    }

    return 0;
}

subtest 'multi route' => sub {
    my $graph = graph {
        multi_route +{
            a => [qw/b c/],
            d => 'e',
            f => {
                g => { h => 'i'},
                j => 'k',
            },
        };
    };

    my @expected = (
        [a => 'b'], [a => 'c'],
        [d => 'e'],
        [f => 'g'], [g => 'h'], [h => 'i'],
        [f => 'j'], [j => 'k'],
    );

    for my $edge (@{$graph->{edges}}) {
        my ($start_id, $end_id) = ($edge->start->id, $edge->end->id);
        ok _any([$start_id, $end_id], \@expected), "add $start_id => $end_id";
    }
};

subtest 'invalid argument' => sub {
    eval {
        my $graph = graph {
            multi_route [];
        };
    };

    like $@, qr/should take 'HashRef'/, 'Invalid data type';
};

done_testing;
