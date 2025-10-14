use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $json = q({
  "num": 42,
  "str": "hello",
  "flag": true,
  "maybe": null,
  "arr": [1, "two", false],
  "obj": {"name": "Alice", "age": 30}
});

my $jq = JQ::Lite->new;

my @number = $jq->run_query($json, '.num | tojson');
is($number[0], '42', 'tojson emits JSON for numeric scalars');

my @string = $jq->run_query($json, '.str | tojson');
is($string[0], '"hello"', 'tojson re-escapes plain strings as JSON text');

my @boolean = $jq->run_query($json, '.flag | tojson');
is($boolean[0], 'true', 'tojson encodes booleans using JSON literals');

my @null = $jq->run_query($json, '.maybe | tojson');
is($null[0], 'null', 'tojson encodes null/undef as the literal null');

my @array = $jq->run_query($json, '.arr | tojson');
my $decoded_array = JSON::PP->new->decode($array[0]);
is_deeply($decoded_array, [1, 'two', JSON::PP::false], 'tojson encodes arrays as JSON text');

my @object = $jq->run_query($json, '.obj | tojson');
my $decoded_object = JSON::PP->new->decode($object[0]);
is_deeply($decoded_object, { name => 'Alice', age => 30 }, 'tojson encodes objects as JSON text');

my @missing = $jq->run_query($json, '.missing? | tojson');
if (@missing) {
    is($missing[0], 'null', 'tojson treats optional missing values as JSON null');
} else {
    pass('optional path produced no results to encode');
}

my @raw = $jq->run_query('["foo", "bar"]', 'tojson');
is($raw[0], '["foo","bar"]', 'top-level arrays are encoded as JSON text');

my @raw_string = $jq->run_query('"hi"', 'tojson');
is($raw_string[0], '"hi"', 'top-level strings retain JSON escaping');

done_testing;
