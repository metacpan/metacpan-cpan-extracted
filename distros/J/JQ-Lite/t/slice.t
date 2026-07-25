use strict;
use warnings;

use Test::More;
use JQ::Lite;
use JSON::PP;

my $jq = JQ::Lite->new;

my $json = encode_json({ numbers => [10, 20, 30, 40, 50] });

my @result = $jq->run_query($json, '.numbers | slice(1, 2)');
is_deeply($result[0], [20, 30], 'slice(1, 2) returns middle segment');

@result = $jq->run_query($json, '.numbers | slice(3)');
is_deeply($result[0], [40, 50], 'slice(3) defaults length to array end');

@result = $jq->run_query($json, '.numbers | slice(-2, 1)');
is_deeply($result[0], [40], 'slice(-2, 1) supports negative start offsets');

@result = $jq->run_query($json, '.numbers | slice(10)');
is_deeply($result[0], [], 'slice start beyond array produces empty array');

@result = $jq->run_query($json, '.numbers | slice(-10, 2)');
is_deeply($result[0], [10, 20], 'slice clamps negative starts earlier than array length');

@result = $jq->run_query($json, '.numbers | slice(2, 0)');
is_deeply($result[0], [], 'slice with non-positive length is empty');

my $json_scalar = encode_json({ value => 42 });
@result = $jq->run_query($json_scalar, '.value | slice(1, 2)');
is($result[0], 42, 'slice leaves scalar values unchanged');

my $non_numeric_start_ok = eval { $jq->run_query($json, '.numbers | slice("nope", 2)') };
ok(!$non_numeric_start_ok && $@ =~ /slice\(\): start must be numeric/,
    'slice() rejects non-numeric start values');

my $non_numeric_length_ok = eval { $jq->run_query($json, '.numbers | slice(1, "nope")') };
ok(!$non_numeric_length_ok && $@ =~ /slice\(\): length must be numeric/,
    'slice() rejects non-numeric length values');

my $semicolon_length_ok = eval { $jq->run_query($json, '.numbers | slice(1; "2")') };
ok(!$semicolon_length_ok && $@ =~ /slice\(\): length must be numeric/,
    'slice() identifies a non-numeric semicolon-separated length');

@result = $jq->run_query($json, '.numbers[1:3]');
is_deeply($result[0], [20, 30], 'bracket slice uses an exclusive end bound');

@result = $jq->run_query($json, '.numbers[-2:-1]');
is_deeply($result[0], [40], 'bracket slice supports negative end bounds');

@result = $jq->run_query($json, '.numbers[2:]');
is_deeply($result[0], [30, 40, 50], 'bracket slice supports an omitted end bound');

my $bracket_start_ok = eval { $jq->run_query($json, '.numbers["1":2]') };
ok(!$bracket_start_ok && $@ =~ /slice\(\): start must be numeric/,
    'bracket slice rejects a non-numeric start');

my $spaced_bracket_start_ok = eval { $jq->run_query($json, '.numbers[ "1" : 2 ]') };
ok(!$spaced_bracket_start_ok && $@ =~ /slice\(\): start must be numeric/,
    'bracket slice validates spaced arguments');

my $bracket_length_ok = eval { $jq->run_query($json, '.numbers[1:"2"]') };
ok(!$bracket_length_ok && $@ =~ /slice\(\): length must be numeric/,
    'bracket slice rejects a non-numeric length');


done_testing();
