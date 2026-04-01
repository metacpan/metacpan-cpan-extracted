package Graphics::Penplotter::GcodeXY::Swirl v0.9.4;

use v5.38.2;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use strict;
use warnings;
use Role::Tiny;

# ---------------------------------------------------------------------------
# Graphics::Penplotter::GcodeXY::Swirl
#
# Role providing whirl (pursuit-curve polygon) generation for GcodeXY.
# Based on:  Kerry Mitchell, "Fun with Whirls", Bridges 2015, pp. 175-182.
# ---------------------------------------------------------------------------

requires qw( _croak line polygon );

# ---------------------------------------------------------------------------
# Direction constants (also exposed as exportable package scalars)
# ---------------------------------------------------------------------------

our $SWIRL_CW  = 0;    # clockwise  (default)
our $SWIRL_CCW = 1;    # counter-clockwise

# ===========================================================================
# PUBLIC API
# ===========================================================================

=for comment
  swirl( points  => \@pts,      # flat [x0,y0, x1,y1, ...] array (compulsory)
         d       => \@d,        # per-edge advance percentages  (compulsory)
         direction  => 0|1,     # 0=CW (default), 1=CCW
         draw       => \@bool,  # per-edge draw flags (default: all 1)
         iterations => $n,      # stop after $n nested polygons (highest precedence)
         min_size   => $pct,    # stop when first edge shrinks to $pct% of original
       )
=cut

sub swirl ($self, %args) {

    # -----------------------------------------------------------------------
    # 1. Required parameters
    # -----------------------------------------------------------------------
    my $pts_ref = $args{points}
        or $self->_croak('swirl: "points" is required');
    my $d_ref = $args{d}
        or $self->_croak('swirl: "d" (per-edge percentages) is required');

    # -----------------------------------------------------------------------
    # 2. Optional parameters with defaults
    # -----------------------------------------------------------------------
    my $direction  = $args{direction}  // $SWIRL_CW;
    my $draw_ref   = $args{draw};
    my $iterations = $args{iterations};   # undef → use size-based termination
    my $min_size   = $args{min_size} // 1.0;  # percent of original first-edge length

    # -----------------------------------------------------------------------
    # 3. Validate inputs
    # -----------------------------------------------------------------------
    my @pts = @{$pts_ref};
    my @d   = @{$d_ref};

    $self->_croak('swirl: "points" must contain an even number of elements (x,y pairs)')
        if @pts % 2;

    my $n = @pts / 2;    # number of vertices
    $self->_croak('swirl: at least 3 vertices are required')
        if $n < 3;

    $self->_croak('swirl: "d" must have exactly one entry per edge (same count as vertices)')
        if @d != $n;

    # Per-edge draw flags — default all true
    my @draw = defined $draw_ref ? @{$draw_ref} : ( (1) x $n );
    $self->_croak('swirl: "draw" must have exactly one entry per edge (same count as vertices)')
        if @draw != $n;

    $self->_croak('swirl: "direction" must be 0 (clockwise) or 1 (counter-clockwise)')
        if $direction != $SWIRL_CW && $direction != $SWIRL_CCW;

    # -----------------------------------------------------------------------
    # 4. Convert percentage d-values to fractions in [0,1]
    # -----------------------------------------------------------------------
    my @df = map { $_ / 100.0 } @d;

    # -----------------------------------------------------------------------
    # 5. Build vertex list as [[x,y], ...] pairs
    # -----------------------------------------------------------------------
    my @verts;
    for my $i ( 0 .. $n - 1 ) {
        push @verts, [ $pts[ 2 * $i ], $pts[ 2 * $i + 1 ] ];
    }

    # -----------------------------------------------------------------------
    # 6. Termination threshold (size-based)
    # -----------------------------------------------------------------------
    my $orig_edge_len = _edge_len( $verts[0], $verts[1] );
    # Avoid division-by-zero for degenerate polygons
    my $threshold = $orig_edge_len > 0
        ? $orig_edge_len * $min_size / 100.0
        : 0;
    # Guard against a zero (or near-zero) threshold that would cause a
    # near-infinite loop when min_size => 0.  Clamp to a relative epsilon
    # of 1e-9 so the loop always terminates within a reasonable number of
    # iterations (the polygon simply converges to numerical noise).
    if ( $orig_edge_len > 0 && $threshold < $orig_edge_len * 1e-9 ) {
        $threshold = $orig_edge_len * 1e-9;
    }

    # -----------------------------------------------------------------------
    # 7. Draw the base (outermost) polygon
    # -----------------------------------------------------------------------
    $self->_swirl_draw_poly( \@verts, \@draw );

    # -----------------------------------------------------------------------
    # 8. Iterate inward
    # -----------------------------------------------------------------------
    my $iter = 0;
    ITERATE: while (1) {

        # Fixed-iteration termination (highest precedence)
        last ITERATE if defined $iterations && $iter >= $iterations;

        # Compute next ring of vertices
        my @new_verts;
        for my $i ( 0 .. $n - 1 ) {
            my $j = ( $i + 1 ) % $n;
            if ( $direction == $SWIRL_CW ) {
                # CW: new vertex i moves fraction df[i] from verts[i] toward verts[j]
                push @new_verts, [
                    $verts[$i][0] + $df[$i] * ( $verts[$j][0] - $verts[$i][0] ),
                    $verts[$i][1] + $df[$i] * ( $verts[$j][1] - $verts[$i][1] ),
                ];
            }
            else {
                # CCW: new vertex i moves fraction df[i] from verts[j] toward verts[i]
                push @new_verts, [
                    $verts[$j][0] + $df[$i] * ( $verts[$i][0] - $verts[$j][0] ),
                    $verts[$j][1] + $df[$i] * ( $verts[$i][1] - $verts[$j][1] ),
                ];
            }
        }

        $iter++;
        @verts = @new_verts;

        # Size-based termination (only when iterations not fixed)
        unless ( defined $iterations ) {
            last ITERATE if $orig_edge_len == 0;
            my $cur_edge_len = _edge_len( $verts[0], $verts[1] );
            last ITERATE if $cur_edge_len <= $threshold;
        }

        # Draw this ring
        $self->_swirl_draw_poly( \@verts, \@draw );
    }

    return 1;
}

# ===========================================================================
# PRIVATE HELPERS
# ===========================================================================

# Draw one ring of the whirl.
# Uses polygon() when all edges are active (efficient), otherwise line().
sub _swirl_draw_poly ($self, $verts, $draw) {
    my $n = scalar @{$verts};

    # Check whether all edges should be drawn
    my $all_draw = 1;
    for my $flag ( @{$draw} ) {
        unless ($flag) { $all_draw = 0; last; }
    }

    if ($all_draw) {
        # polygon() is a moveto + sequence of line()s; include first vertex
        # at the end to close the ring.
        my @flat;
        for my $v ( @{$verts} ) { push @flat, $v->[0], $v->[1]; }
        push @flat, $verts->[0][0], $verts->[0][1];   # closing point
        $self->polygon(@flat);
        $self->stroke();   # flush psegments to currentpage
    }
    else {
        # Draw only the enabled edges individually.
        for my $i ( 0 .. $n - 1 ) {
            next unless $draw->[$i];
            my $j = ( $i + 1 ) % $n;
            $self->line(
                $verts->[$i][0], $verts->[$i][1],
                $verts->[$j][0], $verts->[$j][1],
            );
        }
        $self->stroke();   # flush psegments to currentpage
    }
    return 1;
}

# Euclidean distance between two [x,y] vertex refs.
sub _edge_len ($v1, $v2) {
    return sqrt(
        ( $v2->[0] - $v1->[0] ) ** 2 +
        ( $v2->[1] - $v1->[1] ) ** 2
    );
}

1;

__END__

=head1 NAME

Graphics::Penplotter::GcodeXY::Swirl - Whirl (pursuit-curve) polygon generation for GcodeXY

=head1 SYNOPSIS

    use Graphics::Penplotter::GcodeXY;

    my $g = Graphics::Penplotter::GcodeXY->new(
        xsize => 200, ysize => 200, units => 'mm',
    );

    # Simple square whirl, 100 iterations, 20% advance per edge
    $g->swirl(
        points     => [ 10,10,  190,10,  190,190,  10,190 ],
        d          => [ 20, 20, 20, 20 ],
        iterations => 100,
    );

    # Triangular whirl, varying d, stops when first edge reaches 1% of original
    $g->swirl(
        points   => [ 100,10,  190,170,  10,170 ],
        d        => [ 15, 25, 10 ],
        min_size => 1,
    );

    # Counter-clockwise hexagonal whirl, two edges suppressed for visual effect
    $g->swirl(
        points    => [ 100,10, 162,50, 162,130, 100,170, 38,130, 38,50 ],
        d         => [ (20) x 6 ],
        direction => $Graphics::Penplotter::GcodeXY::Swirl::SWIRL_CCW,
        draw      => [ 1, 0, 1, 1, 0, 1 ],
        min_size  => 0.5,
    );

    $g->output('whirl.gcode');

=head1 DESCRIPTION

A L<Role::Tiny> role providing I<whirl> (also called I<pursuit-curve polygon>)
generation for L<Graphics::Penplotter::GcodeXY>.

A whirl is produced by iteratively constructing a series of nested polygons
where each new vertex lies a fixed fractional distance along an edge of the
enclosing polygon.  The corners of successive polygons trace discrete
approximations to logarithmic spirals, as described in:

    Kerry Mitchell, "Fun with Whirls", Bridges 2015, pp. 175-182.

The role is composed automatically when
L<Graphics::Penplotter::GcodeXY> is loaded; no extra C<use> statement is
required in user code.

=head1 CONSTRUCTION ALGORITHM

Given a base polygon with vertices V[0] to V[n-1] and per-edge advance
fractions f[0] to f[n-1] (converted from the supplied percentages):

=over 4

=item *

For clockwise mode (C<direction =E<gt> 0>), new vertex I<i> is placed at
fraction f[i] of the way from V[i] towards V[(i+1) mod n].

=item *

For counter-clockwise mode (C<direction =E<gt> 1>), new vertex I<i> is placed
at fraction f[i] of the way from V[(i+1) mod n] towards V[i].

=back

This produces a mirror-image whirl.  The resulting nested polygon is drawn
after each iteration.  The base polygon is always drawn first.

=head1 TERMINATION

Iteration stops when the first condition that has been configured is met:

=over 4

=item 1.

B<Fixed iteration count> (C<iterations =E<gt> $n>): exactly C<$n> nested
polygons are drawn inside the base (highest precedence).

=item 2.

B<Size threshold> (C<min_size =E<gt> $pct>): iteration stops when the length of
the first edge of the current polygon falls to or below C<$pct> percent of the
corresponding edge of the base polygon.  The default is C<1.0> (one percent).

=back

If neither is given, the size threshold of 1% is used.

=head1 METHODS

=over 4

=item swirl(%args)

Draw a whirl from the given polygon.  Named arguments:

=over 4

=item C<points =E<gt> \@pts>  (B<compulsory>)

A reference to a flat array of vertex coordinates in alternating X, Y order:
C<[x0,y0, x1,y1, ...]>  At least 3 vertices are required.  Coordinates are
in the current drawing units.

=item C<d =E<gt> \@d>  (B<compulsory>)

A reference to an array of I<advance percentages>, one per edge (same count as
vertices).  Each value specifies how far along the corresponding edge the next
polygon's vertex is placed.  Values are percentages in the range C<0> to C<100>.
For example, C<20> means 20% of the way along the edge.

When all values are equal to C<50>, consecutive polygons degenerate to straight
lines (no visible spiral).  Values close to C<0> or C<100> produce densely
packed spirals; values close to C<50> produce loosely spaced ones.

=item C<direction =E<gt> 0|1>  (optional, default C<0>)

Spiral direction.  C<0> (C<$SWIRL_CW>) gives a clockwise whirl; C<1>
(C<$SWIRL_CCW>) gives a counter-clockwise whirl.

=item C<draw =E<gt> \@bool>  (optional, default all C<1>)

A reference to an array of boolean flags, one per edge, that controls whether
each edge of every nested polygon is drawn.  When all flags are true the
implementation uses C<polygon()> for efficiency; otherwise individual C<line()>
calls are made for the enabled edges.  Setting some flags to false can produce
striking visual effects (see Mitchell, Figures 6 and 7).

=item C<iterations =E<gt> $n>  (optional)

Draw exactly C<$n> nested polygons (not counting the base polygon).  When
given, this takes precedence over C<min_size>.

=item C<min_size =E<gt> $pct>  (optional, default C<1.0>)

Stop iterating once the length of the first edge of the current polygon has
shrunk to C<$pct> percent of the original first-edge length.  Ignored when
C<iterations> is also given.

=back

Returns C<1> on success.  Croaks on invalid input.

=back

=head1 PACKAGE VARIABLES

=over 4

=item C<$Graphics::Penplotter::GcodeXY::Swirl::SWIRL_CW>

Constant C<0>: clockwise direction (the default).

=item C<$Graphics::Penplotter::GcodeXY::Swirl::SWIRL_CCW>

Constant C<1>: counter-clockwise direction.

=back

=head1 REQUIRED METHODS

C<_croak>, C<line>, C<polygon>.

All of these are provided by the host class
L<Graphics::Penplotter::GcodeXY>.

=head1 SEE ALSO

L<Graphics::Penplotter::GcodeXY>, L<Graphics::Penplotter::GcodeXY::Hatch>

Kerry Mitchell, I<"Fun with Whirls">, Bridges Conference 2015, pp. 175-182.
L<https://archive.bridgesmathart.org/2015/bridges2015-175.html>

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com)

=head1 LICENSE

Same terms as Perl itself.

=cut
