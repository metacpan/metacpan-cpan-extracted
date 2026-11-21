#!/usr/bin/env perl
#
# What happens to the text of an operating system error in other locales.
#
# Two of the module's warnings carry an OS error: sendmail that cannot be run
# (sendmail_failed) and a key directory that cannot be read (keydir_unreadable).
# The OS part follows the locale of the process.  Each is raised in a child perl
# started with LC_ALL set, and the child compares the warning with the string
# Perl itself gives for ENOENT - local $! = ENOENT; "$!" - in that same process,
# so the C library's strerror is never asked directly and the two cannot
# diverge.  A locale that is not installed falls back to the C locale, which
# still has to agree with itself, so the test needs no locale to be present.
#
# There is no geographic (GeoIP) test: this module decides nothing from a
# client's country, and a test of country-based access would test something
# that does not exist here.

use strict;
use warnings;

use Test::Most;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);

my $LIB = File::Spec->catdir($Bin, File::Spec->updir(), 'lib');
BAIL_OUT("Cannot find $LIB") unless(-d $LIB);

my $MISSING = File::Spec->catdir(tempdir('CLEANUP' => 1), 'does-not-exist');

# English, German, and Japanese and Chinese for the East Asian cases.
my @LOCALES = qw(en_US.UTF-8 de_DE.UTF-8 ja_JP.UTF-8 zh_CN.UTF-8);

# Raises the error named by argv[0] and says what became of it.
my $CHILD = <<'CHILD';
use strict;
use warnings;
use Errno qw(ENOENT);
use Mail::Send::DKIM;

my ($kind, $path) = @ARGV;
my @warnings;
local $SIG{'__WARN__'} = sub { push(@warnings, @_) };

my $dkim = Mail::Send::DKIM->new('keydir' => $path, 'sendmail' => $path);
my $result = $kind eq 'send' ? $dkim->send("x\n") : $dkim->selector();

my $expected;
{
	local $! = ENOENT;
	$expected = "$!";
}

my $carried = scalar(grep { index($_, $expected) >= 0 } @warnings);
print 'RESULT=', (defined($result) ? $result : 'undef'), "\n";
print 'WARNINGS=', scalar(@warnings), "\n";
print 'CARRIED=', $carried, "\n";
CHILD

sub in_locale
{
	my ($locale, $kind) = @_;

	local $ENV{'LC_ALL'} = $locale;
	local $ENV{'LANG'} = $locale;
	local $ENV{'LANGUAGE'} = $locale;
	# An uninstalled locale falls back to C; perl's complaint about it is noise.
	local $ENV{'PERL_BADLANG'} = 0;

	# PERL5LIB is left alone: the dependencies may be reachable only through it.
	open(my $child, '-|', $^X, '-I', $LIB, '-e', $CHILD, $kind, $MISSING)
		or BAIL_OUT("Cannot run $^X: $!");
	my %seen = map { /\A(\w+)=(.*)\z/ ? ($1 => $2) : () } map { chomp; $_ } <$child>;
	close($child);

	return \%seen;
}

foreach my $locale (@LOCALES) {
	subtest "$locale: a sendmail that cannot be run" => sub {
		my $seen = in_locale($locale, 'send');

		is($seen->{'RESULT'}, 1, 'returns 1, and does not throw');
		is($seen->{'WARNINGS'}, 1, 'warns once');
		is($seen->{'CARRIED'}, 1, 'and the warning carries the OS error as this locale words it');
	};

	subtest "$locale: a key directory that cannot be read" => sub {
		my $seen = in_locale($locale, 'selector');

		is($seen->{'RESULT'}, 'undef', 'gives undef, and does not throw');
		is($seen->{'WARNINGS'}, 1, 'warns once');
		is($seen->{'CARRIED'}, 1, 'and the warning carries the OS error as this locale words it');
	};
}

done_testing();
