use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# The construct lowers to a plain optree at compile time; nothing of the parser
# survives. We verify that indirectly with B::Deparse, and that the code runs
# correctly in a hot loop.

SKIP: {
	eval { require B::Deparse; 1 }
		or skip 'B::Deparse not available', 3;

	# Fast path: a flat array pattern lowers to a single native list-assignment
	# (my (...) = @{...}), not a chain of per-element fetches.
	my $flat = sub {
		use Destructure::Declare;
		let [$a, $b] = $_[0];
		($a, $b);
	};
	my $flat_text = B::Deparse->new->coderef2text($flat);
	like($flat_text, qr/my\s*\(.*\)\s*=\s*\@\{/s,
		'flat pattern deparses to a native list-assignment');
	unlike($flat_text, qr/Destructure::Declare::/,
		'fast path: no runtime call back into the module');

	# General path: a nested pattern lowers to plain element access.
	my $nested = sub {
		use Destructure::Declare;
		let {tags => [$first]} = $_[0];
		$first;
	};
	my $nested_text = B::Deparse->new->coderef2text($nested);
	unlike($nested_text, qr/Destructure::Declare::/,
		'general path: no runtime call back into the module');
}

# Behavioral: repeated execution is stable and correct (the lowering is reusable).
my @seen;
for my $n (1 .. 100) {
	let [$x, $y, @rest] = [$n, $n * 2, $n * 3, $n * 4];
	push @seen, "$x:$y:@rest";
}
is($seen[0],  '1:2:3 4',         'loop iteration 1');
is($seen[99], '100:200:300 400', 'loop iteration 100');
is(scalar(@seen), 100, 'all iterations ran');

done_testing;
