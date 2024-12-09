#!perl -T
use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More 0.82;
use Map::Tube::Beijing;

my $map = Map::Tube::Beijing->new( );
isa_ok( $map, 'Map::Tube::Beijing', 'Map::Tube object' );
ok_unique_names($map);
ok_unique_ids($map);
ok_lines_defined_and_used($map);
ok_stations_defined_and_linked($map);
ok_stations_not_self_linked($map);
ok_stations_linked_share_lines($map);
ok_bidirectional_links($map);
ok_indexed_lines($map);
ok_connected($map);

done_testing( );


# *** Public functions ***

sub ok_unique_names {
  # Line names must be unique.
  # Station names must be unique. (Newer versions of Map::Tube already test this on init.)
  # (But a line may have the same name as a station, even if this is of doubtful value.)
  my $map = shift;
  $map = _prepare_raw_map($map) unless exists $map->{_rawdata};
  my $rawinfo = $map->{_rawinfo};

  my @dup_names = grep { scalar( @{ $rawinfo->{line_names}{$_} } ) > 1 } sort keys %{ $rawinfo->{line_names} };
  fail( "Line name $_ defined more than once (ids " . join( ', ', @{ $rawinfo->{line_names}{$_} } ) . ')' ) for @dup_names;

  @dup_names = grep { scalar( @{ $rawinfo->{station_names}{$_} } ) > 1 } sort keys %{ $rawinfo->{station_names} };
  fail( "Station name $_ defined more than once (ids " . join( ', ', @{ $rawinfo->{station_names}{$_} } ) . ')' ) for @dup_names;

  return;
}


sub ok_unique_ids {
  # Line ids must be unique.
  # Station ids must be unique.
  # (But a line may have the same id as a station, even if this is of doubtful value.)
  my $map = shift;
  $map = _prepare_raw_map($map) unless exists $map->{_rawdata};
  my $rawinfo = $map->{_rawinfo};

  my @dup_ids = grep { $rawinfo->{line_ids_defined}->{$_} > 1 } sort keys %{ $rawinfo->{line_ids_defined} };
  fail( "Line id $_ defined more than once" ) for @dup_ids;

  @dup_ids = grep { $rawinfo->{station_ids_defined}->{$_} > 1 } sort keys %{ $rawinfo->{station_ids_defined} };
  fail( "Station id $_ defined more than once" ) for @dup_ids;

  return;
}


sub ok_lines_defined_and_used {
  # All lines serving some station must be defined (does not apply to other_links). (Newer versions of Map::Tube already check for this.)
  # All defined lines must be serving some station (possibly within other_links).
  # Lines must not come up both in ordinary and in other_links.
  my $map = shift;
  $map = _prepare_raw_map($map) unless exists $map->{_rawdata};
  my $rawinfo = $map->{_rawinfo};

  my @undef_ids = grep { !exists( $rawinfo->{line_ids_defined}{$_} ) } sort keys %{ $rawinfo->{line_ids_used} };
  fail( "Line id $_ serves stations but is not defined" ) for @undef_ids;

  my @unserve_ids = grep { !$rawinfo->{line_ids_used}{$_} && !exists( $rawinfo->{other_link_used}{$_} ) } sort keys %{ $rawinfo->{line_ids_defined} };
  fail( "Line id $_ defined but serves no stations (not even as other_link)" ) for @unserve_ids;

  my @line_and_other_link = grep { exists( $rawinfo->{other_link_used}{$_} ) } sort keys %{ $rawinfo->{line_ids_used} };
  fail( "Line id $_ used both as ordinary link and in other_link" ) for sort @line_and_other_link;

  return;
}


sub ok_stations_defined_and_linked {
  # All stations that are linked to must be defined.
  # All stations must have at least one linked-to station (possibly in other_link).
  #   (Theoretically that is not the case if there are unidirectional links. It would be strange, though.)
  # All stations must be served by at least one line (possibly in other_link).
  my $map = shift;
  $map = _prepare_raw_map($map) unless exists $map->{_rawdata};
  my $rawinfo = $map->{_rawinfo};

  my @undef_ids = grep { !exists( $rawinfo->{station_ids_defined}{$_} ) } sort keys %{ $rawinfo->{station_ids_used} };
  fail( "Station id $_ is linked from some station but is not defined" ) for @undef_ids;

  my @unlinked_ids = grep { !scalar( keys %{ $rawinfo->{station_linked_to_stations}{$_} } ) } sort keys %{ $rawinfo->{station_ids_defined} };
  fail( "Station id $_ is not linked to any station" ) for @unlinked_ids;

  my @unserved_ids = grep { !scalar( keys %{ $rawinfo->{station_served_by_lines}{$_} } ) } sort keys %{ $rawinfo->{station_ids_defined} };
  fail( "Station id $_ is not served by any line" ) for @unserved_ids;

  return;
}


sub ok_stations_not_self_linked {
  # Stations must not link to themselves.
  my $map = shift;
  $map = _prepare_raw_map($map) unless exists $map->{_rawdata};
  my $rawinfo = $map->{_rawinfo};

  my @self_linked_ids = grep { exists( $rawinfo->{station_linked_to_stations}{$_}{$_} ) } sort keys %{ $rawinfo->{station_ids_defined} };
  fail( "Station id $_ is linked to itself" ) for @self_linked_ids;

  return;
}


sub ok_stations_linked_share_lines {
  # Stations that are linked must share at least one line (possibly through other_link).
  # Lines serving some station must also serve at least one linked station (ordinary link).
  # other_links at some station must also be named at at least one linked station.
  my $map = shift;
  $map = _prepare_raw_map($map) unless exists $map->{_rawdata};
  my $rawinfo = $map->{_rawinfo};

  my @unlinked_links;
  for my $station1 ( sort keys %{ $rawinfo->{station_linked_to_stations} } ) {
    for my $station2 ( sort keys %{ $rawinfo->{station_linked_to_stations}{$station1} } ) {
      my $linect = scalar( grep { exists( $rawinfo->{station_served_by_lines}{$station2} ) } keys %{ $rawinfo->{station_served_by_lines}{$station1} } );
      push( @unlinked_links, "$station1 and $station2" ) unless $linect;
    }
  }
  fail( "Stations id $_ are linked but share no line" ) for @unlinked_links;

  my @unlinking_lines;
  for my $station ( grep { $rawinfo->{station_served_by_lines} == 1 } sort keys %{ $rawinfo->{station_served_by_lines} } ) {
    for my $line( keys %{ $rawinfo->{station_served_by_lines}{$station} } ) {
      my $stationct = grep { exists( $rawinfo->{station_served_by_lines}{$_}{$line} ) } keys %{ $rawinfo->{station_linked_to_stations}{$station} };
      push( @unlinking_lines, "$line at station id $station" );
    }
  }
  fail( "Line id $_ does not serve any linked station" ) for @unlinking_lines;

  my @unlinking_other_links;
  for my $station ( grep { $rawinfo->{station_served_by_lines} == 2 } sort keys %{ $rawinfo->{station_served_by_lines} } ) {
    for my $line( keys %{ $rawinfo->{station_served_by_lines}{$station} } ) {
      my $stationct = grep { exists( $rawinfo->{station_served_by_lines}{$_}{$line} ) } keys %{ $rawinfo->{station_linked_to_stations}{$station} };
      push( @unlinking_other_links, "$line at station id $station" );
    }
  }
  fail( "Line id $_ does not serve any linked station" ) for @unlinking_other_links;

  return;
}


sub ok_bidirectional_links {
  # Are stations all linked symmetrically?
  # This is optional -- links may legally be unidirectional.
  my $map = shift;
  $map = _prepare_raw_map($map) unless exists $map->{_rawdata};
  my $rawinfo = $map->{_rawinfo};

  my @nonsymmetric;
  for my $station( sort keys %{ $rawinfo->{station_linked_to_stations} } ) {
    push( @nonsymmetric, "$station linked to $_") for grep { !exists( $rawinfo->{station_linked_to_stations}{$_}{$station} ) } keys %{ $rawinfo->{station_linked_to_stations}{$station} };
  }
  fail( "Station id $_ but not vice versa" ) for @nonsymmetric;

  return;
}


sub ok_indexed_lines {
  # Each line must have either all or no stations indexed (but not some aye, some nay).
  # Each line's indices must be unique.
  my $map = shift;
  $map = _prepare_raw_map($map) unless exists $map->{_rawdata};
  my $rawinfo = $map->{_rawinfo};

  my @partially_indexed = grep { ( $rawinfo->{line_ids_indexed}{$_} != 0 ) &&
                                 ( $rawinfo->{line_ids_indexed}{$_} != $rawinfo->{line_ids_used}{$_} )
                               } sort keys %{ $rawinfo->{line_ids_used} };
  fail( "Line id $_ is partially indexed but not completely" ) for @partially_indexed;

  my @messed_up_lines;
  for my $line( sort keys %{ $rawinfo->{line_id_has_indices} } ) {
    my @nonuniq_idx = grep { $rawinfo->{line_has_indices}{$line}{$_} > 1 } keys %{ $rawinfo->{line_has_indices}{$line} };
    push( @messed_up_lines, $line . ': ' . join( ',', sort { $a <=> $b } @nonuniq_idx ) ) if @nonuniq_idx;
  }
  fail( "Line id $_ non-unique indices" ) for @messed_up_lines;

  return;
}


sub ok_connected {
  # Is the whole map connected, i.e., are there tracks between any two stations?
  # If so: are there connections beteween any two stations? (Might not be if teher are unidirectional links).
  # In either case, show examples of stations in different components.
  my $map = shift;
  $map = _prepare_raw_map($map) unless exists $map->{_rawdata};
  my $rawinfo = $map->{_rawinfo};

  eval 'use Graph';
  if ($@) {
    diag('Graph required for testing connectedness');
    return;
  }

  # Build a list of pairs of (directly) linked stations (possibly by other_link)
  my @all_links;
  for my $station( keys %{ $rawinfo->{station_linked_to_stations} } ) {
    push( @all_links, [ $station, $_ ] ) for keys %{ $rawinfo->{station_linked_to_stations}->{$station} };
  }
  # diag( "*** Total number of links: ", scalar(@all_links) );

  my $graph = Graph->new( directed => 1, edges => \@all_links );

  if ( !$graph->is_weakly_connected( ) ) {
    my @components = $graph->weakly_connected_components( );
    my @examples = map { ( sort @$_ )[0] } @components;
    fail( 'Is map connected? Has ' . scalar(@components) . ' separate components; e.g., stations with ids ' . join( ', ', @examples ) );
  } else {
    if (!$graph->is_strongly_connected( ) ) {
      my @components = $graph->strongly_connected_components( );
      my( $station1, @examples ) = map { ( sort @$_ )[0] } @components;
      my @unlinked;
      for (@examples) {
        my $unlink = $graph->is_reachable( $station1, $_ ) ? ( $_ . '//' . $station1 ) : ( $station1 . '//' . $_ );
        push( @unlinked, $unlink );
      }
      fail( 'Is every station is reachable from every other station? Has ' . scalar(@components) .
            ' separate components; e.g., stations with ids ' . join( ', ', @unlinked ) );
    }
  }

  return;
}


# *** Private functions ***

use Carp;

sub _prepare_raw_map {
  # analyse the original map data (XML or JSON) and store it
  # surreptitiously in the Map::Tube object for later use.
  my $map = shift;
  return _prepare_xml_map($map ) if $map->can('xml');
  return _prepare_json_map($map) if $map->can('json');
  croak( "Don't know how to access underlying map data" );
}


sub _prepare_xml_map {
  # analyse the original map data (XML format) and store it
  # surreptitiously in the Map::Tube object for later use.
  eval 'use XML::Twig';
  plan skip_all => 'XML::Twig required' if $@;

  my $map = shift;
  my $xml = XML::Twig->new( );
  $xml->parsefile( $map->xml( ) );
  my $root = $xml->root( );
  my( %line_names,    %line_ids_defined,    %line_ids_used,    %line_ids_indexed,           %line_id_has_indices, %other_link_used,
      %station_names, %station_ids_defined, %station_ids_used, %station_linked_to_stations, %station_served_by_lines, );

  my $line = $root->first_child('lines')->first_child('line');
  while ($line) {
    my $id   = $line->att('id');
    my $name = $line->att('name');
    $line_names{$name} //= [ ];
    push( @{ $line_names{$name} }, $id );
    $line_ids_defined{$id}++;
    $line_ids_used{$id}    = 0;
    $line_ids_indexed{$id} = 0;
    $line = $line->next_sibling( );
  }

  my $station = $root->first_child('stations')->first_child('station');
  while ($station) {
    my $id    = $station->att('id');
    my $name  = $station->att('name');
    $station_names{$name} //= [ ];
    push( @{ $station_names{$name} }, $id );
    $station_ids_defined{$id}++;
    $station_ids_used{$_}++                   for map { ( split(/:/) )[0] } split( /,/, $station->att('link') );
    $station_linked_to_stations{$id}{$_} |= 1 for map { ( split(/:/) )[0] } split( /,/, $station->att('link') );

    for ( map { ( split( /:/) )[0] } split( /,/, $station->att('line') ) ) {
      $line_ids_used{$_}++;
      $station_served_by_lines{$id}{$_} |= 1;
    }
    for ( grep { scalar( split(/:/) ) > 1 } split( /,/, $station->att('line') ) ) {
      my( $line, $idx ) = split( /:/, $_ );
      $line_ids_indexed{$line}++;
      $line_id_has_indices{$line}{$idx}++;
    }

    if ( defined( $station->att('other_link') ) ) {
      for my $other_link ( split( /,/, $station->att('other_link') ) ) {
        my( $ol, $target ) = split( /:/, $other_link );
        $other_link_used{$ol}++;
        $station_ids_used{$target}++;
        $station_linked_to_stations{$id}{$target} |= 2;
        $station_served_by_lines{$id}{$ol}        |= 2;
      }
    }

    $station = $station->next_sibling( );
  }

  $map->{_rawinfo} = { line_names                 => \%line_names,
                       line_ids_defined           => \%line_ids_defined,
                       line_ids_used              => \%line_ids_used,
                       line_ids_indexed           => \%line_ids_indexed,
                       line_id_has_indices        => \%line_id_has_indices,
                       station_names              => \%station_names,
                       station_ids_defined        => \%station_ids_defined,
                       station_ids_used           => \%station_ids_used,
                       other_link_used            => \%other_link_used,
                       station_linked_to_stations => \%station_linked_to_stations,
                       station_served_by_lines    => \%station_served_by_lines,
                     };
  return $map;
}


sub _prepare_json_map {
  # analyse the original map data (JSON format) and store it
  # surreptitiously in the Map::Tube object for later use.
  eval 'use JSON';
  plan skip_all => 'JSON required' if $@;

  my $map = shift;
  my( %line_names,    %line_ids_defined,    %line_ids_used,    %line_ids_indexed,           %line_id_has_indices, %other_link_used,
      %station_names, %station_ids_defined, %station_ids_used, %station_linked_to_stations, %station_served_by_lines, );

  ...;

  $map->{_rawinfo} = { line_names                 => \%line_names,
                       line_ids_defined           => \%line_ids_defined,
                       line_ids_used              => \%line_ids_used,
                       line_ids_indexed           => \%line_ids_indexed,
                       line_id_has_indices        => \%line_id_has_indices,
                       station_names              => \%station_names,
                       station_ids_defined        => \%station_ids_defined,
                       station_ids_used           => \%station_ids_used,
                       other_link_used            => \%other_link_used,
                       station_linked_to_stations => \%station_linked_to_stations,
                       station_served_by_lines    => \%station_served_by_lines,
                     };
  return $map;
}


