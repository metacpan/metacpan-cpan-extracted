use strict;
use warnings;
use Test::More tests => 3;
use JSON::PP;
use JQ::Lite;

my $jq = JQ::Lite->new;

# --- 1. Existing value should not be replaced
my $json1 = '{"nickname":"alice"}';
my @result1 = $jq->run_query($json1, '.nickname | default("unknown")');
is($result1[0], 'alice', 'default() does not override existing value');

# --- 2. Undefined value should be replaced
my $json2 = '{}';
my @result2 = $jq->run_query($json2, '.nickname | default("unknown")');
is($result2[0], 'unknown', 'default() applies default for missing field');

# --- 3. Null value should be replaced
my $json3 = '{"nickname":null}';
my @result3 = $jq->run_query($json3, '.nickname | default("unknown")');
is($result3[0], 'unknown', 'default() applies default for null');

