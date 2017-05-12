#!/user/bin/perl
use strict;
use warnings;
use Geo::MapInfo::MIF::Writer::Region;

=head1 NAME

perl-Geo-MapInfo-MIF-Writer-Region-minimal.pl - Geo::MapInfo::MIF::Writer::Region Minimal Example

=cut

my $map=Geo::MapInfo::MIF::Writer::Region->new(basename=>"minimal");

$map->addMultipartRegion;
$map->addMultipartRegion;
$map->addMultipartRegion;
$map->addMultipartRegion;
$map->addMultipartRegion;
$map->save;
