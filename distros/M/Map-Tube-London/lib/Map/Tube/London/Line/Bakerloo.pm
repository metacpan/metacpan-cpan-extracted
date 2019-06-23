package Map::Tube::London::Line::Bakerloo;

$Map::Tube::London::Line::Bakerloo::VERSION   = '1.31';
$Map::Tube::London::Line::Bakerloo::AUTHORITY = 'cpan:MANWAR';

use 5.006;
use strict; use warnings;

=head1 NAME

Map::Tube::London::Line::Bakerloo - London Tube Map: Bakerloo Line.

=head1 VERSION

Version 1.31

=head1 DESCRIPTION

London Tube Map: Bakerloo Line.

    +-----------------------+---------------------------------------------------+
    | Station Name          | Linked To                                         |
    +-----------------------+---------------------------------------------------+
    | Harrow & Wealdstone   | Kenton                                            |
    | Kenton                | Harrow & Wealdstone, South Kenton                 |
    | South Kenton          | Kenton, North Wembley                             |
    | North Wembley         | South Kenton, Wembley Central                     |
    | Wembley Central       | North Wembley, Stonebridge Park                   |
    | Stonebridge Park      | Wembley Central, Harlesden                        |
    | Harlesden             | Stonebridge Park, Willesden Junction              |
    | Willesden Junction    | Harlesden, Kensal Green                           |
    | Kensal Green          | Willesden Junction, Queen's Park                  |
    | Queen's Park          | Kensal Green, Kilburn Park                        |
    | Kilburn Park          | Queen's Park, Maida Vale                          |
    | Maida Vale            | Kilburn Park, Warwick Avenue                      |
    | Warwick Avenue        | Maida Vale, Paddington                            |
    | Paddington            | Warwick Avenue, Edgware Road                      |
    | Edgware Road          | Paddington, Marylebone                            |
    | Marylebone            | Edgware Road, Baker Street                        |
    | Baker Street          | Marylebone, Regent's Park                         |
    | Regent's Park         | Baker Street, Oxford Circus                       |
    | Oxford Circus         | Regent's Park, Picadilly Circus                   |
    | Piccadilly Circus     | Oxford Circus, Charing Cross                      |
    | Charing Cross         | Picadilly Circus, Embankment                      |
    | Embankment            | Charing Cross, Waterloo                           |
    | Waterloo              | Embankment, Lambeth North                         |
    | Lambeth North         | Waterloo, Elephant & Castle                       |
    | Elephant & Castle     | Lambeth North                                     |
    +-----------------------+---------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Baker Street" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Charing Cross" is also part of
          L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Edgware Road" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Embankment" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Harlesden" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Harrow & Wealdstone" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Kensal Green" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Kenton" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "North Wembley" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Oxford Circus" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Paddington" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Piccadilly Circus" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "South Kenton" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Stonebridge Park" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Waterloo" is also part of
          L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Northern Line|Map::Tube::London::Line::Northern>
        | L<Waterloo & City Line|Map::Tube::London::Line::WaterlooCity>

=item * The station "Wembley Central" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Willesden Junction" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=back

=head1 MAP

London Tube Map: L<Bakerloo Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Bakerloo.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Bakerloo.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Bakerloo.png"
     alt    = "London Tube Map: Bakerloo Line"
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

    perldoc Map::Tube::London::Line::Bakerloo

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

This program is  free software;  you can redistribute it and / or modify it under
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

1; # End of Map::Tube::London::Line::Bakerloo
