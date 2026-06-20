use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# default applied when the slot is missing
let [$a, $b = 99] = [1];
is($a, 1,  'present value');
is($b, 99, 'default for missing slot');

# default applied when the slot is undef (// semantics)
let [$c = 'X'] = [undef];
is($c, 'X', 'default for undef slot');

# default NOT applied when a real (even falsey) value is present
let [$d = 'X'] = [0];
is($d, 0, 'falsey value beats default');
let [$e = 'X'] = [''];
is($e, '', 'empty string beats default');

# defaults in hash patterns
let {port => $p = 8080, host => $h = 'localhost'} = {port => 3000};
is($p, 3000,        'hash present');
is($h, 'localhost', 'hash default');

# default expression is an arbitrary Perl expr
let [$sum = 2 + 3 * 4] = [];
is($sum, 14, 'default expression evaluated');

# default expression is evaluated lazily (only when needed)
my $hits = 0;
sub mk { $hits++; 'D' }
let [$x = mk()] = ['real'];
is($x,    'real', 'lazy: value present');
is($hits, 0,      'lazy: default not evaluated when value present');
let [$y = mk()] = [undef];
is($y,    'D', 'lazy: default used when undef');
is($hits, 1,   'lazy: default evaluated exactly once when needed');

done_testing;
