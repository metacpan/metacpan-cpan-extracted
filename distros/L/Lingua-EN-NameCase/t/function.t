#!/usr/bin/perl -w

# White-box tests for every routine in Lingua::EN::NameCase, public and
# private.  Strategy: each routine is tested alone, with its neighbours
# mocked, so a failure points at one routine.  Most subtests are hostile:
# they feed bad input, force helpers to die half way through, and push
# large data through, to prove the module cannot be corrupted or bypassed.

use strict;
use warnings;

use Test::Most;

# Sub::Private is optional.  Declare its variables so Perl does not warn that they
# are "used only once" when the module is not installed.
# Naming each variable twice is what makes Perl treat it as intentional.
BEGIN { my @known = ( \%Sub::Private::config, \$Sub::Private::BYPASS ); }
use Test::Needs 'Test::Mockingbird';    # needs a recent Perl; skip the file without it
use Test::Mockingbird;
use lib 't/lib';
use ReturnsOk;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(weaken);
use Time::HiRes qw(time);

use Lingua::EN::NameCase qw( NameCase nc );

# Private routines are guarded by Sub::Private.  The tests call them from
# outside the package on purpose (white-box), so switch the guard off here.
# The 'enforcement' subtest switches it back on for a moment.
$Sub::Private::BYPASS = 1;

Readonly my $PKG            => 'Lingua::EN::NameCase';
Readonly my $HUGE_WORD_LEN  => 200_000;
Readonly my $MANY_ITEMS     => 50_000;
Readonly my $TIME_LIMIT_SEC => 20;     # generous: guards against runaway regexes only
Readonly my $SENTINEL       => 'SENTINEL VALUE';

# Prefixes that must stay lowercase after "Mac" (kept in step with the module).
Readonly my @MAC_EXCEPTIONS => qw(
	Evicius Hado Har Hin Hlin Ias Iulis Kie Kle Klin Quarie Omber In
	Kintosh Ken Hen Hiel Iol Kell Klem Krell Lin Key Kley Hell Hon
);

# Print internal state only when the user asked for verbose output.
sub dbg {
	diag(@_) if $ENV{TEST_VERBOSE};
	return;
}

# Run a block and return every warning it produced, so "no warnings" can be asserted.
sub warnings_from(&) {
	my $code = shift;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	eval { $code->() };
	return [ @warnings, ( $@ ? "DIED: $@" : () ) ];
}

# ---------------------------------------------------------------- _i18n
subtest '_i18n: templates, placeholders, hostile templates' => sub {
	my $got = Lingua::EN::NameCase::_i18n( 'usage_nc', { got => 'HASH' } );
	is( $got, 'Usage: nc [[\\]$SCALAR] (got HASH)', 'default template filled in' );
	returns_ok( $got, { type => 'string' }, 'returns a string' );

	is( Lingua::EN::NameCase::_i18n('no_such_key'), 'no_such_key', 'unknown key: the key itself' );
	is( Lingua::EN::NameCase::_i18n(undef), 'unknown_message', 'undef key: fixed text, no warning' );
	is( Lingua::EN::NameCase::_i18n( 'usage_nc', {} ), 'Usage: nc [[\\]$SCALAR] (got {got})', 'missing arg: placeholder kept' );
	is( Lingua::EN::NameCase::_i18n( 'usage_nc', { got => undef } ), 'Usage: nc [[\\]$SCALAR] (got {got})', 'undef arg: placeholder kept' );

	# A value that looks like a placeholder must not be expanded again.
	is( Lingua::EN::NameCase::_i18n( 'usage_nc', { got => '{got}' } ), 'Usage: nc [[\\]$SCALAR] (got {got})', 'no recursive expansion' );

	# Hostile override text: format codes, code-injection and regex characters
	# must come out as plain text.
	my $evil = '%s %n %1$s $1 @{[ die "pwned" ]} ${\ die "pwned" } \\E (?{ die }) {got}';
	local %Lingua::EN::NameCase::MESSAGES = ( usage_nc => $evil );
	my $text = eval { Lingua::EN::NameCase::_i18n( 'usage_nc', { got => 'X' } ) };
	is( $@, '', 'hostile template did not die' );
	is( $text, '%s %n %1$s $1 @{[ die "pwned" ]} ${\ die "pwned" } \\E (?{ die }) X', 'hostile template is inert' );

	# An arg value full of regex/replacement metacharacters is inserted verbatim.
	local $Lingua::EN::NameCase::MESSAGES{usage_nc} = 'got {got}';
	is( Lingua::EN::NameCase::_i18n( 'usage_nc', { got => '$1\\1&$&' } ), 'got $1\\1&$&', 'metacharacters in args are literal' );

	# Placeholders: names must be \w+, so these are left alone.
	local $Lingua::EN::NameCase::MESSAGES{usage_nc} = '{} { got } {g-ot}';
	is( Lingua::EN::NameCase::_i18n( 'usage_nc', { got => 'X' } ), '{} { got } {g-ot}', 'malformed placeholders untouched' );

	local $_ = $SENTINEL;
	Lingua::EN::NameCase::_i18n( 'usage_nc', { got => 'X' } );
	is( $_, $SENTINEL, '$_ is not clobbered' );
};

# ---------------------------------------------------------------- _fail
subtest '_fail: always croaks with the localised text' => sub {
	# Mock the two collaborators so only _fail's own wiring is tested.
	my @i18n_calls;
	mock "${PKG}::_i18n" => sub { push @i18n_calls, [@_]; return 'MOCK TEXT' };
	my @croaked;
	mock "${PKG}::croak" => sub { push @croaked, [@_]; die "stop\n" };

	throws_ok { Lingua::EN::NameCase::_fail( 'k', { a => 1 } ) } qr/^stop$/, 'propagates the croak';
	is_deeply( \@i18n_calls, [ [ 'k', { a => 1 } ] ], 'key and args passed to _i18n untouched' );
	is_deeply( \@croaked, [ ['MOCK TEXT'] ], 'croak got exactly the i18n text' );
	restore_all();

	# Real croak: exact text, and the location is the caller, not the module.
	throws_ok { Lingua::EN::NameCase::_fail('single_arg') }
		qr/^NameCase only accepts a single scalar, array or array ref at \Q$0\E line \d+\.?$/,
		'exact message, reported at the caller';
	my $w = warnings_from { eval { Lingua::EN::NameCase::_fail() } };
	is_deeply( $w, [], 'a missing key warns about nothing' );
	throws_ok { Lingua::EN::NameCase::_fail() } qr/^unknown_message at /, 'no key at all still dies, never returns';
	lives_ok { eval { Lingua::EN::NameCase::_fail('x') }; 1 } 'caught croak leaves no state behind';
};

# ---------------------------------------------------------------- _base_case
subtest '_base_case: capitalisation rules' => sub {
	my %table = (
		'JOHN SMITH'      => 'John Smith',
		"o'callaghan"     => "O'Callaghan",
		"FRED'S"          => "Fred's",
		'leigh-williams'  => 'Leigh-Williams',
		'st. john'        => 'St. John',
		'a'               => 'A',
		"john\nsmith"     => "John\nSmith",
		"  padded  "      => '  Padded  ',
		'123 abc'         => '123 Abc',
	);
	while ( my ( $in, $want ) = each %table ) {
		my $arg = $in;
		is( Lingua::EN::NameCase::_base_case($arg), $want, "_base_case($in)" );
		is( $arg, $in, '... argument not modified' );
	}
	returns_ok( Lingua::EN::NameCase::_base_case('X'), { type => 'string' }, 'returns a string' );

	local $_ = $SENTINEL;
	Lingua::EN::NameCase::_base_case('abc');
	is( $_, $SENTINEL, '$_ is not clobbered' );
};

subtest '_base_case: hostile text' => sub {
	my @hostile = ( '', "\0", "\0abc\0", "\t\r\n", '((( [[[ \\Q \\E', '$1 @{[1]} ${x}', "\x{1F600}", "\x{e9}mile", "\x{3b1}\x{3b2}\x{3b3}" );
	for my $text (@hostile) {
		my $w = warnings_from { Lingua::EN::NameCase::_base_case($text) };
		is_deeply( $w, [], sprintf( 'no warning or death for %vd', $text ) );
	}
	is( Lingua::EN::NameCase::_base_case("john \x{1F600} smith"), "John \x{1F600} Smith", 'emoji untouched, words fixed' );
	is( Lingua::EN::NameCase::_base_case("\x{c9}MILE"), "\x{c9}mile", 'accented word start is capitalised, the rest lowered' );
};

# ---------------------------------------------------------------- _mac_case
subtest '_mac_case: Mc/Mac names and exceptions' => sub {
	is( Lingua::EN::NameCase::_mac_case('Mcdonald'),     'McDonald',     'Mc' );
	is( Lingua::EN::NameCase::_mac_case('Macdonald'),    'MacDonald',    'Mac' );
	is( Lingua::EN::NameCase::_mac_case('Macmurdo'),     'MacMurdo',     'Macmurdo special case' );
	is( Lingua::EN::NameCase::_mac_case('Mcdonald Macdonald'), 'McDonald MacDonald', 'several in one string' );

	# Every exception prefix must stay lowercase.
	for my $suffix (@MAC_EXCEPTIONS) {
		my $name = 'Mac' . lc($suffix) . 'son';
		is( Lingua::EN::NameCase::_mac_case($name), $name, "exception Mac$suffix stays lowercase" );
	}
	is( Lingua::EN::NameCase::_mac_case('Mcmachado'), 'McMachado', 'exception only applies right after a word-start Mac' );
};

subtest '_mac_case: names it must leave alone' => sub {
	# Short names (Mack, Mace), and endings typical of Polish/Italian names.
	for my $name (qw( Mack Macy Mace Macdonalda Macchiato Macewicz Macko Macci Maciej Mac Mc Macaroni Machine )) {
		my $w = warnings_from { Lingua::EN::NameCase::_mac_case($name) };
		is_deeply( $w, [], "no warning for $name" );
	}
	is( Lingua::EN::NameCase::_mac_case('Mack'), 'Mack', 'Mack is not split' );
	is( Lingua::EN::NameCase::_mac_case('Macdonalda'), 'Macdonalda', 'trailing a: Polish/Italian, untouched' );
	is( Lingua::EN::NameCase::_mac_case('Smith'), 'Smith', 'non Mac name untouched' );
	is( Lingua::EN::NameCase::_mac_case(''), '', 'empty string' );
	is( Lingua::EN::NameCase::_mac_case('Mc'), 'Mc', 'bare Mc' );

	my $arg = 'Mcdonald';
	Lingua::EN::NameCase::_mac_case($arg);
	is( $arg, 'Mcdonald', 'argument not modified' );
	local $_ = $SENTINEL;
	Lingua::EN::NameCase::_mac_case('Mcdonald');
	is( $_, $SENTINEL, '$_ is not clobbered' );
};

# ---------------------------------------------------------------- _particle_case
subtest '_particle_case: lowercase particles' => sub {
	my %table = (
		'Van Der Post'     => 'van der Post',
		'Von Trapp'        => 'von Trapp',
		'Da Vinci'         => 'da Vinci',
		'Di Caprio'        => 'di Caprio',
		'Du Pont'          => 'du Pont',
		'De Legate'        => 'de Legate',
		'Del Crond'        => 'del Crond',
		'Della Robbia'     => 'della Robbia',
		'Delle Fave'       => 'delle Fave',
		'Le Figaro'        => 'le Figaro',
		'Lo Presti'        => 'lo Presti',
		'Ap Llwyd Dafydd'  => 'ap Llwyd Dafydd',
		'Al Fahd'          => 'al Fahd',
		'John Van Dyke'    => 'John van Dyke',
	);
	while ( my ( $in, $want ) = each %table ) {
		is( Lingua::EN::NameCase::_particle_case($in), $want, "_particle_case($in)" );
	}
};

subtest '_particle_case: forenames and look-alikes are NOT lowercased' => sub {
	is( Lingua::EN::NameCase::_particle_case('Al'),       'Al',       'lone Al is a forename' );
	is( Lingua::EN::NameCase::_particle_case('John Al'),  'John Al',  'trailing Al is a forename' );
	is( Lingua::EN::NameCase::_particle_case('Van'),      'Van',      'lone Van' );
	is( Lingua::EN::NameCase::_particle_case('John Van'), 'John Van', 'trailing Van' );
	is( Lingua::EN::NameCase::_particle_case('Deli'),     'Deli',     'Del only as a whole word' );
	is( Lingua::EN::NameCase::_particle_case('Dad'),      'Dad',      'Da only as a whole word' );
	is( Lingua::EN::NameCase::_particle_case('Alan'),     'Alan',     'Al inside a word' );
	is( Lingua::EN::NameCase::_particle_case("D'arcy"),   "D'arcy",   'apostrophe is not a particle' );
	is( Lingua::EN::NameCase::_particle_case(''),         '',         'empty string' );
};

subtest '_particle_case: HEBREW and SPANISH switches, including odd values' => sub {
	for my $off ( undef, 0, '', '0' ) {
		local $Lingua::EN::NameCase::HEBREW = $off;
		is( Lingua::EN::NameCase::_particle_case('Miriam Bat Rivkah'), 'Miriam Bat Rivkah', 'HEBREW off: ' . ( $off // 'undef' ) );
	}
	for my $on ( 1, 'yes' ) {
		local $Lingua::EN::NameCase::HEBREW = $on;
		is( Lingua::EN::NameCase::_particle_case('Miriam Bat Rivkah'), 'Miriam bat Rivkah', "HEBREW on: $on" );
		is( Lingua::EN::NameCase::_particle_case('Ben Jones'), 'Ben Jones', 'first-word Ben is a forename' );
	}
	{
		local $Lingua::EN::NameCase::SPANISH = 0;
		is( Lingua::EN::NameCase::_particle_case('El Paso La Luna'), 'el Paso la Luna', 'Greek/French El, La' );
	}
	for my $on ( 1, 'si' ) {
		local $Lingua::EN::NameCase::SPANISH = $on;
		is( Lingua::EN::NameCase::_particle_case('El Paso La Luna'), 'El Paso La Luna', "SPANISH on: $on" );
	}
	my $w = warnings_from {
		local $Lingua::EN::NameCase::HEBREW  = undef;
		local $Lingua::EN::NameCase::SPANISH = undef;
		Lingua::EN::NameCase::_particle_case('Van Der Post');
	};
	is_deeply( $w, [], 'undef switches cause no warnings' );
};

# ---------------------------------------------------------------- _roman_case
subtest '_roman_case: numerals' => sub {
	is( Lingua::EN::NameCase::_roman_case('Henry Viii'),   'Henry VIII',   'VIII' );
	is( Lingua::EN::NameCase::_roman_case('Louis Xiv'),    'Louis XIV',    'XIV' );
	is( Lingua::EN::NameCase::_roman_case('Fred Xlix'),    'Fred XLIX',    'XLIX' );
	is( Lingua::EN::NameCase::_roman_case('Na Li'),        'Na LI',        'Li is a numeral' );
	is( Lingua::EN::NameCase::_roman_case('A Iii B Ii'),   'A III B II',   'several numerals' );
};

subtest '_roman_case: words that merely contain numeral letters' => sub {
	for my $name ( 'Civic', 'Mix', 'Livi', 'Vivian', 'Dixie', 'Xavier', 'Lixi', 'Iiiii', '' ) {
		my $w = warnings_from { Lingua::EN::NameCase::_roman_case($name) };
		is_deeply( $w, [], "no warning for '$name'" );
	}
	is( Lingua::EN::NameCase::_roman_case('Civic'),  'Civic',  'whole word only: Civic' );
	is( Lingua::EN::NameCase::_roman_case('Vivian'), 'Vivian', 'whole word only: Vivian' );
	is( Lingua::EN::NameCase::_roman_case('Iiiii'),  'Iiiii',  'too many I: not a numeral' );
	is( Lingua::EN::NameCase::_roman_case("Louis Xiv\n"), "Louis XIV\n", 'newline preserved' );
};

# ---------------------------------------------------------------- _postnominal_case
subtest '_postnominal_case: trailing qualifications' => sub {
	my %table = (
		'Jane Smith Phd'  => 'Jane Smith PhD',
		'Jane Smith Mba'  => 'Jane Smith MBA',
		'Jane Smith Md'   => 'Jane Smith MD',
		'Jane Smith Msc'  => 'Jane Smith MSc',
		'Jane Smith Obe'  => 'Jane Smith OBE',
		'Jane Smith Bvm&s'=> 'Jane Smith BVM&S',
		'Jane Smith Mch.' => 'Jane Smith MCh.',
		'Jane Smith Fcsp.'=> 'Jane Smith FCSP.',
		'Jane Smith Dbenv'=> 'Jane Smith DBEnv',
		'Phd'             => 'PhD',
	);
	while ( my ( $in, $want ) = each %table ) {
		is( Lingua::EN::NameCase::_postnominal_case($in), $want, "_postnominal_case($in)" );
	}
	is( Lingua::EN::NameCase::_postnominal_case("Jane Phd\n"), "Jane PhD\n", 'trailing newline kept' );
};

subtest '_postnominal_case: things that must NOT match' => sub {
	# The dot in MCh. is literal.  It once matched any character.
	is( Lingua::EN::NameCase::_postnominal_case('John Mchx'),  'John Mchx',  'Mchx is not MCh.' );
	is( Lingua::EN::NameCase::_postnominal_case('John Fcspx'), 'John Fcspx', 'Fcspx is not FCSP.' );
	is( Lingua::EN::NameCase::_postnominal_case('Phd Student'), 'Phd Student', 'only a trailing word' );
	is( Lingua::EN::NameCase::_postnominal_case('Jane Phdx'),  'Jane Phdx',  'suffix of a longer word' );
	is( Lingua::EN::NameCase::_postnominal_case('Jane Xphd'),  'Jane Xphd',  'prefix of a longer word' );
	is( Lingua::EN::NameCase::_postnominal_case('Jane Phd '),  'Jane Phd ',  'trailing space: not at the end' );
	is( Lingua::EN::NameCase::_postnominal_case(''),           '',           'empty string' );
	is( Lingua::EN::NameCase::_postnominal_case('Smith'),      'Smith',      'no post-nominal' );
	is( Lingua::EN::NameCase::_postnominal_case('Jane (Phd'),  'Jane (PhD',  'punctuation before is a word break' );
	for my $meta ( '(((', '[[', '.*', '\\E', 'a|b', '^', '$', '$1', '@{[1]}' ) {
		my $w = warnings_from { Lingua::EN::NameCase::_postnominal_case("Jane $meta") };
		is_deeply( $w, [], "regex metacharacters are inert: $meta" );
		is( Lingua::EN::NameCase::_postnominal_case("Jane $meta"), "Jane $meta", "unchanged: $meta" );
	}
	local $_ = $SENTINEL;
	Lingua::EN::NameCase::_postnominal_case('Jane Phd');
	is( $_, $SENTINEL, '$_ is not clobbered' );
};

# The post-nominal matcher works on the reversed name and needs every list
# entry to start with a letter or digit (a word boundary in front of it).
# Read the list from the source so a new entry cannot break that unnoticed.
subtest '_postnominal_case: every entry in the module list works' => sub {
	open( my $fh, '<', $INC{'Lingua/EN/NameCase.pm'} ) or die "read module: $!";
	my $source = do { local $/; <$fh> };
	close $fh;
	my ($list) = $source =~ /Readonly my \@POST_NOMINAL_INITIALS => qw\((.*?)\);/s;
	ok( defined $list, 'found the list in the source' ) or return;

	my @entries = split ' ', $list;
	my %canonical;
	$canonical{ lc $_ } = $_ for @entries;    # later entries win, as in the module
	cmp_ok( scalar @entries, '>', 100, 'a long list' );

	my @bad_start = grep { !/^[A-Za-z0-9]/ } @entries;
	is_deeply( \@bad_start, [], 'every entry starts with a letter or digit' );

	my @wrong;
	for my $key ( sort keys %canonical ) {
		for my $before ( 'Jane ', 'Jane-', '(', '' ) {
			my $got = Lingua::EN::NameCase::_postnominal_case( $before . $key );
			push @wrong, "$before$key -> $got" unless $got eq $before . $canonical{$key};
		}
		my $glued = Lingua::EN::NameCase::_postnominal_case( 'xx' . $key );
		push @wrong, "xx$key changed to $glued" if $glued ne 'xx' . $key && !exists $canonical{ lc "xx$key" };
	}
	is_deeply( \@wrong, [], 'each entry is found at the end, after a space, hyphen, bracket or nothing' ) or diag explain [ @wrong[ 0 .. ( $#wrong < 9 ? $#wrong : 9 ) ] ];
};

# The post-nominal matcher only looks at the end of the name.  Check that the
# cut-off cannot cause a false match or a miss at any length near the window.
subtest '_postnominal_case: long names and the look-at-the-end window' => sub {
	for my $prefix_length ( 0, 1, 10, 11, 12, 13, 14, 15, 16, 20, 100, $HUGE_WORD_LEN ) {
		my $prefix = 'x' x $prefix_length;
		is( Lingua::EN::NameCase::_postnominal_case( $prefix . ' Phd' ), $prefix . ' PhD', "found after $prefix_length characters" );
		is( Lingua::EN::NameCase::_postnominal_case( $prefix . 'Phd' ), $prefix . 'Phd', "glued to a word of $prefix_length letters: not an entry" ) if $prefix_length;
		is( Lingua::EN::NameCase::_postnominal_case( $prefix . ' Phd' . "\n" ), $prefix . " PhD\n", "with a final newline, $prefix_length" );
		is( Lingua::EN::NameCase::_postnominal_case( $prefix . ' Phd ' ), $prefix . ' Phd ', "trailing space: not at the end, $prefix_length" );
	}
};

# The Mac gate checks the last LETTER of the word.  It once accepted a space or
# punctuation in that place, so Polish and Italian names were not excluded when
# another word followed them.
subtest '_mac_case: names ending in a c i o z j are left alone (regression)' => sub {
	for my $name ( 'Macdonalda Smith', 'Macchiato Rossi', 'Machado Smith', 'Macewicz Kowal', 'Macko Da', 'Macci Gcie', "Macdonalda's Pub" ) {
		is( Lingua::EN::NameCase::_mac_case($name), $name, "unchanged: $name" );
	}
	is( Lingua::EN::NameCase::_mac_case('Macdonald Smith'), 'MacDonald Smith', 'a Mac name followed by a word still works' );
	is( Lingua::EN::NameCase::_mac_case("Macdonald's Pub"), "MacDonald's Pub", 'with an apostrophe' );
	is( Lingua::EN::NameCase::_mac_case('Mcdonald Smith'), 'McDonald Smith', 'Mc names are not gated' );
	is( Lingua::EN::NameCase::_mac_case('Mackenzie'), 'Mackenzie', 'exception list still applies' );
};

# ---------------------------------------------------------------- nc (pipeline, mocked helpers)
subtest 'nc: calls helpers in order, honouring the switches' => sub {
	my @order;
	for my $step (qw( _base_case _mac_case _particle_case _roman_case _postnominal_case )) {
		mock "${PKG}::$step" => sub { push @order, $step; return "$_[0]+$step" };
	}

	local ( $Lingua::EN::NameCase::ROMAN, $Lingua::EN::NameCase::POSTNOMINAL ) = ( 1, 1 );
	is( Lingua::EN::NameCase::nc('x'), 'x+_base_case+_mac_case+_particle_case+_roman_case+_postnominal_case', 'each result feeds the next' );
	is_deeply( \@order, [qw( _base_case _mac_case _particle_case _roman_case _postnominal_case )], 'order' );

	for my $off ( undef, 0, '', '0' ) {
		@order = ();
		local ( $Lingua::EN::NameCase::ROMAN, $Lingua::EN::NameCase::POSTNOMINAL ) = ( $off, $off );
		is( Lingua::EN::NameCase::nc('x'), 'x+_base_case+_mac_case+_particle_case', 'both off: ' . ( $off // 'undef' ) );
		is_deeply( \@order, [qw( _base_case _mac_case _particle_case )], '... optional steps skipped' );
	}

	@order = ();
	{
		local ( $Lingua::EN::NameCase::ROMAN, $Lingua::EN::NameCase::POSTNOMINAL ) = ( 1, 0 );
		Lingua::EN::NameCase::nc('x');
		is_deeply( \@order, [qw( _base_case _mac_case _particle_case _roman_case )], 'ROMAN only' );
	}
	restore_all();
};

subtest 'nc: false input short-circuits (no helper is called)' => sub {
	my $calls = 0;
	mock "${PKG}::$_" => sub { $calls++; return 'CALLED' } for qw( _base_case _mac_case _particle_case _roman_case _postnominal_case );

	is( Lingua::EN::NameCase::nc(undef), undef, 'undef' );
	is( Lingua::EN::NameCase::nc(''),    '',    'empty' );
	is( Lingua::EN::NameCase::nc('0'),   '0',   'zero' );
	is( Lingua::EN::NameCase::nc(0),     0,     'numeric zero' );
	is( Lingua::EN::NameCase::nc( \'' ), '',    'ref to empty' );
	is( $calls, 0, 'no helper ran' );

	# "00" and "0.0" are true in Perl and must be processed.
	Lingua::EN::NameCase::nc('00');
	cmp_ok( $calls, '>', 0, '"00" is a real string and is processed' );
	restore_all();
};

subtest 'nc: error guards pass the right key and type' => sub {
	my @failed;
	mock "${PKG}::_fail" => sub { push @failed, [@_]; die "FAIL:$_[0]\n" };

	my %bad = (
		'hash ref'      => [ {} => 'HASH' ],
		'array ref'     => [ [] => 'ARRAY' ],
		'code ref'      => [ sub { 1 } => 'CODE' ],
		'ref to ref'    => [ \\'x' => 'REF' ],
		'regexp'        => [ qr/x/ => 'Regexp' ],
		'glob ref'      => [ \*STDOUT => 'GLOB' ],
		'blessed'       => [ ( bless {}, 'Evil::Class' ) => 'Evil::Class' ],
		'blessed scalar'=> [ ( bless \( my $s = 'x' ), 'Evil::Scalar' ) => 'Evil::Scalar' ],
	);
	for my $label ( sort keys %bad ) {
		@failed = ();
		my ( $arg, $type ) = @{ $bad{$label} };
		throws_ok { Lingua::EN::NameCase::nc($arg) } qr/^FAIL:usage_nc$/, "$label rejected";
		is_deeply( \@failed, [ [ 'usage_nc', { got => $type } ] ], "$label: reported as $type" );
	}

	@failed = ();
	throws_ok { Lingua::EN::NameCase::nc( 'a', 'b' ) } qr/^FAIL:usage_nc$/, 'two args rejected';
	is_deeply( \@failed, [ [ 'usage_nc', { got => 'list' } ] ], 'two args: reported as list' );
	@failed = ();
	throws_ok { Lingua::EN::NameCase::nc( undef, undef ) } qr/^FAIL:usage_nc$/, 'two undefs rejected';
	throws_ok { Lingua::EN::NameCase::nc( \'ok', {} ) } qr/^FAIL:usage_nc$/, 'good then bad rejected';
	restore_all();
};

subtest 'nc: real error text' => sub {
	throws_ok { Lingua::EN::NameCase::nc( {} ) } qr/^Usage: nc \[\[\\\]\$SCALAR\] \(got HASH\) at \Q$0\E line \d+/, 'hash';
	throws_ok { Lingua::EN::NameCase::nc( 1, 2 ) } qr/^Usage: nc \[\[\\\]\$SCALAR\] \(got list\) at /, 'two args';
	throws_ok { Lingua::EN::NameCase::nc( bless [], 'Obj' ) } qr/\(got Obj\)/, 'object class named';
};

subtest 'nc: a helper dying half way leaves no damage' => sub {
	for my $step (qw( _base_case _mac_case _particle_case _roman_case _postnominal_case )) {
		mock "${PKG}::$step" => sub { die "boom in $step\n" };

		local ( $Lingua::EN::NameCase::ROMAN, $Lingua::EN::NameCase::POSTNOMINAL ) = ( 1, 1 );
		local $_ = $SENTINEL;
		my $arg = 'JOHN SMITH';
		throws_ok { Lingua::EN::NameCase::nc($arg) } qr/^boom in \Q$step\E$/, "$step failure propagates";
		is( $_,   $SENTINEL,    "$step: \$_ untouched" );
		is( $arg, 'JOHN SMITH', "$step: argument untouched" );
		restore_all();
		is( Lingua::EN::NameCase::nc('JOHN SMITH'), 'John Smith', "$step: next call works normally" );
	}
};

# ---------------------------------------------------------------- nc (real)
subtest 'nc: input forms and $_ handling' => sub {
	my $name = 'JOHN SMITH';
	is( Lingua::EN::NameCase::nc($name),   'John Smith', 'plain scalar' );
	is( Lingua::EN::NameCase::nc( \$name ), 'John Smith', 'scalar ref' );
	is( $name, 'JOHN SMITH', 'caller scalar never modified' );
	is( Lingua::EN::NameCase::nc('MARY JONES'), 'Mary Jones', 'read-only literal' );
	is( Lingua::EN::NameCase::nc( \ 'MARY JONES' ), 'Mary Jones', 'ref to read-only literal' );

	{
		local $_ = 'ANNE LEE';
		is( Lingua::EN::NameCase::nc(), 'Anne Lee', 'no argument uses $_' );
		is( $_, 'ANNE LEE', '$_ unchanged' );
	}
	{
		my $held = \'ANNE LEE';
		local $_ = $held;
		is( Lingua::EN::NameCase::nc(), 'Anne Lee', '$_ holding a scalar ref' );
		is( $_, $held, '$_ is still the same reference (was once overwritten)' );
	}
	{
		local $_ = undef;
		my $w = warnings_from { is( Lingua::EN::NameCase::nc(), undef, 'undef $_ gives undef' ) };
		is_deeply( $w, [], 'no warning for undef' );
	}
	{
		# An argument of undef is one argument, not "no argument".
		local $_ = 'IGNORED NAME';
		is( Lingua::EN::NameCase::nc(undef), undef, 'explicit undef does not fall back to $_' );
	}
	returns_ok( Lingua::EN::NameCase::nc('A B'), { type => 'string' }, 'returns a string' );
};

subtest 'nc: idempotent on every sample (the output is already correct)' => sub {
	my @names = ( 'KEITH', 'MCCARTHY', "O'CALLAGHAN", 'VAN DER POST', 'HENRY VIII', 'JANE SMITH PHD',
		'MIRIAM BAT RIVKAH', 'DR SARAH BEETLE', 'MACHADO', 'ST. JOHN', 'LEIGH-WILLIAMS' );
	for my $name (@names) {
		my $once = Lingua::EN::NameCase::nc($name);
		is( Lingua::EN::NameCase::nc($once), $once, "nc(nc($name))" );
	}
};

# ---------------------------------------------------------------- NameCase (mocked nc)
subtest 'NameCase: dispatch, with nc mocked' => sub {
	my @seen;
	mock "${PKG}::nc" => sub { push @seen, $_[0]; return defined $_[0] ? "<$_[0]>" : '<undef>' };

	# List context, several scalars.
	my @list = NameCase( 'a', 'b', 'c' );
	is_deeply( \@list, [ '<a>', '<b>', '<c>' ], 'list of scalars' );
	is_deeply( \@seen, [ 'a', 'b', 'c' ], 'nc called once per element, in order' );

	# List context, array ref: copies, source untouched.
	@seen = ();
	my $src = [ 'x', 'y' ];
	my @copy = NameCase($src);
	is_deeply( \@copy, [ '<x>', '<y>' ], 'array ref in list context' );
	is_deeply( $src, [ 'x', 'y' ], 'source untouched' );

	# List context, array ref plus extra args: extras are ignored.
	@copy = NameCase( $src, 'extra' );
	is_deeply( \@copy, [ '<x>', '<y>' ], 'extra args after an array ref ignored' );

	# Scalar context, array ref: in place, returns the ref.
	my $inplace = [ 'p', 'q' ];
	my $ret = NameCase($inplace);
	is_deeply( $inplace, [ '<p>', '<q>' ], 'in place' );
	is( $ret, $inplace, 'returns the same array ref' );

	# Void context.
	my $void = [ 'v' ];
	NameCase($void);
	is_deeply( $void, ['<v>'], 'void context is also in place' );

	# Scalar ref: copy returned, original untouched.
	my $text = 'orig';
	is( scalar NameCase( \$text ), '<orig>', 'scalar ref value' );
	is( $text, 'orig', 'scalar ref target untouched' );
	my ($one) = NameCase( \$text );
	is( $one, '<orig>', 'scalar ref in list context' );

	# Plain scalar.
	is( scalar NameCase('solo'), '<solo>', 'one scalar' );
	my @one = NameCase('solo');
	is_deeply( \@one, ['<solo>'], 'one scalar in list context gives a one-element list' );
	is( scalar NameCase(undef), '<undef>', 'undef passes through to nc' );

	# Empty array: nothing to do, no calls.
	@seen = ();
	my @none = NameCase( [] );
	is_deeply( [ \@none, \@seen ], [ [], [] ], 'empty array ref' );
	restore_all();
};

subtest 'NameCase: error guards, with _fail mocked' => sub {
	my @failed;
	mock "${PKG}::_fail" => sub { push @failed, [@_]; die "FAIL:$_[0]\n" };

	for my $bad ( {}, sub { 1 }, \\'x', qr/x/, \*STDOUT, ( bless [], 'Obj' ) ) {
		@failed = ();
		throws_ok { NameCase($bad) } qr/^FAIL:usage_namecase$/, 'bad ref type: ' . ref $bad;
		is( $failed[0][1]{got}, ref $bad, '... the type is reported' );
	}
	@failed = ();
	throws_ok { my @r = NameCase( {}, 'ok' ) } qr/^FAIL:usage_namecase$/, 'bad ref first, even with more args';
	throws_ok { NameCase() } qr/^FAIL:single_arg$/, 'no arguments (scalar/void)';
	throws_ok { my @r = NameCase() } qr/^FAIL:single_arg$/, 'no arguments (list)';
	throws_ok { my $r = NameCase( 'a', 'b' ) } qr/^FAIL:single_arg$/, 'two scalars wanted as one scalar';
	throws_ok { NameCase( 'a', 'b' ) } qr/^FAIL:single_arg$/, 'two scalars in void context';
	is_deeply( $failed[-1], ['single_arg'], 'single_arg carries no args' );
	restore_all();
};

subtest 'NameCase: real error text' => sub {
	throws_ok { NameCase( {} ) } qr/^Usage: \$SCALAR\|\@ARRAY = NameCase \[\\\]\$SCALAR\|\@ARRAY \(got HASH\) at \Q$0\E line \d+/, 'usage';
	throws_ok { NameCase() } qr/^NameCase only accepts a single scalar, array or array ref at \Q$0\E line \d+/, 'single arg';
	# Errors from nc inside a list are reported for nc, at the caller.
	throws_ok { my @r = NameCase( 'ok', {} ) } qr/^Usage: nc /, 'bad element in a list';
};

subtest 'NameCase: in place is all-or-nothing' => sub {
	# A bad element in the middle must not leave the array half converted.
	my @mixed = ( 'ANNE JONES', {}, 'BOB SMITH' );
	my @before = @mixed;
	throws_ok { NameCase( \@mixed ) } qr/^Usage: nc /, 'bad element croaks';
	is_deeply( \@mixed, \@before, 'array unchanged after the failure' );

	my @nested = ( 'A B', ['C D'] );
	throws_ok { NameCase( \@nested ) } qr/^Usage: nc /, 'nested array rejected';
	is( $nested[0], 'A B', 'earlier element not converted' );

	# Failure forced mid-flight on the third element.
	my $calls = 0;
	mock "${PKG}::nc" => sub { die "stop at 3\n" if ++$calls == 3; return uc $_[0] };
	my @data = qw( a b c d );
	throws_ok { NameCase( \@data ) } qr/^stop at 3$/, 'mid-flight failure propagates';
	is_deeply( \@data, [qw( a b c d )], 'array unchanged' );
	restore_all();
	is_deeply( [ NameCase( \@data ) ], [ 'A', 'B', 'C', 'D' ], 'works afterwards' );
};

subtest 'NameCase: in place, odd contents' => sub {
	my @data = ( 'ANNE JONES', undef, '', '0', \'BOB MCVEY' );
	my $w = warnings_from { NameCase( \@data ) };
	is_deeply( $w, [], 'undef and empty elements cause no warnings' );
	is_deeply( \@data, [ 'Anne Jones', undef, '', '0', 'Bob McVey' ], 'each element handled, count unchanged' );

	# The same scalar twice must be converted both times, not corrupted.
	my $shared = 'JOHN SMITH';
	my @twice = ( $shared, $shared );
	NameCase( \@twice );
	is_deeply( \@twice, [ 'John Smith', 'John Smith' ], 'repeated value' );
	is( $shared, 'JOHN SMITH', 'original scalar not aliased into the change' );

	# Refs to the array itself must not recurse.
	my @selfish = ( 'A B' );
	push @selfish, \$selfish[0];
	lives_ok { NameCase( \@selfish ) } 'element referring to another element';
};

subtest 'NameCase: $_ is preserved' => sub {
	local $_ = $SENTINEL;
	my @r = NameCase( 'A B', 'C D' );
	is( $_, $SENTINEL, 'list form' );
	my $aref = ['a b'];
	NameCase($aref);
	is( $_, $SENTINEL, 'in place form' );
	NameCase('a b');
	is( $_, $SENTINEL, 'scalar form' );
	eval { NameCase( {} ) };
	is( $_, $SENTINEL, 'after an error' );

	# Inside a caller's loop, aliased $_ must not be written to.
	my @outer = ( 'x', 'y' );
	for (@outer) { my @r2 = NameCase( 'a b', 'c d' ); }
	is_deeply( \@outer, [ 'x', 'y' ], 'caller loop variable untouched' );
};

subtest 'NameCase: return values match their specification' => sub {
	my @list = NameCase( 'ANNE JONES', 'BOB MCVEY' );
	returns_ok( \@list, { type => 'arrayref', min => 2 }, 'list result' );
	returns_ok( scalar NameCase('ANNE JONES'), { type => 'string' }, 'scalar result' );
	returns_ok( scalar NameCase( ['ANNE JONES'] ), { type => 'arrayref' }, 'in place result' );
	returns_ok( [ NameCase( ['ANNE JONES'] ) ], { type => 'arrayref', min => 1 }, 'list context from array ref' );
};

# ---------------------------------------------------------------- hostile load
subtest 'resource exhaustion: huge inputs finish, correctly and quickly' => sub {
	my $start = time;

	my $word = 'ab' x $HUGE_WORD_LEN;
	my $got  = Lingua::EN::NameCase::nc( uc $word );
	is( length $got, length $word, 'huge single word: same length' );
	is( substr( $got, 0, 4 ), 'Abab', 'huge single word: fixed' );

	my $mac = 'mac' . ( 'b' x $HUGE_WORD_LEN ) . 'n';
	is( length Lingua::EN::NameCase::nc($mac), length $mac, 'huge Mac word (regex back-tracking)' );

	my $many = join ' ', ('SMITH') x $MANY_ITEMS;
	is( Lingua::EN::NameCase::nc($many), join( ' ', ('Smith') x $MANY_ITEMS ), 'many words' );

	my $hyphens = join '-', ('a') x $MANY_ITEMS;
	is( length Lingua::EN::NameCase::nc($hyphens), length $hyphens, 'many word boundaries (post-nominal scan)' );

	my $roman = 'i' x $HUGE_WORD_LEN;
	is( Lingua::EN::NameCase::nc($roman), 'I' . ( 'i' x ( $HUGE_WORD_LEN - 1 ) ), 'long run of numeral letters is not a numeral' );

	my @big = ('JOHN SMITH') x $MANY_ITEMS;
	NameCase( \@big );
	is( scalar @big, $MANY_ITEMS, 'huge array in place: count unchanged' );
	is( $big[-1], 'John Smith', 'huge array in place: last element' );
	my @copy = NameCase( ('A B') x $MANY_ITEMS );
	is( scalar @copy, $MANY_ITEMS, 'huge list' );

	my $elapsed = time - $start;
	dbg( sprintf 'hostile load took %.2fs', $elapsed );
	cmp_ok( $elapsed, '<', $TIME_LIMIT_SEC, 'no runaway regex' );
};

subtest 'hostile content: nothing executes, nothing warns' => sub {
	my @hostile = (
		"\0", "A\0B", "\x01\x02\x7f", "\r\n\r\n", "\t", ' ', '-', "'", "''''", '---',
		'((( [[[ {{{ \\Q \\E \\', '$1 $& @{[ die ]} ${\ die} %s %n', '`id`', '; rm -rf /',
		"\x{1F600}\x{1F600}", "\x{202E}rtl", "\x{e9}mile \x{c9}MILE", "\x{3b1}\x{3b2} \x{391}\x{392}",
		"\x{4e2d}\x{6587}", "\x{fffd}", 'a' . ( ' ' x 1000 ) . 'b',
	);
	for my $text (@hostile) {
		my $w = warnings_from { Lingua::EN::NameCase::nc($text) };
		is_deeply( $w, [], sprintf( 'nc: clean for %vd', substr( $text, 0, 12 ) ) );
	}
	is( Lingua::EN::NameCase::nc('$1 @{[ die ]}'), '$1 @{[ Die ]}', 'code-like text is cased as text, never run' );
	is( Lingua::EN::NameCase::nc("\x{4e2d}\x{6587}"), "\x{4e2d}\x{6587}", 'scripts without case unchanged' );
	is( Lingua::EN::NameCase::nc("john \x{1F600} smith"), "John \x{1F600} Smith", 'emoji kept' );
	is( Lingua::EN::NameCase::nc("\x{3b1}\x{3b2}\x{3b3} SMITH"), "\x{391}\x{3b2}\x{3b3} Smith", 'Greek' );
};

subtest 'switches: odd values never break a call' => sub {
	for my $value ( undef, '', 0, '0', 1, 'yes', -1, '0E0', [] ) {
		my $w = warnings_from {
			local $Lingua::EN::NameCase::HEBREW      = $value;
			local $Lingua::EN::NameCase::SPANISH     = $value;
			local $Lingua::EN::NameCase::ROMAN       = $value;
			local $Lingua::EN::NameCase::POSTNOMINAL = $value;
			my $r = Lingua::EN::NameCase::nc('JANE VAN DER POST PHD');
			die "bad result" unless defined $r;
		};
		is_deeply( $w, [], 'no warning or death for ' . ( defined $value ? "'$value'" : 'undef' ) );
	}
};

subtest 'switches: concurrent configurations do not leak' => sub {
	my @results;
	for my $roman ( 1, 0, 1 ) {
		local $Lingua::EN::NameCase::ROMAN = $roman;
		push @results, Lingua::EN::NameCase::nc('NA LI');
	}
	is_deeply( \@results, [ 'Na LI', 'Na Li', 'Na LI' ], 'each scope sees its own value' );
	is( $Lingua::EN::NameCase::ROMAN, 1, 'default restored' );
};

# ---------------------------------------------------------------- encapsulation
subtest 'enforcement: private routines refuse outside callers' => sub {
	plan skip_all => 'Sub::Private is not installed (it is optional)' unless $INC{'Sub/Private.pm'};
	# Switch the test bypass off (prove also sets HARNESS_ACTIVE, a second bypass).
	local $Sub::Private::BYPASS = 0;
	local $Sub::Private::config{harness_bypass} = 0;

	for my $private (qw( _i18n _fail _base_case _mac_case _particle_case _roman_case _postnominal_case )) {
		throws_ok { no strict 'refs'; &{"${PKG}::$private"}('x') }
			qr/^\Q$private\E\(\) is a private subroutine of \Q$PKG\E and cannot be called from main at /,
			"$private is private";
	}
	is( Lingua::EN::NameCase::nc('ok name'), 'Ok Name', 'public API unaffected' );
	is( Lingua::EN::NameCase::NameCase('ok name'), 'Ok Name', 'public NameCase unaffected' );
};

subtest 'messages: user overrides are used, and bad ones are harmless' => sub {
	local %Lingua::EN::NameCase::MESSAGES = (
		usage_nc   => 'Eingabefehler: {got}',
		single_arg => '%s %d {unknown}',
	);
	throws_ok { Lingua::EN::NameCase::nc( [] ) } qr/^Eingabefehler: ARRAY at /, 'translated usage_nc';
	throws_ok { NameCase() } qr/^%s %d \{unknown\} at /, 'format characters are plain text';
	throws_ok { NameCase( {} ) } qr/^Usage: \$SCALAR/, 'keys not overridden keep the default';

	local $Lingua::EN::NameCase::MESSAGES{usage_nc} = undef;
	throws_ok { Lingua::EN::NameCase::nc( [] ) } qr/^Usage: nc /, 'undef override falls back to the default';
};

# ---------------------------------------------------------------- memory
subtest 'memory: no cycles, nothing retained' => sub {
	my @list = NameCase( 'A B', 'C D' );
	memory_cycle_ok( \@list, 'list result has no cycles' );

	my $array = [ 'A B', 'C D' ];
	NameCase($array);
	memory_cycle_ok( $array, 'array changed in place has no cycles' );

	local %Lingua::EN::NameCase::MESSAGES = ( usage_nc => 'x {got}' );
	eval { Lingua::EN::NameCase::nc( [] ) };
	memory_cycle_ok( \%Lingua::EN::NameCase::MESSAGES, 'message table has no cycles' );
	memory_cycle_ok( \$@, 'exception object has no cycles' );

	# The module must not keep a reference to caller data after returning.
	my $victim = [ 'JOHN SMITH', 'MARY JONES' ];
	my $weak   = $victim;
	weaken($weak);
	NameCase($victim);
	my @copy = NameCase($victim);
	undef $victim;
	ok( !defined $weak, 'array ref is freed after the calls' );

	# The hash passed to _i18n must not be kept either.
	my $args = { got => 'X' };
	my $weak_args = $args;
	weaken($weak_args);
	Lingua::EN::NameCase::_i18n( 'usage_nc', $args );
	undef $args;
	ok( !defined $weak_args, 'args hash is freed after _i18n' );

	# A failing call must not leak the offending argument.
	my $bad      = {};
	my $weak_bad = $bad;
	weaken($weak_bad);
	eval { Lingua::EN::NameCase::nc($bad) };
	undef $bad;
	undef $@;
	ok( !defined $weak_bad, 'rejected argument is freed' );
};

done_testing();
