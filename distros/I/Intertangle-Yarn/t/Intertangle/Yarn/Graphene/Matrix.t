#!/usr/bin/env perl

use Test::Most tests => 6;
use Modern::Perl;
use Intertangle::Yarn::Graphene;

subtest "Matrix stringify" => sub {
	my $m = Intertangle::Yarn::Graphene::Matrix->new;
	$m->init_from_float([ 0..15 ]);

	is "$m", <<EOF;
[
    0 1 2 3
    4 5 6 7
    8 9 10 11
    12 13 14 15
]
EOF
};

subtest "Matrix from ArrayRef" => sub {
	my $m = Intertangle::Yarn::Graphene::Matrix->new_from_arrayref(
		[
			[ 1, 0, 0, 0 ],
			[ 0, 1, 0, 0 ],
			[ 0, 0, 1, 0 ],
			[ 0, 0, 0, 0 ],
		]
	);

	is "$m", <<EOF;
[
    1 0 0 0
    0 1 0 0
    0 0 1 0
    0 0 0 0
]
EOF
};

subtest "Matrix from ArrayRef must be correct size" => sub {
	throws_ok {
		Intertangle::Yarn::Graphene::Matrix->new_from_arrayref(
			[
				[ 1, 0, 0, 0 ],
				[ 0, 0, 1, 0 ],
				[ 0, 0, 0, 0 ],
			]
		);
	} qr/4x4/, 'too few rows';

	throws_ok {
		Intertangle::Yarn::Graphene::Matrix->new_from_arrayref(
			[
				[ 1, 0, 0, 0 ],
				[ 0, 0, 1, 0 ],
				[ 0, 0, 0, 0 ],
				[ 0, 0, 0, 0 ],
				[ 0, 0, 0, 0 ],
			]
		);
	} qr/4x4/, 'too many rows';

	throws_ok {
		Intertangle::Yarn::Graphene::Matrix->new_from_arrayref(
			[
				[ 1, 0, 0, 0 ],
				[ 0, 0, 0, 0 ],
				[ 0, 0, 0 ],
				[ 0, 0, 0, 0 ],
			]
		);
	} qr/4x4/, 'too few columns';

	throws_ok {
		Intertangle::Yarn::Graphene::Matrix->new_from_arrayref(
			[
				[ 1, 0, 0, 0 ],
				[ 0, 0, 0, 0,   1 ],
				[ 0, 0, 0, 0 ],
				[ 0, 0, 0, 0 ],
			]
		);
	} qr/4x4/, 'too many columns';
};

subtest "Matrix multiply operator (matrix x matrix)" => sub {
	my $m1 = Intertangle::Yarn::Graphene::Matrix->new_from_arrayref(
		[
			[  3, 0, 0, 0 ],
			[  0, 4, 0, 0 ],
			[  0, 0, 5, 0 ],
			[  0, 0, 0, 0 ],
		]
	);
	my $m2 = Intertangle::Yarn::Graphene::Matrix->new_from_float(
		[ 1..16 ]
	);

	is "@{[ $m1 x $m2 ]}", <<EOF;
[
    3 6 9 12
    20 24 28 32
    45 50 55 60
    0 0 0 0
]
EOF

	is "@{[ $m2 x $m1 ]}", <<EOF;
[
    3 8 15 0
    15 24 35 0
    27 40 55 0
    39 56 75 0
]
EOF
};

subtest "Matrix transform function" => sub {
	my $m = Intertangle::Yarn::Graphene::Matrix->new_from_arrayref(
		[
			[  3, 0, 0, 0 ],
			[  0, 4, 0, 0 ],
			[  0, 0, 5, 0 ],
			[  0, 0, 0, 0 ],
		]
	);

	subtest "Point" => sub {
		my $p_t = $m->transform(
			Intertangle::Yarn::Graphene::Point->new(
				x => 10, y => 10
			)
		);

		is $p_t, [ 30, 40 ], 'correct transform';
	}
};

subtest "Matrix transform operator" => sub {
	is( Intertangle::Yarn::Graphene::Matrix->new_from_arrayref(
		[
			[  3, 0, 0, 0 ],
			[  0, 4, 0, 0 ],
			[  0, 0, 5, 0 ],
			[  0, 0, 0, 0 ],
		]
	) * Intertangle::Yarn::Graphene::Point->new( x => 10, y => 10 ),
		[ 30, 40 ], 'correct transform');
};

done_testing;
