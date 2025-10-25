use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = '{"row":["foo","bar","baz,qux","he said \"hi\""]}';

my $jq = JQ::Lite->new;

my @row = $jq->run_query($json, '.row | @csv');
is_deeply(\@row, ['"foo","bar","baz,qux","he said ""hi"""'], '@csv formats arrays as CSV rows');

my @single = $jq->run_query($json, '.row[0] | @csv');
is_deeply(\@single, ['"foo"'], '@csv formats scalar values as CSV fields');

my $mixed_json = '["42", 42]';
my @mixed = $jq->run_query($mixed_json, '@csv');
is_deeply(\@mixed, ['"42",42'], '@csv preserves numeric-looking strings with quotes');

done_testing();
