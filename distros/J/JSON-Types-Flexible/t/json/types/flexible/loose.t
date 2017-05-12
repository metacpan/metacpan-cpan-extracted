use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

use JSON::XS;
use JSON::Types::Flexible ':loose';

subtest basic => sub {
    is encode_json([ number 0 ]), '[0]';
    is encode_json([ number 1 ]), '[1]';

    is encode_json([ string 0 ]), '["0"]';
    is encode_json([ string 1 ]), '["1"]';

    is encode_json([ bool 1 ]), '[true]';
    is encode_json([ bool 0 ]), '[false]';

    is encode_json([ boolean 1 ]), '[true]';
    is encode_json([ boolean 0 ]), '[false]';
};

done_testing;
