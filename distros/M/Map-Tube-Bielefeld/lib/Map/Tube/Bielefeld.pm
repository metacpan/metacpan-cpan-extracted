package Map::Tube::Bielefeld;

$VERSION = '2020.0330';

=head1 NAME

Map::Tube::Bielefeld - interface to the Bielefeld Stadtbahn

=cut

use File::Share ':all';
use utf8;

use Moo;
use namespace::clean;

has xml => (
    is => 'ro',
    default =>
        sub {return dist_file('Map-Tube-Bielefeld', 'bielefeld-map.xml')}
);

with 'Map::Tube';

=head1 DESCRIPTION

It currently provides functionality to find the shortest route between
the two given stations.

=head1 CONSTRUCTOR

    use Map::Tube::Bielefeld;
    my $tube = Map::Tube::Bielefeld->new;

=head1 METHODS

=head2 get_shortest_route(I<START>, I<END>)

This method expects two parameters I<START> and I<END> station name.
Station names are case insensitive. The station sequence from I<START>
to I<END> is returned.

    use Map::Tube::Bielefeld;
    my $tube = Map::Tube::Bielefeld->new;
    my $route = $tube->get_shortest_route('', '');
    print "Route: $route\n";

=head1 AUTHOR

Vitali Peil E<lt>vitali.peil@uni-bielefeld.deE<gt>

=head1 COPYRIGHT

Copyright 2019- Vitali Peil

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Map::Tube>.

=cut

1;
