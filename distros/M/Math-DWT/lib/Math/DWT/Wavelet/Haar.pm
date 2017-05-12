package Math::DWT::Wavelet::Haar;
use strict;
use warnings;

=head1 NAME

Math::DWT::Wavelet::Haar - FIR lo- & hi-pass filter coefficients for the Haar wavelet.

=head1 VERSION

Version 0.022

=cut

our $VERSION = '0.022';

=head1 SYNOPSIS

This module provides the lo- and hi-pass decomposition and reconstruction filter coefficients for the Haar wavelet.  It is meant to be used with other Math::DWT modules:

    use Math::DWT;
    use Math::DWT::UDWT;
    
    my $dwt = Math::DWT->new('Haar');
    my $udwt = Math::DWT::UDWT->new('Haar');


=cut

=head1 SUBROUTINES/METHODS

=head2 new()

The Haar wavelet module is unique among the other wavelet modules in that there is no "VAR" argument to new().  This method returns a Math::DWT::Wavelet::Haar object;

=head2 vars()

This method returns a list of possible choices for VAR when creating a new object, e.g.:

    my @v = Math::DWT::Wavelet::Daubechies->vars();
    print scalar(@v); # 20

This method returns an empty array/arrayref for the Haar wavelet, since there are no options for VAR.

=head2 filters()

Depending on the context in which it is called, returns an array or an arrayref containing (lo_d, hi_d, lo_r, hi_r) - the set of filters which are defined with the instantiated object.

=head2 lo_d()

=head2 hi_d()

=head2 lo_r()

=head2 hi_r()

Returns the requested set of filter coefficients as either an array or arrayref, depending on calling context.

=head1 SEE ALSO

Math::DWT(3pm), Math::DWT::UDWT(3pm), Math::DWT::Wavelet::Daubechies(3pm), Math::DWT::Wavelet::Coiflet(3pm), Math::DWT::Wavelet::Symlet(3pm), Math::DWT::Wavelet::Biorthogonal(3pm), Math::DWT::Wavelet::ReverseBiorthogonal(3pm), Math::DWT::Wavelet::DiscreteMeyer(3pm), perl(1)


=head1 AUTHOR


Mike Kroh, C<< <kroh at cpan.org> >>

=head1 BUGS


Please report any bugs or feature requests to C<bug-math-dwt-wavelet-haar at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-DWT-Wavelet-Haar>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.



=head1 ACKNOWLEDGEMENTS

These wavelet filter coefficients were scraped from this site: L<http://wavelets.pybytes.com/>.

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


my @vars=qw//;

my %lo_d; my %hi_d; my %lo_r; my %hi_r;


$lo_d{""}=[qw/0.7071067811865476 0.7071067811865476/];
$lo_r{""}=[qw/0.7071067811865476 0.7071067811865476/];
$hi_d{""}=[qw/-0.7071067811865476 0.7071067811865476/];
$hi_r{""}=[qw/0.7071067811865476 -0.7071067811865476/];
;

sub new {
	my $class=shift;
	my $self={};
	my $var=shift || "";

	$self={lo_d=>$lo_d{$var},
		hi_d=>$hi_d{$var},
		lo_r=>$lo_r{$var},
		hi_r=>$hi_r{$var}
		};
	
	bless $self,$class;
	return $self;
};

sub vars {
	my $self=shift;
	if (wantarray()) {
		return (@vars);
	};
	return \@vars;
};

sub filters {
	my $self=shift;
	my $lo_d=$self->lo_d;
	my $hi_d=$self->hi_d;
	my $lo_r=$self->lo_r;
	my $hi_r=$self->hi_r;
	my @a=( $lo_d,$hi_d,$lo_r,$hi_r);
	if (wantarray()) {
		return (@a);
	};
	return \@a;
};

sub lo_d {
	my $self=shift;
	my $a=$self->{lo_d};
	if (wantarray()) {
		return (@{$a});
	};
	return $a;
};	
sub hi_d {
	my $self=shift;
	my $a=$self->{hi_d};
	if (wantarray()) {
		return (@{$a});
	};
	return $a;
};	
sub lo_r {
	my $self=shift;
	my $a=$self->{lo_r};
	if (wantarray()) {
		return (@{$a});
	};
	return $a;
};	
sub hi_r {
	my $self=shift;
	my $a=$self->{hi_r};
	if (wantarray()) {
		return (@{$a});
	};
	return $a;
};	

		
1;
