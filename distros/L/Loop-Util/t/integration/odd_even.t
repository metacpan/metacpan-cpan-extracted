use Test2::V0;
use Loop::Util;

my @out;

for my $item ( qw( a b c d ) ) {
	ifodd {
		push @out, "odd:$item";
	}
	else {
		push @out, "even:$item";
	}
}

is(
	\@out,
	[
		"odd:a", "even:b", "odd:c", "even:d",
	],
	"ifodd supports else in foreach"
);

@out = ();
for my $item ( qw( a b c d ) ) {
	ifeven {
		push @out, "even:$item";
	}
	else {
		push @out, "odd:$item";
	}
}

is(
	\@out,
	[
		"odd:a", "even:b", "odd:c", "even:d",
	],
	"ifeven supports else in foreach"
);

@out = ();
my $e_while = do {
	local $@;
	eval q{
		my $i = 0;
		while ( $i++ < 4 ) {
			ifeven { }
		}
	};
	$@;
};

like( $e_while, qr/ifeven only works in for\/foreach loops/, "ifeven in while dies" );

for (1) {
	# This loop only ever has one iteration.
	# One is an odd number.
	ifodd  { pass; }
	ifodd  { pass; }
	ifodd  { pass; }
	ifodd  { pass; }
}

@out = ();
my @nums = ( 1 .. 10 );
for my $x ( @nums ) {
	next if $x % 2;
	ifeven {
		push @out, "even:$x";
	}
	else {
		push @out, "odd:$x";
	}
}

is( \@out, [ 'even:2', 'even:4', 'even:6', 'even:8', 'even:10' ], "works properly" );

done_testing;
