#!perl

use strict;
use utf8;
use Test::More tests => 5;
use Map::Tube::Beijing;

my $map = new_ok( 'Map::Tube::Beijing' );

{
  my @selflinked;
  for my $nodeId( keys %{ $map->nodes() } ) {
    push( @selflinked, $nodeId ) if grep { $_ eq $nodeId } split( ',', $map->get_node_by_id($nodeId)->link() );
  }
  is( scalar(@selflinked), 0, 'Stations should not be linked to themselves: ' . join(' ', @selflinked) );
}

{
  my @multilined;
  for my $nodeId( keys %{ $map->nodes() } ) {
    my %lines;
    $lines{$_}++ for split( ',', $map->get_node_by_id($nodeId)->line() );
    my $maxlink = 0;
    for (keys %lines) { $maxlink = $lines{$_} if ( $maxlink < $lines{$_} ) }
    push( @multilined, $nodeId . ':' . join( ',', grep { $lines{$_} > 1 } keys %lines ) ) if ( $maxlink > 1 );
  }
  is( scalar(@multilined), 0, 'Stations should name lines once only: ' . join(' ', @multilined) );
}

{
  my @multilinked;
  for my $nodeId( keys %{ $map->nodes() } ) {
    my %lines;
    $lines{$_}++ for split( ',', $map->get_node_by_id($nodeId)->link() );
    my $maxlink = 0;
    for (keys %lines) { $maxlink = $lines{$_} if ( $maxlink < $lines{$_} ) }
    push( @multilinked, $nodeId . ':' . join( ',', grep { $lines{$_} > 1 } keys %lines ) ) if ( $maxlink > 1 );
  }
  is( scalar(@multilinked), 0, 'Stations should name links once only: ' . join(' ', @multilinked) );
}

{
  my %names;
  for my $nodeId( keys %{ $map->nodes() } ) {
    my $name = $map->get_node_by_id($nodeId)->name();
    $names{$name} ||= [ ];
    push( @{ $names{$name} }, $nodeId);
  }
  my %multinames = map { $_ => $names{$_} } grep { scalar( @{ $names{$_} } ) > 1 } keys %names;
  is( scalar(keys %multinames), 0, 'Station names should be unique: ' . join("\n", map { "$_ -> " . join(' ', @{ $multinames{$_} } ) } sort keys %multinames ) );
}

