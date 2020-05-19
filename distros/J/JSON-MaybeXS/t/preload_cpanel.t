use strict;
use warnings;

use Test::Needs 'Cpanel::JSON::XS'; # load first, before JSON::MaybeXS
use Test::More 0.88;
use JSON::MaybeXS;

diag 'Using Cpanel::JSON::XS ', Cpanel::JSON::XS->VERSION;

is(JSON, 'Cpanel::JSON::XS', 'Correct JSON class');

is(
  \&encode_json, \&Cpanel::JSON::XS::encode_json,
  'Correct encode_json function'
);

is(
  \&decode_json, \&Cpanel::JSON::XS::decode_json,
  'Correct encode_json function'
);

require './t/lib/is_bool.pm';

done_testing;
