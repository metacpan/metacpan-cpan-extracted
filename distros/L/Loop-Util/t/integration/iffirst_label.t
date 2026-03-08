use Test2::V0;
use Loop::Util;

my @out;

OUTER: loop(2) {
	INNER: loop(3) {
		iffirst OUTER { push @out, 'hi' }
	}
}

is(
	\@out,
	[ 'hi', 'hi', 'hi' ],
	'iffirst OUTER works for nested loop() forms',
);

@out = ();

OUTER: for my $o ( 1 .. 3 ) {
	loop(2) {
		iflast OUTER { push @out, 'last_for' }
		ifodd OUTER { push @out, 'odd_for' }
		ifeven OUTER { push @out, 'even_for' }
	}
}

is(
	scalar( grep { $_ eq 'last_for' } @out ),
	2,
	'iflast label works for for() containing loop()',
);

is(
	scalar( grep { $_ eq 'odd_for' } @out ),
	4,
	'ifodd label works for for() containing loop()',
);

is(
	scalar( grep { $_ eq 'even_for' } @out ),
	2,
	'ifeven label works for for() containing loop()',
);

OUTER: loop(2) {
	for my $i ( 1 .. 3 ) {
		iffirst OUTER { push @out, 'mix' }
	}
}

is(
	scalar( grep { $_ eq 'mix' } @out ),
	3,
	'iffirst label works for loop() containing for()',
);

for my $keyword ( qw(iffirst iflast ifodd ifeven) ) {
	like(
		dies {
			loop(2) {
				if ( $keyword eq 'iffirst' ) {
					iffirst MISSING { }
				}
				elsif ( $keyword eq 'iflast' ) {
					iflast MISSING { }
				}
				elsif ( $keyword eq 'ifodd' ) {
					ifodd MISSING { }
				}
				else {
					ifeven MISSING { }
				}
			}
		},
		qr/could not find loop label 'MISSING'/,
		"$keyword label reports missing label",
	);
}

done_testing;
