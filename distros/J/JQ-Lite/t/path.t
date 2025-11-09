use 5.029;
use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

BEGIN {
    if ($] < 5.029) {
        plan skip_all => "Perl 5.29 or higher required for this test";
    } else {
        plan tests => 4;
    }
}

my $jq = JQ::Lite->new;

# --- 1. Hash input
my $json1 = '{"name":"Alice","age":30,"email":"alice@example.com"}';
my @result1 = $jq->run_query($json1, 'path');
is_deeply($result1[0], [sort qw(name age email)], 'path() returns keys for hash');

# --- 2. Array input
my $json2 = '["apple","banana","cherry"]';
my @result2 = $jq->run_query($json2, 'path');
is_deeply($result2[0], [0,1,2], 'path() returns indices for array');

# --- 3. Scalar input
my $json3 = '"hello world"';
my @result3 = $jq->run_query($json3, 'path');
is($result3[0], '', 'path() returns empty string for scalar');

# --- 4. Null input
my $json4 = 'null';
my @result4 = $jq->run_query($json4, 'path');
is($result4[0], '', 'path() returns empty string for null');
