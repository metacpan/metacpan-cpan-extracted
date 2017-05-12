#!/user/bin/perl
use strict;
use warnings;
use Geo::MapInfo::MIF::Writer::Region;

=head1 NAME

perl-Geo-MapInfo-MIF-Writer-Region-data.pl - Geo::MapInfo::MIF::Writer::Region Data Only Example

=cut

my $map=Geo::MapInfo::MIF::Writer::Region->new(basename=>"data");

$map->addMultipartRegion(data=>{});
$map->addMultipartRegion(data=>{colInt=>1, colBigInt=>2**32, colString=>"Foo"});
$map->addMultipartRegion(data=>{colInt=>2});
$map->addMultipartRegion(data=>{colBigInt=>2**33});
$map->addMultipartRegion(data=>{colString=>"Bar"});
$map->addMultipartRegion(data=>{});
$map->save;
