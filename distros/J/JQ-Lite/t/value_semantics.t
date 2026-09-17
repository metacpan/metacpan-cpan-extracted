use strict;
use warnings;

use Test::More;
use JSON::PP ();
use Scalar::Util qw(dualvar);

use lib 'lib';
use JQ::Lite::Value ();

is(JQ::Lite::Value::type_of(undef), 'null', 'classifies null');
is(JQ::Lite::Value::type_of(JSON::PP::false), 'boolean', 'classifies booleans');
is(JQ::Lite::Value::type_of(10), 'number', 'classifies numbers');
is(JQ::Lite::Value::type_of('ten'), 'string', 'classifies strings');
is(JQ::Lite::Value::type_of([]), 'array', 'classifies arrays');
is(JQ::Lite::Value::type_of({}), 'object', 'classifies objects');

# Older JSON::PP releases reject scalar documents unless allow_nonref is set.
my $decoded_number = JSON::PP->new->allow_nonref->decode('10');
my $stringified_number = "$decoded_number";
is($stringified_number, '10', 'decoded number is stringified before classification');
is(JQ::Lite::Value::type_of($decoded_number), 'number',
    'stringification does not change a decoded number type');
ok(JQ::Lite::Value::equal($decoded_number, 10),
    'stringification does not change numeric equality');

my $dual_number = dualvar(10, '10');
is(JSON::PP::encode_json($dual_number), '10',
    'dual-valued scalar retains JSON numeric identity');
is(JQ::Lite::Value::type_of($dual_number), 'number',
    'numeric flags take precedence over a public string flag');
ok(JQ::Lite::Value::equal($dual_number, 10),
    'dual-valued numeric scalar retains numeric equality');

ok(!JQ::Lite::Value::equal('10', 10), 'equality keeps JSON scalar types distinct');
ok(JQ::Lite::Value::equal([1, { a => JSON::PP::true }],
        [1, { a => JSON::PP::true }]), 'equality handles nested JSON values');
ok(JQ::Lite::Value::compare(JSON::PP::false, 0) < 0,
    'comparison follows jq cross-type ordering');
ok(JQ::Lite::Value::compare([1, 2], [1, 3]) < 0,
    'arrays compare lexicographically');
ok(JQ::Lite::Value::compare([1, 2], [1, 2, 0]) < 0,
    'an equal array prefix sorts before the longer array');
ok(JQ::Lite::Value::compare({ a => 1 }, { a => 2 }) < 0,
    'objects with equal keys compare their values');
ok(JQ::Lite::Value::compare({ a => 9 }, { b => 0 }) < 0,
    'objects compare sorted key sets before values');

done_testing;
