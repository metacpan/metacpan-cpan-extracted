package Map::Tube::Copenhagen;

$Map::Tube::Copenhagen::VERSION   = '0.04';
$Map::Tube::Copenhagen::AUTHORITY = 'cpan:SLU';

=begin html

<p>
    <a href="https://travis-ci.org/soren/Map-Tube-Copenhagen"><img
        src="https://travis-ci.org/soren/Map-Tube-Copenhagen.svg?branch=master"/></a>
    <a href="https://coveralls.io/github/soren/Map-Tube-Copenhagen?branch=master"><img
        src="https://coveralls.io/repos/github/soren/Map-Tube-Copenhagen/badge.svg?branch=master"/></a>
    <a href="https://metacpan.org/release/Map-Tube-Copenhagen"><img
        src="https://badge.fury.io/pl/Map-Tube-Copenhagen.svg"/></a>
</p>

=end html

=head1 NAME

Map::Tube::Copenhagen - Interface to the Copenhagen Metro map

=head1 VERSION

Version 0.04

=cut

use 5.006;
use Data::Dumper;
use File::Share ':all';

use Moo;
use namespace::autoclean;

has json => (is => 'ro', default => sub { return dist_file('Map-Tube-Copenhagen', 'copenhagen-map.json') });
with 'Map::Tube';

=head1 DESCRIPTION

It currently provides functionality to find the shortest route between the two given stations. It covers the two (and only) metro lines: M1 and M2.

=head1 CONSTRUCTOR

The constructor DO NOT expects parameters.This setup the default node definitions.

    use strict; use warnings;
    use Map::Tube::Copenhagen;

    my $tube = Map::Tube::Copenhagen->new;

=head1 METHODS

=head2 get_shortest_route($from, $to)

It expects C<$from> and C<$to> station name, required param. It returns an object
of type L<Map::Tube::Route>. On error it throws exception of type L<Map::Tube::Exception>.

    use strict; use warnings;
    use Map::Tube::Copenhagen;

    my $tube  = Map::Tube::Copenhagen->new;
    my $route = $tube->get_shortest_route('Flintholm', 'Kastrup');

    print "Route: $route\n";;

=head2 as_image($line_name)

It expects the plugin  L<Map::Tube::Plugin::Graph> to be  installed. Returns line
image  as  base64  encoded string if C<$line_name> passed in otherwise it returns
base64 encoded string of the entire map.

    use strict; use warnings;
    use MIME::Base64;
    use Map::Tube::Copenhagen;

    my $tube = Map::Tube::Copenhagen->new;
    my $map  = $tube->name;
    open(my $IMAGE, ">$map.png");
    binmode($IMAGE);
    print $IMAGE decode_base64($tube->as_image);
    close($IMAGE);

=for text
=encoding utf-8
=end

=head1 AUTHOR

Søren Lund, C<< <soren at lund.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-map-tube-copenhagen at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-Copenhagen>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Copenhagen

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube-Copenhagen>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-Copenhagen>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-Copenhagen>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube-Copenhagen/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Søren Lund

This program  is free software; you can  redistribute it and / or modify it under
the  terms  of the the Artistic License  (2.0). You may obtain a copy of the full
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

1; # End of Map::Tube::Copenhagen
