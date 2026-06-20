use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# basic positional binding from an arrayref
let [$a, $b, $c] = [10, 20, 30];
is($a, 10, 'first');
is($b, 20, 'second');
is($c, 30, 'third');

# fewer pattern slots than elements: extras ignored
let [$x, $y] = [1, 2, 3, 4];
is($x, 1, 'short pattern x');
is($y, 2, 'short pattern y');

# more pattern slots than elements: missing -> undef
{
	no warnings 'uninitialized';
	let [$p, $q, $r] = [5];
	is($p, 5, 'long pattern p');
	ok(!defined $q, 'long pattern q undef');
	ok(!defined $r, 'long pattern r undef');
}

# single element
let [$only] = [42];
is($only, 42, 'single element');

# empty pattern parses and binds nothing
let [] = [1, 2];
ok(1, 'empty array pattern ok');

# trailing comma allowed
let [$m, $n,] = [7, 8];
is("$m-$n", "7-8", 'trailing comma');

done_testing;
