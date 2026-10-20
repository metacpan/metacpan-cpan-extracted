#!/usr/bin/env perl

# Fuzz the six sibling geocoders' "could this be a location?" rule against
# Geo::Location::Predicate, and report every class of input on which they
# disagree.
#
# Each sibling geocode() asks Geo::Location::Predicate::_valid_location() and
# nothing else, so the harness does not re-implement any of it.  It drives the
# real geocode() with a user agent that dies the moment a lookup would be made,
# and reads the verdict off what happened: a croak naming the input means the
# predicate refused it, a returned value or the sentinel means it was accepted.
# Nothing touches the network.
#
# Usage:
#     perl scripts/location-predicate-fuzz.pl [--iterations N] [--seed S]
#                                             [--sibling DIST|MODULE ...]
#                                             [--report | --no-check]
#                                             [--summary=FILE]
#                                             [--update-document[=FILE]]
#
# The output is Markdown: a table of the curated input classes, then the
# randomised run over scalars, references and undef.  The exit status is the
# verdict as well as the report: a sibling whose answer on any value - a scalar,
# a reference or undef - differs from the rule's fails the run, and the class or
# the value is named on both streams.  That is the runtime half of
# t/location-rule.t, which reads the same six siblings' source for the rule's
# spellings; this one asks them.  A build that runs it gets a regression check
# without having to remember a flag, and --report is the explicit report-only
# form for a caller that wants the table and not the verdict (--no-check is the
# same thing; --check is still accepted, because it is now what a plain run
# does).  A verdict the harness cannot read at all also fails the run.
#
# It needs the six checkouts, and the checkout of the distribution that holds the
# rule, beside this one - the layout the CI job assembles, and the one an author's
# workspace has - and says so when they are not there rather than reporting a skip
# that looks like agreement.
#
# --sibling grades only the sibling it names, and the report says which were left
# out.  That is what each of the six runs in its own pipeline: the drift this looks
# for is a change in one of them, so the distribution that would have to fix it
# should hear about it without waiting for another repository's daily run - and
# without going red for a divergence in a sibling it does not ship.  It takes the
# distribution name (Geo-Coder-CA) or the module's (Geo::Coder::CA), repeatable,
# and only the named siblings are loaded, constructed and driven, so a job that
# belongs to one of them installs that one's dependencies and nobody else's.
# Without it the run grades all six, which is what Geo-Coder-Free's job does.
#
# --update-document writes the report into the Markdown document that quotes it -
# LOCATION-PREDICATE-FUZZ.md in this distribution unless a file is named - and
# replaces the sample there rather than asking an author to retype it.  The span
# it replaces is the one the document says the sample is: from the '## Harness
# output' heading the harness prints to the end of the file, or to the next '## '
# section if one is added after it.  The prose before that heading is left alone.
# A run that fails the gate writes nothing, because the document quotes a run that
# passes; the report is still printed, so the flag never hides a failure.
#
# --summary=FILE writes the same run as JSON: the seed and the iteration count,
# the rule that answered and where it was loaded from, the siblings graded and
# the ones left out by --sibling, the verdict on every curated class per sibling,
# the counts the randomised run produced, and the gate's verdict with every
# disagreement as a record rather than a line of prose.  The report is a
# rendering of that data, and a rendering is free to be reworded; a caller that
# has to assert what a run found wants the data.  t/location-predicates.t is that
# caller.  The file is written whether the gate passed or failed, because the
# counts of a failing run are the ones worth reading, and the report and the exit
# status are unchanged: stdout is still the Markdown.

use strict;
use warnings;

use FindBin qw($Bin);

# The rule's file in this workspace, worked out by the BEGIN below and checked
# once the module has been loaded, and the workspace itself, which is where the
# document that quotes the report lives.  They are declared out here because
# 'our' inside a block is scoped to that block.
our $RULE_FILE;
our $WORKSPACE;

# The checkouts sit side by side, and this file is run from different places: the
# workspace root, which is where it was written, and Geo-Coder-Free/xt, which is
# where it lives.  So the workspace is whichever of those holds the
# Geo-Coder-Free checkout, and every sibling has to be in it.
BEGIN {
	require Cwd;
	require File::Spec;

	# The rule is shipped by Geo-Location-Predicate, a distribution of its own, so
	# it is one of the checkouts this needs: the comparison is against the tree
	# being changed, not against whichever copy is installed.
	my @DISTS = qw(
		Geo-Coder-Free
		Geo-Location-Predicate
		Geo-Coder-CA
		Geo-Coder-DataScienceToolkit
		Geo-Coder-GeoApify
		Geo-Coder-List
		Geo-Coder-Postcodes
		Geo-Coder-XYZ
	);

	my $workspace;
	for my $candidate ($Bin, "$Bin/..", "$Bin/../..") {
		next unless -d "$candidate/Geo-Coder-Free/lib/Geo/Coder/Free";
		$workspace = $candidate;
		last;
	}
	die 'Cannot find a Geo-Coder-Free checkout beside ', File::Spec->canonpath($Bin), "\n"
		unless defined($workspace);

	# Spelled out without the '..' the candidate was built from: this is the message
	# a build reads when a checkout failed, and it names the directory to look in.
	my $here = Cwd::abs_path($workspace) // File::Spec->canonpath($workspace);
	$WORKSPACE = $here;
	for my $dist (@DISTS) {
		die "The sibling checkout $dist is not in $here: this fuzz needs "
			. scalar(@DISTS) . " checkouts beside each other\n"
			unless -d "$workspace/$dist/lib";
	}

	unshift @INC, map { "$workspace/$_/lib" } @DISTS;

	# Which file the rule has to come from.  The check below is against this, so
	# that a run cannot be graded against an installed release: an installed copy
	# answers for a tree that is not the one being changed, and a gate that graded
	# it would agree with itself - the same reason t/location-rule.t names the file
	# it expects to have answered.
	$RULE_FILE = Cwd::abs_path("$workspace/Geo-Location-Predicate/lib/Geo/Location/Predicate.pm");
}

use Getopt::Long qw(GetOptions);
use Geo::Location::Predicate qw(_valid_location);

# The rule answering here is the checkout in this workspace, or nothing else in
# it is worth the fuzz: an installed copy would grade the six against a rule that
# is not the one under test, and would do it silently.
{
	my $from = $INC{'Geo/Location/Predicate.pm'};
	my $loaded = defined($from) ? Cwd::abs_path($from) : undef;

	if(!defined($loaded) || !defined($RULE_FILE) || $loaded ne $RULE_FILE) {
		die 'The rule that loaded is ', ($loaded // 'nothing'),
			', not the checkout beside this distribution (', ($RULE_FILE // 'none'),
			"): this run has to grade the tree being changed\n";
	}
}

# The six, by the name their distribution is published under and the name the
# module loads as.  A job that belongs to one of them asks for that one and grades
# only it - the same question, in the pipeline that would have to fix it - and the
# mapping means it can ask with either name.
my %SIBLING_OF = (
	'Geo-Coder-CA'                 => 'Geo::Coder::CA',
	'Geo-Coder-DataScienceToolkit' => 'Geo::Coder::DataScienceToolkit',
	'Geo-Coder-GeoApify'           => 'Geo::Coder::GeoApify',
	'Geo-Coder-List'               => 'Geo::Coder::List',
	'Geo-Coder-Postcodes'          => 'Geo::Coder::Postcodes',
	'Geo-Coder-XYZ'                => 'Geo::Coder::XYZ',
);

# Sorted by distribution name, which is the order the report has always listed
# them in, so a restricted run and a full one agree on it.
my @ALL_SIBLINGS = map { $SIBLING_OF{$_} } sort keys %SIBLING_OF;

my $iterations = 5000;
my $seed = 20261017;
# A disagreement is a failure.  The harness is a regression check, and a run that
# had to be asked for its verdict is one that can be run without it and go green
# with a sibling answering something else; so the gate is what a plain run does,
# and --report is how a caller asks for the table alone.
my $check = 1;
my @wanted;
# undef: print the report and write nothing.  Empty: the document in this
# distribution, which is the one the job compares against.  Anything else: the
# file the caller named.
my $update;
# undef: print the report and write no summary.  Anything else: the file the
# JSON summary goes to.  It is a file rather than stdout because the report is
# stdout and the two renderings of one run cannot share a stream: JSON appended
# to Markdown is neither readable nor parseable.
my $summary;

GetOptions(
	'iterations=i'      => \$iterations,
	'seed=i'            => \$seed,
	'check!'            => \$check,
	'report'            => sub { $check = 0 },
	'sibling=s'         => \@wanted,
	'summary=s'         => \$summary,
	'update-document:s' => \$update,
) or die "Usage: $0 [--iterations N] [--seed S] [--sibling DIST|MODULE ...]",
	" [--check|--no-check|--report] [--summary=FILE] [--update-document[=FILE]]\n";

# Named here so that report() can see it; a summary of a run that failed the gate
# is written like any other.
my $summary_file = $summary;

my $document;
$document = length($update) ? $update
	: File::Spec->catfile($WORKSPACE, 'Geo-Coder-Free', 'LOCATION-PREDICATE-FUZZ.md')
	if defined($update);

# --sibling takes either spelling a caller would reach for - the distribution,
# which is what the job's own checkout is called, or the module - and a
# comma-separated list is the same as repeating the flag.
my @graded;
if(@wanted) {
	my %module_of = (%SIBLING_OF, map { $_ => $_ } values %SIBLING_OF);

	for my $asked (map { split(/,/, $_) } @wanted) {
		next unless defined($asked);
		(my $name = $asked) =~ s/^\s+|\s+$//g;
		next unless length($name);

		die "--sibling does not name one of the six: '$name' (one of: ",
			join(', ', sort keys %SIBLING_OF), ")\n" unless exists($module_of{$name});

		push @graded, $module_of{$name}
			unless grep { $_ eq $module_of{$name} } @graded;
	}

	die "--sibling was given but named nothing to grade\n" unless @graded;

	# Reported in the harness's own order rather than the order they were asked
	# for, so two runs of the same job produce the same report.
	@graded = grep { my $module = $_; grep { $_ eq $module } @graded } @ALL_SIBLINGS;
} else {
	@graded = @ALL_SIBLINGS;
}

for my $module (@graded) {
	(my $file = $module) =~ s{::}{/}g;
	require "$file.pm";	## no critic (Modules::RequireBarewordIncludes)
}

# ---------------------------------------------------------------------------
# The stub user agent
# ---------------------------------------------------------------------------

package Fuzz::UA;

sub new { return bless {}, shift }

# Any value that gets this far has passed the predicate: the module is about to
# do the lookup, which is the line the fuzz must not cross.
sub get { die "FUZZ_REACHED_NETWORK\n" }

sub default_header { return $_[0] }
sub env_proxy      { return $_[0] }
sub ssl_opts       { return $_[0] }
sub DESTROY        { }

# Values with a stringification of their own, for the reference classes.
# Geo::Coder::List sends its "not a location" complaints to a logger rather
# than through warn/croak, so the harness supplies one that records them.
package Fuzz::Logger;

sub new { return bless { events => [] }, shift }

sub _record
{
	my $self = shift;
	my $level = shift;

	push @{$self->{'events'}}, "$level: " . join('', @_);

	return;
}

sub warn  { return $_[0]->_record('warn',  @_[1 .. $#_]) }
sub error { return $_[0]->_record('error', @_[1 .. $#_]) }
sub debug { return; }
sub info  { return; }
sub trace { return; }
sub events { return $_[0]->{'events'} }
sub clear { return @{$_[0]->{'events'}} = () }
sub DESTROY { }

package Fuzz::Plain;

sub new { return bless {}, shift }

package Fuzz::Str;

use overload '""' => sub { $_[0]->{'s'} }, fallback => 1;

sub new
{
	my ($class, $s) = @_;

	return bless { s => $s }, $class;
}

# A reference whose boolean value is false, as a db row object might be.
package Fuzz::FalseStr;

use overload '""' => sub { $_[0]->{'s'} }, 'bool' => sub { 0 }, fallback => 1;

sub new
{
	my ($class, $s) = @_;

	return bless { s => $s }, $class;
}

package main;

# ---------------------------------------------------------------------------
# The predicates under test
# ---------------------------------------------------------------------------

my @SIBLINGS = (
	{
		name   => 'Geo::Coder::CA',
		file   => 'Geo-Coder-CA/lib/Geo/Coder/CA.pm',
		maker  => sub { Geo::Coder::CA->new(ua => Fuzz::UA->new(), host => 'localhost') },
	},
	{
		name   => 'Geo::Coder::DataScienceToolkit',
		file   => 'Geo-Coder-DataScienceToolkit/lib/Geo/Coder/DataScienceToolkit.pm',
		# This one's new() hands Object::Configure an arrayref, so the user agent
		# goes in through the accessor instead of the constructor.
		maker  => sub {
			my $geocoder = Geo::Coder::DataScienceToolkit->new();
			$geocoder->ua(Fuzz::UA->new());
			return $geocoder;
		},
	},
	{
		name   => 'Geo::Coder::GeoApify',
		file   => 'Geo-Coder-GeoApify/lib/Geo/Coder/GeoApify.pm',
		maker  => sub {
			Geo::Coder::GeoApify->new(
				apiKey => 'fuzz',
				ua     => Fuzz::UA->new(),
				host   => 'localhost',
			)
		},
	},
	{
		name   => 'Geo::Coder::List',
		file   => 'Geo-Coder-List/lib/Geo/Coder/List.pm',
		# Object::Configure puts its own logger in, so ours is installed after
		# construction rather than passed to new().
		maker  => sub {
			my $list = Geo::Coder::List->new();
			$list->{'logger'} = Fuzz::Logger->new();
			return $list;
		},
		logger => 1,	# read the recorded messages after each call
	},
	{
		name   => 'Geo::Coder::Postcodes',
		file   => 'Geo-Coder-Postcodes/lib/Geo/Coder/Postcodes.pm',
		maker  => sub { Geo::Coder::Postcodes->new(ua => Fuzz::UA->new(), host => 'localhost') },
	},
	{
		name   => 'Geo::Coder::XYZ',
		file   => 'Geo-Coder-XYZ/lib/Geo/Coder/XYZ.pm',
		maker  => sub { Geo::Coder::XYZ->new(ua => Fuzz::UA->new(), host => 'localhost') },
	},
);

sub build_predicates
{
	for my $sibling (@SIBLINGS) {
		my $object = eval { $sibling->{'maker'}->() };
		die "Cannot construct $sibling->{'name'}: $@" if $@;
		$sibling->{'object'} = $object;
		$sibling->{'logger'} = $object->{'logger'} if $sibling->{'logger'};
	}

	return @SIBLINGS;
}

# ---------------------------------------------------------------------------
# One verdict
# ---------------------------------------------------------------------------

sub _oneline
{
	my $text = shift;

	$text =~ s/\s+/ /g;
	$text =~ s/^\s+|\s+$//g;

	return $text;
}

# 'REJECT' when the predicate refused the value; 'ACCEPT' when it let it
# through to the lookup (or returned before reaching one, as List does with no
# geocoders); 'ERROR' for anything the harness did not anticipate, which is
# itself worth reporting.
sub verdict
{
	my ($sibling, $value) = @_;

	my @warnings;
	$sibling->{'logger'}->clear() if $sibling->{'logger'};
	my $returned = eval {
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$sibling->{'object'}->geocode(location => $value);
		1;
	};
	my $error = $@ // '';
	push @warnings, @{$sibling->{'logger'}->events()} if $sibling->{'logger'};

	if(!$returned) {
		return ('ACCEPT', 'reached the lookup')
			if $error =~ /FUZZ_REACHED_NETWORK/;
		# Postcodes.io rejects an address after the location predicate has
		# accepted it; that is the endpoint's policy, not the predicate.
		return ('ACCEPT', 'post-predicate policy: ' . _oneline($error))
			if $error =~ /only supports towns/;
		return ('REJECT', _oneline($error))
			if $error =~ /invalid input|Usage:/;
		return ('ERROR', _oneline($error));
	}

	# Geo::Coder::List warns and returns for undef and '' rather than croaking,
	# and with a logger configured it does not even warn.
	for my $warning (@warnings) {
		return ('REJECT', _oneline($warning))
			if $warning =~ /usage: geocode|invalid input/i;
	}

	return ('ACCEPT', 'returned without a lookup');
}

sub free_verdict
{
	my $value = shift;

	return _valid_location($value) ? 'ACCEPT' : 'REJECT';
}

# ---------------------------------------------------------------------------
# The curated classes
# ---------------------------------------------------------------------------

sub blessed
{
	my ($class, $string) = @_;

	return $class->new($string);
}

my @CLASSES = (
	{
		name   => 'undef',
		values => [undef],
	},
	{
		name   => 'empty string',
		values => [''],
	},
	{
		name   => 'zero',
		values => ['0', 0, 0.0],
	},
	{
		name   => 'digits only',
		values => [
			'1',
			'0044',
			'12345678901234567890',
			'9' x 200,
			"\x{0661}\x{0662}",	# Arabic-Indic digits
			"\x{FF11}\x{FF12}",	# fullwidth digits
		],
	},
	{
		name   => 'string with a non-digit',
		values => [
			'London',
			'Ramsgate, Kent',
			' ',
			'-',
			'+44',
			'3.14',
			"12\n",
			'12a',
			"\x{00E9}",
			'0 but true',
		],
	},
	{
		name   => 'unblessed reference',
		values => [
			\1,
			[1, 2],
			{ a => 1 },
			sub { },
			\*STDOUT,
			qr/x/,
		],
		note   => 'A reference is not a string, so the rule refuses it before it looks'
			. ' at anything else; the string form `ARRAY(0x...)` contains a non-digit and'
			. ' is what a check on the string would have accepted.',
	},
	{
		name   => 'blessed reference, plain',
		values => [blessed('Fuzz::Plain')],
		note   => 'As above: the default string form `Fuzz::Plain=HASH(0x...)` is a'
			. ' non-digit string, so a check on the string would have accepted it.',
	},
	{
		name   => 'blessed reference, stringifies to a location',
		values => [blessed('Fuzz::Str', 'London')],
		note   => 'An overloaded `""` returns `London`, which is accepted on its own;'
			. ' the reference must be refused all the same.',
	},
	{
		name   => 'blessed reference, stringifies to digits',
		values => [blessed('Fuzz::Str', '0044')],
		note   => 'The overload returns `0044`, which is refused on its own; the'
			. ' reference must be refused for being a reference and not for its digits.',
	},
	{
		name   => 'blessed reference, false boolean, stringifies to a location',
		values => [blessed('Fuzz::FalseStr', 'London')],
		note   => 'A false object is refused for being a reference, not for being'
			. ' false: the two reasons have to give the same answer in every module.',
	},
	{
		name   => 'blessed reference, false boolean, stringifies to digits',
		values => [blessed('Fuzz::FalseStr', '0044')],
		note   => 'Both a false boolean and digits, which the one rule answers once.',
	},
);

sub class_summary
{
	my ($sibling, $class) = @_;

	my %seen;
	for my $value (@{$class->{'values'}}) {
		my ($verdict) = verdict($sibling, $value);
		$seen{$verdict}++;
	}

	return join('/', sort keys %seen);
}

sub free_summary
{
	my $class = shift;

	my %seen;
	for my $value (@{$class->{'values'}}) {
		$seen{free_verdict($value)}++;
	}

	return join('/', sort keys %seen);
}

# ---------------------------------------------------------------------------
# The randomised run
# ---------------------------------------------------------------------------

my @SCALAR_CHARS = ('a' .. 'z', 'A' .. 'Z', '0' .. '9', ' ', ',', '.', '-', '+', "\n", "\t", 'é', 'ß', '£');

sub random_scalar
{
	my $kind = int(rand(5));

	# Numeric strings, including the long ones a numeric column holds.
	if($kind == 0) {
		my $length = 1 + int(rand(24));
		return join('', map { int(rand(10)) } 1 .. $length);
	}

	# Actual numbers.
	if($kind == 1) {
		return int(rand(2_000_000)) - 1_000_000;
	}
	if($kind == 2) {
		return (rand(2) ? -1 : 1) * rand(1000);
	}

	# Arbitrary text, often with a digit or two to keep it near the boundary.
	my $length = int(rand(20));
	my $text = join('', map { $SCALAR_CHARS[int(rand(@SCALAR_CHARS))] } 1 .. $length);

	return $text;
}

sub random_reference
{
	my $kind = int(rand(10));

	return \1                 if $kind == 0;
	return [1, 2, 3]          if $kind == 1;
	return { a => 1 }         if $kind == 2;
	return sub { }            if $kind == 3;
	return \*STDOUT           if $kind == 4;
	return qr/x/              if $kind == 5;
	return blessed('Fuzz::Plain') if $kind == 6;
	return blessed('Fuzz::Str', random_scalar()) if $kind == 7;
	return blessed('Fuzz::FalseStr', random_scalar()) if $kind == 8;
	return blessed('Fuzz::Str', join('', map { int(rand(10)) } 1 .. (1 + int(rand(6)))));
}

sub random_value
{
	my $kind = int(rand(10));

	return undef if $kind == 0;          # undef
	return random_reference() if $kind >= 7;  # references
	return random_scalar();
}

sub describe
{
	my $value = shift;

	return 'undef' unless defined($value);
	return "reference ($value)" if ref($value);
	(my $shown = $value) =~ s/([^\x20-\x7e])/sprintf('\\x{%X}', ord($1))/ge;
	$shown = substr($shown, 0, 40) . '...' if length($shown) > 40;

	return "scalar ('$shown')";
}

sub random_phase
{
	my ($iterations) = @_;

	my @predicates = @SIBLINGS;
	my %scalar_disagreements;
	my %reference_disagreements;
	my %sibling_splits;
	my %errors;
	my $scalars = 0;
	my $refs = 0;
	my $undefs = 0;

	for my $iteration (1 .. $iterations) {
		my $value = random_value();

		if(!defined($value)) {
			$undefs++;
		} elsif(ref($value)) {
			$refs++;
		} else {
			$scalars++;
		}

		my $free = free_verdict($value);
		my @pairs = map { my ($v) = verdict($_, $value); [$_, $v] } @predicates;
		my @verdicts = map { $_->[1] } @pairs;
		my %distinct = map { $_ => 1 } @verdicts;

		for my $verdict (@verdicts) {
			if($verdict eq 'ERROR') {
				$errors{describe($value)} = 1;
			}
		}

		my $sibling_differs = grep { $_ ne $free } @verdicts;
		next unless $sibling_differs || scalar(keys %distinct) > 1;

		my $key = join(' ', map { $_->[0]->{'name'} . '=' . $_->[1] } @pairs);
		# The rule's own verdict travels with the value: it is what the gate is
		# measured against, and a verdict pattern alone does not say which of the
		# two a sibling came from.  References are kept in their own bucket so the
		# report can count them separately, but they are graded the same way.
		if(!defined($value) || !ref($value)) {
			$scalar_disagreements{$key} //= { value => describe($value), rule => $free };
		} else {
			$reference_disagreements{$key} //= { value => describe($value), rule => $free };
		}
		$sibling_splits{$key}++ if(scalar(keys %distinct) > 1);
	}

	return {
		iterations             => $iterations,
		scalars                => $scalars,
		references             => $refs,
		undefs                 => $undefs,
		scalar_disagreements   => \%scalar_disagreements,
		reference_disagreements => \%reference_disagreements,
		sibling_splits         => \%sibling_splits,
		errors                 => \%errors,
	};
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

sub pattern
{
	my $class = shift;

	my %verdict;
	for my $sibling (@SIBLINGS) {
		$verdict{$sibling->{'name'}} = class_summary($sibling, $class);
	}

	return (free_summary($class), \%verdict);
}

# Every curated class and every generated value on which a sibling does not answer
# what the rule answers.  A reference is a value like any other here: the six
# refuse it for being a reference, and a copy that lets it through is drift the
# gate has to catch - the rule's answer on a reference is part of what the six
# are compared with, not a separate question.
sub violations
{
	my @found;

	for my $class (@CLASSES) {
		for my $value (@{$class->{'values'}}) {
			my $free = free_verdict($value);
			for my $sibling (@SIBLINGS) {
				my ($verdict, $why) = verdict($sibling, $value);
				next if $verdict eq $free;
				push @found, {
					kind    => 'curated',
					class   => $class->{'name'},
					sibling => $sibling->{'name'},
					verdict => $verdict,
					rule    => $free,
					why     => $why,
				};
			}
		}
	}

	return @found;
}

# One violation as the sentence the report prints and the log keeps.  The records
# are what --summary writes and what a caller asserts on; this is how a reader
# sees the same thing.
sub violation_text
{
	my ($violation) = @_;

	return sprintf("curated class '%s': %s says %s, the rule says %s (%s)",
		@{$violation}{qw(class sibling verdict rule why)})
		if $violation->{'kind'} eq 'curated';

	return sprintf('generated %s: %s; the rule says %s',
		@{$violation}{qw(value pattern rule)});
}

# The machine-readable form of the run.  JSON::PP is core, so asking for a
# summary needs nothing installed: this harness runs in eight repositories' jobs,
# several of which install their own list of modules and would otherwise have to
# be told about one more.
sub write_summary
{
	my ($found) = @_;

	require JSON::PP;

	my $json = JSON::PP->new->canonical->pretty->utf8->encode($found);

	open(my $out, '>', $summary_file)
		or die "Cannot write the summary to $summary_file: $!\n";
	print {$out} $json or die "Cannot write the summary to $summary_file: $!\n";
	close($out) or die "Cannot close $summary_file: $!\n";

	return;
}

sub report
{
	# --sibling, if it was given, has already narrowed what was loaded; this is
	# the same narrowing for the predicates that get constructed, driven and
	# graded.  The ones left out are named in the report rather than being
	# silently absent, because a green run that only looked at one sibling is a
	# different claim from a green run that looked at six.
	my %graded = map { $_ => 1 } @graded;
	@SIBLINGS = grep { $graded{$_->{'name'}} } @SIBLINGS;

	build_predicates();
	srand($seed);

	# What the run found, as data.  The report below is one rendering of it and
	# --summary writes it out as it stands, so the two cannot say different
	# things: every count and verdict the report prints is recorded here as it is
	# printed, from the same variable the print used.
	my %summary = (
		seed       => $seed,
		iterations => $iterations,
		check      => $check ? 1 : 0,
		rule       => {
			module => 'Geo::Location::Predicate::_valid_location',
			file   => $RULE_FILE,
		},
		siblings   => [map { $_->{'name'} } @SIBLINGS],
		not_driven => [],
	);

	print "## Harness output\n\n";
	if(@SIBLINGS == @ALL_SIBLINGS) {
		print "Six sibling geocoders, each asking `_valid_location()` from `geocode()`:\n\n";
	} else {
		print scalar(@SIBLINGS), ' sibling geocoder', (@SIBLINGS == 1 ? '' : 's'),
			', selected with --sibling, ', (@SIBLINGS == 1 ? 'asking' : 'each asking'),
			" `_valid_location()` from `geocode()`:\n\n";
	}
	for my $sibling (@SIBLINGS) {
		print "- `$sibling->{'name'}` - `$sibling->{'file'}`\n";
	}

	# A restricted run is a verdict about the siblings it named and about no
	# other, which is the point of it in a distribution's own pipeline; saying so
	# here keeps the report from reading like the full-workspace one.
	if(@SIBLINGS != @ALL_SIBLINGS) {
		my %shown = map { $_->{'name'} => 1 } @SIBLINGS;
		my @left = grep { !$shown{$_} } @ALL_SIBLINGS;
		$summary{'not_driven'} = \@left;
		print "\nNot driven in this run (--sibling): ", join(', ', map { "`$_`" } @left),
			".  Their verdicts are not part of it.\n";
	}
	print "\nThe reference rule is `Geo::Location::Predicate::_valid_location`",
		" (`Geo-Location-Predicate/lib/Geo/Location/Predicate.pm`).\n\n";
	print "Verdicts: `ACCEPT` means the predicate let the value through to the lookup",
		" (the stub user agent dies there, so no request is made); `REJECT` means it",
		" refused the value before that point.  The random seed is $seed.\n\n";

	print "### Curated classes\n\n";
	# Printed as a table, then walked again for the ones that disagree.  Each class
	# is driven once and both readings come from that one drive, so the table, the
	# list below it and the summary cannot be three readings of the same class.
	print '| Input class | Predicate | ', join(' | ', map { $_->{'name'} } @SIBLINGS), " |\n";
	print '| --- | --- | ', join(' | ', map { '---' } @SIBLINGS), " |\n";

	my @curated;
	for my $class (@CLASSES) {
		my ($free, $verdicts) = pattern($class);
		print "| $class->{'name'} | $free | ",
			join(' | ', map { $verdicts->{$_->{'name'}} } @SIBLINGS), " |\n";

		my %distinct = map { $verdicts->{$_} => 1 } keys %{$verdicts};
		push @curated, {
			name      => $class->{'name'},
			predicate => $free,
			siblings  => { map { $_->{'name'} => $verdicts->{$_->{'name'}} } @SIBLINGS },
			disagrees => (scalar(keys %distinct) > 1
				|| grep { $verdicts->{$_} ne $free } keys %{$verdicts}) ? 1 : 0,
			note      => $class->{'note'},
		};
	}
	$summary{'curated'} = { classes => \@curated, disagreements => 0 };

	print "\n#### Where they disagree\n\n";
	my $disagreements = 0;
	for my $class (@curated) {
		next unless $class->{'disagrees'};
		$disagreements++;

		my $says = join(', ', map { "$_ says " . $class->{'siblings'}{$_} } @SIBLINGS);
		print "- **$class->{'name'}** - Predicate says $class->{'predicate'}; $says.\n";
		print "  $class->{'note'}\n" if $class->{'note'};
	}
	print "- None: every curated class is answered the same way by the rule and every",
		" sibling under test.\n"
		unless $disagreements;
	$summary{'curated'}{'disagreements'} = $disagreements;

	print "\n### Randomised run\n\n";
	my $random = random_phase($iterations);
	print "Generated $random->{'iterations'} values: $random->{'scalars'} scalars,",
		" $random->{'undefs'} undefs and $random->{'references'} references.\n\n";

	my $scalar_count = scalar keys %{$random->{'scalar_disagreements'}};
	print "- Scalar/undef disagreements: $scalar_count.\n";
	for my $key (sort keys %{$random->{'scalar_disagreements'}}) {
		my $record = $random->{'scalar_disagreements'}{$key};
		print "  - $record->{'value'}: the rule says $record->{'rule'}; $key\n";
	}

	my $reference_count = scalar keys %{$random->{'reference_disagreements'}};
	print "- Reference disagreements: $reference_count distinct verdict patterns.\n";
	my $shown = 0;
	for my $key (sort keys %{$random->{'reference_disagreements'}}) {
		last if $shown++ >= 6;
		my $record = $random->{'reference_disagreements'}{$key};
		print "  - e.g. $record->{'value'}: the rule says $record->{'rule'}; $key\n";
	}

	my $split_count = scalar(keys %{$random->{'sibling_splits'}});
	print "- Inter-sibling splits: $split_count distinct verdict patterns.\n";
	for my $key (sort keys %{$random->{'sibling_splits'}}) {
		print "  - $key\n";
	}

	my $error_count = scalar(keys %{$random->{'errors'}});
	print "- Unclassified errors: $error_count.\n";
	for my $key (sort keys %{$random->{'errors'}}) {
		print "  - $key\n";
	}

	$summary{'random'} = {
		values => {
			total      => $random->{'iterations'},
			scalars    => $random->{'scalars'},
			references => $random->{'references'},
			undefs     => $random->{'undefs'},
		},
		scalar_disagreements    => $scalar_count,
		reference_disagreements => $reference_count,
		sibling_splits          => $split_count,
		errors                  => $error_count,
	};

	# The gate.  A pattern recorded by the randomised run is always a disagreement
	# with the rule: the siblings can only split among themselves after one of them
	# has left the rule, so every recorded pattern carries a sibling that does not
	# answer what the rule answers.  References are included on the same terms as
	# anything else the rule decides on.
	my @curated_found = violations();
	my @generated;
	for my $bucket (qw(scalar_disagreements reference_disagreements)) {
		my $kind = $bucket =~ /\Ascalar/ ? 'scalar' : 'reference';
		for my $key (sort keys %{$random->{$bucket}}) {
			my $record = $random->{$bucket}{$key};
			push @generated, {
				kind    => 'generated',
				bucket  => $kind,
				value   => $record->{'value'},
				pattern => $key,
				rule    => $record->{'rule'},
			};
		}
	}
	$summary{'random'}{'disagreements'} = \@generated;

	# A record and the line it renders to, in the same order, so the count the
	# report prints and the count the summary carries are the same number.
	my @found = (@curated_found, @generated);
	my @violations = map { violation_text($_) } @found;

	print "\n### Gate\n\n";
	my $count = scalar @found;
	my $verdict = $count ? ($check ? 'FAIL' : 'REPORT') : 'PASS';

	if($count) {
		# The label is built before it is printed: a print() in a comma list puts
		# everything after it in void context, which is a warning and no output.
		my $label = $check ? '- FAIL: ' : '- REPORT: ';
		print $label, $count,
			" disagreement(s) with Geo::Location::Predicate on a scalar, a reference or undef.\n";
		print "  - $_\n" for @violations;

		if($check) {
			# The report goes to the job summary; this goes to the log.
			print STDERR "FAIL: $count disagreement(s) with Geo::Location::Predicate",
				" on a scalar, a reference or undef:\n";
			print STDERR "  - $_\n" for @violations;
		} else {
			print "  This run asked for a report, so its exit status is 0 and it cannot be\n",
				"  used as a gate: without --report a disagreement fails the run.\n";
		}
	} else {
		my $scope = @SIBLINGS == @ALL_SIBLINGS ? 'every sibling' : 'every sibling under test';
		print "- PASS: $scope answers what the rule answers on every value.\n";
		print STDERR "Ok: $scope answers what the rule answers on every value.\n";
	}

	$summary{'gate'} = {
		verdict    => $verdict,
		count      => $count,
		counts     => {
			curated   => scalar @curated_found,
			generated => scalar @generated,
		},
		violations => \@found,
	};
	write_summary(\%summary) if defined($summary_file);

	return $verdict eq 'FAIL' ? 1 : 0;
}

# ---------------------------------------------------------------------------
# Writing the report back into the document that quotes it
# ---------------------------------------------------------------------------

# The document quotes the report from its own heading to the end of the file, or
# to the next section if one is added after it: everything the run prints is
# Markdown, so the sample's headings are the document's headings too.  This
# replaces exactly that span and leaves the prose before it alone.  It writes
# through a second file, so a failure part-way leaves the document as it was
# rather than half-written, and says whether it changed anything.
sub regenerate
{
	my ($document, $printed) = @_;

	open(my $in, '<', $document) or die "Cannot read $document: $!\n";
	my $old = do { local $/; <$in> };
	close($in) or die "Cannot close $document: $!\n";

	# The heading is in the report, not a marker of the document's own: the sample
	# starts where a run starts, which is also why the end is a heading of the
	# document rather than a line of the report.
	my $heading = '## Harness output';
	my $at = index($old, "\n$heading\n");
	die "Cannot find a '$heading' section in $document: the sample is written from\n"
		. "the heading the harness prints, so that heading has to be there\n"
		unless $at >= 0;
	$at++;

	my $rest = substr($old, $at + length($heading) + 1);
	my $end = index($rest, "\n## ");
	my $after = $end >= 0 ? substr($rest, $end) : '';

	my $new = substr($old, 0, $at) . $printed . $after;
	return 0 if $new eq $old;

	my $temp = "$document.new";
	open(my $out, '>', $temp) or die "Cannot write $temp: $!\n";
	print {$out} $new or die "Cannot write $temp: $!\n";
	close($out) or die "Cannot close $temp: $!\n";
	rename($temp, $document) or die "Cannot rename $temp to $document: $!\n";

	return 1;
}

sub main
{
	return report() unless defined($document);

	# The report is captured rather than printed as it is made, so it can be
	# written into the document before it is printed.  It is the default handle
	# that is redirected, which is where report() writes; stderr is left alone, so
	# the gate's log line still reaches the caller.  Stdout is the report in either
	# mode, so a caller that pipes this still gets what it asked for.
	my $captured = '';
	open(my $buffer, '>', \$captured) or die "Cannot capture the report: $!\n";
	my $saved = select($buffer);
	my $status = report();
	select($saved);
	close($buffer) or die "Cannot close the captured report: $!\n";

	# A failing run is not what the document quotes: writing it would leave the
	# sample claiming a verdict the next run does not repeat, and the sample is
	# compared against a run that has to pass first.
	if($status) {
		print STDERR "$document was not updated: the run failed\n";
	} elsif(regenerate($document, $captured)) {
		print STDERR "Wrote the sample report into $document\n";
	} else {
		print STDERR "$document already contains this report\n";
	}

	print $captured;

	return $status;
}

# A probing caller can load this file and use the pieces above.
exit(main()) unless $ENV{'FUZZ_NO_RUN'};
