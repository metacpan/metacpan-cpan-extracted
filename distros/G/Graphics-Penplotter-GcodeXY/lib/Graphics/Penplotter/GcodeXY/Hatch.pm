package Graphics::Penplotter::GcodeXY::Hatch v0.7.2;

use v5.38.2;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use strict;
use warnings;
use Role::Tiny;
use Readonly qw( Readonly );
use POSIX    qw( floor );

# ---------------------------------------------------------------------------
# Graphics::Penplotter::GcodeXY::Hatch
#
# Role providing scanline hatch-fill for GcodeXY paths.
# ---------------------------------------------------------------------------

requires qw(_croak gsave grestore _getsegintersect _addtopage _flushPsegments newpath);

# ---------------------------------------------------------------------------
# Constants -- private copies of values defined in GcodeXY.pm.
# ---------------------------------------------------------------------------

Readonly my $EOL       => qq{\n};
Readonly my $BBMAX     => 1_000_000.0;   # sentinel for bounding-box initialisation
Readonly my $PI        => 3.14159265359;

# ===========================================================================
# PUBLIC API
# ===========================================================================

# Set the spacing between hatch lines (in current units).
sub sethatchsep ($self, $sep) {
    if ( !defined $sep ) {
        $self->_croak('wrong number of args for sethatchsep');
        return 0;
    }
    $self->{hatchsep} = $sep;
    return 1;
}

# Set the angle of hatch lines in degrees (0 = horizontal, 90 = vertical).
# Positive angles rotate the lines counter-clockwise.
sub sethatchangle ($self, $angle) {
    if ( !defined $angle ) {
        $self->_croak('wrong number of args for sethatchangle');
        return 0;
    }
    $self->{hatchangle} = $angle;
    return 1;
}

# Hatch-fill the current path, then flush and clear it.
sub strokefill ($self) {
    $self->_dohatching();
    $self->_flushPsegments();
    $self->newpath();
    return 1;
}

# ===========================================================================
# INTERNAL: BOUNDING BOX
# ===========================================================================

# Compute the bounding box of the current path from its 'l' (line) segments.
# Returns (minx, miny, maxx, maxy), or (-1,-1,-1,-1) if no line segments exist.
sub _get_bbox ($self) {
    # Initialise to extreme sentinels so any real coordinate wins.
    # maxx/maxy must start at -$BBMAX (not 0) so that negative
    # coordinates -- which occur after rotating psegments for non-zero
    # hatch angles -- are handled correctly.
    my $maxx  = -$BBMAX;
    my $maxy  = -$BBMAX;
    my $minx  =  $BBMAX;
    my $miny  =  $BBMAX;
    my $len   = scalar @{ $self->{psegments} };
    my $count = 0;
    return ( -1, -1, -1, -1 ) unless $len;
    SEGMENT:
    foreach my $i ( 0 .. $len - 1 ) {
        next SEGMENT if $self->{psegments}[$i]{key} ne 'l';
        $count++;
        my $k = $self->{psegments}[$i]{sx};
        if ( $k > $maxx ) { $maxx = $k }
        if ( $k < $minx ) { $minx = $k }
        $k = $self->{psegments}[$i]{sy};
        if ( $k > $maxy ) { $maxy = $k }
        if ( $k < $miny ) { $miny = $k }
        $k = $self->{psegments}[$i]{dx};
        if ( $k > $maxx ) { $maxx = $k }
        if ( $k < $minx ) { $minx = $k }
        $k = $self->{psegments}[$i]{dy};
        if ( $k > $maxy ) { $maxy = $k }
        if ( $k < $miny ) { $miny = $k }
    }
    return ( -1, -1, -1, -1 ) unless $count;
    return ( $minx, $miny, $maxx, $maxy );
}

# ===========================================================================
# INTERNAL: HATCH SEGMENT LIST
# ===========================================================================

# Append a segment to the hatch segment list.
sub _addhsegmentpath ($self, $key, $sx, $sy, $dx, $dy) {
    if ( !defined $dy ) {
        $self->_croak('need 4 numbers for addhsegpath');
        return 0;
    }
    my $len = scalar @{ $self->{hsegments} };
    $self->{hsegments}[$len] = {
        key => $key, sx => $sx, sy => $sy, dx => $dx, dy => $dy
    };
    return 1;
}

# Clear the hatch segment list.
sub _newhpath ($self) {
    @{ $self->{hsegments} } = ();
    return 1;
}

# Placeholder for future hatch-line ordering optimisation.
sub _hoptimize ($self) {
    return 1;
}

# Flush hatch segments to the gcode page, computing pen-travel distances.
sub _flushHsegments ($self) {
    my $len = scalar @{ $self->{hsegments} };
    if ( !$len ) {
        if ( $self->{check} ) {
            print STDOUT '*** no hsegments found' . $EOL;
        }
        return;
    }
    $self->_hoptimize();
    foreach my $i ( 0 .. $len - 1 ) {
        my $d = sqrt(
            ( $self->{hsegments}[$i]{sx} - $self->{hsegments}[$i]{dx} ) ** 2 +
            ( $self->{hsegments}[$i]{sy} - $self->{hsegments}[$i]{dy} ) ** 2
        );
        if ( $self->{hsegments}[$i]{key} eq 'm' ) {
            if ( !$self->{penlocked} ) {
                $self->_addtopage( $self->{penupcmd} );
                $self->{pencount}++;
            }
            $self->_addtopage(
                sprintf "G00 X %.5f Y %.5f" . $EOL,
                $self->{hsegments}[$i]{dx},
                $self->{hsegments}[$i]{dy}
            );
            if ( !$self->{penlocked} ) {
                $self->_addtopage( $self->{pendowncmd} );
            }
            $self->{fastdistcount} += $d;
        }
        if ( $self->{hsegments}[$i]{key} eq 'l' ) {
            $self->_addtopage(
                sprintf "G01 X %.5f Y %.5f" . $EOL,
                $self->{hsegments}[$i]{dx},
                $self->{hsegments}[$i]{dy}
            );
            $self->{slowdistcount} += $d;
        }
    }
    return 1;
}


# ===========================================================================
# INTERNAL: SCANLINE FILL
# ===========================================================================

# Generate hatch-fill segments for the current path by scanline intersection.
# Works in device coordinates.  Graphics state is saved and restored.
#
# When hatchangle is non-zero the algorithm works in a rotated "hatch space"
# where the scanlines are always horizontal:
#
#   1. All psegment endpoints are rotated by -hatchangle into hatch space.
#   2. The bbox, scanline sweep, intersection tests, and deduplication all
#      run unchanged on the rotated copy (stored temporarily in psegments).
#   3. Before recording each hatch segment, its endpoints are rotated back
#      by +hatchangle into drawing space.
#   4. The original psegments are restored before flushing.
#
# This keeps every helper (_get_bbox, _identical, _sameside, _getsegintersect)
# completely unaware of the angle — they always see horizontal scanlines.
sub _dohatching ($self) {
    my ( $xmind, $ymind, $xmaxd, $ymaxd );
    my ( @crossings, @csorted );
    my $perc    = 0;
    # Normalise to [0, 180): hatch lines at θ and θ+180° are identical.
    my $angle   = ( $self->{hatchangle} // 0 ) % 180;
    my $margin  = 10 * $self->{dscale};
    my $sep     = $self->{hatchsep};
    my ( $p, $xstart, $xend, $ymindsave );
    my ( $xmovex, $ymovey, $clen, $same );

    $self->gsave();
    $self->_newhpath();

    # ------------------------------------------------------------------
    # If a non-zero angle is requested, build a rotated working copy of
    # psegments (rotate by -angle) and swap it in.  All the geometry
    # below then runs in hatch space where scanlines are horizontal.
    # ------------------------------------------------------------------
    my $orig_segs = $self->{psegments};
    my ( $cos_a, $sin_a ) = ( 1.0, 0.0 );
    if ( $angle != 0 ) {
        my $rad = $angle * $PI / 180.0;
        $cos_a  = cos($rad);
        $sin_a  = sin($rad);
        my @rotated;
        for my $seg ( @{$orig_segs} ) {
            push @rotated, {
                key => $seg->{key},
                sx  =>  $seg->{sx} * $cos_a + $seg->{sy} * $sin_a,
                sy  => -$seg->{sx} * $sin_a + $seg->{sy} * $cos_a,
                dx  =>  $seg->{dx} * $cos_a + $seg->{dy} * $sin_a,
                dy  => -$seg->{dx} * $sin_a + $seg->{dy} * $cos_a,
            };
        }
        $self->{psegments} = \@rotated;
    }

    my $pathlen = scalar @{ $self->{psegments} };

    ( $xmind, $ymind, $xmaxd, $ymaxd ) = $self->_get_bbox();
    $ymindsave = $ymind;
    $xmovex    = $xmind;
    $ymovey    = $ymind;
    $xmind -= $margin;
    $xmaxd += $margin;
    $ymaxd += $margin;
    # Anchor the sweep to the sep grid with a half-step offset so that no
    # scanline ever falls exactly on a horizontal shape edge.  This makes
    # the hatch-line count independent of floating-point perturbations
    # introduced by the rotation (e.g. cos(pi/2) != 0 exactly).
    {
        my $snapped = floor( $ymindsave / $sep ) * $sep + $sep / 2;
        $snapped -= $sep if $snapped > $ymindsave;
        $ymind = $snapped;
    }

    while ( $ymind < $ymaxd ) {
        @crossings = ();
        foreach my $i ( 0 .. $pathlen - 1 ) {
            if ( $self->{psegments}[$i]{key} eq 'l' ) {
                $perc = $self->_getsegintersect(
                    $xmind,                      $ymind,
                    $xmaxd,                      $ymind,
                    $self->{psegments}[$i]{sx},  $self->{psegments}[$i]{sy},
                    $self->{psegments}[$i]{dx},  $self->{psegments}[$i]{dy}
                );
                if ( $perc > 0.0 ) {
                    push @crossings, { perc => $perc, seg => $i };
                }
            }
        }
        $clen = scalar @crossings;
        if ($clen) {
            @csorted = sort { $a->{perc} <=> $b->{perc} } @crossings;
            HATCH:
            foreach my $i ( 0 .. $clen - 2 ) {
                if ( $csorted[$i]{perc} == $csorted[ $i + 1 ]{perc} ) {
                    if ( $self->_identical( $csorted[$i]{seg}, $csorted[ $i + 1 ]{seg} ) ) {
                        splice @csorted, $i, 1;  $clen--;
                        splice @csorted, $i, 1;  $clen--;
                    }
                    else {
                        $same = $self->_sameside( $ymind,
                            $csorted[$i]{seg}, $csorted[ $i + 1 ]{seg} );
                        if ( $same == 1 ) {
                            splice @csorted, $i, 1;  $clen--;
                            splice @csorted, $i, 1;  $clen--;
                        }
                        elsif ( !$same ) {
                            splice @csorted, $i, 1;  $clen--;
                        }
                        else {
                            next HATCH;
                        }
                    }
                }
            }
            if ( $clen % 2 ) {
                if ( $self->{check} ) {
                    print STDOUT 'dohatching: odd number of crossings' . $EOL;
                }
            }
        }
        if ($clen) {
            PAIR:
            foreach my $i ( 0 .. $clen - 1 ) {
                next PAIR if $i % 2;
                last PAIR if $i + 1 >= $clen;  # safety: skip unpaired crossing
                $p      = $csorted[ $i + 0 ]{perc};
                $xstart = $xmind + $p * ( $xmaxd - $xmind );
                $p      = $csorted[ $i + 1 ]{perc};
                $xend   = $xmind + $p * ( $xmaxd - $xmind );
                if ( $angle != 0 ) {
                    # Rotate all three points back from hatch space to drawing space
                    # (rotation by +angle: x' = x·cos - y·sin, y' = x·sin + y·cos)
                    my ( $ox, $oy ) = ( $xmovex * $cos_a - $ymovey * $sin_a,
                                        $xmovex * $sin_a + $ymovey * $cos_a );
                    my ( $sx, $sy ) = ( $xstart * $cos_a - $ymind   * $sin_a,
                                        $xstart * $sin_a + $ymind   * $cos_a );
                    my ( $ex, $ey ) = ( $xend   * $cos_a - $ymind   * $sin_a,
                                        $xend   * $sin_a + $ymind   * $cos_a );
                    $self->_addhsegmentpath( 'm', $ox, $oy, $sx, $sy );
                    $self->_addhsegmentpath( 'l', $sx, $sy, $ex, $ey );
                }
                else {
                    $self->_addhsegmentpath( 'm', $xmovex, $ymovey, $xstart, $ymind );
                    $self->_addhsegmentpath( 'l', $xstart, $ymind,  $xend,   $ymind );
                }
                $xmovex = $xend;
                $ymovey = $ymind;
            }
        }
        $ymind += $sep;
    }

    # Restore original segments before flushing.
    $self->{psegments} = $orig_segs if $angle != 0;

    $self->_flushHsegments();
    $self->grestore();
    return 1;
}


# ===========================================================================
# INTERNAL: SCANLINE GEOMETRY HELPERS
# ===========================================================================

# True if seg1 and seg2 are the same segment (possibly with endpoints reversed).
sub _identical ($self, $seg1, $seg2) {
    my %h1 = %{ $self->{psegments}[$seg1] };
    my %h2 = %{ $self->{psegments}[$seg2] };
    my ( $ax, $ay, $bx, $by ) = ( $h1{sx}, $h1{sy}, $h1{dx}, $h1{dy} );
    my ( $cx, $cy, $dx, $dy ) = ( $h2{sx}, $h2{sy}, $h2{dx}, $h2{dy} );
    return 1 if $ax == $dx && $ay == $dy && $cx == $bx && $cy == $by;
    return 1 if $ax == $cx && $ay == $cy && $bx == $dx && $by == $dy;
    return 0;
}

# True (1) if seg1 and seg2 share a vertex on the hatch line $y and their
# other endpoints are both on the same side of it.
# Returns -1 if the shared vertex cannot be determined.
sub _sameside ($self, $y, $seg1, $seg2) {
    my %h1 = %{ $self->{psegments}[$seg1] };
    my %h2 = %{ $self->{psegments}[$seg2] };
    my ( $ay, $by ) = ( $h1{sy}, $h1{dy} );
    my ( $cy, $dy ) = ( $h2{sy}, $h2{dy} );
    my ( $y1, $y2 );
    if    ( $ay == $y ) { $y1 = $by }
    elsif ( $by == $y ) { $y1 = $ay }
    else {
        if ( $self->{check} ) {
            print STDOUT "sameside: cannot determine vertex 1 for $y of $seg1 and $seg2" . $EOL;
        }
        return -1;
    }
    if    ( $cy == $y ) { $y2 = $dy }
    elsif ( $dy == $y ) { $y2 = $cy }
    else {
        if ( $self->{check} ) {
            print STDOUT "sameside: cannot determine vertex 2 for $y of $seg1 and $seg2" . $EOL;
        }
        return -1;
    }
    return 1 if $y1 > $y && $y2 > $y;
    return 1 if $y1 < $y && $y2 < $y;
    return 0;
}


1;

__END__

=head1 NAME

Graphics::Penplotter::GcodeXY::Hatch - Scanline hatch-fill for GcodeXY paths

=head1 SYNOPSIS

    $g->sethatchsep(2);        # 2-unit spacing between hatch lines
    $g->sethatchangle(45);     # 45-degree hatch lines (default: 0 = horizontal)
    $g->polygon(0,0, 10,0, 10,10, 0,10, 0,0);
    $g->strokefill();          # hatch-fill the polygon and stroke it

=head1 DESCRIPTION

A L<Role::Tiny> role providing scanline hatch-fill at any angle for
L<Graphics::Penplotter::GcodeXY>.

The entry points are C<sethatchsep>, C<sethatchangle>, and C<strokefill>.
The internal method C<_dohatching> is also composed in so that
C<Graphics::Penplotter::GcodeXY::Font>'s C<_doglyphs> can call it via
C<$self-E<gt>_dohatching()> when rendering filled text.

=head2 Algorithm

C<_dohatching> works in a rotated I<hatch space> where the scanlines are
always horizontal, regardless of the requested C<hatchangle>:

=over 4

=item 1.

All C<psegments> endpoints are rotated by B<-hatchangle> into hatch space
and stored in a temporary array, which is swapped into C<$self-E<gt>{psegments}>.

=item 2.

The bounding box, scanline sweep, intersection tests (C<_getsegintersect>),
and vertex deduplication (C<_identical>, C<_sameside>) all run unchanged on
the rotated copy, they always see horizontal scanlines and need no
modification.

=item 3.

Before each hatch segment is recorded via C<_addhsegmentpath>, its
endpoints are rotated back by B<+hatchangle> into drawing space.

=item 4.

The original C<psegments> are restored before C<_flushHsegments> writes
the gcode.

=back

=head1 METHODS

=over 4

=item sethatchsep($sep)

Set the spacing between hatch lines in the current drawing unit.

=item sethatchangle($degrees)

Set the angle of the hatch lines in degrees.  C<0> (the default) gives
horizontal lines; C<90> gives vertical lines; C<45> gives diagonal lines.
Positive angles rotate the lines counter-clockwise.

=item strokefill()

Hatch-fill the current path at the current angle and spacing, then flush
the segment queue and clear the path.

=back

=head1 REQUIRED METHODS

C<_croak>, C<gsave>, C<grestore>, C<_getsegintersect>,
C<_addtopage>, C<_flushPsegments>, C<newpath>.

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com)

=head1 LICENSE

Same terms as Perl itself.

=cut
