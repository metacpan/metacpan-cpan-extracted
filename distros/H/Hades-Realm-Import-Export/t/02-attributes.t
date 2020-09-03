use Test::More;

BEGIN {
	use Hades;
	Hades->run({
		realm => 'Import::Export',
		eval => 'Kato { 
			penthos :i(1) :required 
			curae :i(1) :r :default(5)
			nosoi :i(1) :default(3) :t(Int) :clearer
			hypnos :i(1) :default(this is just a test) :type(Str) :c
			limos :i(1) :t(Bool)
			phobos :i(1) :t(ArrayRef[HashRef, 1, 100]) 
			aporia :i(1) :t(HashRef[Int])
			thanatos :i(1) :t(Map[Str, Int])
			gaudia :i(1) :t(Tuple[Str, Int])
			oneiroi :i(1) :type(Dict[name => Str, id => Optional[Int], meta => Dict[name => Str, id => Optional[Int], options => ArrayRef[Str, 1, 1]]])
			geras :i(1) { if (penthos() == nosoi()) { return curae(); } } 
		}
		Kato::Kosmos base Kato { 
			algea :d([{ test => [qw/a b c/] }]) :t(ArrayRef) :i(1)
		}',
		lib => 't/lib'
	});
	use lib 't/lib';
}

use Kato qw/EXPORT_OK/;

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

done_testing;
=pod
use Kato::Kosmos;
my $okay = Kato::Kosmos->new(
	penthos => 2,
	nosoi => 2,
);
is($okay->penthos, 2);
is($okay->nosoi, 2);
is($okay->curae, 5);
is($okay->geras, 5);
is_deeply($okay->algea, [{ test => [qw/a b c/] }]);

$not_okay = eval {
	Kato::Kosmos->new({
		curae => 5
	});
};

like($@, qr/required/);
=cut

