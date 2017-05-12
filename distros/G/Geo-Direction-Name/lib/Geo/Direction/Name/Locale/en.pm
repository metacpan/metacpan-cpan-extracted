package Geo::Direction::Name::Locale::en;

use warnings;
use strict;
use Carp;

use base qw/Geo::Direction::Name::Locale/;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; import utf8;
    }
}

sub dir_string {
[
    'North',
    'North by east',
    'North-northeast',
    'Northeast by north',
    'Northeast',
    'Northeast by east',
    'East-northeast',
    'East by north',
    'East',
    'East by south',
    'East-southeast',
    'Southeast by east',
    'Southeast',
    'Southeast by south',
    'South-southeast',
    'South by east',
    'South',
    'South by west',
    'South-southwest',
    'Southwest by south',
    'Southwest',
    'Southwest by west',
    'West-southwest',
    'West by south',
    'West',
    'West by north',
    'West-northwest',
    'Northwest by west',
    'Northwest',
    'Northwest by north',
    'North-northwest',
    'North by west',
]
}

sub abbr_string {
[
    'N',
    'NbE',
    'NNE',
    'NEbN',
    'NE',
    'NEbE',
    'ENE',
    'EbN',
    'E',
    'EbS',
    'ESE',
    'SEbE',
    'SE',
    'SEbS',
    'SSE',
    'SbE',
    'S',
    'SbW',
    'SSW',
    'SWbS',
    'SW',
    'SWbW',
    'WSW',
    'WbS',
    'W',
    'WbN',
    'WNW',
    'NWbW',
    'NW',
    'NWbN',
    'NNW',
    'NbW',
]
}


1;

=head1 NAME

Geo::Direction::Name::Locale::en - Locale 'en' class of Geo::Direction::Name's locale class.


=head1 OVERRIDE METHODS

=over 4

=item * dir_string

=item * abbr_string

=back


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

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

