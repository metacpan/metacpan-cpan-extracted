# Traversal Guide: Graph::Easy::Introspect AST

This document describes how to navigate the AST returned by `$g->ast` and
how to drive a renderer from it.

## Entry Point

```perl
use Graph::Easy ;
use Graph::Easy::Parser::Graphviz ;
use Graph::Easy::Introspect ;

my $parser = Graph::Easy::Parser::Graphviz->new ;
my $g      = $parser->from_text($dot_source) ;
my $ast    = $g->ast ;

die $ast->{error} if exists $ast->{error} ;
```

## Graph-Level Information

```perl
my $graph = $ast->{graph} ;

printf "directed:   %d\n",      $graph->{is_directed} ;
printf "dimensions: %dx%d\n",   $graph->{total_width}, $graph->{total_height} ;
printf "label:      %s\n",      $graph->{label} // '(none)' ;

for my $key (sort keys %{ $graph->{attrs} })
	{
	printf "attr %s = %s\n", $key, $graph->{attrs}{$key} ;
	}
```

## Iterating Nodes

Nodes are sorted by `id` (the Graph::Easy internal name).

```perl
for my $node (@{ $ast->{nodes} })
	{
	printf "%s  cell=(%d,%d)  char=(%d,%d)  char_size=%dx%d  in=%d  out=%d\n",
		$node->{id},
		$node->{x},      $node->{y},
		$node->{char_x}, $node->{char_y},
		$node->{char_width}, $node->{char_height},
		$node->{in_degree},  $node->{out_degree} ;

	next if $node->{is_isolated} ;

	printf "  label:     %s\n",   $node->{label} ;
	printf "  component: %d\n",   $node->{component} ;
	printf "  shape:     %s\n",   $node->{attrs}{shape} // 'rect' ;

	my $bb = $node->{bbox} ;
	printf "  cell bbox: (%d,%d)->(%d,%d)\n",
		$bb->{x1}, $bb->{y1}, $bb->{x2}, $bb->{y2} ;
	}
```

## Finding a Specific Node

```perl
my %node_by_id = map { $_->{id} => $_ } @{ $ast->{nodes} } ;
my $n = $node_by_id{A} ;
```

## Iterating Edges

Edges are sorted by `from` then `to`.

```perl
for my $edge (@{ $ast->{edges} })
	{
	printf "[%d] %s -> %s  arrow=%s  mult=%d\n",
		$edge->{id}, $edge->{from}, $edge->{to},
		$edge->{arrow_dir} // 'none',
		$edge->{multiplicity} ;

	print "  self-loop\n"      if $edge->{is_self_loop} ;
	print "  bidirectional\n"  if $edge->{is_bidirectional} ;
	}
```

## Finding Edges for a Node

```perl
my %edge_by_id = map { $_->{id} => $_ } @{ $ast->{edges} } ;
my $node = $node_by_id{B} ;

for my $eid (@{ $node->{edges_in} })
	{
	printf "incoming from %s\n", $edge_by_id{$eid}{from} ;
	}

for my $eid (@{ $node->{edges_out} })
	{
	printf "outgoing to %s\n", $edge_by_id{$eid}{to} ;
	}
```

## Edge Ports and Connection Sides

Port coordinates are available in both cell-grid and character space.

```perl
for my $edge (@{ $ast->{edges} })
	{
	next if $edge->{is_self_loop} ;

	printf "leaves %s on the %s side  cell=(%d,%d)  char=(%d,%d)\n",
		$edge->{from},
		$edge->{from_side} // 'unknown',
		$edge->{from_port}{x},      $edge->{from_port}{y},
		$edge->{from_port}{char_x}, $edge->{from_port}{char_y} ;

	printf "arrives at %s on the %s side  cell=(%d,%d)  char=(%d,%d)\n",
		$edge->{to},
		$edge->{to_side} // 'unknown',
		$edge->{to_port}{x},      $edge->{to_port}{y},
		$edge->{to_port}{char_x}, $edge->{to_port}{char_y} ;
	}
```

## Port Traversal on a Node

Ports are pre-sorted by visual position along each face and carry a `seq`
integer indicating their order.

```perl
for my $side (qw/left right top bottom/)
	{
	for my $port (@{ $node->{ports}{$side} })
		{
		printf "  %s side seq=%d  edge=%d  role=%s  cell=(%d,%d)  char=(%d,%d)\n",
			$side, $port->{seq}, $port->{edge_id},
			$port->{role},
			$port->{x},      $port->{y},
			$port->{char_x}, $port->{char_y} ;
		}
	}
```

## Edge Path Traversal

Each path entry describes one layout cell. Cells carry both cell-grid and
character-space coordinates.

```perl
for my $point (@{ $edge->{path} })
	{
	printf "  cell=(%d,%d)  char=(%d,%d)->(%d,%d)  type=%-8s  is_label=%d\n",
		$point->{x},       $point->{y},
		$point->{char_x},  $point->{char_y},
		$point->{char_x2}, $point->{char_y2},
		$point->{type},
		$point->{is_label} ;
	}
```

Cell type names and their meanings:

- `HOR` — horizontal segment
- `VER` — vertical segment
- `CROSS` — two edges crossing
- `N_E`, `N_W`, `S_E`, `S_W` — 90-degree corners (direction pair)
- `S_E_W`, `N_E_W`, `E_N_S`, `W_N_S` — T-junctions
- `N_W_S`, `S_W_N`, `E_S_W`, `W_S_E` — loop types
- `HOLE` — placeholder cell

## Edge Label Position

```perl
if (defined $edge->{label})
	{
	printf "label '%s'  cell=(%d,%d)  char=(%d,%d)\n",
		$edge->{label},
		$edge->{label_x},      $edge->{label_y},
		$edge->{label_char_x}, $edge->{label_char_y} ;
	}
```

## Group Traversal

Groups and member nodes have a bidirectional relationship. Groups carry
both cell-grid and character-space bounding boxes.

```perl
for my $group (@{ $ast->{groups} })
	{
	printf "group %s  char=(%d,%d)  char_size=%dx%d  nodes=[%s]\n",
		$group->{id},
		$group->{char_x},    $group->{char_y},
		$group->{char_width}, $group->{char_height},
		join(', ', @{ $group->{nodes} }) ;

	my $bb = $group->{bbox} ;
	printf "  cell bbox (%d,%d)->(%d,%d)\n",
		$bb->{x1}, $bb->{y1}, $bb->{x2}, $bb->{y2} ;
	}

# From a node, find its groups
for my $gid (@{ $node->{groups} })
	{
	printf "node belongs to group %s\n", $gid ;
	}
```

## Connected Components

Each node carries a `component` integer. Nodes with the same value belong
to the same weakly connected component.

```perl
my %by_component ;

for my $node (@{ $ast->{nodes} })
	{
	push @{ $by_component{ $node->{component} } }, $node->{id} ;
	}

for my $cid (sort keys %by_component)
	{
	printf "component %d: %s\n", $cid, join(', ', @{ $by_component{$cid} }) ;
	}
```

## Character Grid

The grid is indexed as `$grid->[$row][$col]`, matching the `as_ascii` output
character by character. Row 0 is the top line. Node and edge char coordinates
index directly into this array.

```perl
my $grid = $ast->{grid} ;

for my $row (@$grid)
	{
	print join('', @$row), "\n" ;
	}

# Verify a node's top-left corner character
my $node = $node_by_id{A} ;
my $char  = $grid->[ $node->{char_y} ][ $node->{char_x} ] ;
# $char eq '+' for a normal rectangular node
```

## Cell Grid

`ast->{cell_grid}` maps `"cell_x,cell_y"` keys to a description of what
occupies that cell. It is the bridge between cell-grid coordinates and
character-space coordinates without iterating the node or edge arrays.

```perl
my $cell_grid = $ast->{cell_grid} ;

# Look up what is at a known cell position
my $entry = $cell_grid->{'0,0'} ;
printf "type=%s name=%s char=(%d,%d) size=%dx%d\n",
	$entry->{type}, $entry->{name},
	$entry->{char_x}, $entry->{char_y},
	$entry->{render_w}, $entry->{render_h} ;

# List all node cells
for my $key (sort keys %$cell_grid)
	{
	my $c = $cell_grid->{$key} ;
	next unless $c->{type} eq 'node' ;
	printf "node %s at cell %s, char (%d,%d)\n",
		$c->{name}, $key, $c->{char_x}, $c->{char_y} ;
	}
```

## Generation Metadata

```perl
my $meta = $ast->{meta} ;

printf "generated at:        %s\n", scalar localtime($meta->{generated_at}) ;
printf "Graph::Easy version: %s\n", $meta->{graph_easy_version} ;
printf "Introspect version:  %s\n", $meta->{introspect_version} ;
printf "layout algorithm:    %s\n", $meta->{layout_algorithm} ;
```

## Driving a Renderer

The `graph_easy_render` script and `Graph::Easy::Introspect::Renderer`
provide a complete rendering pipeline. To use the base class directly:

```perl
use Graph::Easy::Introspect::Renderer ;

my $r   = Graph::Easy::Introspect::Renderer->new ;
my $ast = $g->ast ;

# groups first so node boxes are drawn on top
for my $grp (@{ $ast->{groups} })
	{
	$r->draw_group($grp->{char_x}, $grp->{char_y},
		$grp->{char_width}, $grp->{char_height}, $grp->{label}) ;
	}

for my $node (@{ $ast->{nodes} })
	{
	$r->draw_box($node->{char_x}, $node->{char_y},
		$node->{char_width}, $node->{char_height}, $node->{label}) ;
	}

for my $edge (@{ $ast->{edges} })
	{
	next if $edge->{is_self_loop} ;
	my $end = $ast->{graph}{is_directed} ? 'arrow' : 'none' ;
	$r->draw_arrow('none', $end, $edge->{path}) ;
	}
```

To build a real renderer, subclass and override only the methods you need:

```perl
package My::Renderer ;
use parent 'Graph::Easy::Introspect::Renderer' ;

sub draw_box
{
my ($self, $x, $y, $w, $h, $text) = @_ ;
# emit real output
}
```

Unoverridden methods continue to print to STDERR, making it easy to track
which drawing calls are generated during development.
