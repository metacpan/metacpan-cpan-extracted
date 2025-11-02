use strict;
use warnings;

use Test::More;
use Encode qw(decode);
use JQ::Lite;

my $json = decode('UTF-8', '"こんにちは！"');
my $jq   = JQ::Lite->new;

my @results = eval { $jq->run_query($json, '@uri') };
my $error   = $@;

is($error, '', 'running @uri on decoded UTF-8 input does not throw');
is_deeply(\@results, ['%E3%81%93%E3%82%93%E3%81%AB%E3%81%A1%E3%81%AF%EF%BC%81'], 'UTF-8 text is percent-encoded');

done_testing();
