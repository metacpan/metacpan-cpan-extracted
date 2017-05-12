package Math::DWT;

use 5.006;
use strict;
use warnings;


=head1 NAME

Math::DWT - Pure Perl 1-D Discrete Wavelet Transform.

=head1 VERSION

Version 0.022

=cut

our $VERSION = '0.022';


=head1 SYNOPSIS

This module computes the forward and inverse Discrete Wavelet Transform using arbitrary wavelets defined in modules (many are included in the distribution).

    use Math::DWT;

    my $dwt = Math::DWT->new('Daubechies',1); # Haar

    my @x = qw/8 6 7 5 3 0 9 0/; # zero-pad input to make it 2^n long

    # perform a single transform with default loaded filters
    my $coeffs = $dwt->dwt(\@x);

    # $coeffs points to LEVEL+1 array refs

    # Check perfect reconstruction:
    my @X = $dwt->idwt($coeffs);

    my $maxerr=0;
    for(my $i=0;$i<scalar(@X);$i++) {
       my $err=abs($x[$i] - $X[$i]);
       $maxerr = $err if ($err > $maxerr);
    }

    print $maxerr . "\n"; # 5.27844434827784e-12 (close enough to 0)



=head1 SUBROUTINES/METHODS


=head2 new(WAVELET,VAR)

=head2 new(WAVELET)

=head2 new()

Create a new DWT object with the wavelet WAVELET and variable VAR.  The wavelet is loaded from the module Math::DWT::Wavelet::WAVELET, so there will be an error if this module is not installed.  If VAR is omitted, then VAR is set to whatever the default is as defined in the module (usually the lowest option).  If WAVELET is left blank, then an empty object is returned with no filters defined.  See the set_filters method to set custom filters (TODO).

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

	

=head2 dwt(SIGNAL,LEVEL,LO-PASS,HI-PASS)

=head2 dwt(SIGNAL,LEVEL)

=head2 dwt(SIGNAL)


This performs the forward Discrete Wavelet Transform on SIGNAL using LO-PASS and HI-PASS as filters.  The process is repeated LEVEL times.  If LO-PASS and HI-PASS are omitted, then it uses defaults set in loaded wavelet.  If LEVEL is omitted, then it sets LEVEL=1.  SIGNAL is an array ref.  The length of SIGNAL must be a power of 2, e.g. 256, 512, 1024, etc.

dwt returns an arrayref (or array, if called in array context) of arrayrefs, one for each set of detail coefficients, and an extra one for the last set of scaling coefficients.  So for a 256-sample long input signal, processed to 4 levels, the return value of dwt would be an array/arrayref with 5 arrayrefs with sizes 128, 64, 32, 16, and 16, in that order.

    @x=@x[0..255];
    my $coeffs = $dwt->dwt(\@x,4);

    foreach my $i (@$coeffs) { print scalar(@$i) . " "; }
    # prints
    # 128 64 32 16 16



=cut

sub dwt {
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

	my @hi_tmp;
	my @tmp_lo=@{$x};
	my $lo_tmp=\@tmp_lo;

	for(my $j=1;$j<=$level;$j++) {
		($lo_tmp,$hi_tmp[$j-1])=afb($lo_tmp,$lo,$hi);
	};
	$hi_tmp[$level]=$lo_tmp;
	if (wantarray()) {
		return @hi_tmp;
	};
	return \@hi_tmp;

}

=head2 idwt(COEFFICIENTS,LEVEL,LO-PASS,HI-PASS)

=head2 idwt(COEFFICIENTS,LEVEL)

=head2 idwt(COEFFICIENTS)

Inverse Discrete Wavelet Transform.  Same defaults setup as for dwt.  COEFFICIENTS must be an array ref of the structure returned by dwt.  Returns an array or arrayref (depending on the value of wantarray()) with the original signal, or at least the signal inversely processed LEVEL times.

=cut

sub idwt {
        my $self=shift;
        my ($x,$level,$lo,$hi)=@_;

        if (!defined($level)|| $level == 0) {
                $level = 1;
        };

        if (!defined($lo)) {
                $lo = $self->{lo_r};
        };
        if (!defined($hi)) {
                $hi = $self->{hi_r};
        };

	my @y;

	@y=@{$x->[$level]};
	#print STDERR "HERE: " . scalar(@y) . "\n";

	for (my $j=$level;$j>=1;$j--) {
		@y=sfb(\@y,$x->[$j-1],$lo,$hi);
	};

	my @out;
	for (my $i=0;$i<scalar(@y);$i++) {
		$out[$i]=$y[$i];
	};
	if (wantarray()) {
		return (@out);
	};
	return \@out;	
	
}

=head2 cshift(ARRAY,SHIFT)

Utility method that shifts the elements of ARRAY by SHIFT amount in a circular fashion (i.e. elements positioned past the end of the array are placed back at the beginning).  Accepts negative values for SHIFT.

=cut


sub cshift {
        my ($xc,$m)=@_;
        my @ac=@{$xc};
        my @bc;
        my @tmpc;
        if ($m < 0) {
                @tmpc=splice(@ac,0,-$m);
                @bc=(@ac,@tmpc);
        } elsif ($m > 0) {
                @tmpc=splice(@ac,-$m);
                @bc=(@tmpc,@ac);
        } else {
                @bc=@ac;
        }

        if (wantarray()) {
                return @bc;
        };
        return \@bc;
};

=head2 afb(SIGNAL,LO-PASS,HI-PASS)

This is a utility method you shouldn't need to use.  Stands for Analysis Filter Bank.  This method convolves SIGNAL with LO-PASS and separately with HI-PASS, then downsamples each by 2,  and returns arrayrefs of the results of the proper length (half the input length).

=cut

sub afb {
        # analysis filter banks
        my ($x,$afL,$afH)=@_;
        my $N=scalar(@{$x});
        my $L=scalar(@{$afL})/2;

        # do the mystery circle shift
        my @X=cshift($x,-$L);
	#foreach(@X) { $_=$_/sqrt(2); }

        # temporary lo/hi arrays
        my @c;
        my @d;

        # convolutions
        for (my $i=0; $i < $N; $i++) {
                $c[$i]=0;
                $d[$i]=0;
                for (my $j = 0; $j < $L*2; $j++) {
			my $a=0;
			if (defined($X[$i-$j])) { $a=$X[$i-$j]; }
                        $c[$i]+=$a * $afL->[$j];
                        $d[$i]+=$a * $afH->[$j];
                };
        };

        my @lo; my @hi;
        foreach my $k (0 .. scalar(@c)/2) {
                push @lo, $c[2*$k];
                push @hi, $d[2*$k];
        };
        for (my $i=0;$i<$L;$i++) {
		if (!defined($lo[$i+($N/2)])) { $lo[$i+($N/2)]=0;}
		if (!defined($hi[$i+($N/2)])) { $hi[$i+($N/2)]=0;}
                $lo[$i]=$lo[$i+($N/2)] + $lo[$i];
                $hi[$i]=$hi[$i+($N/2)] + $hi[$i];
        }

        my @lo_fin=@lo[ 0 .. ($N/2)-1 ];
        my @hi_fin=@hi[ 0 .. ($N/2)-1 ];

        return (\@lo_fin, \@hi_fin);
};

=head2 sfb(LO-PART,HI-PART,LO-PASS,HI-PASS)

This is an internal utility method for reconstructing a signal from a set of wavelet coefficients and scaling coefficients and a pair of lo-pass and hi-pass reconstruction filters.  It stands for Synthesis Filter Bank and it returns a single array or arrayref that is the result of upsampling the input by 2, then convolving each set of coefficients with its respective filter, and, finally, adding up corresponding lo-pass/hi-pass values.

=cut


sub sfb {
        my ($lo,$hi,$sfL,$sfH)=@_;
        my $N=2*scalar(@{$lo});
        my $L=scalar(@{$sfL});
        $lo=upfirdn($lo,$sfL,2,1);
        $hi=upfirdn($hi,$sfH,2,1);
        my @y;
        my $i=0;

        for ($i=0;$i<scalar(@{$hi});$i++) {
                $y[$i]=$lo->[$i] + $hi->[$i];
        };

        for ($i=0;$i<$L-$N/2;$i++) {
		my $a=0;
		if (defined($y[$N+$i])) { $a=$y[$N+$i]; }
		my $b=0;
		if (defined($y[$i])) { $b=$y[$i]; }
                $y[$i]=$b + $a;
        };
        @y=@y[0..$N-1];
        @y=cshift(\@y,1-($L/2));
	#foreach(@y) { $_=$_/sqrt(2); }

        if (wantarray()) { return @y; };
        return \@y;
};

=head2 upfirdn(A,B,UP,DN)

This is an internal utility method modeled after MATLAB's upfirdn command.  First, it upsamples signal A by the value of UP (use 1 to disable), then convolves A and B, then downsamples the result by a factor of DN (again, use 1 to disable).  The result is an array or arrayref with length defined by: (((length(A)-1)*UP+length(B))/DN)

=cut



sub upfirdn {
        my ($a,$b,$up,$dn)=@_;
        my $N=scalar(@{$a});
        my $L=scalar(@{$b});

        my @A;
        if ($up > 1) {
                for(my $k=0; $k<scalar(@{$a});$k++) {
                        $A[$up*$k]=$a->[$k];
                        $A[($up*$k)+1]=0;
                };
        } else {
                for(my $k=0;$k<scalar(@{$a});$k++) {
                        $A[$k]=$a->[$k];
                };
        };

        my @c;
        for (my $i=0; $i < scalar(@A); $i++) {
                $c[$i]=0;
                for (my $j = 0; $j < $L; $j++) {
			my $tmpa=0;
			if (defined($A[$i-$j])) { $tmpa=$A[$i-$j]; }
                        $c[$i]+=$tmpa * $b->[$j];
                };
        };
        my @d;
        foreach my $k (0 .. (scalar(@c)/$dn)-1) {
                push @d, $c[$dn*$k];
        };
        if (wantarray()) {
                return @d;
        }
        return \@d;
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






=head1 SEE ALSO

Math::DWT::UDWT(3pm), Math::DWT::Wavelet::Haar(3pm), Math::DWT::Wavelet::Coiflet(3pm), Math::DWT::Wavelet::Symlet(3pm), Math::DWT::Wavelet::Biorthogonal(3pm), Math::DWT::Wavelet::ReverseBiorthogonal(3pm), Math::DWT::Wavelet::Daubechies(3pm), Math::DWT::Wavelet::DiscreteMeyer(3pm), perl(1)



=head1 AUTHOR


Mike Kroh, C<< <kroh at cpan.org> >>

=head1 BUGS


Please report any bugs or feature requests to C<bug-math-dwt at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-DWT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 ACKNOWLEDGEMENTS


Special thanks to Ivan Selesnick for his software (on which these modules are based) available here L<http://eeweb.poly.edu/iselesni/software/index.html>.

Some wavelet filter coefficients scraped from this site: L<http://wavelets.pybytes.com/>.

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

1; # End of Math::DWT
