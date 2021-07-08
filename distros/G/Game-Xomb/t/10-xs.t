#!perl
#
# XS tests; more are in t/jsf.t or via other tests that indirectly call
# into XS code

use 5.24.0;
use warnings;
use Game::Xomb;
use Test::Most;

plan tests => 27;

my $deeply = \&eq_or_diff;

# bypair
{
    dies_ok { Game::Xomb::bypair sub { }, 'odd' };
    lives_ok { Game::Xomb::bypair sub { 1 } };

    my @ret;
    Game::Xomb::bypair(sub { push @ret, $_[1], $_[0] }, qw/1 pa 2 re 3 ci/);
    $deeply->(\@ret, [qw/pa 1 re 2 ci 3/]);
}

# distance - Pythagorean, with rounding
{
    is Game::Xomb::distance(1, 1, 1, 1), 0;
    # Chebyshev distance will be different for offsets such as these
    is Game::Xomb::distance(0, 0, 4, 4), 6;
}

# extract, relies on jsf.c
{
    Game::Xomb::init_jsf(2020);

    my @gismu = qw(cribe mlatu ratcu);
    is Game::Xomb::extract(\@gismu), 'mlatu';
    $deeply->(\@gismu, [qw/cribe ratcu/]);

    is Game::Xomb::extract(\@gismu), 'ratcu';
    $deeply->(\@gismu, [qw/cribe/]);

    is Game::Xomb::extract(\@gismu), 'cribe';
    $deeply->(\@gismu, []);

    is Game::Xomb::extract(\@gismu), undef;
    $deeply->(\@gismu, []);
}

# linecb - Bresenham, with benefits
{
    my ($steps, @path);

    Game::Xomb::linecb(sub { push @path, [ $_[0], $_[1] ]; $steps = $_[2] },
        1, 1, -3, -3);
    # starting point skipped, should not walk off the level map bounds
    is $steps, 1;
    $deeply->(\@path, [ [ 0, 0 ] ]);

    # Chebyshev distance (a very slow way to calculate this)
    Game::Xomb::linecb(sub { $steps = $_[2] }, 0, 0, 4, 4);
    is $steps, 4;

    # abort of line walk
    Game::Xomb::linecb(sub { $steps = $_[2]; return -1 }, 0, 0, 4, 4);
    is $steps, 1;
}

# pick, relies on jsf.c
{
    Game::Xomb::init_jsf(2020);

    my @gismu = qw(cribe mlatu ratcu);
    is Game::Xomb::pick(\@gismu), 'mlatu';
    is Game::Xomb::pick(\@gismu), 'ratcu';
    is Game::Xomb::pick(\@gismu), 'mlatu';
    is Game::Xomb::pick(\@gismu), 'ratcu';
    is Game::Xomb::pick(\@gismu), 'cribe';
    $deeply->(\@gismu, [qw/cribe mlatu ratcu/]);

    ok !defined Game::Xomb::pick([]);
}

# walkcb - linecb only without stopping (except at map boundaries)
#
# NOTE makes assumptions about MAP_COLS MAP_ROWS which are set both in
# the *.pm and in the *.xs
{
    my ($steps, @path);

    # first point is skipped as does linecb
    Game::Xomb::walkcb(sub { push @path, [ $_[0], $_[1] ]; $steps = $_[2] },
        73, 17, 75, 19);
    is $steps, 4;
    $deeply->(\@path, [ [ 74, 18 ], [ 75, 19 ], [ 76, 20 ], [ 77, 21 ] ]);

    # can abort like linecb
    Game::Xomb::walkcb(sub { $steps = $_[2]; return -1 }, 0, 0, 4, 4);
    is $steps, 1;
}
