use strict;
use warnings;

use if !eval { require JSON::XS; 1; }, 'Test::More', skip_all => 'No JSON::XS';
use Test::More 0.88;
use JSON::MaybeXS;

diag 'Using JSON::XS ', JSON::XS->VERSION;

is( JSON, 'JSON::XS', 'Correct JSON class' );

is( \&encode_json, \&JSON::XS::encode_json, 'Correct encode_json function' );
is( \&decode_json, \&JSON::XS::decode_json, 'Correct encode_json function' );

require './t/lib/is_bool.pm';

done_testing;
