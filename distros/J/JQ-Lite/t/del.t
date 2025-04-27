use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "profile": {
    "name": "Alice",
    "age": 30,
    "password": "secret"
  }
}
JSON

my $jq = JQ::Lite->new;

my @result = $jq->run_query($json, '.profile | del("password")');

is_deeply(
    $result[0],
    {
        "name" => "Alice",
        "age" => 30
    },
    'deleted password field'
);

done_testing();

