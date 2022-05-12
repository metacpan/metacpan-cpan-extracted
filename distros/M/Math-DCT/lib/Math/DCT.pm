package Math::DCT;

use 5.008;
use strict;
use warnings;

=encoding UTF-8

=head1 NAME

Math::DCT - 1D and NxN 2D Fast Discreet Cosine Transforms (DCT-II)

=head1 SYNOPSIS

  use Math::DCT qw/dct dct1d dct2d idct1d idct2d/;

  # DCT of 1D array
  my $dct1d = dct([[1,2,3,4]]);
  $dct1d = dct1d([1,2,3,4]);

  # DCT of 2D array
  my $dct2d = dct([[1,2],[3,4]]);
  $dct2d = dct2d([1,2,3,4]);

  # iDCT of 1D and 2D array
  my $idct1d = idct1d([1,2,3,4]);
  my $idct2d = idct2d([1,2,3,4]);

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Math::DCT', $VERSION);

use Exporter qw(import);

our @EXPORT_OK = qw(
    dct
    dct1d
    dct2d
    idct1d
    idct2d
);

our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

=head1 DESCRIPTION

An unscaled DCT-II implementation for 1D and NxN 2D matrices implemented in XS.
For array sizes which are a power of 2 a fast - I<O(n logn)> for 1D, I<O(n² logn)>
for 2D - algorithm (FCT) described by Lee is used with some tweaks.
In addition, an unscaled version of the specially optimized Arai, Agui, Nakajima
FCT is used for 1x8, 8x8 matrices. A less optimized algorithm is used for
the generic case, so any 1D or square 2D matrix can be processed (I<O(n²)>,
I<O(n³)> respectivelly).

For convenience the inverse functions are provided (inverse DCT-II, usually called
iDCT, is essentially a scaled DCT-III), with an implementation equivalent to the
generic DCT-II case.

The module was written for a perceptual hash project that needed 32x32 DCT-II, and
on a 2.5GHz i7 2015 Macbook Pro about 18000/s per thread are processed.
The common 8x8 DCT-II uses a special path, (about 380000/s on that same CPU),
although for most image/video applications that require 8x8 DCT there are much faster
implementations (SIMD, approximations etc) that usually produce an already scaled result
for the specific application.

None of the algorithms used on this module are approximate, the test suite verifies
against a naive DCT-II implementation with a tolerance of 1e-08.

=head1 METHODS
 
=head2 C<dct>

  my $dct = dct([[1,2],[3,4]]);   # Example for 2x2 2D matrix 

Pass an array (ref) of either a single array, or N x length-N arrays for 1D and NxN
2D DCT-II calculation respectivelly. The output will be an arrayref of array(s)
with the result of the transform.

It is a convenience function with some overhead, mainly in the case of NxN arrays
which have to be flattened before processing - for already flat 2D data see L<dct2d>
below.

=cut

sub dct {
    my $vector = shift;
    die "Expect array of array(s)"
        unless $vector && ref $vector eq 'ARRAY'
        && $vector->[0] && ref $vector->[0] eq 'ARRAY';

    my $dim = scalar(@$vector);
    my $sz  = scalar(@{$vector->[0]});
    die "Expect 1d or NxN 2d arrays" unless $dim == 1 || $dim == $sz;

    my $pack;
    for (my $x = 0; $x < $dim; $x++) {
        $pack .= pack "d$sz", @{$vector->[$x]}
    }

    if ($dim > 1) {
        $sz == 8
            ? fct8_2d($pack)
            : 0 == ($sz & ($sz - 1)) ? fast_dct_2d($pack, $sz) : dct_2d($pack, $sz);
    } else {
        $sz == 8
            ? fct8_1d($pack)
            : 0 == ($sz & ($sz - 1)) ? fast_dct_1d($pack, $sz) : dct_1d($pack, $sz);
    }

    my $result;
    foreach (0..$dim-1) {
        $result->[$_] = [unpack "d".($sz), substr $pack, $_ * $sz*8, $sz*8];
    }
    return $result;
}

=head2 C<dct1d>

  my $dct = dct1d([1,2,3]);

Pass an array (ref) for a 1D DCT-II calculation. The output will be an arrayref
with the result of the transform.

=cut

sub dct1d {
    my $input = shift;
    my $sz    = scalar @$input;
    my $pack  = pack "d$sz", @$input;
    $sz == 8
        ? fct8_1d($pack)
        : 0 == ($sz & ($sz - 1)) ? fast_dct_1d($pack, $sz) : dct_1d($pack, $sz);
    my @result = unpack "d$sz", $pack;
    return \@result;
}

=head2 C<idct1d>

  my $idct = idct1d([1,2,3]);

Pass an array (ref) for a 1D iDCT calculation. The output will be an arrayref
with the result of the transform. This is essentially a DCT-III transform scaled
by 2/N.

=cut

sub idct1d {
    my $input = shift;
    my $sz    = scalar @$input;
    my $pack  = pack "d$sz", @$input;
    idct_1d($pack, $sz);
    my @result = unpack "d$sz", $pack;
    return \@result;
}

=head2 C<dct2d>

  my $dct = dct2d(
      [1,2,3,4],   # Arrayref containing your NxN matrix
      2            # Optionally, the size N of your array (sqrt of its length)
  );

Pass an array (ref) for a 2D DCT-II calculation. The length of the array is expected
to be a square (as only NxN arrays are supported) - you can optionally pass N as
the second argument to avoid a C<sqrt> calculation.
The output will be an arrayref with the result of the transform.

If your 2D data is available in a 1D array as is usual with most image manipulation
etc cases, this function will be faster than C<dct>, as the DCT calculation is
anyway done on a flattened (1D) array, hence you skip the conversion.

=cut

sub dct2d {
    my $input = shift;
    my $sz    = shift || sqrt(scalar @$input);
    my $pack  = pack "d".($sz*$sz), @$input;
    $sz == 8
        ? fct8_2d($pack)
        : 0 == ($sz & ($sz - 1)) ? fast_dct_2d($pack, $sz) : dct_2d($pack, $sz);
    my @result = unpack "d".($sz*$sz), $pack;
    return \@result;
}

=head2 C<idct2d>

  my $idct = idct2d(
      [1,2,3,4],   # Arrayref containing your NxN matrix
      2            # Optionally, the size N of your array (sqrt of its length)
  );

Pass an array (ref) for a 2D iDCT calculation. The length of the array is expected
to be a square (as only NxN arrays are supported) - you can optionally pass N as
the second argument to avoid a C<sqrt> calculation.
This is essentially a DCT-III transform scaled by 2/N.
The output will be an arrayref with the result of the transform.

=cut

sub idct2d {
    my $input = shift;
    my $sz    = shift || sqrt(scalar @$input);
    my $pack  = pack "d".($sz*$sz), @$input;
    idct_2d($pack, $sz);
    my @result = unpack "d".($sz*$sz), $pack;
    return \@result;
}

=head1 USAGE NOTES

The C functions are not exported, but theoretically you could use them directly
if you do your own C<pack/unpack>. The fast versions for power-of-2 size arrays
are C<fast_dct_1d> and C<fast_dct_2d>, while the generic versions are C<dct_1d>
and C<dct_2d> (with their inverse functions being C<idct_1d> and C<idct_2d>).
The specialized size-8 versions are C<fct8_1d> and C<fct8_2d>.
First argument is a C<char *> (use C<pack "dN">), second is the size N (except
for the fct8* functions which don't need a second argument).

There is a simple benchmarking script available (C<bench/benchmarking.pl>).
Sample output (on an Apple M1 CPU):

  ** Fast 2D DCT-II (Arai et al.) **
  8x8: 688910/s
  ** Fast 2D DCT-II (Lee) **
  32x32: 34501/s
  64x64: 8471/s
  256x256: 438/s
  ** Generic 2D DCT-II **
  24x24: 49898/s
  48x48: 7616/s
  ** Generic 2D iDCT **
  8x8: 516756/s
  32x32: 24187/s

=head1 ACKNOWLEDGEMENTS

C-code for 1D DCT was adapted from Project Nayuki and improved where possible.

(L<https://www.nayuki.io/page/fast-discrete-cosine-transform-algorithms>)

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>
 
=head1 BUGS

Please report any bugs or feature requests either on GitHub, or on RT (via the email
C<bug-math-dct at rt.cpan.org> or web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-DCT>).

I will be notified, and then you'll be notified of progress on your bug as I make changes.

=head1 GIT

L<https://github.com/SpareRoom/Math-DCT>
 
=head1 COPYRIGHT & LICENSE

Copyright (C) 2019, SpareRoom.com

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
