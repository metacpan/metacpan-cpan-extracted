use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# ( ... ) destructures a list (list-context RHS), like my (...) = LIST but with
# the extra Destructure::Declare powers.

let ($a, $b) = (1, 2);
is("$a$b", '12', 'basic list bind');

# from an array
my @arr = (10, 20, 30);
let ($x, $y, $z) = @arr;
is("$x-$y-$z", '10-20-30', 'bind from array');

# slurpy tail
let ($head, @tail) = (1, 2, 3, 4);
is($head, 1, 'head');
is_deeply(\@tail, [2, 3, 4], 'list slurpy tail');

# %rest collects the remaining list as key/value pairs
let ($first, %kv) = ('f', a => 1, b => 2);
is($first, 'f', 'first');
is_deeply(\%kv, {a => 1, b => 2}, 'list %rest as pairs');

# defaults and holes work in list form
let ($p = 99, undef, $q) = (undef, 'skip', 'r');
is($p, 99,  'list default for undef');
is($q, 'r', 'list hole skips a slot');

# nested patterns: an element that is itself a ref
let ($name, [$lo, $hi], {k => $v}) = ('rng', [1, 9], {k => 'V'});
is($name, 'rng', 'list scalar');
is("$lo-$hi", '1-9', 'nested arrayref in list');
is($v, 'V', 'nested hashref in list');

# evaluated exactly once
my $calls = 0;
sub src { $calls++; (1, 2, 3) }
let ($m, $n, @rest) = src();
is($calls, 1, 'list RHS evaluated once');
is("$m$n@rest", '123', 'list bindings correct');

# empty list pattern
let () = (1, 2, 3);
ok(1, 'empty list pattern ok');

done_testing;
