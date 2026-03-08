package Graphics::Penplotter::GcodeXY::Split v0.7.2;

use v5.38.2;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use strict;
use warnings;
use Role::Tiny;
use Carp     qw( croak );
use Readonly qw( Readonly );

# ---------------------------------------------------------------------------
# Graphics::Penplotter::GcodeXY::Split
# Role providing page-splitting for GcodeXY.
# ---------------------------------------------------------------------------

requires qw( _croak stroke _parse _addpath _addtopage output penup pendown _LiangBarsky);

# ---------------------------------------------------------------------------
# Constants -- private copies of the values defined in GcodeXY.pm.
# These must remain identical to their counterparts in the main module.
# ---------------------------------------------------------------------------

Readonly my $EMPTY_STR => q{};
Readonly my $EOL       => qq{\n};
Readonly my $SPACE     => q{ };

# _parse() return opcodes
Readonly my $PU   => 1;
Readonly my $PD   => 2;
Readonly my $G00  => 3;
Readonly my $G01  => 4;
Readonly my $NOOP => 5;

# Virtual / physical pen states
Readonly my $IN      => 0;   # virtual pen is inside the sheet
Readonly my $OUT     => 1;   # virtual pen is outside the sheet
Readonly my $PENUP   => 3;   # physical pen is off the paper
Readonly my $PENDOWN => 4;   # physical pen is on the paper

# ---------------------------------------------------------------------------
# Module-level state for the sheet-splitting algorithm.
# All variables are reset inside split() before each run.
# ---------------------------------------------------------------------------

my $location  = $IN;
my $penstate  = $PENUP;
my $previous  = $EMPTY_STR;
my $prevx     = 0.0;
my $prevy     = 0.0;
my $prevop    = $PU;
my $current   = $EMPTY_STR;
my $currx     = 0.0;
my $curry     = 0.0;
my $curop;
my $linecount = 1;
my $len       = 2;
my $mode;
my $op        = $PU;
my $xn        = $EMPTY_STR;
my $yn        = $EMPTY_STR;

my $scale;
my %corner    = ();
my %sheets    = ();
my ( $sx,      $sy );
my ( $xoffset, $yoffset );
my ( $xwhite,  $ywhite );
my ( $xlen,    $ylen );


# ===========================================================================
# PUBLIC ENTRY POINT
# ===========================================================================

sub split ($self, $dest, $file) {
    croak 'split: wrong number of args'          unless defined $file;
    croak 'split: cannot split if papersize undefined'
        unless defined $self->{papersize};

    $self->_sheetinfo($dest);

    croak "split: cannot handle sheet size: $dest"
        unless defined $sheets{$dest};
    croak 'split: cannot split paper into LARGER pieces of paper'
        if $sheets{$dest}{rank} > $sheets{ $self->{papersize} }{rank};

    if ($sheets{$dest}{rank} == $sheets{ $self->{papersize} }{rank}) {
        $self->_croak('split: paper sizes are the same. Finished.');
        return 1;
    }

    $self->stroke();          # flush the segment queue to currentpage
    $self->_corners($dest);   # set up %corner, $sx, $sy, $mode

    foreach my $i ( 0 .. $sx - 1 ) {
        foreach my $j ( 0 .. $sy - 1 ) {

            # Distance from the bottom-left of the big sheet to this sub-sheet
            $xoffset = $corner{$i}{$j}{blx};
            $yoffset = $corner{$i}{$j}{bly};

            # Reset all per-sheet state
            $location = ( $i == 0 && $j == 0 ) ? $IN : $OUT;
            $prevx    = 0.0;
            $prevy    = 0.0;
            $prevop   = $PU;
            $current  = $EMPTY_STR;
            $penstate = $PENUP;

            # Create a fresh GcodeXY object to hold this sub-sheet's gcode
            my $class = ref($self);
            my $f = $class->new(
                header     => $self->{header},
                trailer    => $self->{trailer},
                penupcmd   => $self->{penupcmd},
                pendowncmd => $self->{pendowncmd},
                margin     => $self->{margin},
                outfile    => $file . '_' . $i . '_' . $j . '.gcode',
            );

            my ( $x1, $y1, $x2, $y2, $info );
            $len       = scalar @{ $self->{currentpage} };
            $linecount = 1;    # skip the gcode header entry

            LINE:
            while ( $linecount <= $len - 1 ) {
                $self->_setprevious( $op, $xn, $yn );
                $current = $self->{currentpage}[$linecount];
                ( $op, $xn, $yn ) = $f->_parse($current);

                if ( $op == $PU ) {
                    next LINE if $location == $OUT;
                    $f->do_penup();
                    next LINE;
                }
                if ( $op == $PD ) {
                    next LINE if $location == $OUT;
                    $f->do_pendown();
                    next LINE;
                }

                # G00 or G01: clip against this sub-sheet boundary
                ( $x1, $y1, $x2, $y2, $info ) = $f->_LiangBarsky(
                    $corner{$i}{$j}{blx}, $corner{$i}{$j}{bly},
                    $corner{$i}{$j}{trx}, $corner{$i}{$j}{try},
                    $prevx, $prevy, $xn, $yn
                );

                if ( $info == 1 || $info == 3 ) {
                    # Start inside boundary
                    if ( $op == $G00 ) {
                        $f->do_penup() if $penstate == $PENDOWN;
                        $f->_addfastmove( $x2, $y2 );
                    }
                    else {    # G01
                        $f->do_pendown() if $penstate == $PENUP;
                        $f->_addslowmove( $x2, $y2 );
                    }
                    $location = ( $info == 3 ) ? $OUT : $IN;
                }
                elsif ( $info == 2 ) {
                    # Entirely outside
                    $f->do_penup() if $location == $IN && $penstate == $PENDOWN;
                    $location = $OUT;
                }
                elsif ( $info == 4 ) {
                    # Start outside, end inside
                    if ( $op == $G00 ) {
                        $f->do_penup() if $penstate == $PENDOWN;
                        $f->_addfastmove( $x2, $y2 );
                    }
                    else {    # G01
                        $f->do_penup() if $penstate == $PENDOWN;
                        $f->_addfastmove( $x1, $y1 );
                        $f->do_pendown();
                        $f->_addslowmove( $x2, $y2 );
                    }
                    $location = $IN;
                }
                elsif ( $info == 5 ) {
                    # Both endpoints outside but crossing through
                    if ( $op == $G01 ) {
                        $f->do_penup() if $penstate == $PENDOWN;
                        $f->_addfastmove( $x1, $y1 );
                        $f->do_pendown();
                        $f->_addslowmove( $x2, $y2 );
                    }
                    # G00 entirely outside: ignore
                    $location = $OUT;
                }
            }
            continue { $linecount++ }

            $f->_addtopage( $f->{trailer} );
            $f->output();

        }    # foreach $j
    }    # foreach $i

    return 1;
}


# ===========================================================================
# PEN STATE WRAPPERS
# (distinct from GcodeXY::penup/pendown -- these also track $penstate)
# ===========================================================================

sub do_penup ($self) {
    $self->_addpath( 'u', -1, -1, -1, -1 );
    $penstate = $PENUP;
    return 1;
}

sub do_pendown ($self) {
    $self->_addpath( 'd', -1, -1, -1, -1 );
    $penstate = $PENDOWN;
    return 1;
}


# ===========================================================================
# COORDINATE HELPERS
# ===========================================================================

# Generate one move (fast or slow), translating from big-sheet coordinates
# to sub-sheet coordinates, applying scale and whitespace margin.
sub _addmove ($self, $x, $y, $speed) {
    my ( $newx, $newy );
    if ( $mode eq 'p' ) {
        $newx = ( $x - $xoffset ) * $scale + $xwhite;
        $newy = ( $y - $yoffset ) * $scale + $ywhite;
    }
    else {    # 'l' -- landscape: swap axes
        $newx = ( $y - $yoffset ) * $scale + $xwhite;
        $newy = ( $xoffset + $xlen - $x ) * $scale + $ywhite;
    }
    if ( $speed eq 'slow' ) {
        $self->_addpath( 'l', $prevx, $prevy, $newx, $newy );
    }
    else {
        $self->_addpath( 'm', $prevx, $prevy, $newx, $newy );
    }
    return 1;
}

sub _addslowmove ($self, $x, $y) {
    $self->_addmove( $x, $y, 'slow' );
    return 1;
}

sub _addfastmove ($self, $x, $y) {
    $self->_addmove( $x, $y, 'fast' );
    return 1;
}

# Record the previous coordinates before they are overwritten by the next line.
sub _setprevious ($self, $op, $xn, $yn) {
    return if $current eq $EMPTY_STR;
    return if $current eq $self->{penupcmd} || $current eq $self->{pendowncmd};
    $previous = $current;
    $prevop   = $op;
    $prevx    = $xn;
    $prevy    = $yn;
    return 1;
}


# ===========================================================================
# SETUP HELPERS
# ===========================================================================

# Populate %sheets with dimensions (in inches) and ranking for every
# supported paper size.
sub _sheetinfo ($self, $dest) {
    $sheets{'4A0'} = { rank => 12, maxx => 66.22, maxy => 93.62 };
    $sheets{'2A0'} = { rank => 11, maxx => 46.81, maxy => 66.22 };
    $sheets{'A0'}  = { rank => 10, maxx => 33.11, maxy => 46.81 };
    $sheets{'A1'}  = { rank => 9,  maxx => 23.39, maxy => 33.11 };
    $sheets{'A2'}  = { rank => 8,  maxx => 16.54, maxy => 23.39 };
    $sheets{'A3'}  = { rank => 7,  maxx => 11.69, maxy => 16.54 };
    $sheets{'A4'}  = { rank => 6,  maxx => 8.27,  maxy => 11.69 };
    $sheets{'A5'}  = { rank => 5,  maxx => 5.83,  maxy => 8.27  };
    $sheets{'A6'}  = { rank => 4,  maxx => 4.13,  maxy => 5.83  };
    $scale  = 1.0 - 0.02 * $self->{margin};
    $xwhite = ( 1.0 - $scale ) * $sheets{$dest}{maxx} / 2.0;
    $ywhite = ( 1.0 - $scale ) * $sheets{$dest}{maxy} / 2.0;
    return 1;
}

# Compute the corner coordinates of every sub-sheet on the big sheet.
sub _corners ($self, $dest) {
    my $bigsheet = $self->{papersize};
    my $diff     = $sheets{$bigsheet}{rank} - $sheets{$dest}{rank};

    $mode = 'p';
    if ( $diff % 2 ) {    # odd rank difference => landscape rotation needed
        $sx   = ( $diff > 1 ) ? $diff - 1 : 1;
        $sy   = 2 * $sx;
        $mode = 'l';
    }
    else {                # even rank difference => portrait
        $sx = $diff;
        $sy = $diff;
    }

    if ( $mode eq 'p' ) {
        $xlen = $sheets{$dest}{maxx};
        $ylen = $sheets{$dest}{maxy};
    }
    else {
        $xlen = $sheets{$dest}{maxy};
        $ylen = $sheets{$dest}{maxx};
    }

    foreach my $i ( 0 .. $sx - 1 ) {
        foreach my $j ( 0 .. $sy - 1 ) {
            $corner{$i}{$j}{blx} = $i * $xlen;
            $corner{$i}{$j}{bly} = $j * $ylen;
            $corner{$i}{$j}{tlx} = $corner{$i}{$j}{blx};
            $corner{$i}{$j}{tly} = ( $j + 1 ) * $ylen;
            $corner{$i}{$j}{trx} = ( $i + 1 ) * $xlen;
            $corner{$i}{$j}{try} = $corner{$i}{$j}{tly};
            $corner{$i}{$j}{brx} = $corner{$i}{$j}{trx};
            $corner{$i}{$j}{bry} = $corner{$i}{$j}{bly};
        }
    }
    return 1;
}


# ===========================================================================
# DEBUGGING
# ===========================================================================

sub printcorner ($self, $sx, $sy) {
    foreach my $i ( 0 .. $sx - 1 ) {
        foreach my $j ( 0 .. $sy - 1 ) {
            print STDOUT "$i $j      "
                . $corner{$i}{$j}{blx} . $SPACE
                . $corner{$i}{$j}{bly} . ( $SPACE x 5 )
                . $corner{$i}{$j}{trx} . $SPACE
                . $corner{$i}{$j}{try} . $SPACE
                . $EOL;
        }
    }
    return 1;
}


1;

__END__

=head1 NAME

Graphics::Penplotter::GcodeXY::Split - Page-splitting role for GcodeXY

=head1 SYNOPSIS

    $g->split('A4', 'output');
    # Produces output_0_0.gcode, output_0_1.gcode, etc.

=head1 DESCRIPTION

A L<Role::Tiny> role that adds the C<split> method to
L<Graphics::Penplotter::GcodeXY>.  Given a drawing on a large sheet
(e.g. A0) and a target smaller sheet size (e.g. A4), C<split> uses the
Liang-Barsky line-clipping algorithm to divide the drawing across as many
output files as needed to cover the big sheet, one file per sub-sheet.
=head1 METHODS

=over 4

=item split(size, filestem)

Divide the current drawing across multiple output gcode files sized to
C<size> (e.g. C<'A4'>).  Output files are named
C<< filestem_I<i>_I<j>.gcode >>.  The source object must have
C<papersize> set.

=back

=head1 REQUIRED METHODS

This role requires the consuming class to provide:
C<_croak>, C<stroke>, C<_parse>, C<_addpath>, C<_addtopage>, C<output>,
C<penup>, C<pendown>, C<_LiangBarsky>.

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com)

=head1 LICENSE

Same terms as Perl itself.

=cut
