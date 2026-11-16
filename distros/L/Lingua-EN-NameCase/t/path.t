#!/usr/bin/perl -w

# Path-coverage tests for Lingua::EN::NameCase.
#
# <thinking>
# Control flow graph, routine by routine.  A path is one choice at every
# decision on the way from entry to exit.
#
# nc
#   D1 @_ ?            : argument given / none ($_)
#   D2 @_ > 1          : croak usage_nc "list"      (or the ref type, when the
#                        first argument is a reference)
#   D3 ref, not SCALAR : croak usage_nc "<type>"
#   D4 ref (SCALAR)    : dereference / plain value
#   D5 false value     : return it at once (undef, '', '0'), before D6
#   D6 MAX_LENGTH      : undef / defined and fits (== max) / defined and over
#   D7 ROMAN           : stage runs / is skipped
#   D8 POSTNOMINAL     : stage runs / is skipped
#   D7 x D8 gives four paths through the stage list.
#
# NameCase
#   D1 ref type not SCALAR/ARRAY                      -> croak usage_namecase
#   D2 list context and (more than one arg or ARRAY)  -> map in list context
#   D3 ARRAY (scalar/void context)                    -> in place, return ref
#   D4 SCALAR ref                                     -> nc of the value
#   D5 exactly one arg                                -> nc of the value
#   D6 otherwise (none, or several in scalar context) -> croak single_arg
#   plus: the array map runs 0, 1 and many times.
#
# _fail
#   D1 args missing (single_arg) / present
#   D2 args has "got" (cleaned) / not (too_long)
#   D3 message empty (an override of '') -> the key is used / non-empty
#   then croak.  The "die" after croak cannot be reached by any path.
#
# _safe_type   straight line; the cleaning substitution matches / does not
# _i18n        key undef / defined; args missing / given; override / default
#              / unknown key; placeholder known / unknown / undef value
# _base_case   straight line; the apostrophe rule matches / does not
# _mac_case    gate true: exception matched / not, Macisaac matched / not;
#              gate false; Macmurdo matched / not
# _particle_case  four patterns (HEBREW x SPANISH); matches / does not
# _roman_case  matches / does not
# _postnominal_case
#              short name / long name (window cut); no match; match with a
#              canonical spelling; match found only by case folding (no key)
#
# Loops: the two load-time loops over (0,1) run twice each, the table loop
# runs once per entry.  None runs zero times or at most once.
# Dead code: "die $message" after croak in _fail (marked in the module).
# </thinking>

use strict;
use warnings;

use Readonly;
use Test::Needs 'Test::Mockingbird';
use Test::Mockingbird;
use Test::Most;
use lib 't/lib';
use ReturnsOk;

BEGIN { my @known = ( \%Sub::Private::config, \$Sub::Private::BYPASS ); }

use Lingua::EN::NameCase qw( NameCase nc );

# The private routines are called from outside the package on purpose.
$Sub::Private::BYPASS = 1;

Readonly my $PKG => 'Lingua::EN::NameCase';

Readonly my %config => (
	window_pad => 40,    # characters before a post-nominal, past the window
	many       => 5,     # "many" iterations of the array map
);

Readonly my @STAGES => qw( _base_case _mac_case _particle_case _roman_case _postnominal_case );

# ----- helpers -----------------------------------------------------------

# Run a block with the package settings at their defaults, and put the old
# values back afterwards even if the block dies.
sub with_settings {
	my ( $settings, $code ) = @_;
	my @names = qw( HEBREW SPANISH ROMAN POSTNOMINAL MAX_LENGTH );
	my %saved;
	{
		no strict 'refs';
		%saved = map { $_ => ${"${PKG}::$_"} } @names;
		my %default = ( HEBREW => 1, SPANISH => 0, ROMAN => 1, POSTNOMINAL => 1, MAX_LENGTH => undef );
		${"${PKG}::$_"} = $default{$_} for @names;
		${"${PKG}::$_"} = $settings->{$_} for keys %{$settings};
	}
	my $ok    = eval { $code->(); 1 };
	my $error = $@;
	{
		no strict 'refs';
		${"${PKG}::$_"} = $saved{$_} for @names;
	}
	die $error unless $ok;
	return;
}

# Run a block while every stage of the pipeline is wrapped so that the order
# in which they ran is recorded.  Returns the list of stages that ran.
sub stages_run {
	my ($code) = @_;
	my @trace;
	my %original;
	for my $stage (@STAGES) {
		no strict 'refs';
		$original{$stage} = \&{"${PKG}::$stage"};
		my $real = $original{$stage};
		mock "${PKG}::$stage" => sub { push @trace, $stage; return $real->(@_) };
	}
	my $ok    = eval { $code->(); 1 };
	my $error = $@;
	unmock "${PKG}::$_" for @STAGES;
	die $error unless $ok;
	return \@trace;
}

# ----- nc ----------------------------------------------------------------

subtest 'nc: argument and guard paths' => sub {
	with_settings( {}, sub {
		# D1: no argument -> $_
		local $_ = 'john smith';
		is( nc(), 'John Smith', 'path: no argument, uses $_' );
		# D1: an argument is given
		is( nc('mary jones'), 'Mary Jones', 'path: argument given' );
		# D1, with $_ holding a reference: still not modified
		local $_ = \'x y';
		is( nc(), 'X Y', 'path: no argument, $_ is a scalar ref' );
		# D2: more than one argument, plain first
		throws_ok { nc( 'a', 'b' ) } qr/\AUsage: nc \[\[\\\]\$SCALAR\] \(got list\)/,
			'path: two arguments, first plain -> got list';
		# D2: more than one argument, first is a reference: type is reported
		throws_ok { nc( [], 'b' ) } qr/\(got ARRAY\)/,
			'path: two arguments, first a reference -> got <type>';
		# D3: one reference of the wrong type
		throws_ok { nc( {} ) } qr/\(got HASH\)/, 'path: HASH reference';
		# D4: scalar reference
		is( nc( \'a b' ), 'A B', 'path: scalar reference' );
		# D4: plain scalar
		is( nc('a b'), 'A B', 'path: plain scalar' );
	} );
	done_testing();
};

subtest 'nc: false-value early exit (D5) happens before the length check' => sub {
	with_settings( { MAX_LENGTH => 0 }, sub {
		is( nc(undef), undef, 'path: undef returned' );
		is( nc(q{}),   q{},   "path: '' returned" );
		is( nc('0'),   '0',   "path: '0' returned" );
		is( nc( \'0' ), '0',  "path: reference to '0' returned" );
		my $ran = stages_run( sub { nc('0') } );
		is_deeply( $ran, [], 'no stage runs on the early exit' );
	} );
	done_testing();
};

subtest 'nc: MAX_LENGTH paths (D6)' => sub {
	with_settings( { MAX_LENGTH => undef }, sub {
		is( nc( 'a' x 100 ), 'A' . ( 'a' x 99 ), 'path: no limit' );
	} );
	with_settings( { MAX_LENGTH => 3 }, sub {
		is( nc('abc'), 'Abc', 'path: limit set, length equals the limit' );
		throws_ok { nc('abcd') } qr/\AName is too long: 4 characters \(the maximum is 3\)/,
			'path: limit set, length over the limit';
		my $ran = stages_run( sub { eval { nc('abcd') } } );
		is_deeply( $ran, [], 'path: no stage runs after too_long' );
	} );
	done_testing();
};

subtest 'nc: stage list, ROMAN x POSTNOMINAL (D7 x D8)' => sub {
	my %expect = (
		'1,1' => [@STAGES],
		'1,0' => [ @STAGES[ 0 .. 3 ] ],
		'0,1' => [ @STAGES[ 0 .. 2 ], $STAGES[4] ],
		'0,0' => [ @STAGES[ 0 .. 2 ] ],
	);
	for my $combo ( sort keys %expect ) {
		my ( $roman, $post ) = split /,/, $combo;
		with_settings( { ROMAN => $roman, POSTNOMINAL => $post }, sub {
			my $ran = stages_run( sub { nc('henry viii phd') } );
			is_deeply( $ran, $expect{$combo}, "ROMAN=$roman POSTNOMINAL=$post: stages and order" );
		} );
	}
	# a stage that returns a changed value feeds the next one
	with_settings( {}, sub {
		mock "${PKG}::_base_case" => sub { return 'x' };
		my $got = eval { nc('anything') };
		unmock "${PKG}::_base_case";
		is( $got, 'X', 'stage output is the next stage input (base case replaced)' )
			or diag("got: $got");
	} );
	done_testing();
};

# ----- NameCase ----------------------------------------------------------

subtest 'NameCase: every path' => sub {
	with_settings( {}, sub {
		# D1: bad reference
		throws_ok { my @x = NameCase( {} ) } qr/\(got HASH\)/, 'D1: HASH reference, list context';
		throws_ok { my $x = NameCase( sub { 1 } ) } qr/\(got CODE\)/, 'D1: CODE reference, scalar context';

		# D2: list context, several plain arguments
		my @many = NameCase( 'a b', 'c d' );
		is_deeply( \@many, [ 'A B', 'C D' ], 'D2: list context, several scalars' );
		# D2: list context, one array ref (size many / 1 / 0)
		for my $size ( 0, 1, $config{many} ) {
			my @in  = map { "n$_" } 1 .. $size;
			my @out = NameCase( [@in] );
			is_deeply( \@out, [ map { "N$_" } 1 .. $size ], "D2: list context, array ref of $size" );
		}
		# D2: list context, array ref followed by more arguments: extras ignored
		my @first = NameCase( ['a b'], 'c d' );
		is_deeply( \@first, ['A B'], 'D2: list context, array ref then extra argument' );
		# D2: list context, a scalar ref among several
		my @mixed = NameCase( \'a b', 'c d' );
		is_deeply( \@mixed, [ 'A B', 'C D' ], 'D2: list context, scalar ref in a list' );

		# D3: scalar and void context, array ref
		my $array = [ 'a b', 'c d' ];
		my $ret = NameCase($array);
		is( $ret, $array, 'D3: scalar context returns the same ref' );
		is_deeply( $array, [ 'A B', 'C D' ], 'D3: scalar context, changed in place' );
		my $void = ['e f'];
		NameCase($void);
		is_deeply( $void, ['E F'], 'D3: void context, changed in place' );
		my $empty = [];
		is_deeply( scalar NameCase($empty), [], 'D3: empty array, nothing to do' );

		# D4: scalar ref, scalar context and list context
		my $s = 'a b';
		is( scalar NameCase( \$s ), 'A B', 'D4: scalar ref, scalar context' );
		is( $s, 'a b', 'D4: scalar ref is copied, not changed' );
		my @one = NameCase( \$s );
		is_deeply( \@one, ['A B'], 'D4: scalar ref, list context gives one name' );

		# D5: one plain argument, scalar and list context
		is( scalar NameCase('a b'), 'A B', 'D5: one plain argument, scalar context' );
		my @plain = NameCase('a b');
		is_deeply( \@plain, ['A B'], 'D5: one plain argument, list context' );
		is( scalar NameCase(undef), undef, 'D5: undef argument' );

		# D6: nothing to do it with
		throws_ok { my $x = NameCase() } qr/\ANameCase only accepts a single scalar, array or array ref at /,
			'D6: no arguments';
		throws_ok { my $x = NameCase( 'a', 'b' ) } qr/\ANameCase only accepts a single scalar/,
			'D6: several plain arguments, scalar context';
		throws_ok { NameCase( 'a', 'b' ) } qr/\ANameCase only accepts a single scalar/,
			'D6: several plain arguments, void context';
		my @none;
		throws_ok { @none = NameCase() } qr/\ANameCase only accepts a single scalar/,
			'D6: no arguments, list context';
		is( scalar @none, 0, 'D6: nothing returned on failure' );
	} );
	done_testing();
};

subtest 'NameCase: error path inside the array map leaves the array alone' => sub {
	with_settings( { MAX_LENGTH => 3 }, sub {
		my $array = [ 'abc', 'abcd' ];
		throws_ok { NameCase($array) } qr/\AName is too long: 4 characters/,
			'second element too long';
		is_deeply( $array, [ 'abc', 'abcd' ], 'no element was written' );
		throws_ok { my @x = NameCase($array) } qr/\AName is too long: /,
			'same, list context';
	} );
	done_testing();
};

# ----- _fail, _safe_type, _i18n ------------------------------------------

subtest '_fail: every path' => sub {
	with_settings( {}, sub {
		# D1 args missing; D2 no "got"
		throws_ok { Lingua::EN::NameCase::_fail('single_arg') }
			qr/\ANameCase only accepts a single scalar, array or array ref at /,
			'args missing';
		# D1 args present, D2 no "got"
		throws_ok { Lingua::EN::NameCase::_fail( 'too_long', { length => 5, max => 4 } ) }
			qr/\AName is too long: 5 characters \(the maximum is 4\)/,
			'args without got';
		# D2 "got" present: cleaned
		throws_ok { Lingua::EN::NameCase::_fail( 'usage_nc', { got => "A\nB" } ) }
			qr/\(got A\?B\)/, 'got is cleaned';
		# the caller's hash is not changed
		my %args = ( got => "A\nB" );
		eval { Lingua::EN::NameCase::_fail( 'usage_nc', \%args ) };
		is( $args{got}, "A\nB", 'caller hash untouched' );

		# D3 empty message: the key is used
		{
			local %Lingua::EN::NameCase::MESSAGES = ( single_arg => q{} );
			throws_ok { Lingua::EN::NameCase::_fail('single_arg') } qr/\Asingle_arg at /,
				'empty override: the key is the message';
		}
		# D3 undef override falls back to the default text
		{
			local %Lingua::EN::NameCase::MESSAGES = ( single_arg => undef );
			throws_ok { Lingua::EN::NameCase::_fail('single_arg') } qr/\ANameCase only accepts/,
				'undef override: default text';
		}
		# the message is an exception string, never a reference
		eval { Lingua::EN::NameCase::_fail('single_arg') };
		ok( !ref $@, 'exception is a plain string' );
	} );
	done_testing();
};

subtest '_safe_type: both paths of the cleaning substitution, and the cut' => sub {
	is( Lingua::EN::NameCase::_safe_type('HASH'), 'HASH', 'nothing to clean' );
	is( Lingua::EN::NameCase::_safe_type("Foo::Bar"), 'Foo::Bar', 'colons kept' );
	is( Lingua::EN::NameCase::_safe_type("a\nb c"), 'a?b?c', 'hostile characters replaced' );
	is( length Lingua::EN::NameCase::_safe_type( 'x' x 1000 ), 64, 'cut to 64' );
	is( Lingua::EN::NameCase::_safe_type(q{}), q{}, 'empty' );
	done_testing();
};

subtest '_i18n: every path' => sub {
	my $i = \&Lingua::EN::NameCase::_i18n;
	local %Lingua::EN::NameCase::MESSAGES;
	is( $i->(undef), 'unknown_message', 'key undef' );
	is( $i->('nonesuch'), 'nonesuch', 'unknown key, args missing' );
	is( $i->( 'usage_nc', { got => 'X' } ), 'Usage: nc [[\\]$SCALAR] (got X)', 'default, placeholder known' );
	is( $i->( 'usage_nc', {} ), 'Usage: nc [[\\]$SCALAR] (got {got})', 'placeholder unknown: kept' );
	is( $i->( 'usage_nc', { got => undef } ), 'Usage: nc [[\\]$SCALAR] (got {got})', 'value undef: kept' );
	$Lingua::EN::NameCase::MESSAGES{usage_nc} = 'bad {got}';
	is( $i->( 'usage_nc', { got => 'Y' } ), 'bad Y', 'override used' );
	$Lingua::EN::NameCase::MESSAGES{usage_nc} = [];
	like( $i->('usage_nc'), qr/\AARRAY\(0x[0-9a-f]+\)\z/, 'reference override becomes a string' );
	done_testing();
};

# ----- the pipeline stages -----------------------------------------------

subtest '_base_case: apostrophe rule matches / does not' => sub {
	is( Lingua::EN::NameCase::_base_case('JOHN SMITH'), 'John Smith', 'no apostrophe' );
	is( Lingua::EN::NameCase::_base_case("FRED'S CAR"), "Fred's Car", "'s lowered" );
	is( Lingua::EN::NameCase::_base_case("O'BRIEN"),    "O'Brien",    'O\' keeps the next capital' );
	done_testing();
};

subtest '_mac_case: every path' => sub {
	my $m = \&Lingua::EN::NameCase::_mac_case;
	# gate false (no Mc, Mac+3 letters ending a c i o z j), nothing else matches
	is( $m->('Smith Jones'), 'Smith Jones', 'gate false, no Macmurdo' );
	is( $m->('Macab'),       'Macab',       'gate false: Mac + 2 letters' );
	is( $m->('Macabc'),      'Macabc',      'gate false: ends in c' );
	# gate false, Macmurdo outside it
	is( $m->('Macmurdo'),    'MacMurdo',    'gate false, Macmurdo matches' );
	# gate true, no exception, no Macisaac
	is( $m->('Macdonald'),   'MacDonald',   'gate true, no exception' );
	is( $m->('Mcdonald'),    'McDonald',    'gate true by Mc' );
	# gate true, exception matches
	is( $m->('Machado Mcx'), 'Machado McX', 'gate true, exception matched' );
	# gate true, Macisaac matches (the gate is opened by another word)
	is( $m->('Macisaac Macdonald'), 'MacIsaac MacDonald', 'gate true, Macisaac matched' );
	# gate true and Macmurdo too
	is( $m->('Macmurdo Mcx'), 'MacMurdo McX', 'gate true, Macmurdo matched' );
	done_testing();
};

subtest '_particle_case: four patterns, match and no match' => sub {
	my $p = \&Lingua::EN::NameCase::_particle_case;
	my $text = 'John Bat David El Bar La Mesa Van Dyke';
	my %expect = (
		'1,0' => 'John bat David el Bar la Mesa van Dyke',
		'1,1' => 'John bat David El Bar La Mesa van Dyke',
		'0,0' => 'John Bat David el Bar la Mesa van Dyke',
		'0,1' => 'John Bat David El Bar La Mesa van Dyke',
	);
	for my $combo ( sort keys %expect ) {
		my ( $hebrew, $spanish ) = split /,/, $combo;
		with_settings( { HEBREW => $hebrew, SPANISH => $spanish }, sub {
			is( $p->($text), $expect{$combo}, "HEBREW=$hebrew SPANISH=$spanish" );
		} );
	}
	# switches given as undef / '' select the "off" pattern
	with_settings( { HEBREW => undef, SPANISH => q{} }, sub {
		is( $p->('John Bat David El Bar'), 'John Bat David el Bar', 'undef and empty mean off' );
	} );
	with_settings( {}, sub {
		is( $p->('John Smith'), 'John Smith', 'no particle: unchanged' );
		is( $p->(q{}),          q{},          'empty string' );
	} );
	done_testing();
};

subtest '_roman_case: match / no match' => sub {
	is( Lingua::EN::NameCase::_roman_case('Henry Viii'), 'Henry VIII', 'match' );
	is( Lingua::EN::NameCase::_roman_case('Henry Smith'), 'Henry Smith', 'no match' );
	is( Lingua::EN::NameCase::_roman_case('Henry Xc'), 'Henry Xc', 'out of range: no match' );
	is( Lingua::EN::NameCase::_roman_case('Vi Xi'), 'VI XI', 'several matches' );
	done_testing();
};

subtest '_postnominal_case: every path' => sub {
	my $p = \&Lingua::EN::NameCase::_postnominal_case;
	# short name (not longer than the window), matching
	is( $p->('Jo Phd'), 'Jo PhD', 'short name, match, canonical' );
	# short name, no match
	is( $p->('Jo Smith'), 'Jo Smith', 'short name, no match' );
	is( $p->(q{}), q{}, 'empty name' );
	# long name: only the tail is examined
	my $long = ( 'Smith ' x $config{window_pad} ) . 'Phd';
	is( $p->($long), ( 'Smith ' x $config{window_pad} ) . 'PhD', 'long name, match' );
	my $long_none = ( 'Smith ' x $config{window_pad} ) . 'Jones';
	is( $p->($long_none), $long_none, 'long name, no match' );
	# trailing newline is part of the optional pattern
	is( $p->("Jo Phd\n"), "Jo PhD\n", 'match before a final newline' );
	# match only through case folding: no key, so the text is left alone
	my $fold = "Bob M\x{17F}";
	my $out;
	my @warnings;
	{
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		$out = $p->($fold);
	}
	is( $out, $fold, 'fold-only match: left unchanged' );
	is( scalar @warnings, 0, 'fold-only match: no warning' );
	done_testing();
};

done_testing();
