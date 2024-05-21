use Test::More;

BEGIN {
	use Hades;
	Hades->run({
		realm => 'Rope',
		eval => 'Kato { 
			penthos :required 
			curae :r :default(5)
			nosoi :default(3) :t(Int) :clearer
			hypnos :default(this is just a test) :t(Maybe[Str]) :c
			limos :t(Bool)
			phobos :t(ArrayRef[HashRef, 1, 100]) 
			aporia :t(HashRef[Int])
			thanatos :t(Map[Str, Int])
			gaudia :t(Tuple[Str, Int])
			oneiroi :type(Maybe[Dict[name => Str, id => Optional[Int], meta => Maybe[Dict[name => Str, id => Optional[Int], options => ArrayRef[Str, 1, 1]]]]])
			geras { if ($_[0]->penthos == $_[0]->nosoi) { return $_[0]->curae; } } 
		}
		Kato::Kosmos extends Kato { 
			algea :d([{ test => [qw/a b c/] }]) :t(ArrayRef)
		}',
		lib => 't/lib'
	});
	use lib 't/lib';
}

use Kato;
my $okay = Kato->new(
	oneiroi => {
		name => 'test',
		meta => {
			name => 'test',
			id => 1,
			options => ['test']
		}
	},
	gaudia => ['abc', 1],
	aporia => {
		a => 1,
		b => 2
	},
	penthos => 2,
	nosoi => 2,
	limos => 0,
	phobos => [
		{
			abc => 1
		}
	],
	thanatos => {
		a => 1,
		b => 2
	}
);

is($okay->penthos, 2);
is($okay->nosoi, 2);
is($okay->curae, 5);
is($okay->geras, 5);
is($okay->limos, 0);
is_deeply($okay->phobos, [ { abc => 1 } ]);
is_deeply($okay->aporia, {a => 1, b => 2});
is_deeply($okay->thanatos, {a => 1, b => 2});
is_deeply($okay->gaudia, ['abc', 1]);
is_deeply($okay->oneiroi, {name => 'test', meta => { name => 'test', id => 1, options => ['test'] }});
is($okay->hypnos, 'this is just a test');
not($okay->clear_hypnos);
is($okay->hypnos, undef);
my $type_check = eval {
	$okay->hypnos({ abc => 1 });
};
like($@, qr/did not pass type constraint/);
$type_check = eval {
	$okay->nosoi('abc');
};
like($@, qr/did not pass type constraint/);

$type_check = eval {
	$okay->phobos([qw/abc/]);
};
like($@, qr/did not pass type constraint/);

$type_check = eval {
	$okay->phobos([]);
};
like($@, qr/did not pass type constraint/);

$type_check = eval {
	$okay->aporia({ a => 'abc' });
};
like($@, qr/did not pass type constraint/);

$type_check = eval {
	$okay->thanatos({ a => 'abc' });
};
like($@, qr/did not pass type constraint/);

my $not_okay = eval { 
	Kato->new(
		curae => 5
	);
};

like($@, qr/required/i);

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
	Kato::Kosmos->new(
		curae => 5
	);
};

like($@, qr/required/i);

done_testing;
