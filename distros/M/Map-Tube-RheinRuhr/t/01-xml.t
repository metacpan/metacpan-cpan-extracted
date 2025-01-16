#!perl -T
use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More 0.82;
use Map::Tube::RheinRuhr;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

eval 'use XML::Twig';
plan skip_all => 'XML::Twig required' if $@;

my $map = new_ok( 'Map::Tube::RheinRuhr' );
my $xml = XML::Twig->new( );
$xml->parsefile( $map->xml( ) );
my $root = $xml->root( );

# This test operates on the original XML data, not the digested data
is( $root->tag( ), 'tube',                     'The root element should be a <tube> tag' );
ok( defined( $root->att('name') ),             '<tube> tag should have a name attribute' );
isnt( $root->att('name'),     '',              'name attribute of <tube> tag should not be empty' )     if defined( $root->att('name') );

my $lines = $root->first_child('lines');
ok( defined($lines), 'There should be a <lines> tag directly under the root' );
if ( defined($lines) ) {
  cmp_ok( $lines->children_count('line'), '>=', 5, 'There should be several <line> tags directly under <lines>' );
  my $line = $lines->first_child('line');
  my $i = 0;
  while ($line) {
    ok( $line->att('id'),       "<line> tag #$i should have a non-empty id attribute"        );
    ok( $line->att('name'),     "<line> tag #$i should have a non-empty name attribute"      );
    ok( $line->att('color'),    "<line> tag #$i should have a non-empty color attribute"     );
    $line = $line->next_sibling( );
    $i++;
  }
}

my $stations = $root->first_child('stations');
ok( defined($stations), 'There should be a <stations> tag directly under the root' );
if ( defined($stations) ) {
  cmp_ok( $stations->children_count('station'), '>=', 5, 'There should be several <station> tags directly under <stations>' );
  my $station = $stations->first_child('station');
  my $i = 0;
  while ($station) {
    ok( $station->att('id'),       "<station> tag #$i should have a non-empty id attribute"        );
    ok( $station->att('name'),     "<station> tag #$i should have a non-empty name attribute"      );
    ok( $station->att('line'),     "<station> tag #$i should have a non-empty line attribute"      );
    ok( $station->att('link'),     "<station> tag #$i should have a non-empty link attribute"      );
    $station = $station->next_sibling( );
    $i++;
  }
}

done_testing( );
