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

my @non_array = $jq->run_query('"scalar"', 'getpath([0])');
ok(!defined $non_array[0], 'getpath returns undef when traversing non-container with path');

my @multi_literal = $jq->run_query($json, '.profile | getpath([["name"], ["age"]])');
is_deeply($multi_literal[0], ['Alice', 30], 'getpath returns arrayref when multiple literal paths supplied');

done_testing;
