use Test2::V0;
use Loop::Util;

my @array = qw(foo bar baz);

my @out;

for my $i (@array) {
	iffirst { push @out, "FIRST"; }
	push @out, $i;
	iflast  { push @out, "FINAL"; }
	push @out, uc($i);
}

is(
	\@out,
	[ "FIRST", "foo", "FOO", "bar", "BAR", "baz", "FINAL", "BAZ" ]
);

my $x = '';
for (1) {
	# Only one loop, so this is always the first iteration.
	iffirst { $x .= 'a' }
	iffirst { $x .= 'b' }
	iffirst { $x .= 'c' }
}

is( $x, 'abc', 'iffirst multiple times in the same loop iteration' );

my $str = '';
OUTER: loop(2) {
	my $ix = __IX__;
	INNER: loop(2) {
		iffirst {
			$str .= $ix . __IX__;
		}
	}
}

is( $str, '0010' );

done_testing;
