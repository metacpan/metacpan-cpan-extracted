package Map::Tube::London::Line::HammersmithCity;

$Map::Tube::London::Line::HammersmithCity::VERSION   = '1.31';
$Map::Tube::London::Line::HammersmithCity::AUTHORITY = 'cpan:MANWAR';

use 5.006;
use strict; use warnings;

=head1 NAME

Map::Tube::London::Line::HammersmithCity - London Tube Map: Hammersmith & City Line.

=head1 VERSION

Version 1.31

=head1 DESCRIPTION

London Tube Map: Hammersmith & City Line.

    +--------------------------+-------------------------------------------------+
    | Station Name             | Connected To                                    |
    +--------------------------+-------------------------------------------------+
    | Hammersmith              | Goldhawk Road                                   |
    | Goldhawk Road            | Hammersmith, Shepherd's Bush Market             |
    | Shepherd's Bush Market   | Goldhawk Road, Wood Lane                        |
    | Wood Lane                | Shepherd's Bush Market, Latimer Road            |
    | Latimer Road             | Wood Lane, Ladbroke Grove                       |
    | Ladbroke Grove           | Latimer Road, Westbourne Park                   |
    | Westbourne Park          | Ladbroke Grove, Royal Oak                       |
    | Royal Oak                | Westbourne Park, Paddington                     |
    | Paddington               | Royal Oak, Edgware Road                         |
    | Edgware Road             | Paddington, Baker Street                        |
    | Baker Street             | Edgware Road, Great Portland Street             |
    | Great Portland Street    | Baker Street, Euston Square                     |
    | Euston Square            | Great Portland Street, King's Cross St. Pancras |
    | King's Cross St. Pancras | Euston Square, Farringdon                       |
    | Farringdon               | King's Cross St. Pancras, Barbican              |
    | Barbican                 | Farringdon, Moorgate                            |
    | Moorgate                 | Barbican, Liverpool Street                      |
    | Liverpool Street         | Moorgate, Aldgate East                          |
    | Aldgate East             | Liverpool Street, Whitechapel                   |
    | Whitechapel              | Aldgate East, Stepney Green                     |
    | Stepney Green            | Whitechapel, Mile End                           |
    | Mile End                 | Stepney Green, Bow Road                         |
    | Bow Road                 | Mile End, Bromley-by-Bow                        |
    | Bromley-by-Bow           | Bow Road, West Ham                              |
    | West Ham                 | Bromley-by-Bow, Plaistow                        |
    | Plaistow                 | West Ham, Upton Park                            |
    | Upton Park               | Plaistow, East Ham                              |
    | East Ham                 | Upton Park, Barking                             |
    | Barking                  | East Ham                                        |
    +--------------------------+-------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Aldgate East" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Baker Street" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Barbican" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Barking" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Bow Road" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Bromley-by-Bow" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "East Ham" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Edgware Road" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Euston Square" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Farringdon" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Goldhawk Road" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Great Portland Street" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Hammersmith" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "King's Cross St. Pancras" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>
        | L<Northern Line|Map::Tube::London::Line::Northern>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Ladbroke Grove" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Latimer Road" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Liverpool Street" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Mile End" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Moorgate" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>
        | L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Paddington" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Plaistow" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Royal Oak" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Shepherd's Bush Market" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Stepney Green" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Upton Park" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "West Ham" is also part of
          L<DLR Line|Map::Tube::London::Line::Dlr>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Westbourne Park" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Whitechapel" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Wood Lane" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=back

=head1 MAP

London Tube Map: L<Hammersmith & City Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/HammersmithCity.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/HammersmithCity.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/HammersmithCity.png"
     alt    = "London Tube Map: Hammersmith & City Line"
     width  = "500px"
     height = "500px"/>
</a>

=end html

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-London>

=head1 BUGS

Please report any bugs or feature requests to C<bug-map-tube-london at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-London>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::London::Line::HammersmithCity

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube-London>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-London>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-London>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube-London/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2016 Mohammad S Anwar.

This program is  free software; you can  redistribute it and / or modify it under
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

1; # End of Map::Tube::London::Line::HammersmithCity
