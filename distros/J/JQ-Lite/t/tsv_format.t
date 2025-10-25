use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = '{"row":["foo","bar","baz\tqux","line1\nline2"]}';

my $jq = JQ::Lite->new;

my @row = $jq->run_query($json, '.row | @tsv');
my $expected_row = "foo\tbar\tbaz\\tqux\tline1\\nline2";
is_deeply(\@row, [$expected_row], '@tsv formats arrays as TSV rows with escapes');

my @single = $jq->run_query($json, '.row[0] | @tsv');
is_deeply(\@single, ['foo'], '@tsv formats scalar values as TSV fields');

my $mixed_json = '{"data":[true,{"k":"v"}]}';
my @mixed = $jq->run_query($mixed_json, '.data | @tsv');
my $expected_mixed = "true\t{\"k\":\"v\"}";
is_deeply(\@mixed, [$expected_mixed], '@tsv stringifies booleans and objects');

done_testing();
