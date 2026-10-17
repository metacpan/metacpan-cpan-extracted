#!/usr/bin/env perl

# Is this the environment the "No databases, no optional parsers" job claims to
# be?  That job runs the test suite with none of the data Geo::Coder::Free can
# answer from and neither of the parsers it can use, so that a test which
# quietly depends on one of them fails there instead of passing on a machine
# that happens to have it.
#
# What that job removes:
#
#   - OpenAddresses, WhosOnFirst, dr5hn and OpenStreetMap data, which the tests
#     find through OPENADDR_HOME, WHOSONFIRST_HOME, DR5HN_HOME and OSM_HOME;
#   - the MaxMind databases under lib/Geo/Coder/Free/MaxMind/databases, which
#     createdatabase.PL builds from a GeoLite2 download and which no entry in
#     the MANIFEST names, so a fresh checkout has none of them;
#   - Geo::Address::Parser, which Makefile.PL recommends, and Geo::libpostal,
#     which is no prerequisite at all: both are loaded only if they are found.
#
# If the job acquired any of that, its result would stop meaning anything - the
# run would pass while exercising the code paths it exists to leave untested -
# so the claim is checked rather than assumed, before the suite runs.
#
# Run it by hand on a machine that does have the data and it fails, naming what
# it found: that machine is not this job.
#
#   perl xt/bare-environment.pl

use strict;
use warnings;

use File::Find;
use File::Spec;
use Test::DescribeMe qw(author);

my $failed = 0;

# The variables the tests read to find their data.
my %dataset = (
	'OPENADDR_HOME'    => 'OpenAddresses',
	'WHOSONFIRST_HOME' => 'WhosOnFirst',
	'DR5HN_HOME'       => 'dr5hn',
	'OSM_HOME'         => 'OpenStreetMap',
);

# Where bin/download_databases puts that data, under the defaults it uses when
# those variables are unset.
my @downloaded = qw(
	etc/openaddr
	src/whosonfirst-sqlite
	src/countries-states-cities-database
	etc/osm
);

# The databases the tests ask for by name.  t/maxmind.t and t/cities.t want
# cities.sql, t/admin1.t and t/admin2.t the .db files beside it; each reports the
# one it is missing and skips, and that report is all that stands between a
# broken code path and a green run.
my $databases = File::Spec->catdir(qw(lib Geo Coder Free MaxMind databases));

# Not installed, and the suite uses it when it is installed.
my @optional = qw(Geo::Address::Parser Geo::libpostal);

# Installed, and the suite cannot run without it: a run missing one of these
# would be measuring a broken install rather than an environment without the
# optional parts.  Test::Without::Module is what blocks the optional parsers, so
# it belongs here too.
my @required = qw(Lingua::EN::AddressParse Geo::StreetAddress::US Test::Without::Module);

foreach my $name(sort keys %dataset) {
	check(!length($ENV{$name} // ''),
		"$name is unset, so there is no $dataset{$name} data to find",
		sub { "it is set to $ENV{$name}: unset it, and take it out of the job," .
			' before the run means anything' });
}

my $home = $ENV{'HOME'} // '';

foreach my $dir(@downloaded) {
	my $path = File::Spec->catdir($home, split(m{/}, $dir));

	check(!-e $path, "nothing is downloaded at $path",
		'a step has downloaded the data, or the image ships it');
}

my @built;

if(-d $databases) {
	find({
		no_chdir => 1,
		wanted   => sub { push @built, $File::Find::name if -f && /\.(?:sql|db)$/ },
	}, $databases);
}

check(!@built, 'no MaxMind database is built in the checkout',
	'found ' . join(', ', sort @built) .
	': the tests would read it instead of reporting what is missing');

foreach my $module(@optional) {
	check(!loads($module), "$module is not installed",
		sub { "$module is installed, and the suite uses it when it finds it:" .
			' Geo::Address::Parser is recommended by Makefile.PL, so cpanm' .
			' without --no-recommends, or a prerequisite of a prerequisite,' .
			' is how it came back' });
}

foreach my $module(@required) {
	check(loads($module), "$module is installed",
		"the suite cannot run without it");
}

if($failed) {
	print "\n$failed check", (($failed == 1) ? '' : 's'), " failed: this is not a bare environment\n";
	exit(1);
}

print "\nThere is no database and no optional parser here\n";

exit(0);

# ---------------------------------------------------------------------------

# Prints the result of one check, and remembers a failure.
sub check
{
	my ($ok, $what, $why) = @_;

	print(($ok ? 'ok' : 'not ok'), " - $what\n");

	unless($ok) {
		$failed++;

		# The reason is a sub where it names the value that failed the check, so
		# that it is only worked out when it is needed.
		print "\t", (ref($why) eq 'CODE' ? $why->() : $why), "\n" if defined($why);
	}

	return $ok;
}

# Whether a module can be loaded, which for the optional parsers is the
# difference between "not installed" and "installed but not wanted".
sub loads
{
	my $module = shift;
	(my $file = $module) =~ s{::}{/}g;

	return eval { require "$file.pm"; 1 } ? 1 : 0;
}
