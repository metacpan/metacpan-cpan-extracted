use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $jq = JQ::Lite->new;

# --- 1. Empty array
my $json1 = '[]';
my @result1 = $jq->run_query($json1, 'is_empty');
ok($result1[0], 'is_empty() returns true for empty array');

# --- 2. Non-empty array
my $json2 = '[1,2,3]';
my @result2 = $jq->run_query($json2, 'is_empty');
ok(!$result2[0], 'is_empty() returns false for non-empty array');

# --- 3. Empty hash
my $json3 = '{}';
my @result3 = $jq->run_query($json3, 'is_empty');
ok($result3[0], 'is_empty() returns true for empty hash');

# --- 4. Non-empty hash
my $json4 = '{"key":"value"}';
my @result4 = $jq->run_query($json4, 'is_empty');
ok(!$result4[0], 'is_empty() returns false for non-empty hash');

subtest 'non-collection values return false' => sub {
    my @string = $jq->run_query('" "', 'is_empty');
    ok(!$string[0], 'is_empty() returns false for strings');

    my @number = $jq->run_query('42', 'is_empty');
    ok(!$number[0], 'is_empty() returns false for numbers');

    my @bool = $jq->run_query('true', 'is_empty');
    ok(!$bool[0], 'is_empty() returns false for booleans');

    my @null_value = $jq->run_query('null', 'is_empty');
    ok(!$null_value[0], 'is_empty() returns false for null');
};

subtest 'collections with contents are not empty' => sub {
    my @nested_array = $jq->run_query('[[]]', 'is_empty');
    ok(!$nested_array[0], 'is_empty() treats arrays with elements as non-empty');

    my @empty_string_array = $jq->run_query('[""]', 'is_empty');
    ok(!$empty_string_array[0], 'is_empty() treats arrays with empty strings as non-empty');

    my @empty_object_value = $jq->run_query('{"key":{}}', 'is_empty');
    ok(!$empty_object_value[0], 'is_empty() treats objects with keys as non-empty');
};

done_testing;
