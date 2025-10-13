use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "score": "42",
  "raw": "n/a",
  "flag": true,
  "nested": [["10", "oops"], [false, "0"]],
  "maybe": null
});

my $jq = JQ::Lite->new;

my @scalar = $jq->run_query($json, '.score | to_number');
is($scalar[0], 42, 'to_number converts numeric strings to numbers');
ok(!ref $scalar[0], 'to_number returns plain scalars for converted values');

my @boolean = $jq->run_query($json, '.flag | to_number');
is($boolean[0], 1, 'to_number converts JSON booleans to numeric values');

my @string = $jq->run_query($json, '.raw | to_number');
is($string[0], 'n/a', 'non-numeric strings remain unchanged');

my @array = $jq->run_query($json, '.nested | to_number');
is_deeply(
    $array[0],
    [[10, 'oops'], [0, 0]],
    'to_number recurses through arrays preserving non-numeric entries'
);

my @maybe = $jq->run_query($json, '.maybe | to_number');
ok(!defined $maybe[0], 'undef/null input stays undef after to_number');

my @missing = $jq->run_query($json, '.missing? | to_number');
ok(!defined $missing[0], 'optional keys remain undef when absent');

done_testing;
