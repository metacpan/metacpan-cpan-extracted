use strict;
use warnings;
use Test::More 0.88;
use JSON::MaybeXS;

use Test::Needs 'Cpanel::JSON::XS';
diag 'Using Cpanel::JSON::XS ', Cpanel::JSON::XS->VERSION;

is( JSON, 'Cpanel::JSON::XS', 'Correct JSON class' );

is( \&encode_json,
    \&Cpanel::JSON::XS::encode_json,
    'Correct encode_json function'
);

is( \&decode_json,
    \&Cpanel::JSON::XS::decode_json,
    'Correct encode_json function'
);

my ($zero, $one) = (0, 1);
ok(JSON::MaybeXS::is_bool(bless(\$zero, 'Cpanel::JSON::XS::Boolean')), 'Cpanel::JSON::XS::Boolean true');
ok(JSON::MaybeXS::is_bool(bless(\$one, 'Cpanel::JSON::XS::Boolean')), 'Cpanel::JSON::XS::Boolean false');

require './t/lib/is_bool.pm';

done_testing;
