use strict;
use warnings;
use Test::More;
use JSON::PP ();
use JQ::Lite;

my $json = q({
  "word": "Perl",
  "words": ["Hi", "JSON", null, {"skip": true}],
  "codes": [80, 101, 114, 108],
  "nested": [[65, 66], [67, 68]],
  "bool": true
});

my $jq = JQ::Lite->new;

my @exploded = $jq->run_query($json, '.word | explode');
is_deeply($exploded[0], [80, 101, 114, 108], 'explode converts string into Unicode code points');

my @exploded_array = $jq->run_query($json, '.words | explode');
my $expected_array = [
    [72, 105],
    [74, 83, 79, 78],
    undef,
    { skip => JSON::PP::true },
];
is_deeply($exploded_array[0], $expected_array, 'explode applies element-wise and preserves non-strings');

my @bool_exploded = $jq->run_query($json, '.bool | explode');
is_deeply($bool_exploded[0], [116, 114, 117, 101], 'explode stringifies booleans similar to jq');

my @imploded = $jq->run_query($json, '.codes | implode');
is($imploded[0], 'Perl', 'implode converts array of code points into string');

my @roundtrip = $jq->run_query($json, '.nested | implode');
my $expected_roundtrip = ['AB', 'CD'];
is_deeply($roundtrip[0], $expected_roundtrip, 'implode maps nested arrays of code points back to strings');

my @loop = $jq->run_query($json, '.word | explode | implode');
is($loop[0], 'Perl', 'explode + implode roundtrip returns original string');

my @mixed_implode = $jq->run_query($json, '.words | explode | implode');
my $expected_mixed = ['Hi', 'JSON', undef, { skip => JSON::PP::true }];
is_deeply($mixed_implode[0], $expected_mixed, 'implode reverses explode for arrays while leaving passthrough entries intact');

done_testing;
