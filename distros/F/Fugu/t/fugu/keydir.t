#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Guards for Fugu::KeyDir
#
# The module holds the names, the order and the generated text of a
# published key directory. It holds no policy, so each test supplies
# the organization word, the purposes and the dates.
#
# The order tests read the byte sequence, not a set. A site build
# writes the index page and the KEYS file on every build, so an
# unstable order would make a diff on each run.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('Fugu::KeyDir');

my $kd = Fugu::KeyDir->new( org => 'fugubsd' );

# An armored body for the KEYS tests. The bytes never reach a parser
# here: keys_file copies the field as text.
use constant ARMOR => "-----BEGIN PGP PUBLIC KEY BLOCK-----\n\n"
    . "mDMEfake\n=abcd\n-----END PGP PUBLIC KEY BLOCK-----";

subtest 'new holds the organization word' => sub {
	is( $kd->org, 'fugubsd', 'org reports the word' );

	ok( !eval { Fugu::KeyDir->new; 1 }, 'new dies for an absent org' );
	like( $@, qr/necessary/, 'and the reason says so' );

	ok( !eval { Fugu::KeyDir->new( org => 'FuguBSD' ); 1 },
		'new dies for an upper-case org' );
	ok( !eval { Fugu::KeyDir->new( org => 'fugu-bsd' ); 1 },
		'new dies for an org with a hyphen' );
	ok( !eval { Fugu::KeyDir->new( org => '1fugu' ); 1 },
		'new dies for an org that starts on a digit' );
};

subtest 'the module runs no command and cannot sign' => sub {
	for my $name (qw(sign generate rotate)) {
		ok( !Fugu::KeyDir->can($name), "no $name method exists" );
	}
};

subtest 'parse_name reads a valid name of each type' => sub {
	my $signify = $kd->parse_name('fugubsd-1-release.pub');
	is_deeply(
		$signify,
		{
			stem    => 'fugubsd-1-release',
			org     => 'fugubsd',
			serial  => 1,
			purpose => 'release',
			type    => 'signify',
		},
		'a .pub name gives the signify type'
	);

	my $openpgp = $kd->parse_name('fugubsd-12-mail.asc');
	is( $openpgp->{type},   'openpgp', 'a .asc name gives the openpgp type' );
	is( $openpgp->{serial}, 12,        'a two-digit serial reads as 12' );

	# The serial must be a number, so a sort of 2 and 10 puts 10
	# second. A text sort would put 10 first.
	my @serials =
	    map { $kd->parse_name($_)->{serial} }
	    qw(fugubsd-2-release.pub fugubsd-10-release.pub);
	is_deeply( [ sort { $a <=> $b } @serials ],
		[ 2, 10 ], 'a serial sorts as a number' );

	is( $kd->parse_name('fugubsd-1-code-signing.pub')->{purpose},
		'code-signing', 'a purpose can hold a hyphen' );
};

subtest 'parse_name rejects a bad name' => sub {
	my %bad = (
		'fugustx-1-release.pub'  => qr/names the organization fugustx/,
		'fugubsd-01-release.pub' => qr/serial is padded/,
		'fugubsd-0-release.pub'  => qr/serial is zero/,
		'fugubsd-1-release.key'  => qr/unknown key extension/,
		'fugubsd-1-Release.pub'  => qr/does not match/,
		'fugubsd-1-release'      => qr/holds no extension/,
		'fugubsd-release.pub'    => qr/does not match/,
		'keys/fugubsd-1-release.pub' => qr/holds a solidus/,
		''                           => qr/empty/,
	);

	for my $name ( sort keys %bad ) {
		is( $kd->parse_name($name), undef, "'$name' fails" );
		like( $kd->error, $bad{$name}, "and the reason names the fault" );
	}

	# An upper-case extension needs its own reason. "holds no
	# extension" sends a reader to look for a missing dot.
	for my $name (qw(fugubsd-1-release.PUB fugubsd-1-release.Asc)) {
		is( $kd->parse_name($name), undef, "'$name' fails" );
		like( $kd->error, qr/extension must be lower case/,
			'and the reason names the case, not a missing dot' );
	}

	is( $kd->parse_name(undef), undef, 'undef fails' );
};

subtest 'name_for is the inverse of parse_name' => sub {
	is( $kd->name_for( serial => 1, purpose => 'release', type => 'signify' ),
		'fugubsd-1-release.pub', 'a signify name' );
	is( $kd->name_for( serial => 2, purpose => 'mail', type => 'openpgp' ),
		'fugubsd-2-mail.asc', 'an openpgp name' );

	# The round trip must return the parts that went in.
	for my $type (qw(signify openpgp)) {
		my $name = $kd->name_for(
			serial  => 7,
			purpose => 'release',
			type    => $type,
		);
		my $parts = $kd->parse_name($name);
		is( $parts->{serial},  7,         "$type round trip: serial" );
		is( $parts->{purpose}, 'release', "$type round trip: purpose" );
		is( $parts->{type},    $type,     "$type round trip: type" );
	}

	is( $kd->name_for( serial => 0, purpose => 'release', type => 'signify' ),
		undef, 'a zero serial fails' );
	is( $kd->name_for( serial => '01', purpose => 'x', type => 'signify' ),
		undef, 'a padded serial fails' );
	is( $kd->name_for( serial => 1, purpose => 'Release', type => 'signify' ),
		undef, 'an upper-case purpose fails' );
	is( $kd->name_for( serial => 1, purpose => 'release', type => 'gpg' ),
		undef, 'an unknown type fails' );
	like( $kd->error, qr/unknown key type/, 'and the reason says so' );
};

subtest 'the serial holds a digit bound' => sub {
	# A serial above the bound leaves the integer range and
	# becomes a float. next_serial would then hand name_for a
	# value such as 1e+20, and the rotation would stall with a
	# reason that names neither the file nor the true fault.
	my $huge = 'fugubsd-' . ( '9' x 20 ) . '-release.pub';
	is( $kd->parse_name($huge), undef, 'a 20-digit serial fails' );
	like( $kd->error, qr/holds 20 digits, and the bound is 9/,
		'and the reason names the count and the bound' );

	is( $kd->next_serial( [$huge], 'release' ),
		undef, 'next_serial fails on it too' );

	# The bound itself must still parse.
	my $at = 'fugubsd-999999999-release.pub';
	ok( $kd->parse_name($at), 'a 9-digit serial parses' );

	# name_for holds the same bound, so the two stay inverses. A
	# name that name_for built and parse_name rejected would break
	# every caller that writes a file and reads it back.
	is(
		$kd->name_for(
			serial  => 1_000_000_000,
			purpose => 'release',
			type    => 'signify'
		),
		undef,
		'name_for rejects a serial above the bound'
	);
	like( $kd->error, qr/holds 10 digits/, 'and the reason says so' );

	my $built = $kd->name_for(
		serial  => 999_999_999,
		purpose => 'release',
		type    => 'signify'
	);
	ok( $kd->parse_name($built),
		'a name that name_for built at the bound still parses' );

	is( Fugu::KeyDir::MAX_SERIAL_DIGITS(), 9, 'the bound is 9 digits' );
};

subtest 'next_serial adds one to the highest of the purpose' => sub {
	is( $kd->next_serial( [], 'release' ),
		1, 'an empty directory starts at 1' );

	is(
		$kd->next_serial(
			[qw(fugubsd-1-release.pub fugubsd-3-release.pub)],
			'release'
		),
		4,
		'the highest serial decides, not the count'
	);

	# A second purpose starts at 1, so a compromise of one purpose
	# leaves the others in force.
	my @names = qw(
	    fugubsd-1-release.pub
	    fugubsd-2-release.pub
	    fugubsd-5-mail.asc
	);
	is( $kd->next_serial( \@names, 'release' ), 3, 'release goes to 3' );
	is( $kd->next_serial( \@names, 'mail' ),    6, 'mail goes to 6' );
	is( $kd->next_serial( \@names, 'code' ),    1, 'a new purpose starts at 1' );

	is( $kd->next_serial( ['fugubsd-01-release.pub'], 'release' ),
		undef, 'a name that parse_name rejects fails' );
	like( $kd->error, qr/padded/, 'and the reason names the fault' );

	is( $kd->next_serial( [], '' ), undef, 'an empty purpose fails' );

	# The answer must pass name_for. At the top of the range the
	# sum leaves the bound, and a caller that took the answer
	# would stall one step later with a reason that names neither
	# the purpose nor the bound.
	is( $kd->next_serial( ['fugubsd-999999999-release.pub'], 'release' ),
		undef, 'a purpose at the highest allowed serial fails' );
	like( $kd->error, qr/highest serial that the digit bound allows/,
		'and the reason names the bound' );

	# A purpose below the top still answers.
	is( $kd->next_serial( ['fugubsd-999999998-release.pub'], 'release' ),
		999_999_999, 'one below the top still answers' );

	ok( !eval { $kd->next_serial( 'not a reference', 'release' ); 1 },
		'a non-reference dies' );
};

subtest 'order writes one byte sequence' => sub {
	my @keys = (
		{ name => 'fugubsd-1-release.pub', status => 'retired' },
		{ name => 'fugubsd-3-release.pub', status => 'current' },
		{ name => 'fugubsd-4-release.pub', status => 'next' },
		{ name => 'fugubsd-2-release.pub', status => 'retired' },
	);

	my $ordered = $kd->order( \@keys ) or diag( $kd->error );
	is_deeply(
		[ map { $_->{name} } @$ordered ],
		[
			'fugubsd-3-release.pub',
			'fugubsd-4-release.pub',
			'fugubsd-2-release.pub',
			'fugubsd-1-release.pub',
		],
		'current, then next, then retired by descending serial'
	);

	# The method adds the parts of the name, so a caller reads the
	# serial without a second parse.
	is( $ordered->[0]{serial},  3,         'the entry holds the serial' );
	is( $ordered->[0]{purpose}, 'release', 'and the purpose' );
	is( $ordered->[0]{type},    'signify', 'and the type' );
	is( $ordered->[0]{stem}, 'fugubsd-3-release', 'and the stem' );

	# A reversed input must give the same output. Without a total
	# order the two runs would differ.
	my $again = $kd->order( [ reverse @keys ] );
	is_deeply( [ map { $_->{name} } @$again ],
		[ map { $_->{name} } @$ordered ],
		'a reversed input gives the same order' );

	# Two purposes at one serial: the purpose breaks the tie. The
	# pair must be one where the purpose and the name disagree,
	# or the name comparator alone would satisfy the assertion.
	# The name puts the hyphen of code-signing before the dot of
	# code, and the purpose puts code first.
	my $mixed = $kd->order(
		[
			{
				name   => 'fugubsd-1-code-signing.pub',
				status => 'current'
			},
			{ name => 'fugubsd-1-code.pub', status => 'current' },
		]
	);
	is_deeply(
		[ map { $_->{name} } @$mixed ],
		[ 'fugubsd-1-code.pub', 'fugubsd-1-code-signing.pub' ],
		'the purpose breaks a tie, and it beats the name'
	);

	# The name tie-break is reachable in a set that
	# check_statuses accepts: two retired keys of one purpose at
	# one serial, with two types. The rule allows many retired
	# keys, so this set is legitimate and the comparator matters.
	my @valid_tie = (
		{ name => 'fugubsd-1-mail.asc', status => 'retired' },
		{ name => 'fugubsd-1-mail.pub', status => 'retired' },
		{ name => 'fugubsd-2-mail.asc', status => 'current' },
	);
	is( $kd->check_statuses( \@valid_tie ), 1, 'the tied set is valid' );
	is_deeply(
		[ map { $_->{name} } @{ $kd->order( \@valid_tie ) } ],
		[ map { $_->{name} }
			@{ $kd->order( [ reverse @valid_tie ] ) } ],
		'and its order does not follow the input'
	);

	# One purpose at one serial with two types: only the name
	# breaks this tie, and without it the order follows the input.
	# Both keys are retired, so check_statuses accepts the set.
	my @two_types = (
		{ name => 'fugubsd-1-mail.pub', status => 'retired' },
		{ name => 'fugubsd-1-mail.asc', status => 'retired' },
	);
	is_deeply(
		[ map { $_->{name} } @{ $kd->order( \@two_types ) } ],
		[ 'fugubsd-1-mail.asc', 'fugubsd-1-mail.pub' ],
		'the name breaks the last tie'
	);
	is_deeply(
		[ map { $_->{name} } @{ $kd->order( [ reverse @two_types ] ) } ],
		[ 'fugubsd-1-mail.asc', 'fugubsd-1-mail.pub' ],
		'and a reversed input gives the same order'
	);

	# The method must not mutate its own input.
	is( scalar keys %{ $keys[0] }, 2, 'the input key keeps its two fields' );
};

subtest 'order holds each key to the vocabulary' => sub {
	is(
		$kd->order(
			[ { name => 'fugubsd-1-release.pub', status => 'live' } ]
		),
		undef,
		'a status outside the vocabulary fails'
	);
	like( $kd->error, qr/the vocabulary is current, next, retired/,
		'and the reason names the vocabulary' );

	is( $kd->order( [ { name => 'fugubsd-1-release.pub' } ] ),
		undef, 'an absent status fails' );

	is( $kd->order( [] ), undef, 'an empty set fails' );
	like( $kd->error, qr/empty/, 'and the reason says so' );

	is(
		$kd->order(
			[
				{
					name   => 'fugubsd-1-release.pub',
					status => 'current'
				},
				{
					name   => 'fugubsd-1-release.pub',
					status => 'retired'
				},
			]
		),
		undef,
		'one name twice fails'
	);
	like( $kd->error, qr/twice/, 'and the reason says so' );

	ok( !eval { $kd->order('not a reference'); 1 },
		'a non-reference dies' );
	ok( !eval { $kd->order( ['not a hash'] ); 1 },
		'a key that is not a hash reference dies' );
};

subtest 'check_statuses holds one current key for each purpose' => sub {
	my @good = (
		{ name => 'fugubsd-1-release.pub', status => 'retired' },
		{ name => 'fugubsd-2-release.pub', status => 'current' },
		{ name => 'fugubsd-3-release.pub', status => 'next' },
		{ name => 'fugubsd-1-mail.asc',    status => 'current' },
	);
	is( $kd->check_statuses( \@good ), 1, 'a valid set passes' );
	is( $kd->error, undef, 'and it reports no reason' );

	# Two current keys is the dangerous case: a reader cannot tell
	# which key signs a release today.
	my @two_current = (
		{ name => 'fugubsd-1-release.pub', status => 'current' },
		{ name => 'fugubsd-2-release.pub', status => 'current' },
	);
	is( $kd->check_statuses( \@two_current ),
		undef, 'two current keys of one purpose fail' );
	like( $kd->error, qr/release holds 2 current keys/,
		'and the reason names the purpose and the count' );

	my @two_next = (
		{ name => 'fugubsd-1-release.pub', status => 'current' },
		{ name => 'fugubsd-2-release.pub', status => 'next' },
		{ name => 'fugubsd-3-release.pub', status => 'next' },
	);
	is( $kd->check_statuses( \@two_next ),
		undef, 'two next keys of one purpose fail' );
	like( $kd->error, qr/release holds 2 next keys/,
		'and the reason says so' );

	my @no_current =
	    ( { name => 'fugubsd-1-release.pub', status => 'retired' } );
	is( $kd->check_statuses( \@no_current ),
		undef, 'a purpose with no current key fails' );
	like( $kd->error, qr/release holds 0 current keys/,
		'and the reason says so' );

	# A second purpose must not hide the fault of the first.
	my @one_bad = (
		{ name => 'fugubsd-1-release.pub', status => 'current' },
		{ name => 'fugubsd-1-mail.asc',    status => 'retired' },
	);
	is( $kd->check_statuses( \@one_bad ),
		undef, 'one bad purpose beside a good one fails' );
	like( $kd->error, qr/mail holds 0 current keys/,
		'and the reason names the bad purpose' );
};

subtest 'keys_file holds each OpenPGP key in order' => sub {
	my @keys = (
		{
			name        => 'fugubsd-1-mail.asc',
			status      => 'retired',
			armor       => ARMOR,
			fingerprint => 'AAAA',
		},
		{
			name        => 'fugubsd-2-mail.asc',
			status      => 'current',
			armor       => ARMOR,
			fingerprint => 'BBBB',
			since       => '2026-09-06',
		},
		{ name => 'fugubsd-1-release.pub', status => 'current' },
	);

	my $text = $kd->keys_file( \@keys ) or diag( $kd->error );

	# gpg --import reads this file, and it cannot read a signify
	# key, so the signify stem must not appear.
	unlike( $text, qr/fugubsd-1-release/,
		'the file holds no signify key' );

	like( $text, qr/fugubsd-2-mail/, 'the file holds the current key' );
	like( $text, qr/fugubsd-1-mail/, 'and the retired key' );

	# The current key leads, so a reader imports the key in force
	# first.
	ok( index( $text, 'fugubsd-2-mail' ) < index( $text, 'fugubsd-1-mail' ),
		'the current key comes before the retired key' );

	like( $text, qr/^fingerprint: BBBB$/m, 'the comment holds the fingerprint' );
	like( $text, qr/^since: 2026-09-06$/m, 'and the date' );
	like( $text, qr/^status: current$/m,   'and the status' );

	is( scalar( () = $text =~ /BEGIN PGP PUBLIC KEY BLOCK/g ),
		2, 'the file holds two armored bodies' );

	# A set with no OpenPGP key gives empty text, and not a
	# failure: a site can publish signify keys only.
	my $only_signify =
	    $kd->keys_file(
		[ { name => 'fugubsd-1-release.pub', status => 'current' } ] );
	is( $only_signify, '', 'a signify-only set gives empty text' );

	# The empty string is false, so a caller must test defined and
	# never truth. This pins the trap that the sidecar names: a
	# caller that writes 'or die $dir->error' dies with an undef
	# reason on a signify-only set.
	ok( defined $only_signify, 'and the answer is defined' );
	is( $kd->error, undef, 'and no reason is set' );

	# The armored body takes one blank line after it, whatever
	# trailing newline the field held. Two runs then write one
	# byte sequence.
	for my $trailing ( '', "\n", "\n\n\n" ) {
		my $text = $kd->keys_file(
			[
				{
					name   => 'fugubsd-1-mail.asc',
					status => 'current',
					armor  => ARMOR . $trailing,
				}
			]
		);
		is( $text, $kd->keys_file(
				[
					{
						name   => 'fugubsd-1-mail.asc',
						status => 'current',
						armor  => ARMOR,
					}
				]
			),
			'a trailing newline in the armor changes no byte' );
	}

	is(
		$kd->keys_file(
			[ { name => 'fugubsd-1-mail.asc', status => 'current' } ]
		),
		undef,
		'an OpenPGP key with no armor fails'
	);
	like( $kd->error, qr/holds no armor/, 'and the reason says so' );
};

subtest 'keys_file lets no field forge a second block' => sub {
	# One line holds one field. A value with a newline would forge
	# a second field, and the comment block sits in front of an
	# armored body, so it would also forge a whole second block.
	# gpg --import reads that block, so the guard is the whole
	# defence of the file.
	my $forged = "AAAA\nstatus: retired\n\n"
	    . "-----BEGIN PGP PUBLIC KEY BLOCK-----\n\n"
	    . "mDMEforged\n=zzzz\n-----END PGP PUBLIC KEY BLOCK-----";

	for my $field (qw(fingerprint since until)) {
		my $text = $kd->keys_file(
			[
				{
					name   => 'fugubsd-1-mail.asc',
					status => 'current',
					armor  => ARMOR,
					$field => $forged,
				}
			]
		);
		is( $text, undef, "a $field with a newline fails" );
		like( $kd->error, qr/\Qthe $field of fugubsd-1-mail.asc\E/,
			'and the reason names the field and the key' );
	}

	# A bare carriage return is the same fault.
	is(
		$kd->keys_file(
			[
				{
					name        => 'fugubsd-1-mail.asc',
					status      => 'current',
					armor       => ARMOR,
					fingerprint => "AAAA\rBBBB",
				}
			]
		),
		undef,
		'a carriage return fails too'
	);

	# A clean field still passes, so the guard is not a blanket
	# refusal.
	ok(
		$kd->keys_file(
			[
				{
					name        => 'fugubsd-1-mail.asc',
					status      => 'current',
					armor       => ARMOR,
					fingerprint => 'AAAA',
					since       => '2026-09-06',
				}
			]
		),
		'a clean field set still passes'
	);
};

subtest 'keys_file holds one block in each armor field' => sub {
	# One key holds one block. A field with two blocks would
	# publish a second key under one name, and gpg --import would
	# read both, while Fugu::OpenPGP reads the first block only.
	# The index row would then name the first key alone.
	my $two = ARMOR . "\n\n" . ARMOR;
	is(
		$kd->keys_file(
			[
				{
					name   => 'fugubsd-1-mail.asc',
					status => 'current',
					armor  => $two,
				}
			]
		),
		undef,
		'an armor field with two blocks fails'
	);
	like( $kd->error, qr/holds 2 BEGIN and 2 END lines/,
		'and the reason names the count' );

	# Text after the end line would sit in front of the next
	# comment block, and a reader would take it for that block.
	is(
		$kd->keys_file(
			[
				{
					name   => 'fugubsd-1-mail.asc',
					status => 'current',
					armor  => ARMOR
					    . "\nfugubsd-9-evil\nstatus: current\n",
				}
			]
		),
		undef,
		'text after the end line fails'
	);
	like( $kd->error, qr/holds text after its end line/,
		'and the reason says so' );

	# The block must be a public key. Nothing else in this module
	# reads the armored bytes, and the fingerprint field is
	# optional, so no other guard stands in the way of a private
	# key block.
	my $private = ARMOR;
	$private =~ s/PUBLIC KEY/PRIVATE KEY/g;
	is(
		$kd->keys_file(
			[
				{
					name   => 'fugubsd-1-mail.asc',
					status => 'current',
					armor  => $private,
				}
			]
		),
		undef,
		'a PRIVATE KEY BLOCK fails'
	);
	like( $kd->error, qr/publishes a PUBLIC KEY BLOCK/,
		'and the reason names the type' );

	# Text before the begin line lands in front of this key's own
	# body, where a reader takes it for the comment block. A guard
	# on the tail alone leaves this open.
	is(
		$kd->keys_file(
			[
				{
					name   => 'fugubsd-1-mail.asc',
					status => 'current',
					armor  => "fugubsd-9-evil\nstatus: current\n\n"
					    . ARMOR,
				}
			]
		),
		undef,
		'text before the begin line fails'
	);
	like( $kd->error, qr/holds text before its begin line/,
		'and the reason says so' );

	# A trailing newline is not trailing text.
	ok(
		$kd->keys_file(
			[
				{
					name   => 'fugubsd-1-mail.asc',
					status => 'current',
					armor  => ARMOR . "\n\n",
				}
			]
		),
		'a trailing newline still passes'
	);
};

subtest 'index_data holds one row for each key, in order' => sub {
	my @keys = (
		{ name => 'fugubsd-1-release.pub', status => 'retired' },
		{
			name        => 'fugubsd-2-release.pub',
			status      => 'current',
			since       => '2026-09-06',
			fingerprint => 'CCCC',
			email       => 'security@fugubsd.org',
		},
	);

	my $rows = $kd->index_data( \@keys ) or diag( $kd->error );
	is( scalar @$rows, 2, 'one row for each key' );

	is( $rows->[0]{name},        'fugubsd-2-release.pub', 'the current key leads' );
	is( $rows->[0]{serial},      2,                       'the row holds the serial' );
	is( $rows->[0]{purpose},     'release',               'and the purpose' );
	is( $rows->[0]{type},        'signify',               'and the type' );
	is( $rows->[0]{status},      'current',               'and the status' );
	is( $rows->[0]{fingerprint}, 'CCCC',                  'and the fingerprint' );
	is( $rows->[0]{since},       '2026-09-06',            'and the date' );
	is( $rows->[0]{email}, 'security@fugubsd.org', 'and the email' );

	# An absent optional field stays undef, so a template tests
	# one thing and never two.
	ok( exists $rows->[1]{fingerprint},
		'an absent fingerprint still holds the field' );
	is( $rows->[1]{fingerprint}, undef, 'and the value is undef' );
	is( $rows->[1]{until},       undef, 'the same for until' );

	# The method renders no HTML: the site owns the template.
	unlike( join( '', map { join '', grep { defined } values %$_ } @$rows ),
		qr/</, 'no row holds markup' );
};

subtest 'security_txt writes the fields of RFC 9116' => sub {
	my $text = $kd->security_txt(
		contact => 'mailto:security@fugubsd.org',
		expires => '2027-01-01T00:00:00Z',
		encryption =>
		    'https://www.fugubsd.org/keys/fugubsd-1-mail.asc',
	) or diag( $kd->error );

	like( $text, qr/^Contact: mailto:security\@fugubsd\.org$/m,
		'the text holds the contact' );
	like( $text, qr/^Expires: 2027-01-01T00:00:00Z$/m, 'and the expiry' );
	like(
		$text,
		qr{^Encryption: https://www\.fugubsd\.org/keys/fugubsd-1-mail\.asc$}m,
		'and the encryption field'
	);

	# The RFC states that the field order carries the preference
	# of the operator, so Contact leads.
	ok( index( $text, 'Contact:' ) < index( $text, 'Expires:' ),
		'Contact comes before Expires' );
	ok( index( $text, 'Expires:' ) < index( $text, 'Encryption:' ),
		'Expires comes before Encryption' );

	# Many contacts, in the order that the caller named.
	my $many = $kd->security_txt(
		contact => [ 'mailto:a@example.org', 'https://example.org/form' ],
		expires => '2027-01-01T00:00:00Z',
		encryption => [ 'https://example.org/1.asc',
			'https://example.org/2.asc' ],
		languages  => [ 'en', 'sv' ],
	);
	is( scalar( () = $many =~ /^Contact:/mg ), 2, 'two contact fields' );
	is( scalar( () = $many =~ /^Encryption:/mg ), 2, 'two encryption fields' );
	like( $many, qr/^Preferred-Languages: en, sv$/m,
		'the languages join on a comma' );
	ok( index( $many, 'mailto:a@example.org' )
		< index( $many, 'https://example.org/form' ),
		'the contacts keep the order of the caller' );

	is( $kd->security_txt( expires => '2027-01-01T00:00:00Z' ),
		undef, 'an absent contact fails' );
	like( $kd->error, qr/contact is a necessary field/,
		'and the reason says so' );

	is( $kd->security_txt( contact => 'mailto:a@example.org' ),
		undef, 'an absent expiry fails' );
	like( $kd->error, qr/expires is a necessary field/,
		'and the reason says so' );

	# One line holds one field, so an embedded newline would forge
	# a second field.
	is(
		$kd->security_txt(
			contact => "mailto:a\@example.org\nExpires: 1999",
			expires => '2027-01-01T00:00:00Z',
		),
		undef,
		'a value with a newline fails'
	);
	like( $kd->error, qr/holds a newline/, 'and the reason says so' );

	# The languages field joins on a comma, so a value that holds
	# one would forge a second language tag. A tag of RFC 9116
	# never holds a comma.
	is(
		$kd->security_txt(
			contact   => 'mailto:a@example.org',
			expires   => '2027-01-01T00:00:00Z',
			languages => ['en, xx'],
		),
		undef,
		'a language value with a comma fails'
	);
	like( $kd->error, qr/holds a comma/, 'and the reason says so' );

	# The sidecar states that a method dies for an argument of the
	# wrong reference type. Without that test a reference
	# stringifies into the file: a field then reads
	# "Contact: HASH(0x55...)".
	ok(
		!eval {
			$kd->security_txt(
				contact => {},
				expires => '2027-01-01T00:00:00Z'
			);
			1;
		},
		'a reference contact dies'
	);
	ok(
		!eval {
			$kd->security_txt(
				contact => 'mailto:a@example.org',
				expires => ['2027-01-01T00:00:00Z']
			);
			1;
		},
		'an array reference expires dies'
	);
	ok(
		!eval {
			$kd->security_txt(
				contact => [ {} ],
				expires => '2027-01-01T00:00:00Z'
			);
			1;
		},
		'a reference inside a list dies'
	);
};

subtest 'STATUSES names the vocabulary' => sub {
	is_deeply(
		[ Fugu::KeyDir::STATUSES() ],
		[qw(current next retired)],
		'the vocabulary is current, next, retired'
	);
};

done_testing();
