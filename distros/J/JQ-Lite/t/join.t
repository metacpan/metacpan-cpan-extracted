use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = '{"users":[{"name":"Alice"},{"name":"Bob"},{"name":"Carol"}]}';

my $jq = JQ::Lite->new;

my @result = $jq->run_query($json, '.users | map(.name) | join(", ")');
is_deeply(\@result, ['Alice, Bob, Carol'], 'join() works correctly');

done_testing();

