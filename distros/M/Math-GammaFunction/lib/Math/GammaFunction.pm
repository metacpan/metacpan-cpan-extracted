package Math::GammaFunction;
use 5.006;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.02';

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
    gamma
    log_gamma
    faculty
	psi
    psi_derivative
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

require XSLoader;
XSLoader::load('Math::GammaFunction', $VERSION);


1;
__END__

=head1 NAME

Math::GammaFunction - The Gamma and its related functions

=head1 SYNOPSIS

  use Math::GammaFunction qw/:all/;
  my $gamma     = gamma(5); # 24
  my $fac       = faculty(4); # same
  my $psi       = psi(4); # 1.256...
  my $psi_deriv = psi_derivative($x, $order); # order==0 => psi
  # ...

=head1 DESCRIPTION

This module computes the Gamma function, its logarithmic derivative
(the Psi or Digamma function) and the derivatives of the Psi function.

It is a thin wrapper around a couple of functions in the math library
of the R statistics package.

=head2 EXPORT

None by default. You may choose to export the following functions
separately or all at once using the C<:all> tag:

    gamma
    log_gamma
    faculty
	psi
    psi_derivative

=head1 SUBROUTINES

=head2 gamma

Takes a real, positive number as argument. Computes the Gamma function.
(C<n! == Gamma(n+1)>)

=head2 log_gamma

Takes a real, positive number as argument. Computes the logarithm of
the Gamma function.

=head2 psi

Takes a real as argument. Computes the Psi (or Digamma) function.
(C<d/dx Gamma(x) == Gamma(x)*Psi(x)> or C<d/dx ln(Gamma(x)) == Psi(x)>)

=head2 psi_derivative

Takes two arguments: The argument x of the function (real) and the
order of the derivative (integer 0 or positive). Computes
the n-th derivative of Psi at position x.

The maximum derivative is, as far as I can gather from the R sources, 100.

This is basically the Polygamma function.

=head2 faculty

Takes a positive integer as argument. Computes its faculty.
(Thin wrapper around C<gamma>)

=head1 SEE ALSO

The actual computation is carried out in C by the excellent R library.

Thus, refer to the R manual for details. What I call C<gamma> here is
the C<gammafn> in R's C sources, C<log_gamma> is is C<gamma> in the C
sources. L<http://www.r-project.org/>

Here's a list of Wikipedia pages about related functions:

L<http://en.wikipedia.org/wiki/Gamma_function>, 
L<http://en.wikipedia.org/wiki/Polygamma_function>, 
L<http://en.wikipedia.org/wiki/Digamma_function>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
