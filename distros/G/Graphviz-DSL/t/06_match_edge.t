use strict;
use warnings;
use Test::More;

use Graphviz::DSL;

subtest 'match edge with regexp(only start node)' => sub {
    my $graph = graph {
        route 'aa' => 'cc';
        route 'ab' => 'cc';
        route 'bb' => 'dc';
        route 'bb' => 'dd';

        edge [qr/^a.$/ => 'cc'], color => 'blue';
    };

    for my $edge (@{$graph->{edges}}) {
        my %attrs = map { $_->[0] => $_->[1] } @{$edge->attributes};

        if (($edge->start->id eq 'aa' || $edge->start->id eq 'ab')
             && $edge->end->id eq 'cc') {
            is $attrs{color}, 'blue', "matched start node";
        } else {
            ok !exists $attrs{color}, "not matched start node";
        }
    }
};

subtest 'match edge with regexp(only end node)' => sub {
    my $graph = graph {
        route 'aa' => 'cc';
        route 'ab' => 'cd';
        route 'aa' => 'dd';
        route 'ab' => 'dc';

        edge ['aa' => qr/^(.)\1$/], color => 'orange';
    };

    for my $edge (@{$graph->{edges}}) {
        my %attrs = map { $_->[0] => $_->[1] } @{$edge->attributes};

        if (($edge->end->id eq 'cc' || $edge->end->id eq 'dd')
             && $edge->start->id eq 'aa') {
            is $attrs{color}, 'orange', "matched end node";
        } else {
            ok !exists $attrs{color}, "not matched end node";
        }
    }
};

subtest 'match edge with regexp(start and end nodes)' => sub {
    my $graph = graph {
        route 'aa' => 'cc';
        route 'ab' => 'cd';
        route 'ba' => 'dc';
        route 'bb' => 'dd';

        edge [qr/^.b$/ => qr/^c.$/], color => 'green';
    };

    for my $edge (@{$graph->{edges}}) {
        my %attrs = map { $_->[0] => $_->[1] } @{$edge->attributes};

        if ($edge->start->id eq 'ab' && $edge->end->id eq 'cd') {
            is $attrs{color}, 'green', "matched both node:";
        } else {
            ok !exists $attrs{color}, "not matched both node:";
        }
    }
};

done_testing;
