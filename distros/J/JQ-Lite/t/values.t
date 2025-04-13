use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $json = <<'JSON';
{
  "profile": {
    "name": "Alice",
    "age": 30,
    "active": true
  }
}
JSON

my $jq = JQ::Lite->new;
my @result = $jq->run_query($json, '.profile | values');

ok(ref($result[0]) eq 'ARRAY', 'values() returns arrayref');

my $vals = $result[0];
my %seen;
$seen{$_}++ for @$vals;

ok($seen{'Alice'} && $seen{30} && $seen{JSON::PP::true}, 'values contain Alice, 30, and true');

done_testing();
