use Test2::V0;
use Loop::Util;

my @array = qw(foo bar baz);

my @out;

sub do_first { iffirst { push @out, "FIRST" } }
sub do_last  { iflast  { push @out, "FINAL" } }

for my $i (@array) {
	do_first();
	push @out, $i;
	do_last();
	push @out, uc($i);
}

is(
	\@out,
	[ "FIRST", "foo", "FOO", "bar", "BAR", "baz", "FINAL", "BAZ" ]
);

done_testing;
