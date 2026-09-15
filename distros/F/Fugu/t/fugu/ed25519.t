#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The vectors of RFC 8032 section 7.1, byte for byte. Each entry
# holds the public key, the message, and the signature, in the
# hexadecimal lines of the document. The secret key of each vector
# stays out of the file: the module verifies, and it never signs.
#
# The operator takes a vector from the document once. No test makes
# one, and no test runs another program to make one.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('Fugu::Ed25519');

my $dir = tempdir( CLEANUP => 1 );

my @VECTORS = (
	{
		name      => 'TEST 1',
		key       => join( '', qw(
		    d75a980182b10ab7d54bfed3c964073a
		    0ee172f3daa62325af021a68f707511a
		) ),
		message   => '',
		signature => join( '', qw(
		    e5564300c360ac729086e2cc806e828a
		    84877f1eb8e5d974d873e06522490155
		    5fb8821590a33bacc61e39701cf9b46b
		    d25bf5f0595bbe24655141438e7a100b
		) ),
	},
	{
		name      => 'TEST 2',
		key       => join( '', qw(
		    3d4017c3e843895a92b70aa74d1b7ebc
		    9c982ccf2ec4968cc0cd55f12af4660c
		) ),
		message   => '72',
		signature => join( '', qw(
		    92a009a9f0d4cab8720e820b5f642540
		    a2b27b5416503f8fb3762223ebdb69da
		    085ac1e43e15996e458f3613d0f11d8c
		    387b2eaeb4302aeeb00d291612bb0c00
		) ),
	},
	{
		name      => 'TEST 3',
		key       => join( '', qw(
		    fc51cd8e6218a1a38da47ed00230f058
		    0816ed13ba3303ac5deb911548908025
		) ),
		message   => 'af82',
		signature => join( '', qw(
		    6291d657deec24024827e69c3abe01a3
		    0ce548a284743a445e3680d7db5ac3ac
		    18ff9b538d16f290ae67f760984dc659
		    4a7c15e9716ed28dc027beceea1ec40a
		) ),
	},
	{
		name      => 'TEST 1024',
		key       => join( '', qw(
		    278117fc144c72340f67d0f2316e8386
		    ceffbf2b2428c9c51fef7c597f1d426e
		) ),
		message   => join( '', qw(
		    08b8b2b733424243760fe426a4b54908
		    632110a66c2f6591eabd3345e3e4eb98
		    fa6e264bf09efe12ee50f8f54e9f77b1
		    e355f6c50544e23fb1433ddf73be84d8
		    79de7c0046dc4996d9e773f4bc9efe57
		    38829adb26c81b37c93a1b270b20329d
		    658675fc6ea534e0810a4432826bf58c
		    941efb65d57a338bbd2e26640f89ffbc
		    1a858efcb8550ee3a5e1998bd177e93a
		    7363c344fe6b199ee5d02e82d522c4fe
		    ba15452f80288a821a579116ec6dad2b
		    3b310da903401aa62100ab5d1a36553e
		    06203b33890cc9b832f79ef80560ccb9
		    a39ce767967ed628c6ad573cb116dbef
		    efd75499da96bd68a8a97b928a8bbc10
		    3b6621fcde2beca1231d206be6cd9ec7
		    aff6f6c94fcd7204ed3455c68c83f4a4
		    1da4af2b74ef5c53f1d8ac70bdcb7ed1
		    85ce81bd84359d44254d95629e9855a9
		    4a7c1958d1f8ada5d0532ed8a5aa3fb2
		    d17ba70eb6248e594e1a2297acbbb39d
		    502f1a8c6eb6f1ce22b3de1a1f40cc24
		    554119a831a9aad6079cad88425de6bd
		    e1a9187ebb6092cf67bf2b13fd65f270
		    88d78b7e883c8759d2c4f5c65adb7553
		    878ad575f9fad878e80a0c9ba63bcbcc
		    2732e69485bbc9c90bfbd62481d9089b
		    eccf80cfe2df16a2cf65bd92dd597b07
		    07e0917af48bbb75fed413d238f5555a
		    7a569d80c3414a8d0859dc65a46128ba
		    b27af87a71314f318c782b23ebfe808b
		    82b0ce26401d2e22f04d83d1255dc51a
		    ddd3b75a2b1ae0784504df543af8969b
		    e3ea7082ff7fc9888c144da2af58429e
		    c96031dbcad3dad9af0dcbaaaf268cb8
		    fcffead94f3c7ca495e056a9b47acdb7
		    51fb73e666c6c655ade8297297d07ad1
		    ba5e43f1bca32301651339e22904cc8c
		    42f58c30c04aafdb038dda0847dd988d
		    cda6f3bfd15c4b4c4525004aa06eeff8
		    ca61783aacec57fb3d1f92b0fe2fd1a8
		    5f6724517b65e614ad6808d6f6ee34df
		    f7310fdc82aebfd904b01e1dc54b2927
		    094b2db68d6f903b68401adebf5a7e08
		    d78ff4ef5d63653a65040cf9bfd4aca7
		    984a74d37145986780fc0b16ac451649
		    de6188a7dbdf191f64b5fc5e2ab47b57
		    f7f7276cd419c17a3ca8e1b939ae49e4
		    88acba6b965610b5480109c8b17b80e1
		    b7b750dfc7598d5d5011fd2dcc5600a3
		    2ef5b52a1ecc820e308aa342721aac09
		    43bf6686b64b2579376504ccc493d97e
		    6aed3fb0f9cd71a43dd497f01f17c0e2
		    cb3797aa2a2f256656168e6c496afc5f
		    b93246f6b1116398a346f1a641f3b041
		    e989f7914f90cc2c7fff357876e506b5
		    0d334ba77c225bc307ba537152f3f161
		    0e4eafe595f6d9d90d11faa933a15ef1
		    369546868a7f3a45a96768d40fd9d034
		    12c091c6315cf4fde7cb68606937380d
		    b2eaaa707b4c4185c32eddcdd306705e
		    4dc1ffc872eeee475a64dfac86aba41c
		    0618983f8741c5ef68d3a101e8a3b8ca
		    c60c905c15fc910840b94c00a0b9d0
		) ),
		signature => join( '', qw(
		    0aab4c900501b3e24d7cdf4663326a3a
		    87df5e4843b2cbdb67cbf6e460fec350
		    aa5371b1508f9f4528ecea23c436d94b
		    5e8fcd4f681e30a6ac00a9704a188a03
		) ),
	},
	{
		name      => 'TEST SHA(abc)',
		key       => join( '', qw(
		    ec172b93ad5e563bf4932c70e1245034
		    c35467ef2efd4d64ebf819683467e2bf
		) ),
		message   => join( '', qw(
		    ddaf35a193617abacc417349ae204131
		    12e6fa4e89a97ea20a9eeee64b55d39a
		    2192992a274fc1a836ba3c23a3feebbd
		    454d4423643ce80e2a9ac94fa54ca49f
		) ),
		signature => join( '', qw(
		    dc2a4459e7369633a52b1bf277839a00
		    201009a3efbf3ecb69bea2186c26b589
		    09351fc9ac90b3ecfdfbc7c66431e030
		    3dca179c138ac17ad9bef1177331a704
		) ),
	},
);

# bytes($hex):
#	The byte string of one hexadecimal field of a vector.
sub bytes ($hex)
{
	return pack 'H*', $hex;
}

# flip($bytes, $index):
#	The byte string with the lowest bit of one byte turned over.
sub flip ( $bytes, $index )
{
	substr( $bytes, $index, 1 ) =
	    chr( ord( substr $bytes, $index, 1 ) ^ 1 );
	return $bytes;
}

# write_file($path, $bytes):
#	Write a fixture file, and return its path.
sub write_file ( $path, $bytes )
{
	open my $fh, '>', $path or die "Cannot write $path: $!";
	binmode $fh;
	print {$fh} $bytes;
	close $fh or die "Cannot close $path: $!";
	return $path;
}

subtest 'the constants hold the documented values' => sub {
	is( Fugu::Ed25519::KEY_SIZE(), 32, 'KEY_SIZE is 32' );
	is( Fugu::Ed25519::SIGNATURE_SIZE(),
		64, 'SIGNATURE_SIZE is 64' );
};

subtest 'the module cannot sign' => sub {
	ok( !Fugu::Ed25519->can('sign'),    'no sign method exists' );
	ok( !Fugu::Ed25519->can('keypair'), 'no keypair method exists' );
};

subtest 'each vector of RFC 8032 section 7.1 verifies' => sub {
	my $verifier = Fugu::Ed25519->new;

	for my $vector (@VECTORS) {
		is(
			$verifier->verify(
				key       => bytes( $vector->{key} ),
				signature => bytes( $vector->{signature} ),
				message   => bytes( $vector->{message} ),
			),
			1,
			"$vector->{name} verifies"
		);
		is( $verifier->error, undef,
			"$vector->{name} reports no reason" );
	}
};

subtest 'one turned bit in the signature fails' => sub {
	my $verifier = Fugu::Ed25519->new;

	for my $vector (@VECTORS) {
		is(
			$verifier->verify(
				key       => bytes( $vector->{key} ),
				signature =>
				    flip( bytes( $vector->{signature} ), 0 ),
				message => bytes( $vector->{message} ),
			),
			0,
			"$vector->{name} fails with one turned bit"
		);

		# A signature that does not verify is no shape error.
		is( $verifier->error, undef, 'and it reports no reason' );
	}
};

subtest 'one turned bit in the message fails' => sub {
	my $verifier = Fugu::Ed25519->new;

	for my $vector (@VECTORS) {

		# The empty message holds no bit to turn over, so the
		# changed message of that vector is one zero byte.
		my $message = bytes( $vector->{message} );
		$message = length $message ? flip( $message, 0 ) : "\x00";

		is(
			$verifier->verify(
				key       => bytes( $vector->{key} ),
				signature => bytes( $vector->{signature} ),
				message   => $message,
			),
			0,
			"$vector->{name} fails against a changed message"
		);
	}
};

subtest 'a scalar at or above the group order fails' => sub {
	my $verifier = Fugu::Ed25519->new;
	my $vector   = $VECTORS[0];

	# The group order itself, little-endian, and a scalar with
	# every bit set, which is far above it.
	my $order = 'edd3f55c1a631258d69cf7a2def9de14'
	    . '00000000000000000000000000000010';

	for my $scalar ( $order, 'ff' x 32 ) {
		my $signature =
		    substr( bytes( $vector->{signature} ), 0, 32 )
		    . bytes($scalar);

		is(
			$verifier->verify(
				key       => bytes( $vector->{key} ),
				signature => $signature,
				message   => bytes( $vector->{message} ),
			),
			0,
			'the scalar ' . substr( $scalar, 0, 8 ) . ' fails'
		);
		is( $verifier->error, undef, 'and it reports no reason' );
	}
};

subtest 'an encoding that decodes to no point fails' => sub {
	my $verifier = Fugu::Ed25519->new;
	my $vector   = $VECTORS[0];

	# A y of 7 has no square root on the curve. A y with every
	# bit set is above p, so it is no canonical encoding.
	my @encodings = ( "\x07" . "\x00" x 31, "\xFF" x 32 );

	for my $encoding (@encodings) {
		is(
			$verifier->verify(
				key       => bytes( $vector->{key} ),
				signature => $encoding
				    . substr( bytes( $vector->{signature} ),
					32 ),
				message => bytes( $vector->{message} ),
			),
			0,
			'a point of the signature that decodes to no point'
			    . ' fails'
		);

		is(
			$verifier->verify(
				key       => $encoding,
				signature => bytes( $vector->{signature} ),
				message   => bytes( $vector->{message} ),
			),
			0,
			'a public key that decodes to no point fails'
		);
	}
};

# A re-encoding of a point in an RFC 8032 vector proves nothing about
# the two canonical guards: the challenge scalar hashes the encoding
# of R and of the public key, so a changed encoding changes the hash,
# and the check then fails for that reason alone. The neutral point
# breaks that tie. [k]A is the neutral point for every k when A is
# the neutral point, so the signature of R the neutral point and S of
# zero verifies against any message. The encoding alone then decides
# the answer, and each guard carries its case.
subtest 'a non-canonical encoding of one point fails' => sub {
	my $verifier = Fugu::Ed25519->new;

	# The neutral point is x of zero and y of one. Two encodings
	# reach the same point, and a decoder must take neither: y of
	# one with the sign bit set, which asks for the other x of a
	# zero x, and y of 1 + p, which reduces to y of one, the
	# point under test.
	my $canonical = "\x01" . "\x00" x 31;
	my $sign_set  = "\x01" . "\x00" x 30 . "\x80";
	my $above_p   = "\xEE" . "\xFF" x 30 . "\x7F";
	my $scalar    = "\x00" x 32;
	my $message   = 'the neutral point verifies every message';

	is(
		$verifier->verify(
			key       => $canonical,
			signature => $canonical . $scalar,
			message   => $message,
		),
		1,
		'the canonical encoding of the point verifies'
	);

	for my $case (
		[ 'the sign bit of a zero x', $sign_set ],
		[ 'a y above p',              $above_p ] )
	{
		my ( $name, $encoding ) = @$case;

		is(
			$verifier->verify(
				key       => $encoding,
				signature => $canonical . $scalar,
				message   => $message,
			),
			0,
			"a public key that holds $name fails"
		);

		is(
			$verifier->verify(
				key       => $canonical,
				signature => $encoding . $scalar,
				message   => $message,
			),
			0,
			"a signature R that holds $name fails"
		);
	}
};

subtest 'a shape error returns undef with a reason' => sub {
	my $verifier  = Fugu::Ed25519->new;
	my $vector    = $VECTORS[1];
	my $key       = bytes( $vector->{key} );
	my $signature = bytes( $vector->{signature} );
	my $message   = bytes( $vector->{message} );

	my @cases = (
		[
			'a key of 31 bytes', qr/32 bytes/,
			{ key => substr( $key, 0, 31 ) }
		],
		[
			'a signature of 65 bytes', qr/64 bytes/,
			{ signature => $signature . "\x00" }
		],
		[
			'a message with a character above 255',
			qr/above 255/, { message => "w\x{105}" }
		],
		[
			'a key with a character above 255',
			qr/above 255/, { key => "w\x{105}" }
		],
		[ 'an absent key', qr/necessary/, { key => undef } ],
		[
			'an absent signature', qr/necessary/,
			{ signature => undef }
		],
		[
			'neither a message nor a file',
			qr/needs a message/, { message => undef }
		],
		[
			'a message and a file together', qr/never both/,
			{ file => "$dir/absent.msg" }
		],
		[
			'a file that does not open', qr/cannot read/,
			{ message => undef, file => "$dir/absent.msg" }
		],
	);

	for my $case (@cases) {
		my ( $name, $reason, $override ) = @$case;
		my %args = (
			key       => $key,
			signature => $signature,
			message   => $message,
			%$override,
		);

		is( $verifier->verify(%args), undef, "$name returns undef" );
		like( $verifier->error, $reason, 'and the reason names it' );
	}

	# The reason of one call must not survive the next one.
	is(
		$verifier->verify(
			key       => $key,
			signature => $signature,
			message   => $message,
		),
		1,
		'a good call after a shape error verifies'
	);
	is( $verifier->error, undef, 'and it clears the reason' );
};

subtest 'the file form and the message form agree' => sub {
	my $verifier = Fugu::Ed25519->new;
	my ($vector) = grep { $_->{name} eq 'TEST 1024' } @VECTORS;

	my $path =
	    write_file( "$dir/vector.msg", bytes( $vector->{message} ) );
	is(
		$verifier->verify(
			key       => bytes( $vector->{key} ),
			signature => bytes( $vector->{signature} ),
			file      => $path,
		),
		1,
		'the file form verifies the 1023-byte vector'
	);

	# A message of 1 MiB. The module cannot sign, so no signature
	# of it exists, and both forms must give the same 0.
	my $big  = 'z' x ( 1024 * 1024 );
	my $file = write_file( "$dir/big.msg", $big );
	my %args = (
		key       => bytes( $vector->{key} ),
		signature => bytes( $vector->{signature} ),
	);

	my $by_message = $verifier->verify( %args, message => $big );
	my $by_file    = $verifier->verify( %args, file    => $file );
	is( $by_file, $by_message,
		'both forms give one answer over 1 MiB' );
	is( $by_file, 0, 'and the answer is that the signature fails' );
};

done_testing();
