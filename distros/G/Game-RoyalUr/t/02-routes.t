use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Engine ':all';
my $E = 'Game::RoyalUr::Engine';

sub c {
    my ($name) = @_;
    my ($f, $r) = $name =~ /\A([a-h])([1-3])\z/ or die "not a square: $name";
    return $E->cell_of(ord($f) - ord('a'), $r - 1);
}

sub name {
    my ($cell) = @_;
    return '-' if $cell < 0;
    return chr(ord('a') + $E->file_of($cell)) . ($E->row_of($cell) + 1);
}

# THE FOUR ROUTES, TYPED OUT BY HAND and not computed the way the engine
# computes them. Dark's are light's with rows 1 and 3 exchanged, and they are
# typed too: a mirror that was written wrong once would agree with itself.
#
# The long route was read off two diagrams on 9 Oct 2026, Wikipedia's
# MastersPath.png and the route picture on royalur.net/rules: in at the fourth
# square of the home row, along it to the corner, up the middle row to the
# seventh square, across to the far row, round the end, and off from the
# seventh square of the home row.
my %ROUTE = (
    'short light' => [qw(d1 c1 b1 a1 a2 b2 c2 d2 e2 f2 g2 h2 h1 g1)],
    'short dark'  => [qw(d3 c3 b3 a3 a2 b2 c2 d2 e2 f2 g2 h2 h3 g3)],
    'long light'  => [qw(d1 c1 b1 a1 a2 b2 c2 d2 e2 f2 g2 g3 h3 h2 h1 g1)],
    'long dark'   => [qw(d3 c3 b3 a3 a2 b2 c2 d2 e2 f2 g2 g1 h1 h2 h3 g3)],
);
my %R = (short => ROUTE_SHORT, long => ROUTE_LONG);
my %S = (light => SIDE_LIGHT, dark => SIDE_DARK);

subtest 'how long a route is' => sub {
    is($E->route_len(ROUTE_SHORT), 14, 'the short route has fourteen steps');
    is($E->route_len(ROUTE_LONG),  16, 'the long route has sixteen');
    is($E->route_len(2),  -1, 'route 2 is not a route');
    is($E->route_len(-1), -1, 'nor is route -1');
    is(scalar @{ $ROUTE{'short light'} }, 14, 'and the lists in this file are as long');
    is(scalar @{ $ROUTE{'long dark'} },   16, 'both of them');
};

subtest 'every step of every route is the square written here' => sub {
    for my $key (sort keys %ROUTE) {
        my ($route, $side) = split ' ', $key;
        my $len = $E->route_len($R{$route});
        my @got = map { name($E->route_cell($R{$route}, $S{$side}, $_)) } 1 .. $len;
        is("@got", "@{ $ROUTE{$key} }", "the $route route for $side");
    }
};

subtest 'a step that is not on the board' => sub {
    for my $route (ROUTE_SHORT, ROUTE_LONG) {
        my $len = $E->route_len($route);
        for my $side (SIDE_LIGHT, SIDE_DARK) {
            is($E->route_cell($route, $side, 0),        -1, "step 0 is the hand (route $route, side $side)");
            is($E->route_cell($route, $side, $len + 1), -1, 'the step after the last is home');
            is($E->route_cell($route, $side, 99),       -1, 'and step 99 is nowhere');
            is($E->route_cell($route, $side, -1),       -1, 'like step -1');
        }
    }
    is($E->route_cell(ROUTE_SHORT, SIDE_LIGHT, 15), -1, 'step 15 of the short route is home, though the long route has one');
    is($E->route_cell(2, SIDE_LIGHT, 1), -1, 'a route that does not exist has no cells');
    is($E->route_cell(ROUTE_SHORT, 2, 1), -1, 'nor has a side that does not');
};

subtest 'route_step undoes route_cell, for both sides' => sub {
    my @bad;
    for my $route (ROUTE_SHORT, ROUTE_LONG) {
        for my $side (SIDE_LIGHT, SIDE_DARK) {
            for my $step (1 .. $E->route_len($route)) {
                my $cell = $E->route_cell($route, $side, $step);
                my $back = $E->route_step($route, $side, $cell);
                push @bad, "route $route side $side step $step came back $back" unless $back == $step;
            }
        }
    }
    is("@bad", '', 'every step of all four');
    is($E->route_step(ROUTE_SHORT, SIDE_LIGHT, -1), 0, 'a number that is not a cell is on no route');
    is($E->route_step(ROUTE_SHORT, SIDE_LIGHT, 20), 0, 'at either end');
    is($E->route_step(2, SIDE_LIGHT, c('d2')), 0, 'and a route that does not exist visits nothing');
};

# THE SAME CELL, A DIFFERENT STEP. This is the subtest the long route exists to
# need: under the short route a shared cell is the same step for both sides,
# and a suite that only played that route would never ask.
subtest 'a cell is a step FOR A SIDE' => sub {
    is($E->route_step(ROUTE_LONG, SIDE_LIGHT, c('g3')), 12, 'g3 is step 12 for light on the long route');
    is($E->route_step(ROUTE_LONG, SIDE_DARK,  c('g3')), 16, 'and step 16 for dark');
    is($E->route_step(ROUTE_LONG, SIDE_LIGHT, c('g1')), 16, 'g1 is step 16 for light');
    is($E->route_step(ROUTE_LONG, SIDE_DARK,  c('g1')), 12, 'and step 12 for dark');
    is($E->route_step(ROUTE_LONG, SIDE_LIGHT, c('h2')), 14, 'h2 is step 14 for both, light');
    is($E->route_step(ROUTE_LONG, SIDE_DARK,  c('h2')), 14, 'and dark');

    is($E->route_step(ROUTE_SHORT, SIDE_LIGHT, c('g3')), 0, 'on the short route light never visits g3');
    is($E->route_step(ROUTE_SHORT, SIDE_DARK,  c('g3')), 14, 'and it is dark step 14');
    is($E->route_step(ROUTE_SHORT, SIDE_DARK,  c('d1')), 0, 'dark never visits d1 on either route');
    is($E->route_step(ROUTE_LONG,  SIDE_DARK,  c('d1')), 0, 'either');

    my @differ = grep {
        my $l = $E->route_step(ROUTE_SHORT, SIDE_LIGHT, $_);
        my $d = $E->route_step(ROUTE_SHORT, SIDE_DARK,  $_);
        $l && $d && $l != $d
    } $E->all_cells;
    is(scalar @differ, 0, 'on the short route no shared cell is two different steps');
};

# WRITTEN OUT, both lists. "The middle row" is the short route's answer and is
# wrong for the long one.
subtest 'the cells both sides visit' => sub {
    my %shared = (
        short => [qw(a2 b2 c2 d2 e2 f2 g2 h2)],
        long  => [qw(g1 h1 a2 b2 c2 d2 e2 f2 g2 h2 g3 h3)],
    );
    for my $route (qw(short long)) {
        my @got = map { name($_) } grep { $E->route_shared($R{$route}, $_) } $E->all_cells;
        is("@{[ sort @got ]}", "@{[ sort @{ $shared{$route} } ]}", "the $route route shares these");
    }
    is(scalar(grep { $E->route_shared(ROUTE_SHORT, $_) } $E->all_cells), 8,  'eight on the short route');
    is(scalar(grep { $E->route_shared(ROUTE_LONG,  $_) } $E->all_cells), 12, 'twelve on the long');
    ok(!$E->route_shared(ROUTE_LONG, c($_)), "$_ is one side's alone on the long route")
        for qw(a1 b1 c1 d1 a3 b3 c3 d3);
    ok(!$E->route_shared(ROUTE_SHORT, -1), 'a number that is not a cell is shared by nobody');
};

subtest 'the rosettes fall where the rule sets say' => sub {
    my %want = (short => '4 8 14', long => '4 8 12 16');
    for my $route (qw(short long)) {
        for my $side (qw(light dark)) {
            my @steps = grep { $E->is_rosette($E->route_cell($R{$route}, $S{$side}, $_)) }
                        1 .. $E->route_len($R{$route});
            is("@steps", $want{$route}, "$route route, $side");
        }
    }
};

subtest 'every cell is on somebody\'s route' => sub {
    for my $route (ROUTE_SHORT, ROUTE_LONG) {
        my @orphan = grep { !$E->route_step($route, SIDE_LIGHT, $_) && !$E->route_step($route, SIDE_DARK, $_) }
                     $E->all_cells;
        is(scalar @orphan, 0, "no cell is left out of route $route");
    }
};

done_testing();
