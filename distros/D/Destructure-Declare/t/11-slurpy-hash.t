use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# %rest captures every key not named earlier
let {name => $n, %rest} = {name => 'A', x => 1, y => 2};
is($n, 'A', 'named key bound');
is_deeply(\%rest, {x => 1, y => 2}, '%rest captures the remaining keys');

# %rest is empty when nothing is left over
let {a => $a, %r2} = {a => 1};
is($a, 1, 'a');
is_deeply(\%r2, {}, 'empty %rest');

# %rest as the only element captures the whole hash
let {%all} = {p => 1, q => 2};
is_deeply(\%all, {p => 1, q => 2}, 'whole-hash %rest');

# several named keys excluded from %rest
let {one => $x, two => $y, %others} = {one => 1, two => 2, three => 3, four => 4};
is("$x$y", '12', 'named keys');
is_deeply(\%others, {three => 3, four => 4}, '%rest excludes all named keys');

# non-hashref source -> empty %rest, no warning
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, "@_" };
	let {%none} = undef;
	is_deeply(\%none, {}, 'undef source -> empty %rest');
	is(scalar(@w), 0, 'no warnings on undef source');
}

# @rest is rejected in a hash pattern
{
	local $@;
	my $ok = eval 'use Destructure::Declare; let {a => $a, @bad} = {}; 1';
	ok(!$ok, '@rest invalid in hash pattern');
	like($@, qr/hash pattern/, 'helpful error for @rest in hash');
}

done_testing;
