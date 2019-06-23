package Map::Tube::London::Line::Northern;

$Map::Tube::London::Line::Northern::VERSION   = '1.31';
$Map::Tube::London::Line::Northern::AUTHORITY = 'cpan:MANWAR';

use 5.006;
use strict; use warnings;

=head1 NAME

Map::Tube::London::Line::Northern - London Tube Map: Northern Line.

=head1 VERSION

Version 1.31

=head1 DESCRIPTION

London Tube Map: Northern Line.

=head2 High Barnet Branch

    +--------------------------+------------------------------------------------+
    | Station Name             | Connected To                                   |
    +--------------------------+------------------------------------------------+
    | High Barnet              | Totteridge & Whetstone                         |
    | Totteridge & Whetstone   | High Barnet, Woodside Park                     |
    | Woodside Park            | Totteridge & Whetstone, West Finchley          |
    | West Finchley            | Woodside Park, Mill Hill East                  |
    | Mill Hill East           | West Finchley, Finchley Central                |
    | Finchley Central         | Mill Hill East, East Finchley                  |
    | East Finchley            | Finchley Central, Highgate                     |
    | Highgate                 | East Finchley, Archway                         |
    | Archway                  | Highgate, Tufnell Park                         |
    | Tufnell Park             | Archway, Kentish Town                          |
    | Kentish Town             | Tufnell Park                                   |
    +--------------------------+------------------------------------------------+

=head2 Edgware Branch

    +--------------------------+------------------------------------------------+
    | Station Name             | Connected To                                   |
    +--------------------------+------------------------------------------------+
    | Edgware                  | Burnt Oak                                      |
    | Burnt Oak                | Edgware Road, Collindale                       |
    | Colindale                | Burnt Oak, Hendon Central                      |
    | Hendon Central           | Collindale, Brent Cross                        |
    | Brent Cross              | Hendon Central, Golders Green                  |
    | Golders Green            | Brent Cross, Hamstead                          |
    | Hampstead                | Golders Green, Belsize Park                    |
    | Belsize Park             | Hampstead, Chalk Farm                          |
    | Chalk Farm               | Belsize Park                                   |
    +--------------------------+------------------------------------------------+

=head2 Charing Cross Branch

    +--------------------------+------------------------------------------------+
    | Station Name             | Connected To                                   |
    +--------------------------+------------------------------------------------+
    | Mornington Crescent      | Euston                                         |
    | Euston                   | Mornington Crescent, Warren Street             |
    | Warren Street            | Euston, Goodge Street                          |
    | Goodge Street            | Warren Street, Tottenham Court Road            |
    | Tottenham Court Road     | Goodge Street, Leicester Square                |
    | Leicester Square         | Tottenham Court Road, Charing Cross            |
    | Charing Cross            | Leicester Square, Embankment                   |
    | Embankment               | Charing Cross, Waterloo                        |
    | Waterloo                 | Embankment                                     |
    +--------------------------+------------------------------------------------+

=head2 Bank Branch

    +--------------------------+------------------------------------------------+
    | Station Name             | Connected To                                   |
    +--------------------------+------------------------------------------------+
    | Euston                   | King's Cross St. Pancras                       |
    | King's Cross St. Pancras | Euston, Angel                                  |
    | Angel                    | King's Cross St. Pancras, Old Street           |
    | Old Street               | Angel, Moorgate                                |
    | Moorgate                 | Old Street, Bank                               |
    | Bank                     | Moorgate, London Bridge                        |
    | London Bridge            | Bank, Borough                                  |
    | Borough                  | London Bridge, Elephant and Castle             |
    | Elephant and Castle      | Borough                                        |
    +--------------------------+------------------------------------------------+

=head2 Morden Branch

    +--------------------------+------------------------------------------------+
    | Station Name             | Connected To                                   |
    +--------------------------+------------------------------------------------+
    | Kennington               | Oval                                           |
    | Oval                     | Kennington, Stockwell                          |
    | Stockwell                | Oval, Clapham North                            |
    | Clapham North            | Stockwell, Clapham Common                      |
    | Clapham Common           | Clapham North, Clapham South                   |
    | Clapham South            | Clapham Common, Balham                         |
    | Balham                   | Clapham South, Tooting Bec                     |
    | Tooting Bec              | Balham, Tooting Broadway                       |
    | Tooting Broadway         | Tooting Bec, Colliers Wood                     |
    | Colliers Wood            | Tooting Broadway, South Wimbledon              |
    | South Wimbledon          | Colliers Wood, Morden                          |
    | Morden                   | South Wimbledon                                |
    +--------------------------+------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Bank" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<DLR Line|Map::Tube::London::Line::DLR>
        | L<Waterloo & City Line|Map::Tube::London::Line::WaterlooCity>

=item * The station "Charing Cross" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "Embankment" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Euston" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "King's Cross St. Pancras" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Leicester Square" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "London Bridge" is also part of
          L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Moorgate" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Stockwell" is also part of
          L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Tottenham Court Road" is also part of
          L<Central Line|Map::Tube::London::Line::Central>

=item * The station "Warren Street" is also part of
          L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Waterloo" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Waterloo & City Line|Map::Tube::London::Line::WaterlooCity>

=back

=head1 MAP

London Tube Map: L<Northern Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Northern.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Northern.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Northern.png"
     alt    = "London Tube Metro: Northern Line"
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

    perldoc Map::Tube::London::Line::Northern

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

1; # End of Map::Tube::London::Line::Northern
