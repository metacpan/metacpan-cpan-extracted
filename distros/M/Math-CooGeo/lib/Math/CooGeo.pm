package Math::CooGeo;

use strict;
use warnings;
use Exporter;

our @ISA=qw(Exporter);
our @EXPORT=qw(distance midpoint slope gradient);

our $VERSION='1.0.2';
our $LIBRARY=__PACKAGE__;

sub distance(x1,y1,x2,y2){return sqrt((x2-x1)**2+(y2-y1)**2)}
sub midpoint(x1,y1,x2,y2){return (x=>(x1+x2)/2),y=>(y1+y2)/2}
sub slope(x1,y1,x2,y2){return (y2-y1)/(x2-x1)}
*gradient=*slope;

1;

__END__

=encoding UTF-8

=head1 NAME

Math::CooGeo - Coordinate geometry library for Perl.

=head1 VERSION

Version 1.0.1

=head1 DESCRIPTION

Math::CooGeo is coordinate geometry library for Perl.

=head1 METHODS

=head2 distance(x1,y1,x2,y2)

=over 5

=item *

x1 - X coordinate of first point.

=item *

y1 - Y coordinate of first point.

=item *

x2 - X coordinate of second point.

=item *

y2 - Y coordinate of second point.

=item *

return value - Distance between point x1,y1 and point x2,y2.

=back

=head2 midpoint(x1,y1,x2,y2)

=over 5

=item *

x1 - X coordinate of first point.

=item *

y1 - Y coordinate of first point.

=item *

x2 - X coordinate of second point.

=item *

y2 - Y coordinate of second point.

=item *

return value - Midpoint of line joining points x1,y1 and x2,y2.

=back

=head2 slope(x1,y1,x2,y2)

=over 5

=item *

x1 - X coordinate of first point.

=item *

y1 - Y coordinate of first point.

=item *

x2 - X coordinate of second point.

=item *

y2 - Y coordinate of second point.

=item *

return value - Slope of line joining points x1,y1 and x2,y2.

=back

=head2 gradient(x1,y1,x2,y2)

Same as slope(x1,y1,x2,y2)

=head1 BUGS

Please report any bugs here:

=over 4

=item *

debos@cpan.org

=item *

L<GitHub|https://github.com/DeBos99/Math-CooGeo/issues>

=item *

Discord: DeBos#3292

=item *

L<Reddit|https://www.reddit.com/user/DeBos99>

=back

=head1 AUTHOR

Michał Wróblewski <debos@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2019 Michał Wróblewski

=head1 LICENSE

This project is licensed under the MIT License - see the L<LICENSE|https://github.com/DeBos99/Math-CooGeo/blob/master/LICENSE> file for details.

=cut
