use strict;
use warnings;

use Test::More;
use JSON::MaybeXS;

my $data = JSON::MaybeXS->new->decode('{"foo": true, "bar": false, "baz": 1}');
diag 'true is: ', explain $data->{foo};
diag 'false is: ', explain $data->{bar};

ok(
    JSON::MaybeXS::is_bool($data->{foo}),
    JSON() . ': true decodes to a bool',
);
ok(
    JSON::MaybeXS::is_bool($data->{bar}),
    JSON() . ': false decodes to a bool',
);
ok(
    !JSON::MaybeXS::is_bool($data->{baz}),
    JSON() . ': int does not decode to a bool',
);

1;
