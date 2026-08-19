#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('Fugu::Random');

# The randomness is core Perl. It never skips.
subtest 'random_bytes' => sub {
	for my $length ( 1, 16, 32, 64, 4096 ) {
		my $bytes = Fugu::Random->random_bytes($length);
		is( length($bytes), $length, "$length bytes" );
	}

	isnt(
		Fugu::Random->random_bytes(32),
		Fugu::Random->random_bytes(32),
		'two draws differ'
	);

	ok( !eval { Fugu::Random->random_bytes(0); 1 },
		'a length of zero is a programming error' );
	ok( !eval { Fugu::Random->random_bytes(-1); 1 },
		'a negative length is a programming error' );
	ok( !eval { Fugu::Random->random_bytes(undef); 1 },
		'a missing length is a programming error' );
};

subtest 'random_password' => sub {
	for my $length ( 1, 8, 32, 100 ) {
		is( length( Fugu::Random->random_password($length) ),
			$length, "a password of $length characters" );
	}

	is( length( Fugu::Random->random_password ),
		32, 'the default length is 32' );

	# URL-safe base64: a password survives a shell, a URL and a
	# configuration file with no quoting
	like( Fugu::Random->random_password(64),
		qr{^[A-Za-z0-9_-]+$}, 'the alphabet is URL-safe' );

	isnt(
		Fugu::Random->random_password,
		Fugu::Random->random_password,
		'two passwords differ'
	);

	ok( !eval { Fugu::Random->random_password(0); 1 },
		'a length of zero is a programming error' );
};

done_testing();
