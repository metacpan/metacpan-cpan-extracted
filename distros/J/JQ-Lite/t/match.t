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

done_testing;
