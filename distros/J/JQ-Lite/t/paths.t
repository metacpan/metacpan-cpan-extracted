use strict;
use warnings;
use Test::More tests => 4;
use JSON::PP;
use JQ::Lite;

my $jq = JQ::Lite->new;

sub unordered_paths_ok {
    my ($got, $expected, $name) = @_;

    my @got_sorted = sort map { encode_json($_) } @$got;
    my @exp_sorted = sort map { encode_json($_) } @$expected;

    is_deeply(\@got_sorted, \@exp_sorted, $name);
}

# --- 1. paths includes container nodes
my $json1 = '{"a":[1,2]}';
my @result1 = $jq->run_query($json1, 'paths');
unordered_paths_ok(
    \@result1,
    [
        [ 'a' ],
        [ 'a', 0 ],
        [ 'a', 1 ],
    ],
    'paths() emits container and child paths',
);

# --- 2. paths(scalars) only reports scalar leaves
my $json2 = '{"a":[1,{"b":true}],"c":null}';
my @result2 = $jq->run_query($json2, 'paths(scalars)');
unordered_paths_ok(
    \@result2,
    [
        [ 'a', 0 ],
        [ 'a', 1, 'b' ],
        [ 'c' ],
    ],
    'paths(scalars) emits only scalar-leaf paths',
);

# --- 3. Scalar input produces an empty stream for paths
my $json3 = '"hello"';
my @result3 = $jq->run_query($json3, 'paths');
is_deeply(\@result3, [], 'paths() yields no results for scalar input');

# --- 4. Scalar input produces an empty stream for paths(scalars)
my $json4 = 'true';
my @result4 = $jq->run_query($json4, 'paths(scalars)');
is_deeply(\@result4, [], 'paths(scalars) yields no results for scalar input');

