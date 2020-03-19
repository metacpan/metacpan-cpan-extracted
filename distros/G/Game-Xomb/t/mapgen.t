#!perl
#
# is the map (and player) generation doing sane things?
#
# expensive check for things that should not be:
#
#   AUTHOR_TEST_JMATES=1 prove t/mapgen.t
#
# look at stats for level 5 a bunch of times:
#
#   XOMB_MAPGEN_MINLVL=5 XOMB_MAPGEN_TRIALS=100 prove t/mapgen.t
#
# or only level 3 with the amulet in hand:
#
#   XOMB_AMULET=1 XOMB_MAPGEN_MINLVL=3 XOMB_MAPGEN_MAXLVL=3 \
#     XOMB_MAPGEN_TRIALS=100 prove t/mapgen.t
#
# setting both XOMB_MAPGEN_TRIALS and AUTHOR_TEST_JMATES=1 is probably
# no bueno

use 5.24.0;
use warnings;
use Data::Dumper;
use Game::Xomb;
use Statistics::Lite qw(statshash);
use Test::Most;

my $trials = $ENV{XOMB_MAPGEN_TRIALS} || 1;
BAIL_OUT("trials must be positive") if $trials < 1;

my $minlvl = Game::Xomb::between(1, 5, $ENV{XOMB_MAPGEN_MINLVL} || 1);
my $maxlvl = Game::Xomb::between(1, 5, $ENV{XOMB_MAPGEN_MAXLVL} || 5);
BAIL_OUT("maxlvl must be >= minlvl") if $maxlvl < $minlvl;

Game::Xomb::init_jsf(int rand 2**32);

# do they have the amulet?
{
    no warnings 'redefine';
    if ($ENV{XOMB_AMULET}) {
        *Game::Xomb::has_amulet = sub { 1 }
    } else {
        *Game::Xomb::has_amulet = sub { 0 }
    }
}

my $deeply = \&eq_or_diff;

ok @Game::Xomb::LMap == 0;
Game::Xomb::init_map;
$deeply->($Game::Xomb::LMap[1][1][Game::Xomb::WHERE], [ 1, 1 ]);

my ($col, $row) = Game::Xomb::make_player;

is $Game::Xomb::LMap[$row][$col][Game::Xomb::ANIMAL][Game::Xomb::SPECIES],
  Game::Xomb::HERO;

# how often is something good (gate, gem) being camped?
my @camping;

# how many seeds is the level gen using up? (too few available is really
# bad, too many is less efficient but will better allow one to find a
# close point to some other point...)
my @seeds;

my @GGV;

for my $level ($minlvl .. $maxlvl) {
    $Game::Xomb::Level = $level;
    for (1 .. $trials) {
        my ($ammie, $gemcount, $gemvalue, $left, $camps) = Game::Xomb::generate_map;
        # amulet only generated on levels 4 and 5 and only if player
        # does not already have it
        is $ammie, ($level > 3 and !$ENV{XOMB_AMULET}) ? 1 : 0;
        push @camping, $camps;
        push @seeds,   $left;
        push @GGV,     $gemvalue;
        audit_map() if $ENV{AUTHOR_TEST_JMATES};
    }
}

report('camping',        \@camping);
report('free map seeds', \@seeds);
report('GGV',            \@GGV);

done_testing;

sub audit_map {
    my $anicount = 0;
    for my $r (0 .. Game::Xomb::MAP_ROWS - 1) {
        for my $c (0 .. Game::Xomb::MAP_COLS - 1) {
            ok defined $Game::Xomb::LMap[$r][$c][Game::Xomb::MINERAL]
              or diag Dumper $Game::Xomb::LMap[$r][$c];
            ok( !defined $Game::Xomb::LMap[$r][$c][Game::Xomb::VEGGIE]
                  or $Game::Xomb::LMap[$r][$c][Game::Xomb::VEGGIE]->@*
            ) or diag Dumper $Game::Xomb::LMap[$r][$c];
            my $ani = $Game::Xomb::LMap[$r][$c][Game::Xomb::ANIMAL];
            ok(!defined $ani or $ani->@*) or diag Dumper $Game::Xomb::LMap[$r][$c];
            $anicount++ if defined $ani;
        }
    }
    ok scalar @Game::Xomb::Animates == $anicount
      or diag "Animates "
      . scalar @Game::Xomb::Animates
      . " but found in map $anicount";
}

sub report {
    my ($prefix, $values) = @_;
    my %stats = statshash $values->@*;
    diag $prefix . sprintf " %.2f sd %.2f min,max %d,%d",
      map { $stats{$_} } qw/mean stddev min max/;
}
