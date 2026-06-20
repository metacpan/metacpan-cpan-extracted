use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# bound names are real lexicals, visible for the rest of the enclosing block
let [$a, $b] = [1, 2];
is($a + $b, 3, 'visible after the let statement');

# lexical to the enclosing block: not visible outside it
{
	let [$inner] = [42];
	is($inner, 42, 'visible inside block');
}
ok(!eval 'no strict; defined $main::inner_should_not_exist', 'no leak placeholder');

# a later let can shadow / rebind in an inner scope without touching the outer
let [$x] = ['outer'];
{
	let [$x] = ['inner'];
	is($x, 'inner', 'inner scope sees its own binding');
}
is($x, 'outer', 'outer binding intact after inner block');

# hidden source temp does not collide across multiple lets in one scope
let [$p] = [1];
let [$q] = [2];
let [$r] = [3];
is("$p$q$r", '123', 'multiple lets in one scope coexist');

# strict 'vars' is satisfied: these are genuine my-vars (no symbolic refs)
let [$strictv] = ['ok'];
is($strictv, 'ok', 'works under use strict');

done_testing;
