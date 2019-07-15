package Map::Tube::NYC::Line::INDEighthAvenue;

$Map::Tube::NYC::Line::INDEighthAvenue::VERSION   = '0.69';
$Map::Tube::NYC::Line::INDEighthAvenue::AUTHORITY = 'cpan:MANWAR';

use 5.006;
use strict; use warnings;

=head1 NAME

Map::Tube::NYC::Line::INDEighthAvenue - NYC Subway Map: IND Eighth Avenue Line.

=head1 VERSION

Version 0.69

=head1 DESCRIPTION

NYC Subway Map: IND Eighth Avenue Line.

    +---------------------+-----------------------------------------------------+
    | Station Name        | Connected To                                        |
    +---------------------+-----------------------------------------------------+
    | 207th Street        | Dyckman Street                                      |
    | Dyckman Street      | 207th Street, 190th Street                          |
    | 190th Street        | Dyckman Street, 181st Street                        |
    | 181st Street        | 190th Street, 175th Street                          |
    | 175th Street        | 181st Street, 168th Street                          |
    | 168th Street        | 175th Street, 163rd Street                          |
    | 163rd Street        | 168td Street, 155th Street                          |
    | 155th Street        | 163rd Street, 145th Street                          |
    | 145th Street        | 155th Street, 135th Street                          |
    | 135th Street        | 145th Street, 125th Street                          |
    | 125th Street        | 135th Street, 116th Street                          |
    | 116th Street        | 125th Street, 110th Street                          |
    | 110th Street        | 116th Street, 103rd Street                          |
    | 103rd Street        | 110th Street, 96th Street                           |
    | 96th Street         | 103rd Street, 86th Street                           |
    | 86th Street         | 96th Street, 81st Street                            |
    | 81st Street         | 86th Street, 72nd Street                            |
    | 72nd Street         | 81st Street, 59th Street                            |
    | 59th Street         | 72nd Street, 50th Street                            |
    | 50th Street         | 59th Street, 42nd Street                            |
    | 42nd Street         | 50th Street, 34th Street                            |
    | 34th Street         | 42nd Street, 23rd Street                            |
    | 23rd Street         | 34th Street, Union Square                           |
    | Union Square        | 23rd Street, West Fourth Street                     |
    | West Fourth Street  | Union Square, Spring Stree                          |
    | Spring Street       | West Fourth Street, Canal Street                    |
    | Canal Street        | Spring Street, Chambers Street                      |
    | Chambers Street     | Canal Street, Fulton Street                         |
    | Fulton Street       | Chambers Street, High Street                        |
    | High Street         | Fulton Street                                       |
    +---------------------+-----------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "West Fourth Street" is also part of
          L<IND Sixth Avenue Line|Map::Tube::NYC::Line::INDSixthAvenue>.

=item * The station "Fulton Street" is also part of
          IRT Broadway Line
        | L<IRT Lexington Avenue|Map::Tube::NYC::Line::IRTLexingtonAvenue>
        | L<BMT Nassau Street Line|Map::Tube::NYC::Line::BMTNassauStreet>.

=item * The station "Canal Street" is also part of
          L<BMT Nassau Street Line|Map::Tube::NYC::Line::BMTNassauStreet>
        | L<IRT Lexington Avenue|Map::Tube::NYC::Line::IRTLexingtonAvenue>.

=item * The station "Chambers Street" is also part of
          L<BMT Nassau Street Line|Map::Tube::NYC::Line::BMTNassauStreet>.

=item * The station "Union Square" is also part of
          L<BMT Canarsie Line|Map::Tube::NYC::Line::BMTCanarsie>.

=item * The station "59th Street" is also part of
          IRT Broadway Line
        | L<IRT Lexington Avenue|Map::Tube::NYC::Line::IRTLexingtonAvenue>.

=item * The station "42nd Street" is also part of
          IRT Broadway Line
        | L<IRT Flushing Line|Map::Tube::NYC::Line::IRTFlushing>.

=item * The station "125th Street" is also part of
          L<IRT Lexington Avenue|Map::Tube::NYC::Line::IRTLexingtonAvenue>.

=item * The station "116th Street" is also part of
          L<IRT Lexington Avenue|Map::Tube::NYC::Line::IRTLexingtonAvenue>.

=item * The station "110th Street" is also part of
          L<IRT Lexington Avenue|Map::Tube::NYC::Line::IRTLexingtonAvenue>.

=item * The station "103rd Street" is also part of
          L<IRT Lexington Avenue|Map::Tube::NYC::Line::IRTLexingtonAvenue>.

=item * The station "96th Street" is also part of
          L<IRT Lexington Avenue|Map::Tube::NYC::Line::IRTLexingtonAvenue>.

=item * The station "86th Street" is also part of
          L<IRT Lexington Avenue|Map::Tube::NYC::Line::IRTLexingtonAvenue>.

=item * The station "33rd Street" is also part of
          L<IRT Lexington Avenue|Map::Tube::NYC::Line::IRTLexingtonAvenue>.

=back

=head1 MAP

NYC Subway Map: L<IND Eighth Avenue Line|https://raw.githubusercontent.com/manwar/Map-Tube-NYC/master/maps/IND-Eighth-Avenue.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-NYC/master/maps/IND-Eighth-Avenue.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-NYC/master/maps/IND-Eighth-Avenue.png"
     alt    = "NYC Subway Map: IND Eighth Avenue Line"
     width  = "300px"
     height = "600px"/>
</a>

=end html

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-NYC>

=head1 BUGS

Please report any bugs/feature requests to C<bug-map-tube-nyc at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-NYC>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::NYC::Line::INDEighthAvenue

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube-NYC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-NYC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-NYC>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube-NYC/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2019 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
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

1; # End of Map::Tube::NYC::Line::INDEighthAvenue
