package Math::Gauss::XS;
use warnings;
use strict;

our $VERSION = '0.02';

require Exporter;
our @ISA = qw( Exporter );
our %EXPORT_TAGS = ('all' => [qw( pdf cdf inv_cdf )]);
Exporter::export_ok_tags('all');

require XSLoader;
XSLoader::load('Math::Gauss::XS', $VERSION);

=head1 NAME

Math::Gauss::XS - Gaussian distribution function and its inverse, fast XS version

=head1 VERSION

0.01

=head1 STATUS

=begin HTML

<p>
    <a href="https://travis-ci.org/binary-com/perl-Math-Gauss-XS"><img src="https://travis-ci.org/binary-com/perl-Math-Gauss-XS.svg" /></a>
</p>

=end HTML

=head1 SYNOPSIS

  use Math::Gauss::XS ':all';
  my ($p, $c, $z, $x, $m, $s); # intialize them
  $p = pdf( $z );
  $p = pdf( $x, $m, $s );

  $c = cdf( $z );
  $c = cdf( $x, $m, $s );

  $z = inv_cdf( $z );

=head1 DESCRIPTION

This module just rewrites the L<Math::Gauss> module in XS. The precision and
exported function remain the same as in the original.

The benchmark results are

 Benchmark: timing 30000000 iterations of pp/pdf, xs/pdf...
    pp/pdf: 15 wallclock secs (14.99 usr +  0.00 sys = 14.99 CPU) @ 2001334.22/s (n=30000000)
    xs/pdf:  2 wallclock secs ( 2.16 usr +  0.00 sys =  2.16 CPU) @ 13888888.89/s (n=30000000)
 Benchmark: timing 30000000 iterations of pp/cdf, xs/cdf...
    pp/cdf: 40 wallclock secs (38.93 usr +  0.00 sys = 38.93 CPU) @ 770613.92/s (n=30000000)
    xs/cdf:  2 wallclock secs ( 2.22 usr +  0.00 sys =  2.22 CPU) @ 13513513.51/s (n=30000000)
 Benchmark: timing 30000000 iterations of pp/inv_cdf, xs/inv_cdf...
 pp/inv_cdf: 15 wallclock secs (16.02 usr +  0.00 sys = 16.02 CPU) @ 1872659.18/s (n=30000000)
 xs/inv_cdf:  2 wallclock secs ( 2.18 usr +  0.00 sys =  2.18 CPU) @ 13761467.89/s (n=30000000)

=for Pod::Coverage cdf inv_cdf pdf

=head1 SOURCE CODE

L<GitHub|https://github.com/binary-com/perl-Math-Gauss-XS>


=head1 AUTHOR

binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/binary-com/perl-Math-Gauss-XS/issues>.

=cut

1;
