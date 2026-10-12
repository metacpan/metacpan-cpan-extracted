#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# THE FOUR NAMES OBJECT::PROTO INSTALLS ARE EXEMPT, and nothing else is.
#
# `new`, `prototype`, `set_prototype` and the `BUILD`/`DEMOLISH` pair come from
# Object::Proto::Sugar, not from this distribution, and documenting them here
# would be documenting somebody else's module. Every attribute declared with
# `has` is ours and is still checked: an accessor added without an entry in the
# POD fails this test.
#
# BEFORE THIS, all fifteen assertions were red and had been for some time, and
# all fifteen were red for that one reason. A suite that is red for a reason
# nobody intends is a suite nobody reads, and the genuinely undocumented method
# it was hiding (Deck::Card::stringify) had to be found by hand.
my $GENERATED = qr/\A(?:new|prototype|set_prototype|BUILD|DEMOLISH)\z/;

all_pod_coverage_ok({ also_private => [$GENERATED] });
