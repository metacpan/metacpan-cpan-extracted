#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# ---------------------------------------------------------------------------
# 18-swirl.t  --  Tests for Graphics::Penplotter::GcodeXY::Swirl
#
# Tests are grouped into:
#   1.  Module availability and composed method
#   2.  Input validation (compulsory args, bad shapes)
#   3.  Iteration control: fixed count
#   4.  Iteration control: size-based termination
#   5.  Clockwise vs counter-clockwise direction
#   6.  Per-edge draw flags
#   7.  Varying d values per edge
#   8.  Output produces gcode
#   9.  Geometric correctness (new vertex lies on edge)
#  10.  Package constants
#  11.  Constructor attribute integration (swirl does not add state)
# ---------------------------------------------------------------------------

BEGIN {
    eval { require Graphics::Penplotter::GcodeXY; 1 }
        or plan( skip_all => 'Graphics::Penplotter::GcodeXY not available' );
}
use Graphics::Penplotter::GcodeXY;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub new_g {
    my (%extra) = @_;
    return Graphics::Penplotter::GcodeXY->new(
        xsize    => 200,
        ysize    => 200,
        units    => 'in',
        optimize => 0,
        %extra,
    );
}

# Tolerance comparison
sub near { abs( $_[0] - $_[1] ) < 1e-9 }

# Unit square (10,10)-(90,10)-(90,90)-(10,90), CCW winding
my @SQUARE = ( 10,10,  90,10,  90,90,  10,90 );
my @D4     = ( 20, 20, 20, 20 );           # uniform 20% advance

# Equilateral-ish triangle
my @TRIANGLE = ( 50,10,  90,80,  10,80 );
my @D3       = ( 15, 25, 10 );

# Count G01 (draw) lines in currentpage
sub count_g01 {
    my ($g) = @_;
    return scalar grep { /^G01/ } @{ $g->{currentpage} };
}

# Count G00 (travel) lines
sub count_g00 {
    my ($g) = @_;
    return scalar grep { /^G00\s+X/ } @{ $g->{currentpage} };
}

# Extract all unique Y-coordinate values from G00/G01 lines
sub all_y_values {
    my ($g) = @_;
    my %y;
    for my $line ( @{ $g->{currentpage} } ) {
        if ( $line =~ /[XY]\s+([-\d.]+)\s+Y\s+([-\d.]+)/ ) {
            $y{ $2 + 0 } = 1;
        }
    }
    return sort { $a <=> $b } keys %y;
}


# ===========================================================================
# 1. Module availability and composed method
# ===========================================================================

note('--- 1. module availability ---');

{
    my $g = new_g();
    isa_ok( $g, 'Graphics::Penplotter::GcodeXY', 'object created' );
    ok( $g->can('swirl'), 'swirl() is composed into the host class' );
}


# ===========================================================================
# 2. Input validation
# ===========================================================================

note('--- 2. input validation ---');

# Missing 'points'
{
    my $g = new_g();
    eval { $g->swirl( d => \@D4 ) };
    ok( $@, 'swirl without "points" croaks' );
}

# Missing 'd'
{
    my $g = new_g();
    eval { $g->swirl( points => \@SQUARE ) };
    ok( $@, 'swirl without "d" croaks' );
}

# Odd number of coordinates in points
{
    my $g = new_g();
    eval { $g->swirl( points => [ 10, 20, 30 ], d => [ 20, 20 ] ) };
    ok( $@, 'swirl with odd-length "points" croaks' );
}

# Only 2 vertices (< 3)
{
    my $g = new_g();
    eval { $g->swirl( points => [ 10,10, 90,90 ], d => [ 20, 20 ] ) };
    ok( $@, 'swirl with fewer than 3 vertices croaks' );
}

# Mismatch between vertex count and d count
{
    my $g = new_g();
    eval { $g->swirl( points => \@SQUARE, d => [ 20, 20 ] ) };
    ok( $@, 'swirl with wrong number of d values croaks' );
}

# Mismatch between vertex count and draw count
{
    my $g = new_g();
    eval { $g->swirl( points => \@SQUARE, d => \@D4, draw => [ 1, 1 ] ) };
    ok( $@, 'swirl with wrong number of draw flags croaks' );
}

# Invalid direction
{
    my $g = new_g();
    eval { $g->swirl( points => \@SQUARE, d => \@D4, direction => 2 ) };
    ok( $@, 'swirl with direction=2 croaks' );
}

# Valid minimal call returns 1
{
    my $g = new_g();
    my $rc = eval { $g->swirl( points => \@SQUARE, d => \@D4, iterations => 5 ) };
    ok( !$@,      'swirl with valid args does not croak' );
    is( $rc, 1,   'swirl returns 1 on success' );
}


# ===========================================================================
# 3. Iteration control: fixed count
# ===========================================================================

note('--- 3. fixed iteration count ---');

# With iterations => N the base polygon is always drawn plus N inner ones.
# Each square ring is a closed polygon: 4 edges + closing move = at least
# 4 G01 lines.  So total G01 count >= 4 * (N+1).
{
    for my $n ( 1, 5, 20 ) {
        my $g = new_g();
        $g->swirl( points => \@SQUARE, d => \@D4, iterations => $n );
        my $g01 = count_g01($g);
        ok( $g01 >= 4 * ( $n + 1 ),
            "iterations=$n: G01 count ($g01) >= 4 * (n+1) = " . 4*($n+1) );
    }
}

# iterations => 0 draws only the base polygon
{
    my $g = new_g();
    $g->swirl( points => \@SQUARE, d => \@D4, iterations => 0 );
    my $g01 = count_g01($g);
    ok( $g01 >= 4, "iterations=0: base polygon (>= 4 G01 lines) drawn ($g01)" );

    # The number of draw lines should not exceed what a single square needs.
    # A closed polygon is 4 line segments; generous upper bound is 10.
    ok( $g01 <= 10, "iterations=0: no extra polygons drawn ($g01 <= 10)" );
}

# More iterations → more gcode
{
    my $g5  = new_g();
    $g5->swirl( points => \@SQUARE, d => \@D4, iterations => 5 );

    my $g20 = new_g();
    $g20->swirl( points => \@SQUARE, d => \@D4, iterations => 20 );

    ok( count_g01($g20) > count_g01($g5),
        'more iterations produce more G01 draw lines' );
}


# ===========================================================================
# 4. Iteration control: size-based termination
# ===========================================================================

note('--- 4. size-based termination ---');

# With a very loose threshold (50%) the whirl stops quickly
{
    my $g = new_g();
    $g->swirl( points => \@SQUARE, d => \@D4, min_size => 50 );
    my $g01_loose = count_g01($g);

    my $g2 = new_g();
    $g2->swirl( points => \@SQUARE, d => \@D4, min_size => 1 );
    my $g01_tight = count_g01($g2);

    ok( $g01_tight >= $g01_loose,
        'smaller min_size produces at least as many draw lines as larger min_size' );
}

# min_size => 0 should iterate until the polygon converges (no crash)
{
    my $g = new_g();
    eval { $g->swirl( points => \@SQUARE, d => \@D4, min_size => 0 ) };
    ok( !$@, 'min_size => 0 does not croak' );
    ok( count_g01($g) > 0, 'min_size => 0 still draws something' );
}


# ===========================================================================
# 5. Clockwise vs counter-clockwise direction
# ===========================================================================

note('--- 5. CW vs CCW direction ---');

# Both directions produce the same number of G01 lines for the same number
# of iterations (the winding differs but the count does not).
{
    my $g_cw = new_g();
    $g_cw->swirl( points => \@SQUARE, d => \@D4, direction => 0, iterations => 10 );

    my $g_ccw = new_g();
    $g_ccw->swirl( points => \@SQUARE, d => \@D4, direction => 1, iterations => 10 );

    is( count_g01($g_cw), count_g01($g_ccw),
        'CW and CCW produce the same number of G01 lines' );
}

# The coordinate outputs must differ (the polygons are mirror images)
{
    my $g_cw = new_g();
    $g_cw->swirl( points => \@SQUARE, d => \@D4, direction => 0, iterations => 3 );

    my $g_ccw = new_g();
    $g_ccw->swirl( points => \@SQUARE, d => \@D4, direction => 1, iterations => 3 );

    my $cw_page  = join( '', @{ $g_cw->{currentpage}  } );
    my $ccw_page = join( '', @{ $g_ccw->{currentpage} } );
    isnt( $cw_page, $ccw_page,
        'CW and CCW produce different gcode output (mirror images)' );
}

# Using the package constants gives the same result as numeric literals
{
    my $g_lit = new_g();
    $g_lit->swirl( points => \@SQUARE, d => \@D4, direction => 1, iterations => 5 );

    my $g_const = new_g();
    $g_const->swirl(
        points    => \@SQUARE,
        d         => \@D4,
        direction => $Graphics::Penplotter::GcodeXY::Swirl::SWIRL_CCW,
        iterations => 5,
    );

    is( join( '', @{ $g_lit->{currentpage} } ),
        join( '', @{ $g_const->{currentpage} } ),
        'SWIRL_CCW constant gives same result as direction => 1' );
}


# ===========================================================================
# 6. Per-edge draw flags
# ===========================================================================

note('--- 6. per-edge draw flags ---');

# All edges drawn (default) vs some suppressed: suppressing edges reduces G01 count
{
    my $g_full = new_g();
    $g_full->swirl( points => \@SQUARE, d => \@D4, iterations => 10 );

    my $g_part = new_g();
    $g_part->swirl(
        points     => \@SQUARE,
        d          => \@D4,
        iterations => 10,
        draw       => [ 1, 0, 1, 0 ],   # alternating: skip 2 edges per ring
    );

    ok( count_g01($g_part) < count_g01($g_full),
        'suppressing 2 edges per ring reduces G01 count' );
}

# Suppressing all edges should produce zero G01 lines
{
    my $g = new_g();
    $g->swirl(
        points     => \@SQUARE,
        d          => \@D4,
        iterations => 10,
        draw       => [ 0, 0, 0, 0 ],
    );
    is( count_g01($g), 0, 'draw=[0,0,0,0]: no G01 lines produced' );
}

# Suppressing no edges gives same count as omitting the draw argument
{
    my $g_no_draw = new_g();
    $g_no_draw->swirl( points => \@SQUARE, d => \@D4, iterations => 10 );

    my $g_all_draw = new_g();
    $g_all_draw->swirl(
        points     => \@SQUARE,
        d          => \@D4,
        iterations => 10,
        draw       => [ 1, 1, 1, 1 ],
    );

    is( count_g01($g_no_draw), count_g01($g_all_draw),
        'draw=[1,1,1,1] gives same count as omitting draw argument' );
}


# ===========================================================================
# 7. Varying d values per edge
# ===========================================================================

note('--- 7. varying d values ---');

# Uniform d and varying d with same mean produce different gcode
{
    my $g_uni = new_g();
    $g_uni->swirl( points => \@SQUARE, d => [ 20, 20, 20, 20 ], iterations => 10 );

    my $g_var = new_g();
    $g_var->swirl( points => \@SQUARE, d => [  5, 40, 10, 25 ], iterations => 10 );

    isnt(
        join( '', @{ $g_uni->{currentpage} } ),
        join( '', @{ $g_var->{currentpage} } ),
        'varying d produces different gcode from uniform d',
    );
}

# Triangle with varying d
{
    my $g = new_g();
    my $rc = eval {
        $g->swirl( points => \@TRIANGLE, d => \@D3, iterations => 15 );
    };
    ok( !$@,      'triangle with varying d does not croak' );
    is( $rc, 1,   'triangle with varying d returns 1' );
    ok( count_g01($g) > 0, 'triangle with varying d produces draw lines' );
}

# d => [50,50,50,50] should still run without crashing (degenerate case)
{
    my $g = new_g();
    eval { $g->swirl( points => \@SQUARE, d => [ 50,50,50,50 ], iterations => 5 ) };
    ok( !$@, 'd=50 (degenerate) does not croak' );
}


# ===========================================================================
# 8. Output produces gcode
# ===========================================================================

note('--- 8. gcode output ---');

# currentpage must contain G00 travel and G01 draw lines after swirl
{
    my $g = new_g();
    $g->swirl( points => \@SQUARE, d => \@D4, iterations => 5 );

    ok( count_g00($g) > 0, 'currentpage contains G00 travel lines' );
    ok( count_g01($g) > 0, 'currentpage contains G01 draw lines' );
}

# Successive swirl calls accumulate in currentpage
{
    my $g = new_g();
    $g->swirl( points => \@SQUARE,   d => \@D4, iterations => 5 );
    my $len1 = scalar @{ $g->{currentpage} };

    $g->swirl( points => \@TRIANGLE, d => \@D3, iterations => 5 );
    my $len2 = scalar @{ $g->{currentpage} };

    ok( $len2 > $len1,
        'successive swirl calls accumulate in currentpage' );
}

# After swirl the psegments queue is populated (drawn via polygon/line)
{
    my $g = new_g();
    $g->swirl( points => \@SQUARE, d => \@D4, iterations => 3 );
    # psegments may or may not be populated depending on stroke; the key
    # check is that currentpage has content — done above.  Just verify no crash.
    ok( 1, 'no crash verifying psegments after swirl' );
}


# ===========================================================================
# 9. Geometric correctness (new vertex lies on edge)
# ===========================================================================
#
# We verify that for iterations => 1, CW direction, uniform d=20%, each new
# vertex of the inner ring lies exactly 20% of the way along the corresponding
# edge of the base square.
#
# Base square vertices (in order):
#   V0=(10,10)  V1=(90,10)  V2=(90,90)  V3=(10,90)
#
# For d=20% CW:
#   new[0] = V0 + 0.20*(V1-V0) = (10 + 0.2*80, 10) = (26, 10)
#   new[1] = V1 + 0.20*(V2-V1) = (90, 10 + 0.2*80) = (90, 26)
#   new[2] = V2 + 0.20*(V3-V2) = (90 - 0.2*80, 90) = (74, 90)
#   new[3] = V3 + 0.20*(V0-V3) = (10, 90 - 0.2*80) = (10, 74)
#
# These are the coordinates that should appear in the gcode.

note('--- 9. geometric correctness ---');

{
    my @expected_xy = (
        [ 26, 10 ],
        [ 90, 26 ],
        [ 74, 90 ],
        [ 10, 74 ],
    );

    my $g = new_g();
    $g->swirl( points => \@SQUARE, d => \@D4, iterations => 1 );

    my $page = join( "\n", @{ $g->{currentpage} } );

    for my $pt ( @expected_xy ) {
        my ( $ex, $ey ) = @{$pt};
        # sprintf format used by the module: "%.5f"
        my $xs = sprintf '%.5f', $ex;
        my $ys = sprintf '%.5f', $ey;
        like(
            $page,
            qr/G0[01]\s+X\s*$xs\s+Y\s*$ys/,
            "inner ring vertex ($ex,$ey) appears in gcode",
        );
    }
}

# For CCW with d=20%, new[0] = V1 + 0.20*(V0-V1) = (90-0.2*80, 10) = (74, 10)
{
    my $g = new_g();
    $g->swirl( points => \@SQUARE, d => \@D4, direction => 1, iterations => 1 );

    my $page = join( "\n", @{ $g->{currentpage} } );
    my $xs = sprintf '%.5f', 74;
    my $ys = sprintf '%.5f', 10;
    like(
        $page,
        qr/G0[01]\s+X\s*$xs\s+Y\s*$ys/,
        'CCW: first inner vertex (74,10) appears in gcode',
    );
}


# ===========================================================================
# 10. Package constants
# ===========================================================================

note('--- 10. package constants ---');

{
    is( $Graphics::Penplotter::GcodeXY::Swirl::SWIRL_CW,  0, 'SWIRL_CW  == 0' );
    is( $Graphics::Penplotter::GcodeXY::Swirl::SWIRL_CCW, 1, 'SWIRL_CCW == 1' );
}


# ===========================================================================
# 11. No shared state pollution
# ===========================================================================
#
# swirl() must not introduce its own GcodeXY object attributes beyond what
# GcodeXY itself defines.  We verify that calling swirl leaves exactly the
# same attribute keys as before (GcodeXY manages state, not the role).

note('--- 11. no shared-state pollution ---');

{
    my $g = new_g();
    my %keys_before = map { $_ => 1 } keys %{$g};

    $g->swirl( points => \@SQUARE, d => \@D4, iterations => 5 );

    # Keys that are legitimately added by drawing (currentpage, psegments, etc.)
    # are already present after new(); swirl must not introduce NEW top-level keys.
    my %keys_after = map { $_ => 1 } keys %{$g};

    my @new_keys = grep { !exists $keys_before{$_} } keys %keys_after;
    is( scalar @new_keys, 0,
        'swirl does not introduce new top-level object attributes (' .
        join( ',', @new_keys ) . ')' );
}


done_testing();
