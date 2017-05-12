use strict;
use warnings;
use Test::More tests => 1;
use Geo::Coordinates::Converter;

my $geo = Geo::Coordinates::Converter->new(
    formats => [qw/iArea/],
    lat     => '35.645168',
    lng     => '139.723348',
    datum   => 'wgs84'
);
my $point = $geo->convert('degree', 'iarea');
is $point->areacode, '05905';

