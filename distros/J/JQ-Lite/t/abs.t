use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "number": -10,
  "numbers": [-3, 4, -5, "n/a"]
});

my $jq = JQ::Lite->new;

my @scalar = $jq->run_query($json, '.number | abs');
is($scalar[0], 10, 'abs converts scalar numbers to absolute value');

my @array = $jq->run_query($json, '.numbers | abs');
is_deeply(
    $array[0],
    [3, 4, 5, 'n/a'],
    'abs converts numeric array entries and leaves non-numeric intact'
);

done_testing;
