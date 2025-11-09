use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "title": "Hello World",
  "tags": ["Perl", "JSON", "CLI"],
  "users": [
    {"name": "Alice"},
    {"name": "Bob"}
  ],
  "non_ascii": "\u00c5ngstr\u00f6m"
});

my $jq = JQ::Lite->new;

my @scalar_upper = $jq->run_query($json, '.title | upper');
is($scalar_upper[0], 'HELLO WORLD', 'upper converts scalar to uppercase');

my @scalar_lower = $jq->run_query($json, '.title | lower');
is($scalar_lower[0], 'hello world', 'lower converts scalar to lowercase');

my @array_upper = $jq->run_query($json, '.tags | upper');
is_deeply($array_upper[0], ['PERL', 'JSON', 'CLI'], 'upper converts array elements');

my @ascii_downcase = $jq->run_query($json, '.title | ascii_downcase');
is($ascii_downcase[0], 'hello world', 'ascii_downcase lowers ASCII characters');

my @ascii_downcase_array = $jq->run_query($json, '.tags | ascii_downcase');
is_deeply($ascii_downcase_array[0], ['perl', 'json', 'cli'], 'ascii_downcase works on arrays');

my $expected_non_ascii = "\x{00C5}ngstr\x{00F6}m";
my @ascii_downcase_non_ascii = $jq->run_query($json, '.non_ascii | ascii_downcase');
is($ascii_downcase_non_ascii[0], $expected_non_ascii, 'ascii_downcase leaves non-ASCII characters untouched');

my @ascii_upcase = $jq->run_query($json, '.title | ascii_upcase');
is($ascii_upcase[0], 'HELLO WORLD', 'ascii_upcase uppercases ASCII characters');

my @ascii_upcase_array = $jq->run_query($json, '.tags | ascii_upcase');
is_deeply($ascii_upcase_array[0], ['PERL', 'JSON', 'CLI'], 'ascii_upcase works on arrays');

my $expected_ascii_upcase = "\x{00C5}NGSTR\x{00F6}M";
my @ascii_upcase_non_ascii = $jq->run_query($json, '.non_ascii | ascii_upcase');
is($ascii_upcase_non_ascii[0], $expected_ascii_upcase, 'ascii_upcase leaves non-ASCII characters untouched');

my @pipeline_lower = $jq->run_query($json, '.users[] | .name | lower');
is_deeply(\@pipeline_lower, ['alice', 'bob'], 'lower works in pipelines with flattened arrays');

my @scalar_titlecase = $jq->run_query($json, '.title | titlecase');
is($scalar_titlecase[0], 'Hello World', 'titlecase capitalizes each word in scalars');

my @array_titlecase = $jq->run_query($json, '.tags | titlecase');
is_deeply($array_titlecase[0], ['Perl', 'Json', 'Cli'], 'titlecase transforms array elements');

my @pipeline_titlecase = $jq->run_query($json, '.users[] | .name | titlecase');
is_deeply(\@pipeline_titlecase, ['Alice', 'Bob'], 'titlecase works in pipelines with flattened arrays');

done_testing;
