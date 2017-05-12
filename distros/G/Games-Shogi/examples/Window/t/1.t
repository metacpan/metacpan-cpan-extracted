# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 66;
BEGIN { use_ok('Window') };

#########################

# {{{ Non-cursor test
{
  my $vp = Window->new(
    viewport => [3,3],
    #corner   => [0,0],
    grid     => [ [qw(L N S G K G S N L)],
                  [qw(_ R _ _ _ _ _ B _)],
                  [qw(P P P P P P P P P)],
                  [qw(_ _ _ _ _ _ _ _ _)],
                  [qw(_ _ _ _ _ _ _ _ _)],
                  [qw(_ _ _ _ _ _ _ _ _)],
                  [qw(p p p p p p p p p)],
                  [qw(_ b _ _ _ _ _ r _)],
                  [qw(L N S G K G S N L)] ] );

  ok($vp->at_top, "Window at top of grid");
  ok($vp->at_left, "Window at left side of grid");
  is_deeply($vp->view,
            [ [qw(L N S)],
              [qw(_ R _)],
              [qw(P P P)] ], "Initial view correct");
  ok($vp->square(0,0) eq 'L', "TL corner ok");
  ok($vp->square(2,0) eq 'S', "TR corner ok");
  ok($vp->square(0,2) eq 'P', "BL corner ok");
  ok($vp->square(2,2) eq 'P', "BR corner ok");
  ok(!defined $vp->left(), "Can't move left");
  ok(!defined $vp->up(), "Can't move up");
  ok($vp->right(), "Moving window right");
  ok($vp->at_top, "Window still at top of grid");
  ok(!$vp->at_left, "Window no longer at left edge of grid");
  ok($vp->square(0,0) eq 'N', "TL corner ok after moving right");
  ok($vp->square(2,2) eq 'P', "BR corner ok after moving right");
  ok(!defined $vp->up(1), "Can't move window up after moving right");
  ok($vp->down(), "Moving window down");
  ok($vp->square(0,0) eq 'R', "TL corner ok after moving down");
  ok($vp->square(2,2) eq '_', "BR corner ok after moving down");
  is_deeply($vp->view,
            [ [qw(R _ _)],
              [qw(P P P)],
              [qw(_ _ _)] ], "View correct after translation");
  ok($vp->left(), "Moving window left");
  ok($vp->square(0,0) eq '_', "TL corner ok after moving left");
  ok($vp->square(2,2) eq '_', "BR corner ok after moving left");
  is_deeply($vp->view,
            [ [qw(_ R _)],
              [qw(P P P)],
              [qw(_ _ _)] ], "View correct after translation");
  ok($vp->up(), "Moving window up");
  ok($vp->square(0,0) eq 'L', "TL corner ok after moving up");
  ok($vp->square(2,2) eq 'P', "BR corner ok after moving up");
  is_deeply($vp->view,
            [ [qw(L N S)],
              [qw(_ R _)],
              [qw(P P P)] ], "View correct after translation");
}
# }}}

# {{{ Cursor test
{
  my $vp = Window->new(
    viewport => [3,3],
    corner   => [0,0],
    cursor   => [0,0],
    grid     => [ [qw(L N S G K G S N L)],
                  [qw(_ R _ _ _ _ _ B _)],
                  [qw(P P P P P P P P P)],
                  [qw(_ _ _ _ _ _ _ _ _)],
                  [qw(_ _ _ _ _ _ _ _ _)],
                  [qw(_ _ _ _ _ _ _ _ _)],
                  [qw(p p p p p p p p p)],
                  [qw(_ b _ _ _ _ _ r _)],
                  [qw(L N S G K G S N L)] ] );

  ok($vp->at_top, "Window at top of grid");
  ok($vp->at_left, "Window at left side of grid");
  is_deeply($vp->view,
            [ [qw(L N S)],
              [qw(_ R _)],
              [qw(P P P)] ], "Initial view correct");
  ok($vp->square(0,0) eq 'L', "TL corner ok");
  ok($vp->square(2,0) eq 'S', "TR corner ok");
  ok($vp->square(0,2) eq 'P', "BL corner ok");
  ok($vp->square(2,2) eq 'P', "BR corner ok");
  ok(!defined $vp->curs_left(), "Can't move left");
  ok(!defined $vp->curs_up(), "Can't move up");
  ok($vp->curs_right(), "Moving cursor right");
  ok($vp->at_top, "Window still at top of grid after cursor move");
  ok($vp->at_left, "Window still at left edge of grid after cursor move");
  ok($vp->curs_right(), "Moving cursor right");
  ok($vp->at_top, "Window still at top of grid after cursor move");
  ok($vp->at_left, "Window still at left edge of grid after cursor move");
  ok($vp->curs_right(), "Moving cursor right");
  ok(!$vp->at_left, "Window no longer at left edge of grid after cursor move");
  ok($vp->square(0,0) eq 'N', "TL corner ok after moving right");
  ok($vp->square(2,2) eq 'P', "BR corner ok after moving right");
  ok(!defined $vp->curs_up(1), "Can't move cursor up after moving right");
  ok($vp->curs_down(), "Moving cursor down");
  ok($vp->curs_down(), "Moving cursor down");
  ok($vp->curs_down(), "Moving cursor down");
  ok($vp->square(0,0) eq 'R', "TL corner ok after moving down");
  ok($vp->square(2,2) eq '_', "BR corner ok after moving down");
  is_deeply($vp->view,
            [ [qw(R _ _)],
              [qw(P P P)],
              [qw(_ _ _)] ], "View correct after translation");
  ok($vp->curs_left(), "Moving cursor left");
  ok($vp->curs_left(), "Moving cursor left");
  ok($vp->curs_left(), "Moving cursor left");
  ok($vp->square(0,0) eq '_', "TL corner ok after moving left");
  ok($vp->square(2,2) eq '_', "BR corner ok after moving left");
  is_deeply($vp->view,
            [ [qw(_ R _)],
              [qw(P P P)],
              [qw(_ _ _)] ], "View correct after translation");
  ok($vp->curs_up(), "Moving cursor up");
  ok($vp->curs_up(), "Moving cursor up");
  ok($vp->curs_up(), "Moving cursor up");
  ok($vp->square(0,0) eq 'L', "TL corner ok after moving up");
  ok($vp->square(2,2) eq 'P', "BR corner ok after moving up");
  is_deeply($vp->view,
            [ [qw(L N S)],
              [qw(_ R _)],
              [qw(P P P)] ], "View correct after translation");
}
# }}}
