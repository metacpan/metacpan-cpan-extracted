use Test::More;
use lib 't/lib';
use Kato::Kosmos;

is(penthos(2), 2);
is(nosoi(2), 2);
is(curae(5), 5);
is(geras(5), 5);
is(limos(0), 0);
is_deeply(phobos([ { abc => 1 } ]), [ { abc => 1 } ]);
is_deeply(aporia({a => 1, b => 2}), {a => 1, b => 2});
is_deeply(thanatos({a => 1, b => 2}), {a => 1, b => 2});
is_deeply(gaudia(['abc', 1]), ['abc', 1]);
is_deeply(oneiroi({name => 'test', meta => { name => 'test', id => 1, options => ['test'] }}), {name => 'test', meta => { name => 'test', id => 1, options => ['test'] }});
is(hypnos, 'this is just a test');
ok(clear_hypnos);
is(hypnos, undef,);
my $type_check = eval {
	hypnos({ abc => 1 });
};
like($@, qr/invalid value/);
$type_check = eval {
	nosoi('abc');
};
like($@, qr/invalid value/);
$type_check = eval {
	phobos([qw/abc/]);
};
like($@, qr/invalid value/);

$type_check = eval {
	phobos([]);
};
like($@, qr/contain atleast 1/);

$type_check = eval {
	aporia({ a => 'abc' });
};
like($@, qr/invalid value/);

$type_check = eval {
	thanatos({ a => 'abc' });
};
like($@, qr/invalid value/);

is_deeply(algea(), [{ test => [qw/a b c/] }]);

done_testing;
