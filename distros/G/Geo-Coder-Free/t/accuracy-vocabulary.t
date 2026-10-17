#!perl -w

# The accuracy vocabulary - address, street, postcode, locality, city, region,
# country - is written down once, in Geo::Location::Point, which refuses an
# accuracy outside it.  Geo::Coder::Free::Provenance reports one of those levels
# for every match a backend makes, and reads the list from Geo::Location::Point
# rather than keeping a copy of its own.
#
# Sharing it is only worth having if something checks that it happened, so this
# test does: the list Provenance speaks is the list Point validates against,
# every level in it is one a point accepts, and every level a backend can derive
# is one in it.  A level added to either module alone fails here, in the
# distribution that depends on both.

use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Test::Most;

use Geo::Location::Point;
use Geo::Coder::Free::Provenance qw(ACCURACY_LEVELS _accuracy_for);

my $levels = ACCURACY_LEVELS();

isa_ok($levels, 'ARRAY', 'the vocabulary');
is_deeply($levels, Geo::Location::Point::ACCURACY_LEVELS(),
	'and it holds the levels Geo::Location::Point defines');
is(refaddr($levels), refaddr(Geo::Location::Point::ACCURACY_LEVELS()),
	'as one list, not two copies that agree today')
	or diag('Provenance must read the vocabulary from Geo::Location::Point, not repeat it');

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

# And what a backend can derive has to be a level.  Each field set below is one
# a backend matches on, including the empty set, which is a named place.
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
	my $level = _accuracy_for(@$fields);
	ok($is_level{$level},
		'_accuracy_for(' . join(', ', @$fields) . ") is a level in the vocabulary ($level)");
}

done_testing();
