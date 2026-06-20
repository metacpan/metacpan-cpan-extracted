use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# array inside hash, hash inside array, several levels deep
my $rec = {
	id   => 7,
	pos  => [1, 2],
	meta => { tags => ['x', 'y'], who => { name => 'Z' } },
};

let {id => $id, pos => [$px, $py], meta => {tags => [$t0, $t1], who => {name => $nm}}} = $rec;
is($id, 7,   'top scalar');
is($px, 1,   'nested array x');
is($py, 2,   'nested array y');
is($t0, 'x', 'deep array 0');
is($t1, 'y', 'deep array 1');
is($nm, 'Z', 'deep hash scalar');

# hash inside array slot
let [$head, {k => $v}] = ['h', {k => 99}];
is($head, 'h', 'array head before nested hash');
is($v,    99,  'nested hash in array');

# array inside array
let [[$a, $b], [$c, $d]] = [[1, 2], [3, 4]];
is("$a$b$c$d", '1234', 'array in array');

done_testing;
