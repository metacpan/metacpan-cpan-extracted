use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $numbers = '{ "numbers": [1, 2, 3, 4] }';
my @running_totals = $jq->run_query($numbers, 'foreach .numbers[] as $n (0; . + $n)');

is_deeply(\@running_totals, [1, 3, 6, 10], 'foreach emits running totals without extractor');

my @emitted = $jq->run_query(
    $numbers,
    'foreach .numbers[] as $n (0; . + $n; $n)'
);

is_deeply(
    \@emitted,
    [1, 2, 3, 4],
    'foreach extractor can reference iteration variable'
);

my $strings = '{ "words": ["a", "b", "c"] }';
my @concat = $jq->run_query($strings, 'foreach .words[] as $w (""; . + $w)');

is_deeply(\@concat, ['a', 'ab', 'abc'], 'foreach concatenates strings via addition semantics');

done_testing;
