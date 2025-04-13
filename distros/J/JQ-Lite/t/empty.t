use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = <<'JSON';
{
  "users": [
    { "name": "Alice", "age": 30 },
    { "name": "Bob", "age": 25 }
  ]
}
JSON

my $jq = JQ::Lite->new;
my @result = $jq->run_query($json, '.users | empty');

is_deeply(\@result, [], 'empty() returns no results');

done_testing();

