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

TODO:
if ($] ge '5.036') {
  local $TODO = 'support for builtin::is_bool not yet done';
  ok(JSON::MaybeXS::is_bool(!!0), 'is_bool recognizes new stablebool false');
  ok(JSON::MaybeXS::is_bool(!!1), 'is_bool recognizes new stablebool true');
}
else {
  diag 'tests for 5.36+ are skipped';
}

ok(!JSON::MaybeXS::is_bool(0), 'numeric 0 is not a bool');
ok(!JSON::MaybeXS::is_bool(1), 'numeric 1 is not a bool');
ok(!JSON::MaybeXS::is_bool('0'), 'stringy 0 is not a bool');
ok(!JSON::MaybeXS::is_bool('1'), 'stringy 1 is not a bool');
ok(!JSON::MaybeXS::is_bool(''), 'empty string is not a bool');
ok(!JSON::MaybeXS::is_bool(undef), 'undef is not a bool');

1;
