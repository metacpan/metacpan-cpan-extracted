use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json_ordered = q([1, 2, 3, 4, 5]);
my ($p0)  = $jq->run_query($json_ordered, 'percentile(0)');
my ($p25) = $jq->run_query($json_ordered, 'percentile(25)');
my ($p50) = $jq->run_query($json_ordered, 'percentile');
my ($p100) = $jq->run_query($json_ordered, 'percentile(100)');

is($p0, 1, 'percentile(0) returns the minimum value');
is($p25, 2, 'percentile(25) returns the first quartile');
is($p50, 3, 'percentile defaults to the median when no argument is provided');
is($p100, 5, 'percentile(100) returns the maximum value');

my $json_interp = q([10, 20, 30, 40]);
my ($p90) = $jq->run_query($json_interp, 'percentile(0.90)');
my ($p75) = $jq->run_query($json_interp, 'percentile(75)');

is($p90, 37, 'percentile(0.90) performs linear interpolation');
is($p75, 32.5, 'percentile(75) supports percentage arguments between 0 and 100');

my $json_mixed = q(["foo", 10, "20", null]);
my ($p_mixed) = $jq->run_query($json_mixed, 'percentile(50)');

is($p_mixed, 15, 'percentile ignores non-numeric values but keeps numeric strings');

my $json_invalid = q(["a", "b"]);
my ($p_invalid_arg) = $jq->run_query($json_invalid, 'percentile("oops")');

ok(!defined $p_invalid_arg, 'percentile returns undef when the argument is not numeric');

my ($p_nan_arg) = $jq->run_query($json_ordered, 'percentile("NaN")');
ok(!defined $p_nan_arg, 'percentile returns undef when the argument is NaN');

my ($p_inf_arg) = $jq->run_query($json_ordered, 'percentile("Infinity")');
ok(!defined $p_inf_arg, 'percentile returns undef when the argument is infinite');

my ($p_inf_negative) = $jq->run_query($json_ordered, 'percentile("-Infinity")');
ok(!defined $p_inf_negative, 'percentile returns undef when the argument is negative infinity');

my ($p_no_numeric) = $jq->run_query($json_invalid, 'percentile(10)');
ok(!defined $p_no_numeric, 'percentile returns undef when no numeric values are present');

my $json_unsorted = q([40, 10, 50, 20, 30]);
my ($p_unsorted) = $jq->run_query($json_unsorted, 'percentile(60)');
is($p_unsorted, 34, 'percentile sorts the array before computing the percentile');

my ($p_underflow) = $jq->run_query($json_ordered, 'percentile(-25)');
is($p_underflow, 1, 'percentile clamps percentiles below 0 to the minimum value');

my ($p_overflow) = $jq->run_query($json_ordered, 'percentile(175)');
is($p_overflow, 5, 'percentile clamps percentiles above 100 to the maximum value');

my $json_single = q([99]);
my ($p_single) = $jq->run_query($json_single, 'percentile(25)');
is($p_single, 99, 'percentile returns the only element when the array has one value');

done_testing;
