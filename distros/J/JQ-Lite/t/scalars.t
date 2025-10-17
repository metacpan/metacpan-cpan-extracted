use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "items": [
    "text",
    42,
    true,
    null,
    {"note": "object"},
    [1, 2, 3]
  ],
  "flag": false
}
JSON

my $jq = JQ::Lite->new;
my @results = $jq->run_query($json, '.items[] | scalars');

is(scalar @results, 4, 'scalars emits only scalar entries from arrays');
is($results[0], 'text', 'scalars keeps string values');
is($results[1], 42, 'scalars keeps numeric values');
isa_ok($results[2], 'JSON::PP::Boolean', 'scalars preserves boolean objects');
ok(!defined $results[3], 'scalars keeps null values as undef');

@results = $jq->run_query($json, '.items | scalars');
is_deeply(\@results, [], 'scalars yields no output for array containers');

@results = $jq->run_query($json, '.flag | scalars');
isa_ok($results[0], 'JSON::PP::Boolean', 'scalars passes through scalar booleans');
ok(!$results[0], 'boolean false survives scalars filter');

done_testing();
