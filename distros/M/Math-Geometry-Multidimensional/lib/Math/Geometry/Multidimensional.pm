package Math::Geometry::Multidimensional;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/distanceToLineN diagonalComponentsN diagonalDistancesFromOriginN/;

=head1 NAME

Math::Geometry::Multidimensional - geometrical functions in n-dimensions

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module has a bunch of functions that work in mulitiple dimensions,
e.g. distance of a point from a line in n-dimensions.

    use Math::Geometry::Multidimensional qw/distanceToLineN/;
    # parametric:
    my $distance = distanceToLineN($point, $gradients, $intersect);
    # symmetric:
    my $distance = distanceToLineP($point, $denominators, $constants);
    

=head1 EXPORT

=over

=item distanceToLineN 

=item diagonalComponentsN

=item diagonalDistancesFromOriginN

=back

=head1 SUBROUTINES/METHODS

=head2 distanceToLineN

We have a line with symmetric form:

(x+a)/m = (y+b)/n = (z+c)/p ...

@M is the list of denominators and @C is the list of constants.

For a point $P, 

	distanceToLineN($P,\@M,\@C)

returns the distance to the closest point on the line... in n-dimensions.

=cut

sub distanceToLineN {
	my ($P,$M,$C) = @_;
	my $n = @$P;
	my $t = 0;
	my $d = 0;
	foreach my $i(0..$n-1){
		my ($p,$m,$c) = map {$_->[$i]} ($P,$M,$C);
		$p ||= 0; # default value is zero for missing values
		$t += ($m * ($p + $c));
		$d += ($m**2);
	}
	$t /= $d;

	my $sos = 0;
	my $Q = []; # orthogonal point on line
	foreach my $i(0..$n-1){
		my ($p,$m,$c) = map {$_->[$i]} ($P,$M,$C);
		$p ||= 0;# default value is zero for missing values
		my $q += $m * $t -$c;
		push @$Q, $q;
		$sos += ($p-$q)**2; # add squared vector component
	}
	return (sqrt($sos), $Q);
}

=head2 lineFromTwoPoints

=cut

sub lineFromTwoPoints {
}

=head2 diagonalDistanceFromOriginN

This is the distance along the y=z=x=... line from any point to the origin.
First we find the closest point on y=z=x=... from our point, which happens
to be the average of the coordinates, e.g. if the point is (10,8) then the 
closest point on y=z is 9,9.  If the point is (9,8,4) then the closest point
on z=y=x is (7,7,7).  If the point is (2,3,4,7) then the closest point on 
z=y=x=w is (4,4,4,4).  Why?

For P(u,v,w) and L: (x+a)/k = (y+b)/l = (z+c)/m = t

we know that x=kt-a ; y=lt-b ; z=my-c

so k(kt-a) + l(lt-b) + m(mt-c) = kkt-ka + llt-lb + mmt-mc = ku+lv+mw
OR
t(kk+ll+mm) = k(u+a)+l(v+b)+m(w+c)
so
t = (k(u+a)+l(v+b)+m(w+c)) / (kk+ll+mm)

BUT, if  a=b=c=0 and k=l=m=1, then:

t = (x+y+z)/(3)

in general, t is the average of the coordinates.

then, x' = kt-a, and if k is 1 and a is 0, then x' is t.

P' is (t,t,t)
so the distance to P' from the origin is sqrt(3 t^2)
or sqrt( 3 * ((x+y+z)/3)^2)
or sqrt( 3 * (x+y+z)^2 / 9 )
or sqrt( (x+y+z)^2 / 3)
or (x+y+z)/sqrt(3)
or SUM(coords)/sqrt(n)

Does that make sense?

=cut

sub diagonalDistanceFromOriginN {
    my ($P) = @_;
    my $sum = 0;
    $sum += $_ foreach @$P;
    return $sum / sqrt(@$P);
}

=head2 diagonalDistancesFromOriginN 

Acts on columns rather than an individual point... 
give it column number, row number and list of columns.

	my $arrayref = diagonalDistancesFromOriginN ($k,$n,@cols)

=cut

sub diagonalDistancesFromOriginN {
    my ($k,$n,@cols) = @_;
	my $k1 = $k-1;
	my $sk = sqrt($k);
	my @D = ();
	my $count = 0;
	my $sum;
	foreach my $i(0..$n-1){
		$sum = 0;
		foreach (0..$k1){
			if(defined $cols[$_]->[$i] && $cols[$_]->[$i] ne ''){
				$sum += $cols[$_]->[$i];
				$count++;
			}
		}
		push @D, $count ? $sum / $sk : '';
	}
	return \@D;
}

=head2 diagonalComponentsN

Here, we are basically rotating all the data so that the "y-axis" or whatever
you want to call the left-most co-ordinate now lies diagonally through the data.

=cut

sub diagonalComponentsN {
		my ($Y, $X) = @_;
		croak "Y and X are different lengths"
			unless @$Y == @$X;
		return [map {
			my ($y,$x) = ($Y->[$_], $X->[$_]);
			if((! defined $x || $x eq '') && (! defined $y || $y eq '')){
				$x = 'skip';
			}
			$y = 0 unless defined $y && $y ne '';
			$x = 0 unless defined $x && $x ne '';
			$x eq 'skip' 
				? '' 
				: ($y - $x)/sqrt(2)
		} (0..$#$Y)];
}

=head2 distanceFromDiagonalN 

As above, we know that the point P' on the diagonal closest to our point P
has the average coordinates of point P.  And the distance 
PP' (x-x', y-y', z-z') is the root of the sum of the squares. So

so, if x' = t, which is (x+y+z)/3 ...

PP' = sqrt( (x - x/3 - y/3 - z/3)^2  + (y - x/3 - y/3 - z/3)^2
		           + (z + x/3 + y/3 + z/3)^2 )

= sqrt( x^2 (2/3) + y^2 (2/3) + z^2 (2/3) + 2xy + 2xz + 2yz )

this is not implemented yet.

=cut

sub distanceFromDiagonalN {
}

=head1 AUTHOR

Jimi Wills, C<< <jimi at webu.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-geometry-multidimensional at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Geometry-Multidimensional>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Geometry::Multidimensional


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Geometry-Multidimensional>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Geometry-Multidimensional>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Geometry-Multidimensional>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Geometry-Multidimensional/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jimi Wills.

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

1; # End of Math::Geometry::Multidimensional
