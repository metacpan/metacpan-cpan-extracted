use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $json = q({
  "num": 42,
  "str": "hello",
  "flag": false,
  "maybe": null,
  "arr": [1, "two", true],
  "obj": {"name": "Alice", "age": 30}
});

my $jq = JQ::Lite->new;

my @number = $jq->run_query($json, '.num | tostring');
is($number[0], '42', 'tostring converts numbers to their string form');

my @string = $jq->run_query($json, '.str | tostring');
is($string[0], 'hello', 'tostring leaves existing strings unchanged');

my @boolean = $jq->run_query($json, '.flag | tostring');
is($boolean[0], 'false', 'tostring stringifies booleans using JSON literals');

my @null = $jq->run_query($json, '.maybe | tostring');
is($null[0], 'null', 'tostring renders null/undef as the literal "null"');

my @array = $jq->run_query($json, '.arr | tostring');
my $decoded_array = JSON::PP->new->decode($array[0]);
is_deeply($decoded_array, [1, 'two', JSON::PP::true], 'tostring encodes arrays as JSON text');

my @object = $jq->run_query($json, '.obj | tostring');
my $decoded_object = JSON::PP->new->decode($object[0]);
is_deeply($decoded_object, { name => 'Alice', age => 30 }, 'tostring encodes objects as JSON text');

my @missing = $jq->run_query($json, '.missing? | tostring');
if (@missing) {
    is($missing[0], 'null', 'tostring treats optional missing values as null');
} else {
    pass('optional path produced no results to stringify');
}

done_testing;
