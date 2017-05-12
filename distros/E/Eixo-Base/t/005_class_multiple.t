package A;

use Eixo::Base::Clase;

has(

	a=>1,
	
	b=>33
);


package BB;

use Eixo::Base::Clase -norequire, 'A';

has(
	c=>34
);

package ZERO;
use strict;
use Test::More;

use Eixo::Base::Clase -norequire, qw(A BB);

my $zero  = ZERO->new;

ok($zero->isa("A"), "ZERO is A");
ok($zero->isa("BB"), "ZERO is B");

my $b = BB->new;

ok($b->isa("A"), "BB is A");
ok($b->can("b"), "BB can b");

is($b->b, 33, "BB has default A attributes");

done_testing();

