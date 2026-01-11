use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "tags": ["perl", "json", "cli"],
  "title": "jq-lite in perl",
  "meta": {"lang": "perl", "stable": true},
  "nested": {"config": {"theme": "dark", "size": "m"}},
  "numbers": [1, 2, 3],
  "missing": null
});

my $jq = JQ::Lite->new;

my @tag_true  = $jq->run_query($json, '.tags | contains("perl")');
my @tag_false = $jq->run_query($json, '.tags | contains("python")');
my @num_true  = $jq->run_query($json, '.numbers | contains(2)');
my @title_true = $jq->run_query($json, '.title | contains("perl")');
my @meta_true  = $jq->run_query($json, '.meta | contains("lang")');
my @nested_exact = $jq->run_query($json, '.nested | contains({"config": {"theme": "dark", "size": "m"}})');
my @nested_partial = $jq->run_query($json, '.nested | contains({"config": {"theme": "dark"}})');
my @missing    = $jq->run_query($json, '.missing | contains("anything")');
my @null_true  = $jq->run_query($json, '.missing | contains(null)');
my @null_on_string = $jq->run_query($json, '.title | contains(null)');

ok($tag_true[0], 'array contains existing value');
ok(!$tag_false[0], 'array does not contain missing value');
ok($num_true[0], 'numeric array contains number');
ok($title_true[0], 'string contains substring');
ok($meta_true[0], 'hash contains key');
ok($nested_exact[0], 'hash contains nested object with exact match');
ok(!$nested_partial[0], 'contains does not perform deep subset matching for nested objects');
ok(!$missing[0], 'null value does not contain substring');
ok($null_true[0], 'null contains null');
ok(!$null_on_string[0], 'string does not contain null');

done_testing;
