use Test::More;
BEGIN {
	use Hades;
	Hades->run({
		eval => 'KosmosAhh { [penthos curae] :d(2) :p :pr :c :t(Int) geras $nosoi :t(Int) { if ($self->penthos == $nosoi) { return $self->curae; } } }',
		lib => 't/lib'
	});
	use lib 't/lib';
}
use KosmosAhh;
my $okay = KosmosAhh->new({
	curae => 5
});
eval { $okay->penthos };
like( $@, qr/^cannot call private method penthos/);
is($okay->geras(2), 5);
done_testing;
