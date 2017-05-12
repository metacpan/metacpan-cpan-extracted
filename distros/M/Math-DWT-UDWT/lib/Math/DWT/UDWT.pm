package Math::DWT::UDWT;

use 5.006;
use strict;
use warnings;


=head1 NAME

Math::DWT::UDWT - Pure Perl 1-D Undecimated Discrete Wavelet Transform.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module implements a pure Perl version of the 1-D Undecimated Discrete Wavelet Transform (UDWT), also known as the "stationary" Discrete Wavelet Transform, because it is shift-invariant.

Do not look here for efficiency - only implementation.  It is designed to be a reference for others who would like to see wavelets in action.  It is based off of MATLAB code from Ivan Selesnick's website at L<http://eeweb.poly.edu/iselesni/software/index.html>.

    use Math::DWT::UDWT;

    # new object with Math::DWT::Wavelet::Symmlet module loaded
    # as wavelet; specifically, Symmlet5
    my $udwt = Math::DWT::UDWT->new('Symmlet',5);

    @signal=@signal[0..509];
    my $x = \@signal;  # can be any length - not just 2^n

    # performs one iteration of the UDWT on $x
    my $coeffs = $udwt->udwt($x);

    # notice how the UDWT returns more data than it took in
    # this is due to the linear convolution used right now.
    print scalar(@{$coeffs->[0]}); # 265
    print scalar(@{$coeffs->[1]}); # 265

    # test Perfect Reconstruction
    my $y=$udwt->iudwt($coeffs);

    my $maxerr=0;
    foreach my $i (0 .. scalar(@x)-1) {
        my $err = abs($x[$i] - $y->[$i]);
        $maxerr = $err if ($err > $maxerr);
    }
    print "$maxerr\n"; # prints 7.92255150372512e-12 (close to 0)


=cut

   


=head1 SUBROUTINES/METHODS

=head2 new(WAVELET,VAR)

=head2 new(WAVELET)

=head2 new()

Create a new UDWT object with the wavelet WAVELET and variable VAR.

=cut

sub new {
	my $class=shift;
	my $self={};
	my $wavelet=shift;
	my $var=shift;

	my $wname; my $w;
	my ($lo_d,$hi_d,$lo_r,$hi_r);
	if (defined($wavelet)) {
		$wname="Math::DWT::Wavelet::$wavelet";
		require "Math/DWT/Wavelet/$wavelet.pm";
		$w=$wname->new($var);

		($lo_d,$hi_d,$lo_r,$hi_r)=@{$w->filters()};
	}

	$self={ lo_d=>$lo_d,
		hi_d=>$hi_d,
		lo_r=>$lo_r,
		hi_r=>$hi_r };

	bless $self,$class;
	return $self;
};

	

=head2 udwt(SIGNAL,LEVEL,LO-PASS,HI-PASS)

=head2 udwt(SIGNAL,LEVEL)

=head2 udwt(SIGNAL)

This performs the forward Undecimated Discrete Wavelet Transform on SIGNAL using LO-PASS and HI-PASS as filters.  The process is repeated LEVEL times.  If the filters are omitted, it uses the filters set in the wavelet when the udwt object was created.  LEVEL defaults to 1.

The structure of $coeffs is the same as in Math::DWT, i.e., the first LEVEL arrayrefs are iterative arrays of detail coefficients, and the last arrayref is the remaining array of scaling coefficients.


=cut

sub udwt {
	my $self=shift;
	my ($x,$level,$lo,$hi)=@_;

	if (!defined($level)|| $level == 0) {
		$level = 1;
	};

	if (!defined($lo)) {
		$lo = $self->{lo_d};
	};
	if (!defined($hi)) {
		$hi = $self->{hi_d};
	};

	my @out;

	# normalize

	my @LO=@{$lo};
	my @HI=@{$hi};
	my @X=@{$x};

	foreach (@LO) { $_=$_/sqrt(2); }
	foreach (@HI) { $_=$_/sqrt(2); }

	my $Nlo=scalar(@LO);
	my $Nhi=scalar(@HI);

	my $N=scalar(@X);

	for (my $j=1;$j<=$level;$j++) {
		my $L=scalar(@X);
		my $M=2**($j-1);
		my @lo_tmp;
		my @hi_tmp;

		for (my $k=0;$k<=$Nhi-1;$k++) {
			for (my $i=1;$i<=$L;$i++) {
				my $a=0;
				if (!defined($hi_tmp[$M*$k+$i-1])) {
					$hi_tmp[$M*$k+$i-1]=0;
				}
				if (defined($X[$i-1])) {
					$a=$X[$i-1];
				};
				$hi_tmp[$M*$k+$i-1]=$hi_tmp[$M*$k+$i-1] + $HI[$k]*$a;
			};
		};
		for (my $k=0;$k<=$Nlo-1;$k++) {
			for (my $i=1;$i<=$L;$i++) {
				my $a=0;
				if (!defined($lo_tmp[$M*$k+$i-1])) {
					$lo_tmp[$M*$k+$i-1]=0;
				}
				if (defined($X[$i-1])) {
					$a=$X[$i-1];
				};
				$lo_tmp[$M*$k+$i-1]=$lo_tmp[$M*$k+$i-1] + $LO[$k]*$a;
			};
		};
	
		$out[$j-1]=\@hi_tmp;

		@X=@lo_tmp;

	}
	$out[$level]=\@X;

	if (wantarray()) {
		return (@out);
	};
	return \@out;
}
	

=head2 iudwt(COEFFICIENTS,LEVEL,LO-PASS,HI-PASS)

=head2 iudwt(COEFFICIENTS,LEVEL)

=head2 iudwt(COEFFICIENTS)

Inverse Undecimated Discrete Wavelet Transform.  Same options as for Math::DWT::idwt.

=cut

sub iudwt {
	my $self=shift;
	my ($w,$J,$lo,$hi)=@_;

	my @counts;

	if (!defined($J)) { $J=1; }

	for (my $i=0;$i<scalar(@$w);$i++) {
		push @counts, scalar(@{$w->[$i]});
	};

	if (!defined($lo)) {
		$lo = $self->{lo_r};
	};
	if (!defined($hi)) {
		$hi = $self->{hi_r};
	};

	my @LO=@{$lo};
	my @HI=@{$hi};

	foreach (@LO) { $_=$_/sqrt(2);}
	foreach (@HI) { $_=$_/sqrt(2);}

	my $Nlo=scalar(@LO);
	my $Nhi=scalar(@HI);

	my $N=$Nlo+$Nhi;

	my $y;
	my @tmpy;

	for (my $i=0;$i<$counts[$J];$i++) {
		push @{$y}, $w->[$J]->[$i];
	};

	for (my $j=$J;$j>=1;$j--) {
		my $M=2**($j-1);
		my @lo=@{$y};

		my @hi;
		for (my $i=0; $i<$counts[$j-1];$i++) {
			push @hi, $w->[$j-1]->[$i];
		};

		my $Llo=scalar(@lo);
		my $Lhi=scalar(@hi);

		my @ylo;
		my @yhi;

		#for(my $i=0;$i<$Llo+$M*($Nlo-1);$i++) {
			#push @ylo, 0;
		#};
		#for(my $i=0;$i<$Lhi+$M*($Nhi-1);$i++) {
			#push @yhi, 0;
		#};

		for(my $k=0;$k<=$Nlo-1;$k++) {
			for (my $l=1;$l<=$Llo;$l++) {
				my $a=0;
				if (!defined($ylo[$M*$k+$l-1])) {
					$ylo[$M*$k+$l-1]=0;
				};
				if (defined($lo[$l-1])) {
					$a=$lo[$l-1];
				};
				$ylo[$M*$k+$l-1]=$ylo[$M*$k+$l-1] + $LO[$k] * $a;
			}
		}
		for(my $k=0;$k<=$Nhi-1;$k++) {
			for (my $l=1;$l<=$Lhi;$l++) {
				my $a=0;
				if (!defined($yhi[$M*$k+$l-1])) {
					$yhi[$M*$k+$l-1]=0;
				};
				if (defined($hi[$l-1])) {
					$a=$hi[$l-1];
				};
				$yhi[$M*$k+$l-1]=$yhi[$M*$k+$l-1] + $HI[$k] * $a;
			}
		}

		my @cur_y;
		for (my $i=0;$i<scalar(@yhi);$i++) {
			push @cur_y, $ylo[$i]+$yhi[$i];
		}

		$y=\@cur_y;

		my $L=$M*($N/2-1);

		my @tmpyy;

		#for (my $i=$L-1;$i<scalar(@yhi)-$L-1;$i++) {
		for (my $i=$L;$i<scalar(@yhi)-$L;$i++) {
			push @tmpyy, $y->[$i];
		};
		@tmpy=@tmpyy;
		$y=\@tmpy;
	};
	return \@tmpy;
};		

=head2 set_filters(LO_D,HI_D,LO_R,HI_R)

Set the filters manually.  Each of LO_D, HI_D, LO_R, and HI_R is an arrayref to the set of coefficients for the respective filter set.  Returns undef.

=cut

sub set_filters {
	my $self=shift;
	my ($lo_d,$hi_d,$lo_r,$hi_r)=@_;

	$self->{lo_d}=$lo_d;
	$self->{hi_d}=$hi_d;
	$self->{lo_r}=$lo_r;
	$self->{hi_r}=$hi_r;

	return undef;
};

=head2 get_filters()

Get the set of filters.  Returns an array or an arrayref containing LO_D, HI_D, LO_R, HI_R in that order.

=cut

sub get_filters {
	my $self=shift;
	my ($lo_d,$hi_d,$lo_r,$hi_r)=($self->{lo_d},$self->{hi_d},$self->{lo_r},$self->{hi_r});

	if (wantarray()) {
		return ($lo_d,$hi_d,$lo_r,$hi_r);
	};
	return [$lo_d, $hi_d, $lo_r, $hi_r ];
};



=head1 AUTHOR

Mike Kroh, C<< <kroh at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-dwt-udwt at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-DWT-UDWT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS




=head1 LICENSE AND COPYRIGHT

Copyright 2016 Mike Kroh.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Math::DWT::UDWT
