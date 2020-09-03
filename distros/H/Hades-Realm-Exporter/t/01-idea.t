use Test::More;

BEGIN {
	use Hades;
	Hades->run({
                eval => 'Kosmos {
                        [curae penthos] :t(Int) :d(2) :p :pr :c :r :i(1, GROUP)
                        geras $nosoi :t(Int) :d(5) :i { if (£penthos == $nosoi) { return £curae } }
                }',
                realm => 'Exporter',
		lib => 't/lib'
	});
	use lib 't/lib';
}

use Kosmos qw/penthos has_curae geras/;
eval { penthos() };
like( $@, qr/^cannot call private method penthos/);
is(has_curae(), 1);
is(geras(2), 2);
is(geras(), '');

ok(1);
done_testing();
