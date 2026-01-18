package Map::Tube::Sydney::Line::T3;

$Map::Tube::Sydney::Line::T3::VERSION   = '1.01';
$Map::Tube::Sydney::Line::T3::AUTHORITY = 'cpan:EARLYBEAN';

use 5.006;
use strict; use warnings;

=head1 NAME

Map::Tube::Sydney::Line::T3 - Sydney Rail Map: T3 Line.

=head1 VERSION

Version 1.01

=head1 DESCRIPTION

Sydney Rail Map: T3 Line.

    +---------------+----------------------------+
    | Station Name  | Connected To               |
    +---------------+----------------------------+
    | Museum        | Central, St James          |
    | St James      | Museum, Circular Quay      |
    | Circular Quay | St James, Wynyard          |
    | Wynyard       | Circular Quay, Town Hall   |
    | Town Hall     | Wynyard, Central           |
    | Central       | Town Hall, Museum, Redfern |
    | Redfern       | Central, Macdonaldtown     |
    | Macdonaldtown | Redfern, Newtown           |
    | Newtown       | Macdonaldtown, Stanmore    |
    | Stanmore      | Newtown, Petersham         |
    | Petersham     | Stanmore, Lewisham         |
    | Lewisham      | Petersham, Summer Hill     |
    | Summer Hill   | Lewisham, Ashfield         |
    | Ashfield      | Summer Hill, Croydon       |
    | Croydon       | Ashfield, Burwood          |
    | Burwood       | Croydon, Strathfield       |
    | Strathfield   | Burwood, Homebush          |
    | Homebush      | Strathfield, Flemington    |
    | Flemington    | Homebush, Lidcombe         |
    | Lidcombe      | Flemington, Berala         |
    | Berala        | Lidcombe, Regents Park     |
    | Regents Park  | Berala, Sefton             |
    | Sefton        | Regents Park, Chester Hill |
    | Chester Hill  | Sefton, Leightonfield      |
    | Leightonfield | Chester Hill, Villawood    |
    | Villawood     | Leightonfield, Carramar    |
    | Carramar      | Villawood, Cabramatta      |
    | Cabramatta    | Carramar, Warwick Farm     |
    | Warwick Farm  | Cabramatta, Liverpool      |
    | Liverpool     | Warwick Farm               |
    +---------------+----------------------------+

=head1 NOTE

=over 2

=item * The station "Ashfield" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>

=item * The station "Berala" is also part of
          L<T6 Line|Map::Tube::Sydney::Line::T6>

=item * The station "Burwood" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T9 Line|Map::Tube::Sydney::Line::T9>

=item * The station "Cabramatta" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T5 Line|Map::Tube::Sydney::Line::T5>

=item * The station "Central" is also part of
          L<T1 Line|Map::Tube::Sydney::Line::T1>
        | L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T4 Line|Map::Tube::Sydney::Line::T4>
        | L<T8 Line|Map::Tube::Sydney::Line::T8>
        | L<T9 Line|Map::Tube::Sydney::Line::T9>
        | L<M1 Line|Map::Tube::Sydney::Line::M1>

=item * The station "Circular Quay" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T8 Line|Map::Tube::Sydney::Line::T8>
        | L<L2 Line|Map::Tube::Sydney::Line::L2>
        | L<L3 Line|Map::Tube::Sydney::Line::L3>

=item * The station "Croydon" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>

=item * The station "Flemington" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>

=item * The station "Homebush" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>

=item * The station "Lewisham" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>

=item * The station "Lidcombe" is also part of
          L<T1 Line|Map::Tube::Sydney::Line::T1>
        | L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T6 Line|Map::Tube::Sydney::Line::T6>
        | L<T7 Line|Map::Tube::Sydney::Line::T7>

=item * The station "Liverpool" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T5 Line|Map::Tube::Sydney::Line::T5>

=item * The station "Macdonaldtown" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>

=item * The station "Museum" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T8 Line|Map::Tube::Sydney::Line::T8>

=item * The station "Newtown" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>

=item * The station "Petersham" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>

=item * The station "Redfern" is also part of
          L<T1 Line|Map::Tube::Sydney::Line::T1>
        | L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T4 Line|Map::Tube::Sydney::Line::T4>
        | L<T8 Line|Map::Tube::Sydney::Line::T8>
        | L<T9 Line|Map::Tube::Sydney::Line::T9>

=item * The station "Regents Park" is also part of
          L<T6 Line|Map::Tube::Sydney::Line::T6>

=item * The station "St James" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T8 Line|Map::Tube::Sydney::Line::T8>

=item * The station "Stanmore" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>

=item * The station "Strathfield" is also part of
          L<T1 Line|Map::Tube::Sydney::Line::T1>
        | L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T9 Line|Map::Tube::Sydney::Line::T9>

=item * The station "Summer Hill" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>

=item * The station "Town Hall" is also part of
          L<T1 Line|Map::Tube::Sydney::Line::T1>
        | L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T4 Line|Map::Tube::Sydney::Line::T4>
        | L<T8 Line|Map::Tube::Sydney::Line::T8>
        | L<T9 Line|Map::Tube::Sydney::Line::T9>
        | L<L2 Line|Map::Tube::Sydney::Line::L2>
        | L<L3 Line|Map::Tube::Sydney::Line::L3>

=item * The station "Warwick Farm" is also part of
          L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T5 Line|Map::Tube::Sydney::Line::T5>

=item * The station "Wynyard" is also part of
          L<T1 Line|Map::Tube::Sydney::Line::T1>
        | L<T2 Line|Map::Tube::Sydney::Line::T2>
        | L<T8 Line|Map::Tube::Sydney::Line::T8>
        | L<T9 Line|Map::Tube::Sydney::Line::T9>
        | L<L2 Line|Map::Tube::Sydney::Line::L2>
        | L<L3 Line|Map::Tube::Sydney::Line::L3>

=back

=head1 MAP

Sydney Rail Map: L<T3 Line|https://raw.githubusercontent.com/earlybean4/Map-Tube-Sydney/master/maps/T3.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/earlybean4/Map-Tube-Sydney/master/maps/T3.png">
<img src    = "https://raw.githubusercontent.com/earlybean4/Map-Tube-Sydney/master/maps/T3.png"
     alt    = "Sydney Rail Map: T3 Line"
     width  = "729px"
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

    perldoc Map::Tube::Sydney::Line::T3

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

This program is  free software; you  can redistribute it and / or modify it under
the  terms  of the the Artistic  License (2.0). You may obtain a copy of the full
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

1; # End of Map::Tube::Sydney::Line::T3
