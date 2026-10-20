#!perl -w

# The accuracy vocabulary - address, street, postcode, locality, city, region,
# country - is written down once, in Geo::Location::Point, which refuses an
# accuracy outside it.  The rule that turns the fields a match was made on into
# one of those levels lives beside it, as
# Geo::Location::Point::accuracy_for(): the levels a point accepts and the
# levels a backend can derive have a single home, so neither can name a level
# the other does not know.
#
# Geo::Coder::Free::Provenance reports a level for every match a backend makes,
# and re-exports the list from Geo::Location::Point rather than keeping a copy
# of its own.  Sharing it is only worth having if something checks that it
# happened, so this test does: the list Provenance speaks is the list Point
# validates against, every level in it is one a point accepts, and every level
# the derivation can produce is one the list publishes.  A level added to one
# module alone fails here, in the distribution that depends on both.
#
# The Point under test is the one in this workspace, not an installed copy.
# Geo::Location::Point is a sibling distribution, and a test that loaded the
# installed one would compare Provenance with a Point released some time ago:
# the drift this file exists to catch - a level added to Point in the checkout,
# or the rule changed there - would stay invisible until both distributions
# were installed, which is the moment it is too late.  The sibling's lib/ is
# therefore put ahead of the installed one, and the module that was actually
# loaded is checked to be the checkout when the checkout exists.  A
# distribution installed on its own, without the sibling, still runs this file
# against whatever Point it has.

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($Bin);
use Scalar::Util qw(refaddr);
use Test::Most;

# The checkout beside this distribution, read the same way t/consumer-contract.t
# reads its workspace files.  Under prove -t, $Bin is tainted; detaint it before
# it reaches use lib.
use lib (do {
	(my $d = $Bin) =~ /\A(.*)\z/s;
	"$1/../../Geo-Location-Point/lib";
});

use Geo::Location::Point;
use Geo::Coder::Free::Provenance qw(ACCURACY_LEVELS);

my $levels = ACCURACY_LEVELS();

# The loading above is only evidence about this tree if it really loaded this
# tree's Point.  The names would agree just as well against an installed copy
# that happens to be the same version today, so which file was read is
# asserted rather than assumed.  Skipped when this distribution is installed on
# its own, where there is no checkout to prefer and the installed Point is the
# only one there is.
SKIP: {
	my $checkout = File::Spec->catfile(
		$Bin, File::Spec->updir(), File::Spec->updir(),
		'Geo-Location-Point', 'lib', 'Geo', 'Location', 'Point.pm',
	);

	skip 'the sibling Geo-Location-Point checkout is not present', 1
		unless -f $checkout;

	my $loaded = $INC{'Geo/Location/Point.pm'};
	is(defined($loaded) ? abs_path($loaded) : undef, abs_path($checkout),
		'Geo::Location::Point was read from the sibling checkout')
		or diag("the vocabulary guard must test this tree, not an installed copy: loaded "
			. ($loaded // 'nothing'));
}

isa_ok($levels, 'ARRAY', 'the vocabulary');
is_deeply($levels, Geo::Location::Point::ACCURACY_LEVELS(),
	'and it holds the levels Geo::Location::Point defines');
is(refaddr($levels), refaddr(Geo::Location::Point::ACCURACY_LEVELS()),
	'as one list, not two copies that agree today')
	or diag('Provenance must read the vocabulary from Geo::Location::Point, not repeat it');

# The rule that chooses a level moved with the vocabulary.  If a copy were
# left behind in Provenance the two could answer differently, which is the
# drift this file exists to catch, so its absence is asserted as well as the
# derivation being the one Geo::Location::Point publishes.
ok(!Geo::Coder::Free::Provenance->can('_accuracy_for'),
	'Provenance keeps no copy of the rule: accuracy_for() lives in Geo::Location::Point');

my %is_level;
my @duplicate = grep { $is_level{$_}++ } @$levels;
is_deeply(\@duplicate, [], 'no level is listed twice') or diag(explain(\@duplicate));

is($levels->[0], 'address', 'the list starts at the most precise level');
is($levels->[-1], 'country', 'and ends at the least precise');

# What a point accepts has to be what the list says: a backend reporting a level
# that Geo::Location::Point would refuse would be describing a point it cannot
# build.
my $point = Geo::Location::Point->new({ latitude => 0.01, longitude => 0.02 });
for my $level (@$levels) {
	# The accessor validates, and croaks on a name it does not know.  A level
	# that the list publishes and the accessor refuses is exactly the drift this
	# test exists to catch, so it is caught here: reported as the level that
	# caused it, and the rest of the file still runs.
	my $accepted = eval { $point->accuracy($level) };
	ok(!$@ && defined($accepted) && $accepted eq $level,
		"Geo::Location::Point accepts '$level'")
		or diag($@ || 'read back as ' . (defined($accepted) ? $accepted : 'undef'));
}
throws_ok { $point->accuracy('street address') } qr/unknown accuracy/,
	'and refuses an accuracy that is not a level';

# And what a backend can derive has to be a level it publishes.  Each field set
# below is one a backend matches on, including the empty set, which is a named
# place.  The derivation is Point's, so a backend adds no vocabulary of its own
# by calling it.
my @field_sets = (
	[ 'house_number' ], [ 'number' ],
	[ 'road' ], [ 'street' ],
	[ 'postcode' ], [ 'post_code' ], [ 'zip' ],
	[ 'city' ], [ 'town' ], [ 'name' ],
	[ 'state' ], [ 'state_district' ], [ 'county' ], [ 'region' ],
	[ 'country' ],
	[],
	[ qw(number road city state country) ],
);
for my $fields (@field_sets) {
	my $level = Geo::Location::Point::accuracy_for(@$fields);
	ok($is_level{$level},
		'accuracy_for(' . join(', ', @$fields) . ") is a level in the vocabulary ($level)");
}

done_testing();
