use strict;
use warnings;
use Test::More 0.88;
use JSON::MaybeXS;

unless ( eval { require Cpanel::JSON::XS; 1 } ) {
    plan skip_all => 'No Cpanel::JSON::XS';
}

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

require './t/lib/is_bool.pm';

done_testing;
