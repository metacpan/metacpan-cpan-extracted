use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;
use Test::Exception;

use JSON::XS;
use JSON::Types::Flexible qw/number bool/;

subtest basic => sub {
    is encode_json([ number 0 ]), '[0]';
    is encode_json([ number 1 ]), '[1]';

    dies_ok { string(0) };
    dies_ok { string(1) };

    is encode_json([ bool 1 ]), '[true]';
    is encode_json([ bool 0 ]), '[false]';

    dies_ok { boolean(1) };
    dies_ok { boolean(0) };
};

done_testing;
