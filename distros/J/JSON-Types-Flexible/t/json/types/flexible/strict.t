use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;
use Test::Exception;

use JSON::XS;
use JSON::Types::Flexible;

subtest basic => sub {
    is encode_json([ number 0 ]), '[0]';
    is encode_json([ number 1 ]), '[1]';

    is encode_json([ string 0 ]), '["0"]';
    is encode_json([ string 1 ]), '["1"]';

    dies_ok { bool(1) };
    dies_ok { bool(0) };

    is encode_json([ boolean 1 ]), '[true]';
    is encode_json([ boolean 0 ]), '[false]';
};

done_testing;
