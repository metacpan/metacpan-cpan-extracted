package Map::Tube::London::Line::Central;

$Map::Tube::London::Line::Central::VERSION   = '1.32';
$Map::Tube::London::Line::Central::AUTHORITY = 'cpan:MANWAR';

use 5.006;
use strict; use warnings;

=head1 NAME

Map::Tube::London::Line::Central - London Tube Map: Central Line.

=head1 VERSION

Version 1.32

=head1 DESCRIPTION

London Tube Map: Central Line.

    +----------------------+----------------------------------------------------+
    | Station Name         | Linked To                                          |
    +----------------------+----------------------------------------------------+
    | West Ruislip         | Ruislip Gardens                                    |
    | Ruislip Gardens      | West Ruislip, South Ruislip                        |
    | South Ruislip        | Ruislip Gardens, Northolt                          |
    | Northolt             | South Ruislip, Greenford                           |
    | Greenford            | Northolt, Perivale                                 |
    | Perivale             | Greenford, Hanger Lane                             |
    | Hanger Lane          | Perivale, Ealing Broadway                          |
    | Ealing Broadway      | Hanger Lane, West Acton                            |
    | West Acton           | Ealing Broadway, North Acton                       |
    | North Acton          | West Acton, East Acton                             |
    | East Acton           | North Acton, White City                            |
    | White City           | East Acton, Shepherd's Bush                        |
    | Shepherd's Bush      | White City, Holland Park                           |
    | Holland Park         | Shepherd's Bush, Notting Hill Gate                 |
    | Notting Hill Gate    | Holland Park, Queensway                            |
    | Queensway            | Notting Hill Gate, Lancaster Gate                  |
    | Lancaster Gate       | Queensway, Marble Arch                             |
    | Marble Arch          | Lancaster Gate, Bond Street                        |
    | Bond Street          | Marble Arch, Oxford Circus                         |
    | Oxford Circus        | Bond Street, Tottenham Court Road                  |
    | Tottenham Court Road | Oxford Circus, Holborn                             |
    | Holborn              | Tottenham Court Road, Chancery Lane                |
    | Chancery Lane        | Holborn, St. Paul's                                |
    | St. Paul's           | Chancery Lane, Bank                                |
    | Bank                 | St. Paul's, Liverpool Street                       |
    | Liverpool Street     | Bank, Bethnal Green                                |
    | Bethnal Green        | Liverpool Street, Mile End                         |
    | Mile End             | Bethnal Green, Stratford                           |
    | Stratford            | Mile End, Leyton                                   |
    | Leyton               | Stratford, Leytonstone                             |
    | Leytonstone          | Leyton, Wanstead                                   |
    | Wanstead             | Leytonstone, Redbridge                             |
    | Redbridge            | Wanstead, Gants Hill                               |
    | Gants Hill           | Redbridge, Newbury Park                            |
    | Newbury Park         | Gants Hill, Barkingside                            |
    | Barkingside          | Newbury Park, Fairlop                              |
    | Fairlop              | Barkingside, Hainault                              |
    | Hainault             | Fairlop, Grange Hill                               |
    | Grange Hill          | Hainault, Chigwell                                 |
    | Chigwell             | Grange Hill, Roding Valley                         |
    | Roding Valley        | Chigwell, Snaresbrook                              |
    | Snaresbrook          | Roding Valley, South Woodford                      |
    | South Woodford       | Snaresbrook, Woodford                              |
    | Woodford             | South Woodford, Buckhurst Hill                     |
    | Buckhurst Hill       | Woodford, Loughton                                 |
    | Loughton             | Buckhurst Hill, Debden                             |
    | Debden               | Loughton, Theydon Bois                             |
    | Theydon Bois         | Debden, Epping                                     |
    | Epping               | Theydon Bois                                       |
    +----------------------+----------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Bank" is also part of
          L<DLR Line|Map::Tube::London::Line::Dlr>
        | L<Northern Line|Map::Tube::London::Line::Northern>
        | L<Waterloo & City Line|Map::Tube::London::Line::WaterlooCity>

=item * The station "Bond Street" is also part of
          L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Ealing Broadway" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Holborn" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Liverpool Street" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Mile End" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Notting Hill Gate" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Oxford Circus" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Shepherd's Bush" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Stratford" is also part of
          L<DLR Line|Map::Tube::London::Line::Dlr>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Tottenham Court Road" is also part of
          L<Northern Line|Map::Tube::London::Line::Northern>

=back

=head1 MAP

London Tube Map: L<Central Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Central.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Central.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Central.png"
     alt    = "London Tube Map: Central Line"
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

    perldoc Map::Tube::London::Line::Central

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

1; # End of Map::Tube::London::Line::Central
