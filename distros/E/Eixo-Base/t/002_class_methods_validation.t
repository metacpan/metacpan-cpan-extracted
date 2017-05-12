package AA;
use t::test_base;

BEGIN{use_ok("Eixo::Base::Clase")}


use parent qw(Eixo::Base::Clase);

has (

	n => 55,
	o => 'aaa',
	p => {},
	a => [],
	nulo=>undef,
	vacio=>0,
	nada=>''

);

sub t1 : Sig(self, i, ARRAY, HASH){

}


use strict;
use warnings;

use Test::More;
use Data::Dumper;

my $aa = AA->new;

$@ = undef;
eval{
	$aa->t1(1,[]);
};
ok($@, "Error detected");
#print $@;

done_testing();
