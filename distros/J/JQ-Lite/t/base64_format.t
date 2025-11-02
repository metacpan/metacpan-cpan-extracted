use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my @string = $jq->run_query('"hello"', '@base64');
is_deeply(\@string, ['aGVsbG8='], '@base64 encodes simple strings');

my @number = $jq->run_query('42', '@base64');
is_deeply(\@number, ['NDI='], '@base64 encodes numbers via string form');

my @null = $jq->run_query('null', '@base64');
is_deeply(\@null, ['bnVsbA=='], '@base64 encodes null as its literal text');

my @object = $jq->run_query('{"foo":"bar"}', '@base64');
is_deeply(\@object, ['eyJmb28iOiJiYXIifQ=='], '@base64 encodes objects via JSON representation');

my @array = $jq->run_query('["a","b"]', '@base64');
is_deeply(\@array, ['WyJhIiwiYiJd'], '@base64 encodes arrays via JSON representation');

done_testing();
