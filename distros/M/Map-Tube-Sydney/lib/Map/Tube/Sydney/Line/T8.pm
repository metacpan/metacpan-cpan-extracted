package Map::Tube::Sydney::Line::T8;

$Map::Tube::Sydney::Line::T8::VERSION   = '1.00';
$Map::Tube::Sydney::Line::T8::AUTHORITY = 'cpan:EARLYBEAN';

use 5.006;
use strict; use warnings;

=head1 NAME

Map::Tube::Sydney::Line::T8 - Sydney Rail Map: T8 Line.

=head1 VERSION

Version 1.00

=head1 DESCRIPTION

Sydney Rail Map: T8 Line.

    +-----------------------+--------------------------------------+
    | Station Name          | Connected To                         |
    +-----------------------+--------------------------------------+
    | Town Hall             | Central, Wynyard                     |
    | Wynyard               | Town Hall, Circular Quay             |
    | Circular Quay         | Wynyard, St James                    |
    | St James              | Circular Quay, Museum                |
    | Museum                | St James, Central                    |
    | Central               | Museum, Redfern, Green Square        |
    | Redfern               | Central, Erskineville                |
    | Erskineville          | Redfern, St Peters                   |
    | St Peters             | Erskineville, Sydenham               |
    | Sydenham              | St Peters, Turrella                  |
    | Green Square          | Sydenham, Mascot                     |
    | Mascot                | Green Square, Domestic Airport       |
    | Domestic Airport      | Mascot, International Airport        |
    | International Airport | Domestic Airport, Wolli Creek        |
    | Wolli Creek           | International Airport, Turrella      |
    | Turrella              | Sydenham, Wolli Creek, Bardwell Park |
    | Bardwell Park         | Turrella, Bexley North               |
    | Bexley North          | Bardwell Park, Kingsgrove            |
    | Kingsgrove            | Bexley North, Beverly Hills          |
    | Beverly Hills         | Kingsgrove, Narwee                   |
    | Narwee                | Beverly Hills, Riverwood             |
    | Riverwood             | Narwee, Padstow                      |
    | Padstow               | Riverwood, Revesby                   |
    | Revesby               | Padstow, Panania                     |
    | Panania               | Revesby, East Hills                  |
    | East Hills            | Panania, Holsworthy                  |
    | Holsworthy            | East Hills, Glenfield                |
    | Glenfield             | Holsworthy, Macquarie Fields         |
    | Macquarie Fields      | Glenfield, Ingleburn                 |
    | Ingleburn             | Macquarie Fields, Minto              |
    | Minto                 | Ingleburn, Leumeah                   |
    | Leumeah               | Minto, Campbelltown                  |
    | Campbelltown          | Leumeah, Macarthur                   |
    | Macarthur             | Campbelltown                         |
    +-----------------------+--------------------------------------+

=head1 NOTE

=over 2

=item * The station "Central" is also part of
              L<T1 Line|Map::Tube::Sydney::Line::T1>
            | L<T2 Line|Map::Tube::Sydney::Line::T2>
            | L<T3 Line|Map::Tube::Sydney::Line::T3>
            | L<T4 Line|Map::Tube::Sydney::Line::T4>
            | L<T9 Line|Map::Tube::Sydney::Line::T9>
            | L<M1 Line|Map::Tube::Sydney::Line::M1>

=item * The station "Circular Quay" is also part of
              L<T2 Line|Map::Tube::Sydney::Line::T2>
            | L<T3 Line|Map::Tube::Sydney::Line::T3>
            | L<L2 Line|Map::Tube::Sydney::Line::L2>
            | L<L3 Line|Map::Tube::Sydney::Line::L3>

=item * The station "Glenfield" is also part of
              L<T2 Line|Map::Tube::Sydney::Line::T2>
            | L<T5 Line|Map::Tube::Sydney::Line::T5>

=item * The station "Museum" is also part of
              L<T2 Line|Map::Tube::Sydney::Line::T2>
            | L<T3 Line|Map::Tube::Sydney::Line::T3>

=item * The station "Redfern" is also part of
              L<T1 Line|Map::Tube::Sydney::Line::T1>
            | L<T2 Line|Map::Tube::Sydney::Line::T2>
            | L<T3 Line|Map::Tube::Sydney::Line::T3>
            | L<T4 Line|Map::Tube::Sydney::Line::T4>
            | L<T9 Line|Map::Tube::Sydney::Line::T9>

=item * The station "St James" is also part of
              L<T2 Line|Map::Tube::Sydney::Line::T2>
            | L<T3 Line|Map::Tube::Sydney::Line::T3>

=item * The station "Sydenham" is also part of
              L<T4 Line|Map::Tube::Sydney::Line::T4>
            | L<M1 Line|Map::Tube::Sydney::Line::M1>

=item * The station "Town Hall" is also part of
              L<T1 Line|Map::Tube::Sydney::Line::T1>
            | L<T2 Line|Map::Tube::Sydney::Line::T2>
            | L<T3 Line|Map::Tube::Sydney::Line::T3>
            | L<T4 Line|Map::Tube::Sydney::Line::T4>
            | L<T9 Line|Map::Tube::Sydney::Line::T9>
            | L<L2 Line|Map::Tube::Sydney::Line::L2>
            | L<L3 Line|Map::Tube::Sydney::Line::L3>

=item * The station "Wolli Creek" is also part of
              L<T4 Line|Map::Tube::Sydney::Line::T4>

=item * The station "Wynyard" is also part of
              L<T1 Line|Map::Tube::Sydney::Line::T1>
            | L<T2 Line|Map::Tube::Sydney::Line::T2>
            | L<T3 Line|Map::Tube::Sydney::Line::T3>
            | L<T9 Line|Map::Tube::Sydney::Line::T9>
            | L<L2 Line|Map::Tube::Sydney::Line::L2>
            | L<L3 Line|Map::Tube::Sydney::Line::L3>

=back

=head1 MAP

Sydney Rail Map: L<T8 Line|https://raw.githubusercontent.com/earlybean4/Map-Tube-Sydney/master/maps/T8.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/earlybean4/Map-Tube-Sydney/master/maps/T8.png">
<img src    = "https://raw.githubusercontent.com/earlybean4/Map-Tube-Sydney/master/maps/T8.png"
     alt    = "Sydney Rail Map: T8 Line"
     width  = "798px"
     height = "830px"/>
</a>

=end html

=head1 AUTHOR

Peter Harrison, C<< <pete at 28smith.com> >>

=head1 REPOSITORY

L<https://github.com/earlybean4/Map-Tube-Sydney>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/earlybean4/Map-Tube-Sydney/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Sydney::Line::T8

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/earlybean4/Map-Tube-Sydney/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-Sydney>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-Sydney>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Map-Tube-Sydney>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Peter Harrison.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may  obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Map::Tube::Sydney::Line::T8
