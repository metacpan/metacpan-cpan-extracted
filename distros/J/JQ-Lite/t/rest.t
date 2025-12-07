use strict;
use warnings;
use Test::More;

use lib 'lib';
use JQ::Lite;

my $jq = JQ::Lite->new;

subtest 'rest on arrays' => sub {
    my $json = '[1,2,3,4]';
    my @res  = $jq->run_query($json, 'rest');
    is_deeply(\@res, [ [2,3,4] ], 'removes first element');
};

subtest 'rest on empty arrays yields empty array' => sub {
    my $json = '[]';
    my @res  = $jq->run_query($json, 'rest');
    is_deeply(\@res, [ [] ], 'empty array stays empty');
};

subtest 'rest passes through non-arrays' => sub {
    my $json = '{"foo":1}';
    my @res  = $jq->run_query($json, 'rest');
    is_deeply(\@res, [ { foo => 1 } ], 'non-arrays pass through untouched');
};

done_testing();
