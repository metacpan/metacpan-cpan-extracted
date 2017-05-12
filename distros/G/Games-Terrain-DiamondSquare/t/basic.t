use Test::Most;
use Games::Terrain::DiamondSquare 'create_terrain';

my $height = 30;
my $width  = 80;
ok my $terrain = create_terrain( $height, $width, .9 ),
  'We should be able to fetch a terrain from create_terrain()';

is @$terrain, $height, '... and it should have the correct height';
is @{ $terrain->[0] }, $width, '... and the correct width';

my @chars = split '' => ' .,-~:;=!*#$@';
my $bucket  = 0;
my @buckets = map { $bucket += 1/@chars } 1 .. scalar @chars;

sub get_char {
    my $value = shift;
    my $i     = 0;
    foreach (@buckets) {
        last if $value < $_;
        $i++;
    }
    return $chars[$i];
}

foreach my $row (@$terrain) {
    my $output = '';
    foreach my $char (@$row) {
        $output .= get_char($char);
    }
    diag $output;
}

done_testing;
