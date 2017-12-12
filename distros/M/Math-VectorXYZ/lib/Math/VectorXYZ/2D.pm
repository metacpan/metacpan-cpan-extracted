package Math::VectorXYZ::2D;
use base Math::VectorXYZ;

our $VERSION = '1.01';

use 5.006;
use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT = ('Vec');

#----------------------------------------- object constructors ---------------------------------------
#
# Instructions: Provide a list of two numbers (x,y) to the constructor
#
#----------------------------------------------------------------------------------------------------

sub new {

    my $class = shift;
    
    if ( @_ != 2 ) {
        croak '*** Error; syntax is "$vec = VectorXYZ->new(x,y)" ***';
    }

    return bless [ @_, 0 ], $class;
}

sub Vec {

    if ( @_ != 2 ) {
        croak '*** Error; syntax is "$vec = Vec(x,y)" ***';
    }

    return bless [ @_, 0 ], __PACKAGE__;
}

#----------------------------------------- object methods ---------------------------------------
#
# Inherited from parent class except as given below:
#
#----------------------------------------------------------------------------------------------------

sub as_string {
    my $self = shift;
    return "<" . join(",", @$self[0,1]) . ">"; # <x,y>
}

1;

__END__

=pod

=head1 NAME

Math::VectorXYZ::2D - Basic 2d vector operations

=head1 SYNOPSIS

The following vector operations are provided:

B<Create a vector>

    use Math::VectorXYZ::2D;

    my $v1 = Vec(1,2);
    my $v2 = Math::VectorXY::2D->new(4,5);

B<Add, subtract, multiply, and divide>

    my $v_add = $v1 + $v2;
    my $v_sub = $v1 - $v2;

    my $v_mul = 7 * $v1 or $v1 * 7;
    my $v_div = $v1 / 7;

B<Dot product, cross product, printing, etc>

    my $v_dot = $v1.$v2;
    my $v_cross = $v1 x $v2;
    my $unit_vec = $v1->uvec;

    my $magnitude = $v1->mag;
    my $projection = $v1->proj( $v2 );
    my $angle = $v1->angle( $v2 );

    print $v1;

=head1 DESCRIPTION

This module inherits the API from Math::VectorXYZ, but for 2D vectors. 

The internal calculations are the same as the 3D module with zero 
assumed for the Z component of the array [x,y,0]

See L<Math::VectorXYZ> documention for details

=head1 AUTHOR

Ryan Matthew, C<< <rmatthew at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-vectorxyz at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-VectorXYZ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::VectorXYZ::2D


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-VectorXYZ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-VectorXYZ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-VectorXYZ>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-VectorXYZ/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ryan Matthew.

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
