package Map::Tube::Leipzig;

$Map::Tube::Leipzig::VERSION   = '0.03';
$Map::Tube::Leipzig::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::Leipzig - Interface to the Leipzig Rail Map.

=head1 VERSION

Version 0.03

=cut

use v5.14;
use File::ShareDir ':ALL';

use Moo;
use namespace::autoclean;

has xml => (is => 'ro', default => sub { return dist_file('Map-Tube-Leipzig', 'leipzig-map.xml') });

with 'Map::Tube';

=encoding utf8

=head1 DESCRIPTION

This was created and published while participating in the B<Perl Toolchain Summit 2025> in Leipzip, Germany.

It currently provides functionality to find the shortest  route between  the  two
given  nodes. It covers the following rail lines only for now:

=over 2

=item * L<S3|Map::Tube::Leipzig::Line::S3>

=item * L<S7|Map::Tube::Leipzig::Line::S7>

=back

=head1 MAP DATA

The map data collected from L<this website|https://ontheworldmap.com/germany/city/leipzig/leipzig-rail-map.html>.

=head1 CONSTRUCTOR

The constructor DO NOT expects parameters.This setup the default node definitions.

    use strict;
    use warnings;
    use Map::Tube::Leipzig;

    my $rail = Map::Tube::Leipzig->new;

=head1 METHODS

=head2 get_shortest_route($from, $to)

It expects C<$from> and C<$to> station name, required param. It returns an object
of type L<Map::Tube::Route>. On error it throws exception of type L<Map::Tube::Exception>.

    use strict;
    use warnings;
    use Map::Tube::Leipzig;

    my $rail = Map::Tube::Leipzig->new;
    my $route= $rail->get_shortest_route('Trotha', 'Halle Messe');

    print "Route: $route\n";;

=head2 as_image($line_name)

It expects the plugin  L<Map::Tube::Plugin::Graph> to be  installed. Returns line
image  as  base64  encoded string if C<$line_name> passed in otherwise it returns
base64 encoded string of the entire map.

    use strict;
    use warnings;
    use MIME::Base64;
    use Map::Tube::Leipzig;

    my $rail = Map::Tube::Leipzig->new;
    my $map  = $rail->name;
    open(my $IMAGE, ">", "$map.png")
       or die "ERROR: Can't open [$map.png]: $!";
    binmode($IMAGE);
    print $IMAGE decode_base64($subway->as_image);
    close($IMAGE);

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

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
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

1; # End of Map::Tube::Leipzig
