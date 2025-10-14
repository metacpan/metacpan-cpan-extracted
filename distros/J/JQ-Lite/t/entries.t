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

done_testing;
