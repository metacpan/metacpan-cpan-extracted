use strict;
use warnings;
use Test::More;
use JSON::PP;
use FindBin qw($Bin);
use File::Spec;
use Math::Geometry::HexGrid qw(:all);

my $fixture_file = File::Spec->catfile($Bin, 'hex_vectors.json');
open my $fh, '<', $fixture_file or die "Cannot open $fixture_file: $!";
my $json_text = do { local $/; <$fh> };
close $fh;

my $fixtures = decode_json($json_text);

subtest 'Coordinate Conversions' => sub {
    for my $v (@{$fixtures->{coordinate_conversions}}) {
        my ($q, $r, $s) = oddr_to_cube($v->{col}, $v->{row});
        is_deeply([$q, $r, $s], $v->{cube}, "oddr_to_cube($v->{col}, $v->{row})");

        my ($col, $row) = cube_to_oddr($q, $r, $s);
        is_deeply([$col, $row], [$v->{col}, $v->{row}], "cube_to_oddr roundtrip");
    }
};

subtest 'Distances' => sub {
    for my $v (@{$fixtures->{distances}}) {
        my $d = hex_distance($v->{from}[0], $v->{from}[1], $v->{to}[0], $v->{to}[1]);
        is($d, $v->{distance}, "hex_distance from [@{$v->{from}}] to [@{$v->{to}}]");
    }
};

subtest 'Neighbors' => sub {
    for my $v (@{$fixtures->{neighbors}}) {
        my @nbs = hex_neighbors($v->{coord}[0], $v->{coord}[1]);
        is_deeply(\@nbs, $v->{expected_neighbors}, "hex_neighbors for [@{$v->{coord}}]");
    }
};

subtest 'Collinear Rays' => sub {
    for my $v (@{$fixtures->{collinear_rays}}) {
        my $is_col = hex_is_collinear($v->{from}[0], $v->{from}[1], $v->{to}[0], $v->{to}[1]);
        ok(($is_col ? 1 : 0) == ($v->{is_collinear} ? 1 : 0), "is_collinear for [@{$v->{from}}] -> [@{$v->{to}}]");

        my @ray = hex_collinear_ray($v->{from}[0], $v->{from}[1], $v->{to}[0], $v->{to}[1]);
        is_deeply(\@ray, $v->{ray}, "hex_collinear_ray for [@{$v->{from}}] -> [@{$v->{to}}]");
    }
};

done_testing();
