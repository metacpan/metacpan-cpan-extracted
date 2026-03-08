package Graphics::Penplotter::GcodeXY::Postscript v0.7.2;

use v5.38.2;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use strict;
use warnings;
use Role::Tiny;
use Carp        qw( croak );
use POSIX       qw( floor ceil );
use Readonly    qw( Readonly );

# ---------------------------------------------------------------------------
# Graphics::Penplotter::GcodeXY::Postscript
# Role providing PostScript / EPS export for GcodeXY.
# ---------------------------------------------------------------------------

requires qw( _parse _flushPsegments _checkp _checkl);

# ---------------------------------------------------------------------------
# Constants -- private copies of the values defined in GcodeXY.pm.
# These must remain identical to their counterparts in the main module.
# ---------------------------------------------------------------------------

Readonly my $I2P   => 72.0;        # inches to PostScript points
Readonly my $BBMAX => 1_000_000.0; # sentinel for bounding-box minimum
Readonly my $EOL   => qq{\n};

# _parse() return opcodes -- must match the values in GcodeXY.pm exactly
Readonly my $PU    => 1;   # penup
Readonly my $PD    => 2;   # pendown
Readonly my $G00   => 3;   # fast move
Readonly my $G01   => 4;   # draw move
Readonly my $NOOP  => 5;   # ignored line

# ---------------------------------------------------------------------------
# Paper sizes in points [width, height] -- copied from GcodeXY.pm.
# ---------------------------------------------------------------------------

my %pspaper = (
    '4A0' => [ 4768, 6741 ],
    '2A0' => [ 3370, 4768 ],
    A0    => [ 2384, 3370 ],
    A1    => [ 1684, 2384 ],
    A2    => [ 1191, 1684 ],
    A3    => [  841, 1190 ],
    A4    => [  595,  841 ],
);

# Sorted smallest-first for best-fit reporting -- mirrors @a_sizes in GcodeXY.pm
my @a_sizes = (
    { name => 'A4',  width =>  595, height =>  842 },
    { name => 'A3',  width =>  842, height => 1191 },
    { name => 'A2',  width => 1191, height => 1684 },
    { name => 'A1',  width => 1684, height => 2384 },
    { name => 'A0',  width => 2384, height => 3370 },
    { name => '2A0', width => 3370, height => 4768 },
    { name => '4A0', width => 4768, height => 6741 },
);

# ---------------------------------------------------------------------------
# exporteps($filename)
#
# Export the current drawing as a DSC 3.0 compliant Encapsulated PostScript
# file.  See eps.pl for a full description of every design decision.
#
# Returns a four-element list: (llx_pt, lly_pt, urx_pt, ury_pt) as floats,
# matching the return convention of exportsvg().
# ---------------------------------------------------------------------------

sub exporteps ($self, $gcout = undef) {

    croak 'exporteps: filename not provided' unless $gcout;

    # Flush any pending segments so currentpage is complete.
    $self->_flushPsegments();

    my $limit = scalar @{ $self->{currentpage} };
    croak "exporteps: $gcout: empty queue. Aborting." unless $limit;

    # ------------------------------------------------------------------
    # Pass 1: scan currentpage for the true bounding box.
    # We skip the gcode header (everything up to and including the first
    # penupcmd sentinel written by _openpage()).
    # ------------------------------------------------------------------
    my $maxx = 0.0;
    my $maxy = 0.0;
    my $minx = $BBMAX;
    my $miny = $BBMAX;

    my $linecount = 0;
    HEADER_SCAN:
    while ($linecount < $limit) {
        $linecount++;
        last HEADER_SCAN
            if $self->{currentpage}[$linecount - 1] eq $self->{penupcmd};
    }

    for my $i ($linecount .. $limit - 1) {
        my ($op, $xn, $yn) = $self->_parse( $self->{currentpage}[$i] );
        next unless $op eq $G00 || $op eq $G01;
        my $x = $xn + 0.0;
        my $y = $yn + 0.0;
        $maxx = $x if $x > $maxx;
        $maxy = $y if $y > $maxy;
        $minx = $x if $x < $minx;
        $miny = $y if $y < $miny;
    }

    # Convert to points
    croak "exporteps: $gcout: no drawing found (no G00/G01 coordinates in page)"
        if $minx >= $BBMAX;

    my $bbllx_f = $minx * $I2P;
    my $bblly_f = $miny * $I2P;
    my $bburx_f = $maxx * $I2P;
    my $bbuly_f = $maxy * $I2P;

    # DSC requires integer bounding box values.
    # floor the minimums, ceil the maximums (conservative outer bound).
    my $bbllx = floor($bbllx_f);
    my $bblly = floor($bblly_f);
    my $bburx = ceil($bburx_f);
    my $bbuly = ceil($bbuly_f);

    # ------------------------------------------------------------------
    # Paper media comment (informational only -- no device operators).
    # ------------------------------------------------------------------
    my $media_comment = '';
    if ( defined $self->{papersize} ) {
        my $ps = uc $self->{papersize};
        if ( defined $pspaper{$ps} ) {
            my ($pw, $ph) = @{ $pspaper{$ps} };
            $media_comment = "%%PageMedia: $ps $pw $ph 80 () ()\n";
        }
    }

    # ------------------------------------------------------------------
    # Pass 2: write the EPS file.
    # ------------------------------------------------------------------
    open( my $out, '>', $gcout )
        or croak "exporteps: cannot open '$gcout': $!";

    # --- DSC header ---------------------------------------------------
    # The magic comment must be on the very first line, no leading space.
    print {$out} "%!PS-Adobe-3.0 EPSF-3.0\n";
    print {$out} "%%BoundingBox: $bbllx $bblly $bburx $bbuly\n";
    printf {$out} "%%%%HiResBoundingBox: %.4f %.4f %.4f %.4f\n",
        $bbllx_f, $bblly_f, $bburx_f, $bbuly_f;

    my $creator = 'Graphics::Penplotter::GcodeXY';
    $creator   .= " id=$self->{id}" if $self->{id};
    print {$out} "%%Creator: ($creator)\n";
    print {$out} "%%Title: ($gcout)\n";

    {
        my @t = localtime;
        printf {$out} "%%%%CreationDate: %04d-%02d-%02d %02d:%02d:%02d\n",
            $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0];
    }

    print {$out} "%%LanguageLevel: 1\n";
    print {$out} "%%Pages: 1\n";
    print {$out} $media_comment if $media_comment;
    print {$out} "%%EndComments\n";
    print {$out} "%%BeginProlog\n";
    print {$out} "%%EndProlog\n";
    print {$out} "%%Page: 1 1\n";

    # --- Graphics state -----------------------------------------------
    my $lw = $self->{eps_linewidth} // 0.3;
    printf {$out} "%.4f setlinewidth\n", $lw;
    print {$out} "1 setlinecap\n";     # round
    print {$out} "1 setlinejoin\n";    # round

    # --- Body ---------------------------------------------------------
    my $path_open = 0;

    $linecount = 0;
    HEADER_BODY:
    while ($linecount < $limit) {
        $linecount++;
        last HEADER_BODY
            if $self->{currentpage}[$linecount - 1] eq $self->{penupcmd};
    }

    while ($linecount < $limit) {
        $linecount++;
        my $line = $self->{currentpage}[$linecount - 1];
        my ($op, $xn, $yn) = $self->_parse($line);

        if ($op eq $PU) {
            if ($path_open) {
                print {$out} "stroke\n";
                $path_open = 0;
            }
        }
        elsif ($op eq $G00) {
            if ($path_open) {
                print {$out} "stroke\n";
            }
            printf {$out} "newpath %.4f %.4f moveto\n",
                $xn * $I2P, $yn * $I2P;
            $path_open = 1;
        }
        elsif ($op eq $G01) {
            printf {$out} "%.4f %.4f lineto\n",
                $xn * $I2P, $yn * $I2P;
        }
        # $PD and $NOOP: nothing to emit
    }

    # Close any still-open path; no showpage in EPS.
    if ($path_open) {
        print {$out} "stroke\n";
    }

    print {$out} "%%Trailer\n";
    print {$out} "%%EOF\n";

    close $out;

    # --- Diagnostics --------------------------------------------------
    if ( $self->{check} ) {
        printf STDOUT "exporteps: %s: bounding box = (%.3f,%.3f) (%.3f,%.3f) pt\n",
            $gcout, $bbllx_f, $bblly_f, $bburx_f, $bbuly_f;
        $self->_checkp();
        $self->_checkl();
    }

    return ($bbllx_f, $bblly_f, $bburx_f, $bbuly_f);
}

1;

__END__

=head1 NAME

Graphics::Penplotter::GcodeXY::Postscript - EPS export role for GcodeXY

=head1 SYNOPSIS

    $g->exporteps('output.eps');

=head1 DESCRIPTION

A L<Role::Tiny> role that adds the C<exporteps> method to
L<Graphics::Penplotter::GcodeXY>.  The generated file is a DSC 3.0
compliant Encapsulated PostScript document, suitable for embedding in
LaTeX, Inkscape, LibreOffice, and commercial print workflows.

Key properties of the output:

=over 4

=item *

C<%%BoundingBox> contains integer values (floor of min, ceil of max) as
required by the DSC specification.

=item *

C<%%HiResBoundingBox> carries the full-precision floating-point values.

=item *

No C<showpage> -- EPS files must not call showpage.

=item *

No C<setpagedevice> -- EPS files must be device-independent.

=item *

All required DSC structural comments are present: C<%%EndComments>,
C<%%Trailer>, C<%%EOF>.

=back

=head1 METHODS

=over 4

=item ($llx, $lly, $urx, $ury) = exporteps($filename)

Write the current drawing to C<$filename> as EPS.  Returns the bounding
box in PostScript points as a four-element list (matching the return
convention of C<exportsvg>).

The optional object attribute C<eps_linewidth> controls the line width in
points (default 0.3pt).

=back

=head1 REQUIRED METHODS

This role requires the consuming class to provide:
C<_parse>, C<_flushPsegments>, C<_checkp>, C<_checkl>.

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com)

=head1 LICENSE

Same terms as Perl itself.

=cut
