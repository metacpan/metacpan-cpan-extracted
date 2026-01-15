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
  { "name": "Carol", "team": "A" },
  { "name": "Dave",  "team": "B" },
  { "name": "Eve",   "team": "A" }
]
JSON

my @res = $jq->run_query($json, 'group_count(team)');

is_deeply(
    $res[0],
    {
        A => 3,
        B => 2,
    },
    'group_count(team) tallies members per team'
);

@res = $jq->run_query($json, 'group_count(.team)');

is_deeply(
    $res[0],
    {
        A => 3,
        B => 2,
    },
    'group_count(.team) accepts dotted path syntax'
);

@res = $jq->run_query($json, 'group_count(nickname)');

is_deeply(
    $res[0],
    {
        null => 5,
    },
    'group_count on missing key reports null bucket'
);

my $json_strings = <<'JSON';
["red", "blue", "red"]
JSON

@res = $jq->run_query($json_strings, 'group_count(.)');

is_deeply(
    $res[0],
    {
        red  => 2,
        blue => 1,
    },
    'group_count(.) counts entire values for scalar arrays'
);

done_testing;
