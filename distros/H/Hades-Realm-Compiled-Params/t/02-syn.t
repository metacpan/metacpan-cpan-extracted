use Test::More;
BEGIN {
	use Hades::Realm::Compiled::Params;
	Hades::Realm::Compiled::Params->run({
		eval => 'Kosmos { penthos :d(2) :p :pr :c :t(Int) curae :r geras $nosoi :t(Int) { if ($self->penthos == $nosoi) { return $self->curae; } } }',
		lib => 't/lib'
	});
	use lib 't/lib';
}
use Kosmos;
my $okay = Kosmos->new({
	curae => 5
});
eval { $okay->penthos };
like( $@, qr/^cannot call private method penthos/);
is($okay->curae, 5);
is($okay->geras(2), 5);
done_testing;
