use Test::Pod::Coverage tests=>5;

# This module has a number of private methods whose names do not begin with
# _.  This is kind of unfortunate, but it's too late now to change things,
# so I will just manually omit them.

pod_coverage_ok(
	"Games::Worms::Base",
	{ also_private => [
		qw/^(?:am_memoized|be_not_undead|be_undead|can_zombie|default_color|die|eat_segment|init|initial_move|is_alive|is_undead|new|eally_die|segments_eaten|try_move|really_die)$/
	], },
	"Games::Worms::Base is covered"
);
pod_coverage_ok(
	"Games::Worms::Beeler",
	{ also_private => [qw/^(?:init|which_way)$/ ] },
	"Games::Worms::Beeler is covered"
);
pod_coverage_ok(
	"Games::Worms::Random",
	{ also_private => [qw/^(?:am_memoized|which_way)$/ ] },
	"Games::Worms::Random is covered"
);
pod_coverage_ok(
	"Games::Worms::Random2",
	{ also_private => [qw/^(?:am_memoized)$/ ] },
	"Games::Worms::Random2 is covered"
);
pod_coverage_ok(
	"Games::Worms",
	{ also_private => [qw/^(?:worms)$/ ] },
	"Games::Worms is covered"
);
