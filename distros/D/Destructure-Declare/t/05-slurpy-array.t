use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# trailing @rest captures the remainder
let [$head, @tail] = [1, 2, 3, 4];
is($head, 1, 'head');
is_deeply(\@tail, [2, 3, 4], 'tail captures remainder');

# slurpy with nothing left -> empty list
let [$a, $b, @rest] = [10, 20];
is($a, 10, 'a');
is($b, 20, 'b');
is_deeply(\@rest, [], 'empty slurpy');

# slurpy as the only element captures everything
let [@all] = [5, 6, 7];
is_deeply(\@all, [5, 6, 7], 'whole-array slurpy');

# slurpy after a hole
let [undef, @after] = ['skip', 1, 2];
is_deeply(\@after, [1, 2], 'slurpy after hole');

# non-arrayref source -> empty slurpy, no warning
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, "@_" };
	let [@none] = undef;
	is_deeply(\@none, [], 'undef source -> empty slurpy');
	is(scalar(@w), 0, 'no warnings on undef source');
}

done_testing;
