use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "name": "Alice",
  "age": 30,
  "active": true,
  "profile": {
    "country": "US"
  },
  "tags": ["perl", "json"],
  "empty": null
}
JSON

my $jq = JQ::Lite->new;

is_deeply([$jq->run_query($json, '.name | type')], ['string'], 'type of string');
is_deeply([$jq->run_query($json, '.age | type')], ['number'], 'type of number');
is_deeply([$jq->run_query($json, '.active | type')], ['boolean'], 'type of boolean');
is_deeply([$jq->run_query($json, '.profile | type')], ['object'], 'type of object');
is_deeply([$jq->run_query($json, '.tags | type')], ['array'], 'type of array');
is_deeply([$jq->run_query($json, '.empty | type')], ['null'], 'type of null');

done_testing();

