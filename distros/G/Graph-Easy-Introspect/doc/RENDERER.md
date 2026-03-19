# Renderer Guide: Graph::Easy::Introspect::Renderer

## Purpose

`Graph::Easy::Introspect::Renderer` is the base class for all renderers that
consume the AST produced by `Graph::Easy::Introspect`. It defines the drawing
interface and provides stub implementations of every method that print their
name and arguments to STDERR.

## Subclassing

```perl
package My::Renderer ;
use parent 'Graph::Easy::Introspect::Renderer' ;

sub draw_box
{
my ($self, $x, $y, $w, $h, $text) = @_ ;
# emit real output
}

# only override what you need
# unoverridden methods print to STDERR
```

## Method Reference

All coordinates are in character space. See `ARCHITECTURE.md` for the
definition of character space and how it relates to cell-grid space.

### Node Methods

#### draw_box($x, $y, $w, $h, $text)

Default shape. Called for nodes with shape `rect` or any unrecognised shape.

- `$x`, `$y` — character-space top-left corner of the box
- `$w`, `$h` — rendered width and height in character columns/rows
- `$text` — display label

#### draw_rounded_box($x, $y, $w, $h, $text)

Called for nodes with shape `rounded`. Same arguments as `draw_box`.

#### draw_diamond($x, $y, $w, $h, $text)

Called for nodes with shape `diamond`. Same arguments as `draw_box`.

#### draw_circle($x, $y, $w, $h, $text)

Called for nodes with shape `circle` or `ellipse`. Same arguments as `draw_box`.

#### draw_point($x, $y)

Called for nodes with shape `point`. No border, no label.

- `$x`, `$y` — character-space position

#### draw_invisible($x, $y, $w, $h)

Called for nodes with shape `invisible`. The node occupies layout space but
nothing is drawn.

### Edge Methods

#### draw_arrow($start_style, $end_style, \@points)

Called for every non-self-loop edge.

- `$start_style` — `'none'` or `'arrow'`; `'arrow'` only for bidirectional edges
- `$end_style` — `'none'` or `'arrow'`; `'arrow'` for all directed edges
- `\@points` — arrayref of hashrefs in path order from source to target

Each point hashref contains:

| field       | description                              |
|-------------|------------------------------------------|
| `char_x`    | character-space start column             |
| `char_y`    | character-space start row                |
| `char_x2`   | character-space end column               |
| `char_y2`   | character-space end row                  |
| `x`         | cell-grid column                         |
| `y`         | cell-grid row                            |
| `type`      | cell type name (HOR, VER, N_E, ...)      |
| `type_code` | raw numeric type (base bits only)        |
| `is_label`  | 1 if this cell carries the edge label    |

#### draw_self_loop($x, $y, $w, $h, $side)

Called instead of `draw_arrow` when `edge.is_self_loop` is true.

- `$x`, `$y`, `$w`, `$h` — character-space box of the source node
- `$side` — face the loop attaches to: `left`, `right`, `top`, `bottom`, or `unknown`

#### draw_edge_label($x, $y, $text)

Called after `draw_arrow` or `draw_self_loop` when the edge has a label.

- `$x`, `$y` — character-space position of the label cell
- `$text` — label string

### Group Method

#### draw_group($x, $y, $w, $h, $text)

Called once per group, before nodes are drawn.

- `$x`, `$y` — character-space top-left of the group border
- `$w`, `$h` — full character-space extent including border cells
- `$text` — group label

### Graph-Level Method

#### draw_graph_label($x, $y, $total_w, $text)

Called once when the graph carries a label, before any other drawing.

- `$x`, `$y` — character-space top-left of the label area (always 0, 0)
- `$total_w` — total character width of the rendered output; use for centering
- `$text` — label string

## Rendering Order

`graph_easy_render` follows this order, which ensures correct layering:

1. `draw_graph_label` — if the graph has a label
2. `draw_group` — for every group
3. Node methods — for every node
4. `draw_arrow` or `draw_self_loop` — for every edge
5. `draw_edge_label` — immediately after each edge that has a label

## Using graph_easy_render

```
graph_easy_render file.dot
```

The script instantiates the base renderer, builds the AST, and calls the
drawing methods in the correct order. To use a custom renderer, copy and
adapt the script, replacing the renderer class name.

## STDERR Output Format

The default implementations print tab-aligned columns for easy scanning:

```
draw_box         x=2   y=3   w=9   h=3   text=A
draw_box         x=18  y=3   w=5   h=3   text=B
draw_arrow       start=none   end=arrow   points=(13,3) (14,3) (15,3) (16,3) (17,3)
draw_group       x=0   y=0   w=13  h=8   text=Group 1
```
