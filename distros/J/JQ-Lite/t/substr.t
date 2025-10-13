use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json = encode_json({ users => [ { name => 'Alice' }, { name => 'Bob' } ] });
my @first_three = $jq->run_query($json, '.users[].name | substr(0, 3)');
is_deeply(\@first_three, ['Ali', 'Bob'], 'substr(0, 3) slices expected prefixes');

my @from_index = $jq->run_query($json, '.users[0].name | substr(2)');
is($from_index[0], 'ice', 'substr(2) without length returns remainder of string');

my @last_char = $jq->run_query($json, '.users[].name | substr(-1)');
is_deeply(\@last_char, ['e', 'b'], 'substr(-1) returns final character for each name');

my $json_words = encode_json({ words => [ 'Perl', 'JSON' ] });
my @array_slice = $jq->run_query($json_words, '.words | substr(0, 2)');
is_deeply($array_slice[0], ['Pe', 'JS'], 'substr applies element-wise to arrays');

my $json_null = encode_json({ name => undef });
my @null_slice = $jq->run_query($json_null, '.name | substr(0, 2)');
ok(!defined $null_slice[0], 'substr preserves undef for downstream defaults');

my @no_args = $jq->run_query($json, '.users[1].name | substr');
is($no_args[0], 'Bob', 'substr with no arguments returns original value');

done_testing;
