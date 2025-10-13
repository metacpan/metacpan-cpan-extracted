use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "users": [
    { "name": "Alice", "age": 30 },
    { "name": "Bob",   "age": 20 },
    { "name": "Carol", "age": 25 }
  ]
}
JSON

my $jq = JQ::Lite->new;

my @result = $jq->run_query($json, '.users | max_by(.age) | .name');
is_deeply(
    \@result,
    ['Alice'],
    'max_by(.age) returns user with the largest age',
);

@result = $jq->run_query($json, '.users | min_by(.age) | .name');
is_deeply(
    \@result,
    ['Bob'],
    'min_by(.age) returns user with the smallest age',
);

@result = $jq->run_query($json, '.users | max_by(.name) | .name');
is_deeply(
    \@result,
    ['Carol'],
    'max_by(.name) compares projected string values',
);

my $numbers = '[3, 10, 7, -2]';

@result = $jq->run_query($numbers, '. | max_by(.)');
is_deeply(
    \@result,
    [10],
    'max_by(.) on scalars returns the largest numeric value',
);

@result = $jq->run_query($numbers, '. | min_by(.)');
is_deeply(
    \@result,
    [-2],
    'min_by(.) on scalars returns the smallest numeric value',
);

@result = $jq->run_query($json, '.users | min_by(.missing)');

is(scalar @result, 1, 'min_by with missing path still returns a single result');
ok(!defined $result[0], 'min_by(.missing) yields undef when no values are comparable');

done_testing();
