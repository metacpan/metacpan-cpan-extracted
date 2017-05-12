use t::test_base;

BEGIN{use_ok("Eixo::Base::Util")}

$@ = undef;
eval{
	A->m;
};

ok($@ && $@ =~ /A\:\:m is ABSTRACT/, 'Abstract controls works ');

done_testing();

package A;

use strict;
use Eixo::Base::Clase;

sub m :Abstract{

}
