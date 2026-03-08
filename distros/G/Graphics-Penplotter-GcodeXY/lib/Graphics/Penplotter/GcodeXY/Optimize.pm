package Graphics::Penplotter::GcodeXY::Optimize v0.7.2;

use v5.38.2;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use strict;
use warnings;
use Role::Tiny;
use Readonly qw( Readonly );

# ---------------------------------------------------------------------------
# Graphics::Penplotter::GcodeXY::Optimize
# Role providing the segment-queue peephole optimiser for GcodeXY.
# ---------------------------------------------------------------------------

# No requires: all optimizer methods are self-contained within this role.

# ---------------------------------------------------------------------------
# Constants -- private copies of values defined in GcodeXY.pm.
# ---------------------------------------------------------------------------

Readonly my $OPTLOW  => 0;   # low margin for optimization (first instruction to consider)
Readonly my $LONGEST => 6;   # length of the longest recognisable pattern
Readonly my $EOL     => qq{\n};

# ---------------------------------------------------------------------------
# Module-level state -- moved from GcodeXY.pm.
# ---------------------------------------------------------------------------

my $optline = 0;   # instruction counter, used in debug output


# ===========================================================================
# PUBLIC ENTRY POINT
# Called by _flushPsegments in GcodeXY.pm.
# ===========================================================================

# Path segment peephole optimisation.
# Applied immediately before gcode generation.
# Removes redundant pen-up/down pairs, back-and-forth strokes, and
# zero-length moves from the psegments queue.
sub _optimize ($self) {
    my ( $op, $xs, $ys, $xn, $yn, $tmpx, $tmpy, $tmpx2, $tmpy2, $xd, $yd );
    my ( $before, $after, $line, $rest );
    if ( !$self->{optimize} ) { return 0 }
    $line    = $OPTLOW;
    $optline = $OPTLOW - 1;
    $rest    = scalar @{ $self->{psegments} } - $OPTLOW;
    $before  = $rest + $OPTLOW;
    INSTRUCTION:
    while ( $rest > 0 ) {
        ( $op, $xs, $ys, $xd, $yd ) = $self->_curseg($line);
        $tmpx  = $xs;
        $tmpy  = $ys;
        $tmpx2 = $xd;
        $tmpy2 = $yd;
        $optline++;
        if ( $self->{opt_debug} ) {
            print STDOUT $EOL;
            $self->_prPseg( $line + 0 );
            $self->_prPseg( $line + 1 );
            $self->_prPseg( $line + 2 );
            $self->_prPseg( $line + 3 );
            $self->_prPseg( $line + 4 );
            $self->_prPseg( $line + 5 );
        }

        # Pattern 10:
        # (0) line from (a,b) to (c,d)
        # (1) line from (c,d) to (c,d)
        # (2) line from (c,d) to (a,b)
        # (3) penup
        # (4) move from (a,b) to (e,f)
        # => (0) line (a,b)->(c,d)  (1) penup  (2) move (c,d)->(e,f)
        if ( $self->_pattern10( $line, $rest ) ) {
            if ( $self->{opt_debug} ) { print STDOUT "[$optline opt pattern 10] " }
            my $c = $self->{psegments}[ $line + 0 ]{dx};
            my $d = $self->{psegments}[ $line + 0 ]{dy};
            $self->_keep( \$line, \$rest );
            $self->_drop( $line,  \$rest );
            $self->_drop( $line,  \$rest );
            $self->_keep( \$line, \$rest );
            $self->_fastmove( $line, $c, $d,
                $self->{psegments}[ $line + 0 ]{dx},
                $self->{psegments}[ $line + 0 ]{dy} );
            if ( $self->{opt_debug} ) { print STDOUT $EOL }
            next INSTRUCTION;
        }

        # Pattern 1:
        # (0) move (x,y)->(a,b)   (1) pendown
        # (2) line (a,b)->(c,d)   (3) line (c,d)->(a,b)   (4) penup
        # => (0) move (x,y)->(c,d)  (1) pendown  (2) line (c,d)->(a,b)  (3) penup
        if ( $self->_pattern1( $line, $rest ) ) {
            if ( $self->{opt_debug} ) { print STDOUT "[line $optline pattern 1] $EOL" }
            $tmpx2 = $self->{psegments}[ $line + 2 ]{dx};
            $tmpy2 = $self->{psegments}[ $line + 2 ]{dy};
            $self->_fastmove( $line, $xd, $yd, $tmpx2, $tmpy2 );
            $self->_keep( \$line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_drop( $line,  \$rest );
            $self->_keep( \$line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ( $self->{opt_debug} ) { print STDOUT $EOL }
            next INSTRUCTION;
        }

        # Pattern 3 (result of pattern 1):
        # (0) line (x,y)->(a,b)  (1) penup  (2) move (a,b)->(a,b)  (3) pendown
        # => (0) line (x,y)->(a,b)
        if ( $self->_pattern3( $line, $rest ) ) {
            if ( $self->{opt_debug} ) { print STDOUT "[line $optline pattern 3] $EOL" }
            $self->_keep( \$line, \$rest );
            $self->_drop( $line,  \$rest );
            $self->_drop( $line,  \$rest );
            $self->_drop( $line,  \$rest );
            $self->_adjust( \$line, \$rest );
            if ( $self->{opt_debug} ) { print STDOUT $EOL }
            next INSTRUCTION;
        }

        # Pattern 2:
        # (0) line (x,y)->(a,b)  (1) penup   (2) move (a,b)->(c,d)
        # (3) pendown             (4) line (c,d)->(a,b)  (5) penup
        # => (0) line (x,y)->(a,b)  (1) line (a,b)->(c,d)  (2) penup
        if ( $self->_pattern2( $line, $rest ) ) {
            if ( $self->{opt_debug} ) { print STDOUT "[line $optline pattern 2] $EOL" }
            $self->_keep( \$line, \$rest );
            $self->_drop( $line,  \$rest );
            $tmpx2 = $self->{psegments}[ $line + 0 ]{dx};
            $tmpy2 = $self->{psegments}[ $line + 0 ]{dy};
            $self->_slowmove( $line, $xd, $yd, $tmpx2, $tmpy2 );
            $self->_keep( \$line, \$rest );
            $self->_drop( $line,  \$rest );
            $self->_drop( $line,  \$rest );
            # Fix up the source of the following move if it still references (a,b)
            NEXT4:
            for my $i ( 1 .. 4 ) {
                if (   $self->{psegments}[ $line + $i ]{key} eq 'm'
                    || $self->{psegments}[ $line + $i ]{key} eq 'l' )
                {
                    if (   $self->{psegments}[ $line + $i ]{sx} == $xd
                        && $self->{psegments}[ $line + $i ]{sy} == $yd )
                    {
                        $self->{psegments}[ $line + $i ]{sx} = $tmpx2;
                        $self->{psegments}[ $line + $i ]{sy} = $tmpy2;
                        last NEXT4;
                    }
                }
            }
            $self->_adjust( \$line, \$rest );
            if ( $self->{opt_debug} ) { print STDOUT $EOL }
            next INSTRUCTION;
        }

        # Pattern 4: two moves to the same location -- delete second triple.
        # penup / move(a,b) / pendown / penup / move(a,b) / pendown
        # => penup / move(a,b) / pendown
        if ( $self->_pattern4( $line, $rest ) ) {
            $self->_keep( \$line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_drop( $line,  \$rest );
            $self->_drop( $line,  \$rest );
            $self->_drop( $line,  \$rest );
            $self->_adjust( \$line, \$rest );
            next INSTRUCTION;
        }

        # Pattern 11: two consecutive fast moves -- delete the first triple.
        # penup / move(a,b) / pendown / penup / move(c,d) / pendown
        # => penup / move(a,b -> c,d) / pendown
        if ( $self->_pattern11( $line, $rest ) ) {
            if ( $self->{opt_debug} ) { print STDOUT "[line $optline pattern 11] $EOL" }
            $self->{psegments}[ $line + 4 ]{sx} = $self->{psegments}[ $line + 1 ]{sx};
            $self->{psegments}[ $line + 4 ]{sy} = $self->{psegments}[ $line + 1 ]{sy};
            $self->_drop( $line,  \$rest );
            $self->_drop( $line,  \$rest );
            $self->_drop( $line,  \$rest );
            $self->_keep( \$line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ( $self->{opt_debug} ) { print STDOUT $EOL }
            next INSTRUCTION;
        }

        # Pattern 5: PU/PD -- delete both.
        if ( $self->_pattern5( $line, $rest ) ) {
            if ( $self->{opt_debug} ) { print STDOUT "[line $optline pattern 5] $EOL" }
            $self->_drop( $line, \$rest );
            $self->_drop( $line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ( $self->{opt_debug} ) { print STDOUT $EOL }
            next INSTRUCTION;
        }

        # Pattern 8: PD/PU -- delete both.
        if ( $self->_pattern8( $line, $rest ) ) {
            if ( $self->{opt_debug} ) { print STDOUT "[line $optline pattern 8] $EOL" }
            $self->_drop( $line, \$rest );
            $self->_drop( $line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ( $self->{opt_debug} ) { print STDOUT $EOL }
            next INSTRUCTION;
        }

        # Pattern 6: PU/PU -- delete one.
        if ( $self->_pattern6( $line, $rest ) ) {
            if ( $self->{opt_debug} ) { print STDOUT "[line $optline pattern 6] $EOL" }
            $self->_drop( $line,  \$rest );
            $self->_keep( \$line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ( $self->{opt_debug} ) { print STDOUT $EOL }
            next INSTRUCTION;
        }

        # Pattern 7: PD/PD -- delete one.
        if ( $self->_pattern7( $line, $rest ) ) {
            if ( $self->{opt_debug} ) { print STDOUT "[line $optline pattern 7] $EOL" }
            $self->_drop( $line,  \$rest );
            $self->_keep( \$line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ( $self->{opt_debug} ) { print STDOUT $EOL }
            next INSTRUCTION;
        }

        # Pattern 9: move/line where source == dest -- delete.
        if ( $self->_pattern9( $line, $rest ) ) {
            if ( $self->{opt_debug} ) { print STDOUT "[line $optline pattern 9] $EOL" }
            $self->_drop( $line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ( $self->{opt_debug} ) { print STDOUT $EOL }
            next INSTRUCTION;
        }

        # No pattern matched: advance.
        $line++;
        $rest--;
    }
    if ( $self->{check} ) {
        $after = scalar @{ $self->{psegments} };
        print STDOUT 'optimization removed '
            . ( $before - $after )
            . ' instructions' . $EOL;
    }
    return 1;
}

# ===========================================================================
# PATTERN MATCHERS
# Note: order of testing in _optimize matters -- longest patterns first.
# ===========================================================================

sub _pattern1 ($self, $line, $rest) {
    if ( $rest < 5 ) { return 0 }
    return (
           $self->{psegments}[ $line + 0 ]{key} eq 'm'
        && $self->{psegments}[ $line + 1 ]{key} eq 'd'
        && $self->{psegments}[ $line + 2 ]{key} eq 'l'
        && $self->{psegments}[ $line + 3 ]{key} eq 'l'
        && $self->{psegments}[ $line + 4 ]{key} eq 'u'
        && $self->{psegments}[ $line + 2 ]{dx} == $self->{psegments}[ $line + 0 ]{dx}
        && $self->{psegments}[ $line + 2 ]{dy} == $self->{psegments}[ $line + 0 ]{dy}
        && $self->{psegments}[ $line + 3 ]{dx} == $self->{psegments}[ $line + 2 ]{sx}
        && $self->{psegments}[ $line + 3 ]{dy} == $self->{psegments}[ $line + 2 ]{sy}
    ) ? 1 : 0;
}

sub _pattern2 ($self, $line, $rest) {
    if ( $rest < 6 ) { return 0 }
    return (
           $self->{psegments}[ $line + 0 ]{key} eq 'l'
        && $self->{psegments}[ $line + 1 ]{key} eq 'u'
        && $self->{psegments}[ $line + 2 ]{key} eq 'm'
        && $self->{psegments}[ $line + 3 ]{key} eq 'd'
        && $self->{psegments}[ $line + 4 ]{key} eq 'l'
        && $self->{psegments}[ $line + 5 ]{key} eq 'u'
        && $self->{psegments}[ $line + 2 ]{sx} == $self->{psegments}[ $line + 0 ]{dx}
        && $self->{psegments}[ $line + 2 ]{sy} == $self->{psegments}[ $line + 0 ]{dy}
        && $self->{psegments}[ $line + 4 ]{dx} == $self->{psegments}[ $line + 0 ]{dx}
        && $self->{psegments}[ $line + 4 ]{dy} == $self->{psegments}[ $line + 0 ]{dy}
    ) ? 1 : 0;
}

sub _pattern10 ($self, $line, $rest) {
    if ( $rest < 5 ) { return 0 }
    return (
           $self->{psegments}[ $line + 0 ]{key} eq 'l'
        && $self->{psegments}[ $line + 1 ]{key} eq 'l'
        && $self->{psegments}[ $line + 2 ]{key} eq 'l'
        && $self->{psegments}[ $line + 3 ]{key} eq 'u'
        && $self->{psegments}[ $line + 4 ]{key} eq 'm'
        && $self->{psegments}[ $line + 1 ]{sx} == $self->{psegments}[ $line + 0 ]{dx}
        && $self->{psegments}[ $line + 1 ]{sy} == $self->{psegments}[ $line + 0 ]{dy}
        && $self->{psegments}[ $line + 1 ]{dx} == $self->{psegments}[ $line + 1 ]{sx}
        && $self->{psegments}[ $line + 1 ]{dy} == $self->{psegments}[ $line + 1 ]{sy}
        && $self->{psegments}[ $line + 2 ]{sx} == $self->{psegments}[ $line + 0 ]{dx}
        && $self->{psegments}[ $line + 2 ]{sy} == $self->{psegments}[ $line + 0 ]{dy}
        && $self->{psegments}[ $line + 2 ]{dx} == $self->{psegments}[ $line + 0 ]{sx}
        && $self->{psegments}[ $line + 2 ]{dy} == $self->{psegments}[ $line + 0 ]{sy}
    ) ? 1 : 0;
}

sub _pattern3 ($self, $line, $rest) {
    if ( $rest < 4 ) { return 0 }
    return (
           $self->{psegments}[ $line + 0 ]{key} eq 'l'
        && $self->{psegments}[ $line + 1 ]{key} eq 'u'
        && $self->{psegments}[ $line + 2 ]{key} eq 'm'
        && $self->{psegments}[ $line + 3 ]{key} eq 'd'
        && $self->{psegments}[ $line + 2 ]{dx} == $self->{psegments}[ $line + 0 ]{dx}
        && $self->{psegments}[ $line + 2 ]{dy} == $self->{psegments}[ $line + 0 ]{dy}
    ) ? 1 : 0;
}

sub _pattern4 ($self, $line, $rest) {
    if ( $rest < 6 ) { return 0 }
    return (
           $self->{psegments}[ $line + 0 ]{key} eq 'u'
        && $self->{psegments}[ $line + 3 ]{key} eq 'u'
        && $self->{psegments}[ $line + 2 ]{key} eq 'd'
        && $self->{psegments}[ $line + 5 ]{key} eq 'd'
        && $self->{psegments}[ $line + 1 ]{key} eq 'm'
        && $self->{psegments}[ $line + 4 ]{key} eq 'm'
        && $self->{psegments}[ $line + 1 ]{dx} == $self->{psegments}[ $line + 4 ]{dx}
        && $self->{psegments}[ $line + 1 ]{dy} == $self->{psegments}[ $line + 4 ]{dy}
    ) ? 1 : 0;
}

sub _pattern11 ($self, $line, $rest) {
    if ( $rest < 6 ) { return 0 }
    return (
           $self->{psegments}[ $line + 0 ]{key} eq 'u'
        && $self->{psegments}[ $line + 3 ]{key} eq 'u'
        && $self->{psegments}[ $line + 2 ]{key} eq 'd'
        && $self->{psegments}[ $line + 5 ]{key} eq 'd'
        && $self->{psegments}[ $line + 1 ]{key} eq 'm'
        && $self->{psegments}[ $line + 4 ]{key} eq 'm'
    ) ? 1 : 0;
}

sub _pattern5 ($self, $line, $rest) {
    if ( $rest < 2 ) { return 0 }
    return (
           $self->{psegments}[ $line + 0 ]{key} eq 'u'
        && $self->{psegments}[ $line + 1 ]{key} eq 'd'
    ) ? 1 : 0;
}

sub _pattern6 ($self, $line, $rest) {
    if ( $rest < 2 ) { return 0 }
    return (
           $self->{psegments}[ $line + 0 ]{key} eq 'u'
        && $self->{psegments}[ $line + 1 ]{key} eq 'u'
    ) ? 1 : 0;
}

sub _pattern7 ($self, $line, $rest) {
    if ( $rest < 2 ) { return 0 }
    return (
           $self->{psegments}[ $line + 0 ]{key} eq 'd'
        && $self->{psegments}[ $line + 1 ]{key} eq 'd'
    ) ? 1 : 0;
}

sub _pattern8 ($self, $line, $rest) {
    if ( $rest < 2 ) { return 0 }
    return (
           $self->{psegments}[ $line + 0 ]{key} eq 'd'
        && $self->{psegments}[ $line + 1 ]{key} eq 'u'
    ) ? 1 : 0;
}

sub _pattern9 ($self, $line, $rest) {
    if ( $rest < 1 ) { return 0 }
    return (
        (   $self->{psegments}[ $line + 0 ]{key} eq 'm'
         || $self->{psegments}[ $line + 0 ]{key} eq 'l' )
        && $self->{psegments}[ $line + 0 ]{sx} == $self->{psegments}[ $line + 0 ]{dx}
        && $self->{psegments}[ $line + 0 ]{sy} == $self->{psegments}[ $line + 0 ]{dy}
    ) ? 1 : 0;
}

# ===========================================================================
# WINDOW MANAGEMENT
# ===========================================================================

# Retract the window pointer by $LONGEST after a match, so that newly
# created optimisable sequences are not missed (cf. Tanenbaum peephole).
sub _adjust ($self, $lref, $rref) {
    my $len = scalar @{ $self->{psegments} };
    ${$lref} -= $LONGEST;
    ${$rref}  = $len - $$lref;
    if ( ${$lref} < $OPTLOW ) {
        ${$lref} = $OPTLOW;
        ${$rref} = $len - $OPTLOW;
    }
    return 1;
}

# Return the fields of the segment at $line as a flat list.
sub _curseg ($self, $line) {
    return (
        $self->{psegments}[$line]{key},
        $self->{psegments}[$line]{sx},
        $self->{psegments}[$line]{sy},
        $self->{psegments}[$line]{dx},
        $self->{psegments}[$line]{dy},
    );
}

# ===========================================================================
# IN-PLACE SEGMENT MUTATORS
# ===========================================================================

# Rewrite segment $line as a slow (G01) move.
sub _slowmove ($self, $line, $xs, $ys, $x, $y) {
    $self->{psegments}[$line]{key} = 'l';
    $self->{psegments}[$line]{sx}  = $xs;
    $self->{psegments}[$line]{sy}  = $ys;
    $self->{psegments}[$line]{dx}  = $x;
    $self->{psegments}[$line]{dy}  = $y;
    return 1;
}

# Rewrite segment $line as a fast (G00) move.
sub _fastmove ($self, $line, $xs, $ys, $x, $y) {
    $self->{psegments}[$line]{key} = 'm';
    $self->{psegments}[$line]{sx}  = $xs;
    $self->{psegments}[$line]{sy}  = $ys;
    $self->{psegments}[$line]{dx}  = $x;
    $self->{psegments}[$line]{dy}  = $y;
    return 1;
}

# Delete segment at $line; $rest is decremented via its reference.
sub _drop ($self, $line, $refrest) {
    if ( $self->{opt_debug} ) {
        print STDOUT 'drop ';
        $self->_prPseg($line);
    }
    splice @{ $self->{psegments} }, $line, 1;
    ${$refrest} -= 1;
    return 1;
}

# Advance past segment at $line without deleting it; $rest is decremented.
sub _keep ($self, $line, $refrest) {
    if ( $self->{opt_debug} ) {
        print STDOUT 'keep ';
        $self->_prPseg( ${$line} );
    }
    ${$line}    += 1;
    ${$refrest} -= 1;
    return 1;
}

# ===========================================================================
# DEBUGGING
# ===========================================================================

sub _prPseg ($self, $index) {
    my $len = scalar @{ $self->{psegments} };
    if ( $index > $len - 1 || !defined $self->{psegments}[$index]{key} ) {
        print STDOUT "    UNDEFINED$EOL";
        return 0;
    }
    if ( $self->{psegments}[$index]{key} eq 'u' ) {
        print STDOUT "    $index: PENUP$EOL";
        return 1;
    }
    if ( $self->{psegments}[$index]{key} eq 'd' ) {
        print STDOUT "    $index: PENDOWN$EOL";
        return 1;
    }
    printf STDOUT "    %d: %s (%5.2f,%5.2f) -> (%5.2f,%5.2f)$EOL",
        $index,
        $self->{psegments}[$index]{key},
        $self->{psegments}[$index]{sx},
        $self->{psegments}[$index]{sy},
        $self->{psegments}[$index]{dx},
        $self->{psegments}[$index]{dy};
    return 1;
}


1;

__END__

=head1 NAME

Graphics::Penplotter::GcodeXY::Optimize - Segment-queue peephole optimiser for GcodeXY

=head1 SYNOPSIS

    # The optimiser is called automatically by _flushPsegments; no
    # user-facing API change.

=head1 DESCRIPTION

A L<Role::Tiny> role providing the peephole optimiser for the internal
segment queue of L<Graphics::Penplotter::GcodeXY>.

The optimiser is applied automatically by C<_flushPsegments> immediately
before gcode generation.  It makes a single pass over the C<psegments>
array, matching a set of named patterns and rewriting or deleting
redundant instructions.  After each match the window is retracted by
C<$LONGEST> positions so that newly formed optimisable sequences are not
missed (Tanenbaum-style peephole).

The following patterns are recognised (tested longest-first):

=over 4

=item Pattern 10

A line immediately followed by a zero-length line and its reverse, then a
pen-up and a move.  Removes the redundant lines and fixes up the following
move's source.

=item Pattern 1

A move + pendown followed by a line and its reverse + penup (a line drawn
twice, common in single-stroke fonts).  Replaced by a single line.

=item Pattern 3

The canonical result of pattern 1: a line followed by PU/move(same)/PD.
The PU/move/PD triple is deleted.

=item Pattern 2

A line followed by PU/move/PD/line(back)/PU, a pen lifted unnecessarily.
Merged into two consecutive lines.

=item Patterns 4 and 11

Two consecutive fast-move triples (PU/move/PD), pattern 4 deletes the
second when both land at the same point; pattern 11 merges them when they
differ.

=item Patterns 5 and 8

Adjacent PU/PD or PD/PU pairs, both deleted.

=item Patterns 6 and 7

Adjacent PU/PU or PD/PD pairs, one deleted.

=item Pattern 9

A move or line whose source and destination are identical, deleted.

=back

=head1 CONFIGURATION

The optimiser respects the following object attributes:

=over 4

=item C<optimize>

Set to C<0> to disable the optimiser entirely.  Default is C<1>.

=item C<check>

When set, prints the number of instructions removed to STDOUT.

=item C<opt_debug>

When set, prints a per-instruction trace to STDOUT.

=back

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com)

=head1 LICENSE

Same terms as Perl itself.

=cut
