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
#
# Parts 2 and 3 need the sibling checkouts (HTML-Genealogy-Map and friends) that
# share this workspace; they are skipped, with a diagnostic, when this dist is
# installed on its own.  There the checker itself is missing too, so the whole
# file skips rather than failing the install.
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

# The declaration
# ---------------------------------------------------------------------------

sub _declaration
{
	return (
	source => 'Geo::Coder::Free',

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
	},

	# Files that match the discovery rule but are not consumers of a raw
	# Geo::Coder::Free result.  Keyed by path prefix, with the reason it is safe.
	ignored => [
		[
			'Geo-Coder-List/',
			"reads Geo::Coder::List's own normalised output, which sets lon, lng,"
			. ' geometry and geocoder itself and treats lon as an optional alias'
		],
		[
			'Config-Abstraction/',
			'names Geo::Coder::Free as a configuration value; it never reads a result'
		],
		[
			'NJH-Snippets/',
			'optional chaining in a helper; reads no result key'
		],
	],

	# Documented accessors of Geo::Location::Point, plus the AUTOLOAD-documented
	# 'attr'.  A result object is read through these, never through a raw hash key.
	accessors => [qw(lat latitude long lng longitude distance equal not_equal
		tz timezone as_string as_uri attr new)],

	# Class introspection, not result data: asking whether a result can answer
	# latitude() is not the same as reading an attribute off it.
	inspection => [qw(can isa DOES)],

	# The sibling checkouts parts 2 and 3 need.  Naming them is what tells a
	# missing checkout apart from a passing one.
	require_workspace => [qw(HTML-Genealogy-Map Geo-Location-Point)],
	);
}

# Run it
# ---------------------------------------------------------------------------

# Called by its full name: the checker is loaded at run time, so that a
# distribution installed outside this workspace skips this file instead of
# failing to compile it.
if(my $missing = _checker_missing()) {
	plan skip_all => $missing;
} else {
	Test::Consumer::Contract::run_consumer_contract(_declaration());

	done_testing();
}

sub _checker_missing
{
	my $error = do {
		local $@;
		eval { require Test::Consumer::Contract; 1 } ? undef : $@;
	};

	return unless $error;

	# A workspace that has the checkouts this contract is about, and no checker
	# to check them with, is a broken configuration rather than an installation
	# without the workspace: say so here, loudly, instead of quietly checking
	# nothing.
	my $workspace = File::Spec->catdir($Bin, File::Spec->updir(), File::Spec->updir());
	my @siblings = grep { -d File::Spec->catdir($workspace, $_) }
		qw(HTML-Genealogy-Map Geo-Location-Point);
	BAIL_OUT("Test::Consumer::Contract is missing from a workspace that has "
		. join(', ', @siblings) . ": $error") if(@siblings);

	return 'Test::Consumer::Contract is not installed, so the reader/producer contract cannot be checked';
}
