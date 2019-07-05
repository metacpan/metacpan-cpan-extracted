package Map::Tube::Delhi::Line::Blue;
$Map::Tube::Delhi::Line::Blue::AUTHORITY = 'cpan:MANWAR';
$Map::Tube::Delhi::Line::Blue::VERSION = '0.92';
use 5.006;
use strict; use warnings;

=head1 NAME

Map::Tube::Delhi::Line::Blue - Delhi Metro Map: Blue Line.

=head1 VERSION

version 0.92

=head1 DESCRIPTION

Delhi Metro Map: Blue Line.

    +-------------------------+-------------------------------------------------+
    | Station Name            | Linked To                                       |
    +-------------------------+-------------------------------------------------+
    | Dwarka Sector 21        | Dwarka Sector 8                                 |
    | Dwarka Sector 8         | Dwarka Sector 9, Dwarka Sector 21               |
    | Dwarka Sector 9         | Dwarka Sector 10, Dwarka Sector 8               |
    | Dwarka Sector 10        | Dwarka Sector 11, Dwarka Sector 9               |
    | Dwarka Sector 11        | Dwarka Sector 12, Dwarka Sector 10              |
    | Dwarka Sector 12        | Dwarka Sector 13, Dwarka Sector 11              |
    | Dwarka Sector 13        | Dwarka Sector 14, Dwarka Sector 12              |
    | Dwarka Sector 14        | Dwarka, Dwarka Sector 13                        |
    | Dwarka                  | Dwarka Mor, Dwarka Sector 14                    |
    | Dwarka Mor              | Nawada, Dwarka                                  |
    | Nawada                  | Uttam Nagar West, Dwarka Mor                    |
    | Uttam Nagar West        | Uttam Nagar East, Nawada                        |
    | Uttam Nagar East        | Janakpuri West, Uttam Nagar West                |
    | Janakpuri West          | Janakpuri East, Uttam Nagar East                |
    | Janakpuri East          | Tilak Nagar, Janakpuri West                     |
    | Tilak Nagar             | Subhash Nagar, Janakpuri East                   |
    | Subhash Nagar           | Tagore Garden, Tilak Nagar                      |
    | Tagore Garden           | Rajouri Garden, Subhash Nagar                   |
    | Rajouri Garden          | Ramesh Garden, Tagore Garden                    |
    | Ramesh Nagar            | Moti Nagar, Rajouri Garden                      |
    | Moti Nagar              | Kirti Nagar, Ramesh Nagar                       |
    | Kirti Nagar             | Shadipur, Moti Nagar                            |
    | Shadipur                | Patel Nagar, Kirti Nagar                        |
    | Patel Nagar             | Rajendra Place, Shadipur                        |
    | Rajendra Place          | Karol Bagh, Patel Nagar                         |
    | Karol Bagh              | Jhandewalan, Rajendra Place                     |
    | Jhandewalan             | Ramkrishna Ashram Marg, Karol Bagh              |
    | Ramkrishna Ashram Marg  | Rajiv Chowk, Jhandewalan                        |
    | Rajiv Chowk             | Barakhamba Road, Ramkrishna Ashram Marg         |
    | Barakhamba Road         | Mandi House, Rajiv Chowk                        |
    | Mandi House             | Pragati Maidan, Barakhamba Road                 |
    | Pragati Maidan          | Indraprastha, Mandi House                       |
    | Indraprastha            | Yamuna Bank, Pragati Maidan                     |
    | Yamuna Bank             | Laxmi Nagar, Akshardham, Indraprastha           |
    | Laxmi Nagar             | Nirman Vihar, Yamuna Bank, Akshardham           |
    | Nirman Vihar            | Preet Vihar, Laxmi Nagar                        |
    | Preet Vihar             | Karkarduma, Nirman Vihar                        |
    | Karkarduma              | Anand Vihar ISBT, Preet Vihar                   |
    | Anand Vihar ISBT        | Kaushambi, Karkarduma                           |
    | Kaushambi               | Vaishali, Anand Vihar ISBT                      |
    | Vaishali                | Kaushambi                                       |
    | Akshardham              | Yamuna Bank, Laxmi Nagar, Mayur Vihar I         |
    | Mayur Vihar I           | Mayur Vihar Extn., Akshardham                   |
    | Mayur Vihar Extn.       | New Ashok Nagar, Mayur Vihar I                  |
    | New Ashok Nagar         | Noida Sector 15, Mayur Vihar Extn.              |
    | Noida Sector 15         | Noida Sector 16, New Ashok Nagar                |
    | Noida Sector 16         | Noida Sector 18, Noida Sector 15                |
    | Noida Sector 18         | Botanical Garden, Noida Sector 16               |
    | Botanical Garden        | Golf Course, Noida Sector 18                    |
    | Golf Course             | Noida City Centre, Botanical Garden             |
    | Noida City Centre       | Golf Course                                     |
    +-------------------------+-------------------------------------------------+

=head2 NOTE

=over 2

=item * The station "Dwarka Sector 21" is also part of
          L<Orange Line|Map::Tube::Delhi::Line::Orange>.

=item * The station "Kirti Nagar" is also part of
          L<Green Line|Map::Tube::Delhi::Line::Green>.

=item * The station "Rajiv Chowk" is also part of
          L<Yellow Line|Map::Tube::Delhi::Line::Yellow>.

=back

=head1 MAP

Delhi Metro Map: L<Blue Line|https://raw.githubusercontent.com/manwar/Map-Tube-Delhi/master/maps/Blue.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-Delhi/master/maps/Blue.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-Delhi/master/maps/Blue.png"
     alt    = "Delhi Metro Map: Blue Line"
     width  = "250px"
     height = "600px"/>
</a>

=end html

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-Delhi>

=head1 BUGS

Please  report any bugs/feature requests to C<bug-map-tube-delhi at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-Delhi>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Delhi::Line::Blue

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube-Delhi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-Delhi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-Delhi>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube-Delhi/>

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

1; # End of Map::Tube::Delhi::Line::Blue
