use strict;
use warnings;

use Test::More;
use JSON::MaybeXS;

sub test_is_bool {
  my ($value, $test_name) = @_;
  my $result = JSON::MaybeXS::is_bool($value);
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  ok($result, $test_name);

  # on earlier perls, booleans are '' and 1, which are not JSON booleans
  ok(JSON::MaybeXS::is_bool($result), 'result of is_bool is also a boolean') if "$]" >= 5.036;
}

sub test_isnt_bool {
  my ($value, $test_name) = @_;
  my $result = JSON::MaybeXS::is_bool($value);
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  ok(!$result, $test_name);

  # on earlier perls, booleans are '' and 1, which are not JSON booleans
  ok(JSON::MaybeXS::is_bool($result), 'result of is_bool is also a boolean') if "$]" >= 5.036;
}

SKIP: {
  skip ('these tests are only valid for perl 5.36+', 2) if "$]" < 5.036;
  test_is_bool(!!0, 'native boolean false is a bool');
  test_is_bool(!!1, 'native boolean true is a bool');
}

my $zero = 0;
test_is_bool(bless(\$zero, $_), "$_ object is a boolean") foreach qw(
    JSON::PP::Boolean
    Cpanel::JSON::XS::Boolean
    JSON::XS::Boolean
  );

test_isnt_bool(bless({}, 'Local::Foo'), 'other blessed objects are not booleans');

my $data = JSON::MaybeXS->new->decode('{"foo": true, "bar": false, "baz": 1}');
diag 'true is: ', explain $data->{foo};
diag 'false is: ', explain $data->{bar};

test_is_bool($data->{foo}, JSON() . ': true decodes to a bool');
test_is_bool($data->{bar}, JSON() . ': false decodes to a bool');
test_isnt_bool($data->{baz}, JSON() . ': int does not decode to a bool');

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

SKIP: {
  skip ('these tests are only valid for perl 5.36+', 2) if "$]" < 5.036;
  test_is_bool(!!0, 'is_bool recognizes new stablebool false');
  test_is_bool(!!1, 'is_bool recognizes new stablebool true');
}

test_isnt_bool(0, 'numeric 0 is not a bool');
test_isnt_bool(1, 'numeric 1 is not a bool');
test_isnt_bool('0', 'stringy 0 is not a bool');
test_isnt_bool('1', 'stringy 1 is not a bool');
test_isnt_bool('', 'empty string is not a bool');
test_isnt_bool(undef, 'undef is not a bool');

1;
