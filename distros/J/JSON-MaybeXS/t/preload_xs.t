use strict;
use warnings;

use Test::Needs { 'JSON::XS' => '3.0' };  # load first, before JSON::MaybeXS
use Test::More 0.88;
use JSON::MaybeXS;

diag 'Using JSON::XS ', JSON::XS->VERSION;

is( JSON, 'JSON::XS', 'Correct JSON class' );

is( \&encode_json, \&JSON::XS::encode_json, 'Correct encode_json function' );
is( \&decode_json, \&JSON::XS::decode_json, 'Correct encode_json function' );

require './t/lib/is_bool.pm';

done_testing;
