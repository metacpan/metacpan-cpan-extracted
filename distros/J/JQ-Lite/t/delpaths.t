use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

# --- 1. Delete multiple paths from an object
my $json_object = <<'JSON';
{
  "profile": {
    "name": "Alice",
    "password": "secret",
    "tokens": ["abc", "def"]
  }
}
JSON

my @result_object = $jq->run_query(
    $json_object,
    '.profile | delpaths([["password"], ["tokens", 0]])'
);

is_deeply(
    $result_object[0],
    {
        "name"   => "Alice",
        "tokens" => ["def"],
    },
    'delpaths removes multiple keys and array entries from objects'
);

# --- 2. Delete array entries by index
my $json_array = <<'JSON';
{
  "items": [
    {"id": 1},
    {"id": 2},
    {"id": 3}
  ]
}
JSON

my @result_array = $jq->run_query($json_array, '.items | delpaths([[1]])');

is_deeply(
    $result_array[0],
    [
        {"id" => 1},
        {"id" => 3},
    ],
    'delpaths removes array elements by index'
);

# --- 3. Removing the root path yields null
my $json_scalar = '{"keep": true}';
my @result_null = $jq->run_query($json_scalar, '. | delpaths([[]])');

ok(!defined $result_null[0], 'delpaths with empty path removes the entire value');

my $error = eval { $jq->run_query($json_object, '.profile | delpaths("password")'); 1 };
ok(!$error, 'delpaths throws on non-array paths argument');
like(
    $@,
    qr/^delpaths\(\): paths must be an array of path arrays/,
    'delpaths error message indicates array-of-array requirement'
);

$error = eval { $jq->run_query($json_object, '.profile | delpaths(["password"])'); 1 };
ok(!$error, 'delpaths throws when paths list is not an array of arrays');
like(
    $@,
    qr/^delpaths\(\): paths must be an array of path arrays/,
    'delpaths rejects paths arrays containing non-array entries'
);

$error = eval {
    $jq->run_query(
        $json_object,
        '.profile | delpaths([["name", {"nested":true}]])'
    );
    1;
};
ok(!$error, 'delpaths throws when any path segment is non-scalar');
like(
    $@,
    qr/^delpaths\(\): path elements must be scalars/,
    'delpaths rejects non-scalar path segments'
);

$error = eval { $jq->run_query($json_object, '.profile | delpaths([[null]])'); 1 };
ok(!$error, 'delpaths throws when a path contains an undefined/null segment');
like(
    $@,
    qr/^delpaths\(\): path elements must be defined/,
    'delpaths rejects null path elements'
);

done_testing;

