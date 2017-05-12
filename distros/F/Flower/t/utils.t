use strict;
use warnings;

use Test::More;
use Flower::Chronos::Utils qw(are_hashes_equal parse_time);
use Flower::Chronos::Report;
use JSON;

subtest 'compare two empty hashes' => sub {
    ok are_hashes_equal({}, {});
};

subtest 'compare two equal hashes' => sub {
    ok are_hashes_equal({foo => 'bar'}, {foo => 'bar'});
};

subtest 'equal when values undefined' => sub {
    ok are_hashes_equal({foo => undef}, {foo => undef});
};

subtest 'not equal when different values' => sub {
    ok !are_hashes_equal({foo => 'bar'}, {foo => 'baz'});
};

subtest 'not equal when one is undefined' => sub {
    ok !are_hashes_equal({foo => 'bar'}, {foo => undef});
};

subtest 'not equal different keys' => sub {
    ok !are_hashes_equal({foo => 'bar'}, {bar => 'foo'});
};

subtest 'parse date' => sub {
    is parse_time('2014-09-30'), 1412035200;
};

subtest 'parse date with time' => sub {
    is parse_time('2014-09-30 09:01:12'), 1412067672;
};

subtest 'calculate_sig' => sub {
    my $record = decode_json(q[{"_end":1413849902,"category":"browser","url":"github.com","application":"Firefox","name":"\"marpa-cpp-rules/marpa.hpp at master · pstuifzand/marpa-cpp-rules - Mozilla Firefox\"","class":"\"Navigator\", \"Firefox\"","role":"\"browser\"","id":"0x38000b3","command":"","_start":1413849897}]);
    is Flower::Chronos::Report::calculate_sig($record, qw/name url/), 'd5ab0e50c7c23323a6f7fa59e4c52aea';
};

done_testing;
