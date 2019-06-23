package Map::Tube::London::Line::Piccadilly;

$Map::Tube::London::Line::Piccadilly::VERSION   = '1.31';
$Map::Tube::London::Line::Piccadilly::AUTHORITY = 'cpan:MANWAR';

use 5.006;
use strict; use warnings;

=head1 NAME

Map::Tube::London::Line::Piccadilly - London Tube Map: Piccadilly Line.

=head1 VERSION

Version 1.31

=head1 DESCRIPTION

London Tube Map: Piccadilly Line.

    +---------------------------+-----------------------------------------------+
    | Station Name              | Connected To                                  |
    +---------------------------+-----------------------------------------------+
    | Uxbridge                  | Hillingdon                                    |
    | Hillingdon                | Uxbridge, Ickenham                            |
    | Ickenham                  | Hillingdon, Ruislip                           |
    | Ruislip                   | Ickenham, Ruislip Manor                       |
    | Ruislip Manor             | Ruislip, Eastcote                             |
    | Eastcote                  | Ruislip Manor, Rayners Lane                   |
    | Rayners Lane              | Eastcote, South Harrow                        |
    | South Harrow              | Rayners Lane, Sudbury Hill                    |
    | Sudbury Hill              | South Harrow, Sudbury Town                    |
    | Sudbury Town              | Sudbury Hill, Alperton                        |
    | Alperton                  | Sudbury Town, Park Royal                      |
    | Park Royal                | Alperton, North Ealing                        |
    | North Ealing              | Park Royal, Ealing Common                     |
    | Ealing Common             | North Ealing, Acton Town                      |
    | Acton Town                | Ealing Common, South Ealing, Turnham Green    |
    | South Ealing              | Acton Town, Northfields                       |
    | Northfields               | South Ealing, Boston Manor                    |
    | Boston Manor              | Northfields, Osterley                         |
    | Osterley                  | Boston Manor, Hounslow East                   |
    | Hounslow East             | Osterley, Hounslow Central                    |
    | Hounslow Central          | Hounslow East, Hounslow West                  |
    | Hounslow West             | Hounslow Central, Hatton Cross                |
    | Hatton Cross              | Hounslow West, Heathrow Terminal 4,           |
    | Heathrow Terminal 4       | Heathrow Terminal 5                           |
    | Heathrow Terminal 5       | Heathrow Terminal 1,2,3                       |
    | Heathrow Terminal 1,2,3   | Hatton Cross                                  |
    | Turnham Green             | Acton Town, Hammersmith                       |
    | Hammersmith               | Turnham Green, Barons Court                   |
    | Barons Court              | Hammersmith, Earl's Court                     |
    | Earl's Court              | Barons Court, Gloucester Road                 |
    | Gloucester Road           | Earl's Court, South Kensington                |
    | South Kensington          | Gloucester Road, Knightsbridge                |
    | Knightsbridge             | South Kensington, Hyde Park Corner            |
    | Hyde Park Corner          | Knightsbridge, Green Park                     |
    | Green Park                | Hyde Park Corner, Piccadilly Circus           |
    | Piccadilly Circus         | Green Park, Leicester Square                  |
    | Leicester Square          | Piccadilly Circus, Covent Garden              |
    | Covent Garden             | Leicester Square, Holborn                     |
    | Holborn                   | Covent Garden, Russell Square                 |
    | Russell Square            | Holborn, King's Square St. Pancras            |
    | King's Square St. Pancras | Russell Square, Caledonian Road               |
    | Caledonian Road           | King's Square St. Pancras, Holloway Road      |
    | Holloway Road             | Caledonian Road, Arsenal                      |
    | Arsenal                   | Holloway Road, Finsbury Park                  |
    | Finsbury Park             | Arsenal, Manor House                          |
    | Manor House               | Finsbury Park, Turnpike Lane                  |
    | Turnpike Lane             | Manor House, Wood Green                       |
    | Wood Green                | Turnpike Lane, Bounds Green                   |
    | Bounds Green              | Wood Green, Arnos Grove                       |
    | Arnos Grove               | Bounds Green, Southgate                       |
    | Southgate                 | Arnos Grove, Oakwood                          |
    | Oakwood                   | Southgate, Cockfosters                        |
    | Cockfosters               | Oakwood                                       |
    +---------------------------+-----------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Acton Town" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Barons Court" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Ealing Common" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Earl's Court" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Eastcote" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Finsbury Park" is also part of
          L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Gloucester Road" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Green Park" is also part of
          L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Hammersmith" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Hillingdon" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Holborn" is also part of
          L<Central Line|Map::Tube::London::Line::Central>

=item * The station "Ickenham" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "King's Cross St. Pancras" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>
        | L<Northern Line|Map::Tube::London::Line::Northern>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Leicester Square" is also part of
          L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Piccadilly Circus" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "Rayners Lane" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Ruislip" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Ruislip Manor" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "South Kensington" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Turnham Green" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Uxbridge" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=back

=head1 MAP

London Tube Map: L<Piccadilly Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Piccadilly.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Piccadilly.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Piccadilly.png"
     alt    = "London Tube Map: Piccadilly Line"
     width  = "400px"
     height = "600px"/>
</a>

=end html

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Map-Tube-London>

=head1 BUGS

Please report any bugs or feature requests to C<bug-map-tube-london at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-London>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::London::Line::Piccadilly

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

1; # End of Map::Tube::London::Line::Piccadilly
