package Map::Tube::Exception;
$Map::Tube::Exception::AUTHORITY = 'cpan:MANWAR';
$Map::Tube::Exception::VERSION = '3.14';
=head1 NAME

Map::Tube::Exception - Base exception package as Moo Role for Map::Tube::* family.

=head1 VERSION

version 3.14

=cut

use 5.006;
use Data::Dumper;

use Moo::Role;
use namespace::clean;
requires qw(status);
with 'Throwable';

use overload q{""} => 'as_string', fallback => 1;

has method      => (is => 'ro');
has message     => (is => 'ro');
has filename    => (is => 'ro');
has line_number => (is => 'ro');

sub as_string {
    my ($self) = @_;

    return sprintf("%s(): %s (status: %s) file %s on line %d\n",
                   $self->method, $self->message, $self->status,
                   $self->filename, $self->line_number);
}

=head1 DESCRIPTION

Base exception package as Moo Role for Map::Tube::* family.

Extracted out of the distribution L<Map::Tube> v3.0,so that it can be shared with
Map::Tube and it's Map::Tube::* family. It has been re-structured in the process.

=head1 STATUS CODES

    +-------------+-------------------------------------------------------------+
    | Status Code | Description                                                 |
    +-------------+-------------------------------------------------------------+
    |     100     | Missing station name.                                       |
    |     101     | Invalid station name.                                       |
    |     102     | Missing station id.                                         |
    |     103     | Invalid station id.                                         |
    |     104     | Missing line name.                                          |
    |     105     | Invalid line name.                                          |
    |     106     | Missing node object i.e. Map::Tube::Node.                   |
    |     107     | Invalid node object.                                        |
    |     108     | Missing plugin graph i.e Map::Tube::Plugin::Graph.          |
    |     109     | Duplicate station name.                                     |
    |     110     | Duplicate station id.                                       |
    |     111     | Found self linked station.                                  |
    |     112     | Found multi linked station.                                 |
    |     113     | Found multi lined station.                                  |
    |     114     | Found unsupported map.                                      |
    |     115     | Missing supported map.                                      |
    |     116     | Found unsupported object.                                   |
    |     117     | Missing supported object, Map::Tube::Node / Map::Tube::Line |
    |     118     | Invalid supported object.                                   |
    |     119     | Invalid line id.                                            |
    |     120     | Missing line id.                                            |
    |     121     | Missing plugin fuzzy find i.e. Map::Tube::Plugin::FuzzyFind |
    |     122     | Missing plugin formatter i.e. Map::Tube::Plugin::Formatter  |
    |     123     | Invalid line color.                                         |
    |     124     | Missing Map Data.                                           |
    |     125     | Found unsupported map data format.                          |
    |     126     | Malformed Map Data.                                         |
    |     127     | Invalid color hex code.                                     |
    +-------------+-------------------------------------------------------------+

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-Exception>

=head1 BUGS

Please  report  any  bugs  or  feature requests to C<bug-map-tube-exception at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-Exception>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Exception

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube-Exception>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-Exception>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-Exception>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube-Exception/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2016 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or  modify it under
the  terms  of the the Artistic License (2.0).  You may obtain a copy of the full
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

1; # End of Map::Tube::Exception
