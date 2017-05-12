#!/usr/bin/env perl

use strict;
use warnings;

use List::MoreUtils qw/mesh/;
use Math::FFT;

use FindBin;
use lib ("$FindBin::Bin/../lib");
use Math::PhaseOnlyCorrelation qw/poc_without_fft/;

my @array1     = ( 1, 2, 3, 4, 5, 6, 7, 8 );
my @array2     = ( 1, 2, 3, 4, 5, 6, 7, 8 );
my @zero_array = ( 0, 0, 0, 0, 0, 0, 0, 0 );    # <= imaginary components

@array1 = mesh( @array1, @zero_array );
@array2 = mesh( @array2, @zero_array );

my $array1_fft = Math::FFT->new( \@array1 );
my $array2_fft = Math::FFT->new( \@array2 );
my $result     = poc_without_fft( $array1_fft->cdft(), $array2_fft->cdft() );

my $ifft  = Math::FFT->new($result);
my $coeff = $ifft->invcdft($result);
