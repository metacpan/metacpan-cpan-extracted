use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $object_json = q({
  "meta": {
    "version": "1.0",
    "author": "you"
  }
});

my $array_json = q({
  "items": [10, 20, 30]
});

my $jq = JQ::Lite->new;

my ($has_version) = $jq->run_query($object_json, '.meta | has("version")');
my ($missing_key) = $jq->run_query($object_json, '.meta | has("missing")');
my ($has_index)   = $jq->run_query($array_json, '.items | has(1)');
my ($bad_index)   = $jq->run_query($array_json, '.items | has(5)');
my ($non_numeric) = $jq->run_query($array_json, '.items | has("value")');

ok($has_version, 'hash has the requested key');
ok(!$missing_key, 'hash missing key returns false');
ok($has_index, 'array reports existing index');
ok(!$bad_index, 'array reports missing index as false');
ok(!$non_numeric, 'array returns false for non-numeric argument');

done_testing;
