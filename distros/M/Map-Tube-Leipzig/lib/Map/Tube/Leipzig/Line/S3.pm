package Map::Tube::Leipzig::Line::S3;

$Map::Tube::Leipzig::Line::S3::VERSION   = '0.03';
$Map::Tube::Leipzig::Line::S3::AUTHORITY = 'cpan:MANWAR';

use v5.14;
use strict;
use warnings;

=head1 NAME

Map::Tube::Leipzig::Line::S3 - Leipzig Rail Map: S3 Line.

=head1 VERSION

Version 0.03

=encoding utf8

=head1 DESCRIPTION

Leipzig Rail Map: S3.

    +---------------------------+-----------------------------------------+
    | Station Name              | Connected To                            |
    +---------------------------+-----------------------------------------+
    | Trotha                    | Wohnstadt Nord                          |
    | Wohnstadt Nord            | Trotha, Zoo                             |
    | Zoo                       | Wohnstadt Nord, Dessauer Brücke         |
    | Dessauer Brücke           | Zoo, Steintorbrücke                     |
    | Steintorbrücke            | Dessauer Brücke,                        |
    | Halle Hbf                 | Steintorbrücke, Halle Messe             |
    | Halle Messe               | Halle Hbf, Dieskau                      |
    | Dieskau                   | Halle Messe, Gröbers                    |
    | Gröbers                   | Dieskau, Großkugel                      |
    | Großkugel                 | Gröbers, Schkeuditz                     |
    | Schkeuditz                | Großkugel, Lützschena                   |
    | Lützschena                | Schkeuditz, Wahren                      |
    | Wahren                    | Lützschena, Slevogt-str                 |
    | Slevogt-str               | Wahren, Olbritch-str                    |
    | Olbritch-str              | Slevogt-str, Gohlis,                    |
    | Gohlis                    | Olbritch-str, Leipzig Hbf               |
    | Leipzig Hbf               | Gehlis, Markt                           |
    | Markt                     | Leipzig Hbf, Wilhelm-Leuschner-PI.      |
    | Wilhelm-Leuschner-PI.     | Markt, Bayerischer Bf                   |
    | Bayerischer Bf            | Wilhelm-Leuschner-PI., MDR              |
    | MDR                       | Bayerischer Bf, Connewitz               |
    | Connewitz                 | MDR, Markkleeberg                       |
    | Markkleeberg              | Connewitz, Markkleeberg-Großstädtein    |
    | Markkleeberg-Großstädtein | Markkleeberg, Großdeuben                |
    | Großdeuben                | Markkleeberg-Großstädtein, Böhlen Werke |
    | Böhlen Werke              | Großdeuben, NeuKieritzsch               |
    | NeuKieritzsch             | Böhlen Werke, Lobstädt                  |
    | Lobstädt                  | NeuKieritzsch, Borna                    |
    | Borna                     | Lobstädt, Petergrube                    |
    | Petergrube                | Borna, Neukirchen-Wyrha                 |
    | Neukirchen-Wyrha          | Petergrube, Frohburg                    |
    | Frohburg                  | Neukirchen-Wyrha, Geithain              |
    | Geithain                  | Frohburg                                |
    +---------------------------+-----------------------------------------+

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-Leipzig>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Map-Tube-Leipzig/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Leipzig

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Map-Tube-Leipzig/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-Leipzig>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-Leipzig>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Map-Tube-Leipzig>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the   terms  of the the Artistic License (2.0). You may obtain a copy of the full
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

1; # End of Map::Tube::Leipzig::Line::S3
