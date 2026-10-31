#!perl -w

# The location-predicate fuzz is what makes "the six ask the rule" a fact rather
# than an assertion: it drives each sibling's real geocode() with a user agent
# that dies at the lookup, and compares the verdict with
# Geo::Location::Predicate::_valid_location().  The scheduled CI job runs it,
# and what its exit status does is what this test checks:
#
#   1. the workspace passes - the six answer what the rule answers on every
#      curated class and on randomly generated scalars, references and undef;
#   2. a sibling whose predicate stops refusing a string of digits fails the run,
#      with the sibling, the class and both verdicts named;
#   3. a sibling that accepts a reference fails it as well.  It is the same
#      question as the digits one: the six refuse a reference because the rule
#      does, so a copy that lets one through has left the rule whatever the
#      value stringifies to;
#   4. the gate is what a plain run does: a disagreement fails a run with no
#      flags at all, and only --report (or --no-check) asks for the table while
#      leaving the exit status at 0;
#   5. the rule that is graded is the checkout beside the harness.  A workspace
#      whose rule's file is not there refuses to run rather than compare the six
#      against an installed release, which would answer for a tree that is not
#      the one being changed - and would say the six agree;
#   6. --sibling grades the sibling it names and no other, which is what makes
#      the same question usable as each sibling's own scheduled job: a
#      divergence in one distribution fails the job that would have to fix it,
#      and does not go red in the other five.  A name that is not one of the six
#      is refused rather than quietly grading nobody.
#
# The divergence is planted in a copy of the workspace in a temporary directory,
# never in the checkouts: the harness works out which workspace it is in from the
# path it was loaded from, so a copy of it in the temporary tree fuzzes the
# siblings copied beside it.  The copy is a real file, not a link, because
# following a link back to the real harness would put the real siblings in front
# of the planted one.
#
# There is one copy of the workspace for the whole file rather than one per case.
# Every case is the same copy with one file different - the sibling's guard, or
# the rule's file taken away - so that file is rewritten and the run repeated,
# instead of five eight-checkout copies being built and thrown away.
#
# What each of those runs found is read from the summary the harness writes with
# --summary, not from the report it prints.  The report is Markdown for a reader,
# and a rendering is free to be reworded; a test that matched its prose would fail
# for a change that says the same thing and pass for a change that does not.  So
# the counts, the per-class verdicts and the gate's own verdict are asserted as
# data, and the two places this file does read the report do it to check that the
# rendering and the data agree - a count printed on the gate line is the count the
# summary carries - rather than to find out what happened.
#
# The harness needs all eight checkouts, so this test skips when they are not
# beside each other, like t/location-rule.t does.
#
#   prove -l t/location-predicates.t

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use JSON::PP qw(decode_json);
use Test::Most;

# The six, in the order the harness reports them - its own order, sorted by
# distribution name, so a restricted run and a full one agree on it.
my @ALL_SIBLINGS = qw(
	Geo::Coder::CA
	Geo::Coder::DataScienceToolkit
	Geo::Coder::GeoApify
	Geo::Coder::List
	Geo::Coder::Postcodes
	Geo::Coder::XYZ
);

# The six that ask the rule, and the two distributions that hold it and the
# facade the harness runs from.  The rule has been a distribution of its own
# since 0.48, so it is a checkout beside the others, not a file under Free's lib.
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

# The distributions copied with a divergence planted in them.
my $PATCHED = 'Geo-Coder-XYZ';
my $MODULE  = 'lib/Geo/Coder/XYZ.pm';

# The guard, as each of the six writes it.  The planted source has to contain it
# exactly once, so a sibling that rewrites its guard fails this test rather than
# passing it with the patch silently not applied.
my $GUARD = 'if(!_could_be_a_location($location)) {';

# Each divergence replaces the guard with a test of its own.  They are the two
# shapes the six had before they were changed.
my %DIVERGENCE = (
	'digits' => {
		what   => 'a string of digits is no longer refused: the predicate that of a'
			. ' numeric column read by mistake is gone',
		guard  => 'if(!defined($location) || ref($location)) {',
		fails  => 1,
	},
	'reference' => {
		what   => 'a reference is accepted again, while a string of digits is still'
			. ' refused, so the disagreement is about references only',
		guard  => "if(!defined(\$location) || (!ref(\$location) && \$location !~ /\\D/)) {",
		fails  => 0,
	},
);

# Under prove -t $Bin is tainted; detaint before it reaches a file name.
my $root = do {
	(my $d = File::Spec->catdir($Bin, File::Spec->updir())) =~ /\A(.*)\z/s;
	$1;
};

# The directory holding the sibling distributions.
my $workspace = do {
	(my $d = File::Spec->catdir($root, File::Spec->updir())) =~ /\A(.*)\z/s;
	$1;
};

my $harness = File::Spec->catfile($root, 'scripts', 'location-predicate-fuzz.pl');

# Enough values that every generated class is reached, and few enough that each
# of the runs below is quick: the curated classes are what the gate is proved on.
my $ITERATIONS = 200;

my @absent = grep { !-d File::Spec->catdir($workspace, $_, 'lib') } @DISTS;
plan skip_all => 'the sibling checkouts are not in the workspace: ' . join(', ', @absent)
	if @absent;

BAIL_OUT("$harness is not in the distribution") unless -f $harness;

# ---------------------------------------------------------------------------
# Running the harness
# ---------------------------------------------------------------------------

# Run it as the CI job does, and read back what it said on both streams: the
# report on stdout, the failures on stderr.  -| rather than a shell, so a path
# with a space in it needs no quoting and nothing else is inherited.
sub run_harness
{
	my ($program, $iterations, @flags) = @_;

	my $dir = tempdir(CLEANUP => 1);
	my $echo = File::Spec->catfile($dir, 'stderr.txt');
	my $json = File::Spec->catfile($dir, 'summary.json');

	# The child's stderr is a file of ours rather than this test's, and the
	# file descriptor is the one it inherits, so the gate's own complaints are
	# readable here and do not appear as bare text in the TAP stream.
	open(my $saved, '>&', \*STDERR) or BAIL_OUT("Cannot save stderr: $!");
	open(STDERR, '>', $echo) or BAIL_OUT("Cannot write $echo: $!");

	# --summary is what this file asserts on: the same run as data rather than as
	# Markdown.
	my $pid = open(my $fh, '-|', $^X, $program, '--iterations', $iterations,
		'--summary', $json, @flags);
	BAIL_OUT("Cannot run $program: $!") unless defined($pid);
	my $report = do { local $/; <$fh> };
	close($fh);
	my $status = $? >> 8;

	open(STDERR, '>&', $saved) or BAIL_OUT("Cannot restore stderr: $!");

	open(my $err_fh, '<', $echo) or BAIL_OUT("Cannot read $echo: $!");
	my $errors = do { local $/; <$err_fh> };
	close($err_fh);

	return ($status, $report // '', $errors // '', summary_from($json));
}

# The summary, or undef when the run never got as far as writing one.  A run that
# refuses to start - no rule to grade, a --sibling that is not one of the six -
# has no verdict, and a caller has to be able to say so rather than read the file
# the run before it left behind: every summary is written into a directory of its
# own, so an undef here means this run wrote none.
sub summary_from
{
	my ($file) = @_;

	return undef unless -f $file;

	my $decoded = eval { decode_json(slurp($file)) };
	BAIL_OUT("Cannot read the summary run wrote to $file: $@") if $@;

	return $decoded;
}

# The curated class of that name, as the summary records it: the rule's verdict,
# each sibling's, and whether anyone answered differently.
sub curated_class
{
	my ($summary, $name) = @_;

	my ($class) = grep { $_->{'name'} eq $name } @{$summary->{'curated'}{'classes'}};

	return $class;
}

# Every violation the summary records that has the fields named, so a case can ask
# for the disagreement it planted - this class, this sibling - without knowing how
# the report words it.
sub violations_like
{
	my ($summary, %want) = @_;

	return grep {
		my $violation = $_;
		!grep { ($violation->{$_} // '') ne $want{$_} } keys %want;
	} @{$summary->{'gate'}{'violations'}};
}

# ---------------------------------------------------------------------------
# Building a workspace with a divergence in it
# ---------------------------------------------------------------------------

sub copy_tree
{
	my ($from, $to) = @_;

	find({
		no_chdir => 1,
		wanted   => sub {
			my $target = File::Spec->catfile($to, File::Spec->abs2rel($_, $from));
			if(-d $_) {
				make_path($target) unless -d $target;
			} else {
				copy($_, $target) or BAIL_OUT("Cannot copy $_ to $target: $!");
			}
		},
	}, $from);

	return;
}

sub slurp
{
	my ($file) = @_;

	open(my $in, '<', $file) or BAIL_OUT("Cannot read $file: $!");
	my $text = do { local $/; <$in> };
	close($in) or BAIL_OUT("Cannot close $file: $!");

	return $text;
}

sub spew
{
	my ($file, $text) = @_;

	open(my $out, '>', $file) or BAIL_OUT("Cannot write $file: $!");
	print {$out} $text or BAIL_OUT("Cannot write $file: $!");
	close($out) or BAIL_OUT("Cannot close $file: $!");

	return;
}

# A workspace of copies: the six modules, the rule, and the harness itself.
#
# Geo-Coder-Free is here for its lib/Geo/Coder/Free directory, which is how the
# harness works out which workspace it is in, and for the facade it is run from -
# not for the backends under it or the databases they read.  Those are two
# gigabytes in a checkout, nothing this file loads reads them, and copying them
# was most of the time the suite took and all of the scratch it left behind.
sub build_workspace
{
	my ($dir) = @_;

	for my $dist (@DISTS) {
		next if $dist eq 'Geo-Coder-Free';

		copy_tree(
			File::Spec->catdir($workspace, $dist, 'lib'),
			File::Spec->catdir($dir, $dist, 'lib')
		);
	}

	make_path(File::Spec->catdir($dir, 'Geo-Coder-Free', 'lib', 'Geo', 'Coder', 'Free'));
	copy(File::Spec->catfile($root, 'lib', 'Geo', 'Coder', 'Free.pm'),
		File::Spec->catfile($dir, 'Geo-Coder-Free', 'lib', 'Geo', 'Coder', 'Free.pm'))
		or BAIL_OUT("Cannot copy the Geo::Coder::Free facade: $!");

	my $scripts = File::Spec->catdir($dir, 'scripts');
	make_path($scripts);
	copy($harness, File::Spec->catfile($scripts, 'location-predicate-fuzz.pl'))
		or BAIL_OUT("Cannot copy $harness: $!");

	return File::Spec->catfile($scripts, 'location-predicate-fuzz.pl');
}

# The one copy, and the two files a case changes in it.  Every case is this copy
# with the sibling's guard rewritten, or with the rule's file taken away, so the
# copy is built once and the file put back as it was between cases.
my $scratch = tempdir(CLEANUP => 1);
my $program = build_workspace($scratch);

my $module_file = File::Spec->catfile($scratch, $PATCHED, $MODULE);
my $rule_file   = File::Spec->catfile($scratch, 'Geo-Location-Predicate', 'lib',
	'Geo', 'Location', 'Predicate.pm');

# As copied, so a case that plants a divergence in it starts from the same
# workspace as the case before.
my $pristine_module = slurp($module_file);
my $pristine_rule   = slurp($rule_file);

# The workspace as it was copied: no divergence, and the rule where it belongs.
sub reset_workspace
{
	spew($module_file, $pristine_module);
	spew($rule_file, $pristine_rule);

	return;
}

sub use_divergence
{
	my ($divergence) = @_;

	reset_workspace();

	my $source = $pristine_module;
	my $planted = ($source =~ s/\Q$GUARD\E/$DIVERGENCE{$divergence}{'guard'}/);
	BAIL_OUT("$module_file does not contain the guard this test plants a divergence in,"
		. " so the divergence was not planted:\n\t$GUARD")
		unless $planted == 1;

	spew($module_file, $source);

	return;
}

# ---------------------------------------------------------------------------
# 1. The workspace passes
# ---------------------------------------------------------------------------

my ($status, $report, $errors, $summary) = run_harness($harness, $ITERATIONS, '--check');

is($status, 0, 'the six answer what the rule answers, so the gate passes')
	or diag($errors);
is($summary->{'gate'}{'verdict'}, 'PASS', 'the summary says the gate passed');
is($summary->{'gate'}{'count'}, 0, 'with no disagreement to count');
is_deeply($summary->{'gate'}{'counts'}, { curated => 0, generated => 0 }, 'of either kind');
is_deeply($summary->{'gate'}{'violations'}, [], 'and none listed');
is($summary->{'random'}{'scalar_disagreements'}, 0, 'no scalar or undef disagreed');
is($summary->{'random'}{'reference_disagreements'}, 0, 'and no reference did');
is($summary->{'random'}{'errors'}, 0, 'and nothing went unclassified');
is($summary->{'iterations'}, $ITERATIONS, 'the summary is of the run that was asked for');
is($summary->{'seed'}, 20261017, 'with the default seed, so the run is reproducible');
is($summary->{'check'}, 1, 'and it was a gate, not a report');
is_deeply($summary->{'siblings'}, [@ALL_SIBLINGS], 'with every sibling graded');
is_deeply($summary->{'not_driven'}, [], 'and none left out');
is($summary->{'rule'}{'file'},
	abs_path(File::Spec->catfile($workspace, 'Geo-Location-Predicate', 'lib',
		'Geo', 'Location', 'Predicate.pm')),
	'the rule graded is the checkout beside the harness, not an installed release');
is($summary->{'rule'}{'module'}, 'Geo::Location::Predicate::_valid_location',
	'and it is the rule that was consulted');

# The verdicts: every curated class answered the same way by the rule and by all
# six.  The classes the whole change was about are named, and the rest are only
# required not to disagree.
ok(!(grep { $_->{'disagrees'} } @{$summary->{'curated'}{'classes'}}),
	'no curated class is answered differently by anyone');
is($summary->{'curated'}{'disagreements'}, 0, 'and the summary counts none');

for my $expected (['undef', 'REJECT'], ['empty string', 'REJECT'],
	['digits only', 'REJECT'], ['string with a non-digit', 'ACCEPT']) {
	my ($name, $verdict) = @{$expected};
	my $class = curated_class($summary, $name);
	ok($class, "the summary records the '$name' class");
	is($class->{'predicate'}, $verdict, "the rule says $verdict on '$name'");
	is_deeply([sort keys %{$class->{'siblings'}}], [sort @ALL_SIBLINGS],
		"and all six verdicts are recorded for '$name'");
	ok(!(grep { $_ ne $verdict } values %{$class->{'siblings'}}),
		"every one of the six says $verdict on '$name'");
}

# The report is still the run's rendering and CI still keeps it, so it is checked
# for being there - not for what it says, which the summary has already said.
like($report, qr/^## Harness output$/m,
	'stdout is still the report, which is what the job summary is fed');
like($report, qr/^- PASS: /m, 'and its gate line agrees that it passed');
like($errors, qr/^Ok: /m, 'the run says so on stderr as well, which is what CI keeps');

# ---------------------------------------------------------------------------
# 2. A sibling that stops refusing a string of digits fails the run
# ---------------------------------------------------------------------------

{
	use_divergence('digits');
	my ($patched_status, $patched_report, $patched_errors, $patched)
		= run_harness($program, $ITERATIONS, '--check');

	cmp_ok($patched_status, '!=', 0, 'the gate fails when a sibling stops refusing digits');
	is($patched->{'gate'}{'verdict'}, 'FAIL', 'the summary says the gate failed');

	my $count = $patched->{'gate'}{'count'};
	cmp_ok($count, '>', 0, 'with a count of disagreements');
	is($count, scalar @{$patched->{'gate'}{'violations'}},
		'which is the length of the list it carries');
	is($patched->{'gate'}{'counts'}{'curated'} + $patched->{'gate'}{'counts'}{'generated'},
		$count, 'and the two kinds add up to it');

	my @digit_violations = violations_like($patched,
		kind => 'curated', class => 'digits only', sibling => 'Geo::Coder::XYZ');
	ok(@digit_violations, 'the digits class names the sibling that left the rule');
	ok(!(grep { $_->{'verdict'} ne 'ACCEPT' || $_->{'rule'} ne 'REJECT' } @digit_violations),
		'and every one of them says the sibling accepts what the rule refuses');

	my $class = curated_class($patched, 'digits only');
	is($class->{'predicate'}, 'REJECT', 'the rule still refuses a string of digits');
	is($class->{'siblings'}{'Geo::Coder::XYZ'}, 'ACCEPT',
		'and the copy with the planted guard accepts one');
	is_deeply([grep { $class->{'siblings'}{$_} ne 'REJECT' } @ALL_SIBLINGS],
		['Geo::Coder::XYZ'], 'so it is the only one of the six that has left the rule');
	is($class->{'disagrees'}, 1, 'and the class is recorded as one they disagree on');
	cmp_ok($patched->{'curated'}{'disagreements'}, '>=', 1, 'as at least one class is');

	# The two renderings are of one run, so the number on the gate line is the
	# number the summary carries.
	like($patched_report, qr/^- FAIL: $count disagreement\(s\)/m,
		'the report prints the count the summary carries');
	unlike($patched_report, qr/^- PASS: /m, 'and does not say it passed');
	like($patched_errors, qr/^FAIL: $count disagreement\(s\)/m,
		'the failure is on stderr, where the log keeps it, with the same count');
}

# ---------------------------------------------------------------------------
# 3. A reference disagreement fails the run as well.  A reference is a value the
#    rule decides on like any other, so a sibling that lets one through has left
#    the rule - the gate is not restricted to the scalar question any more.
# ---------------------------------------------------------------------------

{
	use_divergence('reference');
	my ($patched_status, undef, $patched_errors, $patched)
		= run_harness($program, $ITERATIONS, '--check');

	cmp_ok($patched_status, '!=', 0, 'a reference disagreement fails the gate');
	is($patched->{'gate'}{'verdict'}, 'FAIL', 'the summary says the gate failed');
	cmp_ok($patched->{'gate'}{'count'}, '>', 0, 'with disagreements counted');

	my @reference_violations = violations_like($patched,
		kind => 'curated', class => 'unblessed reference', sibling => 'Geo::Coder::XYZ');
	ok(@reference_violations, 'and it names the class and the sibling that accepts one');
	ok(!(grep { $_->{'verdict'} ne 'ACCEPT' || $_->{'rule'} ne 'REJECT' } @reference_violations),
		'with the sibling accepting what the rule refuses');
	cmp_ok($patched->{'random'}{'reference_disagreements'}, '>=', 1,
		'and the generated references are counted with them');
	is($patched->{'random'}{'scalar_disagreements'}, 0,
		'while the scalars and undef still agree');
	like($patched_errors, qr/^FAIL: /m, 'the failure is on stderr, where the log keeps it');

	# --report is still the way to ask for the table without the verdict, and the
	# summary says which of the two the run was rather than saying it in words.
	my ($report_status, undef, undef, $reported)
		= run_harness($program, $ITERATIONS, '--report');

	is($report_status, 0, '--report leaves the exit status at 0 for a reference finding too');
	is($reported->{'gate'}{'verdict'}, 'REPORT', 'and the summary labels it a report');
	is($reported->{'check'}, 0, 'with the gate switched off');
	cmp_ok($reported->{'gate'}{'count'}, '>', 0, 'and the finding still counted');
	ok(violations_like($reported, kind => 'curated', class => 'unblessed reference',
		sibling => 'Geo::Coder::XYZ'), 'and the same disagreement recorded');
}

# ---------------------------------------------------------------------------
# 4. The gate is the default.  A run with no flags is the regression check: a
#    disagreement fails it, and --report is the explicit way to ask for the
#    table with the exit status left alone.
# ---------------------------------------------------------------------------

# The real workspace, with nothing asked for: the default gate has to pass on a
# workspace where the six agree, or it would be a gate nobody could keep green.
{
	my ($plain_status, undef, $plain_errors, $plain)
		= run_harness($harness, $ITERATIONS);

	is($plain_status, 0, 'a run with no flags passes where the six agree');
	is($plain->{'gate'}{'verdict'}, 'PASS', 'and the summary says the six agree');
	is($plain->{'check'}, 1, 'because a plain run is the gate');
	is($plain->{'random'}{'scalar_disagreements'}, 0,
		'with no scalar or undef disagreement');
	like($plain_errors, qr/^Ok: /m, 'and the same on stderr');
}

{
	use_divergence('digits');

	my ($default_status, $default_report, $default_errors, $default)
		= run_harness($program, $ITERATIONS);

	cmp_ok($default_status, '!=', 0,
		'a disagreement fails a run that was not asked to be a gate');
	is($default->{'gate'}{'verdict'}, 'FAIL', 'and the summary says it failed');
	my $count = $default->{'gate'}{'count'};
	cmp_ok($count, '>', 0, 'with the count the report prints');
	like($default_report, qr/^- FAIL: $count disagreement\(s\)/m,
		'which is the same number the report renders');
	like($default_errors, qr/^FAIL: $count disagreement\(s\)/m,
		'and the log is told, as for an explicit --check');

	my ($report_status, $report_report, $report_errors, $reported)
		= run_harness($program, $ITERATIONS, '--report');

	is($report_status, 0, '--report asks for the table and not the verdict');
	is($reported->{'gate'}{'verdict'}, 'REPORT', 'the summary says which of the two it was');
	is($reported->{'check'}, 0, 'with the gate switched off');
	is($reported->{'gate'}{'count'}, $count, 'and the same disagreements counted');
	unlike($report_report, qr/^- FAIL: /m, 'so it does not claim a failure it did not make');
	ok(violations_like($reported, kind => 'curated', class => 'digits only',
		sibling => 'Geo::Coder::XYZ'), 'while still recording the disagreement');
	unlike($report_errors, qr/^FAIL: /m, 'and nothing is written as a failure');

	my ($nocheck_status, undef, undef, $nocheck)
		= run_harness($program, $ITERATIONS, '--no-check');

	is($nocheck_status, 0, '--no-check is the same report-only form');
	is($nocheck->{'gate'}{'verdict'}, 'REPORT', 'and the summary says so the same way');
	is($nocheck->{'check'}, 0, 'with the gate off there too');
}

# ---------------------------------------------------------------------------
# 5. The rule that is graded is the checkout in the workspace.  With the rule's
#    file taken out of the copy - and only that - the run has to refuse rather
#    than compare the six against whatever release is installed.
# ---------------------------------------------------------------------------

{
	reset_workspace();
	unlink($rule_file) or BAIL_OUT("Cannot remove $rule_file: $!");

	my ($absent_status, $absent_report, $absent_errors, $absent)
		= run_harness($program, $ITERATIONS, '--check');

	cmp_ok($absent_status, '!=', 0, 'a workspace without the rule does not pass');
	is($absent, undef, 'and no summary is written: there was no verdict to write');
	like($absent_errors, qr/Predicate\.pm/,
		'and names the rule on stderr, whichever copy it refused to grade');
	unlike($absent_report, qr/^- PASS: /m,
		'so it cannot report the six agreeing with a rule that is not the checkout');
	unlike($absent_report, qr/^### Gate$/m, 'and there is no verdict at all');

	# The copy is shared with the case after this one, which needs the rule back.
	spew($rule_file, $pristine_rule);
}

# ---------------------------------------------------------------------------
# 6. --sibling grades only the sibling it names.  That is what puts this fuzz in
#    each of the six's own pipeline: a divergence fails in the distribution that
#    would have to fix it, and does not fail in the other five, which do not ship
#    it.  The workspace the divergence is planted in is the same one as above.
# ---------------------------------------------------------------------------

{
	use_divergence('digits');	# Geo::Coder::XYZ no longer refuses digits

	my ($other_status, undef, $other_errors, $other)
		= run_harness($program, $ITERATIONS, '--check', '--sibling', 'Geo::Coder::CA');

	is($other_status, 0, "another sibling's divergence does not fail a run that names only CA")
		or diag($other_errors);
	is($other->{'gate'}{'verdict'}, 'PASS', 'the gate passes');
	is_deeply($other->{'siblings'}, ['Geo::Coder::CA'],
		'the summary says which sibling was graded');
	is_deeply($other->{'not_driven'}, [grep { $_ ne 'Geo::Coder::CA' } @ALL_SIBLINGS],
		'and which five were left out');
	is_deeply([sort keys %{$other->{'curated'}{'classes'}[0]{'siblings'}}], ['Geo::Coder::CA'],
		'so the verdicts it records are about that one sibling and no other');

	# The same workspace, naming the sibling that drifted: this is the run that a
	# job in its own repository makes.
	my ($own_status, undef, $own_errors, $own)
		= run_harness($program, $ITERATIONS, '--check', '--sibling', 'Geo-Coder-XYZ');

	cmp_ok($own_status, '!=', 0, 'the same divergence fails the job that names XYZ');
	is($own->{'gate'}{'verdict'}, 'FAIL', 'and the summary says the gate failed');
	ok(violations_like($own, kind => 'curated', class => 'digits only',
		sibling => 'Geo::Coder::XYZ'), 'with the class and the sibling recorded');
	is_deeply($own->{'siblings'}, ['Geo::Coder::XYZ'], 'and graded XYZ alone');
	like($own_errors, qr/^FAIL: /m, 'with the failure on stderr');

	# The distribution name is what the job's own checkout is called, so it selects
	# the same sibling as the module name.
	my ($named_status, undef, undef, $named)
		= run_harness($program, $ITERATIONS, '--check', '--sibling', 'Geo-Coder-XYZ');

	cmp_ok($named_status, '!=', 0, 'the distribution name selects the same sibling');
	is_deeply($named->{'siblings'}, $own->{'siblings'},
		'and the summary grades the same one either way');

	# And the run with a divergence in a sibling nobody named is the run these
	# jobs make on a green day: the default gate, over one column.
	my ($green_status, undef, undef, $green)
		= run_harness($harness, $ITERATIONS, '--sibling', 'Geo::Coder::DataScienceToolkit');

	is($green_status, 0, 'a single sibling that agrees passes a run with no flags');
	is($green->{'gate'}{'verdict'}, 'PASS',
		'and the summary says every sibling under test agrees');
	is_deeply($green->{'siblings'}, ['Geo::Coder::DataScienceToolkit'],
		'with the verdict said to be about that sibling, not about all six');
}

{
	my ($status, $report, $errors, $summary)
		= run_harness($harness, $ITERATIONS, '--sibling', 'Geo::Coder::Nowhere');

	cmp_ok($status, '!=', 0, 'a name that is not one of the six fails the run');
	is($summary, undef, 'and no summary is written, so nothing reads as a verdict');
	like($errors, qr/--sibling does not name one of the six: 'Geo::Coder::Nowhere'/,
		'and says which name it did not recognise');
	unlike($report, qr/^### Gate$/m, 'rather than reporting a verdict about nobody');
}

done_testing();
