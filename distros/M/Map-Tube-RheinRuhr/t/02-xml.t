#!perl -T
use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More 0.82;
use Map::Tube::RheinRuhr;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

my $map = Map::Tube::RheinRuhr->new( );
isa_ok( $map, 'Map::Tube::RheinRuhr', 'Map::Tube object' );
ok_station_names_different( $map, 1, 4 );
# ok_station_names_different( $map, 2, 65 );   # optionally instead: stricter testing
ok_station_complete_names($map, 62 );
ok_line_names_unique($map);
ok_line_ids_unique($map);
ok_lines_used($map);
ok_stations_linked_share_lines($map);
ok_links_bidirectional($map, qw( 101/106 705 706 H-Bahn U73 U78 ) );
ok_lines_indexed($map);
ok_lines_run_through($map);
ok_connected($map, 4);   # In this map, 3 stations are not reachable from everywhere and from each other. Strange, but real.

done_testing( );


# *** Public functions ***

sub ok_line_names_unique {
  # Line names must be unique.
  # Station names must also be unique, but since newer versions of Map::Tube already test this on init, we don't repeat this.
  my( $map ) = @_;
  $map = _prepare_raw_map($map) unless exists $map->{_rawinfo};
  my $rawinfo = $map->{_rawinfo};

  my @dup_names = grep { scalar( @{ $rawinfo->{line_names}{$_} } ) > 1 } sort keys %{ $rawinfo->{line_names} };
  fail( "Line name $_ defined more than once (ids " . join( ', ', @{ $rawinfo->{line_names}{$_} } ) . ')' ) for @dup_names;

  return;
}


sub ok_line_ids_unique {
  # Line ids must be unique.
  # Station ids must also be unique, but since newer versions of Map::Tube already test this on init, we don't repeat this.
  my( $map ) = @_;
  $map = _prepare_raw_map($map) unless exists $map->{_rawinfo};
  my $rawinfo = $map->{_rawinfo};

  my @dup_ids = grep { $rawinfo->{line_ids_defined}->{$_} > 1 } sort keys %{ $rawinfo->{line_ids_defined} };
  fail( "Line id $_ defined more than once" ) for @dup_ids;

  return;
}


sub ok_lines_used {
  # All lines serving some station must be defined (does not apply to other_links),
  # but since newer versions of Map::Tube already test this on init, we don't repeat this.
  # All defined lines must be serving some station (possibly within other_links).
  # (It seems that Test::Map::Tube does test for this, but the message is not very helpful:
  # "get_lines() returns incorrect line entries"
  # Lines must not come up both in ordinary and in other_links.
  my( $map ) = @_;
  $map = _prepare_raw_map($map) unless exists $map->{_rawinfo};
  my $rawinfo = $map->{_rawinfo};

  my @unserve_ids = grep { !$rawinfo->{line_ids_used}{$_} && !exists( $rawinfo->{other_link_used}{$_} ) } sort keys %{ $rawinfo->{line_ids_defined} };
  fail( "Line id $_ defined but serves no stations (not even as other_link)" ) for @unserve_ids;

  my @line_and_other_link = grep { exists( $rawinfo->{other_link_used}{$_} ) } sort keys %{ $rawinfo->{line_ids_used} };
  fail( "Line id $_ used both as ordinary link and in other_link" ) for sort @line_and_other_link;

  return;
}


sub ok_station_names_different {
  my( $map, $dist_limit, $max_allowed ) = @_;
  $dist_limit //= 2;
  $max_allowed //= 0;

  eval 'use Text::Levenshtein::XS qw(distance)';
  if ($@) {
    diag('Text::Levenshtein::XS required for testing connectedness');
    return;
  }

  $map = _prepare_raw_map($map) unless exists $map->{_rawinfo};
  my $rawinfo = $map->{_rawinfo};

  my @similar_names;
  my @station_names = sort keys %{ $rawinfo->{station_names} };
  my $n_station_names = scalar(@station_names);
  for my $i ( 0..($n_station_names-2) ) {
    my $station1 = $station_names[$i];
    for my $j ( ($i+1)..($n_station_names-1) ) {
      my $station2 = $station_names[$j];
      if ( distance( $station1, $station2 ) <= $dist_limit ) {
        push( @similar_names, ":$station1:$station2:" );
      }
    }
  }

  if ( scalar(@similar_names) > $max_allowed ) {
    diag( scalar(@similar_names), " similar name pairs found at or below distance $dist_limit" );
    fail( "Similar names maybe due to typo? $_" ) for @similar_names;
  }

  return;
}


sub ok_station_complete_names {
  my( $map, $max_allowed ) = @_;
  $max_allowed ||= 0;

  $map = _prepare_raw_map($map) unless exists $map->{_rawinfo};
  my $rawinfo = $map->{_rawinfo};

  my @incomplete_names;
  my @station_names = sort keys %{ $rawinfo->{station_names} };
  my $n_station_names = scalar(@station_names);
  for my $i ( 0..($n_station_names-2) ) {
    my $station1 = $station_names[$i];
    for my $j ( ($i+1)..($n_station_names-1) ) {
      my $station2 = $station_names[$j];
      if ( ( $station1 eq substr( $station2, 0, length($station1) ) ) ||
           ( $station2 eq substr( $station1, 0, length($station2) ) ) ) {
        push( @incomplete_names, ":$station1:$station2:" );
      }
    }
  }

  if ( scalar(@incomplete_names) > $max_allowed ) {
    diag( scalar(@incomplete_names), ' potentially incomplete names found' );
    fail( "Incomplete name? $_" ) for @incomplete_names;
  }

  return;
}


sub ok_stations_linked_share_lines {
  # Stations that are linked must share at least one line (possibly through other_link).
  # Lines serving some station must also serve at least one linked station (ordinary link).
  # other_links at some station must also be named at at least one linked station.
  my( $map ) = @_;
  $map = _prepare_raw_map($map) unless exists $map->{_rawinfo};
  my $rawinfo = $map->{_rawinfo};

  my @unlinked_links;
  for my $station1 ( sort keys %{ $rawinfo->{station_linked_to_stations} } ) {
    for my $station2 ( grep { $_ gt $station1 } sort keys %{ $rawinfo->{station_linked_to_stations}{$station1} } ) {
      my $linect = scalar( grep { exists( $rawinfo->{station_served_by_lines}{$station2}{$_} ) } keys %{ $rawinfo->{station_served_by_lines}{$station1} } );
      push( @unlinked_links, "$station1 and $station2" ) unless $linect;
    }
  }
  fail( "Stations id $_ are linked but share no line" ) for @unlinked_links;

  my @unlinking_lines;
  for my $station ( sort keys %{ $rawinfo->{station_served_by_lines} } ) {
    for my $line( grep { $rawinfo->{station_served_by_lines}{$station}{$_} == 1 } keys %{ $rawinfo->{station_served_by_lines}{$station} } ) {
      my $stationct = grep { exists( $rawinfo->{station_served_by_lines}{$_}{$line} ) } keys %{ $rawinfo->{station_linked_to_stations}{$station} };
      push( @unlinking_lines, "$line at station id $station" ) unless $stationct;
    }
  }
  fail( "Line id $_ does not serve any linked station" ) for @unlinking_lines;

  my @unlinking_other_links;
  for my $station ( sort keys %{ $rawinfo->{station_served_by_lines} } ) {
    for my $line( grep { $rawinfo->{station_served_by_lines}{$station}{$_} == 2 } keys %{ $rawinfo->{station_served_by_lines}{$station} } ) {
      my $stationct = grep { exists( $rawinfo->{station_served_by_lines}{$_}{$line} ) } keys %{ $rawinfo->{station_linked_to_stations}{$station} };
      push( @unlinking_other_links, "$line at station id $station" ) unless $stationct;
    }
  }
  fail( "Line id $_ does not serve any linked station" ) for @unlinking_other_links;

  return;
}


sub ok_links_bidirectional {
  # Are stations all linked symmetrically?
  # This is optional -- links may legally be unidirectional.
  my( $map, @skip_lines ) = @_;
  $map = _prepare_raw_map($map) unless exists $map->{_rawinfo};
  my $rawinfo = $map->{_rawinfo};
  my %skip_lines_ids = map { $rawinfo->{line_names}->{$_}->[0] => $_ } @skip_lines;

  my @nonsymmetric;
  for my $station( sort keys %{ $rawinfo->{station_linked_to_stations} } ) {
    for my $station1( grep { !exists( $rawinfo->{station_linked_to_stations}{$_}{$station} ) } keys %{ $rawinfo->{station_linked_to_stations}{$station} } ) {
      my $problematic = 1;
      for my $line( keys( %{ $rawinfo->{station_served_by_lines}->{$station} } ) ) {
        next unless exists $rawinfo->{station_served_by_lines}->{$station1}->{$line};
        if ( exists $skip_lines_ids{$line} ) {
          $problematic = 0;
          last;
        }
      }
      push( @nonsymmetric, "$station linked to $station1") if $problematic;
    }
  }
  fail( "Station id $_ but not vice versa" ) for @nonsymmetric;

  return;
}


sub ok_lines_indexed {
  # Each line must have either all or no stations indexed (but not some aye, some nay).
  # Each line's indices must be unique.
  my( $map ) = @_;
  $map = _prepare_raw_map($map) unless exists $map->{_rawinfo};
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


sub ok_lines_run_through {
  # Each line should be weakly connected, i.e., all pairs of stations on a line should be connected at least
  # when regarding directionality.
  # If exceptionally this is known not to hold for certain lines, their names can be passed to this function.
  my( $map, @skip_lines ) = @_;

  $map = _prepare_raw_map($map) unless exists $map->{_rawinfo};
  my $rawinfo = $map->{_rawinfo};
  my %skip_lines_ids = map { $rawinfo->{line_names}->{$_}->[0] => $_ } @skip_lines;

  eval 'use Graph';
  if ($@) {
    diag('Graph required for testing line connectedness');
    return;
  }

  # For each line separately:
  # Build a list of pairs of (directly) linked stations on this line
  my @unconnected;
  for my $line_id( grep { !exists( $skip_lines_ids{$_} ) } keys %{ $rawinfo->{line_ids_defined} } ) {

    my @all_links;
    for my $station( grep { exists( $rawinfo->{station_served_by_lines}->{$_}->{$line_id} ) } keys %{ $rawinfo->{station_linked_to_stations} } ) {
      push( @all_links, [ $station, $_ ] ) for grep { ( $rawinfo->{station_served_by_lines}->{$_}->{$line_id} ) } keys %{ $rawinfo->{station_linked_to_stations}->{$station} };
    }

    my $graph = Graph->new( directed => 1, edges => \@all_links );
    if ( !$graph->is_weakly_connected( ) ) {
      my @components = $graph->weakly_connected_components( );
      push( @unconnected, "Line id $line_id consists of " . scalar(@components) . ' separate components' );
    }
  }
  fail( $_ ) for @unconnected;

  return;
}


sub ok_connected {
  # Is the whole map connected, i.e., are there tracks between any two stations?
  # If so: are there connections between any two stations? (Might not be if there are unidirectional links).
  # In either case, show examples of stations in different components.
  # For maps that are known not to be connected, the expected maximum number of components may be specified. Defaults to 1.
  my( $map, $max_allowed ) = @_;
  $max_allowed ||= 1;
  $map = _prepare_raw_map($map) unless exists $map->{_rawinfo};
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
    if ( scalar(@components) > $max_allowed ) {
      my @examples = map { ( sort @$_ )[0] } @components;
      fail( 'Is map connected? Has ' . scalar(@components) . ' separate components; e.g., stations with ids ' . join( ', ', @examples ) );
      return;
    }
  }

  # Map is connected, but maybe not all stations reachable from each other station?
  if (!$graph->is_strongly_connected( ) ) {
    my @components = $graph->strongly_connected_components( );
    return if ( scalar(@components) <= $max_allowed );
    print STDERR 'This test may take long... ';   # because the Graph module has to do a lot of work upfront
    my @composizes = map { scalar(@$_) } @components;
    print STDERR '.';
    my( $station1, @examples ) = map { $_->[0] } sort { scalar(@$b) <=> scalar(@$a) } @components;
    # $station1 is taken from the largest component, because we asume that one to be the "healthiest"
    my @unlinked;
    for (@examples) {
      my $unlink = $graph->is_reachable( $station1, $_ ) ? ( $_ . '//' . $station1 ) : ( $station1 . '//' . $_ );
      push( @unlinked, $unlink );
    }
    fail( 'Is every station reachable from every other station? Has ' . scalar(@components) .
          ' separate components; e.g., stations with ids ' . join( ', ', @unlinked ) );
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
  eval 'use Map::Tube::Utils';
  plan skip_all => 'Map::Tube::Utils required (should have been installed along with Map::Tube)' if $@;

  my $map = shift;
  my( %line_names,    %line_ids_defined,    %line_ids_used,    %line_ids_indexed,           %line_id_has_indices, %other_link_used,
      %station_names, %station_ids_defined, %station_ids_used, %station_linked_to_stations, %station_served_by_lines, );

  my $json = Map::Tube::Utils::to_perl( $map->json( ) );

  for my $line ( @{ $json->{lines}{line} } ) {
    my $id   = $line->{id};
    my $name = $line->{name};
    $line_names{$name} //= [ ];
    push( @{ $line_names{$name} }, $id );
    $line_ids_defined{$id}++;
    $line_ids_used{$id}    = 0;
    $line_ids_indexed{$id} = 0;
  }

  for my $station ( @{ $json->{stations}{station} } ) {
    my $id    = $station->{id};
    my $name  = $station->{name};
    $station_names{$name} //= [ ];
    push( @{ $station_names{$name} }, $id );
    $station_ids_defined{$id}++;
    $station_ids_used{$_}++                   for map { ( split(/:/) )[0] } split( /,/, $station->{link} );
    $station_linked_to_stations{$id}{$_} |= 1 for map { ( split(/:/) )[0] } split( /,/, $station->{link} );

    for ( map { ( split( /:/) )[0] } split( /,/, $station->{line} ) ) {
      $line_ids_used{$_}++;
      $station_served_by_lines{$id}{$_} |= 1;
    }
    for ( grep { scalar( split(/:/) ) > 1 } split( /,/, $station->{line} ) ) {
      my( $line, $idx ) = split( /:/, $_ );
      $line_ids_indexed{$line}++;
      $line_id_has_indices{$line}{$idx}++;
    }

    if ( exists( $station->{other_link} ) ) {
      for my $other_link ( split( /,/, $station->{other_link} ) ) {
        my( $ol, $target ) = split( /:/, $other_link );
        $other_link_used{$ol}++;
        $station_ids_used{$target}++;
        $station_linked_to_stations{$id}{$target} |= 2;
        $station_served_by_lines{$id}{$ol}        |= 2;
      }
    }

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

