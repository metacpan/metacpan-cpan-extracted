use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "users": [
    { "name": "Alice", "email": "alice@example.com" },
    { "name": "Bob",   "email": "bob@admin.com" },
    { "name": "Carol", "email": "carol@example.org" }
  ]
});

my $jq = JQ::Lite->new;

my @matched_bob   = $jq->run_query($json, '.users[] | select(.name match "Bob")');
my @matched_admin = $jq->run_query($json, '.users[] | select(.email match "^bob@")');
my @matched_fail  = $jq->run_query($json, '.users[] | select(.name match "David")');

is($matched_bob[0]{name}, 'Bob', 'matched user name = Bob');
is($matched_admin[0]{email}, 'bob@admin.com', 'matched email start with bob@');
ok(!@matched_fail, 'no match for David');

my $regex_error;
eval { $jq->run_query($json, '.users[] | select(.name match "[")'); 1 };
$regex_error = $@;
like(
    $regex_error,
    qr/match\(\): invalid regular expression/i,
    'match() reports errors for invalid regular expressions'
);

my $match_fn_error;
eval { $jq->run_query('"abc"', 'match("[")'); 1 };
$match_fn_error = $@;
like(
    $match_fn_error,
    qr/match\(\): invalid regular expression/i,
    'match() function reports errors for invalid regular expressions'
);

my $invalid_flag_error;
eval { $jq->run_query('"abc"', 'match("a"; "z")'); 1 };
$invalid_flag_error = $@;
like(
    $invalid_flag_error,
    qr/match\(\): invalid regular expression - unknown regex flag 'z'/,
    'match() reports errors for unknown regex flags'
);

my $match_in_select_error;
eval { $jq->run_query('"abc"', 'select(match("[") )'); 1 };
$match_in_select_error = $@;
like(
    $match_in_select_error,
    qr/match\(\): invalid regular expression/i,
    'match() inside select reports errors for invalid regular expressions'
);

my $regex_op_error;
eval { $jq->run_query('"abc"', 'select(. =~ "[")'); 1 };
$regex_op_error = $@;
like(
    $regex_op_error,
    qr/invalid regular expression/i,
    '=~ operator reports errors for invalid regular expressions'
);

my @regex_op_match = $jq->run_query('"abc"', 'select(. =~ "^a")');
is_deeply(\@regex_op_match, [ 'abc' ], '=~ operator matches strings');

my $test_in_select_error;
eval { $jq->run_query('"abc"', 'select(test("[") )'); 1 };
$test_in_select_error = $@;
like(
    $test_in_select_error,
    qr/test\(\): invalid regular expression/i,
    'test() inside select reports errors for invalid regular expressions',
);

my @multiline_match = $jq->run_query('"alpha\nbeta"', 'match("^beta"; "m")');
is_deeply(
    $multiline_match[0],
    {
        offset   => 6,
        length   => 4,
        string   => 'beta',
        captures => [],
    },
    'match() honors multiline flag (m) for anchors',
);

my @multiline_default = $jq->run_query('"alpha\nbeta"', 'match("^beta")');
ok(!$multiline_default[0], 'match() defaults to single-line anchors without m');

my @dotall_match = $jq->run_query('"a\nb"', 'match("a.*b"; "s")');
is_deeply(
    $dotall_match[0],
    {
        offset   => 0,
        length   => 3,
        string   => "a\nb",
        captures => [],
    },
    'match() honors dotall flag (s) for newlines',
);

my @dotall_default = $jq->run_query('"a\nb"', 'match("a.*b")');
ok(!$dotall_default[0], 'match() defaults to non-dotall behavior without s');

my @extended_match = $jq->run_query('"ab"', 'match("a b"; "x")');
is_deeply(
    $extended_match[0],
    {
        offset   => 0,
        length   => 2,
        string   => 'ab',
        captures => [],
    },
    'match() honors extended flag (x) for whitespace',
);

my @extended_default = $jq->run_query('"ab"', 'match("a b")');
ok(!$extended_default[0], 'match() treats whitespace literally without x');

my @captures_match = $jq->run_query('"abc123"', 'match("([a-z]+)([0-9]+)")');
is_deeply(
    $captures_match[0],
    {
        offset   => 0,
        length   => 6,
        string   => 'abc123',
        captures => [
            {
                offset => 0,
                length => 3,
                string => 'abc',
            },
            {
                offset => 3,
                length => 3,
                string => '123',
            },
        ],
    },
    'match() returns capture group details',
);

done_testing;
