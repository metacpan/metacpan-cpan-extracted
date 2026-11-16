#!/usr/bin/perl -w

# White-box and behaviour tests for the error-message handler, the private
# routines and the behaviours changed or fixed in the refactor.

use strict;
use warnings;

use Test::Most;

# Sub::Private is optional.  Declare its variables so Perl does not warn that they
# are "used only once" when the module is not installed.
# Naming each variable twice is what makes Perl treat it as intentional.
BEGIN { my @known = ( \%Sub::Private::config, \$Sub::Private::BYPASS ); }

use Lingua::EN::NameCase qw( NameCase nc );

subtest 'default messages carry the offending type' => sub {
	throws_ok { nc( {} ) } qr/^Usage: nc .*\(got HASH\)/, 'nc: hash ref';
	throws_ok { nc( 'a', 'b' ) } qr/\(got list\)/, 'nc: too many args';
	throws_ok { NameCase( sub { 1 } ) } qr/^Usage: .*NameCase.*\(got CODE\)/, 'NameCase: code ref';
	throws_ok { NameCase() } qr/^NameCase only accepts a single scalar/, 'NameCase: no args';
	throws_ok { my $x = NameCase( 'a', 'b' ) } qr/only accepts a single/, 'NameCase: several args in scalar context';
};

subtest 'errors are reported at the caller, not inside the module' => sub {
	eval { nc( {} ) };
	like( $@, qr/at \Q$0\E line \d+/, 'croak location is this file' );
};

subtest 'MESSAGES overrides, with placeholders' => sub {
	local %Lingua::EN::NameCase::MESSAGES = ( usage_nc => 'Falsche Eingabe: {got} / {unknown}' );
	throws_ok { nc( [] ) } qr/^Falsche Eingabe: ARRAY \/ \{unknown\}/, 'translated; unknown placeholder kept';
	throws_ok { NameCase() } qr/only accepts/, 'other keys keep the default';
};

subtest 'private routines (white-box, called from inside the package)' => sub {
	package Lingua::EN::NameCase;    ## no critic
	use Test::Most;

	is( _i18n('no_such_key'), 'no_such_key', 'unknown key falls back to the key' );
	is( _i18n( 'usage_nc', { got => 'X' } ), 'Usage: nc [[\\]$SCALAR] (got X)', 'sprintf-free interpolation' );
	is( _i18n('usage_nc'), 'Usage: nc [[\\]$SCALAR] (got {got})', 'missing args leave the placeholder' );
	is( _base_case("FRED'S O'NEIL"), "Fred's O'Neil", '_base_case lowercases only a trailing apostrophe-s' );
	is( _mac_case('Mcdonald'), 'McDonald', '_mac_case' );
	is( _particle_case('Van Der Post'), 'van der Post', '_particle_case' );
	is( _roman_case('Henry Viii'), 'Henry VIII', '_roman_case' );
	is( _postnominal_case('Jane Phd'), 'Jane PhD', '_postnominal_case' );
	throws_ok { _fail( 'single_arg' ) } qr/only accepts/, '_fail croaks';
};

subtest 'private routines cannot be called from other packages' => sub {
	plan skip_all => 'Sub::Private is not installed (it is optional)' unless $INC{'Sub/Private.pm'};
	# prove sets HARNESS_ACTIVE, which Sub::Private treats as a bypass.
	local $Sub::Private::config{harness_bypass} = 0;
	throws_ok { Lingua::EN::NameCase::_base_case('x') } qr/is a private subroutine of Lingua::EN::NameCase and cannot be called from main/, '_base_case is private';
	throws_ok { Lingua::EN::NameCase::_fail('single_arg') } qr/is a private subroutine of Lingua::EN::NameCase and cannot be called from main/, '_fail is private';
};

subtest 'nc with no argument uses $_ and never modifies it' => sub {
	for my $ref ( \'JOHN SMITH' ) {
		local $_ = $ref;
		is( nc(), 'John Smith', 'uses $_, dereferencing a scalar ref' );
		is( ref $_, 'SCALAR', '$_ is untouched' );
	}
	local $_ = 'MARY JONES';
	is( nc(), 'Mary Jones', 'uses $_' );
	is( $_, 'MARY JONES', '$_ not modified' );
};

subtest 'false values are returned unchanged' => sub {
	is( nc(undef), undef, 'undef' );
	is( nc(''), '', 'empty string' );
	is( nc('0'), '0', 'zero' );
	is( nc( \'' ), '', 'ref to empty' );
};

subtest 'NameCase in place returns the array ref' => sub {
	my @names = ( 'ANNE JONES', 'BOB MCVEY' );
	my $r = NameCase( \@names );
	is_deeply( \@names, [ 'Anne Jones', 'Bob McVey' ], 'modified' );
	is( $r, \@names, 'returns the same ref' );
	is_deeply( [ NameCase( 'A', 'B' ) ], [ 'A', 'B' ], 'list of scalars' );
	is_deeply( [ NameCase( ['x y'] ) ], ['X Y'], 'list context with array ref returns copies' );
};

subtest 'post-nominals are matched literally (regression: unescaped dot)' => sub {
	is( nc('JOHN MCHX'), 'John McHx', 'MCHX is not turned into "MCh."' );
	is( nc('JANE MCH.'), 'Jane MCh.', 'MCh. still works' );
	is( nc('SAM FCSP.'), 'Sam FCSP.', 'FCSP. still works' );
	is( nc('SAM FCSPX'), 'Sam Fcspx', 'FCSPX does not match FCSP.' );
	is( nc('ALICE BVM&S'), 'Alice BVM&S', 'ampersand entry' );
	is( nc("BOB PHD\n"), "Bob PhD\n", 'trailing newline is preserved' );
	is( nc('PHD STUDENT'), 'Phd Student', 'only a trailing post-nominal is changed' );
};

subtest 'particles and Mac rules, flags toggled at run time' => sub {
	is( nc('AL FAHD'), 'al Fahd', 'al' );
	is( nc('AL'), 'Al', 'lone Al is a forename' );
	is( nc('VAN'), 'Van', 'lone Van is a forename' );
	is( nc('MACISAAC MCDONALD'), 'MacIsaac McDonald', 'MacIsaac restored' );
	is( nc('MACHADO MCCARTHY'), 'Machado McCarthy', 'Machado exception' );
	is( nc('DELLA ROBBIA'), 'della Robbia', 'della' );
	is( nc('JOHN BEN SMITH'), 'John ben Smith', 'ben is lowercased when HEBREW is on' );
	local $Lingua::EN::NameCase::HEBREW = 0;
	is( nc('JOHN BEN SMITH'), 'John Ben Smith', 'ben is left alone when HEBREW is off' );
	is( nc('MIRIAM BAT RIVKAH'), 'Miriam Bat Rivkah', 'HEBREW off' );
};

done_testing();
