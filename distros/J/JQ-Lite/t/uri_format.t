use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my @space = $jq->run_query('"hello world"', '@uri');
is_deeply(\@space, ['hello%20world'], '@uri encodes spaces in strings');

my @utf8 = $jq->run_query('"こんにちは"', '@uri');
is_deeply(\@utf8, ['%E3%81%93%E3%82%93%E3%81%AB%E3%81%A1%E3%81%AF'], '@uri encodes UTF-8 characters');

my @number = $jq->run_query('42', '@uri');
is_deeply(\@number, ['42'], '@uri leaves numeric characters as-is');

my @null = $jq->run_query('null', '@uri');
is_deeply(\@null, ['null'], '@uri renders null as its literal text');

my @object = $jq->run_query('{"foo":"bar"}', '@uri');
is_deeply(\@object, ['%7B%22foo%22%3A%22bar%22%7D'], '@uri encodes objects via JSON representation');

done_testing();
