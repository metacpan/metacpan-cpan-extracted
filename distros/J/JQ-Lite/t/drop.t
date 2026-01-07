use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "numbers": [1, 2, 3, 4],
  "user": { "name": "Alice" }
});

my $jq = JQ::Lite->new;

my @drop_0 = $jq->run_query($json, '.numbers | drop(0)');
my @drop_2 = $jq->run_query($json, '.numbers | drop(2)');
my @drop_5 = $jq->run_query($json, '.numbers | drop(5)');
my @non_array = $jq->run_query($json, '.user | drop(1)');

my $negative_ok = eval { $jq->run_query($json, '.numbers | drop(-2)') };
ok(!$negative_ok && $@ =~ /drop\(\): count must be a non-negative integer/,
   'drop() rejects negative counts');

my $non_numeric_ok = eval { $jq->run_query($json, '.numbers | drop(foo)') };
ok(!$non_numeric_ok && $@ =~ /drop\(\): count must be a non-negative integer/,
   'drop() rejects non-numeric counts');

is_deeply($drop_0[0], [1, 2, 3, 4], 'drop(0) keeps all elements');
is_deeply($drop_2[0], [3, 4], 'drop(2) skips the first two elements');
is_deeply($drop_5[0], [], 'drop(5) returns an empty array when count exceeds length');
is_deeply($non_array[0], { name => 'Alice' }, 'drop(n) leaves non-array values unchanged');

done_testing;
