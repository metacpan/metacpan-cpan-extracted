#!/usr/bin/perl -w

# Black-box tests of the public API of Lingua::EN::NameCase, written from
# the POD alone (nc, NameCase, the four switches and %MESSAGES).
# The module calls no database, network or other external service, so
# there is nothing to mock; the failure paths are reached with bad input.
# A ledger of every documented message and return state is built first,
# each test removes what it proves, and the script fails if any is left.

use strict;
use warnings;

use Errno qw(ENOENT);
use Test::Most;
use lib 't/lib';
use ReturnsOk;
use Readonly;

use Lingua::EN::NameCase qw( NameCase nc );


Readonly my $SENTINEL      => 'SENTINEL';
Readonly my $ALARM_SECONDS => 100;
Readonly my $ERRNO_VALUE   => ENOENT;

# ---------------------------------------------------------------- ledger
# Every message key and return state that the POD documents.
my %ledger = map { $_ => 1 } (
	# messages
	'message:usage_nc',
	'message:usage_namecase',
	'message:single_arg',
	'message:too_long',
	'config:MAX_LENGTH',
	# nc return states
	'nc:string',
	'nc:false-undef',
	'nc:false-empty',
	'nc:false-zero',
	'nc:scalar-ref',
	'nc:default-to-$_',
	# NameCase return states
	'NameCase:list-of-scalars',
	'NameCase:list-from-array-ref',
	'NameCase:in-place-returns-array-ref',
	'NameCase:scalar-ref-copy',
	'NameCase:scalar-copy',
	'NameCase:extra-args-ignored',
	'NameCase:empty-array-ref',
	# configuration
	'config:HEBREW',
	'config:SPANISH',
	'config:ROMAN',
	'config:POSTNOMINAL',
	'config:MESSAGES',
);

# Mark a documented state as exercised.
sub covered {
	my @keys = @_;
	for my $key (@keys) {
		fail("ledger has no entry '$key'") unless exists $ledger{$key};
		delete $ledger{$key};
	}
	return;
}

sub dbg {
	diag(@_) if $ENV{TEST_VERBOSE};
	return;
}

# ---------------------------------------------------------------- nc
# Purpose: nc turns one string into a correctly cased name.  The table is
# the "EXAMPLE FIXES" list of the POD plus the SYNOPSIS examples.
subtest 'nc: documented examples' => sub {
	my %documented = (
		'KEITH'                 => 'Keith',
		'LEIGH-WILLIAMS'        => 'Leigh-Williams',
		'MCCARTHY'              => 'McCarthy',
		q{O'CALLAGHAN}          => q{O'Callaghan},
		'ST. JOHN'              => 'St. John',
		'VON STREIT'            => 'von Streit',
		'VAN DYKE'              => 'van Dyke',
		'AP LLWYD DAFYDD'       => 'ap Llwyd Dafydd',
		'henry viii'            => 'Henry VIII',
		'louis xiv'             => 'Louis XIV',
		'MR. JON WHITACRE III'  => 'Mr. Jon Whitacre III',
		'JANE SMITH PHD'        => 'Jane Smith PhD',
		'Nigel'                 => 'Nigel',
		'MACHADO'               => 'Machado',
		'DOUGAL MACDONALD'      => 'Dougal MacDonald',
	);
	for my $in ( sort keys %documented ) {
		my $got = nc($in);
		is( $got, $documented{$in}, "nc($in)" );
		returns_ok( $got, { type => 'string' }, '... returns a string' );
	}
	covered('nc:string');
};

# Purpose: undef, '' and '0' are returned as they are, with no warning.
subtest 'nc: undefined, empty and zero input come back unchanged' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	is( nc(undef), undef, 'undef' );
	covered('nc:false-undef');
	is( nc(''), '', 'empty string' );
	covered('nc:false-empty');
	is( nc('0'), '0', 'zero' );
	covered('nc:false-zero');

	is_deeply( \@warnings, [], 'no warnings' );
};

# Purpose: a scalar reference is accepted, and its target is not changed.
subtest 'nc: scalar reference' => sub {
	my $name = 'JOHN SMITH';
	is( nc( \$name ), 'John Smith', 'value from a reference' );
	is( $name, 'JOHN SMITH', 'the target is not changed' );
	covered('nc:scalar-ref');
};

# Purpose: with no argument nc uses $_, like lc and uc.
subtest 'nc: no argument uses $_' => sub {
	local $_ = 'MARY JONES';
	is( nc(), 'Mary Jones', 'nc() uses $_' );
	is( $_, 'MARY JONES', '$_ is not changed' );
	covered('nc:default-to-$_');
};

# Purpose: the POD says nc takes at most one argument, and only a string
# or scalar reference.  Each breach must raise usage_nc, exactly worded,
# naming the offending type.
subtest 'nc: usage errors (message usage_nc)' => sub {
	my %bad = (
		'hash ref'   => [ [ {} ],             'HASH' ],
		'array ref'  => [ [ [] ],             'ARRAY' ],
		'code ref'   => [ [ sub { 1 } ],      'CODE' ],
		'ref to ref' => [ [ \\'x' ],          'REF' ],
		'object'     => [ [ bless( {}, 'My::Class' ) ], 'My::Class' ],
		'two args'   => [ [ 'a', 'b' ],       'list' ],
		'three args' => [ [ 'a', 'b', 'c' ],  'list' ],
	);
	for my $label ( sort keys %bad ) {
		my ( $args, $type ) = @{ $bad{$label} };
		throws_ok { nc( @{$args} ) }
			qr/^Usage: nc \[\[\\\]\$SCALAR\] \(got \Q$type\E\) at \Q$0\E line \d+\.?$/,
			"$label: exact message";
	}
	covered('message:usage_nc');
};

# ---------------------------------------------------------------- NameCase
# Purpose: several scalars in list context give a list of copies.
subtest 'NameCase: list of scalars' => sub {
	my @source = ( 'ANNE JONES', 'BOB MCVEY' );
	my @got    = NameCase(@source);
	is_deeply( \@got, [ 'Anne Jones', 'Bob McVey' ], 'copies, in order' );
	is_deeply( \@source, [ 'ANNE JONES', 'BOB MCVEY' ], 'source not modified' );
	returns_ok( \@got, { type => 'arrayref', min => 2 }, 'a list of two' );

	my @one = NameCase('JOHN SMITH');
	is_deeply( \@one, ['John Smith'], 'one scalar in list context: a list of one' );
	covered('NameCase:list-of-scalars');
};

# Purpose: an array reference in list context gives copies; the array is untouched.
subtest 'NameCase: array reference in list context' => sub {
	my $source = [ 'ANNE JONES', 'BOB MCVEY' ];
	my @got    = NameCase($source);
	is_deeply( \@got, [ 'Anne Jones', 'Bob McVey' ], 'copies' );
	is_deeply( $source, [ 'ANNE JONES', 'BOB MCVEY' ], 'array not modified' );
	covered('NameCase:list-from-array-ref');

	# "any further arguments are ignored"
	my @extra = NameCase( $source, 'IGNORED NAME' );
	is_deeply( \@extra, [ 'Anne Jones', 'Bob McVey' ], 'extra arguments ignored' );
	covered('NameCase:extra-args-ignored');

	my @none = NameCase( [] );
	is_deeply( \@none, [], 'empty array ref gives an empty list' );
	my $empty = [];
	NameCase($empty);
	is_deeply( $empty, [], 'empty array stays empty in place' );
	covered('NameCase:empty-array-ref');
};

# Purpose: an array reference in scalar or void context is changed in
# place and the same reference is returned.
subtest 'NameCase: array reference in place' => sub {
	my $names = [ 'ANNE JONES', 'BOB MCVEY' ];
	my $ret   = NameCase($names);
	is_deeply( $names, [ 'Anne Jones', 'Bob McVey' ], 'array changed' );
	is( $ret, $names, 'the same array reference is returned' );
	returns_ok( $ret, { type => 'arrayref' }, 'returns an array reference' );

	my @array = ( 'ANNE JONES', 'BOB MCVEY' );
	NameCase( \@array );
	is_deeply( \@array, [ 'Anne Jones', 'Bob McVey' ], 'void context also in place' );
	covered('NameCase:in-place-returns-array-ref');
};

# Purpose: a scalar reference gives a copy, and the target stays the same
# (the "WRONG: null operation" warning of the SYNOPSIS).
subtest 'NameCase: scalar and scalar reference' => sub {
	my $name = 'JOHN SMITH';
	is( scalar NameCase( \$name ), 'John Smith', 'scalar ref: copy returned' );
	is( $name, 'JOHN SMITH', 'scalar ref: target unchanged' );
	covered('NameCase:scalar-ref-copy');

	is( scalar NameCase($name), 'John Smith', 'scalar: copy returned' );
	is( $name, 'JOHN SMITH', 'scalar: source unchanged' );
	returns_ok( scalar NameCase($name), { type => 'string' }, 'returns a string' );
	is( scalar NameCase(undef), undef, 'undef comes back unchanged' );
	is( scalar NameCase(''), '', 'empty string comes back unchanged' );
	covered('NameCase:scalar-copy');
};

# Purpose: every documented NameCase error, with exact wording.
subtest 'NameCase: usage errors' => sub {
	for my $bad ( { type => 'HASH', value => {} }, { type => 'CODE', value => sub { 1 } },
		{ type => 'REF', value => \\'x' }, { type => 'My::Obj', value => bless( [], 'My::Obj' ) } ) {
		throws_ok { NameCase( $bad->{value} ) }
			qr/^Usage: \$SCALAR\|\@ARRAY = NameCase \[\\\]\$SCALAR\|\@ARRAY \(got \Q$bad->{type}\E\) at \Q$0\E line \d+\.?$/,
			"usage_namecase for $bad->{type}";
	}
	covered('message:usage_namecase');

	# No arguments, or several scalars wanted as one scalar.
	my $single = qr/^NameCase only accepts a single scalar, array or array ref at \Q$0\E line \d+\.?$/;
	throws_ok { NameCase() } $single, 'no arguments, void context';
	throws_ok { my @r = NameCase() } $single, 'no arguments, list context';
	throws_ok { my $r = NameCase( 'a', 'b' ) } $single, 'two scalars, scalar context';
	covered('message:single_arg');
};

# Purpose: an invalid element reaches the caller as an nc usage error and
# leaves an in-place array unchanged (SIDE EFFECTS in the POD).
subtest 'NameCase: invalid element' => sub {
	my @data = ( 'ANNE JONES', {}, 'BOB MCVEY' );
	throws_ok { NameCase( \@data ) } qr/^Usage: nc \[\[\\\]\$SCALAR\] \(got HASH\) at /, 'error names the bad type';
	is_deeply( [ map { ref $_ || $_ } @data ], [ 'ANNE JONES', 'HASH', 'BOB MCVEY' ], 'array left unchanged' );
	throws_ok { my @r = NameCase( 'OK', [] ) } qr/^Usage: nc /, 'bad element in a list';
};

# ---------------------------------------------------------------- size limit
# Purpose: $MAX_LENGTH is optional; when set, longer names are refused.
subtest 'configuration: MAX_LENGTH (message too_long)' => sub {
	is( nc( 'a' x 20 ), 'A' . ( 'a' x 19 ), 'default: no limit' );
	local $Lingua::EN::NameCase::MAX_LENGTH = 5;
	is( nc('abcde'), 'Abcde', 'at the limit' );
	throws_ok { nc('abcdef') } qr/^Name is too long: 6 characters \(the maximum is 5\) at \Q$0\E line \d+\.?$/, 'over the limit: exact message';
	covered( 'message:too_long', 'config:MAX_LENGTH' );
};

# ---------------------------------------------------------------- configuration
# Purpose: each switch changes the documented result, in both directions,
# and takes effect at once (they are read on every call).
subtest 'configuration: HEBREW' => sub {
	is( nc('Aharon BEN Amram Ha-Kohein'), 'Aharon ben Amram Ha-Kohein', 'default 1: ben lowercase' );
	is( nc('MIRIAM BAT RIVKAH'), 'Miriam bat Rivkah', 'default 1: bat lowercase' );
	is( nc('BEN MCGRATH'), 'Ben McGrath', 'a first-word Ben is a forename' );
	local $Lingua::EN::NameCase::HEBREW = 0;
	is( nc('Aharon BEN Amram Ha-Kohein'), 'Aharon Ben Amram Ha-Kohein', '0: Ben stays capital' );
	covered('config:HEBREW');
};

subtest 'configuration: SPANISH' => sub {
	is( nc('EL PASO'), 'el Paso', 'default 0: El lowercase' );
	is( nc('LA LUNA'), 'la Luna', 'default 0: La lowercase' );
	local $Lingua::EN::NameCase::SPANISH = 1;
	is( nc('EL PASO'), 'El Paso', '1: El kept' );
	is( nc('LA LUNA'), 'La Luna', '1: La kept' );
	covered('config:SPANISH');
};

subtest 'configuration: ROMAN' => sub {
	is( nc('NA LI'), 'Na LI', 'default 1: numeral' );
	local $Lingua::EN::NameCase::ROMAN = 0;
	is( nc('NA LI'), 'Na Li', '0: left alone' );
	is( nc('HENRY VIII'), 'Henry Viii', '0: all numerals left alone' );
	covered('config:ROMAN');
};

subtest 'configuration: POSTNOMINAL' => sub {
	is( nc('JANE PHD'), 'Jane PhD', 'default 1: PhD' );
	local $Lingua::EN::NameCase::POSTNOMINAL = 0;
	is( nc('JANE PHD'), 'Jane Phd', '0: Phd' );
	covered('config:POSTNOMINAL');
};

# Purpose: %MESSAGES replaces a message by key; {name} is filled in;
# other keys keep their default.
subtest 'configuration: MESSAGES' => sub {
	local %Lingua::EN::NameCase::MESSAGES = ( usage_nc => 'Bad input: {got}' );
	throws_ok { nc( [] ) } qr/^Bad input: ARRAY at /, 'override with a placeholder';
	throws_ok { NameCase() } qr/^NameCase only accepts a single scalar/, 'other keys keep the default';
	covered('config:MESSAGES');
};

# ---------------------------------------------------------------- global state
# Purpose: the POD promises nc does not change $_, $@, $! or alarm.  Check
# the success path and, for $_ and alarm, the error path too.
subtest 'global state is preserved' => sub {
	local $_ = $SENTINEL;
	local $@ = $SENTINEL;
	local $! = $ERRNO_VALUE;
	# Windows has no real alarm() timer to inspect.
	my $has_alarm = $^O ne 'MSWin32';
	alarm $ALARM_SECONDS if $has_alarm;

	nc('JOHN SMITH');
	my @pair = NameCase( 'A B', 'C D' );
	my $names = ['E F'];
	NameCase($names);
	my $text = 'G H';
	nc( \$text );

	is( $_, $SENTINEL, '$_ after success' );
	is( $@, $SENTINEL, '$@ after success' );
	is( $! + 0, $ERRNO_VALUE, '$! after success' );

	# Errors are raised by the caller's own eval, so only $_, $! and alarm are checked here.
	{
		local $@;
		eval { nc( {} ) };
		eval { NameCase() };
	}
	is( $_, $SENTINEL, '$_ after errors' );
	is( $! + 0, $ERRNO_VALUE, '$! after errors' );

	if ($has_alarm) {
		my $remaining = alarm 0;
		ok( $remaining > 0 && $remaining <= $ALARM_SECONDS, "alarm still running ($remaining s left)" );
		dbg("alarm remaining: $remaining");
	}
};

# ---------------------------------------------------------------- ledger
# Every documented state must have been reached above.
if (%ledger) {
	fail( 'untested POD conditions remain: ' . join( ', ', sort keys %ledger ) );
} else {
	pass('every documented message and return state was exercised');
}

done_testing();
