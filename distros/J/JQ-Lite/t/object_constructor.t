use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
[
  {"name": "Alice", "age": 30},
  {"name": "Bob",   "age": 25}
]
JSON

my $jq = JQ::Lite->new;

my @results = $jq->run_query($json, '.[] | {"name": .name}');

is_deeply(
    \@results,
    [
        { name => 'Alice' },
        { name => 'Bob' },
    ],
    'object constructor builds hashes with selected fields',
);

@results = $jq->run_query($json, '.[] | {name: .nickname}');

is_deeply(
    \@results,
    [
        { name => undef },
        { name => undef },
    ],
    'missing values are represented as null entries in constructed objects',
);

@results = $jq->run_query($json, '.[] | {}');

is_deeply(
    \@results,
    [ {}, {} ],
    'empty object constructors yield empty hashes for each input',
);

done_testing();
