use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json = q({
  "profile": {
    "name": "Alice",
    "age": 30
  },
  "tags": ["perl", "json"]
});

my @profile_entries = $jq->run_query($json, '.profile | to_entries');
is_deeply(
    $profile_entries[0],
    [
        { key => 'age',  value => 30 },
        { key => 'name', value => 'Alice' },
    ],
    'to_entries converts objects into key/value pairs'
);

my @tag_entries = $jq->run_query($json, '.tags | to_entries');
is_deeply(
    $tag_entries[0],
    [
        { key => 0, value => 'perl' },
        { key => 1, value => 'json' },
    ],
    'to_entries converts arrays using zero-based indexes'
);

my $entry_json = q([
  {"key": "name", "value": "Alice"},
  {"key": "role", "value": "admin"}
]);
my @from_entries = $jq->run_query($entry_json, 'from_entries');
is_deeply(
    $from_entries[0],
    { name => 'Alice', role => 'admin' },
    'from_entries rebuilds objects from entry hashes'
);

my $tuple_json = q([
  ["lang", "perl"],
  ["level", "pro"]
]);
my @from_tuple = $jq->run_query($tuple_json, 'from_entries');
is_deeply(
    $from_tuple[0],
    { lang => 'perl', level => 'pro' },
    'from_entries handles tuple-style entries'
);

my @filtered = $jq->run_query($json, '.profile | with_entries(select(.key != "age"))');
is_deeply(
    $filtered[0],
    { name => 'Alice' },
    'with_entries filters entries before reconstruction'
);

my @array_roundtrip = $jq->run_query('["perl", "json"]', 'to_entries | from_entries');
is_deeply(
    $array_roundtrip[0],
    ['perl', 'json'],
    'to_entries/from_entries round-trip arrays back to arrays'
);

my @numeric_key = $jq->run_query('[ {"key": 1, "value": "x"} ]', 'from_entries');
is_deeply(
    $numeric_key[0],
    { '1' => 'x' },
    'from_entries keeps sparse numeric keys as an object'
);

my @numeric_range = $jq->run_query(
    '[ {"key": 0, "value": "a"}, {"key": 1, "value": "b"} ]',
    'from_entries'
);
is_deeply(
    $numeric_range[0],
    [ 'a', 'b' ],
    'from_entries restores arrays for contiguous numeric keys'
);

my $non_array_ok = eval {
    $jq->run_query('"oops"', 'from_entries');
    1;
};
my $non_array_err = $@;
ok(!$non_array_ok, 'from_entries throws runtime error on non-array input');
like(
    $non_array_err,
    qr/^from_entries\(\): argument must be an array/,
    'runtime error message mentions array input'
);

my $bad_entry_ok = eval {
    $jq->run_query('[1]', 'from_entries');
    1;
};
my $bad_entry_err = $@;
ok(!$bad_entry_ok, 'from_entries throws runtime error when entry is not object/tuple');
like(
    $bad_entry_err,
    qr/^from_entries\(\): entry must be an object or \[key, value\] tuple/,
    'runtime error message mentions entry type'
);

my $bad_key_ok = eval {
    $jq->run_query('[ [{"nested":true}, 2] ]', 'from_entries');
    1;
};
my $bad_key_err = $@;
ok(!$bad_key_ok, 'from_entries throws runtime error when key is not string');
like(
    $bad_key_err,
    qr/^from_entries\(\): key must be a string/,
    'runtime error message mentions string key'
);

my $missing_value_ok = eval {
    $jq->run_query('[ {"key": "name"} ]', 'from_entries');
    1;
};
my $missing_value_err = $@;
ok(!$missing_value_ok, 'from_entries throws runtime error when value is missing');
like(
    $missing_value_err,
    qr/^from_entries\(\): entry is missing value/,
    'runtime error message mentions missing value'
);

done_testing;
