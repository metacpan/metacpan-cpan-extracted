
use strict;
use Test;

my ($x, $y) = (25, 25);

plan tests => ($x * $y);

use Games::RolePlay::MapGen;
use Storable qw(freeze thaw);

my $map = new Games::RolePlay::MapGen({bounding_box => join("x", $x, $y) });

$map->generate;
my $saved_string = freeze($map);

my %checksums = ();
for my $i (0..$x-1) {
    for my $j (0..$y-1) {
        $checksums{$i}{$j} = &a_kind_of_checksum( $i, $j, $map );
    }
}

delete $map->{_the_map};
delete $map->{_the_groups};

$map = thaw($saved_string);

for my $i (0..$x-1) {
    for my $j (0..$y-1) {
        ok( &a_kind_of_checksum($i, $j, $map), $checksums{$i}{$j} );
    }
}

sub a_kind_of_checksum {
    my ($x, $y, $map) = @_;

    my $tile = $map->{_the_map}[$y][$x];

    return "nothin' there" if not exists $tile->{type};
    return sprintf('%d-%d-%s-%d%d%d%d', $x, $y, $tile->{type}, map($tile->{od}{$_}, qw(n e s w)));
}
