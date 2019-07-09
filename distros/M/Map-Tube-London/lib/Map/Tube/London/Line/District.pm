package Map::Tube::London::Line::District;

$Map::Tube::London::Line::District::VERSION   = '1.32';
$Map::Tube::London::Line::District::AUTHORITY = 'cpan:MANWAR';

use 5.006;
use strict; use warnings;

=head1 NAME

Map::Tube::London::Line::District - London Tube Map: District Line.

=head1 VERSION

Version 1.32

=head1 DESCRIPTION

London Tube Map: District Line.

    +-------------------------+-------------------------------------------------+
    | Station Name            | Connected To                                    |
    +-------------------------+-------------------------------------------------+
    | Richmond                | Kew Gardens                                     |
    | Kew Gardens             | Richmond, Gunnersbury                           |
    | Gunnersbury             | Kew Gardens, Ealing Broadway                    |
    | Ealing Broadway         | Gunnerbury, Ealing Common                       |
    | Ealing Common           | Ealing Broadway, Acton Towm                     |
    | Acton Town              | Ealing Common, Chiswick Park                    |
    | Chiswick Park           | Acton Town, Turnham Green                       |
    | Turnham Green           | Chiswick Park, Stamford Brook                   |
    | Stamford Brook          | Turnham Green, Havenscourt Park                 |
    | Ravenscourt Park        | Stamford Brook, Hammersmith                     |
    | Hammersmith             | Ravenscourt Park, Barons Court                  |
    | Barons Court            | Hammersmith, West Kensington                    |
    | West Kensington         | Barons Court, Wimbledon                         |
    | Wimbledon               | West Kensington, Wimbledon Park                 |
    | Wimbledon Park          | Wimbledon, Southfields                          |
    | Southfields             | Wimbledon Park, East Putney                     |
    | East Putney             | Southfields, Putney Bridge                      |
    | Putney Bridge           | East Putney, Parsons Green                      |
    | Parsons Green           | Putney Bridge, Fulham Broadway                  |
    | Fulham Broadway         | Parsons Green, West Brompton                    |
    | West Brompton           | Fulham Broadway, Kensington (Olympia)           |
    | Kensington (Olympia)    | West Brompton, Earl's Court                     |
    | Earl's Court            | Kensington (Olympia), High Street Kensington    |
    | High Street Kensington  | Earl's Court, Notting Hill Gate                 |
    | Notting Hill Gate       | High Street Kensington, Bayswater               |
    | Bayswater               | Notting Hill Gate, Paddington                   |
    | Paddington              | Bayswater, Edgware Road                         |
    | Edgware Road            | Paddington, Gloucester Road                     |
    | Gloucester Road         | Edgware Road, South Kensington                  |
    | South Kensington        | Gloucester Road, Sloane Square                  |
    | Sloane Square           | South Kensington, Victoria                      |
    | Victoria                | Sloane Square, St Jame's Park                   |
    | St James's Park         | Victoria, Westminster                           |
    | Westminster             | St Jame's Park, Embankment                      |
    | Embankment              | Westminster, Temple                             |
    | Temple                  | Embankment, Blackfriars                         |
    | Blackfriars             | Temple, Mansion House                           |
    | Mansion House           | Blackfriars, Cannon Street                      |
    | Cannon Street           | Mansion House, Monument                         |
    | Monument                | Cannon Street, Bank, Tower Hill                 |
    | Tower Hill              | Monument, Aldgate East                          |
    | Aldgate East            | Tower Hill, Whitechapel                         |
    | Whitechapel             | Aldgate East, Stepney Green                     |
    | Stepney Green           | Whitechapel, Mile End                           |
    | Mile End                | Stepney Green, Bow Road                         |
    | Bow Road                | Mile End, Bromley-by-Bow                        |
    | Bromley-by-Bow          | Row Road, West Ham                              |
    | West Ham                | Bromley-by-Bow, Plaistow                        |
    | Plaistow                | West Ham, Upton Park                            |
    | Upton Park              | Plaistow, East Ham                              |
    | East Ham                | Upton Park, Barking                             |
    | Barking                 | East Ham, Becontree                             |
    | Becontree               | Barking, Dagenham Heathway                      |
    | Dagenham Heathway       | Becontree, Dagenham East                        |
    | Dagenham East           | Dagenham Heathway, Elm Park                     |
    | Elm Park                | Dagenham East, Hornchurch                       |
    | Hornchurch              | Elm Park, Upminster Bridge                      |
    | Upminster Bridge        | Hornchurch, Upminster                           |
    | Upminster               | Upminster Bridge                                |
    +-------------------------+-------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Acton Town" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Aldgate East" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Barking" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Barons Court" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Bayswater" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Blackfriars" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Bow Road" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Bromley-by-Bow" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Cannon Street" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Ealing Broadway" is also part of
          L<Central Line|Map::Tube::London::Line::Central>

=item * The station "Ealing Common" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Earl's Court" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "East Ham" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Edgware Road" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Embankment" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Gloucester Road" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Gunnersbury" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Hammersmith" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "High Street Kensington" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Kensington (Olympia)" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Mansion House" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Mile End" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Monument" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Notting Hill Gate" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Paddington" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Plaistow" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Richmond" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Sloane Square" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "South Kensington" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "St. James's Park" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Stepney Green" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Temple" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Tower Hill" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Turnham Green" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Upton Park" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Victoria" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "West Brompton" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "West Ham" is also part of
          L<DLR Line|Map::Tube::London::Line::DLR>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Westminster" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Whitechapel" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Overground Line|Map::Tube::London::Line::Overground>

=back

=head1 MAP

London Tube Map: L<District Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/District.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/District.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/District.png"
     alt    = "London Tube Map: District Line"
     width  = "400px"
     height = "600px"/>
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

    perldoc Map::Tube::London::Line::District

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

1; # End of Map::Tube::London::Line::District
