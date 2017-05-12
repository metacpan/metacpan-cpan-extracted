package Geo::Formatter::CalcurateDMS;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT      = qw(__degree2dms __dms2degree);

sub __degree2dms {
    my $degree = shift;

    my $minus  = $degree < 0 ? 1 : 0;
    $degree    = abs($degree);
    my $minute = ($degree - int($degree)) * 60;
    my $second = ($minute - int($minute)) * 60;

    return ($minus,int($degree),int($minute),$second);
}

sub __dms2degree {
    my ($minus,$degree,$minute,$second) = @_;

    $degree = int($degree) + int($minute) / 60 + $second / 3600;
    $degree *= -1 if ($minus);

    return $degree;
}

1;
__END__

=head1 NAME

Geo::Formatter::CalcurateDMS - Bonus class for provide dms/degree convert functions


=head1 DESCRIPTION

This module provides bonus functions to convert dms/degree value each other.
These are convinient to use in Geo::Formatter::Format::XXX.


=head1 EXPORT

2 functions are exported.

=over 4

=item * __degree2dms( [DEGREE] )

Return values are [FLAG OF MINUS],[INT_DEGREE],[INT_MINUTE],[FLOAT_SECOND].

=item * __dms2degree( [FLAG OF MINUS],[INT_DEGREE],[INT_MINUTE],[FLOAT_SECOND] )

Return value is [DEGREE].

=back


=head1 DEPENDENCIES

Exporter


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

