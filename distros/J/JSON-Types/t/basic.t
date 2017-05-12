use strict;
use warnings;
use Test::More;

use JSON;
use JSON::Types;

my $obj = 123;
is encode_json([ $obj ]), '[123]', 'number data ok';
is encode_json([ string $obj ]), '["123"]', 'to string ok';

$obj = "123";
is encode_json([ $obj ]), '["123"]', 'string data ok';
is encode_json([ number $obj ]), '[123]', 'to number ok';

is encode_json([ bool $obj ]), '[true]', 'to true ok';
is encode_json([ bool !$obj ]), '[false]', 'to false ok';

done_testing;
