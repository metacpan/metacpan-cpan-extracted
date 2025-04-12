use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json = <<'JSON';
[
  { "name": "Alice", "team": "A" },
  { "name": "Bob",   "team": "B" },
  { "name": "Carol", "team": "A" }
]
JSON

my @res = $jq->run_query($json, 'group_by(team)');

is_deeply($res[0], {
  A => [
    { name => "Alice", team => "A" },
    { name => "Carol", team => "A" }
  ],
  B => [
    { name => "Bob", team => "B" }
  ]
}, 'group_by(team) works as expected');

done_testing;
