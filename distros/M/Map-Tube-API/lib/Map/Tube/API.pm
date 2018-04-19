package Map::Tube::API;

$Map::Tube::API::VERSION   = '0.05';
$Map::Tube::API::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::API - Interface to Map::Tube REST API.

=head1 VERSION

Version 0.05

=cut

use 5.006;
use JSON;
use Data::Dumper;

use Map::Tube::API::UserAgent;

use Moo;
use namespace::autoclean;
extends 'Map::Tube::API::UserAgent';

our $DEFAULT_HOST    = 'manwar.mooo.info';
our $DEFAULT_VERSION = 'v1';

has 'host'    => (is => 'rw', default => sub { $DEFAULT_HOST    });
has 'version' => (is => 'rw', default => sub { $DEFAULT_VERSION });

=head1 DESCRIPTION

Map::Tube REST API is still in beta. No API key is required at the moment.

=head1 MAP NAMES

=over 2

=item Barcelona

=item Beijing

=item Berlin

=item Bucharest

=item Budapest

=item Delhi

=item Dnipropetrovsk

=item Glasgow

=item Kazan

=item Kharkiv

=item Kiev

=item KoelnBonn

=item Kolkatta

=item KualaLumpur

=item London

=item Lyon

=item Malaga

=item Minsk

=item Moscow

=item Nanjing

=item NizhnyNovgorod

=item Novosibirsk

=item Prague

=item SaintPetersburg

=item Samara

=item Singapore

=item Sofia

=item Tbilisi

=item Vienna

=item Warsaw

=item Yekaterinburg

=back

=head1 CONSTRUCTOR

Optionally you can provide C<host> of REST API and also  the C<version>. Default
version is C<v1>.

    use strict; use warnings;
    use Map::Tube::API;

    my $api = Map::Tube::API->new;

=head1 METHODS

=head2 shortest_route(\%params)

Returns list of stations for the shortest route.The parameters should be as below

    +-------+-------------------------------------------------------------------+
    | Key   | Description                                                       |
    +-------+-------------------------------------------------------------------+
    | map   | A valid map name.                                                 |
    | start | A valid start station name in the given map.                      |
    | end   | A valid end station name in the give map.                         |
    +-------+-------------------------------------------------------------------+

    use strict; use warnings;
    use Map::Tube::API;

    my $api   = Map::Tube::API->new;
    my $route = $api->shortest_route({ map => 'london', start => 'Baker Street', end => 'Wembley Park' });

=cut

sub shortest_route {
    my ($self, $params) = @_;

    my $map = $params->{map};
    die "ERROR: Missing map name."
        unless (defined $map && ($map !~ /^$/));

    my $start = $params->{start};
    die "ERROR: Missing start station name."
        unless (defined $start && ($start !~ /^$/));

    my $end = $params->{end};
    die "ERROR: Missing end station name."
        unless (defined $end && ($end !~ /^$/));

    my $url      = sprintf("%s/shortest-route/%s/%s/%s", $self->_base_url, $map, $start, $end);
    my $response = $self->get($url);

    return JSON->new->allow_nonref->utf8(1)->decode($response->decoded_content);
}

=head2 line_stations(\%params)

Returns list of stations. The parameters should be as below:

    +-------+-------------------------------------------------------------------+
    | Key   | Description                                                       |
    +-------+-------------------------------------------------------------------+
    | map   | A valid map name.                                                 |
    | line  | A valid line name in the given map.                               |
    +-------+-------------------------------------------------------------------+

    use strict; use warnings;
    use Map::Tube::API;

    my $api      = Map::Tube::API->new;
    my $stations = $api->line_stations({ map => 'london', line => 'Metropolitan' });

=cut

sub line_stations {
    my ($self, $params) = @_;

    my $map = $params->{map};
    die "ERROR: Missing map name."
        unless (defined $map && ($map !~ /^$/));

    my $line = $params->{line};
    die "ERROR: Missing line name."
        unless (defined $line && ($line !~ /^$/));

    my $url      = sprintf("%s/stations/%s/%s", $self->_base_url, $map, $line);
    my $response = $self->get($url);

    return JSON->new->allow_nonref->utf8(1)->decode($response->decoded_content);
}

=head2 map_stations(\%params)

Returns list of stations for the given map.

    +-------+-------------------------------------------------------------------+
    | Key   | Description                                                       |
    +-------+-------------------------------------------------------------------+
    | map   | A valid map name.                                                 |
    +-------+-------------------------------------------------------------------+

    use strict; use warnings;
    use Map::Tube::API;

    my $api      = Map::Tube::API->new;
    my $stations = $api->map_stations({ map => 'london' });

=cut

sub map_stations {
    my ($self, $params) = @_;

    my $map = $params->{map};
    die "ERROR: Missing map name."
        unless (defined $map && ($map !~ /^$/));

    my $url      = sprintf("%s/stations/%s", $self->_base_url, $map);
    my $response = $self->get($url);

    return JSON->new->allow_nonref->utf8(1)->decode($response->decoded_content);
}

=head2 available_maps()

Returns list of available maps.

    use strict; use warnings;
    use Map::Tube::API;

    my $api  = Map::Tube::API->new;
    my $maps = $api->available_maps({ map => 'london' });

=cut

sub available_maps {
    my ($self) = @_;

    my $url      = sprintf("%s/maps", $self->_base_url);
    my $response = $self->get($url);

    return JSON->new->allow_nonref->utf8(1)->decode($response->decoded_content);
}

#
#
# PRIVATE METHODS

sub _base_url {
    my ($self) = @_;

    return sprintf("http://%s/map-tube/%s", $self->host, $self->version);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-API>

=head1 BUGS

Please  report  any bugs  or feature requests to C<bug-map-tube-api at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube-API>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::API

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube-API/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Mohammad S Anwar.

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

1; # End of Map::Tube::API
