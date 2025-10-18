use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "users": [
    {"name": "Alice", "age": 30, "tags": ["perl", "jq"]},
    {"name": "Bob", "age": 25}
  ]
}
JSON

my $jq = JQ::Lite->new;

my @results = $jq->run_query($json, '.users[] | [.name, .age]');

is_deeply(
    \@results,
    [
        [ 'Alice', 30 ],
        [ 'Bob',   25 ],
    ],
    'array constructor collects multiple fields from the same object',
);

@results = $jq->run_query($json, '.users[] | [.name, .nickname]');

is_deeply(
    \@results,
    [
        [ 'Alice', undef ],
        [ 'Bob',   undef ],
    ],
    'missing values become null entries inside constructed arrays',
);

@results = $jq->run_query($json, '.users[0] | [.name, .tags[]]');

is_deeply(
    \@results,
    [ [ 'Alice', 'perl', 'jq' ] ],
    'array constructor appends multiple outputs from a single expression',
);

@results = $jq->run_query($json, '.users[] | []');

is_deeply(
    \@results,
    [ [], [] ],
    'empty constructors yield empty arrays for each input',
);

done_testing();
