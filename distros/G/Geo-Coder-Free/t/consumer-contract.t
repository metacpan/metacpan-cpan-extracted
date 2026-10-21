#!perl -w

# Reader/producer contract for the Geo::Location::Point objects that
# Geo::Coder::Free hands back.
#
# The three checks run by Test::Consumer::Contract, which this file declares:
#
# PART 1  every key this test claims a producer sets is checked against the
#         source that is supposed to set it, so a backend that quietly stops
#         stamping (say) 'database' fails here.
# PART 2  every registered consumer of a Geo::Coder::Free result may only read
#         the keys that *every* backend guarantees.  Reading a key that only
#         some backends set is the bug this test exists for: the value is undef
#         for the other backends and the caller silently takes a wrong branch.
# PART 3  discovery: a file that can receive a Geo::Coder::Free result but is
#         not registered is a failure, so a new consumer cannot slip past
#         PART 2 unnoticed.
# PART 4  the accessor lists above are checked against Geo::Location::Point
#         itself, in both directions: every name listed is a documented accessor
#         of it, and every accessor it documents is listed in 'accessors',
#         'not_accessors' or 'conditional'.  The second direction is what stops
#         the value object and this declaration drifting apart - add an accessor
#         to Geo::Location::Point and this test fails until the contract says
#         which kind of accessor it is.
#
# Parts 2 and 3 need the sibling checkouts (HTML-Genealogy-Map and friends) that
# share this workspace; they are skipped, with a diagnostic, when this dist is
# installed on its own.  There the checker itself is missing too, so the whole
# file skips rather than failing the install.
#
# A skip is wrong where the checkouts were put there on purpose.  CI assembles
# the workspace and sets CONTRACT_STRICT, which turns a missing checker or a
# missing checkout into a failure: a job meant to check the contract must not go
# green having checked nothing.  See .github/workflows/contract.yml and
# t/contract-strict.t.
#
# How the checks work, and what they can and cannot see, is documented in
# Test-Consumer-Contract/lib/Test/Consumer/Contract.pm.

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
# Under prove -t (taint mode), $Bin is tainted; detaint before use lib.
use lib (do {
	(my $d = $Bin) =~ /\A(.*)\z/s;
	"$1/../../Test-Consumer-Contract/lib";
});

use Test::Most;
use Test::Needs;

# The oldest checker this declaration can be run with: before 0.04 a workspace
# producer was read even when its sibling was not checked out, so outside a
# workspace check 1 failed on Geo-Location-Point/lib/Geo/Location/Point.pm
# while parts 2 and 3 skipped.
my $CHECKER_VERSION = '0.04';

# The declaration
# ---------------------------------------------------------------------------

sub _declaration
{
	return (
	source => 'Geo::Coder::Free',

	# The calls that hand a Geo::Coder::Free result back, named here rather than
	# defaulted inside the checker: the checker is not a geocoder checker, and
	# geocode_many() is the batch spelling of geocode() - a producing call that
	# hands back a hash of results rather than one.
	methods       => [qw(geocode reverse_geocode geocode_many)],
	batch_methods => [qw(geocode_many)],

	# Read the value object from the checkout in this workspace rather than an
	# installed copy: the contract below is about the code in this tree.
	include => ['Geo-Location-Point/lib'],

	# Set on every result, whichever backend answered.  'lat', 'long' and 'lng'
	# come from Geo::Location::Point::new() (long/lng are synonyms).  The other
	# four are the provenance keys of section 2.1 of BI-Phase6-Dependency-Specs.md,
	# which every construction site in every backend now sets: 'database' names
	# the backend, 'geocoder' the distribution, and 'confidence' and 'accuracy'
	# say how good the match was and how precise the coordinate is.  The
	# distribution string itself is defined once, in Geo::Coder::Free::Provenance.
	guaranteed => [qw(lat long lng database geocoder confidence accuracy)],

	# Set by some backends or only by some paths through a backend.  A consumer
	# may not read these off a result - it can be undef for another backend -
	# unless it registers the reason in 'consumers' below.
	conditional => {
		location => 'OpenAddresses and Local set it; the MaxMind cities path does not',
		text     => 'only the scantext path sets it',
		lon      => "only MaxMind's %known_locations shortcut sets it - Point::new() makes long and lng, never lon",
		# The three attribute accessors of Geo::Location::Point that only some
		# results have anything behind: the backing row decides.  They are
		# documented accessors, so the value object check below needs them
		# accounted for, and naming them here rather than in 'accessors' keeps a
		# read of one an offence unless it is registered - the same rule the
		# hash-key spelling is held to.
		country  => 'set only when the backing database row has one - OpenAddresses sets none of country, city or state',
		city     => 'set only when the backing database row has one',
		state    => 'set only when the backing database row has one',
	},

	# PART 1: file => keys the file is responsible for setting, with the evidence
	# checked by the test.  The latitude/longitude that become lat/long/lng
	# arrive differently in each backend (OpenAddresses passes them as literals,
	# MaxMind and Local splat in a database row), so only the explicit keys are
	# listed here.
	producers => {
		'lib/Geo/Coder/Free/OpenAddresses.pm' => [qw(lat long lng location database geocoder confidence accuracy)],
		'lib/Geo/Coder/Free/MaxMind.pm'       => [qw(database confidence lon geocoder accuracy)],
		'lib/Geo/Coder/Free/Local.pm'         => [qw(location confidence database geocoder accuracy)],
		'lib/Geo/Coder/Free.pm'               => [qw(location text confidence)],
	},

	# The value object is in a sibling distribution, but it makes three of the
	# guaranteed keys, so its evidence is checked here too.
	workspace_producers => {
		'Geo-Location-Point/lib/Geo/Location/Point.pm' => [qw(lat long lng)],
	},

	# The spellings the value object promises to derive lat, long and lng from.
	value_object => {
		class   => 'Geo::Location::Point',
		from    => { latitude => 10, longitude => 20 },
		derives => { lat => 10, long => 20, lng => 20 },
	},

	# PART 2: files that can be handed a Geo::Coder::Free result.  'may_rely_on'
	# names the keys the file reads beyond 'guaranteed', each with the reason it
	# is safe; a read that is not listed there fails the test, and an entry that
	# is no longer read is reported as stale.
	#
	# Discovered by scanning the workspace for files that both mention
	# Geo::Coder::Free and bind a variable from a geocode() call - see PART 3,
	# which fails if a new one appears and is not registered here or in
	# 'ignored'.
	consumers => {
		# The program at the root of the same distribution: ged2map holds its own
		# copy of the geocoding loop, and a program with no extension is as much a
		# consumer as the module beside it.  It reads the position through the
		# same adapter, so the one registered read is the same one.
		'HTML-Genealogy-Map/ged2map' => {
			'may_rely_on' => {
				'_coordinates' => {
					'lon' => 'the third fallback, after {long} and {lng}, for the geocoders that'
						. ' spell longitude that way. Never the only evidence of a position, and'
						. ' never used to test whether a lookup succeeded',
				},
			},
		},

		# Database::BI resolves a place column through a geocode_many() batch: a
		# variable bound from the batch is not itself a result, but a value taken
		# out of it is, and _coordinates() is where those values are read.
		'Database-BI/lib/Database/BI/Model/Geocode.pm' => {
			'may_rely_on' => {
				'_coordinates' => {
					'lon' => 'the third fallback, after {long} and {lng}, for the geocoders that'
						. ' spell longitude that way. Never the only evidence of a position, and'
						. ' never used to test whether a lookup succeeded',
				},
			},
		},

		'HTML-Genealogy-Map/lib/HTML/Genealogy/Map.pm' => {
			# The geocoder is injected (->onload_render(geocoder => ...)), and
			# HTML-Genealogy-Map's own POD and tests pass Geo::Coder::Free, so a
			# result here is a Geo::Location::Point, or a plain hash from some
			# other geocoder.  _coordinates() reads the position, _is_local()
			# reads the provenance.
			# Keyed by sub, not just by key: an exception covers the read inside
			# the adapter it was reviewed for, and the same key read anywhere else
			# in the file is still an offence.  A helper outside the adapters that
			# reads an unset key cannot hide behind one of these entries.
			#
			# _is_local() used to need one for {geocoder}: nothing set that key,
			# so the read was an exception.  Now that every backend stamps it,
			# the read is a guaranteed one and the entry has gone - which is what
			# section 2.1 of BI-Phase6-Dependency-Specs.md was for.
			'may_rely_on' => {
				'_coordinates' => {
					'lon' => "the third fallback, after {long} and {lng}, for the geocoders that"
						. ' spell longitude that way. Never the only evidence of a position, and'
						. ' never used to test whether a lookup succeeded',
				},
			},
		},

		# HTML::OSM takes a geocoder object and never names Geo::Coder::Free, so
		# the scanner cannot discover this file however it is written - the
		# registration here is the only thing that gets its reads checked.  It
		# accepts any object with geocode(), so what it is handed is a
		# Geo::Location::Point when HTML-Genealogy-Map and friends pass one, and
		# _fetch_coordinates() is where that result is read: the accessors first,
		# then the plain-hash shapes the other geocoders return.
		'HTML-OSM/lib/HTML/OSM.pm' => {
			'may_rely_on' => {
				'_fetch_coordinates' => {
					'lon' => 'read only on the plain-hash path, inside the test that both'
						. ' {lat} and {lon} are defined; a Geo::Location::Point has taken the'
						. ' latitude()/longitude() branch above it, so this is for the geocoders'
						. ' that spell longitude that way and never the promise of a result',
					'geometry' => 'the Nominatim response shape, geometry.location.lat/lng,'
						. ' read only after the flat {lat}/{lon} test has failed. It is the'
						. ' fallback for a plain HTTP hash, not a field of a Geo::Coder::Free'
						. ' result, which is an object and never reaches this branch',
				},
			},
		},
	},

	# Files that match the discovery rule but are not consumers of a raw
	# Geo::Coder::Free result.  Keyed by path prefix, with the reason it is safe.
	ignored => [
		[
			'Geo-Coder-List/lib/Geo/Coder/List.pm',
			"normalises what it is given rather than passing it on.  It stamps"
			. ' geocoder itself, fills geometry.location.{lat,lng} and the lat/lng/lon'
			. ' aliases itself, so a caller of Geo::Coder::List reads its own shape,'
			. ' not the promise of the backend that answered. The result it copies'
			. ' those fields from arrives in @rc - an array the scanner does not'
			. ' follow - so there is no read here for the contract to check, and this'
			. ' entry is the recorded reason rather than a substitute for a check'
		],
		[
			'Geo-Coder-List/t/',
			"the aggregator's own tests, which hand it a Geo::Coder::Free backend"
			. ' and then read what Geo::Coder::List publishes - its'
			. ' geometry.location.{lat,lng} and the geocoder it stamps on the result'
			. ' - rather than a backend result of their own'
		],
		[
			'Config-Abstraction/',
			'names Geo::Coder::Free as a configuration value; it never reads a result'
		],
		[
			'NJH-Snippets/',
			'optional chaining in a helper; reads no result key'
		],
		[
			'Test-Consumer-Contract/',
			"the checker's own end-to-end tests hold fixture source in strings; the"
			. ' file itself runs no geocoder'
		],
	],

	# Documented accessors of Geo::Location::Point that a consumer may read a
	# result through: the position, the derived strings and comparisons, the
	# AUTOLOAD-documented 'attr', and the four provenance keys of section 2.1 of
	# BI-Phase6-Dependency-Specs.md - geocoder, database, confidence and accuracy
	# are guaranteed keys as well, and the accessors are how HTML-Genealogy-Map
	# and friends read them without reaching for a hash key.
	accessors => [qw(lat latitude long lng longitude distance equal not_equal
		tz timezone as_string as_uri attr geocoder database confidence accuracy)],

	# Documented too, but not a slot of one result, so a consumer never reads a
	# result through these.  The value object check fails if Geo::Location::Point
	# documents an accessor that is in none of these three lists, which is how the
	# four provenance accessors above were found to be missing from it: the value
	# object grew them and this declaration was not told.
	not_accessors => {
		new             => 'the constructor, not a slot of one result',
		AUTOLOAD        => 'the attribute mechanism; the documented face of it is attr()',
		ACCURACY_LEVELS => 'a class constant, the levels accuracy() accepts',
		accuracy_for    => 'a class function, the level a set of matched fields justifies',
	},

	# Class introspection, not result data: asking whether a result can answer
	# latitude() is not the same as reading an attribute off it.
	inspection => [qw(can isa DOES)],

	# The sibling checkouts parts 2 and 3 need.  Naming them is what tells a
	# missing checkout apart from a passing one.  HTML-OSM is here because a
	# consumer that has to be registered by hand still has to be in the
	# workspace: without the checkout, check 2 could not tell 'safe' from 'not
	# looked at'.
	require_workspace => [qw(HTML-Genealogy-Map Geo-Location-Point Database-BI HTML-OSM)],
	);
}

# The directory holding the sibling distributions.
sub _workspace_root
{
	return File::Spec->catdir($Bin, File::Spec->updir(), File::Spec->updir());
}

# The workspace files the declaration above registers, read from this checkout
# rather than from an installed copy.
sub _workspace_file
{
	my $rel = shift;

	return File::Spec->catfile(_workspace_root(), split(m{/}, $rel));
}

# CONTRACT_STRICT is set by the CI job once it has checked the workspace out.
# A checkout it could not find is then a broken job, not an installation
# without a workspace: bail out naming what is missing rather than let parts 2
# and 3 skip and the build report success.
sub _require_workspace
{
	my %declaration = _declaration();
	my @missing = grep { !-d File::Spec->catdir(_workspace_root(), $_) }
		@{$declaration{'require_workspace'} || []};

	return unless @missing;

	BAIL_OUT('CONTRACT_STRICT is set and the workspace has no '
		. join(', ', @missing)
		. ': .github/workflows/contract.yml checks the sibling distributions out,'
		. ' so a job that cannot see them has checked nothing');
}

sub _slurp
{
	my $path = shift;

	open(my $fh, '<', $path) or return;
	local $/;
	my $text = <$fh>;
	close($fh);

	return $text;
}

# Run it
# ---------------------------------------------------------------------------

# Called by its full name: the checker is loaded at run time, so that a
# distribution installed outside this workspace, or with a checker older than
# $CHECKER_VERSION, skips this file instead of failing to compile it.
_need_checker();
_require_workspace() if($ENV{'CONTRACT_STRICT'});

Test::Consumer::Contract::run_consumer_contract(_declaration());

# The two readers the scanner used to walk past, proved against the real
# files rather than the checker's fixtures: ged2map is a program with no
# extension, and Database::BI's reads start from a geocode_many() batch.
#
# What is asserted is that both read results at all, which is what makes
# their registration in _declaration() mean something: a registered consumer
# is read whether or not discovery found it, so a registration for a file the
# scanner cannot see would check nothing.  Which files the scanner walks is
# not asserted here: it is private to the checker (it was not until 0.03, and
# calling it from this distribution then only worked under a harness, where
# Sub::Private bypasses its own check), and the walk itself is proved by the
# checker's t/scanner.t.
subtest 'the two readers the scanner used to miss are read' => sub {
	my $contract = Test::Consumer::Contract->new(_declaration());

	# The same checkouts parts 2 and 3 need: without them there is no file
	# to look for, and this subtest must skip rather than fail.
	plan skip_all => 'the sibling checkouts are not present'
		unless $contract->workspace_present();

	for my $rel (qw(HTML-Genealogy-Map/ged2map Database-BI/lib/Database/BI/Model/Geocode.pm)) {
		my $raw = _slurp(_workspace_file($rel));
		ok(defined($raw), "$rel is readable");

		my @reads = $contract->reads_of_results($contract->strip($raw // ''));
		cmp_ok(scalar(@reads), '>', 0, "$rel yields reads of results")
			or diag(explain(\@reads));
	}

	# The mutation: the checker before 0.02 did not know geocode_many() was
	# a producing method, so neither the batch nor the results taken out of
	# it were followed.  With that behaviour back, the file has no reads to
	# check - which is why its registration is only meaningful now.
	my $batch_file = 'Database-BI/lib/Database/BI/Model/Geocode.pm';
	my $raw = _slurp(_workspace_file($batch_file));
	my $blind = Test::Consumer::Contract->new(_declaration(),
		methods       => [qw(geocode reverse_geocode)],
		batch_methods => ['nothing_matches_this'],
	);
	my @blind = $blind->reads_of_results($blind->strip($raw // ''));
	is(scalar(@blind), 0, "$batch_file is invisible without batch support")
		or diag(explain(\@blind));
};

# A consumer that discovery can never see, and why its registration matters:
# HTML::OSM takes a geocoder object and never names Geo::Coder::Free, so the
# walk in part 3 passes it by however the file is written.  The entry in
# 'consumers' is the only thing that gets its reads checked, so it is
# asserted here rather than left to be noticed if it is deleted.
subtest 'a consumer discovery cannot see is registered by hand' => sub {
	my %declaration = _declaration();
	my $rel = 'HTML-OSM/lib/HTML/OSM.pm';

	my $contract = Test::Consumer::Contract->new(%declaration);
	plan skip_all => 'the sibling checkouts are not present'
		unless $contract->workspace_present();

	ok($declaration{'consumers'}{$rel},
		'HTML::OSM is registered, although the discovery check cannot find it')
		or diag("\tWithout this entry nothing checks what HTML::OSM reads off a result.\n");

	my $raw = _slurp(_workspace_file($rel));
	ok(defined($raw), "$rel is readable");
	unlike($raw, qr/Geo::Coder::Free/,
		'and it never names the distribution, which is why discovery misses it')
		or diag("\tIt names Geo::Coder::Free now, so discovery would find it too.\n");

	my @reads = $contract->reads_of_results($contract->strip($raw // ''));
	ok(scalar(@reads), 'it does read results all the same') or diag(explain(\@reads));

	my %read = map { $_->[0] => 1 } @reads;
	ok($read{'lon'} && $read{'geometry'},
		'including the two reads the declaration records a reason for')
		or diag(explain(\@reads));
};

done_testing();

sub _need_checker
{
	my $error = do {
		local $@;
		eval { require Test::Consumer::Contract; Test::Consumer::Contract->VERSION($CHECKER_VERSION); 1 } ? undef : $@;
	};

	return unless $error;

	# CONTRACT_STRICT says this job exists to run the contract: a checker that
	# cannot be loaded is a broken job, not an installation without it.
	BAIL_OUT("CONTRACT_STRICT is set and Test::Consumer::Contract cannot be loaded: $error")
		if($ENV{'CONTRACT_STRICT'});

	# A workspace that has the checkouts this contract is about, and no checker
	# to check them with, is a broken configuration rather than an installation
	# without the workspace: say so here, loudly, instead of quietly checking
	# nothing.
	my $workspace = File::Spec->catdir($Bin, File::Spec->updir(), File::Spec->updir());
	my @siblings = grep { -d File::Spec->catdir($workspace, $_) }
		qw(HTML-Genealogy-Map Geo-Location-Point);
	BAIL_OUT("Test::Consumer::Contract is missing from a workspace that has "
		. join(', ', @siblings) . ": $error") if(@siblings);

	# Anywhere else a checker that is absent or too old skips the file; one that
	# is installed but does not compile is an error, as Test::Needs has it.
	test_needs({ 'Test::Consumer::Contract' => $CHECKER_VERSION });

	return;
}
