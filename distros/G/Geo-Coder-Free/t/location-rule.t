#!perl -w

# The location rule - what could be a location at all - is answered in one place:
# Geo::Location::Predicate::_valid_location(), which says false for undef, the
# empty string, a reference and a string of digits only, and true for anything
# else.  Geo::Coder::Free::valid_location() is its public spelling, and the
# facade and both backends import the sub rather than keeping a copy of it
# (section 2.4 of BI-Phase6-Dependency-Specs.md).
#
# That they share one sub today is checked elsewhere: t/edge_cases.t and
# t/function.t compare the reference of each package's _valid_location with the
# one in Geo::Location::Predicate.  A copy written out again is a different sub, so those
# comparisons pass over it: a renamed copy, or the guard typed straight into a
# caller, has its own regex and nothing notices the second answer.
#
# This test reads the source instead.  It scans every module under lib/, every
# script under bin/ and every program under cgi-bin/, and fails when the rule's
# question is spelled out anywhere in this tree.  There is no home file to allow:
# the rule is shipped by Geo-Location-Predicate, a distribution of its own that
# this one depends on, so a spelling here is a copy of it.  POD, whole-line
# comments and anything after __END__/__DATA__ are masked, so prose that
# describes the rule is not read as a copy of it.
#
# What counts as the rule is listed in @SPELLINGS: a negated digit class
# (/\D/, /[^0-9]/, /[^\d]/) and an anchored test that a string is digits from end
# to end (/^\d+$/, /\A\d+\z/, /^(\d+)$/, /^[0-9]+$/).  A question that merely
# resembles it is not the rule and is not reported: /^\d/ asks whether a string
# starts with a digit, /^[A-Z]{1,2}\d/ is a postcode, /^-?\d+\.?\d*$/ is a
# coordinate, /\d+=\d+/ is a SQL injection.  A copy spelled some third way is not
# found either: this is a test for the spellings the rule already has, not a Perl
# parser.
#
# A site that asks one of those questions about something that is not a location
# is listed in %EXEMPT with the reason.  %EXEMPT is checked in both directions,
# so an entry that no longer names a site fails and the table cannot outlive the
# code it was written for.
#
# Tests in t/ are not scanned.  A test writes values out to check what the rule
# answers, which is not a second definition of it.
#
#   prove -l t/location-rule.t

use strict;
use warnings;

use Cwd ();
use File::Find qw(find);
use File::Spec;
use FindBin qw($Bin);
use Test::Most;

# The rule is shipped by a distribution of its own now, Geo-Location-Predicate,
# so this test has no home file to allow: a spelling of the rule anywhere in
# this tree is a copy.  What it still checks is that the rule is reachable and,
# when the sibling checkout is here, that it is that checkout's file answering
# rather than an installed copy that could be older.
my $RULE_DIST = 'Geo-Location-Predicate';
my $RULE_SUB  = '_valid_location';

# The spellings of the rule's question that this test counts, as source text.
# The name and the question are for the failure message: they say what the site
# looks like it is asking.
my @SPELLINGS = (
	{
		name     => 'a negated digit class',
		question => 'whether a string contains a non-digit, so it is not a bare number',
		re       => qr/(?:\\D|\[\^0-9\]|\[\^\\d\])/,
	},
	{
		name     => 'an anchored all-digits test',
		question => 'whether a string is digits from end to end, so it is a bare number',
		re       => qr/(?:\^|\\A)\s*(?:[\(\[]\s*)?\\d\+\s*(?:[\)\]]\s*)?(?:\$|\\z)/,
	},
	{
		name     => 'an anchored all-digits test, spelled as a class',
		question => 'the same, with the digits written out as [0-9]',
		re       => qr/(?:\^|\\A)\s*(?:[\(\[]\s*)?\[0-9\]\+\s*(?:[\)\]]\s*)?(?:\$|\\z)/,
	},
);

# Sites that ask one of those questions about something that is not a location.
# The key is the file, the sub the site is in - the empty string for code in no
# sub at all - and the spelling as it is written there.
my %EXEMPT = (
	'bin/testcgibin' => {
		'' => {
			'^(\d+)$' => {
				reason => 'the test number is a command line argument that has to be'
					. ' digits: the opposite of what the rule answers, and it never'
					. ' reaches a backend',
			},
		},
	},
	'lib/Geo/Coder/Free/MissCache.pm' => {
		'expires_after' => {
			'^\d+$' => {
				reason => 'a cache lifetime has to be a whole number of seconds: the'
					. ' same shape of question about a number, which is not something'
					. ' that could be a location',
			},
		},
	},
	'lib/Geo/Coder/Free/Utils.pm' => {
		'_validate_cache_config' => {
			'^\d+$' => {
				reason => 'a cache configuration value - port, shm_size, max_size - has'
					. ' to be a positive integer: the same shape of question about a'
					. ' number, which is not something that could be a location',
			},
		},
	},
);

# Under prove -t, $Bin is tainted; detaint before it reaches a file name.
my $root = do {
	(my $d = File::Spec->catdir($Bin, File::Spec->updir())) =~ /\A(.*)\z/s;
	$1;
};

# The directory holding the sibling distributions, for the scan below.
my $workspace = File::Spec->catdir($root, File::Spec->updir());

# The check, on source whose answer is known
# ---------------------------------------------------------------------------
# The scan is only worth anything if it can tell the rule from code that merely
# uses digits, so it is run first on source whose answer is known: a copy of the
# sub under another name, the guard typed into a caller, and regexes that ask
# about digits without asking the rule's question.

{
	my $source = <<'SOURCE';
package Example;

use strict;

my $postcode = qr/^[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}$/i;
my $house    = qr/\b\d{1,5}\s+/;
my $year     = qr/^[0-9]{4}$/;
my $host     = qr/^([a-zA-Z0-9.-]+):(\d+)$/;

# A comment that mentions the guard: return $location =~ /\D/ ? 1 : 0;

=head1 SYNOPSIS

    return $location =~ /\D/ ? 1 : 0;    # prose, not code

=cut

sub _is_location {
	my $location = shift;

	return 0 unless defined($location) && length($location);
	return $location =~ /\D/ ? 1 : 0;
}

sub _is_place {
	my $place = shift;

	# The same question, asked again in the other spelling.
	return 0 if $place !~ /^\d+$/;

	return 1;
}

sub _is_number {
	my $value = shift;

	return defined($value) && $value =~ /^(\d+)$/ ? 1 : 0;
}

sub _coordinates {
	my $row = shift;

	return undef unless $row->{'latitude'} =~ /^-?\d+\.?\d*$/;

	return $row;
}

__DATA__
return $location =~ /\D/ ? 1 : 0;
SOURCE

	my $sites = _sites(_masked($source));

	my %by_sub;
	push @{ $by_sub{ $_->{'sub'} } }, $_ for @{ $sites };

	is_deeply([sort keys %by_sub], ['_is_location', '_is_number', '_is_place'],
		'only the subs that ask the rule\'s question are sites')
		or diag('the postcode, house number, year, host and coordinate regexes are not the'
			. ' rule, and the POD, comment and __DATA__ prose is masked');

	is_deeply([map { $_->{'spelling'} } @{ $by_sub{'_is_location'} }], ['\\D'],
		'a copy of the sub under another name is found by its negated digit class');

	is_deeply([map { $_->{'spelling'} } @{ $by_sub{'_is_place'} }], ['^\\d+$'],
		'the guard typed into a caller is found by its anchored all-digits test');

	is_deeply([map { $_->{'spelling'} } @{ $by_sub{'_is_number'} }], ['^(\\d+)$'],
		'and a spelling that captures the digits is found too');

	is($by_sub{'_is_location'}[0]{'text'}, 'return $location =~ /\\D/ ? 1 : 0;',
		'the line reported for a site is the line the spelling is on');
}

# The rule in the distribution
# ---------------------------------------------------------------------------

my %exemption_used;
my %scanned;

foreach my $file(_files()) {
	$scanned{$file} = 1;

	my $path = File::Spec->catfile($root, split(m{/}, $file));
	my $text = _slurp($path);

	ok(defined($text), "$file is readable");
	next unless defined($text);

	foreach my $site(@{ _sites(_masked($text)) }) {
		my $where = "$file:$site->{'line'}";
		my $in    = length($site->{'sub'}) ? " in sub $site->{'sub'}" : '';

		my $exempt = $EXEMPT{$file}{ $site->{'sub'} }{ $site->{'spelling'} };

		if($exempt) {
			$exemption_used{join("\t", $file, $site->{'sub'}, $site->{'spelling'})} = 1;
			pass("$where$in is exempt: $exempt->{'reason'}");
			next;
		}

		fail("$where$in spells the location rule out again: $site->{'name'}, $site->{'spelling'}");
		diag("    $site->{'text'}");
		diag("    The rule asks $site->{'question'}.");
		diag('    It is answered once, by Geo::Location::Predicate::_valid_location():');
		diag('        use Geo::Location::Predicate qw(_valid_location);');
		diag('        return unless _valid_location($value);');
		diag('    A site that asks one of those questions about something that is not a');
		diag('    location goes in %EXEMPT at the top of this test with its reason.');
	}
}

# The rule's distribution
# ---------------------------------------------------------------------------
# The rule lives in a sibling checkout in this workspace, and in an installed
# distribution elsewhere.  Both have to answer; which file did is asserted when
# the checkout is here, because a stale installed copy would otherwise make a
# workspace run green while the tree that is being changed is not the one asked.

my $rule_lib  = File::Spec->catdir($workspace, $RULE_DIST, 'lib');
my $rule_file = File::Spec->catfile($rule_lib, 'Geo', 'Location', 'Predicate.pm');

# Put the checkout ahead of anything installed, as scripts/location-predicate-fuzz.pl
# does, so it is the checkout that is asked.  Without it only prove -l's lib/ is
# searched first and the installed release answers.
unshift @INC, $rule_lib if(-f $rule_file);

ok(eval { require Geo::Location::Predicate; 1 },
	"$RULE_DIST is installed and loads")
	or diag($@);

if(-f $rule_file) {
	is(Cwd::abs_path($INC{'Geo/Location/Predicate.pm'}), Cwd::abs_path($rule_file),
		"the rule answering here is the $RULE_DIST checkout's file");
} else {
	diag("$RULE_DIST is not beside this distribution: the installed rule is the one checked");
}

ok(Geo::Location::Predicate->can($RULE_SUB),
	"$RULE_DIST\::$RULE_SUB is the rule's one spelling");

# The files the scan is supposed to cover
# ---------------------------------------------------------------------------
# A scan that finds no files finds nothing wrong with any of them, so the files
# the rule could be copied into are named here as well.

foreach my $file(
	'lib/Geo/Coder/Free.pm',
	'lib/Geo/Coder/Free/MaxMind.pm',
	'lib/Geo/Coder/Free/OpenAddresses.pm',
	'lib/Geo/Coder/Free/Utils.pm',
	'lib/Geo/Coder/Free/bin/db2sql',
	'bin/address_lookup',
	'cgi-bin/page.fcgi',
) {
	ok($scanned{$file}, "$file is one of the files scanned for the rule");
}

# The sibling geocoders
# ---------------------------------------------------------------------------
# The rule is not only this distribution's.  The six geocoders that take a
# location from a caller - CA, DataScienceToolkit, GeoApify, List, Postcodes and
# XYZ - refuse what it refuses by calling it, rather than by writing it out
# again, and they are scanned here with the same spellings so that a copy cannot
# come back into one of them unnoticed.  A standalone install of this
# distribution has no siblings beside it, and the section is skipped there.

foreach my $sibling(qw(
	Geo-Coder-CA
	Geo-Coder-DataScienceToolkit
	Geo-Coder-GeoApify
	Geo-Coder-List
	Geo-Coder-Postcodes
	Geo-Coder-XYZ
)) {
	my $lib = File::Spec->catdir($workspace, $sibling, 'lib');

	if(!-d $lib) {
		diag("$sibling is not in this workspace: its copy of the rule is not checked");
		next;
	}

	my @modules;
	find({
		no_chdir => 1,
		wanted   => sub {
			push @modules, $File::Find::name if(-f $_ && /\.pm\z/);
		},
	}, $lib);

	ok(scalar(@modules), "$sibling has modules to scan for the rule");

	my @copies;
	foreach my $path(sort @modules) {
		my $text = _slurp($path);
		next unless defined($text);

		push @copies, map { "$path:$_->{'line'}: $_->{'text'}" } @{ _sites(_masked($text)) };
	}

	is_deeply(\@copies, [], "$sibling asks the rule rather than spelling it out")
		or diag("    A geocoder that spells the question out has its own answer, which may"
			. " disagree with this one.\n"
			. '    Call Geo::Location::Predicate::_valid_location() instead.');
}

# An exemption that no longer names a site
# ---------------------------------------------------------------------------

foreach my $file(sort keys %EXEMPT) {
	foreach my $sub(sort keys %{ $EXEMPT{$file} }) {
		foreach my $spelling(sort keys %{ $EXEMPT{$file}{$sub} }) {
			my $site = join(' sub ', $file, length($sub) ? $sub : '(no sub)');

			ok($exemption_used{join("\t", $file, $sub, $spelling)},
				"the exemption for $site, $spelling, still names a site")
				or diag('    No site matches it any more: delete the entry.');
		}
	}
}

done_testing();

# ---------------------------------------------------------------------------

# Every file that could hold the rule: the modules under lib/, the scripts, which
# are in bin/ and in lib/Geo/Coder/Free/bin/, and the CGI programs.
sub _files
{
	my @files;

	find({
		no_chdir => 1,
		wanted   => sub {
			return unless -f $_;
			my $path = $File::Find::name;
			$path =~ s{\A\./}{};
			push @files, $path
				if(($path =~ /\.(?:p[lm]|cgi|fcgi)\z/)
					|| ($path =~ m{(?:\A|/)bin/})
					|| ($path =~ m{\Acgi-bin/}));
		},
	}, qw(lib bin cgi-bin));

	return sort @files;
}

sub _slurp
{
	my $file = shift;

	# The path came from the filesystem, which is tainted under prove -t;
	# matching it untaints the capture.
	my ($path) = $file =~ /\A(.*)\z/s;

	open(my $fh, '<', $path) or return;
	local $/;
	my $text = <$fh>;
	close($fh);

	return $text;
}

# The source with POD, whole-line comments and anything after __END__/__DATA__
# blanked out, so prose that describes the rule is not read as code.  Each
# blanked line is replaced by spaces of the same length, which keeps every offset
# and so every line number in the result the same as in the original.
sub _masked
{
	my $text = shift;

	my @lines = split(/\n/, $text, -1);
	my $in_pod = 0;
	my $after_end = 0;

	for my $index(0 .. $#lines) {
		my $line = $lines[$index];

		# A POD directive starts at column 0, and =cut is the one that ends it.
		if($line =~ /^=(\w+)/) {
			$in_pod = ($1 ne 'cut');
		} elsif($line =~ /^__(?:END|DATA)__\s*\z/) {
			$after_end = 1;
		} elsif(!$after_end && !$in_pod && $line !~ /^\s*#/) {
			next;
		}

		$lines[$index] = ' ' x length($line);
	}

	return join("\n", @lines);
}

# Every spelling of the rule's question in the source, with the sub it is in, the
# line it is on and the text of that line.
sub _sites
{
	my $text = shift;

	my @subs  = _subs($text);
	my @lines = split(/\n/, $text, -1);
	my @sites;

	foreach my $spelling(@SPELLINGS) {
		my $re = $spelling->{'re'};

		while($text =~ /$re/g) {
			my $offset = $-[0];
			my $line   = _line_at($text, $offset);

			push @sites, {
				offset   => $offset,
				line     => $line,
				spelling => $&,
				name     => $spelling->{'name'},
				question => $spelling->{'question'},
				text     => _trimmed($lines[$line - 1]),
				sub      => (_enclosing_sub(\@subs, $offset))[0],
			};
		}
	}

	# In source order, so that two spellings on one line read in the order they
	# appear.
	return [sort { $a->{'offset'} <=> $b->{'offset'} } @sites];
}

# The named subs of the source, in the order they appear.
sub _subs
{
	my $text = shift;

	my @subs;

	while($text =~ /^sub\s+([\w:]+)/mg) {
		push @subs, [$1, $-[0]];
	}

	return @subs;
}

# The sub a position is in: the last one declared before it.  A position before
# the first sub is in no sub at all, and is named as the empty string.
sub _enclosing_sub
{
	my ($subs, $offset) = @_;

	my ($name, $start) = ('', 0);

	foreach my $sub(@{ $subs }) {
		last if($sub->[1] > $offset);
		($name, $start) = @{ $sub };
	}

	return ($name, $start);
}

sub _trimmed
{
	my $line = shift;

	return '' unless defined($line);
	$line =~ s/\A\s+//;
	$line =~ s/\s+\z//;

	return $line;
}

sub _line_at
{
	my ($text, $offset) = @_;

	my $prefix = substr($text, 0, $offset);

	return ($prefix =~ tr/\n//) + 1;
}
