use Test2::V0;
use Loop::Util;

my @array = qw(foo bar baz);

my @out;

for my $i (@array) {

	iffirst { push @out, "FIRST" }
	else    { push @out, "NOT FIRST" }

	push @out, $i;

	iflast  { push @out, "FINAL" }
	else    { push @out, "NOT FINAL" }

	push @out, uc($i);
}

is(
	\@out,
	[ "FIRST",     "foo", "NOT FINAL", "FOO", 
	  "NOT FIRST", "bar", "NOT FINAL", "BAR",
	  "NOT FIRST", "baz", "FINAL",     "BAZ" ]
);

done_testing;
