use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $structure = {
    profile => {
        name   => 'Alice',
        age    => 30,
        emails => [
            'alice@example.com',
            'alice.work@example.com',
        ],
        meta => {
            active => JSON::PP::true,
        },
    },
};

my $json = encode_json($structure);

my $jq = JQ::Lite->new;

my @name = $jq->run_query($json, '.profile | getpath(["name"])');
is($name[0], 'Alice', 'getpath retrieves nested object key');

my @email = $jq->run_query($json, '.profile | getpath(["emails", 1])');
is($email[0], 'alice.work@example.com', 'getpath retrieves nested array index');

my @missing = $jq->run_query($json, '.profile | getpath(["missing"])');
ok(!defined $missing[0], 'getpath returns undef for missing path');

my @whole = $jq->run_query($json, '.profile | getpath([])');
is_deeply($whole[0], $structure->{profile}, 'getpath([]) returns entire input value');

my @paths_value = $jq->run_query($json, '.profile | getpath(paths())');
my $expected = [
    $structure->{profile}{age},
    $structure->{profile}{emails},
    @{$structure->{profile}{emails}},
    $structure->{profile}{meta},
    $structure->{profile}{meta}{active},
    $structure->{profile}{name},
];

is_deeply($paths_value[0], $expected, 'getpath resolves every path yielded by paths()');

my @boolean_path = $jq->run_query($json, '.profile | getpath(["meta", "active"])');
ok($boolean_path[0], 'getpath handles JSON::PP::Boolean values');

my @negative_index = $jq->run_query($json, '.profile | getpath(["emails", -1])');
is($negative_index[0], 'alice.work@example.com', 'getpath supports negative indices for arrays');

my $boolean_keys = encode_json({ true => 'yes', false => 'no' });
my @bool_true  = $jq->run_query($boolean_keys, 'getpath([true])');
my @bool_false = $jq->run_query($boolean_keys, 'getpath([false])');

is($bool_true[0], 'yes', 'getpath resolves boolean true key to string key');
is($bool_false[0], 'no', 'getpath resolves boolean false key to string key');

my $boolean_indices = q([10, 20, 30]);
my @bool_index_zero = $jq->run_query($boolean_indices, 'getpath([false])');
my @bool_index_one  = $jq->run_query($boolean_indices, 'getpath([true])');

is($bool_index_zero[0], 10, 'getpath treats boolean false as index 0');
is($bool_index_one[0], 20, 'getpath treats boolean true as index 1');

my @non_array = $jq->run_query('"scalar"', 'getpath([0])');
ok(!defined $non_array[0], 'getpath returns undef when traversing non-container with path');

my @multi_literal = $jq->run_query($json, '.profile | getpath([["name"], ["age"]])');
is_deeply($multi_literal[0], ['Alice', 30], 'getpath returns arrayref when multiple literal paths supplied');

my $error = eval { $jq->run_query($json, '.profile | getpath("name")'); 1 };
ok(!$error, 'getpath throws on non-array path argument');
like($@, qr/^getpath\(\): path must be an array/, 'error message indicates array requirement');

done_testing;
