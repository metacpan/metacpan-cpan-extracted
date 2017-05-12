package Math::PhaseOnlyCorrelation;

use warnings;
use strict;
use Carp;
use Exporter;
use Math::FFT;
use List::MoreUtils qw/mesh/;

use vars qw/$VERSION @ISA @EXPORT_OK/;

BEGIN {
    $VERSION   = '0.06';
    @ISA       = qw{Exporter};
    @EXPORT_OK = qw{poc poc_without_fft};
}

sub poc_without_fft {
    my ( $f, $g ) = @_;

    croak 'Both of length of array must be equal.' if ( $#$f != $#$g );
    return _poc( $f, $g, $#$f );
}

sub poc {
    my ( $ref_f, $ref_g ) = @_;

    my @f = @{$ref_f};
    my @g = @{$ref_g};

    my ( $length, $f, $g ) = _adjust_array_length( \@f, \@g );
    my $image_array = _get_zero_array($length);
    @f = mesh( @$f, @$image_array );
    @g = mesh( @$g, @$image_array );

    my $f_fft = Math::FFT->new( \@f );
    my $g_fft = Math::FFT->new( \@g );

    my $result = poc_without_fft( $f_fft->cdft(), $g_fft->cdft() );
    my $result_fft = Math::FFT->new($result);

    return $result_fft->invcdft($result);
}

sub _poc {
    my ( $f, $g, $length ) = @_;

    my $result;
    for ( my $i = 0 ; $i <= $length ; $i += 2 ) {
        my $f_abs =
          sqrt( $f->[$i] * $f->[$i] + $f->[ $i + 1 ] * $f->[ $i + 1 ] );
        my $g_abs =
          sqrt( $g->[$i] * $g->[$i] + $g->[ $i + 1 ] * $g->[ $i + 1 ] );
        my $f_real  = $f->[$i] / $f_abs;
        my $f_image = $f->[ $i + 1 ] / $f_abs;
        my $g_real  = $g->[$i] / $g_abs;
        my $g_image = $g->[ $i + 1 ] / $g_abs;
        $result->[$i] = ( $f_real * $g_real + $f_image * $g_image );
        $result->[ $i + 1 ] = ( $f_image * $g_real - $f_real * $g_image );
    }
    return $result;
}

sub _get_zero_array {
    my $length = shift;

    croak "$!" if $length <= -1;

    my $array;
    $array->[$_] = 0 for 0 .. $length;
    return $array;
}

sub _adjust_array_length {
    my ( $array1, $array2 ) = @_;

    my $length = -1;
    if ( $#$array1 == $#$array2 ) {
        $length = $#$array1;
    }
    elsif ( $#$array1 > $#$array2 ) {
        ( $length, $array2 ) = _adjust_array( $array1, $array2 );
    }
    else {
        ( $length, $array1 ) = _adjust_array( $array2, $array1 );
    }

    return ( $length, $array1, $array2 );
}

sub _adjust_array {
    my ( $longer, $shorter ) = @_;
    return ( $#$longer, _zero_fill( $shorter, $#$longer ) );
}

sub _zero_fill {
    my ( $array, $max ) = @_;

    my @array = @{$array};
    $array[$_] = 0 for ( $#$array + 1 ) .. ($max);

    return \@array;
}
1;

__END__


=head1 NAME

Math::PhaseOnlyCorrelation - calculate the phase only correlation


=head1 VERSION

This document describes Math::PhaseOnlyCorrelation version 0.06


=head1 SYNOPSIS

    use Math::PhaseOnlyCorrelation qw/poc/;

    my $array1 = [1, 2, 3, 4, 5, 6, 7, 8];
    my $array2 = [1, 2, 3, 4, 5, 6, 7, 8];

    my $coeff = poc($array1, $array2);

Or if you want to use own FFT function, you may use like so:

    use Math::FFT;
    use List::MoreUtils qw/mesh/;
    use Math::PhaseOnlyCorrelation qw/poc_without_fft/;

    my @array1 = (1, 2, 3, 4, 5, 6, 7, 8);
    my @array2 = (1, 2, 3, 4, 5, 6, 7, 8);
    my @zero_array = (0, 0, 0, 0, 0, 0, 0, 0); # <= imaginary components

    @array1 = mesh(@array1, @zero_array);
    @array2 = mesh(@array2, @zero_array);

    my $array1_fft = Math::FFT->new(\@array1);
    my $array2_fft = Math::FFT->new(\@array2);
    my $result = poc_without_fft($array1_fft->cdft(), $array2_fft->cdft());

    my $ifft = Math::FFT->new($result);
    my $coeff = $ifft->invcdft($result);


=head1 DESCRIPTION

    This module calculate Phase Only Correlation coefficients. This measures degree of similarity between two waves (signals) heed to only phase component,
    so this method is not affected by an amplitude difference.

    The more similar two signals (waves), coefficient will approximates 1.0. In the opposite case, coefficient will approaches zero.



=head1 METHODS

=over

=item poc

Calculate phase only correlation with FFT (This function is using Math::FFT).

This function needs two arguments. Both of arguments are array reference. Array reference just has real part (don't need imaginary part).

=item poc_without_fft

Calculate phase only correlation without FFT.

This function needs two arguments. Both of arguments are array reference, these reference must be processed by FFT.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Math::PhaseOnlyCorrelation requires no configuration files or environment variables.


=head1 DEPENDENCIES

Math::FFT (Version 1.28 or later)

List::MoreUtils (Version 0.33 or later)

Test::Most (Version 0.31 or later)


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-math-phaseonlycorrelation@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

moznion  C<< <moznion@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, moznion C<< <moznion@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
