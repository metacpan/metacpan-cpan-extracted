# Math::WalshTransform.pm
#########################################################################
#        This Perl module is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This module is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

package Math::WalshTransform;
no strict;
$VERSION = '1.17';
# gives a -w warning, but I'm afraid $VERSION .= ''; would confuse CPAN
require DynaLoader;
require Exporter;
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(fht fhtinv fwt fwtinv biggest logical_convolution
 logical_autocorrelation power_spectrum walsh2hadamard hadamard2walsh);
@EXPORT_OK = qw(sublist distance size average normalise product arr2txt);
%EXPORT_TAGS = (ALL => [@EXPORT,@EXPORT_OK]);
bootstrap Math::WalshTransform $VERSION;

$PP = 0;

sub fht {
	if (! $PP) { return &xs_fht(@_); }
	my @mr = @_;
	my $k = 1;
	my $n = scalar @mr;
	my $l = $n;
	my $i; my $nl; my $nk; my $j;
	while () {
		$i = $[-1; $l = $l/2;
		for ($nl=1; $nl<= $l; $nl++) {
			for ($nk=1; $nk<= $k; $nk++) {
				$i++; $j = $i+$k;
				$mr[$i] = ($mr[$i] + $mr[$j])/2;
				$mr[$j] =  $mr[$i] - $mr[$j];
			}
			$i = $j;
		}
		$k = 2*$k;
		last if $k >= $n;
	}
	if ($k == $n) {
		return @mr;
	} else {
		warn "Math::WalshTransform::fht \$n = $n but must be power of 2\n";
		return ();
	}
}
sub fhtinv {
	if (! $PP) { return &xs_fhtinv(@_); }
	my @mr = @_;
	my $k = 1;
	my $n = scalar @mr;
	my $l = $n;
	my $i; my $nl; my $nk; my $j;
	while () {
		$i = $[-1; $l = $l/2;
		for ($nl=1; $nl<= $l; $nl++) {
			for ($nk=1; $nk<= $k; $nk++) {
				$i++; $j = $i+$k;
				$mr[$i] = $mr[$i] + $mr[$j];
				$mr[$j] = $mr[$i] - 2*$mr[$j];
			}
			$i = $j;
		}
		$k = 2*$k;
		last if $k >= $n;
	}
	if ($k == $n) {
		return @mr;
	} else {
		warn "Math::WalshTransform::fhtinv \$n = $n but must be power of 2\n";
		return ();
	}
}
sub fwt { # might be easier to Hadamard transform and shuffle the results
	if (! $PP) { return &xs_fwt(@_); }
	my @mr = @_;
	my $n = scalar @mr; my @nr; $#nr=$#mr;
	my $k; my $l; my $i; my $nl; my $nk; my $kp1;

	my $m = 0;  # log2($n)
	my $tmp = 1; while () { last if $tmp >= $n; $tmp<<=1; $m++; }
	my $alternate = $m & 1;

	if ($alternate) {
		for ($k=$[; $k<$n-$[; $k+=2) {
			$kp1 = $k+1;
			$mr[$k]   = ($mr[$k] + $mr[$kp1])/2;
			$mr[$kp1] =  $mr[$k] - $mr[$kp1];
		}
	} else { 
		for ($k=$[; $k<$n-$[; $k+=2) { 
			$kp1 = $k+1;
			$nr[$k]   = ($mr[$k] + $mr[$kp1])/2;
			$nr[$kp1] =  $nr[$k] - $mr[$kp1];
		}
	}

	$k = 1; my $nh = $n/2;
	while () {
		my $kh = $k; $k = $k+$k; $kp1 = $k+1; last if $kp1>$n;
		$nh = $nh/2; $l = $[; $i = $[; $alternate = !$alternate;
		for ($nl=1; $nl<=$nh; $nl++) {
			for ($nk=1; $nk<=$kh; $nk++) {
				if ($alternate) {
					$mr[$l]   = ($nr[$i]   + $nr[$i+$k])/2;
					$mr[$l+1] =  $mr[$l]   - $nr[$i+$k];
					$mr[$l+2] = ($nr[$i+1] - $nr[$i+$kp1])/2;
					$mr[$l+3] =  $mr[$l+2] + $nr[$i+$kp1];
				} else {
					$nr[$l]   = ($mr[$i]   + $mr[$i+$k])/2;
					$nr[$l+1] =  $nr[$l]   - $mr[$i+$k];
					$nr[$l+2] = ($mr[$i+1] - $mr[$i+$kp1])/2;
					$nr[$l+3] =  $nr[$l+2] + $mr[$i+$kp1];
				}
				$l = $l+4; $i = $i+2;
			}
			$i = $i+$k;
		}
	}
	return @mr;
}
sub fwtinv {
	if (! $PP) { return &xs_fwtinv(@_); }
	my @mr = @_; my $n = scalar @mr; my @nr; $#nr=$#mr;
	my $k; my $l; my $i; my $nl; my $nk; my $kp1;

	my $m = 0;  # log2($n)
	my $tmp = 1; while () { last if $tmp >= $n; $tmp<<=1; $m++; }
	my $alternate = $m & 1;

	if ($alternate) {
		for ($k=$[; $k<$n-$[; $k+=2) {
			$kp1 = $k+1;
			$mr[$k]   =  $mr[$k] + $mr[$kp1];
			$mr[$kp1] =  $mr[$k] - $mr[$kp1] - $mr[$kp1];
		}
	} else { 
		for ($k=$[; $k<$n-$[; $k+=2) { 
			$kp1 = $k+1;
			$nr[$k]   =  $mr[$k] + $mr[$kp1];
			$nr[$kp1] =  $mr[$k] - $mr[$kp1];
		}
	}

	$k = 1; my $nh = $n/2;
	while () {
		my $kh = $k; $k = $k+$k; $kp1 = $k+1; last if $kp1>$n;
		$nh = $nh/2; $l = $[; $i = $[; $alternate = !$alternate;
		for ($nl=1; $nl<=$nh; $nl++) {
			for ($nk=1; $nk<=$kh; $nk++) {
				if ($alternate) {
					$mr[$l]   =  $nr[$i]   + $nr[$i+$k];
					$mr[$l+1] =  $nr[$i]   - $nr[$i+$k];
					$mr[$l+2] =  $nr[$i+1] - $nr[$i+$kp1];
					$mr[$l+3] =  $nr[$i+1] + $nr[$i+$kp1];
				} else {
					$nr[$l]   =  $mr[$i]   + $mr[$i+$k];
					$nr[$l+1] =  $mr[$i]   - $mr[$i+$k];
					$nr[$l+2] =  $mr[$i+1] - $mr[$i+$kp1];
					$nr[$l+3] =  $mr[$i+1] + $mr[$i+$kp1];
				}
				$l = $l+4; $i = $i+2;
			}
			$i = $i+$k;
		}
	}
	return @mr;
}

sub logical_convolution { my ($xref, $yref) = @_;
	if (ref $xref ne 'ARRAY') { warn
	"Math::WalshTransform::logical_convolution 1st arg must be array ref\n";
		return undef;
	} elsif (ref $yref ne 'ARRAY') { warn
	"Math::WalshTransform::logical_convolution 2nd arg must be array ref\n";
		return undef;
	}
	my @Fx = &fwt(@$xref);  my @Fy = &fwt(@$yref);
	# my @Fz; foreach ($[ .. $#Fx) { $Fz[$_] = $Fx[$_] * $Fy[$_]; } return @Fz;
	return &fwtinv(&product(\@Fx, \@Fy));
}

sub old_logical_convolution { my ($xref, $yref) = @_;
	if (ref $xref ne 'ARRAY') { warn
	"Math::WalshTransform::logical_convolution 1st arg must be array ref\n";
		return undef;
	} elsif (ref $yref ne 'ARRAY') { warn
	"Math::WalshTransform::logical_convolution 2nd arg must be array ref\n";
		return undef;
	}
	local $[ = 0;
	my @x = @$xref; my @y = @$yref;
	my $n = scalar @x;
	my @z; $#z=$#x;
	my $j; my $k; my $sum;
	for ($k=$[; $k<=$#x; $k++) {
		$sum = 0.0;
		for ($j=$[; $j<=$#x; $j++) { $sum += $x[$j^$k] * $y[$j]; }
		$z[$k] = $sum/$n;
	}
	return @z;
}
sub logical_autocorrelation {
	&logical_convolution(\@_,\@_);
}
sub power_spectrum {
	&fwt( &logical_convolution(\@_,\@_) );
}
sub walsh2hadamard {
	my @h; $#h = $#_;
	my @jw2jh = &jw2jh(scalar @_);
	my $i; for ($i=$[; $i<=$#_; $i++) { $h[$jw2jh[$i]] = $_[$i]; }
	return @h;
}
sub hadamard2walsh {
	my @w; $#w = $#_;
	my @jw2jh = &jw2jh(scalar @_);
	my $i; for ($i=$[; $i<=$#_; $i++) { $w[$i] = $_[$jw2jh[$i]]; }
	return @w;
}

# ---------------------- EXPORT_OK stuff ---------------------------

sub biggest { my $k = shift @_; my @weeded = @_;
	my $smallest;
	if ($k <= 0) {
		my $tot = 0.0; foreach (@weeded) { $tot += abs $_; }
		$smallest = $tot / scalar @weeded;
	} else {
		my @sorted = sort { abs $b <=> abs $a } @weeded;
		$smallest = abs $sorted[$[-1+$k];
	}
	foreach (@weeded) { if (abs $_ < $smallest) { $_=0.0; } }
	return @weeded;
}
sub sublist { my ($aref, $offset, $length) = @_;
	if (ref $aref ne 'ARRAY') {
	warn "Math::WalshTransform::sublist 1st arg must be array ref\n"; return ();
	}
	my $first;
	if ($offset<0) { $first = $#{$aref}+$offset+1; } else { $first=$offset; }
	my $last;
	if (! defined $length) { $last = $#{$aref};
	} elsif ($length < 0) { $last = $#{$aref} + $length;
	} else { $last = $first + $length - 1;
	}
	# warn "offset=$offset length=$length first=$first last=$last\n";
	my @sublist = (); my $i;
	for ($i=$first; $i<=$last; $i++) { push @sublist, ${$aref}[$i]; }
	return @sublist;
}
# sub distance { my ($xref, $yref) = @_;  # Euclidian metric
# 	if (ref $xref ne 'ARRAY') {
# 		warn "Math::WalshTransform::distance 1st arg must be array ref\n";
# 		return undef;
# 	} elsif (ref $yref ne 'ARRAY') {
# 		warn "Math::WalshTransform::distance 2nd arg must be array ref\n";
# 		return undef;
# 	}
# 	my $distance = 0.0; my $i; my $diff;
# 	for ($i=$[; $i<= $#$xref; $i++) {
# 		$diff = ${$xref}[$i] - ${$yref}[$i];
# 		$distance += $diff * $diff;
# 	}
# 	return sqrt $distance;
# }
# sub size {my $sum=0.0; foreach (@_) {$sum+=$_*$_;} return sqrt $sum;}
# sub normalise {
#	my $size = &size(@_);
#	my @normalised = ();
#	foreach (@_) { push @normalised, $_/$size; }
#	return @normalised;
#}
sub average {
	my $i = $[; my $j; my @sum;
	foreach (@_) {
		if (ref $_ ne 'ARRAY') {
			warn "Math::WalshTransform::average argument $i must be array ref\n";
			return undef;
		}
		for ($j=$[; $j<=$#$_; $j++) { $sum[$j] += ${$_}[$j]; }
		$i++;
	}
	foreach (@sum) { $_ /= ($i-$[); }
	return @sum;
}
sub arr2txt { # neat printing of arrays for debug use
	my @txt; foreach (@_) { push @txt, sprintf('%g',$_); }
	return join (' ',@txt)."\n";
}

# ---------------------- infrastructure ---------------------------

sub jw2jh { my $n = shift;
	if ($n < 16) {
		if ($n == 8) { return (0,4,6,2,3,7,5,1); }
		if ($n == 4) { return (0,2,3,1); }
		if ($n == 2) { return (0,1); }
		if ($n == 1) { return (0); }
		warn "jw2jh: n=$n must be power of 2\n"; return ();
	} 
	my @half; foreach (&jw2jh($n/2)) { push @half, $_<<1; }
	my @whole = @half; foreach (reverse @half) { push @whole, $_|1; }
	return @whole;
}

my $flag = 0;
sub gaussn {	my $standdev = $_[$[];
	# returns normal distribution around 0.0 by the Box-Muller rules
	if (! $flag) {
		$a = sqrt(-2.0 * log(rand));
		$b = 6.28318531 * rand;
		$flag = 1;
		return ($standdev * $a * sin($b));
	} else {
		$flag = 0;
		return ($standdev * $a * cos($b));
	}
}
1;

__END__

=pod

=head1 NAME

Math::WalshTransform.pm - Fast Hadamard and Walsh Transforms

=head1 SYNOPSIS

 use Math::WalshTransform;
 @f = (1.618, 2.718, 3.142, 4.669);  # must be power-of-two long
 @FH1 = &fht(@f);   # Hadamard transform
 @fh1 = &fhtinv(@FH1);
 # or
 @FW2 = &fwt(@f);   # Walsh transform
 @fw2 = &fwtinv(@FW2);
 @FH2 = &walsh2hadamard(@FW2);

 @PS  = &power_spectrum(@f);

 import Math::WalshTransform qw(:ALL);
 @whats_going_on = &biggest(9,&fwt(&sublist(\@time_series,-16)));
 @EVENT1 = &fwt(&sublist(\@time_series,478,16));
 @EVENT2 = &fwt(&sublist(\@time_series,2316,16));
 @EVENT3 = &fwt(&sublist(\@time_series,3261,16));
 $EVENT1[$[]=0.0; $EVENT2[$[]=0.0; $EVENT3[$[]=0.0; # ignore constant
 @EVENT1 = &normalise(@EVENT1); # ignore scale
 @EVENT2 = &normalise(@EVENT2);
 @EVENT3 = &normalise(@EVENT3);
 @TYPICAL_EVENT = &average(\@EVENT1, \@EVENT2, \@EVENT3);
 ...
 @NOW = &fwt(&sublist(\@time_series,-16));
 $NOW[$[] = 0.0;
 @NOW = &normalise(@NOW);
 if (&distance(\@NOW, \@TYPICAL_EVENT) < .28) { &get_worried(); }

=head1 DESCRIPTION

These routines implement fast Hadamard and Walsh Transforms
and their inverse transforms.

Also included are routines
for converting a Hadamard to a Walsh transform and vice versa,
for calculating the Logical Convolution of two lists,
or the Logical Autocorrelation of a list,
and for calculating the Walsh Power Spectrum -
in short, almost everything you ever wanted to do with a Walsh Transform.

Intelligible speech can be reconstructed by transforming
blocks of, say, 64 samples, deleting all but the several largest
transform components, and inverse-transforming;
in other words, these transforms extract from a time-series
the most significant things that are going on.
They should be useful for B<noticing important things>,
for example in software that monitors time-series data such as
system or network administration data, share-price, currency,
ecological, opinion poll, process management data, and so on.

As from version 1.10, Math::WalshTransform uses C routines to perform
the transforms. This runs 25 to 30 times faster than previous versions.

Not yet included are multi-dimensional Hadamard and Walsh Transforms,
conversion between Logical and Arithmetic Autocorrelation Functions,
or conversion between the Walsh Power Spectrum and the Fourier Power Spectrum.

Version 1.17

=head1 SUBROUTINES

Routines which take just one array as argument expect the array itself;
those which take more than one array expect a list of references.

=over 3

=item I<fht>(@f);

The argument I<@f> is the list of values to be transformed.
The number of values must be a power of 2.
I<fht> returns a list I<@F> of the Hadamard transform.

=item I<fhtinv>(@F);

The argument I<@F> is the list of values to be inverse-transformed.
The number of values must be a power of 2.
I<fhtinv> returns a list I<@f> of the inverse Hadamard transform.

=item I<fwt>(@f);

The argument I<@f> is the list of values to be transformed.
The number of values must be a power of 2.
I<fwt> returns a list I<@F> of the Walsh transform.

=item I<fwtinv>(@F);

The argument I<@F> is the list of values to be inverse-transformed.
The number of values must be a power of 2.
I<fwtinv> returns a list I<@f> of the inverse Walsh transform.

=item I<walsh2hadamard>(@F);

The argument I<@F> is a Walsh transform;
I<walsh2hadamard> returns a list of the corresponding Hadamard transform.

=item I<hadamard2walsh>(@F);

The argument I<@F> is a Hadamard transform;
I<hadamard2walsh> returns a list of the corresponding Walsh transform.

=item I<logical_convolution(\@x, \@y)>

The arguments are references to two arrays of values I<x> and I<y>
which must both be of the same size which must be a power of 2.
I<logical_convolution> returns a list of the logical (or dyadic) convolution
of the two sets of values.  See the MATHEMATICS section ...

=item I<logical_autocorrelation(@x)>

The argument is a list of values I<x>;
the number of values must be a power of 2.
I<logical_autocorrelation> returns a list of the logical (or dyadic)
autocorrelation of the set of values.  See the MATHEMATICS section ...

=item I<power_spectrum(@x)>

The argument is a list of values I<x>;
the number of values must be a power of 2.
I<power_spectrum> returns a list of the Walsh Power Spectrum
of the set of values.  See the MATHEMATICS section ...

=back

=head1 EXPORT_OK SUBROUTINES

The following routines are not exported by default,
but are exported under the I<ALL> tag, so if you need them you should:

 import Math::WalshTransform qw(:ALL);

=over 3

=item I<biggest($k,@x)>

The first argument I<$k> is the number of elements of the array I<@x>
which will be conserved;
I<biggest> returns an array in which the biggest I<$k> elements
are intact and in place, and the other elements are set to zero.
If I<$k> is 0 or negative, then I<biggest> returns an array in which
all elements less than the average (absolute) size have been set to zero.

=item I<sublist(\@array, $offset, $length)>

This routine returns a part of the I<@array> without,
as I<splice> does, munging the original array.
It applies to arrays the same sort of syntax that I<substr> applies to strings;
the sublist is extracted starting at I<$offset> elements from the front
of the array; if I<$offset> is negative the sublist starts that far from the
end of the array instead; if I<$length> is omitted, everything to the end
of the array is returned; if I<$length> is negative, the length is
calculated to leave that many elements off the end of the array.

=item I<distance(\@array1, \@array2)>

This routine returns the distance between the two arrays,
according to the Euclidian Metric;
in other words, the square root of the sum of the squares
of the differences between the corresponding elements.

=item I<size(@array)>

This routine returns the distance between the array and an array of zeroes,
according to the Euclidian Metric;
in other words, the square root of the sum of the squares of the elements.

=item I<normalise(@array)>

This routine returns an array scaled so that its I<size> is 1.0

=item I<average(\@array1, \@array2, ... \@arrayN)>

This routine returns an array in which each element is the average
of the corresponding elements of all the argument arrays.

=item I<product(\@array1, \@array2)>

This routine returns an array in which each element is the product
of the corresponding elements of the argument arrays.

=back

=head1 MATHEMATICS

The Hadamard matrix is a square array of plus and minus ones,
whose rows and columns are orthogonal to each other.
Hence, the product of the matrix and its tranpose
is the identity matrix times a constant I<N> which is equal to the
order of the matrix.
If I<N> is a power of two, symmetrical Hadamard matrices can
be defined recursively:

         | 1  1 |
 Had   = |      |
    2    | 1 -1 |

         | Had   Had  |
         |    N     N |
 Had   = |            |
    2N   | Had  -Had  |
         |    N     N |

Each row of the Hadamard matrix corresponds to
a Hadamard Function I<Had(j,k)> where j = 0...N-1

Another way to describe a Hadamard matrix of dimension 2^N x 2^N is
that the entry in row i and column j is (-1)^P, where P is the number
of positions in which the binary expansion of i and j share a 1.
From this definition it is immediate that the last row (and column) is a
Thue-Morse (or Morse-Thue) sequence, and also that rows that are of the
form 2^N - 2^j will be j-fold repetitions of the Thue-Morse sequence.

The upper half of the Hadamard matrix are cycles of increasing
wavelengths, and the lower half are Morse-Thue sequences on
decreasing cell-sizes, much as the components of a
Fourier analysis are sine-waves of different wavelengths.

The Walsh matrix is derived from the Hadamard matrix by rearranging the rows
so that the number of sign-changes is in increasing order.  Each row of the
Walsh matrix corresponds to a Walsh Function I<Wal(j,k)> where j = 0...N-1

The one-dimensional Hadamard transform pair is defined by

 F(j) = (1/N) * Sigma f(k)*Had(j,k)
 f(j) = Sigma F(k)*Had(j,k)

and the one-dimensional Walsh transform pair is defined by

 F(j) = (1/N) * Sigma f(k)*Wal(j,k)
 f(j) = Sigma F(k)*Wal(j,k)

The two transforms are equivalent, and conversion between them
only involves rearranging the order of the components.
Since the Walsh functions are in order of increasing number of sign-changes,
the Walsh transform is more Fourier-like,
and for that reason is used more often,
although it does use several per-cent more CPU time.

Because all the matrix elements are either 1 or -1,
these transforms involve almost no multiplications
and are computationally very efficient.

The Logical (or Dyadic) Convolution of two arrays x and y is defined by

 z(k) = (1/N) * Sigma x(k^j)*y(j)

where the ^ is used in its Perl sense, to mean bitwise exclusive-or.
There exists a Logical (or Dyadic) Convolution Theorem, analogous to the
normal case, that the Walsh transform of the logical convolution of two
sequences is the product of their Walsh transforms,
and that the Walsh transform of the product of two sequences is the
logical convolution of their Walsh transforms.

Likewise there exists a Logical Wiener-Khintchine Theorem,
stating that the Walsh Power Spectrum
is the Walsh transform of the Logical Autocorrelation Function.

There exist linear transformations converting
between Logical Convolution and the normal Arithmetic Convolution,
and between the Walsh Power Spectrum and the normal Fourier Power Spectrum.

=head1 AUTHOR

Peter J Billam, www.pjb.com.au/comp/contact.html

=head1 REFERENCES

I<Walsh Spectrometry,
a form of spectral analysis well suited to binary computation>,
J. E. Gibbs,
National Physical Lab, Teddington, Middlesex, England,
unpublished, 1967

I<Hadamard transform image encoding>,
W. K. Pratt, J. Kane and H. C. Andrews,
Proc. IEEE,
Vol. 57, Jan 1969, pp. 58-68

I<Walsh function generation>,
D. A. Swick,
IEEE Transactions on Information Theory (Corresp.),
Vol. IT-15 part 1, Jan 1969, p. 167

I<Computation of the Hadamard transform and the R-transform in ordered form>,
L. J. Ulman,
IEEE Trans. Comput. (Corresp.),
Vol. C-19, Apr 1970, pp. 359-360

I<Computation of the Fast Hadamard Transform>,
Ying Shum and Ronald Elliot,
Proc. Symp. Appl. Walsh Functions,
Washington D.C., 1972, pp. 177-180

I<Logical Convolution and Discrete Walsh and Fourier Power Spectra>,
Guener Robinson,
IEEE Transactions on Audio and Electroacoustics,
Vol. AU-20 No. 4, October 1972, pp. 271-280

I<Speech processing with Walsh-Hadamard Transforms>,
Ying Shum, Ronald Elliot and Owen Brown,
IEEE Transactions on Audio and Electroacoustics,
Vol. AU-21 No. 3, June 1973, pp. 174-179

=head1 SEE ALSO

 http://www.pjb.com.au/
 http://search.cpan.org/perldoc?Math::WalshTransform
 Math::Evol    http://search.cpan.org/perldoc?Math::Evol
 Term::Clui    http://search.cpan.org/perldoc?Term::Clui
 Crypt::Tea_JS http://search.cpan.org/perldoc?Crypt::Tea_JS
 http://en.wikipedia.org/wiki/Thue-Morse_sequence
 http://mathworld.wolfram.com/WalshTransform.html
 http://arxiv.org/abs/nlin/0510009
 http://arxiv.org/abs/cs/0703057
 perl(1).

=cut
