package Graphics::Penplotter::GcodeXY::Vpype v0.7.2;

use v5.38.2;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use strict;
use warnings;
use Role::Tiny;
use Carp        qw( croak );
use File::Temp  qw( tempfile );

# ---------------------------------------------------------------------------
# Graphics::Penplotter::GcodeXY::Vpype
# Role providing the vpype line-sort interface for GcodeXY.
# ---------------------------------------------------------------------------

requires qw(exportsvg importsvg _croak);

# ---------------------------------------------------------------------------
# Readonly my $EMPTY_STR -- private copy of the constant in GcodeXY.pm.
# ---------------------------------------------------------------------------

use Readonly qw( Readonly );
Readonly my $EMPTY_STR => q{};


# ===========================================================================
# PUBLIC METHOD
# ===========================================================================

# Run vpype's linemerge+linesort pipeline on the current drawing and return
# a new GcodeXY object containing the optimised path.
#
# Requires vpype to be installed and on $PATH.
# Returns a new object of the same class.
sub vpype_linesort ($self) {
    # Create two temporary SVG files: one for input, one for output.
    my ($fh_in,  $vin)  = tempfile( SUFFIX => '.svg' );
    my ($fh_out, $vout) = tempfile( SUFFIX => '.svg' );
    close $fh_in  if defined $fh_in;
    close $fh_out if defined $fh_out;

    # Export the current drawing to the input temp file.
    $self->exportsvg($vin);

    # Build the vpype command.
    my @cmd = (
        'vpype',
        'read',      $vin,
        'linemerge', '-t', '0.01mm',
        'linesort',
        'write',     '--format', 'svg', $vout,
    );
    if ( defined $self->{papersize} && $self->{papersize} ne $EMPTY_STR ) {
        splice @cmd, -2, 0, '--page-size', lc $self->{papersize};
    }

    # Run vpype.
    my $rc = system(@cmd);
    if ( $rc != 0 ) {
        unlink $vin  if -e $vin;
        unlink $vout if -e $vout;
        $self->_croak("vpype_linesort: vpype command failed (exit=$rc)");
    }

    # Instantiate a new object of the same class and import vpype's output.
    my $class = ref($self) || $self;
    my $v = $class->new(
        papersize     => $self->{papersize},
        xsize         => $self->{xsize},
        ysize         => $self->{ysize},
        units         => $self->{units},
        header        => $self->{header},
        trailer       => $self->{trailer},
        penupcmd      => $self->{penupcmd},
        pendowncmd    => $self->{pendowncmd},
        margin        => $self->{margin},
        curvepts      => $self->{curvepts},
        check         => $self->{check},
        warn          => $self->{warn},
        hatchsep      => $self->{hatchsep},
        id            => 'vpype-linesort',
        optimize      => $self->{optimize},
        dscale        => $self->{dscale},
        opt_debug     => $self->{opt_debug},
        fontsize      => $self->{fontsize},
        fontname      => $self->{fontname},
    );
    $v->importsvg($vout);

    # Clean up temp files.
    unlink $vin  if -e $vin;
    unlink $vout if -e $vout;

    return $v;
}


1;

__END__

=head1 NAME

Graphics::Penplotter::GcodeXY::Vpype - vpype integration for GcodeXY

=head1 SYNOPSIS

    my $sorted = $g->vpype_linesort();
    $sorted->output('sorted.gcode');

=head1 DESCRIPTION

A L<Role::Tiny> role that integrates the external B<vpype> tool with
L<Graphics::Penplotter::GcodeXY>.

C<vpype_linesort> exports the current drawing to a temporary SVG file,
passes it through vpype's C<linemerge> and C<linesort> pipeline to
minimise pen-travel distance, then imports the result into a fresh
GcodeXY object and returns it.  The original object is left unmodified.

B<vpype> must be installed and available on C<$PATH>.  See
L<https://vpype.readthedocs.io/> for installation instructions.

=head1 METHODS

=over 4

=item $sorted = vpype_linesort()

Run vpype's C<linemerge -t 0.01mm linesort> pipeline on the current
drawing.  If C<papersize> is set on the object the C<--page-size> option
is passed to vpype's C<write> command.

Returns a new object of the same class, with C<id> set to
C<'vpype-linesort'> and all other construction parameters copied from the
caller.  The caller is not modified.

Croaks if vpype exits with a non-zero status.

=back

=head1 REQUIRED METHODS

This role requires the consuming class to provide:
C<exportsvg>, C<importsvg>, C<_croak>.

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com)

=head1 LICENSE

Same terms as Perl itself.

=cut
