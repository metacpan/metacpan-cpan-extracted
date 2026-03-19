
package Graph::Easy::Introspect ;

use strict ;
use warnings ;

our $VERSION = '0.01' ;

use Graph::Easy::Edge::Cell qw(
	EDGE_HOR    EDGE_VER  EDGE_CROSS EDGE_HOLE
	EDGE_N_E    EDGE_N_W  EDGE_S_E   EDGE_S_W
	EDGE_START_E EDGE_START_W EDGE_START_N EDGE_START_S
	EDGE_END_E   EDGE_END_W   EDGE_END_N   EDGE_END_S
	) ;

use constant EDGE_TYPE_MASK  => 0x000F ;
use constant EDGE_END_MASK   => 0x00F0 ;
use constant EDGE_START_MASK => 0x0F00 ;
use constant EDGE_LABEL_CELL => 0x1000 ;

my %CELL_TYPE_NAME =
	(
	EDGE_CROSS() => 'CROSS',
	EDGE_HOR()   => 'HOR',
	EDGE_VER()   => 'VER',
	EDGE_N_E()   => 'N_E',
	EDGE_N_W()   => 'N_W',
	EDGE_S_E()   => 'S_E',
	EDGE_S_W()   => 'S_W',
	EDGE_HOLE()  => 'HOLE',
	7            => 'S_E_W',
	8            => 'N_E_W',
	9            => 'E_N_S',
	10           => 'W_N_S',
	12           => 'N_W_S',
	13           => 'S_W_N',
	14           => 'E_S_W',
	15           => 'W_S_E',
	) ;

our $WRAPPER_INSTALLED = 0 ;

# ------------------------------------------------------------------------------

sub install_layout_wrapper
{
return if $WRAPPER_INSTALLED ;

require Graph::Easy::Layout::Grid ;

{
no warnings 'redefine' ;

my $orig = \&Graph::Easy::_prepare_layout ;

*Graph::Easy::_prepare_layout = sub
	{
	my ($self, $format) = @_ ;

	my ($rows, $cols, $max_x, $max_y) = $orig->($self, $format) ;

	if (($format // '') eq 'ascii' && !$self->{_introspect_captured})
		{
		my $align     = eval { $self->attribute('align') } // 'left' ;
		my ($label)   = eval { $self->_aligned_label($align) } ;
		$label      //= [] ;
		my $label_pos = eval { $self->attribute('graph', 'label-pos') } // 'top' ;

		my $y_start = 0 ;
		my $x_start = 0 ;

		if (@$label > 0)
			{
			unshift @$label, '' ;
			push    @$label, '' ;

			$y_start = scalar @$label if $label_pos eq 'top' ;

			my $old_max_x = $max_x ;

			for my $l (@$label)
				{
				$max_x = length($l) + 2 if length($l) > $max_x + 2 ;
				}

			$x_start = int(($max_x - $old_max_x) / 2) ;
			}

		my %char_pos ;

		for my $c (values %{$self->{cells}})
			{
			$char_pos{"$c->{x},$c->{y}"} =
				{
				char_x   => ($cols->{$c->{x}} // 0) + $x_start,
				char_y   => ($rows->{$c->{y}} // 0) + $y_start,
				render_w => $c->{w} // 0,
				render_h => $c->{h} // 0,
				ref      => ref($c),
				name     => ($c->can('name') ? ($c->name // '') : ''),
				} ;
			}

		$self->{_introspect_char_pos} = \%char_pos ;
		$self->{_introspect_captured} = 1 ;
		}

	return ($rows, $cols, $max_x, $max_y) ;
	} ;
}

$WRAPPER_INSTALLED = 1 ;
}

# ------------------------------------------------------------------------------

sub node_bbox
{
my ($node) = @_ ;

my $x  = $node->x  // 0 ;
my $y  = $node->y  // 0 ;
my $cx = $node->{cx} // 1 ;
my $cy = $node->{cy} // 1 ;

return ($x, $y, $x + $cx - 1, $y + $cy - 1) ;
}

# ------------------------------------------------------------------------------

sub port_side
{
my ($node, $port) = @_ ;

return undef unless $port ;

my ($x1, $y1, $x2, $y2) = node_bbox($node) ;
my ($px, $py) = @{$port}{qw/x y/} ;

return 'right'   if $px > $x2 && $py >= $y1 && $py <= $y2 ;
return 'left'    if $px < $x1 && $py >= $y1 && $py <= $y2 ;
return 'bottom'  if $py > $y2 && $px >= $x1 && $px <= $x2 ;
return 'top'     if $py < $y1 && $px >= $x1 && $px <= $x2 ;

return 'unknown' ;
}

# ------------------------------------------------------------------------------

sub cell_type_name
{
my ($type_code) = @_ ;

return $CELL_TYPE_NAME{$type_code} // "UNKNOWN_$type_code" ;
}

# ------------------------------------------------------------------------------

sub extract_attrs
{
my ($obj) = @_ ;

my $att = $obj->{att} ;
return {} unless defined $att && ref $att eq 'HASH' ;

my %attrs ;

for my $key (sort keys %$att)
	{
	my $val = $att->{$key} ;
	next unless defined $val ;
	next if ref $val ;
	next if $val eq '' ;
	$attrs{$key} = $val ;
	}

return \%attrs ;
}

# ------------------------------------------------------------------------------

sub extract_graph_attrs
{
my ($g) = @_ ;

my $att = $g->{att} ;
return {} unless defined $att && ref $att eq 'HASH' ;

my $graph_att = $att->{graph} ;
return {} unless defined $graph_att && ref $graph_att eq 'HASH' ;

my %attrs ;

for my $key (sort keys %$graph_att)
	{
	my $val = $graph_att->{$key} ;
	next unless defined $val ;
	next if ref $val ;
	next if $val eq '' ;
	$attrs{$key} = $val ;
	}

return \%attrs ;
}

# ------------------------------------------------------------------------------

sub compute_components
{
my ($g) = @_ ;

my %adj ;

for my $e ($g->edges)
	{
	my $f = $e->from->name ;
	my $t = $e->to->name ;

	push @{$adj{$f}}, $t ;
	push @{$adj{$t}}, $f unless $f eq $t ;
	}

my %component ;
my $comp_id = 0 ;

for my $node (sort { $a->name cmp $b->name } $g->nodes)
	{
	my $name = $node->name ;
	next if exists $component{$name} ;

	my @queue = ($name) ;

	while (@queue)
		{
		my $n = shift @queue ;
		next if exists $component{$n} ;

		$component{$n} = $comp_id ;

		push @queue, grep { !exists $component{$_} } @{$adj{$n} || []} ;
		}

	$comp_id++ ;
	}

return %component ;
}

# ------------------------------------------------------------------------------

sub sorted_nodes
{
my ($g) = @_ ;

return sort { $a->name cmp $b->name } $g->nodes ;
}

# ------------------------------------------------------------------------------

sub sorted_edges
{
my ($g) = @_ ;

return sort
	{
	$a->from->name cmp $b->from->name ||
	$a->to->name   cmp $b->to->name
	} $g->edges ;
}

# ------------------------------------------------------------------------------

sub group_char_bbox
{
my ($g, $g_ast, $char_pos) = @_ ;

my $bx1 = $g_ast->{bbox}{x1} ;
my $by1 = $g_ast->{bbox}{y1} ;
my $bx2 = $g_ast->{bbox}{x2} ;
my $by2 = $g_ast->{bbox}{y2} ;

my $tl_key = ($bx1 - 1) . ',' . ($by1 - 1) ;
my $br_key = ($bx2 + 1) . ',' . ($by2 + 1) ;

my $tl = $char_pos->{$tl_key} ;
my $br = $char_pos->{$br_key} ;

return undef unless $tl && $br ;

return
	{
	x  => $tl->{char_x},
	y  => $tl->{char_y},
	x2 => $br->{char_x} + $br->{render_w} - 1,
	y2 => $br->{char_y} + $br->{render_h} - 1,
	w  => ($br->{char_x} + $br->{render_w} - 1) - $tl->{char_x} + 1,
	h  => ($br->{char_y} + $br->{render_h} - 1) - $tl->{char_y} + 1,
	} ;
}

# ------------------------------------------------------------------------------
# Compute the char-space face coordinates for an edge port attachment point.
# Returns the point ON the node face (border character row/col) at which the
# edge enters or leaves the node.  This is distinct from the edge cell's
# top-left corner, which for short single-cell edges is the same cell for
# both from_port and to_port.

sub face_char
{
my ($node_ast, $side) = @_ ;

my $nx = $node_ast->{char_x} ;
my $ny = $node_ast->{char_y} ;
my $nw = $node_ast->{char_width} ;
my $nh = $node_ast->{char_height} ;

# Use intrinsic width/height for the center calculation.
# Group membership expands char_width but the edge path uses the intrinsic
# node center, so int(intrinsic/2) gives the correct column/row offset.
my $iw = $node_ast->{width}  || $nw ;
my $ih = $node_ast->{height} || $nh ;

return ($nx + $nw,           $ny + int($ih / 2)) if $side eq 'right' ;
return ($nx - 1,             $ny + int($ih / 2)) if $side eq 'left' ;
return ($nx + int($iw / 2),  $ny + $nh)          if $side eq 'bottom' ;
return ($nx + int($iw / 2),  $ny - 1)            if $side eq 'top' ;

return ($nx, $ny) ;
}

# ------------------------------------------------------------------------------

package Graph::Easy::Edge ;

use strict ;
use warnings ;

sub path
{
my ($self) = @_ ;

return [ map { [$_->{x}, $_->{y}] } @{$self->{cells} || []} ] ;
}

# ------------------------------------------------------------------------------

sub from_port
{
my ($self) = @_ ;

return undef if $self->from->name eq $self->to->name ;

my $from = $self->from ;
my ($x1, $y1, $x2, $y2) = Graph::Easy::Introspect::node_bbox($from) ;

my @adjacent = grep
	{
	my ($cx, $cy) = ($_->{x}, $_->{y}) ;
	($cx > $x2 && $cy >= $y1 && $cy <= $y2) ||
	($cx < $x1 && $cy >= $y1 && $cy <= $y2) ||
	($cy > $y2 && $cx >= $x1 && $cx <= $x2) ||
	($cy < $y1 && $cx >= $x1 && $cx <= $x2)
	} @{$self->{cells} || []} ;

return undef unless @adjacent ;

my $ncx = ($x1 + $x2) / 2 ;
my $ncy = ($y1 + $y2) / 2 ;

my ($best) = sort
	{
	abs($a->{x} - $ncx) + abs($a->{y} - $ncy)
	<=>
	abs($b->{x} - $ncx) + abs($b->{y} - $ncy)
	} @adjacent ;

return { x => $best->{x}, y => $best->{y} } ;
}

# ------------------------------------------------------------------------------

sub to_port
{
my ($self) = @_ ;

return undef if $self->from->name eq $self->to->name ;

my $to = $self->to ;
my ($x1, $y1, $x2, $y2) = Graph::Easy::Introspect::node_bbox($to) ;

my @adjacent = grep
	{
	my ($cx, $cy) = ($_->{x}, $_->{y}) ;
	($cx > $x2 && $cy >= $y1 && $cy <= $y2) ||
	($cx < $x1 && $cy >= $y1 && $cy <= $y2) ||
	($cy > $y2 && $cx >= $x1 && $cx <= $x2) ||
	($cy < $y1 && $cx >= $x1 && $cx <= $x2)
	} @{$self->{cells} || []} ;

return undef unless @adjacent ;

my $ncx = ($x1 + $x2) / 2 ;
my $ncy = ($y1 + $y2) / 2 ;

my ($best) = sort
	{
	abs($a->{x} - $ncx) + abs($a->{y} - $ncy)
	<=>
	abs($b->{x} - $ncx) + abs($b->{y} - $ncy)
	} @adjacent ;

return { x => $best->{x}, y => $best->{y} } ;
}

# ------------------------------------------------------------------------------

sub arrow_dir
{
my ($self) = @_ ;

for my $c (@{$self->{cells} || []})
	{
	my $end = ($c->{type} // 0) & Graph::Easy::Introspect::EDGE_END_MASK ;

	return 'right' if $end == Graph::Easy::Introspect::EDGE_END_E ;
	return 'left'  if $end == Graph::Easy::Introspect::EDGE_END_W ;
	return 'down'  if $end == Graph::Easy::Introspect::EDGE_END_S ;
	return 'up'    if $end == Graph::Easy::Introspect::EDGE_END_N ;
	}

return undef ;
}

# ------------------------------------------------------------------------------

package Graph::Easy ;

use strict ;
use warnings ;

sub ast
{
my ($self) = @_ ;

Graph::Easy::Introspect::install_layout_wrapper() ;

delete $self->{_introspect_captured} ;
delete $self->{_introspect_char_pos} ;
delete $self->{_introspect_grid} ;
delete $self->{_introspect_cell_grid} ;

my $ascii ;

eval { $ascii = $self->as_ascii } ;

if ($@)
	{
	return
		{
		error   => "$@",
		meta    => { introspect_version => $Graph::Easy::Introspect::VERSION },
		} ;
	}

my $char_pos = $self->{_introspect_char_pos} || {} ;
my $grid      = [ map { [split //, $_] } split /\n/, $ascii ] ;

my $total_height = scalar @$grid ;
my $total_width  = 0 ;

for my $row (@$grid)
	{
	$total_width = scalar @$row if scalar @$row > $total_width ;
	}

$self->{_introspect_grid} = $grid ;

my @sorted_nodes = Graph::Easy::Introspect::sorted_nodes($self) ;
my @sorted_edges = Graph::Easy::Introspect::sorted_edges($self) ;

my %node_index ;
my $ni = 0 ;

for my $n (@sorted_nodes)
	{
	$node_index{$n->name} = $ni++ ;
	}

my %component = Graph::Easy::Introspect::compute_components($self) ;

my %mult_groups ;

{
my $eid = 0 ;

for my $e (@sorted_edges)
	{
	my $key = $e->from->name . '|' . $e->to->name ;
	push @{$mult_groups{$key}}, $eid++ ;
	}
}

my $is_directed = do
	{
	my $r = eval { $self->is_directed } ;
	defined $r ? ($r ? 1 : 0) : 1 ;
	} ;

my $graph_attrs = Graph::Easy::Introspect::extract_graph_attrs($self) ;
my $graph_label = do { my $l = eval { $self->label } ; (defined $l && $l ne '') ? $l : undef } ;
my $layout_algo = eval { $self->attribute('flow') } // 'default' ;

my @nodes_ast ;

for my $node (@sorted_nodes)
	{
	my $name    = $node->name ;
	my $cell_x  = $node->x  // 0 ;
	my $cell_y  = $node->y  // 0 ;
	my $cx      = $node->{cx} // 1 ;
	my $cy      = $node->{cy} // 1 ;
	my $cell_key = "$cell_x,$cell_y" ;
	my $cp      = $char_pos->{$cell_key} // {} ;
	my $char_x  = $cp->{char_x}   // 0 ;
	my $char_y  = $cp->{char_y}   // 0 ;
	my $char_w  = $cp->{render_w} // ($node->width  // 0) ;
	my $char_h  = $cp->{render_h} // ($node->height // 0) ;
	my $label   = do { my $l = eval { $node->label } ; (defined $l && $l ne '') ? $l : $name } ;
	my $is_anon = eval { $node->isa('Graph::Easy::Node::Anon') } ? 1 : 0 ;

	push @nodes_ast,
		{
		id          => $name,
		label       => $label,
		is_anon     => $is_anon,
		is_isolated => 0,
		x           => $cell_x,
		y           => $cell_y,
		char_x      => $char_x,
		char_y      => $char_y,
		char_width  => $char_w,
		char_height => $char_h,
		width       => $node->width  // 0,
		height      => $node->height // 0,
		bbox        =>
			{
			x1 => $cell_x,
			y1 => $cell_y,
			x2 => $cell_x + $cx - 1,
			y2 => $cell_y + $cy - 1,
			},
		component   => $component{$name} // 0,
		groups      => [],
		edges_in    => [],
		edges_out   => [],
		ports       =>
			{
			left    => [],
			right   => [],
			top     => [],
			bottom  => [],
			unknown => [],
			},
		attrs       => Graph::Easy::Introspect::extract_attrs($node),
		} ;
	}

my @edges_ast ;
my $edge_id = 0 ;

for my $edge (@sorted_edges)
	{
	my $from = $edge->from ;
	my $to   = $edge->to ;

	my $is_self_loop = $from->name eq $to->name ? 1 : 0 ;
	my $is_bidi      = do
		{
		my $b = 0 ;
		$b = 1 if ref($edge) =~ /Bidirectional/i ;
		$b = 1 if !$b && (eval { $edge->bidirectional } // 0) ;
		$b ;
		} ;

	my $from_port = $edge->from_port ;
	my $to_port   = $edge->to_port ;
	my $arrow_dir = $edge->arrow_dir ;

	my $from_side = Graph::Easy::Introspect::port_side($from, $from_port) ;
	my $to_side   = Graph::Easy::Introspect::port_side($to,   $to_port) ;

	my $key          = $from->name . '|' . $to->name ;
	my $multiplicity = scalar @{$mult_groups{$key} || []} ;

	my $edge_label = do { my $l = eval { $edge->label } ; (defined $l && $l ne '') ? $l : undef } ;

	# from_port and to_port char coords are ON the node face, not the edge cell.
	# This gives correct distinct coords even for single-cell short edges.
	my $from_ast_node = $nodes_ast[ $node_index{$from->name} ] ;
	my $to_ast_node   = $nodes_ast[ $node_index{$to->name} ] ;

	my $build_port = sub
		{
		my ($port, $node_ast, $side) = @_ ;
		return undef unless $port ;

		my ($cx, $cy) = Graph::Easy::Introspect::face_char($node_ast, $side // 'unknown') ;

		return
			{
			x      => $port->{x},
			y      => $port->{y},
			char_x => $cx,
			char_y => $cy,
			} ;
		} ;

	my ($label_x, $label_y, $label_char_x, $label_char_y) ;
	my @path ;

	for my $c (@{$edge->{cells} || []})
		{
		my $type      = $c->{type} // 0 ;
		my $type_base = $type & Graph::Easy::Introspect::EDGE_TYPE_MASK ;
		my $is_label  = ($type & Graph::Easy::Introspect::EDGE_LABEL_CELL) ? 1 : 0 ;
		my $ckey      = "$c->{x},$c->{y}" ;
		my $cp        = $char_pos->{$ckey} // {} ;

		if ($is_label && !defined $label_x)
			{
			$label_x      = $c->{x} ;
			$label_y      = $c->{y} ;
			$label_char_x = $cp->{char_x} ;
			$label_char_y = $cp->{char_y} ;
			}

		my $cx    = $cp->{char_x}   // 0 ;
		my $cy    = $cp->{char_y}   // 0 ;
		my $cx2   = $cx + ($cp->{render_w} // 1) - 1 ;
		my $cy2   = $cy + ($cp->{render_h} // 1) - 1 ;

		push @path,
			{
			x         => $c->{x},
			y         => $c->{y},
			char_x    => $cx,
			char_y    => $cy,
			char_x2   => $cx2,
			char_y2   => $cy2,
			line_x1   => 0,
			line_y1   => 0,
			line_x2   => 0,
			line_y2   => 0,
			type      => Graph::Easy::Introspect::cell_type_name($type_base),
			type_code => $type_base,
			is_label  => $is_label,
			} ;
		}

	# Sort path cells into traversal order by adjacency walk from from_port.
	# $edge->{cells} is a hash so storage order is undefined.
	if (!$is_self_loop && $from_port && @path > 1)
		{
		my %by_pos = map { my $k = "$_->{x},$_->{y}" ; $k => $_ } @path ;
		my $start_key = "$from_port->{x},$from_port->{y}" ;

		unless (exists $by_pos{$start_key})
			{
			for my $d ([-1,0],[1,0],[0,-1],[0,1])
				{
				my $k = ($from_port->{x}+$d->[0]) . ',' . ($from_port->{y}+$d->[1]) ;
				if (exists $by_pos{$k}) { $start_key = $k ; last }
				}
			}

		my @sorted ;
		my %visited ;
		my $cur = $start_key ;

		while (exists $by_pos{$cur} && !$visited{$cur})
			{
			$visited{$cur} = 1 ;
			push @sorted, $by_pos{$cur} ;
			my $c    = $by_pos{$cur} ;
			my $next ;

			for my $d ([-1,0],[1,0],[0,-1],[0,1])
				{
				my $nk = ($c->{x}+$d->[0]) . ',' . ($c->{y}+$d->[1]) ;
				next unless exists $by_pos{$nk} && !$visited{$nk} ;
				$next = $nk ;
				last ;
				}

			last unless defined $next ;
			$cur = $next ;
			}

		@path = @sorted if @sorted == @path ;
		}

	# Compute line_* for each path cell using a waypoint-based polyline model.
	#
	# Waypoints: [from_port_char, corner_0_bend, ..., corner_n_bend, to_port_char]
	# Each corner cell either introduces a straight run (next cell is VER/HOR)
	# or terminates one (prev cell is VER/HOR).
	#   Introducing corner: assign wp[ci]->wp[ci+1], then advance ci.
	#   Terminating corner: advance ci first, then assign wp[ci]->wp[ci+1].
	# VER/HOR cells: always assign wp[ci]->wp[ci+1], never advance ci.
	#
	# This gives contiguous, directed segments: each cell's endpoint equals
	# the next cell's start point.

	my %is_straight_type = (VER => 1, HOR => 1, CROSS => 1, HOLE => 1) ;

	my ($fp_lx, $fp_ly) = (0, 0) ;
	my ($tp_lx, $tp_ly) = (0, 0) ;

	unless ($is_self_loop)
		{
		($fp_lx, $fp_ly) = Graph::Easy::Introspect::face_char($from_ast_node, $from_side)
			if $from_side ne 'unknown' ;
		($tp_lx, $tp_ly) = Graph::Easy::Introspect::face_char($to_ast_node, $to_side)
			if $to_side ne 'unknown' ;
		}

	# Build mid_x/mid_y for each cell (needed for corner bends).
	my %cell_mid ;
	for my $p (@path)
		{
		my $cp2  = $char_pos->{"$p->{x},$p->{y}"} // {} ;
		my $midx = ($cp2->{char_x} // 0) + int(($cp2->{render_w} // 1) / 2) ;
		my $midy = ($cp2->{char_y} // 0) + int(($cp2->{render_h} // 1) / 2) ;
		$cell_mid{"$p->{x},$p->{y}"} = [$midx, $midy] ;
		}

	# Build waypoint list.
	my @wp = ([$fp_lx, $fp_ly]) ;

	for my $p (@path)
		{
		next if $is_straight_type{$p->{type}} ;
		my $m = $cell_mid{"$p->{x},$p->{y}"} ;
		push @wp, [$m->[0], $m->[1]] ;
		}

	push @wp, [$tp_lx, $tp_ly] ;

	# Assign line_* to each cell.
	my $ci = 0 ;

	for my $i (0 .. $#path)
		{
		my $p    = $path[$i] ;
		my $prev = $i > 0 ? $path[$i-1] : undef ;

		if ($is_straight_type{$p->{type}})
			{
			my $next_ci = $ci + 1 < $#wp ? $ci + 1 : $#wp ;
			$p->{line_x1} = $wp[$ci][0] ;
			$p->{line_y1} = $wp[$ci][1] ;
			$p->{line_x2} = $wp[$next_ci][0] ;
			$p->{line_y2} = $wp[$next_ci][1] ;
			}
		else
			{
			my $prev_straight = $prev && $is_straight_type{$prev->{type}} ;

			$ci++ if $prev_straight ;

			my $next_ci = $ci + 1 < $#wp ? $ci + 1 : $#wp ;
			$p->{line_x1} = $wp[$ci][0] ;
			$p->{line_y1} = $wp[$ci][1] ;
			$p->{line_x2} = $wp[$next_ci][0] ;
			$p->{line_y2} = $wp[$next_ci][1] ;

			my $m = $cell_mid{"$p->{x},$p->{y}"} ;
			$p->{bend_x} = $m->[0] ;
			$p->{bend_y} = $m->[1] ;

			$ci++ unless $prev_straight ;
			}
		}

	push @edges_ast,
		{
		id               => $edge_id,
		from             => $from->name,
		to               => $to->name,
		is_self_loop     => $is_self_loop,
		is_bidirectional => $is_bidi,
		multiplicity     => $multiplicity,
		arrow_dir        => $arrow_dir,
		from_port        => $build_port->($from_port, $from_ast_node, $from_side),
		to_port          => $build_port->($to_port,   $to_ast_node,   $to_side),
		from_side        => $from_side,
		to_side          => $to_side,
		label            => $edge_label,
		label_x          => $label_x,
		label_y          => $label_y,
		label_char_x     => $label_char_x,
		label_char_y     => $label_char_y,
		path             => \@path,
		attrs            => Graph::Easy::Introspect::extract_attrs($edge),
		} ;

	$edge_id++ ;
	}

my @groups_ast ;
my %group_index ;
my $gi = 0 ;

my @graph_groups ;
eval { @graph_groups = $self->groups } ;

for my $group (sort { $a->name cmp $b->name } @graph_groups)
	{
	my $gname  = $group->name ;
	my @gnodes = eval { map { $_->name } $group->nodes } ;

	$group_index{$gname} = $gi ;

	my ($bx1, $by1, $bx2, $by2) ;

	for my $nname (@gnodes)
		{
		my $n = $self->node($nname) ;
		next unless $n ;

		my ($nx1, $ny1, $nx2, $ny2) = Graph::Easy::Introspect::node_bbox($n) ;

		$bx1 = $nx1 if !defined $bx1 || $nx1 < $bx1 ;
		$by1 = $ny1 if !defined $by1 || $ny1 < $by1 ;
		$bx2 = $nx2 if !defined $bx2 || $nx2 > $bx2 ;
		$by2 = $ny2 if !defined $by2 || $ny2 > $by2 ;
		}

	my $cell_bbox =
		{
		x1 => $bx1 // 0,
		y1 => $by1 // 0,
		x2 => $bx2 // 0,
		y2 => $by2 // 0,
		} ;

	my $glabel = do { my $l = eval { $group->label } ; (defined $l && $l ne '') ? $l : $gname } ;

	my $gcb = Graph::Easy::Introspect::group_char_bbox($self, { bbox => $cell_bbox }, $char_pos) ;

	push @groups_ast,
		{
		id          => $gname,
		label       => $glabel,
		nodes       => \@gnodes,
		bbox        => $cell_bbox,
		char_x      => $gcb ? $gcb->{x}  : 0,
		char_y      => $gcb ? $gcb->{y}  : 0,
		char_width  => $gcb ? $gcb->{w}  : 0,
		char_height => $gcb ? $gcb->{h}  : 0,
		attrs       => Graph::Easy::Introspect::extract_attrs($group),
		} ;

	$gi++ ;
	}

$edge_id = 0 ;

for my $e_ast (@edges_ast)
	{
	my $from_idx = $node_index{$e_ast->{from}} ;
	my $to_idx   = $node_index{$e_ast->{to}} ;
	my $eid      = $e_ast->{id} ;

	push @{$nodes_ast[$from_idx]{edges_out}}, $eid ;
	push @{$nodes_ast[$to_idx]{edges_in}},   $eid ;

	if ($e_ast->{from_port})
		{
		my $side = $e_ast->{from_side} || 'unknown' ;

		push @{$nodes_ast[$from_idx]{ports}{$side}},
			{
			edge_id => $eid,
			role    => 'out',
			x       => $e_ast->{from_port}{x},
			y       => $e_ast->{from_port}{y},
			char_x  => $e_ast->{from_port}{char_x},
			char_y  => $e_ast->{from_port}{char_y},
			} ;
		}

	if ($e_ast->{to_port})
		{
		my $side = $e_ast->{to_side} || 'unknown' ;

		push @{$nodes_ast[$to_idx]{ports}{$side}},
			{
			edge_id => $eid,
			role    => 'in',
			x       => $e_ast->{to_port}{x},
			y       => $e_ast->{to_port}{y},
			char_x  => $e_ast->{to_port}{char_x},
			char_y  => $e_ast->{to_port}{char_y},
			} ;
		}

	$edge_id++ ;
	}

for my $n_ast (@nodes_ast)
	{
	for my $side (qw/left right/)
		{
		$n_ast->{ports}{$side} =
			[sort { $a->{y} <=> $b->{y} } @{$n_ast->{ports}{$side}}] ;
		}

	for my $side (qw/top bottom/)
		{
		$n_ast->{ports}{$side} =
			[sort { $a->{x} <=> $b->{x} } @{$n_ast->{ports}{$side}}] ;
		}

	for my $side (qw/left right top bottom unknown/)
		{
		my $seq = 0 ;

		for my $p (@{$n_ast->{ports}{$side}})
			{
			$p->{seq} = $seq++ ;
			}
		}

	$n_ast->{is_isolated} =
		(scalar(@{$n_ast->{edges_in}}) == 0 && scalar(@{$n_ast->{edges_out}}) == 0) ? 1 : 0 ;
	}

for my $g_ast (@groups_ast)
	{
	for my $nname (@{$g_ast->{nodes}})
		{
		my $idx = $node_index{$nname} ;
		next unless defined $idx ;
		push @{$nodes_ast[$idx]{groups}}, $g_ast->{id} ;
		}
	}

my %cell_grid ;

for my $key (keys %$char_pos)
	{
	my $cp   = $char_pos->{$key} ;
	my $type = 'unknown' ;

	if ($cp->{ref} =~ /::Node$/)
		{
		$type = 'node' ;
		}
	elsif ($cp->{ref} =~ /Edge/)
		{
		$type = 'edge' ;
		}
	elsif ($cp->{ref} =~ /Group/)
		{
		$type = 'group' ;
		}
	elsif ($cp->{ref} =~ /Node::Cell/)
		{
		$type = 'empty' ;
		}

	$cell_grid{$key} =
		{
		type     => $type,
		name     => $cp->{name},
		char_x   => $cp->{char_x},
		char_y   => $cp->{char_y},
		render_w => $cp->{render_w},
		render_h => $cp->{render_h},
		} ;
	}

$self->{_introspect_cell_grid} = \%cell_grid ;

return
	{
	meta    =>
		{
		introspect_version => $Graph::Easy::Introspect::VERSION,
		graph_easy_version => $Graph::Easy::VERSION,
		generated_at       => time(),
		layout_algorithm   => $layout_algo,
		},
	graph   =>
		{
		is_directed  => $is_directed,
		label        => $graph_label,
		total_width  => $total_width,
		total_height => $total_height,
		attrs        => $graph_attrs,
		},
	nodes     => \@nodes_ast,
	edges     => \@edges_ast,
	groups    => \@groups_ast,
	} ;
}

# ------------------------------------------------------------------------------

sub ast_grid
{
my ($self) = @_ ;

return $self->{_introspect_grid} ;
}

# ------------------------------------------------------------------------------

sub ast_cell_grid
{
my ($self) = @_ ;

return $self->{_introspect_cell_grid} ;
}

1 ;

__END__

=pod

=head1 NAME

Graph::Easy::Introspect - Introspection and AST for Graph::Easy layouts

=head1 SYNOPSIS

  use Graph::Easy;
  use Graph::Easy::Parser::Graphviz;
  use Graph::Easy::Introspect;

  my $parser = Graph::Easy::Parser::Graphviz->new;
  my $g      = $parser->from_text('digraph { A -> B -> C }');

  my $ast       = $g->ast;
  my $grid      = $g->ast_grid;       # 2D char array, undef if ast not called
  my $cell_grid = $g->ast_cell_grid;  # cell-key => info hash

  for my $node (@{ $ast->{nodes} }) {
      printf "%s at char (%d,%d) size %dx%d\n",
          $node->{id},
          $node->{char_x},  $node->{char_y},
          $node->{char_width}, $node->{char_height};
  }

=head1 DESCRIPTION

This module extends Graph::Easy with three entry points: C<ast>, C<ast_grid>,
and C<ast_cell_grid>. C<ast> renders the graph and returns a complete,
self-contained data structure describing nodes, edges, groups, and positions.
The rendered character grid and cell-grid lookup table are stored separately
and retrieved via C<ast_grid> and C<ast_cell_grid>.

The module monkey-patches three packages:

=over 4

=item * C<Graph::Easy::Introspect> — helper functions (not methods)

=item * C<Graph::Easy::Edge> — C<path>, C<from_port>, C<to_port>, C<arrow_dir>

=item * C<Graph::Easy> — C<ast>, C<ast_grid>, C<ast_cell_grid>

=back

C<as_ascii> is called exactly once per C<ast> invocation. Character-space
coordinates and rendered dimensions are captured by wrapping
C<Graph::Easy::_prepare_layout> at module load time.

=head1 COORDINATE SYSTEMS

Two coordinate systems coexist in the AST.

B<Cell-grid space>: each node occupies one or more layout cells. C<node.x>
and C<node.y> are cell-grid coordinates. C<node.bbox> is expressed in
cell-grid units. Edge path points carry C<x> and C<y> in cell-grid units.

B<Character space>: the actual rendered positions. C<node.char_x> and
C<node.char_y> are the character-space top-left corner of the node box.
C<node.char_width> and C<node.char_height> are the rendered dimensions.

Port C<char_x> and C<char_y> are on the node face (the border character row
or column), not the top-left of the adjacent edge cell. This gives correct,
distinct coordinates for both ends of short single-cell edges.

=head1 AST STRUCTURE

=head2 Top level

  {
    meta    => { introspect_version, graph_easy_version, generated_at, layout_algorithm },
    graph   => { is_directed, label, total_width, total_height, attrs },
    nodes   => [ ... ],
    edges   => [ ... ],
    groups  => [ ... ],
  }

The character grid and cell-grid are not part of the AST. Retrieve them with
C<ast_grid> and C<ast_cell_grid> after calling C<ast>.

On error, returns C<< { error => $message, meta => { introspect_version => $v } } >>.

=head2 Node entry

  {
    id          => 'A',
    label       => 'A',
    is_anon     => 0,
    is_isolated => 0,
    x           => 0,          # cell-grid
    y           => 0,          # cell-grid
    char_x      => 2,          # character space, top-left of box
    char_y      => 3,          # character space
    char_width  => 9,          # character space, rendered
    char_height => 3,          # character space, rendered
    width       => 5,          # intrinsic (pre-expansion) char width
    height      => 3,
    bbox        => { x1, y1, x2, y2 },   # cell-grid
    component   => 0,
    groups      => ['g1'],
    edges_in    => [0],
    edges_out   => [1],
    ports       => {
      left    => [ { edge_id, role, x, y, char_x, char_y, seq } ],
      right   => [...],
      top     => [...],
      bottom  => [...],
      unknown => [...],   # catch-all; empty in normal layouts
    },
    attrs       => { shape => 'rounded', ... },
  }

=head2 Edge entry

  {
    id               => 0,
    from             => 'A',
    to               => 'B',
    is_self_loop     => 0,
    is_bidirectional => 0,
    multiplicity     => 1,
    arrow_dir        => 'right',
    from_port        => { x, y, char_x, char_y },  # char coords on from-node face
    to_port          => { x, y, char_x, char_y },  # char coords on to-node face
    from_side        => 'right',
    to_side          => 'left',
    label            => undef,
    label_x          => undef,   # cell-grid
    label_y          => undef,
    label_char_x     => undef,   # character space
    label_char_y     => undef,
    path             => [ { x, y, char_x, char_y, char_x2, char_y2,
                             line_x1, line_y1, line_x2, line_y2,
                             type, type_code, is_label } ],
    attrs            => { style => 'dashed', ... },
  }

=head2 Group entry

  {
    id          => 'mygroup',
    label       => 'mygroup',
    nodes       => ['A', 'B'],
    bbox        => { x1, y1, x2, y2 },    # cell-grid
    char_x      => 0,                      # character space, top-left of border
    char_y      => 0,
    char_width  => 13,
    char_height => 8,
    attrs       => { ... },
  }

=head1 AUTHOR

Nadim Khemir <nadim.khemir@gmail.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
