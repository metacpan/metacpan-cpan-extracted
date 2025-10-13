use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "title": "Hello World",
  "tags": ["perl", "shell", "world"],
  "details": {
    "description": "perl world",
    "count": 2
  },
  "mixed": ["World", 42, null]
});

my $jq = JQ::Lite->new;

my @title = $jq->run_query($json, '.title | replace("World", "Perl")');
is($title[0], 'Hello Perl', 'replace updates simple scalar values');

my @tags = $jq->run_query($json, '.tags | replace("world", "globe")');
is_deeply(
    $tags[0],
    ['perl', 'shell', 'globe'],
    'replace processes array elements recursively'
);

my @description = $jq->run_query($json, '.details.description | replace("perl", "Perl")');
is($description[0], 'Perl world', 'replace respects case-sensitive search term');

my @count = $jq->run_query($json, '.details.count | replace("2", "three")');
is($count[0], 2, 'replace leaves non-string scalars untouched');

my @mixed = $jq->run_query($json, '.mixed | replace("World", "Earth")');
is_deeply(
    $mixed[0],
    ['Earth', 42, undef],
    'replace leaves non-string values unchanged and keeps undef'
);

my @empty_search = $jq->run_query($json, '.title | replace("", "no-op")');
is($empty_search[0], 'Hello World', 'replace is a no-op when search term is empty');

my @missing = $jq->run_query($json, '.missing? | replace("foo", "bar")');
ok(!defined $missing[0], 'replace leaves undef values as undef');

my @chained = $jq->run_query($json, '.title | replace("World", "Perl") | upper');
is($chained[0], 'HELLO PERL', 'replace result can be chained with other functions');

my @double = $jq->run_query($json, '.title | replace("l", "L")');
is($double[0], 'HeLLo WorLd', 'replace substitutes all occurrences of the search term');

done_testing;
