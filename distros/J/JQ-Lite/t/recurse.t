use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

subtest 'recurse without filter traverses nested values' => sub {
    my $json = q({
      "name": "alice",
      "roles": ["dev", "ops"]
    });

    my @results = $jq->run_query($json, 'recurse');

    is(scalar @results, 5, 'emits every node including scalars');
    is_deeply($results[0], { name => 'alice', roles => [ 'dev', 'ops' ] }, 'first result is original object');
    is($results[1], 'alice', 'visits string value before nested array');
    is_deeply($results[2], [ 'dev', 'ops' ], 'visits nested array');
    is($results[3], 'dev', 'visits first array element');
    is($results[4], 'ops', 'visits second array element');
};

subtest 'recurse with filter follows custom child relationships' => sub {
    my $tree_json = q({
      "name": "root",
      "children": [
        { "name": "child1" },
        { "name": "child2", "children": [ { "name": "grand" } ] }
      ]
    });

    my @names = $jq->run_query($tree_json, 'recurse(.children[]?) | .name');

    is_deeply(\@names, [ 'root', 'child1', 'child2', 'grand' ], 'traverses tree depth-first applying child filter');
};

done_testing;
