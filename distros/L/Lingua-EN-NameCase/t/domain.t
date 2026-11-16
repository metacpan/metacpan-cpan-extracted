#!/usr/bin/perl -w

# Domain tests for Lingua::EN::NameCase: equivalence partitioning (EP) and
# boundary value analysis (BVA).
#
# <thinking>
# Input parameters, their partitions and their edges:
#
#  P1  nc: argument count
#        valid   0 (uses $_), 1
#        invalid 2 (just above max)            -> usage_nc, "got list"
#
#  P2  nc: argument type
#        valid   plain string, number, scalar ref, undef, '' , '0'
#        invalid HASH, ARRAY, CODE, GLOB, REF, Regexp, blessed object
#                                              -> usage_nc, "got <TYPE>"
#
#  P3  $MAX_LENGTH (characters)
#        valid   undef (no limit), 0, 1, N-1, N, N+1, very large
#        edge    length == max passes; length == max+1 croaks (too_long)
#        text    counted in characters: emoji, Zalgo and umlauts count as
#                code points, never as bytes
#        not validated (documented, not rejected): negative, non-numeric
#
#  P4  Mac gate: "Mac" + letters
#        2 letters stays, 3 letters is cased unless it ends in a c i o z j
#
#  P5  roman numerals: I .. LXXXIX valid; 90 (XC), IIII, XXXX, LXXXX not
#
#  P6  particles: lone / followed; leading space; HEBREW x SPANISH matrix
#
#  P7  post-nominal: at the end, not at the end, trailing newline
#
#  P8  switches: undef, '', 0, 1, other true values
#
#  P9  NameCase: argument form (scalar, scalar ref, array ref, list),
#        context (list, scalar, void), array size 0, 1, 2, many,
#        invalid: empty call, hash ref, code ref, two refs
#
#  P10 text domains: ASCII, German (umlaut, sharp s), Greek, Cyrillic, CJK,
#        emoji (single, ZWJ family, flag), Zalgo, RTL override, Hebrew,
#        dotted capital I, undecoded bytes
#
# Combinations: MAX_LENGTH at its edge x multibyte text, MAX_LENGTH 0 x false
# values, HEBREW x SPANISH, ROMAN x POSTNOMINAL, array size x MAX_LENGTH.
# </thinking>

use strict;
use warnings;

use Readonly;
use Test::Most;
use lib 't/lib';
use ReturnsOk;

use Lingua::EN::NameCase qw( NameCase nc );

# ----- constants ---------------------------------------------------------

# Exact messages documented in the POD (MESSAGES section).
Readonly my %MSG => (
	usage_nc       => 'Usage: nc [[\]$SCALAR] (got ',
	usage_namecase => 'Usage: $SCALAR|@ARRAY = NameCase [\]$SCALAR|@ARRAY (got ',
	single_arg     => 'NameCase only accepts a single scalar, array or array ref',
);

Readonly my %config => (
	limit      => 10,                # a representative $MAX_LENGTH
	huge_limit => 2**31,             # "very large" partition
	big_length => 100_000,           # a long input, to prove no panic
	max_growth => 3,                 # documented: output <= 3 x input
);

# Non-ASCII text is written with escapes so this file stays strictly ASCII.
Readonly my %TEXT => (
	umlaut     => "m\x{fc}ller",
	umlaut_out => "M\x{fc}ller",
	sharp_s    => "\x{df}",
	sharp_out  => 'Ss',
	strasse    => "stra\x{df}e",
	strasse_up => 'STRASSE',
	e_acute    => "\x{e9}mile",
	e_acute_up => "\x{c9}mile",
	greek      => "\x{3b1}\x{3b2}",
	greek_out  => "\x{391}\x{3b2}",
	cyrillic   => "\x{43f}\x{440}\x{438}",
	cyr_out    => "\x{41f}\x{440}\x{438}",
	cjk        => "\x{5f20}\x{4e09}",
	emoji      => "\x{1F600}",
	emoji_zwj  => "\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467}",
	flag       => "\x{1F1E9}\x{1F1EA}",
	zalgo      => "z\x{0301}\x{0315}\x{0316}\x{0317}a\x{0300}\x{0321}",
	zalgo_out  => "Z\x{0301}\x{0315}\x{0316}\x{0317}a\x{0300}\x{0321}",
	rlo        => "\x{202E}abc",
	rlo_out    => "\x{202E}Abc",
	hebrew     => "\x{5d3}\x{5d5}\x{5d3}",
	dotted_i   => "\x{130}stanbul",
	curly_s    => "fred\x{2019}s",
);

# ----- helpers -----------------------------------------------------------

# Run a block with every package setting at its default, and restore the
# previous values afterwards even if the block dies, so a failing subtest
# cannot leak state into the next.
sub with_settings {
	my ( $settings, $code ) = @_;
	my %saved = (
		HEBREW      => $Lingua::EN::NameCase::HEBREW,
		SPANISH     => $Lingua::EN::NameCase::SPANISH,
		ROMAN       => $Lingua::EN::NameCase::ROMAN,
		POSTNOMINAL => $Lingua::EN::NameCase::POSTNOMINAL,
		MAX_LENGTH  => $Lingua::EN::NameCase::MAX_LENGTH,
	);
	my $ok = eval {
		no warnings 'once';
		$Lingua::EN::NameCase::HEBREW      = 1;
		$Lingua::EN::NameCase::SPANISH     = 0;
		$Lingua::EN::NameCase::ROMAN       = 1;
		$Lingua::EN::NameCase::POSTNOMINAL = 1;
		$Lingua::EN::NameCase::MAX_LENGTH  = undef;
		for my $key ( keys %{$settings} ) {
			no strict 'refs';
			${"Lingua::EN::NameCase::$key"} = $settings->{$key};
		}
		$code->();
		1;
	};
	my $error = $@;
	{
		no warnings 'once';
		$Lingua::EN::NameCase::HEBREW      = $saved{HEBREW};
		$Lingua::EN::NameCase::SPANISH     = $saved{SPANISH};
		$Lingua::EN::NameCase::ROMAN       = $saved{ROMAN};
		$Lingua::EN::NameCase::POSTNOMINAL = $saved{POSTNOMINAL};
		$Lingua::EN::NameCase::MAX_LENGTH  = $saved{MAX_LENGTH};
	}
	die $error unless $ok;
	return;
}

# Call a function and report any warning, so each case also proves that no
# "uninitialized" or "wide character" warning appears for that partition.
sub quiet {
	my ($code) = @_;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my @result = $code->();
	return ( \@warnings, @result );
}

# One equivalence class: input in, expected output, no warning, no crash.
sub partition_is {
	my ( $input, $expected, $label ) = @_;
	my ( $warnings, $got ) = quiet( sub { nc($input) } );
	is( $got, $expected, $label );
	is( scalar @{$warnings}, 0, "$label: no warnings" )
		or diag( join q{}, @{$warnings} );
	return;
}

# ----- P1: nc argument count ---------------------------------------------

subtest 'P1 nc argument count (0, 1, 2 = just above max)' => sub {
	with_settings( {}, sub {
		# zero arguments: falls back to $_
		local $_ = 'john smith';
		is( nc(), 'John Smith', 'valid: no argument uses $_' );

		is( nc('john smith'), 'John Smith', 'valid: one argument' );

		# just above the maximum of one argument
		throws_ok { nc( 'a', 'b' ) } qr/\A\Q$MSG{usage_nc}\Elist\)/,
			'invalid: two arguments -> usage_nc, got list';
		throws_ok { nc( 'a', 'b', 'c' ) } qr/\A\Q$MSG{usage_nc}\Elist\)/,
			'invalid: three arguments -> usage_nc, got list';

		# a failing call must not disturb $_
		is( $_, 'john smith', '$_ untouched by successes and failures' );
	} );
	done_testing();
};

# ----- P2: nc argument type ----------------------------------------------

subtest 'P2 nc argument type partitions' => sub {
	with_settings( {}, sub {
		# valid partitions: one representative each
		partition_is( 'john smith',     'John Smith', 'valid: plain string' );
		partition_is( 12345,            '12345',      'valid: number' );
		partition_is( \'john smith',    'John Smith', 'valid: scalar reference' );
		partition_is( \\'x' x 0 . q{},  q{},          'valid: reference to empty string' );

		# false values come back unchanged, with no warning
		my ( $w, $undef ) = quiet( sub { nc(undef) } );
		is( $undef, undef, 'valid: undef returns undef' );
		is( scalar @{$w}, 0, 'undef: no warning' );
		is( nc(q{}),  q{},  "valid: empty string stays ''" );
		is( nc('0'),  '0',  "valid: '0' stays '0'" );
		is( nc(0),    '0',  'valid: numeric zero' );

		# invalid partitions: one representative of each reference type
		my %invalid = (
			HASH   => {},
			ARRAY  => [],
			CODE   => sub { 1 },
			GLOB   => \*STDOUT,
			REF    => \\'x',
			Regexp => qr/x/,
		);
		for my $type ( sort keys %invalid ) {
			throws_ok { nc( $invalid{$type} ) }
				qr/\A\Q$MSG{usage_nc}\E\Q$type\E\)/,
				"invalid: $type reference -> usage_nc, got $type";
		}

		# a blessed object is reported by its class, made safe for a log
		my $object = bless {}, 'Evil::Class';
		throws_ok { nc($object) } qr/\A\Q$MSG{usage_nc}\EEvil::Class\)/,
			'invalid: blessed hash -> reported by class name';
		my $hostile = bless {}, "Bad\nClass\e[31m";
		throws_ok { nc($hostile) } qr/\A\Q$MSG{usage_nc}\EBad\?Class\?\?31m\)/,
			'invalid: hostile class name is sanitised (no newline or escape)';
		my $long = bless {}, 'A' x 200;
		throws_ok { nc($long) } qr/\A\Q$MSG{usage_nc}\EA{64}\)/,
			'invalid: class name cut to 64 characters (just above the limit)';
	} );
	done_testing();
};

# ----- P3: $MAX_LENGTH boundaries ----------------------------------------

subtest 'P3 $MAX_LENGTH boundaries (min, N-1, N, N+1, unlimited)' => sub {
	my $limit = $config{limit};
	my $at    = 'a' x $limit;
	my $below = 'a' x ( $limit - 1 );
	my $above = 'a' x ( $limit + 1 );
	my $want  = 'A' . ( 'a' x ( $limit - 1 ) );

	with_settings( { MAX_LENGTH => $limit }, sub {
		is( nc($below), 'A' . ( 'a' x ( $limit - 2 ) ), 'N-1: accepted' );
		is( nc($at),    $want,                           'N: accepted (max)' );
		throws_ok { nc($above) }
			qr/\AName is too long: \Q@{[ $limit + 1 ]}\E characters \(the maximum is \Q$limit\E\)/,
			'N+1: rejected with the exact too_long message';
		is( nc(\$at), $want, 'N: a scalar reference obeys the same limit' );
		throws_ok { nc( \$above ) } qr/\AName is too long: /,
			'N+1: a scalar reference obeys the same limit';
	} );

	with_settings( { MAX_LENGTH => undef }, sub {
		my $long = 'a' x $config{big_length};
		is( length nc($long), $config{big_length},
			'undef: no limit, very long name accepted' );
	} );

	with_settings( { MAX_LENGTH => $config{huge_limit} }, sub {
		is( nc('john smith'), 'John Smith', 'very large limit: accepted' );
	} );

	# minimum: a limit of 0 allows only the names that are false
	with_settings( { MAX_LENGTH => 0 }, sub {
		throws_ok { nc('a') }
			qr/\AName is too long: 1 characters \(the maximum is 0\)/,
			'limit 0: one character is already too long';
		is( nc(q{}),  q{},  "limit 0: '' is accepted" );
		is( nc('0'),  '0',  "limit 0: '0' is accepted" );
		is( nc(undef), undef, 'limit 0: undef is accepted' );
	} );

	# limit 1: the smallest limit that admits a real name
	with_settings( { MAX_LENGTH => 1 }, sub {
		is( nc('a'), 'A', 'limit 1: one character accepted' );
		throws_ok { nc('ab') } qr/\(the maximum is 1\)/,
			'limit 1: two characters rejected';
	} );
	done_testing();
};

# ----- P3b: $MAX_LENGTH counts characters, not bytes ---------------------

subtest 'P3b $MAX_LENGTH counts characters (multibyte at the boundary)' => sub {
	# Each name is exactly 3 characters but far more than 3 bytes.
	my %names = (
		umlauts  => "\x{fc}\x{e4}\x{f6}",
		emoji    => "\x{1F600}\x{1F601}\x{1F602}",
		greek    => "\x{3b1}\x{3b2}\x{3b3}",
		zalgo    => "a\x{0301}\x{0302}",
		rlo      => "\x{202E}ab",
	);
	for my $label ( sort keys %names ) {
		my $name = $names{$label};
		is( length $name, 3, "$label: fixture is 3 characters" );
		with_settings( { MAX_LENGTH => 3 }, sub {
			lives_ok { nc($name) } "$label: 3 characters at limit 3 accepted";
		} );
		with_settings( { MAX_LENGTH => 2 }, sub {
			throws_ok { nc($name) }
				qr/\AName is too long: 3 characters \(the maximum is 2\)/,
				"$label: 3 characters at limit 2 rejected, length in characters";
		} );
	}
	done_testing();
};

# ----- P3c: $MAX_LENGTH values outside its documented domain -------------

subtest 'P3c $MAX_LENGTH invalid values are not validated (documented)' => sub {
	# The POD says other values are the caller's responsibility.  The
	# requirement tested here is only that they do not crash the module
	# with an internal error or leave the state changed.
	for my $value ( -1, 'abc', q{}, '1.5' ) {
		with_settings( { MAX_LENGTH => $value }, sub {
			my ( $warnings, $result ) = quiet( sub { eval { nc('john') } } );
			ok( 1, "limit '" . $value . "' does not abort the test run" );
		} );
	}
	is( $Lingua::EN::NameCase::MAX_LENGTH, undef,
		'global MAX_LENGTH restored after the invalid values' );
	done_testing();
};

# ----- P4: Mac gate ------------------------------------------------------

subtest 'P4 Mac prefix: letters after Mac (2, 3, ends in aciozj)' => sub {
	with_settings( {}, sub {
		partition_is( 'macab',     'Macab',     'Mac + 2 letters (below the minimum): unchanged' );
		partition_is( 'macdon',    'MacDon',    'Mac + 3 letters, last letter n: split' );
		partition_is( 'macdonald', 'MacDonald', 'Mac + many letters: split' );

		# each excluded final letter, at the minimum length of 3
		for my $last (qw( a c i o z j )) {
			partition_is( "macab$last", "Macab$last",
				"Mac + 3 letters ending in '$last': not split" );
		}
		# a last letter just outside the excluded set
		partition_is( 'macabn', 'MacAbn', "Mac + 3 letters ending in 'n': split" );

		# Mc has no minimum
		partition_is( 'mca',       'McA',      'Mc + 1 letter (minimum): split' );
		partition_is( 'mcdonald',  'McDonald', 'Mc + letters: split' );
		partition_is( 'mcab',      'McAb',     'Mc + 2 letters: split' );

		# listed exceptions are never split, even at length
		partition_is( 'machado', 'Machado', 'exception prefix: Machado' );
		partition_is( 'mackie',  'Mackie',  'exception prefix: Mackie' );
	} );
	done_testing();
};

# ----- P5: roman numerals ------------------------------------------------

subtest 'P5 roman numerals: valid I..LXXXIX, invalid beyond' => sub {
	with_settings( {}, sub {
		# minimum, a middle value, and the maximum of the valid range
		partition_is( 'i',      'I',      'minimum: I' );
		partition_is( 'xl',     'XL',     'middle: XL (40)' );
		partition_is( 'lxxxix', 'LXXXIX', 'maximum: LXXXIX (89)' );

		# just above the maximum, and malformed numerals
		partition_is( 'xc',    'Xc',    'just above max: XC (90) is not converted' );
		partition_is( 'iiii',  'Iiii',  'malformed: IIII' );
		partition_is( 'xxxx',  'Xxxx',  'malformed: XXXX' );
		partition_is( 'lxxxx', 'Lxxxx', 'malformed: LXXXX' );

		# a numeral is recognised as a whole word only
		partition_is( 'john iii',  'John III',  'trailing numeral' );
		partition_is( 'iii john',  'III John',  'leading numeral' );
		partition_is( 'xiang',     'Xiang',     'numeral letters inside a word' );
	} );
	with_settings( { ROMAN => 0 }, sub {
		partition_is( 'john iii', 'John Iii', 'ROMAN off: numeral not converted' );
	} );
	done_testing();
};

# ----- P6: particles -----------------------------------------------------

subtest 'P6 particles: lone, followed, leading space, switch matrix' => sub {
	with_settings( {}, sub {
		partition_is( 'john van dyke', 'John van Dyke', 'van followed by a word: lower case' );
		partition_is( 'van',           'Van',           'lone van (nothing follows): cased as a name' );
		partition_is( 'john van',      'John Van',      'van at the end: cased as a name' );
		partition_is( 'bob ben david', 'Bob ben David', 'ben after a word: lower case' );
		partition_is( ' ben david',    ' Ben David',    'ben after leading space only: cased' );
		partition_is( 'ben',           'Ben',           'lone ben: cased' );
		partition_is( 'john del toro', 'John del Toro', 'del particle' );
		partition_is( 'ludwig von beethoven', 'Ludwig von Beethoven', 'von particle' );
	} );

	# HEBREW x SPANISH: all four corners on one string
	my %expect = (
		'1,0' => 'John bat David el Bar la Mesa',
		'1,1' => 'John bat David El Bar La Mesa',
		'0,0' => 'John Bat David el Bar la Mesa',
		'0,1' => 'John Bat David El Bar La Mesa',
	);
	for my $combo ( sort keys %expect ) {
		my ( $hebrew, $spanish ) = split /,/, $combo;
		with_settings( { HEBREW => $hebrew, SPANISH => $spanish }, sub {
			is( nc('john bat david el bar la mesa'), $expect{$combo},
				"HEBREW=$hebrew SPANISH=$spanish" );
		} );
	}
	done_testing();
};

# ----- P7: post-nominal letters ------------------------------------------

subtest 'P7 post-nominals: at the end, not at the end, glued, newline' => sub {
	with_settings( {}, sub {
		partition_is( 'john smith phd',   'John Smith PhD',   'at the end: PhD' );
		partition_is( 'phd john smith',   'Phd John Smith',   'not at the end: unchanged rule' );
		partition_is( 'john smith md',    'John Smith MD',    'at the end: MD' );
		partition_is( 'john smithphd',    'John Smithphd',    'glued to the name: not converted' );
		partition_is( 'bob',              'Bob',              'no post-nominal present' );
	} );
	with_settings( { POSTNOMINAL => 0 }, sub {
		partition_is( 'john smith phd', 'John Smith Phd', 'POSTNOMINAL off' );
	} );
	done_testing();
};

# ----- P8: switch values -------------------------------------------------

subtest 'P8 switch values: undef, empty, 0, 1, other true' => sub {
	my %falsy  = ( undef => undef, empty => q{}, zero => 0, string_zero => '0' );
	my %truthy = ( one => 1, two => 2, word => 'yes' );

	for my $label ( sort keys %falsy ) {
		with_settings( { ROMAN => $falsy{$label}, POSTNOMINAL => $falsy{$label} }, sub {
			my ( $warnings, $got ) = quiet( sub { nc('henry viii phd') } );
			is( $got, 'Henry Viii Phd', "ROMAN/POSTNOMINAL $label: both off" );
			is( scalar @{$warnings}, 0, "$label: no warnings" );
		} );
	}
	for my $label ( sort keys %truthy ) {
		with_settings( { ROMAN => $truthy{$label}, POSTNOMINAL => $truthy{$label} }, sub {
			is( nc('henry viii phd'), 'Henry VIII PhD', "ROMAN/POSTNOMINAL $label: both on" );
		} );
	}
	done_testing();
};

# ----- combinatorial: ROMAN x POSTNOMINAL --------------------------------

subtest 'combination ROMAN x POSTNOMINAL (all four corners)' => sub {
	my %expect = (
		'1,1' => 'Henry VIII PhD',
		'1,0' => 'Henry VIII Phd',
		'0,1' => 'Henry Viii PhD',
		'0,0' => 'Henry Viii Phd',
	);
	for my $combo ( sort keys %expect ) {
		my ( $roman, $post ) = split /,/, $combo;
		with_settings( { ROMAN => $roman, POSTNOMINAL => $post }, sub {
			is( nc('henry viii phd'), $expect{$combo}, "ROMAN=$roman POSTNOMINAL=$post" );
		} );
	}
	done_testing();
};

# ----- combinatorial: MAX_LENGTH at its edge x switches ------------------

subtest 'combination: MAX_LENGTH at max while every switch is on / off' => sub {
	my $name = 'henry viii phd';    # 14 characters
	for my $state ( 0, 1 ) {
		with_settings( {
				MAX_LENGTH  => length $name,
				ROMAN       => $state,
				POSTNOMINAL => $state,
				SPANISH     => $state,
				HEBREW      => $state,
			}, sub {
				lives_ok { nc($name) } "length == max, switches=$state: accepted";
			} );
		with_settings( {
				MAX_LENGTH  => length($name) - 1,
				ROMAN       => $state,
				POSTNOMINAL => $state,
			}, sub {
				throws_ok { nc($name) } qr/\AName is too long: 14 characters \(the maximum is 13\)/,
					"length == max+1, switches=$state: rejected";
			} );
	}
	done_testing();
};

# ----- P9: NameCase argument form, context and size ----------------------

subtest 'P9 NameCase: argument forms and array sizes' => sub {
	with_settings( {}, sub {
		# list context copies
		my @in = ( 'john smith', 'mary jones' );
		my @list = NameCase(@in);
		is_deeply( \@list, [ 'John Smith', 'Mary Jones' ], 'list of two' );
		is_deeply( \@in, [ 'john smith', 'mary jones' ], 'list form: inputs unchanged' );

		my @one = NameCase('john');
		is_deeply( \@one, ['John'], 'list of one (minimum)' );

		# scalar and scalar reference
		my $scalar = NameCase('john smith');
		is( $scalar, 'John Smith', 'scalar argument' );
		my $name = 'john smith';
		my $by_ref = NameCase( \$name );
		is( $by_ref, 'John Smith', 'scalar reference form: result returned' );
		is( $name, 'john smith', 'scalar reference form: original is copied, not changed' );

		# array reference: array sizes 0, 1, 2, many
		for my $size ( 0, 1, 2, 50 ) {
			my @names = map { 'name' . $_ } 1 .. $size;
			my @want  = map { 'Name' . $_ } 1 .. $size;
			my $ref   = [@names];
			my $ret;
			if ( $size == 0 ) {
				# an empty array ref is a valid, empty input
				lives_ok { $ret = NameCase($ref) } 'array size 0: accepted';
				is_deeply( $ret, [], 'array size 0: empty result' );
				next;
			}
			$ret = NameCase($ref);
			is_deeply( $ref, \@want, "array size $size: changed in place" );
			is( $ret, $ref, "array size $size: the same reference is returned" );
		}

		# array ref in list context is copied, never changed
		my $source = ['john smith'];
		my @copy = NameCase($source);
		is_deeply( $source, ['john smith'], 'array ref, list context: original kept' );
		is_deeply( \@copy, ['John Smith'], 'array ref, list context: result list' )
			or diag( explain \@copy );
	} );
	done_testing();
};

subtest 'P9b NameCase: invalid arguments' => sub {
	with_settings( {}, sub {
		throws_ok { my $x = NameCase() } qr/\A\Q$MSG{single_arg}\E at /,
			'invalid: no argument -> single_arg';
		throws_ok { my $x = NameCase( {} ) } qr/\A\Q$MSG{usage_namecase}\EHASH\)/,
			'invalid: hash reference';
		throws_ok { my $x = NameCase( sub { 1 } ) } qr/\A\Q$MSG{usage_namecase}\ECODE\)/,
			'invalid: code reference';
		throws_ok { my $x = NameCase( \*STDOUT ) } qr/\A\Q$MSG{usage_namecase}\EGLOB\)/,
			'invalid: glob reference';
		throws_ok { my $x = NameCase( 'a', 'b' ) }
			qr/\A\Q$MSG{single_arg}\E at /,
			'invalid: two plain arguments in scalar context -> single_arg';
		throws_ok { NameCase( 'a', 'b' ) }
			qr/\A\Q$MSG{single_arg}\E at /,
			'invalid: two plain arguments in void context -> single_arg';

		# elements that are not strings inside an otherwise valid array
		my $bad = [ 'john', {} ];
		throws_ok { NameCase($bad) } qr/\A\Q$MSG{usage_nc}\EHASH\)/,
			'invalid element: hash reference inside the array';
		is_deeply( $bad->[0], 'john', 'failed call writes nothing back' );
	} );
	done_testing();
};

subtest 'combination: array size at the minimum / maximum x MAX_LENGTH' => sub {
	my $limit = $config{limit};
	with_settings( { MAX_LENGTH => $limit }, sub {
		my $ok_name   = 'a' x $limit;
		my $long_name = 'a' x ( $limit + 1 );

		my $one = [$ok_name];
		lives_ok { NameCase($one) } 'size 1, element at max: accepted';

		my $many = [ ($ok_name) x 100 ];
		lives_ok { NameCase($many) } 'size 100, every element at max: accepted';

		# the one bad element is last: earlier elements must stay untouched
		my $mixed = [ ('abc') x 99, $long_name ];
		throws_ok { NameCase($mixed) } qr/\AName is too long: /,
			'size 100, last element at max+1: rejected';
		is( $mixed->[0], 'abc', 'rejected call leaves earlier elements unchanged' );

		my $empty = [];
		lives_ok { NameCase($empty) } 'size 0 with a limit: accepted';
	} );
	done_testing();
};

subtest 'combination: context x argument form matrix' => sub {
	with_settings( {}, sub {
		my $ref = ['john smith'];
		my @list_ctx = NameCase('john smith');
		is_deeply( \@list_ctx, ['John Smith'], 'list context, plain string' );

		my $scalar_ctx = NameCase('john smith');
		is( $scalar_ctx, 'John Smith', 'scalar context, plain string' );

		NameCase($ref);    # void context
		is_deeply( $ref, ['John Smith'], 'void context, array ref: in place' );

		my $ret = NameCase($ref);
		is( $ret, $ref, 'scalar context, array ref: same reference' );
	} );
	done_testing();
};

# ----- P10: text domains (multibyte, Zalgo, RTL) -------------------------

subtest 'P10 text domains: German, Greek, Cyrillic, CJK' => sub {
	with_settings( {}, sub {
		partition_is( $TEXT{umlaut},   $TEXT{umlaut_out}, 'German umlaut' );
		partition_is( $TEXT{sharp_s},  $TEXT{sharp_out},  'sharp s, word initial -> Ss' );
		partition_is( $TEXT{strasse},  "Stra\x{df}e",     'sharp s inside a word kept' );
		partition_is( $TEXT{strasse_up}, 'Strasse',       'STRASSE folded' );
		partition_is( $TEXT{e_acute},  $TEXT{e_acute_up}, 'accented Latin' );
		partition_is( $TEXT{greek},    $TEXT{greek_out},  'Greek' );
		partition_is( $TEXT{cyrillic}, $TEXT{cyr_out},    'Cyrillic' );
		partition_is( $TEXT{cjk},      $TEXT{cjk},        'CJK has no case: unchanged' );
		partition_is( $TEXT{hebrew},   $TEXT{hebrew},     'Hebrew has no case: unchanged' );
	} );
	done_testing();
};

subtest 'P10b text domains: emoji, Zalgo, RTL override' => sub {
	with_settings( {}, sub {
		partition_is( $TEXT{emoji},     $TEXT{emoji},     'single emoji unchanged' );
		partition_is( $TEXT{emoji_zwj}, $TEXT{emoji_zwj}, 'ZWJ family emoji kept intact' );
		partition_is( $TEXT{flag},      $TEXT{flag},      'flag (regional indicators) intact' );
		partition_is( "a$TEXT{emoji}b", "A$TEXT{emoji}B", 'emoji between letters' );

		# Zalgo: base letters are cased, every combining mark survives
		partition_is( $TEXT{zalgo}, $TEXT{zalgo_out}, 'Zalgo: marks survive, base cased' );
		my $many = 'a' . ( "\x{0301}" x 5000 );
		my ( $warnings, $got ) = quiet( sub { nc($many) } );
		is( length $got, length $many, 'Zalgo with 5000 marks: no length change' );
		is( scalar @{$warnings}, 0, 'Zalgo with 5000 marks: no warnings' );

		# RTL override: the control character is data, never dropped
		partition_is( $TEXT{rlo}, $TEXT{rlo_out}, 'RTL override kept, letter cased' );
		my $out = nc("\x{202E}\x{202D}\x{2067}abc\x{2069}");
		like( $out, qr/\A\x{202E}\x{202D}\x{2067}/, 'bidi controls all kept in order' );
		like( $out, qr/\x{2069}\z/, 'closing isolate kept' );
	} );
	done_testing();
};

subtest 'P10c text domains: length growth, dotted I, bytes, curly apostrophe' => sub {
	with_settings( {}, sub {
		# U+0130 grows when lower-cased: documented bound is 3x the input
		my $got = nc( $TEXT{dotted_i} );
		is( $got, "I\x{307}stanbul", 'dotted capital I: expands, does not crash' );

		# worst case for growth is U+0390 (documented 3x)
		my $worst = "\x{390}" x 10;
		my $grown = nc($worst);
		cmp_ok( length $grown, '<=', $config{max_growth} * length $worst,
			'U+0390 x 10: output within 3x the input' );

		# only the plain apostrophe triggers the 's rule
		partition_is( "fred's",          "Fred's",             'plain apostrophe: s stays lower case' );
		partition_is( $TEXT{curly_s},    "Fred\x{2019}S",      'curly apostrophe: documented, s is upper case' );

		# undecoded bytes are not cased (documented in ENCODING)
		my $bytes = "m\xc3\xbcller";
		my ( $warnings, $result ) = quiet( sub { nc($bytes) } );
		ok( defined $result, 'undecoded bytes: no crash, a defined result' );
		is( scalar @{$warnings}, 0, 'undecoded bytes: no warnings' );

		# lone surrogate and a non-character: tolerated without a warning
		my ( $w2, $r2 ) = quiet( sub { nc("a\x{D800}b\x{FFFF}") } );
		ok( defined $r2, 'surrogate and non-character: no crash' );
		is( scalar @{$w2}, 0, 'surrogate and non-character: no warnings' );
	} );
	done_testing();
};

subtest 'combination: multibyte text x MAX_LENGTH x NameCase' => sub {
	# The limit counts characters in every entry of an array.
	with_settings( { MAX_LENGTH => 6 }, sub {
		my $ok = [ $TEXT{umlaut} ];    # 6 characters, 7 bytes in UTF-8
		is( length $TEXT{umlaut}, 6, 'fixture: 6 characters' );
		lives_ok { NameCase($ok) } 'multibyte entry at the limit: accepted';
		is( $ok->[0], $TEXT{umlaut_out}, 'multibyte entry cased' );

		my $too = [ $TEXT{umlaut} . 'x' ];
		throws_ok { NameCase($too) }
			qr/\AName is too long: 7 characters \(the maximum is 6\)/,
			'multibyte entry at max+1: rejected with a character count';
	} );
	done_testing();
};

# ----- global state ------------------------------------------------------

subtest 'global state is not polluted by failing calls' => sub {
	with_settings( {}, sub {
		local $_ = 'untouched';
		local $@ = 'prior error';
		local $! = 0;
		eval { nc( 'a', 'b' ) };
		like( $@, qr/Usage: nc/, 'the failure was reported in $@ by eval' );
		is( $_, 'untouched', '$_ preserved after a failing call' );
	} );
	is( $Lingua::EN::NameCase::HEBREW,      1,     'HEBREW at its default' );
	is( $Lingua::EN::NameCase::SPANISH,     0,     'SPANISH at its default' );
	is( $Lingua::EN::NameCase::ROMAN,       1,     'ROMAN at its default' );
	is( $Lingua::EN::NameCase::POSTNOMINAL, 1,     'POSTNOMINAL at its default' );
	is( $Lingua::EN::NameCase::MAX_LENGTH,  undef, 'MAX_LENGTH at its default' );
	done_testing();
};

done_testing();
