#!/user/bin/perl
use strict;
use warnings;
use Geo::MapInfo::MIF::Writer::Region;

=head1 NAME

perl-Geo-MapInfo-MIF-Writer-Region-example.pl - Geo::MapInfo::MIF::Writer::Region Simple Example

=cut

my $map=Geo::MapInfo::MIF::Writer::Region->new(basename=>"example");

my @r1=([-77.1, 39], [-77.2, 39], [-77.2, 38], [-77.1, 38], [-77.1, 39]);
my @r2=([-77.2, 39], [-77.3, 39], [-77.3, 38], [-77.2, 38], [-77.2, 39]);

$map->addMultipartRegion(data=>{id=>0, name=>"zero"}, regions=>[]);
$map->addSimpleRegion(data=>{id=>1, name=>"one"},    region=>\@r1);
$map->addSimpleRegion(data=>{id=>2, name=>"two"},    region=>\@r2);
$map->save;
