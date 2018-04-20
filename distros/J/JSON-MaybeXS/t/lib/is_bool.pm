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

is(
    JSON::MaybeXS::encode_json([JSON::MaybeXS::true]),
    '[true]',
    JSON() . ': true sub encodes as correct boolean',
);

is(
    JSON::MaybeXS::encode_json([JSON::MaybeXS->true]),
    '[true]',
    JSON() . ': true method encodes as correct boolean',
);

is(
    JSON::MaybeXS::encode_json([JSON::MaybeXS::false]),
    '[false]',
    JSON() . ': false sub encodes as correct boolean',
);

is(
    JSON::MaybeXS::encode_json([JSON::MaybeXS->false]),
    '[false]',
    JSON() . ': false method encodes as correct boolean',
);

1;
