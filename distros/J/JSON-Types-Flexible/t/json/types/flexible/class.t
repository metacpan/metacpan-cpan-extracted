use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

use JSON::XS;
use JSON::Types::Flexible ();

subtest basic => sub {
    is encode_json([ JSON::Types::Flexible::number(0) ]), '[0]';
    is encode_json([ JSON::Types::Flexible::number(1) ]), '[1]';

    is encode_json([ JSON::Types::Flexible::string(0) ]), '["0"]';
    is encode_json([ JSON::Types::Flexible::string(1) ]), '["1"]';

    is encode_json([ JSON::Types::Flexible::bool(1) ]), '[true]';
    is encode_json([ JSON::Types::Flexible::bool(0) ]), '[false]';

    is encode_json([ JSON::Types::Flexible::boolean(1) ]), '[true]';
    is encode_json([ JSON::Types::Flexible::boolean(0) ]), '[false]';
};

done_testing;
