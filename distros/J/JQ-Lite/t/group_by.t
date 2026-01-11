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

my @res = $jq->run_query($json, 'group_by(.team)');

is_deeply($res[0], [
  [
    { name => "Alice", team => "A" },
    { name => "Carol", team => "A" }
  ],
  [
    { name => "Bob", team => "B" }
  ]
], 'group_by(.team) groups sorted keys');

my $scalar_keys = <<'JSON';
[
  { "k": 1, "v": "a" },
  { "k": 1, "v": "b" },
  { "k": 2, "v": "c" }
]
JSON

@res = $jq->run_query($scalar_keys, 'group_by(.k)');
is_deeply($res[0], [
  [
    { k => 1, v => "a" },
    { k => 1, v => "b" }
  ],
  [
    { k => 2, v => "c" }
  ]
], 'group_by(.k) handles scalar keys');

my $array_keys = <<'JSON';
[
  { "k": [1, 2], "v": 1 },
  { "k": [1, 2], "v": 2 },
  { "k": [2, 3], "v": 9 }
]
JSON

@res = $jq->run_query($array_keys, 'group_by(.k)');
is_deeply($res[0], [
  [
    { k => [1, 2], v => 1 },
    { k => [1, 2], v => 2 }
  ],
  [
    { k => [2, 3], v => 9 }
  ]
], 'group_by(.k) handles array keys');

my $null_keys = <<'JSON';
[
  { "k": null, "v": 1 },
  { "k": 2, "v": 2 },
  { "k": null, "v": 3 }
]
JSON

@res = $jq->run_query($null_keys, 'group_by(.k)');
is_deeply($res[0], [
  [
    { k => undef, v => 1 },
    { k => undef, v => 3 }
  ],
  [
    { k => 2, v => 2 }
  ]
], 'group_by(.k) handles null keys');

my $not_array = '{"k": 1}';
eval { $jq->run_query($not_array, 'group_by(.k)') };
like($@, qr/group_by\(\): input must be an array/, 'group_by(.k) errors on non-array input');

done_testing;
