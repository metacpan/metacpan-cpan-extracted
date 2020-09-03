use Test::More;
BEGIN {
	use Hades;
	Hades->run({
		eval => 'Kosmos { [curae penthos] :t(Int) :d(2) :p :pr :c :r geras $nosoi :t(Int) :d(5) { if (£penthos == $nosoi) { return £curae; } } }',
		realm => 'Moo',
		lib => 't/lib'
	});
	use lib 't/lib';
}
use Kosmos;
my $okay = Kosmos->new({
	curae => 5
});
eval { $okay->penthos };
like( $@, qr/^cannot call private attribute penthos/);
is($okay->has_curae, 1);
is($okay->geras(2), 5);



done_testing;
