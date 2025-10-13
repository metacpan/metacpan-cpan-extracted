use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "title": "  Hello World  ",
  "tags": [" perl ", "json ", "cli"],
  "score": 5,
  "mixed": [" spaced ", null, {"keep": "  untouched  "}]
});

my $jq = JQ::Lite->new;

my @trimmed_title = $jq->run_query($json, '.title | trim');
is($trimmed_title[0], 'Hello World', 'trim removes leading and trailing spaces from scalar');

my @trimmed_tags = $jq->run_query($json, '.tags | trim');
is_deeply($trimmed_tags[0], ['perl', 'json', 'cli'], 'trim applies recursively to array elements');

my @number = $jq->run_query($json, '.score | trim');
ok(!ref $number[0], 'trim leaves numeric scalar as non-reference');
is($number[0], 5, 'trim leaves non-string scalars untouched');

my @mixed = $jq->run_query($json, '.mixed | trim');
is_deeply(
    $mixed[0],
    ['spaced', undef, { keep => '  untouched  ' }],
    'trim recurses into arrays but leaves hashes as-is'
);

like($trimmed_title[0], qr/^\S.*\S$/, 'result has no surrounding whitespace');

note('ensure undef input stays undef');
my @defaulted = $jq->run_query($json, '.missing? | trim | default("fallback")');
is($defaulted[0], 'fallback', 'trim preserves undef before default() substitution');

note('trim can be chained with other functions');
my @chained = $jq->run_query($json, '.tags | trim | first');
is($chained[0], 'perl', 'trim result works with other filters');

done_testing;
