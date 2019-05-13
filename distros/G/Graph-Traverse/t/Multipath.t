# -*- mode: cperl; -*-
use strict;
use Test::More;

use Graph::Directed;
use Graph::Traverse;

# Path-with-group-via test.
#
# In this test, we create a directed graph with a number of special
# nodes, each of which has only outward edges to a set of ordinary
# nodes.  Those ordinary nodes may be considered to represent the
# members of a set of nodes.  We then compute the shortest path that
# passes through a group of the special nodes in a given order.
#
# For example, we may have a special node named PHX that links to
# nodes PHX1, PHX2, and PHX3; and another special node LAX that links
# to nodes LAX1 through LAX9.  There may be any number of intermediate
# links, such as a mesh of nodes between PXH* and LAX* nodes. We wish
# to compute a path from PHX to LAX, which means from any of the PHX*
# nodes to any of the LAX nodes.
#
# We can then add another special node SFO which links to SFO1 through
# SFO27, and then request a path that links any of the PHX* nodes
# through any one of the LAX* nodes to any of the SFO* nodes.  Note
# that the shortes PHX-LAX link might be PHX1...LAX7 but LAX7 might
# not link to any of the SFO* nodes at all, or might have a long path
# to them.  Thus the requirement to compute a path which visits each
# of a set-of-nodes in order.

my $g = new_ok( 'Graph::Directed' );
ok ($g->add_path(qw(A B C D)), 'Add path');

foreach my $l ( split /\n/, <<EULER )
# Routes from PHX
PHX PHX1 GOODYR1 YUMA1 INDIO1 RIVERSIDE1 LAX1
PHX PHX2 GOODYR2 YUMA2
PHX2 GILABEND1 YUMA1
PHX3 GILABEND2
YUMA1 INDIO2 LAX2
# Note: No path into YUMA3...
YUMA3 INDIO3 LAX3
# special nodes *only* have outgoing edges
LAX LAX1
LAX LAX2
LAX LAX3
# And routes to San Francisco
LAX1 VICTOR1
LAX2 PALMDALE1
LAX2 OXNARD1
LAX2 VENTURA1
LAX3 VICTOR1
LAX3 PALMDALE1
OXNARD1 VENTURA2
VENTURA2 VENTURA1
VENTURA1 BAKERS1
VENTURA2 BAKERS2
BAKERS1 WASCO1
BAKERS2 COALINGA1
WASCO1 HANFORD1
HANFORD1 VISALIA1
HANFORD1 FRESNO1
COALINGA1 FRESNO2
FRESNO2 MERCED1
MERCED1 MODESTO1
MODESTO1 STOCKTON1
STOCKTON1 CONCORD1
CONCORD1 BERKELEY1
BERKELEY1 SFO3
SFO SFO1
SFO SFO2
SFO SFO3
SFO SFO4
VENTURA1 LOMPOC1
LOMPOC1 SLO1
SLO1 PASOROB1
PASOROB1 MONTEREY1
MONTEREY1 SALINAS1
SALINAS1 GILROY1
GILROY1 SANJOSE1
SANJOSE1 PALOALTO1
PALOALTO1 SFO3
EULER

{
    my @nodes = split (/\s+/, $l);
    next if scalar @nodes ==0 || $nodes[0]=~/^#/;
    ok ($g->add_path(@nodes), "Add path");
}

my $to_any = sub {
  my ($graph, $vertex, $weight, $opts) = @_;
  if (ref $opts->{end} eq 'ARRAY') {
    foreach my $k ( @{$opts->{end}} ) {
      return $opts->{end_value} // 1 if $vertex eq $k;
    }
  } elsif (ref $opts->{end} eq 'HASH') {
    foreach my $k (keys %{$opts->{end}}) {
      return $opts->{end}{$k} if $vertex eq $k;
    }
  } else {
    return $opts->{end_value} // 1 if $vertex eq $opts->{end};
  }
  return 0;
};

sub paths_via {
  # Find routes via a series of vertices, or groups of vertices
  my ($graph, @vertices) = @_;
  my ($vertex_this, $vertex_next) = (shift @vertices, shift @vertices);
  
  my $paths;
  while (defined $vertex_next) {
    my $next_paths = $g->traverse($vertex_this, {cb=>$to_any, end=>$vertex_next, hash=>1, all=>0});
    
    if (defined $paths && scalar %{$next_paths}) {
      foreach my $segment_origin (keys %{$next_paths}) {
        pop @{$paths->{$next_paths->{$segment_origin}->{path}->[0]}->{path}};
        $next_paths->{$segment_origin}->{weight} += $paths->{$next_paths->{$segment_origin}->{path}->[0]}->{weight};
        unshift @{$next_paths->{$segment_origin}->{path}},
          @{$paths->{$next_paths->{$segment_origin}->{path}->[0]}->{path}};
      }
    }
    $paths = $next_paths;
    $vertex_next = shift @vertices;
  }
  return $paths;
}

sub filter_special_vertices {
  # TODO: Think of a better name
  # 
  # Looks at each item in an array of vertex names, intended to be
  # passed to via(). If any of them have only successors, replace that
  # item with an array of the vertex's successors.
  my ($graph, @vertices) = @_;
  my @retval;
  foreach my $v (@vertices) {
    if (!ref $v && !$graph->predecessors($v)) {
      push @retval, [$graph->successors($v)];
    } else {
      push @retval, $v;
    }
  }
  return @retval;
}

{
  my $paths = $g->traverse('PHX',{cb=>$to_any, end=>[$g->successors('LAX')], hash=>1, all=>0});

  is (scalar keys %{$paths}, 2, "Finds paths to destination vertices");
  is_deeply ([sort keys %{$paths}], [qw(LAX1 LAX2)], "Finds correct vertices");
  is ($paths->{LAX1}->{weight}, 6, "First path weight");
  is ($paths->{LAX2}->{weight}, 5, "Second path weight");
}

{
  my $paths = paths_via($g, filter_special_vertices($g, qw(PHX LAX SFO)));

  is (scalar keys %{$paths}, 1, "Finds one path to destination vertices");
  is_deeply ([sort keys %{$paths}], [qw(SFO3)], "Finds correct vertex");
  is ($paths->{SFO3}->{weight}, 14, "Path weight");

  # ;$DB::single = 1;
  # print "x";
}


# For each vertex in the list, if that vertex has successors and no
# predecessors, interpret this as "any of the the successors to this
# vertex" for that step in the path.



done_testing;

__END__



{
    my $paths = $g->traverse([qw(A)],{hash => 1});
    is ($paths->{D}->{weight}, 3, "Traversal A->D weight");
}

{
    my $paths = $g->traverse([qw(B)],{hash => 1});
    is (ref $paths, 'HASH', "Detailed traversal returns hash");
    is ($paths->{D}->{weight}, 2, "Traversal B->D weight");
}

{
    my $paths = $g->traverse([qw(B)],{hash => 1, next => 'predecessors'});
    is (ref $paths, 'HASH', "Detailed traversal in reverse returns hash");
    is ($paths->{A}->{weight}, 1, "Traversal B->A weight");
    ok (!defined $paths->{C}, "Reverse traversal from B should not find C");
}

$g->add_path(qw(A E F G D Q)); 
$g->set_edge_attribute('E','F','weight',0.2);
$g->set_edge_attribute('F','G','weight',0.2);

{
    my $paths = $g->traverse([qw(A)],{hash => 1});
    is ($paths->{D}->{weight}, 2.4, "Traversal A->D weight");
    is ($paths->{Q}->{weight}, 3.4, "Traversal A->Q weight");
}

{
    my $paths = $g->traverse('B',{hash => 1});
    is ($paths->{D}->{weight}, 2, "Traversal B->D weight");
    is ($paths->{Q}->{weight}, 3, "Traversal B->Q weight");
}

# Set a high weight on a shortcut, to force recalculation of
# depth-first search
$g->add_path(qw(A D));
$g->set_edge_attribute('A','D', 'weight', 11.3);

{
    my $paths = $g->traverse([qw(A)],{hash => 1});
    is ($paths->{D}->{weight}, 2.4, "Traversal A->D weight with one shortcut");
    is ($paths->{Q}->{weight}, 3.4, "Traversal A->Q weight with one shortcut");
}

$g->set_edge_attribute('A','C', 'weight', 17.3);

{
    my $paths = $g->traverse([qw(A)],{hash => 1});
    is ($paths->{D}->{weight}, 2.4, "Traversal A->D weight with two shortcuts");
    is ($paths->{Q}->{weight}, 3.4, "Traversal A->Q weight with two shortcuts");
}

{
    my $paths = $g->traverse([qw(D)],{hash => 1, next => 'predecessors'});
    is ($paths->{A}->{weight}, 2.4, "Traversal D->A");
}

{
    my $paths = $g->traverse([qw(A)],{hash => 1, attribute => 'time', default => 10});
    is ($paths->{D}->{weight}, 10, "Traversal A->D using 'time' attribute");
    is ($paths->{Q}->{weight}, 20, "Traversal A->Q using 'time' attribute");
}

$g->set_edge_attribute('A','D', 'time', 0.3);

{
    my $paths = $g->traverse([qw(A)],{hash => 1, attribute => 'time', default => 10});
    is ($paths->{B}->{weight},   10, "Traversal A->B using 'time' attribute");
    is ($paths->{C}->{weight},   10, "Traversal A->C using 'time' attribute");   # there is an A-C edge
    is ($paths->{D}->{weight},  0.3, "Traversal A->D using 'time' attribute");
    is ($paths->{Q}->{weight}, 10.3, "Traversal A->Q using 'time' attribute");   # A-D, D-Q.
    ok (!defined $paths->{Z}, "Traversal to undefined vertex");
}

$g->set_vertex_attribute('B', 'weight', 3);
$g->set_vertex_attribute('C', 'weight', 1);
$g->set_vertex_attribute('D', 'weight', 4);
$g->set_vertex_attribute('Q', 'weight', 1);

{
    my $paths = $g->traverse([qw(A)],{hash => 1, vertex => 1, max => 4, default => 0});
    is ($paths->{B}->{weight},   3, "Traversal A->B using vertex weight");   # A has weight 0
    is ($paths->{C}->{weight},   1, "Traversal A->C using vertex weight");   # there is an A-C edge
    is ($paths->{D}->{weight},   4, "Traversal A->D using vertex weight");   # there is an A-D edge
    ok (!defined $paths->{Q}, "Traversal A->Q, with maximum vertex weight, should fail");
}

$g->set_vertex_attribute('Q', 'weight', undef);

{
    my $paths = $g->traverse([qw(A)],{hash => 1, vertex => 1, max => 4, default => 0});
    is ($paths->{Q}->{weight},   4, "Traversal A->Q using vertex weight");   # A (weight=0), D (4), Q (0)
}

$g->add_cycle(qw(A X1 X2 X3));

{
    my $paths = $g->traverse('A',{hash => 1});
    is ($paths->{X3}->{weight}, 3, "Traversal of a graph with a cycle");
}

