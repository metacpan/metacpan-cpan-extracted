#!/usr/bin/env perl

# A process started under the C locale on a system without a locale for the
# target language must still translate after l_lang(). gettext ignores
# LANGUAGE under the C and POSIX messages locale (libintl-perl >= 1.36, like
# GNU gettext), so l_lang has to leave LC_MESSAGES on something else.

use strict;
use warnings;
use Test::More;

use File::Temp qw( tempdir );
use FindBin qw( $Bin );
use POSIX ();

plan skip_all => 'no LC_MESSAGES on this platform'
  unless defined eval { POSIX::LC_MESSAGES() };

# An empty LOCPATH hides every installed glibc locale, like a minimal
# container; other C libraries ignore it.
my $no_locales = tempdir( CLEANUP => 1 );
local %ENV = %ENV;
delete @ENV{qw( LANG LANGUAGE LC_MESSAGES )};
$ENV{LC_ALL}  = 'C';
$ENV{LOCPATH} = $no_locales;

my @inc = map { "-I$_" } grep { !ref } @INC;

sub run_perl {
	my ( $code, @args ) = @_;
	open my $fh, '-|', $^X, @inc, '-e', $code, @args
	  or die "cannot run $^X: $!";
	local $/;
	my $out = <$fh>;
	close $fh;
	return $out;
}

my $usable = run_perl( <<'PERL' );
use POSIX qw( setlocale LC_MESSAGES );
print setlocale( LC_MESSAGES, 'C.UTF-8' ) || setlocale( LC_MESSAGES, 'en_US.UTF-8' ) ? 1 : 0;
PERL
plan skip_all => 'neither C.UTF-8 nor en_US.UTF-8 can be set here'
  unless $usable;

my $out = run_perl( <<'PERL', "$Bin/data/locale" );
use Locale::Simple;
l_dir( shift );
ltd('test');
l_lang('de_DE');
print join "\n", l('Hello'),
  ln( 'You have %d message', 'You have %d messages', 4 ),
  ln( 'You have %d message', 'You have %d messages', 1 );
PERL

is_deeply(
	[ split /\n/, $out ],
	[ 'Hallo', 'Du hast 4 Nachrichten', 'Du hast 1 Nachricht' ],
	'l_lang translates under the C locale without an installed de_DE',
);

done_testing;
