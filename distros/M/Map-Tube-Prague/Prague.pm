package Map::Tube::Prague;

use strict;
use warnings;
use 5.006;

use File::Share ':all';
use Moo;
use namespace::clean;

our $VERSION = 0.15;

# Get XML.
has xml => (
	'is' => 'ro',
	'default' => sub {
		return dist_file('Map-Tube-Prague', 'prague-map.xml');
	},
);

with 'Map::Tube';

1;

__END__

=encoding utf8

=head1 NAME

Map::Tube::Prague - Interface to the Prague Metro Map.

=head1 SYNOPSIS

 use Map::Tube::Prague;

 my $obj = Map::Tube::Prague->new;
 my $routes_ar = $obj->get_all_routes($from, $to);
 my $line = $obj->get_line_by_id($line_id);
 my $line = $obj->get_line_by_name($line_name);
 my $lines_ar = $obj->get_lines;
 my $station = $obj->get_node_by_id($station_id);
 my $station = $obj->get_node_by_name($station_name);
 my $route = $obj->get_shortest_route($from, $to);
 my $stations_ar = $obj->get_stations($line);
 my $metro_name = $obj->name;
 my $xml_file = $obj->xml;

=head1 DESCRIPTION

It currently provides functionality to find the shortest route between the two
given nodes.

For more information about Prague Map, click L<here|https://en.wikipedia.org/wiki/Prague_Metro>.

=head1 METHODS

=over 8

=item C<new()>

 Constructor.

=item C<get_all_routes($from, $to)> [EXPERIMENTAL]

 Get all routes from station to station.
 Returns reference to array with Map::Tube::Route objects.

=item C<get_line_by_id($line_id)>

 Get line object defined by id.
 Returns Map::Tube::Line object.

=item C<get_line_by_name($line_name)>

 Get line object defined by name.
 Returns Map::Tube::Line object.

=item C<get_lines()>

 Get lines in metro map.
 Returns reference to unsorted array with Map::Tube::Line objects.

=item C<get_node_by_id($station_id)>

 Get station node by id.
 Returns Map::Tube::Node object.

=item C<get_node_by_name($station_name)>

 Get station node by name.
 Returns Map::Tube::Node object.

=item C<get_shortest_route($from, $to)>

 Get shortest route between $from and $to node names. Node names in $from and $to are case insensitive.
 Returns Map::Tube::Route object.

=item C<get_stations($line)>

 Get list of stations for concrete metro line.
 Returns reference to array with Map::Tube::Node objects.

=item C<name()>

 Get metro name.
 Returns string with metro name.

=item C<xml()>

 Get XML specification of Prague metro.
 Returns string with XML.

=back

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Encode qw(decode_utf8 encode_utf8);
 use Map::Tube::Prague;

 # Object.
 my $obj = Map::Tube::Prague->new;

 # Get route.
 my $route = $obj->get_shortest_route(decode_utf8('Dejvická'), decode_utf8('Ládví'));

 # Print out type.
 print "Route: ".encode_utf8($route)."\n";

 # Output:
 # Route: Dejvická (Linka A), Hradčanská (Linka A), Malostranská (Linka A), Staroměstská (Linka A), Můstek (Linka A, Tunnel), Můstek (Linka B, Tunnel), Náměstí Republiky (Linka B), Florenc (Linka B, Tunnel), Florenc (Linka C, Tunnel), Vltavská (Linka C), Nádraží Holešovice (Linka C), Kobylisy (Linka C), Ládví (Linka C)

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Map::Tube::Prague;

 # Object.
 my $obj = Map::Tube::Prague->new;

 # Get XML file.
 my $xml_file = $obj->xml;

 # Print out XML file.
 print "XML file: $xml_file\n";

 # Output like:
 # XML file: .*/prague-map.xml

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Map::Tube::GraphViz;
 use Map::Tube::GraphViz::Utils qw(node_color_without_label);
 use Map::Tube::Prague;

 # Object.
 my $obj = Map::Tube::Prague->new;

 # GraphViz object.
 my $g = Map::Tube::GraphViz->new(
         'callback_node' => \&node_color_without_label,
         'tube' => $obj,
 );

 # Get graph to file.
 $g->graph('Prague.png');

 # Print file.
 system "ls -l Prague.png";

 # Output like:
 # -rw-r--r-- 1 skim skim 166110 Apr  6 23:12 Prague.png

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Map-Tube-Prague/master/images/ex3.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Map-Tube-Prague/master/images/ex3.png" alt="Pražské metro" width="300px" height="300px" />
</a>

=end html

=head1 EXAMPLE4

 use strict;
 use warnings;

 use Map::Tube::Prague;

 # Object.
 my $obj = Map::Tube::Prague->new;

 # Get lines.
 my $lines_ar = $obj->get_lines;

 # Print out.
 map { print $_->name."\n"; } sort @{$lines_ar};

 # Output:
 # Linka A
 # Linka B
 # Linka C

=head1 EXAMPLE5

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Map::Tube::Prague;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 line\n";
         exit 1;
 }
 my $line = $ARGV[0];

 # Object.
 my $obj = Map::Tube::Prague->new;

 # Get stations for line.
 my $stations_ar = $obj->get_stations($line);

 # Print out.
 map { print encode_utf8($_->name)."\n"; } @{$stations_ar};

 # Output:
 # Usage: __PROG__ line

 # Output with 'foo' argument.
 # Map::Tube::get_stations(): ERROR: Invalid Line Name [foo]. (status: 105) file __PROG__ on line __LINE__

 # Output with 'Linka A' argument.
 # Nemocnice Motol
 # Petřiny
 # Nádraží Veleslavín
 # Bořislavka
 # Dejvická
 # Hradčanská
 # Malostranská
 # Staroměstská
 # Můstek
 # Muzeum
 # Náměstí Míru
 # Jiřího z Poděbrad
 # Flora
 # Želivského
 # Strašnická
 # Skalka
 # Depo Hostivař

=head1 DEPENDENCIES

L<File::Share>,
L<Map::Tube>,
L<Moo>,
L<namespace::clean>.

=head1 SEE ALSO

=over

=item L<Map::Tube>

Core library as Role (Moo) to process map data.

=item L<Task::Map::Tube>

Install the Map::Tube modules.

=item L<Task::Map::Tube::Metro>

Install the Map::Tube concrete metro modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Map-Tube-Prague>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2014-2020 Michal Josef Špaček

Artistic License

BSD 2-Clause License

=head1 VERSION

0.15

=cut
