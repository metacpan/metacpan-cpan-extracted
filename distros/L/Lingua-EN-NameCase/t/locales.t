#!/usr/bin/perl -w

# The module ignores the process locale, so no locale may change its result.
# (It once used "use locale", which made accented names depend on LC_ALL.)
# It does not produce operating-system error strings, and it has no
# country-based behaviour (no GeoIP), so only the POSIX side applies here:
#   * ASCII names must case identically in every locale;
#   * the module's own error messages must not depend on the locale;
#   * calling the module must not disturb errno.
# Locales that are not installed are skipped, not failed.

use strict;
use warnings;

use Errno qw(ENOENT);
use POSIX qw(setlocale LC_ALL);
use Test::Most;

use Lingua::EN::NameCase qw( NameCase nc );

# The three required families: English, German and an East Asian language.
# C is first: it is on every system and is not UTF-8, which is where wide
# characters used to cause "Wide character" warnings.
my @LOCALES = qw( C en_US.UTF-8 de_DE.UTF-8 ja_JP.UTF-8 );

my %EXPECT = (
	'KEITH'              => 'Keith',
	'MCCARTHY'           => 'McCarthy',
	"O'CALLAGHAN"        => "O'Callaghan",
	'VAN DER POST'       => 'van der Post',
	'HENRY VIII'         => 'Henry VIII',
	'JANE SMITH PHD'     => 'Jane Smith PhD',
	'MIRIAM BAT RIVKAH'  => 'Miriam bat Rivkah',
);

my $original_locale = setlocale(LC_ALL);

for my $wanted (@LOCALES) {
	subtest "locale $wanted" => sub {
		local $ENV{LC_ALL} = $wanted;
		my $got = setlocale( LC_ALL, $wanted );
		plan skip_all => "locale $wanted is not installed" unless defined $got;

		# Sanity: the OS string comes from Perl's own layer (never POSIX::strerror),
		# so it is whatever this process's locale gives for ENOENT.
		my $os_message = do { local $! = ENOENT; "$!" };
		ok( length $os_message, "ENOENT stringifies ($os_message)" );

		while ( my ( $in, $out ) = each %EXPECT ) {
			is( nc($in), $out, "nc($in)" );
		}
		is_deeply( [ NameCase( 'ANNE JONES', 'BOB MCVEY' ) ], [ 'Anne Jones', 'Bob McVey' ], 'NameCase list' );

		# Wide characters are valid input in every locale and must not warn.
		my @warnings;
		{
			local $SIG{__WARN__} = sub { push @warnings, @_ };
			is( nc("\x{c9}MILE ZOLA"), "\x{c9}mile Zola", 'accented Latin-1 name' );
			is( nc("\x{3b1}\x{3b2} SMITH PHD"), "\x{391}\x{3b2} Smith PhD", 'Greek name' );
			is( nc("john \x{1F600} smith"), "John \x{1F600} Smith", 'emoji' );
			is( nc("\x{4e2d}\x{6587}"), "\x{4e2d}\x{6587}", 'CJK unchanged' );
		}
		is_deeply( \@warnings, [], 'no warnings for wide characters' );

		# Our own messages are catalogue text, not OS text, in every locale.
		throws_ok { nc( {} ) } qr/^Usage: nc .*\(got HASH\)/, 'error message is locale independent';
		throws_ok { NameCase() } qr/^NameCase only accepts a single scalar/, 'NameCase error is locale independent';

		# The module never leaves its own errno behind, nor reads the OS one.
		{
			local $! = ENOENT;
			nc('JOHN SMITH');
			eval { nc( [] ) };
			is( $! + 0, ENOENT, 'errno untouched by success and by croak' );
			unlike( $@, qr/\Q$os_message\E/, 'error text does not contain the OS string' );
		}
	};
}

# Concurrent use: two configurations in one process do not leak into each other.
subtest 'configuration is per-scope with local' => sub {
	my $before = nc('NA LI');
	{
		local $Lingua::EN::NameCase::ROMAN = 0;
		is( nc('NA LI'), 'Na Li', 'inside local' );
	}
	is( nc('NA LI'), $before, 'restored afterwards' );
};

setlocale( LC_ALL, $original_locale ) if defined $original_locale;

done_testing();
