use 5.12.0;

package Map::Metro::Plugin::Map::London;

our $VERSION = '0.001';

use Moose;
with 'Map::Metro::Plugin::Map';

has '+mapfile' => (
    default => 'map-london.metro',
);
sub map_version {
    return $VERSION;
}
sub map_package {
    return __PACKAGE__;
}

1;

__END__

=encoding utf-8

=head1 NAME

Map::Metro::Plugin::Map::London - Map::Metro map for London

=head1 SYNOPSIS

    use Map::Metro;
    my $graph = Map::Metro->new('London')->parse;

Or:

    $ map-metro.pl route London 'Baker Street' Bank

=head1 DESCRIPTION

See L<Map::Metro> for usage information.

See F<examples/graph-make> for code that converts the supplied data
into data for both this and L<Map::Tube::London>, filtering lines on
whether they appear in F<examples/line-colours.csv>.

=head1 SOURCES

The ur-dataset, albeit from 2014:
L<https://github.com/nicola/tubemaps/tree/master/datasets>

A Neo4j-orientated roundup updated in 2022:
L<https://github.com/yirensum/tube-ingestor>

From L<https://www.doogal.co.uk/london_stations>:

=over

=item L<https://www.doogal.co.uk/LondonTubeLinesCSV/>

=item L<https://www.doogal.co.uk/LondonStationsCSV/>

=back

=head1 AUTHOR

Ed J

1;
