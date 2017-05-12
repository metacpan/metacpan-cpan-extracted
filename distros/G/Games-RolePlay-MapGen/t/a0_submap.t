
use strict;
use Test;
use Games::RolePlay::MapGen;

my $in_map = Games::RolePlay::MapGen->import_xml( "vis1.map.xml" );
my $im = $in_map->{_the_map};

# <option name="bounding_box" value="40x40" />
my @tests = (
    [[10,  6] => [17, 12]], # middle
    [[ 0,  0] => [10, 10]], # UL
    [[30,  0] => [39, 10]], # UR
    [[ 0, 29] => [10, 39]], # LL
    [[29, 29] => [39, 39]], # LR
);

my $tile_count = 0;
   $tile_count += $_ for map {(1+abs($_->[0][0]-$_->[1][0]))*(1+abs($_->[0][1]-$_->[1][1]))} @tests;

plan tests => 5*$tile_count; # each tile has a type and four directions

for my $test (@tests) {
    my $map = Games::RolePlay::MapGen->sub_map($in_map, @$test); my $m = $map->{_the_map};
    my @X = (1 .. $#{ $m->[0] }-1);
    my @Y = (1 .. $#$m -1);

    for my $x (@X) { my $ox = ($test->[0][0]-1+$x);
    for my $y (@Y) { my $oy = ($test->[0][1]-1+$y);
        my $t = $m->[ $y ][ $x ];
        my $n = $im->[ $oy ][ $ox ];

        ok($t->{type}, $n->{type});

        $t = $t->{od};
        $n = $n->{od};

        for my $d (qw(n e s w)) {
            my $l = $t->{$d};
            my $r = $n->{$d};

            $l = "door" if ref $l;
            $r = "door" if ref $r;

            ok($l, $r);
        }
    }}
}
