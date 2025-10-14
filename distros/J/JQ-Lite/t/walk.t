use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $object_json = q({
  "name": "alice",
  "profile": {
    "roles": ["dev", "ops"],
    "note": "team lead"
  }
});

my @object_results = $jq->run_query($object_json, 'walk(upper)');

is_deeply(
    $object_results[0],
    {
        name    => 'ALICE',
        profile => {
            roles => [ 'DEV', 'OPS' ],
            note  => 'TEAM LEAD',
        },
    },
    'walk(upper) recursively uppercases nested string values'
);

my $array_json = q(["HELLO", ["WORLD", "PERL"]]);
my @array_results = $jq->run_query($array_json, 'walk(lower)');

is_deeply(
    $array_results[0],
    [ 'hello', [ 'world', 'perl' ] ],
    'walk(lower) applies filter recursively within nested arrays'
);

my @scalar_results = $jq->run_query('"hello"', 'walk(tostring)');

is(
    $scalar_results[0],
    'hello',
    'walk(tostring) applies filter to scalar values'
);

done_testing;
