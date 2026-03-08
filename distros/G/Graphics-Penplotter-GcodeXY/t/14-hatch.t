#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use POSIX qw( floor );

# ---------------------------------------------------------------------------
# 17-hatch.t  --  Tests for Graphics::Penplotter::GcodeXY::Hatch
#
# Tests are grouped into:
#   1.  Module availability and composed methods
#   2.  Default attribute values
#   3.  sethatchsep API
#   4.  sethatchangle API
#   5.  strokefill behaviour
#   6.  _get_bbox helper
#   7.  Horizontal hatch geometry  (angle = 0)
#   8.  Vertical hatch geometry    (angle = 90)
#   9.  Diagonal hatch geometry    (angle = 45)
#  10.  Arbitrary-angle geometry   (angle = 30)
#  11.  hatchsep controls line density
#  12.  Hatch segments lie inside the shape
#  13.  Graphics state preservation
#  14.  psegments unchanged by non-zero angle
#  15.  Angle equivalence (0==180, 90==270)
#  16.  Constructor attribute injection
# ---------------------------------------------------------------------------

BEGIN {
    eval { require Graphics::Penplotter::GcodeXY; 1 }
        or plan( skip_all => 'Graphics::Penplotter::GcodeXY not available' );
}
use Graphics::Penplotter::GcodeXY;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Create a GcodeXY object with sensible defaults for hatch testing.
# hatchsep=0.25in gives a predictable but not excessive number of lines.
sub new_g {
    my (%extra) = @_;
    return Graphics::Penplotter::GcodeXY->new(
        xsize    => 10,
        ysize    => 10,
        units    => 'in',
        optimize => 0,
        hatchsep => 0.25,
        %extra,
    );
}

# Toleranced float comparison.
sub near { abs( $_[0] - $_[1] ) < 1e-8 }

# Draw a closed square (x0,y0)-(x1,y1) in USER coordinates.
# Defaults to the standard test square (2,2)-(4,4).
sub draw_square {
    my ( $g, $x0, $y0, $x1, $y1 ) = @_;
    $x0 //= 2;  $y0 //= 2;
    $x1 //= 4;  $y1 //= 4;
    $g->polygon( $x0, $y0,  $x1, $y0,  $x1, $y1,  $x0, $y1,  $x0, $y0 );
}

# Return the hatch 'l' (draw) segments from hsegments.
# These are populated by _dohatching and cleared only by newpath.
sub hatch_lines {
    my ($g) = @_;
    return grep { $_->{key} eq 'l' } @{ $g->{hsegments} };
}

# Return the hatch 'm' (travel) segments from hsegments.
sub hatch_travels {
    my ($g) = @_;
    return grep { $_->{key} eq 'm' } @{ $g->{hsegments} };
}

# Parse all G00/G01 XY moves out of currentpage.
sub get_moves {
    my ($g) = @_;
    my @moves;
    for my $line ( @{ $g->{currentpage} } ) {
        if ( $line =~ /^(G0[01])\s+X\s*([-\d.]+)\s+Y\s*([-\d.]+)/ ) {
            push @moves, { type => $1, x => $2 + 0, y => $3 + 0 };
        }
    }
    return @moves;
}

# Convert degrees to radians.
sub deg2rad { $_[0] * 3.14159265358979 / 180.0 }


# ===========================================================================
# 1. Module availability and composed methods
# ===========================================================================

note('--- 1. module availability ---');

{
    my $g = new_g();
    isa_ok( $g, 'Graphics::Penplotter::GcodeXY', 'object created' );

    ok( $g->can('sethatchsep'),   'sethatchsep is composed' );
    ok( $g->can('sethatchangle'), 'sethatchangle is composed' );
    ok( $g->can('strokefill'),    'strokefill is composed' );

    # Internal methods also composed (needed for font integration)
    ok( $g->can('_dohatching'),       '_dohatching is composed' );
    ok( $g->can('_get_bbox'),         '_get_bbox is composed' );
    ok( $g->can('_flushHsegments'),   '_flushHsegments is composed' );
    ok( $g->can('_addhsegmentpath'),  '_addhsegmentpath is composed' );
}


# ===========================================================================
# 2. Default attribute values
# ===========================================================================

note('--- 2. default attribute values ---');

{
    # Use a plain new() without hatchsep so we test the built-in default,
    # not the 0.25 override that new_g() injects for other test sections.
    my $g = Graphics::Penplotter::GcodeXY->new(
        xsize => 10, ysize => 10, units => 'in', optimize => 0
    );
    is( $g->{hatchsep},   0.012, 'hatchsep default is 0.012' );
    is( $g->{hatchangle}, 0,     'hatchangle default is 0' );
}


# ===========================================================================
# 3. sethatchsep API
# ===========================================================================

note('--- 3. sethatchsep ---');

{
    my $g = new_g();
    my $rc = $g->sethatchsep(0.5);
    is( $rc,                 1,   'sethatchsep returns 1' );
    is( $g->{hatchsep},      0.5, 'sethatchsep stores the value' );

    $g->sethatchsep(0.1);
    is( $g->{hatchsep}, 0.1, 'sethatchsep overwrites previous value' );
}

{
    my $g = new_g();
    eval { $g->sethatchsep() };
    ok( $@, 'sethatchsep with no argument croaks' );
}


# ===========================================================================
# 4. sethatchangle API
# ===========================================================================

note('--- 4. sethatchangle ---');

{
    my $g = new_g();
    my $rc = $g->sethatchangle(45);
    is( $rc,                  1,  'sethatchangle returns 1' );
    is( $g->{hatchangle},    45,  'sethatchangle stores the value' );

    $g->sethatchangle(0);
    is( $g->{hatchangle}, 0, 'sethatchangle can reset to 0' );

    $g->sethatchangle(-30);
    is( $g->{hatchangle}, -30, 'sethatchangle accepts negative angles' );

    $g->sethatchangle(270);
    is( $g->{hatchangle}, 270, 'sethatchangle accepts angles > 180' );
}

{
    my $g = new_g();
    eval { $g->sethatchangle() };
    ok( $@, 'sethatchangle with no argument croaks' );
}


# ===========================================================================
# 5. strokefill behaviour
# ===========================================================================

note('--- 5. strokefill ---');

# strokefill on a shape produces gcode
{
    my $g = new_g( hatchsep => 0.25 );
    draw_square($g);
    $g->strokefill();

    my @moves = get_moves($g);
    ok( scalar @moves > 0, 'strokefill: currentpage has G00/G01 moves' );

    my @draws = grep { $_->{type} eq 'G01' } @moves;
    ok( scalar @draws > 0, 'strokefill: currentpage has at least one G01 draw' );
}

# strokefill clears psegments
{
    my $g = new_g();
    draw_square($g);
    $g->strokefill();
    is( scalar @{ $g->{psegments} }, 0, 'strokefill: psegments empty after call' );
}

# strokefill clears hsegments
{
    my $g = new_g();
    draw_square($g);
    $g->strokefill();
    is( scalar @{ $g->{hsegments} }, 0, 'strokefill: hsegments empty after call' );
}

# strokefill on an empty path does not crash
{
    my $g = new_g();
    eval { $g->strokefill() };
    ok( !$@, 'strokefill on empty path does not crash' );
}

# strokefill on a path with only move segments (no draws) does not crash
{
    my $g = new_g();
    $g->moveto(1, 1);    # adds a penup/pendown + fast move, but no 'l' segment
    eval { $g->strokefill() };
    ok( !$@, 'strokefill on move-only path does not crash' );
}

# Consecutive strokefills accumulate in currentpage
{
    my $g = new_g( hatchsep => 0.5 );
    draw_square($g);
    $g->strokefill();
    my $len_after_first = scalar @{ $g->{currentpage} };

    draw_square($g);
    $g->strokefill();
    my $len_after_second = scalar @{ $g->{currentpage} };

    ok( $len_after_second > $len_after_first,
        'strokefill: successive calls accumulate output in currentpage' );
}

# strokefill returns 1
{
    my $g = new_g();
    draw_square($g);
    my $rc = $g->strokefill();
    is( $rc, 1, 'strokefill returns 1' );
}


# ===========================================================================
# 6. _get_bbox helper
# ===========================================================================

note('--- 6. _get_bbox ---');

# Empty path
{
    my $g = new_g();
    my @bb = $g->_get_bbox();
    is_deeply( \@bb, [-1, -1, -1, -1],
        '_get_bbox on empty psegments returns (-1,-1,-1,-1)' );
}

# Path with only move segments (key='m'), no draw segments (key='l')
{
    my $g = new_g();
    $g->moveto(1, 1);    # generates 'm' segment in psegments, no 'l'
    my @bb = $g->_get_bbox();
    is_deeply( \@bb, [-1, -1, -1, -1],
        '_get_bbox with only move segments returns (-1,-1,-1,-1)' );
}

# Square (2,2)-(4,4): bbox should be approximately (2,2,4,4) in device inches
{
    my $g = new_g();
    draw_square($g);
    my ( $minx, $miny, $maxx, $maxy ) = $g->_get_bbox();
    ok( near( $minx, 2 ), "_get_bbox minx ≈ 2 (got $minx)" );
    ok( near( $miny, 2 ), "_get_bbox miny ≈ 2 (got $miny)" );
    ok( near( $maxx, 4 ), "_get_bbox maxx ≈ 4 (got $maxx)" );
    ok( near( $maxy, 4 ), "_get_bbox maxy ≈ 4 (got $maxy)" );
}

# Asymmetric shape: bbox reflects it
{
    my $g = new_g();
    draw_square( $g, 1, 3, 5, 7 );    # (1,3)-(5,7)
    my ( $minx, $miny, $maxx, $maxy ) = $g->_get_bbox();
    ok( near( $minx, 1 ), "_get_bbox asymmetric minx ≈ 1" );
    ok( near( $miny, 3 ), "_get_bbox asymmetric miny ≈ 3" );
    ok( near( $maxx, 5 ), "_get_bbox asymmetric maxx ≈ 5" );
    ok( near( $maxy, 7 ), "_get_bbox asymmetric maxy ≈ 7" );
}


# ===========================================================================
# 7. Horizontal hatch geometry  (angle = 0)
# ===========================================================================
#
# Strategy: call _dohatching directly; inspect hsegments.
# _dohatching populates hsegments, calls _flushHsegments (writes to
# currentpage) but does NOT clear hsegments.  Only newpath clears them.
#
# For angle=0, every 'l' segment must be horizontal: sy == dy.

note('--- 7. horizontal hatch (angle=0) ---');

{
    my $g = new_g( hatchsep => 0.25, hatchangle => 0 );
    draw_square($g);
    $g->_dohatching();

    my @lines = hatch_lines($g);
    ok( scalar @lines > 0, 'angle=0: at least one hatch line generated' );

    my $all_horizontal = 1;
    for my $seg (@lines) {
        unless ( near( $seg->{sy}, $seg->{dy} ) ) {
            $all_horizontal = 0;
            last;
        }
    }
    ok( $all_horizontal,
        'angle=0: all hatch segments are horizontal (sy == dy)' );
}

# Travel ('m') segments must always exist alongside hatch lines
{
    my $g = new_g( hatchsep => 0.25, hatchangle => 0 );
    draw_square($g);
    $g->_dohatching();

    my @travels = hatch_travels($g);
    ok( scalar @travels > 0, 'angle=0: travel moves accompany hatch lines' );
}

# Each travel move should position to the start of the following hatch line
{
    my $g = new_g( hatchsep => 0.5, hatchangle => 0 );
    draw_square($g);
    $g->_dohatching();

    my @segs  = @{ $g->{hsegments} };
    my $pairs = 0;
    for my $i ( 0 .. $#segs - 1 ) {
        if ( $segs[$i]{key} eq 'm' && $segs[ $i + 1 ]{key} eq 'l' ) {
            # Travel endpoint should be the start of the hatch line
            ok( near( $segs[$i]{dx},  $segs[ $i + 1 ]{sx} ) &&
                near( $segs[$i]{dy},  $segs[ $i + 1 ]{sy} ),
                "angle=0: travel[$i] endpoint = hatch[${\($i+1)}] start" );
            $pairs++;
        }
    }
    ok( $pairs > 0, 'angle=0: found at least one travel+hatch pair' );
}


# ===========================================================================
# 8. Vertical hatch geometry  (angle = 90)
# ===========================================================================
#
# For angle=90, each hatch line runs vertically: sx == dx.

note('--- 8. vertical hatch (angle=90) ---');

{
    my $g = new_g( hatchsep => 0.25, hatchangle => 90 );
    draw_square($g);
    $g->_dohatching();

    my @lines = hatch_lines($g);
    ok( scalar @lines > 0, 'angle=90: at least one hatch line generated' );

    my $all_vertical = 1;
    for my $seg (@lines) {
        unless ( near( $seg->{sx}, $seg->{dx} ) ) {
            $all_vertical = 0;
            last;
        }
    }
    ok( $all_vertical,
        'angle=90: all hatch segments are vertical (sx == dx)' );
}

# Vertical hatch should produce the same number of lines as horizontal
# for a square (the shape is symmetric)
{
    my $g0 = new_g( hatchsep => 0.25, hatchangle => 0 );
    draw_square($g0);
    $g0->_dohatching();

    my $g90 = new_g( hatchsep => 0.25, hatchangle => 90 );
    draw_square($g90);
    $g90->_dohatching();

    is( scalar hatch_lines($g0), scalar hatch_lines($g90),
        'angle=90 vs angle=0: square produces the same number of hatch lines' );
}


# ===========================================================================
# 9. Diagonal hatch geometry  (angle = 45)
# ===========================================================================
#
# For angle=45: cos(45°) = sin(45°), so the direction vector is (1,1)/√2.
# Each hatch segment must satisfy: dx - sx == dy - sy   (unit slope).

note('--- 9. diagonal hatch (angle=45) ---');

{
    my $g = new_g( hatchsep => 0.25, hatchangle => 45 );
    draw_square($g);
    $g->_dohatching();

    my @lines = hatch_lines($g);
    ok( scalar @lines > 0, 'angle=45: at least one hatch line generated' );

    my $all_diagonal = 1;
    for my $seg (@lines) {
        my $ddx = $seg->{dx} - $seg->{sx};
        my $ddy = $seg->{dy} - $seg->{sy};
        unless ( near( $ddx, $ddy ) ) {
            $all_diagonal = 0;
            last;
        }
    }
    ok( $all_diagonal,
        'angle=45: all hatch segments have unit slope (dx-sx == dy-sy)' );
}

# angle=-45 should give slope -1
{
    my $g = new_g( hatchsep => 0.25, hatchangle => -45 );
    draw_square($g);
    $g->_dohatching();

    my @lines = hatch_lines($g);
    ok( scalar @lines > 0, 'angle=-45: at least one hatch line generated' );

    my $all_neg_diag = 1;
    for my $seg (@lines) {
        my $ddx = $seg->{dx} - $seg->{sx};
        my $ddy = $seg->{dy} - $seg->{sy};
        unless ( near( $ddx, -$ddy ) ) {
            $all_neg_diag = 0;
            last;
        }
    }
    ok( $all_neg_diag,
        'angle=-45: all hatch segments have slope -1 (dx-sx == -(dy-sy))' );
}


# ===========================================================================
# 10. Arbitrary-angle geometry  (angle = 30)
# ===========================================================================
#
# For a hatch line at angle α, the direction vector is (cos α, sin α).
# Every 'l' segment must satisfy:
#   (dx - sx) · sin(α) ≈ (dy - sy) · cos(α)
# (cross-product of the segment direction with (cos α, sin α) is zero).

note('--- 10. arbitrary angle (angle=30) ---');

{
    my $alpha = 30;
    my $g = new_g( hatchsep => 0.25, hatchangle => $alpha );
    draw_square($g);
    $g->_dohatching();

    my @lines = hatch_lines($g);
    ok( scalar @lines > 0, 'angle=30: at least one hatch line generated' );

    my $sin_a = sin( deg2rad($alpha) );
    my $cos_a = cos( deg2rad($alpha) );
    my $correct_dir = 1;
    for my $seg (@lines) {
        my $ddx = $seg->{dx} - $seg->{sx};
        my $ddy = $seg->{dy} - $seg->{sy};
        # cross product with direction vector must be zero
        unless ( near( $ddx * $sin_a, $ddy * $cos_a ) ) {
            $correct_dir = 0;
            last;
        }
    }
    ok( $correct_dir,
        'angle=30: all hatch segments run at 30 degrees (cross-product test)' );
}

# angle=60 (complementary to 30)
{
    my $alpha = 60;
    my $g = new_g( hatchsep => 0.25, hatchangle => $alpha );
    draw_square($g);
    $g->_dohatching();

    my @lines = hatch_lines($g);
    ok( scalar @lines > 0, 'angle=60: at least one hatch line generated' );

    my $sin_a = sin( deg2rad($alpha) );
    my $cos_a = cos( deg2rad($alpha) );
    my $correct_dir = 1;
    for my $seg (@lines) {
        my $ddx = $seg->{dx} - $seg->{sx};
        my $ddy = $seg->{dy} - $seg->{sy};
        unless ( near( $ddx * $sin_a, $ddy * $cos_a ) ) {
            $correct_dir = 0;
            last;
        }
    }
    ok( $correct_dir,
        'angle=60: all hatch segments run at 60 degrees' );
}


# ===========================================================================
# 11. hatchsep controls line density
# ===========================================================================

note('--- 11. hatchsep controls density ---');

# Halving the separation should approximately double the number of lines.
{
    my $g_coarse = new_g( hatchsep => 0.50, hatchangle => 0 );
    draw_square($g_coarse);
    $g_coarse->_dohatching();
    my $n_coarse = scalar hatch_lines($g_coarse);

    my $g_fine = new_g( hatchsep => 0.25, hatchangle => 0 );
    draw_square($g_fine);
    $g_fine->_dohatching();
    my $n_fine = scalar hatch_lines($g_fine);

    ok( $n_fine > $n_coarse,
        "smaller hatchsep produces more lines ($n_fine > $n_coarse)" );
    # For a 2in square: roughly 2/sep lines.  Accept anything in [1.5×, 2.5×].
    my $ratio = $n_coarse > 0 ? $n_fine / $n_coarse : 0;
    ok( $ratio > 1.4 && $ratio < 3.0,
        "line-count ratio ≈ 2 when sep halved (got ratio $ratio)" );
}

# Same shape, angle=90 -- same relationship holds
{
    my $g_coarse = new_g( hatchsep => 0.50, hatchangle => 90 );
    draw_square($g_coarse);
    $g_coarse->_dohatching();
    my $n_coarse = scalar hatch_lines($g_coarse);

    my $g_fine = new_g( hatchsep => 0.25, hatchangle => 90 );
    draw_square($g_fine);
    $g_fine->_dohatching();
    my $n_fine = scalar hatch_lines($g_fine);

    ok( $n_fine > $n_coarse,
        "angle=90: smaller hatchsep produces more lines" );
}


# ===========================================================================
# 12. Hatch segments lie inside the shape
# ===========================================================================
#
# The midpoint of every 'l' hatch segment must lie within the bounding box
# of the original shape.  This is a necessary (though not sufficient)
# condition for correct fill.

note('--- 12. hatch segments inside the shape ---');

{
    my ( $x0, $y0, $x1, $y1 ) = ( 2, 2, 4, 4 );

    for my $angle ( 0, 30, 45, 60, 90 ) {
        my $g = new_g( hatchsep => 0.25, hatchangle => $angle );
        draw_square( $g, $x0, $y0, $x1, $y1 );
        $g->_dohatching();

        my @lines = hatch_lines($g);

        # Allow a small tolerance for floating-point fuzz at boundaries
        my $tol = 1e-6;
        my $all_inside = 1;
        for my $seg (@lines) {
            my $mx = ( $seg->{sx} + $seg->{dx} ) / 2.0;
            my $my = ( $seg->{sy} + $seg->{dy} ) / 2.0;
            unless ( $mx >= $x0 - $tol && $mx <= $x1 + $tol &&
                     $my >= $y0 - $tol && $my <= $y1 + $tol )
            {
                $all_inside = 0;
                last;
            }
        }
        ok( $all_inside,
            "angle=${angle}: midpoints of all hatch segments inside bbox" );
    }
}


# ===========================================================================
# 13. Graphics state preservation
# ===========================================================================
#
# _dohatching calls gsave/grestore; after it returns, the CTM and current
# point must be exactly as they were before.

note('--- 13. graphics state preservation ---');

# CTM unchanged after _dohatching
{
    my $g = new_g( hatchangle => 45 );
    draw_square($g);

    # Apply a translate so we can tell if the CTM has changed
    $g->translate(1, 1);
    my @ctm_before = map { [ @$_ ] } @{ $g->{CTM} };

    $g->_dohatching();

    my $ctm_ok = 1;
    for my $r ( 0 .. 2 ) {
        for my $c ( 0 .. 2 ) {
            unless ( near( $g->{CTM}[$r][$c], $ctm_before[$r][$c] ) ) {
                $ctm_ok = 0;
            }
        }
    }
    ok( $ctm_ok, '_dohatching: CTM restored by grestore' );
}

# Current point unchanged after _dohatching
{
    my $g = new_g( hatchangle => 45 );
    draw_square($g);
    $g->translate(1, 1);
    my ( $px_before, $py_before ) = $g->currentpoint();

    $g->_dohatching();

    my ( $px_after, $py_after ) = $g->currentpoint();
    ok( near( $px_before, $px_after ) && near( $py_before, $py_after ),
        '_dohatching: current point restored by grestore' );
}

# CTM unchanged after strokefill
{
    my $g = new_g( hatchangle => 0 );
    draw_square($g);
    $g->translate(2, 3);
    my @ctm_before = map { [ @$_ ] } @{ $g->{CTM} };

    # Draw another square and strokefill it
    draw_square( $g, 1, 1, 3, 3 );
    $g->strokefill();

    my $ctm_ok = 1;
    for my $r ( 0 .. 2 ) {
        for my $c ( 0 .. 2 ) {
            unless ( near( $g->{CTM}[$r][$c], $ctm_before[$r][$c] ) ) {
                $ctm_ok = 0;
            }
        }
    }
    ok( $ctm_ok, 'strokefill: CTM unchanged after call' );
}


# ===========================================================================
# 14. psegments unchanged after non-zero angle
# ===========================================================================
#
# When angle != 0, _dohatching swaps in a rotated copy of psegments and
# then restores the original before returning.  The caller's path must
# be bit-for-bit identical to what it was before the call.

note('--- 14. psegments restored after non-zero angle ---');

{
    for my $angle ( 30, 45, 60, 90 ) {
        my $g = new_g( hatchangle => $angle );
        draw_square($g);

        # Deep-copy the psegments before
        my @before = map { { %$_ } } @{ $g->{psegments} };

        $g->_dohatching();

        my @after = @{ $g->{psegments} };
        is( scalar @after, scalar @before,
            "angle=$angle: psegments count unchanged after _dohatching" );

        my $segs_match = 1;
        for my $i ( 0 .. $#before ) {
            # Compare 'key' (a string) separately with eq.
            if ( ( $before[$i]{key} // '' ) ne ( $after[$i]{key} // '' ) ) {
                $segs_match = 0;
            }
            for my $field (qw( sx sy dx dy )) {
                next unless defined $before[$i]{$field};
                unless ( near( $before[$i]{$field} + 0,
                               $after[$i]{$field}  + 0 ) )
                {
                    $segs_match = 0;
                }
            }
        }
        ok( $segs_match,
            "angle=$angle: psegments values unchanged after _dohatching" );
    }
}


# ===========================================================================
# 15. Angle equivalence
# ===========================================================================
#
# For a square (which is symmetric under 180-degree rotation):
#   angle=0   and angle=180  should produce the same number of hatch lines.
#   angle=90  and angle=270  should produce the same number of hatch lines.

note('--- 15. angle equivalence ---');

{
    for my $base ( 0, 90 ) {
        my $g0 = new_g( hatchsep => 0.25, hatchangle => $base );
        draw_square($g0);
        $g0->_dohatching();

        my $g180 = new_g( hatchsep => 0.25, hatchangle => $base + 180 );
        draw_square($g180);
        $g180->_dohatching();

        is( scalar hatch_lines($g0), scalar hatch_lines($g180),
            "angle=$base and angle=@{[$base+180]} produce the same line count" );
    }
}


# ===========================================================================
# 16. Constructor attribute injection
# ===========================================================================

note('--- 16. constructor attribute injection ---');

{
    my $g = Graphics::Penplotter::GcodeXY->new(
        xsize      => 10,
        ysize      => 10,
        units      => 'in',
        optimize   => 0,
        hatchsep   => 0.1,
        hatchangle => 30,
    );
    is( $g->{hatchsep},   0.1, 'constructor: hatchsep set via new()' );
    is( $g->{hatchangle}, 30,  'constructor: hatchangle set via new()' );
}

# Verify that constructor-set values are actually used by _dohatching
{
    my $g = Graphics::Penplotter::GcodeXY->new(
        xsize      => 10,
        ysize      => 10,
        units      => 'in',
        optimize   => 0,
        hatchsep   => 0.25,
        hatchangle => 45,
    );
    draw_square($g);
    $g->_dohatching();

    my @lines = hatch_lines($g);
    ok( scalar @lines > 0,
        'constructor hatchangle=45: _dohatching produces lines' );

    # All segments must be at 45 degrees
    my $all_45 = 1;
    for my $seg (@lines) {
        my $ddx = $seg->{dx} - $seg->{sx};
        my $ddy = $seg->{dy} - $seg->{sy};
        unless ( near( $ddx, $ddy ) ) {
            $all_45 = 0;
            last;
        }
    }
    ok( $all_45, 'constructor hatchangle=45: lines are at 45 degrees' );
}

done_testing();
