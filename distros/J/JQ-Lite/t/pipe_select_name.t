use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json = <<'JSON';
[
  { "name": "Alice", "age": 30 },
  { "name": "Bob",   "age": 20 },
  { "name": "Carol", "age": 25 }
]
JSON

my @res = $jq->run_query($json, '.[] | select(.age > 21) | .name');

is_deeply(\@res, ["Alice", "Carol"], 'Pipe with .[] | select | .name works correctly');

done_testing;
