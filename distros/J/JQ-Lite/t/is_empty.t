use strict;
use warnings;
use Test::More tests => 4;
use JSON::PP;
use JQ::Lite;

my $jq = JQ::Lite->new;

# --- 1. Empty array
my $json1 = '[]';
my @result1 = $jq->run_query($json1, 'is_empty');
ok($result1[0], 'is_empty() returns true for empty array');

# --- 2. Non-empty array
my $json2 = '[1,2,3]';
my @result2 = $jq->run_query($json2, 'is_empty');
ok(!$result2[0], 'is_empty() returns false for non-empty array');

# --- 3. Empty hash
my $json3 = '{}';
my @result3 = $jq->run_query($json3, 'is_empty');
ok($result3[0], 'is_empty() returns true for empty hash');

# --- 4. Non-empty hash
my $json4 = '{"key":"value"}';
my @result4 = $jq->run_query($json4, 'is_empty');
ok(!$result4[0], 'is_empty() returns false for non-empty hash');

