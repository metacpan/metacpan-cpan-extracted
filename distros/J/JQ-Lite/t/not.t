use strict;
use warnings;
use Test::More tests => 5;
use JSON::PP;
use JQ::Lite;

my $jq = JQ::Lite->new;

# 1. true -> false
my $json_true = 'true';
my @true_result = $jq->run_query($json_true, 'not');
is_deeply($true_result[0], JSON::PP::false, 'not on true yields false');

# 2. false -> true
my $json_false = 'false';
my @false_result = $jq->run_query($json_false, 'not');
is_deeply($false_result[0], JSON::PP::true, 'not on false yields true');

# 3. null -> true
my $json_null = 'null';
my @null_result = $jq->run_query($json_null, 'not');
is_deeply($null_result[0], JSON::PP::true, 'not on null yields true');

# 4. empty array -> true
my $json_empty_array = '[]';
my @empty_array_result = $jq->run_query($json_empty_array, 'not');
is_deeply($empty_array_result[0], JSON::PP::true, 'not on empty array yields true');

# 5. array with content -> false
my $json_array = '[1]';
my @array_result = $jq->run_query($json_array, 'not');
is_deeply($array_result[0], JSON::PP::false, 'not on non-empty array yields false');

