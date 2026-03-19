# Architecture: Graph::Easy::Introspect

## Purpose

Graph::Easy::Introspect extracts a complete, serializable description of a
Graph::Easy layout into a plain Perl hashref called the AST. It captures
node positions and dimensions, edge paths, port connection points, group
boundaries, and attributes — all in a form that a downstream renderer can
consume directly without touching Graph::Easy internals.

## Design Philosophy

- The AST is a plain data structure. No objects, no methods, no circular
  references. It can be serialized to JSON without transformation.
- `as_ascii` is called exactly once per `ast` invocation. All derived data
  (grid, node sizes, edge paths, character coordinates) comes from that
  single rendering pass.
- Only attributes explicitly set on a node or edge are included in `attrs`.
  Default or inherited values are not extracted.
- Nodes and edges are sorted deterministically (by name/from/to) so that
  two ASTs built from semantically identical graphs produce identical output.
- Error handling wraps the rendering call in `eval`. On failure the returned
  hashref contains an `error` key rather than dying.

## Package Structure

The module populates three packages in a single file, plus a separate
renderer base class.

### Graph::Easy::Introspect

Pure helper functions, not methods. Called with full package path from the
other packages to avoid namespace pollution.

- `install_layout_wrapper()` — installs the `_prepare_layout` hook; idempotent
- `node_bbox($node)` — cell-grid bounding box as a four-element list
- `port_side($node, $port)` — classifies a port as left/right/top/bottom/unknown
- `cell_type_name($code)` — maps a numeric cell type code to a name (HOR, VER, N_E, ...)
- `extract_attrs($obj)` — explicitly set attributes from `$obj->{att}`
- `extract_graph_attrs($g)` — graph-level attributes from `$g->{att}{graph}`
- `compute_components($g)` — BFS to assign a component index to every node
- `sorted_nodes($g)` — nodes sorted by name
- `sorted_edges($g)` — edges sorted by from name then to name
- `group_char_bbox($g, $g_ast, $char_pos)` — character-space bbox of a group

### Graph::Easy::Edge

Instance methods monkey-patched onto every edge object.

- `path` — edge cells as `[[x,y], ...]`
- `from_port` — edge cell adjacent to the source node; undef for self-loops
- `to_port` — edge cell adjacent to the target node; undef for self-loops
- `arrow_dir` — decodes EDGE_END_* bits to right/left/up/down

### Graph::Easy

A single method monkey-patched onto the graph object.

- `ast` — orchestrates the full extraction pipeline and returns the AST hashref

### Graph::Easy::Introspect::Renderer

Base class for renderers that consume the AST. Each drawing method has a
default implementation that prints its name and arguments to STDERR. Real
renderers subclass this and override the methods they need.

See `doc/RENDERER.md` for the full method reference and subclassing guide.

## Data Flow

```
DOT source
    |
    v
Graph::Easy::Parser::Graphviz->from_text
    |
    v
Graph::Easy object  (nodes, edges, groups, attributes)
    |
    v
$g->ast
    |
    +-- install_layout_wrapper  (once, wraps _prepare_layout)
    |
    +-- as_ascii
    |       |
    |       +-- _prepare_layout  (wrapper fires here, captures char coords)
    |       |
    |       +-- renders to character grid
    |
    +-- sorted_nodes / sorted_edges
    |
    +-- compute_components  (BFS over edge adjacency)
    |
    +-- build nodes_ast  (id, label, cell coords, char coords, dims, attrs)
    |
    +-- build edges_ast  (path with char coords, ports, arrow_dir, label pos, attrs)
    |
    +-- build groups_ast  (membership, cell bbox, char bbox, attrs)
    |
    +-- finalize  (edges_in/out, degree, port sort+seq, isolated flag, group back-refs)
    |
    +-- build cell_grid  (cell-key -> type/name/char_x/char_y/render_w/render_h)
    |
    v
AST hashref  (version, meta, graph, nodes, edges, groups, grid, cell_grid)
```

## Coordinate Systems

Two coordinate systems coexist in the AST.

### Cell-grid space

Each node occupies one or more layout cells. `node.x` and `node.y` are
cell-grid coordinates. `node.bbox` is expressed in cell-grid units using
`cx`/`cy` cell spans. Edge path points carry `x` and `y` in cell-grid units.
Port coordinates are also in cell-grid units.

Cell-grid coordinates do not directly correspond to character positions when
groups are present: group border rows and columns shift node positions in
character space but not in cell-grid space.

### Character space

`node.char_x` and `node.char_y` are the character-space top-left corner of
the node box as it appears in the `grid` array. `node.char_width` and
`node.char_height` are the rendered character dimensions after group-induced
expansion and graph-label offset.

Every node, every edge path point, and every port carries both coordinate
systems. `char_x` and `char_y` are always correct for indexing into `grid`.

### How character coordinates are captured

Graph::Easy computes character positions inside `_prepare_layout`, which is
called from within `as_ascii`. The module wraps `_prepare_layout` at load
time. The wrapper fires on the first call with format `"ascii"`, reads the
`$cols` and `$rows` accumulation tables that `_prepare_layout` has just
finished computing, applies the `x_start`/`y_start` offset that `as_ascii`
adds for graph-level labels, and stores the resulting character positions on
the graph object for `ast` to collect.

This approach captures coordinates at exactly the right moment — after layout
expansion but before `as_ascii` restores the original `w`/`h` values.

## Cell Grid

`ast->{cell_grid}` is a hashref keyed by `"cell_x,cell_y"` strings. Each
entry describes what occupies that cell:

```
{
  type     => 'node' | 'edge' | 'group' | 'empty' | 'unknown',
  name     => $name_or_empty_string,
  char_x   => $char_space_x,
  char_y   => $char_space_y,
  render_w => $rendered_width_in_chars,
  render_h => $rendered_height_in_chars,
}
```

This allows O(1) lookup from cell coordinates to the element occupying that
cell without scanning the node or edge arrays.

## Attribute Extraction

Graph::Easy stores explicitly set attributes in `$obj->{att}` as a flat
hash of name => value pairs. `extract_attrs` copies this hash, skipping
undefined values, empty strings, and nested references (which are class-level
defaults, not instance attributes).

Graph-level attributes live under `$g->{att}{graph}` and are extracted
separately by `extract_graph_attrs`.

## Cell Type Encoding

Each edge cell has a `type` field that is a bitmask:

- bits 0–3: base type (HOR, VER, N_E, S_W, ...) — shape of the cell
- bits 4–7: end flags (EDGE_END_E/W/N/S) — arrowhead direction
- bits 8–11: start flags (EDGE_START_E/W/N/S) — where the edge originates
- bit 12: EDGE_LABEL_CELL — this cell carries the edge label
- bit 13: EDGE_SHORT_CELL — short filler cell

`arrow_dir` scans cells for a non-zero end flag and maps it to a direction
string. `label_x`/`label_y` and `label_char_x`/`label_char_y` are taken from
the first cell with bit 12 set.

## Port Detection

`from_port` and `to_port` scan all edge cells for those adjacent to the
respective node's cell-grid bounding box. When multiple cells qualify, the
one with the smallest Manhattan distance to the node's cell-grid center is
chosen.

Ports are classified by which face of the node they are adjacent to. Multiple
ports on the same face are sorted by their coordinate along that face (y for
left/right, x for top/bottom) and assigned a sequential `seq` integer.

## Group Handling

Groups are fetched via `$g->groups`. For each group, member node names are
collected and a cell-grid bounding box is computed as the union of member
node bboxes. The group's character-space bbox is derived from the group
border cells at `(bx1-1, by1-1)` and `(bx2+1, by2+1)` in the char_pos
table — the cells that Graph::Easy places around the group perimeter.

Group entries are stored as first-class entries in `ast->{groups}`, and each
member node carries a back-reference in its `groups` array.
