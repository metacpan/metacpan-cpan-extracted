package Map::Tube::Athens;

our $VERSION = '0.01';

=head1 NAME

Map::Tube::Athens - Map::Tube interface to the Athens Metro

=head1 SYNOPSIS

    my $tube = Map::Tube::Athens->new;

    my $name = $tube->name;
    open(my $MAP_IMAGE, ">$name.png");
    binmode($MAP_IMAGE);
    print $MAP_IMAGE decode_base64($tube->as_image);
    close($MAP_IMAGE);

    my $line = $tube->get_line_by_name('M1');
    print $tube->to_string($line),   "\n\n";

    my $route = $tube->get_shortest_route('Piraeus', 'Syntagma');
    print $tube->to_string($route);

=head1 AUTHOR

Errietta Kostala <errietta@errietta.me>

=head1 DESCRIPTION

It currently provides functionality to find the shortest route between the two given nodes. It covers the following metro lines:

=over

=item Metro Line M1

=item Metro Line M2

=item Metro Line M3

=back

=head1 INFORMATION

What I found out was that it's surprisingly difficult to find an up-to-date, accurate map of the Athens Metro. It seemed that the best source was actually a volunteer-made map from Wikipedia: L<https://upload.wikimedia.org/wikipedia/commons/d/da/Athens_Metro_Map_%28December_2013%2C_English%29.svg>.

If you can read Greek, there's also L<http://www.ypodomes.com/media/k2/items/cache/12a344790c511a0cdcacaded32f8a413_XL.jpg>.

=head1 SEE ALSO

L<Map::Tube>


=cut


use Moo;
use namespace::clean;

use File::Share ':all';

has json => (is => 'ro', default => sub { return dist_file('Map-Tube-Athens', 'athens-map.json') });


with 'Map::Tube';

1;
