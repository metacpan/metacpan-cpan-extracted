use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "tags": ["perl", "json", "cli"],
  "title": "jq-lite in perl",
  "meta": {"lang": "perl", "stable": true},
  "numbers": [1, 2, 3],
  "missing": null
});

my $jq = JQ::Lite->new;

my @inside_tags     = $jq->run_query($json, '.tags[0] | inside(["perl", "python"])');
my @inside_missing  = $jq->run_query($json, '.tags[0] | inside(["python", "ruby"])');
my @inside_meta_key = $jq->run_query($json, '.meta | inside({"lang": "perl", "stable": true})');
my @inside_title    = $jq->run_query($json, '.title | inside("jq-lite in perl")');
my @inside_number   = $jq->run_query($json, '.numbers[1] | inside([1, 2, 3])');
my @null_inside     = $jq->run_query($json, '.missing | inside(null)');
my @not_in_null     = $jq->run_query($json, '.title | inside(null)');

ok($inside_tags[0], 'value is inside array');
ok(!$inside_missing[0], 'value missing from array');
ok($inside_meta_key[0], 'object is subset of container');
ok($inside_title[0], 'substring is inside string');
ok($inside_number[0], 'number found inside numeric array');
ok($null_inside[0], 'null is inside identical null container');
ok(!$not_in_null[0], 'non-null value is not inside null container');

done_testing;
