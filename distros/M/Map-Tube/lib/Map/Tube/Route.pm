package Map::Tube::Route;

$Map::Tube::Route::VERSION   = '3.83';
$Map::Tube::Route::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::Route - Class to represent the route in the map.

=head1 VERSION

Version 3.83

=cut

use 5.006;
use Data::Dumper;
use Map::Tube::Types qw(Node Nodes);
use Map::Tube::Utils qw(filter);

use Moo;
use namespace::autoclean;

use overload q{""} => 'as_string', fallback => 1;

has [ qw(from to) ] => (is => 'ro', isa => Node,  required => 1);
has nodes => (is => 'ro', isa => Nodes, required => 1);
with 'Map::Tube::Plugin::Formatter';

=head1 SYNOPSIS

    use strict; use warnings;
    use Map::Tube::London;

    my $map   = Map::Tube::London->new;
    my $route = $map->get_shortest_route('Baker Street', 'Euston Square');

    print "Route Starts:",    $route->from,      "\n";
    print "Route Ends:",      $route->to,        "\n";
    print "Route:",           $route,            "\n";
    print "Route Preferred:", $route->preferred, "\n";

=head1 DESCRIPTION

It provides simple interface to the C<route> of the map.

=head1 METHODS

=head2 from()

Returns an object of type L<Map::Tube::Node> representing the start station.

=head2 to()

Returns an object of type L<Map::Tube::Node> representing the end station.

=head2 nodes()

Returns ref to a list of objects of type L<Map::Tube::Node> representing the path
from C<start> to C<end> station.

=head2 preferred()

Returns an object of type L<Map::Tube::Route> as preferred route.

=cut

sub preferred {
    my ($self) = @_;

    my $index = 0;
    my $nodes = [];
    my $lines = [];
    my $nodes_object = {};
    my $lines_object = {};
    foreach my $node (@{$self->nodes}) {
        push @$nodes, { name => $node->name };
        $nodes_object->{$node->name} = $node;

        foreach my $line (@{$node->{line}}) {
            push @{$lines->[$index]}, $line->id;
            $lines_object->{$line->id} = $line;
        }

        $index++;
    }

    my $data   = filter($lines);
    my $_nodes = [];
    foreach my $i (0..$#$nodes) {
        my $_node = {
            id   => $nodes_object->{$nodes->[$i]->{name}}->id,
            name => $nodes->[$i]->{name},
            link => $nodes_object->{$nodes->[$i]->{name}}->link,
        };

        foreach (@{$data->[$i]}) {
            push @{$_node->{line}}, $lines_object->{$_};
        }

        push @$_nodes, Map::Tube::Node->new($_node);
    }

    return Map::Tube::Route->new({
        from  => $self->from,
        to    => $self->to,
        nodes => $_nodes });
}

sub as_string {
    my ($self) = @_;

    return join ", ", @{$self->nodes};
}

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Map-Tube/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Route

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Map-Tube/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Map-Tube/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 - 2024 Mohammad Sajid Anwar.

This  program  is  free software;  you can redistribute it and/or modify it under
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

1; # End of Map::Tube::Route
