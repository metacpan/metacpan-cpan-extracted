package Math::FFTW;

use 5.006;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.01';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	fftw_dft_real2complex_1d
	fftw_idft_complex2real_1d
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();


require XSLoader;
XSLoader::load('Math::FFTW', $VERSION);

__END__

=head1 NAME

Math::FFTW - Perl interface to parts of the FFTW

=head1 SYNOPSIS

  use Math::FFTW;
  
  # should be evenly spaced in x
  my @ydata = ...; # with noise
  my $coefficients = Math::FFTW::fftw_dft_real2complex_1d(\@ydata);
  
  # $coefficients is ary ref. Contains the complex fourier
  # coefficients as [c1_real, c1_imaginary, c2_real, ..., cn_imaginary]
  
  # should give us the same data as we put in.
  my $same_y_data = Math::FFTW::fftw_idft_complex2real_1d($coefficients);
  
  # set all coefficients beyond the fiftieth to zero
  $_=0 for @{$coefficients}[100..$#$coefficients];
  # ==> should smooth our data
  
  my $smoothed = Math::FFTW::fftw_idft_complex2real_1d($coefficients);

=head1 DESCRIPTION

I<The recommended interface of this module may change. In that case,
however, backwards compatible routines will be provided.>

This is an interface to small parts of the FFTW library. Currently,
only the forward and backward Discrete Fourier Transform of one-dimensional
real data is supported.

If you need anything else, let me know. (And send a patch along if you like.)

=head2 INSTALLATION

You can install this module as you would install any other Perl/XS extension
provided that the FFTW library and its headers are available and can be
found by your compiler/linker.

Tested on Linux/x64.

=head2 EXPORT

None by default. The C<fftw_dft_real2complex_1d> and
C<fftw_idft_complex2real_1d> subroutines can be exported on demand.

=head1 SUBROUTINES

=head2 fftw_dft_real2complex_1d

The forward DFT returns an array of N/2+1 complex
fourier coefficients. The complex coefficients are returned as two reals
each. (Real part, then imaginary part)

The returned array (reference) should have C<(N/2+1)*2 = N+2> elements.

=head2 fftw_idft_complex2real_1d

The backward, or inverse DFT returns data from a set of coefficients as
returned by C<fftw_dft_real2complex_1d>.

Given an array reference of N+2 elements as input, you should get an
array (reference) of N elements in return.

=head1 SEE ALSO

L<http://www.fftw.org>

=head1 AUTHOR

Steffen Müller, E<lt>tsee@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

The FFTW library is not contained in this package. Its copyright is
held by Matteo Frigo and the MIT. It is distributed under the GNU
General Public License.

=cut
