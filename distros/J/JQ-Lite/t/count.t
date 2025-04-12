use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json = <<'JSON';
{
  "users": [
    { "name": "Alice", "age": 30 },
    { "name": "Bob",   "age": 22 },
    { "name": "Carol", "age": 19 }
  ]
}
JSON

my @res1 = $jq->run_query($json, '.users | count');
is_deeply(\@res1, [3], 'count users');

my @res2 = $jq->run_query($json, '.users[] | select(.age > 25) | count');
is_deeply(\@res2, [1], 'count users over 25');

done_testing;
