## Name

HTML::D3 - A simple Perl module for generating charts using D3.js.

## Version

Version 0.24

## Synopsis

```perl
use HTML::D3;

my $chart = HTML::D3->new(
    width => 1024,
    height => 768,
    title => 'Sample Bar Chart'
);

my $data = [
    ['Category 1', 10],
    ['Category 2', 20],
    ['Category 3', 30]
];

my $html = $chart->render_bar_chart($data);
print $html;

$chart = HTML::D3->new(title => 'Sales Data');

$data = [
    ['Product A', 100],
    ['Product B', 150],
    ['Product C', 200]
];

$html = $chart->render_line_chart($data);
print $html;
```

## Description

HTML::D3 is a Perl module that provides functionality to create simple charts using D3.js.
The module generates HTML and JavaScript code to render the chart in a web browser.

## Methods

The `=head3 API SPECIFICATION` subsections use [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
schema syntax (`type => 'arrayref'` etc.) as a documentation convention.
The module is also used at runtime in `new()` to validate constructor
arguments; it is therefore a required runtime dependency.  The schemas describe
the parameter contract in machine-readable notation and can be plumbed into a
WAF or test generator if desired.

### New

```perl
my $chart = HTML::D3->new(%args);
```

Creates a new HTML::D3 object.
Accepts the following optional arguments:

- `width` - The width of the chart (default: 800).
- `height` - The height of the chart (default: 600).
- `title` - The title of the chart (default: 'Chart').
- `responsive` - If true, SVG elements are rendered with
`viewBox` and `width="100%" height="auto"` instead of fixed pixel
dimensions, so the chart scales fluidly with its container.
For snippet methods the per-call `opts => { responsive => 1 }`
takes precedence over this object-level setting (default: 0).

### Categorical\_Schemes

```perl
my $names = HTML::D3->categorical_schemes();
```

Returns an arrayref of the names of the categorical colour schemes this module
can draw with, sorted alphabetically: `category10`, `paired`, `set2`,
`set3` and `tableau10`.
These are the names the `scheme` and `color_scheme` options accept.

### Palette

```perl
my $colours = HTML::D3->palette('set2');
```

Returns an arrayref of the colours of one scheme - the same colours, in the same
order, that a chart drawn with `scheme => 'set2'` draws with.
A map, a legend or a static renderer can therefore colour the same data the way
the chart does, from Perl, without a browser:

```perl
my $scheme  = 'set2';
my $colours = HTML::D3->palette($scheme);
my $index   = 0;
for my $category (@categories) {
    printf "%s is %s\n", $category, HTML::D3->colour_at($scheme, $index++);
}
```

Dies with `Unknown scheme: <name>` for a name that is not in
`categorical_schemes()`, rather than quietly returning the default scheme's
colours, so that a misspelt scheme is found where it is asked for.
The arrayref returned is a copy: pushing onto it does not change the palette.

### Colour\_at

```perl
my $fill = HTML::D3->colour_at('tableau10', $index);
```

Returns the colour one scheme gives the `$index`th category, counting from
zero, cyclically: an index past the end of the palette wraps around to its
start, which is how `d3.scaleOrdinal` - what the snippets draw with - assigns
colours.
Colour 0 is the first colour of the scheme, the one `render_histogram_snippet`
uses as the bar fill when it is given a `scheme`.

The British spelling matches the `colour_by_series` option.
Dies with `Unknown scheme: <name>` for an unknown scheme, and with
`Colour index must be a non-negative integer` for an index that is not one.

### Render\_Bar\_Chart

```perl
my $html = $chart->render_bar_chart($data);
```

Generates HTML and JavaScript code to render a bar chart. Accepts the following arguments:

- `$data` - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.

#### Errors

- Throws `Data is not optional` when `$data` is `undef`.
- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => {
            type => 'arrayref',
            element_type => [ 'string', 'number' ]
    }
}

Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
non-arrayref dies.
```

##### Output

```
Str -- complete HTML5 document starting with C<< <!DOCTYPE html> >>;
       D3.js loaded from CDN; bar chart rendered with C<d3.scaleBand>.
```

### Render\_Animated\_Bar\_Chart

```perl
my $html = $chart->render_animated_bar_chart($data);
```

Generates HTML and JavaScript code to render a bar chart where each bar grows
upward from the baseline on page load.  Bars are staggered so they rise
one-after-another from left to right.
Accepts the following arguments:

- `$data` - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the complete HTML5 document.

#### Errors

- Throws `Data is not optional` when `$data` is `undef`.
- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
}

Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
non-arrayref dies.
```

##### Output

```
Str -- complete HTML5 document; each bar animates from height=0 upward
       using C<d3.transition()> with a staggered per-bar delay.
```

### Render\_Line\_Chart

```perl
my $html = $chart->render_line_chart($data);
```

Generates HTML and JavaScript code to render a line chart. Accepts the following arguments:

- `$data` - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.

#### Errors

- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
}

Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
non-arrayref dies.
```

##### Output

```
Str -- complete HTML5 document; line chart with C<d3.scalePoint> and C<d3.line()>.
```

### Render\_Animated\_Line\_Chart

```perl
my $html = $chart->render_animated_line_chart($data);
```

Generates HTML and JavaScript code to render a line chart where the line
draws itself from left to right on page load, followed by each data-point
circle fading in once the line is complete.
Accepts the following arguments:

- `$data` - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the complete HTML5 document.

#### Errors

- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
}

Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
non-arrayref dies.
```

##### Output

```
Str -- complete HTML5 document; the line path animates via
       C<stroke-dashoffset> with C<d3.easeLinear>; data-point circles
       fade in with C<opacity> after the line transition completes.
```

### Render\_Pie\_Chart

```perl
my $html = $chart->render_pie_chart($data);
my $html = $chart->render_pie_chart($data, { separator => ':' });
```

Generates HTML and JavaScript code to render a pie chart.
Each slice is coloured with the ten hex values of `d3.schemeCategory10`,
inlined into the page rather than read from D3's own palette (see ["palette"](#palette));
percentage labels appear inside each slice and a colour legend is shown to the
right of the pie.
Accepts the following arguments:

- `$data` - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).
- `%opts` - Optional hashref of options.
    - `separator` (string, default `'/'`) - Character shown between the
    label and value in the SVG legend.

Returns a string containing the complete HTML5 document.

#### Errors

- Throws `Data is not optional` when `$data` is `undef`.
- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => {
            type => 'arrayref',
            element_type => [ 'string', 'number' ]
    },
    opts => { type => 'hashref', optional => 1, default => {} },
}

Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
non-arrayref dies.
Recognised C<opts> key: C<separator> (string, default C<'/'>)
- character shown between label and value in the SVG legend.
```

##### Output

```
Str -- complete HTML5 document; pie rendered with C<d3.pie()> and
       C<d3.arc()>; slices coloured with category10's hex values,
       inlined; percentage label inside each slice; legend to the right.
```

### Render\_Animated\_Pie\_Chart

```perl
my $html = $chart->render_animated_pie_chart($data);
my $html = $chart->render_animated_pie_chart($data, { separator => ':' });
```

Generates HTML and JavaScript code to render an animated pie chart where each
slice fans out from zero angle on page load using `attrTween` and
`d3.interpolate`.  Percentage labels fade in once all slices are drawn.
Accepts the following arguments:

- `$data` - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).
- `%opts` - Optional hashref of options.
    - `separator` (string, default `'/'`) - Character shown between the
    label and value in the SVG legend.

Returns a string containing the complete HTML5 document.

#### Errors

- Throws `Data is not optional` when `$data` is `undef`.
- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => {
            type => 'arrayref',
            element_type => [ 'string', 'number' ]
    },
    opts => { type => 'hashref', optional => 1, default => {} },
}

Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
non-arrayref dies.
Recognised C<opts> key: C<separator> (string, default C<'/'>)
- character shown between label and value in the SVG legend.
```

##### Output

```
Str -- complete HTML5 document; slices animate via C<attrTween> with
       C<d3.interpolate> (1000 ms); percentage labels fade in afterwards.
```

### Render\_Pie\_Chart\_Snippet

```perl
my $fragment = $chart->render_pie_chart_snippet(\@slices);
my $fragment = $chart->render_pie_chart_snippet(\@slices, \%opts);
# $fragment->{svg_id} - always 'pie_chart'
# $fragment->{html}   - embeddable fragment; caller must load D3 v7
```

Generates an embeddable pie or donut chart fragment for use in existing HTML
layouts.  Returns `{ svg_id => 'pie_chart', html => Str }`.  The
caller is responsible for loading D3 v7 before embedding the fragment.

#### Data Format

Each element of `\@slices` is `[$label, $value]` or `[$label, $value, \%extra]`.
Negative values are silently converted to their absolute value.  Zero-value
slices are silently omitted.  `\%extra` key/value pairs are shown as
additional rows in the hover tooltip.

#### Options (`\%Opts`)

- `animated` (bool, default 0) - fan slices in from arc-length 0 on
first render using `attrTween` / `d3.easeBackOut` (800 ms, staggered).
Respects `prefers-reduced-motion`.
- `donut` (bool, default 0) - render as a donut chart (inner radius
38% of outer radius); the total sum appears in the centre hole.
- `sort_slices` (string, default `'none'`) - `'value'` for
largest-first, `'label'` for alphabetical, `'none'` for input order.
- `max_slices` (int, default 0) - when > 0, only the top N-1
slices are shown individually; the rest are collapsed into an `"Other"` slice.
- `legend` (bool, default 1) - render an HTML legend panel beside the chart.
- `color_scheme` (string, default `'tableau10'`) - D3 categorical
colour scheme.  Supported: `tableau10`, `category10`, `set2`, `set3`,
`paired` - the names `categorical_schemes()` returns, whose colours `palette()`
makes available to Perl.
- `separator` (string, default `'/'`) - Character shown between the
label and value in each legend entry (e.g. `'/'` produces
`Label / 12.34 (42.0%)`, `':'` produces `Label : 12.34 (42.0%)`).

#### Errors

- Throws `Data must be an array of arrays` when `\@slices` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
    opts => { type => 'hashref', optional => 1, default => {} },
}

Each element of C<$data> is C<[ Str, Num ]> or C<[ Str, Num, HashRef ]>;
passing C<undef> or a non-arrayref dies.
Recognised C<opts> keys: C<animated> (boolean, default C<0>),
C<donut> (boolean, default C<0>), C<sort_slices> (string: C<'value'>,
C<'label'>, or C<'none'>; default C<'none'>), C<max_slices> (integer,
default C<0>), C<legend> (boolean, default C<1>),
C<color_scheme> (string, default C<'tableau10'>),
C<separator> (string, default C<'/'> - shown between label and value in
legend entries).
```

##### Output

```
HashRef -- C<{ svg_id =E<gt> 'pie_chart', html =E<gt> Str }>;
           embeddable fragment; no DOCTYPE, no page shell, no D3 CDN tag.
```

### Render\_Heatmap\_Snippet

```perl
my $fragment = $chart->render_heatmap_snippet(\@triples);
my $fragment = $chart->render_heatmap_snippet(\@triples, \%opts);
# $fragment->{svg_id} - always 'heatmap'
# $fragment->{html}   - embeddable fragment; caller must load D3 v7
```

Generates an embeddable grid heatmap for use in existing HTML layouts.
Each cell sits at the intersection of an X-axis label and a Y-axis label;
its colour encodes the cell's numeric value using a sequential D3 colour
scale.  Returns `{ svg_id => 'heatmap', html => Str }`.  The
caller is responsible for loading D3 v7 before embedding the fragment.

#### Data Format

Each element of `\@triples` is `[$x_label, $y_label, $value]`.
`$value` must be numeric or `undef` (`undef` rows are silently
skipped).  Zero is a valid value and maps to the lightest cell colour.
The caller is responsible for any aggregation: if multiple triples share
the same (x\_label, y\_label) pair, the last one wins.

#### Options (`\%Opts`)

- `color_scheme` (string, default `'YlOrRd'`) - D3 sequential
colour scheme.  Supported: `YlOrRd`, `Blues`, `Greens`, `Purples`,
`RdPu`, `YlGnBu`.
- `x_label` (string, default `''`) - Axis title below the X axis.
The value is JavaScript-escaped (backslash, double-quote, newline, carriage
return) before being embedded in the page; other characters are taken
literally.
- `y_label` (string, default `''`) - Axis title left of the Y axis.
Same JS-escaping as `x_label` applies.
- `val_label` (string, default `'Value'`) - Tooltip value label.
Same JS-escaping as `x_label` applies.
- `show_values` (bool, default 0) - Print value inside each cell.
Auto-suppressed when any cell is narrower than 28 px.
- `cell_padding` (int 0-8, default 2) - Gap in pixels between cells.
- `legend` (bool, default 1) - Render a colour-scale legend bar.
- `animated` (bool, default 0) - Fade cells in on first load.
Respects `prefers-reduced-motion`.

#### Errors

- Dies with `Data must be an array of arrays` when `\@triples`
is not an ARRAY reference.
- Dies with `Each data point must be an array reference` when a
triple element is not an arrayref.
- Dies with `Each data point must have at least 3 elements` when
a triple has fewer than 3 elements.
- Dies with `Value must be numeric` when `$value` is defined but
not numeric.
- Dies with `Unknown color_scheme: <name>` for an
unsupported `color_scheme` value.
- Dies with `cell_padding must be between 0 and 8` when
`cell_padding` is outside the valid range.

#### Side Effects

Appends a tooltip `div` to the page when the fragment is rendered in
the browser.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
    opts => { type => 'hashref', optional => 1, default => {} },
}

Each element of C<$data> is C<[ Str, Str, Num|undef ]>.
Recognised C<opts> keys: C<color_scheme> (string, default C<'YlOrRd'>),
C<x_label> (string, default C<''>), C<y_label> (string, default C<''>),
C<val_label> (string, default C<'Value'>), C<show_values> (boolean,
default C<0>), C<cell_padding> (integer 0-8, default C<2>),
C<legend> (boolean, default C<1>), C<animated> (boolean, default C<0>).
```

##### Output

```
HashRef -- C<{ svg_id =E<gt> 'heatmap', html =E<gt> Str }>;
           embeddable fragment; no DOCTYPE, no page shell, no D3 CDN tag.
```

### Render\_Bar\_Chart\_Snippet

```perl
my $result = $chart->render_bar_chart_snippet(\@bars);
my $result = $chart->render_bar_chart_snippet(\@bars, \%opts);
```

Generates an embeddable D3.js v7 bar chart fragment.  Returns a hashref
`{ svg_id => 'bar_chart', html => $str }` where `$str` is a
self-contained HTML fragment (no page shell, no D3 CDN tag) that the caller
embeds directly after loading D3.js.  `$str` is a Perl character string
with the UTF-8 flag set (or pure ASCII when all labels are ASCII).

Each element of `\@bars` is an array reference:

```
[ $label, $value ]
[ $label, $value, \%extra ]
```

`$label` is the category name (string); `$value` is a non-negative number
(negative values are silently converted to their absolute value); the optional
`\%extra` hashref supplies additional key/value pairs shown in the hover
tooltip.  Data points with an undefined `$value` are silently skipped.

#### Options (`\%Opts`)

- `orientation` (string, default `'vertical'`)

    `'vertical'` draws bars rising from a horizontal category axis.
    `'horizontal'` draws bars extending from a vertical category axis.

- `sort_bars` (string, default `'none'`)

    Sort order applied before rendering: `'value'` sorts descending by bar
    height, `'label'` sorts ascending alphabetically, `'none'` preserves the
    input order.

- `max_bars` (integer, default `0`)

    When non-zero, only the first `max_bars` entries (after any sort) are
    rendered; the remaining entries are collapsed into a single `Other` bar
    whose value equals their sum.  Zero means no limit.

- `color` (string, default `'steelblue'`)

    Either a CSS colour value (e.g. `'steelblue'`, `'#4e79a7'`) applied to all
    bars, or the special token `'categorical'`, which colours each bar
    distinctively using D3's Tableau-10 palette.

- `show_values` (bool, default `0`)

    When true, the numeric value of each bar is printed above vertical bars or
    to the right of horizontal bars.

- `animated` (bool, default `0`)

    When true, bars grow from the baseline on page load: vertical bars rise from
    the bottom; horizontal bars extend from the left.  An 800 ms D3 transition
    with a per-bar stagger up to 100 ms is used.  The animation is suppressed
    when `prefers-reduced-motion` is set in the viewer's OS.

- `value_label` (string, default `'Value'`)

    Label shown in the hover tooltip before the numeric value.  The value is
    JavaScript-escaped before being embedded in the page.

- `x_label` (string, default `''`)

    When non-empty, a text label is rendered below the bottom axis.  The value
    is JavaScript-escaped before being embedded in the page.

#### Errors

- Throws `Data must be an array of arrays` when `$data` is not an
ARRAY reference.
- Throws `Each data point must be an array reference` when an element
is not an array reference.
- Throws `Each data point must have at least 2 elements` when an
element has fewer than 2 items.
- Throws `Value must be numeric` when a `$value` is not a number.
- Throws `orientation must be 'vertical' or 'horizontal'` on an
invalid orientation value.
- Throws `sort_bars must be 'value', 'label', or 'none'` on an
invalid sort\_bars value.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
    opts => { type => 'hashref', optional => 1 },
    orientation => { type => 'string', memberof => [ 'vertical', 'horizontal' ], optional => 1 },
    sort_bars => { type => 'string', memberof => [ 'value', 'label', 'none' ], optional => 1 }
}

Each element of C<$data>: C<[ Str, Num ]> or C<[ Str, Num, HashRef ]>;
undef C<$value> silently skipped; negative C<$value> becomes positive.
```

##### Output

```perl
HashRef -- { svg_id => 'bar_chart', html => Str }
html is a Perl character string (UTF-8 flag set, or pure ASCII).
```

### Render\_Line\_Chart\_With\_Tooltips

```
$html = $chart->render_line_chart_with_tooltips($data);
```

Generates HTML and JavaScript code to render a line chart with mouseover tooltips.
Accepts the following arguments:

- `$data` - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.
The JavaScript tooltip strings use `<\/b>` (with a backslash) rather than
`</b>` to satisfy html-tidy's requirement that `</` followed by a
letter not appear literally inside `<script>` blocks.

#### Errors

- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
}

Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
non-arrayref dies.
```

##### Output

```perl
Str -- complete HTML5 document; mouseover tooltip reveals label and value.
       Tooltip strings use C<< <\/b> >> not C<< </b> >>.
```

### Render\_Line\_Chart\_Snippet

```perl
my $fragment = $chart->render_line_chart_snippet($data);
my $fragment = $chart->render_line_chart_snippet($data, \%opts);
# $fragment->{svg_id} - the id attribute of the <svg> element
# $fragment->{html}   - embeddable HTML fragment (style + svg + script)
```

Generates an embeddable HTML fragment for a line chart with mouseover tooltips.
Unlike `render_line_chart_with_tooltips`, this method returns a fragment with
no `<!DOCTYPE`>, `<html`>, `<head`>, or `<body`> wrapper, suitable for
splicing directly into a Mojolicious TT (or any other) layout.

The caller is responsible for loading D3 in the page `<head`>, e.g.:

```
<script src="https://d3js.org/d3.v7.min.js"></script>
```

#### Arguments

- `$data` - An array reference of data points. Each point is an array
reference with two required elements - the label (string) and the value
(numeric) - and an optional third element: a hash reference of extra key/value
pairs to display in the tooltip after the label and value rows.

    ```
    [$x, $y]          # basic point
    [$x, $y, \%row]   # point with extra tooltip data
    ```

- `\%opts` - Optional hash reference of rendering options:
    - `id` (string, default `'chart'`) - Override the `id` attribute of
    the `<svg`> element.  Use this when embedding multiple charts on the same page.
    - `responsive` (boolean, default `0`) - If true, emit
    `viewBox="0 0 W H" width="100%" height="auto"` instead of fixed pixel
    dimensions, so the chart scales with its container.  Falls back to
    `$self->{responsive}` when not set per call.

#### Return Value

A hash reference with:

- `svg_id` - The `id` attribute used on the `<svg`> element.
- `html` - The embeddable fragment string (Perl character string).

#### Errors

- Dies with `'Data must be an array of arrays'` when `$data` is not an
ARRAY reference.

#### Side Effects

None.  The method is read-only.

#### Api Specification

```perl
{
    data => { type => 'arrayref' },
    opts => {
        type     => 'hashref',
        optional => 1,
        keys     => {
            id         => { type => 'string',  optional => 1 },
            responsive => { type => 'boolean', optional => 1 },
        },
    },
}
```

### Render\_Zoomable\_Line\_Chart\_Snippet

```perl
my $fragment = $chart->render_zoomable_line_chart_snippet($data);
my $fragment = $chart->render_zoomable_line_chart_snippet($data, { animated => 1 });
# $fragment->{svg_id} - the id attribute of the <svg> element
# $fragment->{html}   - embeddable HTML fragment (style + button + svg + script)
```

Like `render_line_chart_snippet`, but adds brush-to-zoom: the user can drag
across a range of the x-axis to zoom into that region. A _Reset zoom_ button
(hidden until a zoom is active) returns the chart to its original extent.
Subsequent brushes on the zoomed view zoom in further; Reset always returns to
the full dataset.

The caller is responsible for loading D3 in the page `<head`>.

Accepts the same arguments as `render_line_chart_snippet`: an array reference
of data points, each `[$x, $y]` or `[$x, $y, \%extra]`, plus an optional
second argument `$opts` (hashref).

#### Options

- `animated` (boolean, default `0`) - when true, the initial page load
animates the line drawing left-to-right via the `stroke-dashoffset` technique
(1200 ms, `d3.easeLinear`), then fades in data-point circles after the line
finishes (300 ms after a 1200 ms delay).  Respects
`prefers-reduced-motion`: when the user has requested reduced motion the line
is drawn immediately at full opacity.  Subsequent zoom and reset redraws are
never animated regardless of this flag.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
    opts => { type => 'hashref', optional => 1, default => {} },
}

Each element of C<$data> is C<[ Str, Num ]> or C<[ Str, Num, HashRef ]>;
passing C<undef> or a non-arrayref dies.
Recognised C<opts> key: C<animated> (boolean, default C<0>).
```

##### Output

```
HashRef -- C<{ svg_id =E<gt> 'chart', html =E<gt> Str }>;
           embeddable fragment; no DOCTYPE, no page shell, no D3 CDN tag.
```

#### Errors

Dies with _Data must be an array of arrays_ if `$data` is not an arrayref.

### Render\_Multi\_Series\_Line\_Chart\_With\_Tooltips

```
$html = $chart->render_multi_series_line_chart_with_tooltips($data);
```

Generates HTML and JavaScript code to render a chart of many lines with mouseover tooltips.

Accepts the following arguments:

- `$data` - An array reference of series hashes. Each element is a hashref
with a `name` key (string) and a `data` key (array reference of `{label, value}`
hashrefs).

    ```perl
    [
        { name => 'Series A', data => [{ label => 'Jan', value => 100 }, ...] },
        ...
    ]
    ```

Returns a string containing the HTML and JavaScript code for the chart.
Tooltip strings use `<\/b>` rather than `</b>` for html-tidy compliance.

#### Errors

- Throws `Data must be an array of hashes` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
}

Each element of C<$data> is a hashref with keys C<name> (string) and
C<data> (arrayref of hashrefs with C<label> and C<value> keys);
passing C<undef> or a non-arrayref dies.
```

##### Output

```
Str -- complete HTML5 document; one coloured line per series with mouseover tooltips.
```

### Render\_Multi\_Series\_Line\_Chart\_With\_Animated\_Tooltips

```
$html = $chart->render_multi_series_line_chart_with_animated_tooltips($data);
```

Generates HTML and JavaScript code to render a chart of many lines with animated mouseover tooltips.

Accepts the following arguments:

- `$data` - Same format as `render_multi_series_line_chart_with_tooltips`:
an array reference of `{ name, data }` series hashes.

Returns a string containing the complete HTML5 document.
The tooltip appears with a CSS `translateY` slide-in animation.
Tooltip strings use `<\/b>` for html-tidy compliance.

#### Errors

- Throws `Data must be an array of hashes` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
}

Each element of C<$data> is a hashref with keys C<name> (string) and
C<data> (arrayref of hashrefs with C<label> and C<value> keys);
passing C<undef> or a non-arrayref dies.
```

##### Output

```
Str -- complete HTML5 document; animated tooltip uses CSS translateY transition.
```

### Render\_Multi\_Series\_Line\_Chart\_With\_Legends

```
$html = $chart->render_multi_series_line_chart_with_legends($data);
```

Generates HTML and JavaScript code to render a chart of many lines with a static
colour legend. Each series gets a labelled colour swatch in the legend area.

Accepts the following arguments:

- `$data` - Same format as `render_multi_series_line_chart_with_tooltips`:
an array reference of `{ name, data }` series hashes.

Returns a string containing the complete HTML5 document. The stylesheet defines
a `.legend` CSS class used by the D3-generated legend elements.

#### Errors

- Throws `Data must be an array of hashes` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
}

Each element of C<$data> is a hashref with keys C<name> (string) and
C<data> (arrayref of hashrefs with C<label> and C<value> keys);
passing C<undef> or a non-arrayref dies.
```

##### Output

```
Str -- complete HTML5 document; static colour legend rendered as SVG C<g> elements
       with the C<.legend> CSS class applied via D3 C<.attr("class", "legend")>.
```

### Render\_Multi\_Series\_Line\_Chart\_With\_Interactive\_Legends

```
$html = $chart->render_multi_series_line_chart_with_interactive_legends($data);
```

Generates HTML and JavaScript code to render a chart of many lines with interactive legends to filter, highlight or modify elements based on legend selections.

Accepts the following arguments:

- `$data` - Same format as `render_multi_series_line_chart_with_tooltips`:
an array reference of `{ name, data }` series hashes.

Returns a string containing the complete HTML5 document. Clicking a legend entry
toggles that series' opacity using an `isVisible` boolean flag in the D3 click
handler (opacity is set to `isVisible ? 0 : 1` on each click).

#### Errors

- Throws `Data must be an array of hashes` when `$data` is not an ARRAY reference.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
}

Each element of C<$data> is a hashref with keys C<name> (string) and
C<data> (arrayref of hashrefs with C<label> and C<value> keys);
passing C<undef> or a non-arrayref dies.
```

##### Output

```
Str -- complete HTML5 document; legend clicks toggle series visibility.
       The C<isVisible> JS variable tracks current visibility state.
       Opacity toggled by C<isVisible ? 0 : 1>.
```

### Render\_Multi\_Series\_Line\_Chart\_Snippet

```perl
my $fragment = $chart->render_multi_series_line_chart_snippet(\@series);
my $fragment = $chart->render_multi_series_line_chart_snippet(\@series, \%opts);
# $fragment->{svg_id} - the id attribute of the <svg> element
# $fragment->{html}   - embeddable HTML fragment (style + svg + script)
```

Generates an embeddable multi-series line chart fragment.  Unlike
`render_multi_series_line_chart_with_interactive_legends`, this method returns
a bare fragment with no `<html>`, `<head>`, or `<body>` wrapper;
D3.js must be loaded by the host page.

#### Arguments

- `\@series` - An array reference of series.  Each series is a hash
reference with a `name` (string) and a `data` array reference of
`{ label => Str, value => Num }` points:

    ```perl
    [
        { name => 'North', data => [ { label => 'Jan', value => 12 }, ... ] },
        { name => 'South', data => [ { label => 'Jan', value =>  8 }, ... ] },
    ]
    ```

    Series need not share labels: the X domain is the union of every series' labels,
    in first-seen order.  One line and one set of dots is drawn per series, and a
    clickable legend toggles each series on and off.

- `\%opts` - Optional hash reference:
    - `scheme` (string, default `'tableau10'`) - D3 categorical colour
    scheme (for example `'category10'`, `'set2'`, `'set3'`, `'paired'`).
    `categorical_schemes()` lists the names, and `palette()` hands a Perl caller
    the colours of one.
    - `x_label` (string, default `''`) - Label shown below the X axis.
    - `y_label` (string, default `''`) - Label shown beside the Y axis.
    - `animated` (boolean, default 0) - If true each line draws itself left
    to right by animating its stroke dash offset.  Respects
    `prefers-reduced-motion`.
    - `responsive` (boolean, optional) - SVG responsive sizing override.
    - `id` (string, default `'chart'`) - `id` of the `<svg`> element.

Returns `{ svg_id => 'chart', html => Str }`.

#### Errors

- Throws `Data must be an array of series` when `\@series` is not an
ARRAY reference.
- Throws `Each series must be a hashref with name and data` when a
series is not a hashref, has no `name`, or has a `data` that is not an ARRAY
reference.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
    opts => {
        type     => 'hashref',
        optional => 1,
        keys     => {
            scheme     => { type => 'string',  optional => 1, default => 'tableau10' },
            x_label    => { type => 'string',  optional => 1, default => '' },
            y_label    => { type => 'string',  optional => 1, default => '' },
            animated   => { type => 'boolean', optional => 1, default => 0 },
            responsive => { type => 'boolean', optional => 1 },
            id         => { type => 'string',  optional => 1, default => 'chart' },
        },
    },
}
```

##### Output

```perl
HashRef -- { svg_id => 'chart', html => Str }
```

### Render\_Scatter\_Chart\_Snippet

```perl
my $fragment = $chart->render_scatter_chart_snippet($data);
my $fragment = $chart->render_scatter_chart_snippet($data, \%opts);
# $fragment->{svg_id} - the id attribute of the <svg> element
# $fragment->{html}   - embeddable HTML fragment (style + svg + script)
```

Generates an embeddable HTML fragment for a scatter plot with mouseover
tooltips.  Returns a fragment with no `<!DOCTYPE`>, `<html`>, `<head`>, or
`<body`> wrapper; the caller is responsible for loading D3 in the page.

#### Arguments

- `$data` - An array reference of data points.  Each point is an array
reference with two required numeric elements (x, y), an optional third hash
reference of extra key/value pairs shown as extra tooltip rows, and an optional
fourth hash reference carrying the `series` (colour group) and `size` (bubble
radius) dimensions:

    ```perl
    [$x, $y]          # basic point
    [$x, $y, \%row]   # point with extra tooltip data
    [$x, $y, \%row, { series => 'North', size => 42 }]   # colour and size
    ```

- `\%opts` - Optional hash reference:
    - `id` (string, default `'scatter_chart'`) - `id` of the `<svg`> element.
    - `color` (CSS colour or `'categorical'`, default `'steelblue'`) -
    Fill colour for the data points.  `'categorical'` uses the Tableau-10 palette.
    - `x_label` (string, default `''`) - Label for the X axis.
    - `y_label` (string, default `''`) - Label for the Y axis.
    - `value_label` (string, default `'Value'`) - Prefix for the tooltip value row.
    - `colour_by_series` (boolean, default 0) - Colour each point by its
    `series` value instead of by point index, and draw a legend listing the series
    to the right of the plot.  Ignored for points with no `series` value.
    - `scheme` (string, default `'tableau10'`) - D3 categorical colour
    scheme used when `colour_by_series` is set, for example `'category10'`,
    `'set2'`, `'set3'`, or `'paired'`.
    `categorical_schemes()` lists the names, and `palette()` hands a Perl caller
    the colours of one.
    - `series_col` (string, default `'Series'`) - Row label for the series
    value in the tooltip.
    - `size_col` (string, default `'Size'`) - Row label for the size value
    in the tooltip.
    - `radius_range` (arrayref of two numbers, default `[3, 15]`) - Pixel
    radii mapped from the smallest and largest observed `size` value.  The mapping
    is by area (`d3.scaleSqrt`), so a point twice as large is drawn with four
    times the area.  A point with no `size` value is drawn at the lower radius.
    - `animated` (boolean, default 0) - If true, circles fade in from
    opacity 0 on page load (400 ms).  Respects `prefers-reduced-motion`.
    - `responsive` (boolean, default 0) - See `render_bar_chart_snippet`.

#### Return Value

A hash reference with `svg_id` (string) and `html` (Perl character string).

#### Errors

- Dies with `'Data must be an array of arrays'` when `$data` is not an ARRAY ref.
- Dies with `'Each data point must be an array reference'` when an element is not an ARRAY ref.
- Dies with `'Each data point must have at least 2 elements'` when a point has fewer than 2 items.
- Dies with `'X value must be numeric'` when the x element is not a number.
- Dies with `'Y value must be numeric'` when the y element is not a number.

#### Api Specification

```perl
{
    data => { type => 'arrayref' },
    opts => {
        type     => 'hashref',
        optional => 1,
        keys     => {
            id          => { type => 'string',  optional => 1 },
            color       => { type => 'string',  optional => 1, default => 'steelblue' },
            x_label     => { type => 'string',  optional => 1, default => '' },
            y_label     => { type => 'string',  optional => 1, default => '' },
            value_label => { type => 'string',  optional => 1, default => 'Value' },
            colour_by_series => { type => 'boolean', optional => 1, default => 0 },
            scheme      => { type => 'string',  optional => 1, default => 'tableau10' },
            series_col  => { type => 'string',  optional => 1, default => '' },
            size_col    => { type => 'string',  optional => 1, default => '' },
            radius_range => { type => 'arrayref', optional => 1, default => [3, 15] },
            animated    => { type => 'boolean', optional => 1, default => 0 },
            responsive  => { type => 'boolean', optional => 1, default => 0 },
        },
    },
}
```

### Render\_Table\_Snippet

```perl
my $fragment = $chart->render_table_snippet($data);
my $fragment = $chart->render_table_snippet($data, \%opts);
# $fragment->{table_id} - the id attribute of the <table> element
# $fragment->{html}     - embeddable HTML fragment (style + table + script)
```

Generates an embeddable HTML fragment for a sortable, filterable data table.
Returns a fragment with no page-shell wrapper; the caller loads D3 if needed.

#### Arguments

- `$data` - An array reference of row array references.  The first row
is treated as the header row.  Every subsequent row must have the same number
of columns as the header.

    ```
    [ ['Name', 'Value', 'Category'],   # header
      ['Alpha',   300,  'A'],
      ['Beta',    150,  'B'],
    ]
    ```

- `\%opts` - Optional hash reference:
    - `id` (string, default `'data_table'`) - `id` of the `<table`> element.
    - `sortable` (boolean, default 1) - If true, clicking a column header
    sorts the table by that column (toggle ascending/descending).
    - `caption` (string, default `''`) - Optional `<caption`> element text.

#### Return Value

A hash reference with `table_id` (string) and `html` (Perl character string).
Note: returns `table_id`, not `svg_id`, because this method renders an HTML
table rather than an SVG chart.

#### Errors

- Dies with `'Data must be an array of arrays'` when `$data` is not an ARRAY ref.
- Dies with `'Data must have at least one row (header row)'` when `$data` is empty.
- Dies with `'Each row must be an array reference'` when a row is not an ARRAY ref.

#### Api Specification

```perl
{
    data => { type => 'arrayref' },
    opts => {
        type     => 'hashref',
        optional => 1,
        keys     => {
            id       => { type => 'string',  optional => 1, default => 'data_table' },
            sortable => { type => 'boolean', optional => 1, default => 1 },
            caption  => { type => 'string',  optional => 1, default => '' },
        },
    },
}
```

### Render\_Stacked\_Bar\_Snippet

```perl
my $result = $chart->render_stacked_bar_snippet(\@rows, \%opts);
```

Generates an embeddable stacked bar chart (no page shell, no CDN tag).

Each element of `\@rows` is a hashref with three keys named by `opts`:
`cat_col` (the X-axis grouping), `seg_col` (the stacking segment), and
`val_col` (the numeric measure).  Multiple rows sharing the same
cat+seg combination are summed.

Accepted `\%opts` keys:

- `cat_col` (string, default `'cat'`) - row key for the X-axis category.
- `seg_col` (string, default `'seg'`) - row key for the stacking segment.
- `val_col` (string, default `'val'`) - row key for the numeric value.
- `orient` (string `'v'` or `'h'`, default `'v'`) - bar orientation.
- `scheme` (string, default `'tableau10'`) - D3 categorical colour scheme.
Supported: `tableau10`, `category10`, `set2`, `set3`, `paired` - the names
`categorical_schemes()` returns, whose colours `palette()` makes available to
Perl.
- `x_label` (string, optional) - axis label shown below the category axis.
- `sort` (string, optional) - sort categories: `'value'` (desc total)
or `'label'` (alpha).
- `id` (string, optional) - override the default `svg_id` value.
- `responsive` (boolean, optional) - SVG responsive sizing override.

Returns `{ svg_id => 'stacked_bar', html => Str }`.

#### Errors

- Throws `Data must be an array of hashes` when `$data` is not an ARRAY reference.
- Throws `Each data point must be a hash reference` when a row is not a hashref.
- Throws `Value must be numeric` when a value field is not a number.
- Throws `orient must be 'v' or 'h'` for an invalid `orient` value.
- Throws `sort must be 'value' or 'label'` for an invalid `sort` value.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
    opts => {
        type     => 'hashref',
        optional => 1,
        keys     => {
            cat_col  => { type => 'string',  optional => 1, default => 'cat' },
            seg_col  => { type => 'string',  optional => 1, default => 'seg' },
            val_col  => { type => 'string',  optional => 1, default => 'val' },
            orient   => { type => 'string',  optional => 1, default => 'v' },
            scheme   => { type => 'string',  optional => 1, default => 'tableau10' },
            x_label  => { type => 'string',  optional => 1, default => '' },
            sort     => { type => 'string',  optional => 1 },
            id       => { type => 'string',  optional => 1, default => 'stacked_bar' },
            responsive => { type => 'boolean', optional => 1 },
        },
    },
}
```

##### Output

```perl
HashRef -- { svg_id => Str, html => Str }
```

### Render\_Combo\_Snippet

```perl
my $result = $chart->render_combo_snippet(\@rows, \%opts);
```

Generates an embeddable combo chart: bars for one measure on the left Y
axis, a line for another measure on the right Y axis, sharing the same
X (category) axis.

Each element of `\@rows` is a hashref with at least three keys named by
`opts`: `x_col` (X-axis label), `bar_col` (bar measure), and
`line_col` (line measure).

Accepted `\%opts` keys:

- `x_col` (string, default `'x'`) - row key for the X-axis label.
- `bar_col` (string, default `'bar_val'`) - row key for the bar measure.
- `line_col` (string, default `'line_val'`) - row key for the line measure.
- `bar_label` (string, default `'Bar'`) - legend/axis label for bars.
- `line_label` (string, default `'Line'`) - legend/axis label for line.
- `bar_color` (string, optional CSS colour, default `'steelblue'`) - bar fill.
- `line_color` (string, optional CSS colour, default `'#e15759'`) - line stroke.
- `id` (string, optional) - override the default `svg_id` value.
- `responsive` (boolean, optional) - SVG responsive sizing override.

Returns `{ svg_id => 'combo_chart', html => Str }`.

#### Errors

- Throws `Data must be an array of hashes` when `$data` is not an ARRAY reference.
- Throws `Each data point must be a hash reference` when a row is not a hashref.
- Throws `Bar value must be numeric` when a bar value field is not a number.
- Throws `Line value must be numeric` when a line value field is not a number.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
    opts => {
        type     => 'hashref',
        optional => 1,
        keys     => {
            x_col      => { type => 'string',  optional => 1, default => 'x' },
            bar_col    => { type => 'string',  optional => 1, default => 'bar_val' },
            line_col   => { type => 'string',  optional => 1, default => 'line_val' },
            bar_label  => { type => 'string',  optional => 1, default => 'Bar' },
            line_label => { type => 'string',  optional => 1, default => 'Line' },
            bar_color  => { type => 'string',  optional => 1, default => 'steelblue' },
            line_color => { type => 'string',  optional => 1, default => '#e15759' },
            id         => { type => 'string',  optional => 1, default => 'combo_chart' },
            responsive => { type => 'boolean', optional => 1 },
        },
    },
}
```

##### Output

```perl
HashRef -- { svg_id => Str, html => Str }
```

### Render\_Treemap\_Snippet

```perl
my $result = $chart->render_treemap_snippet(\@rows_or_tree, \%opts);
```

Generates an embeddable treemap (no page shell, no CDN tag).
Leaf area is proportional to the numeric measure.

Accepts two data formats:

- **Flat path** (arrayref of hashrefs): each row must have a `path`
key (e.g. `'Root/A/X'`) and a `value` key.  The module converts this
to a D3 stratify hierarchy in JS.  Override the path separator with
`opts->{path_sep}`.
- **Nested tree** (hashref): a pre-built D3-compatible hierarchy
with `name`/`children`/`value` structure.  Passed directly to
`d3.hierarchy()`.

Accepted `\%opts` keys:

- `path_sep` (string, default `'/'`)  - path separator (flat format only).
- `scheme` (string, default `'tableau10'`) - D3 categorical colour scheme.
Supported: `tableau10`, `category10`, `set2`, `set3`, `paired` - the names
`categorical_schemes()` returns, whose colours `palette()` makes available to
Perl.
- `label` (boolean, default `1`) - show node labels inside cells.
- `id` (string, optional) - override the default `svg_id` value.
- `responsive` (boolean, optional) - SVG responsive sizing override.

Returns `{ svg_id => 'treemap', html => Str }`.

#### Errors

- Throws `Data must be an array of hashes or a hash tree`
when `$data` is neither an ARRAY nor a HASH reference.
- Throws `Each flat row must be a hash reference` when a flat row is not a hashref.
- Throws `Each flat row must have a 'path' key` when a flat row lacks `path`.
- Throws `Each flat row must have a numeric 'value' key` when a value is not numeric.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref | hashref' },
    opts => {
        type     => 'hashref',
        optional => 1,
        keys     => {
            path_sep => { type => 'string',  optional => 1, default => '/' },
            scheme   => { type => 'string',  optional => 1, default => 'tableau10' },
            label    => { type => 'boolean', optional => 1, default => 1 },
            id       => { type => 'string',  optional => 1, default => 'treemap' },
            responsive => { type => 'boolean', optional => 1 },
        },
    },
}
```

##### Output

```perl
HashRef -- { svg_id => Str, html => Str }
```

### Render\_Histogram\_Snippet

```perl
my $result = $chart->render_histogram_snippet(\@values, \%opts);
```

Generates an embeddable frequency histogram (no page shell, no CDN tag).
`\@values` is an arrayref of numeric scalars (already extracted and
coerced by the caller).

Accepted `\%opts` keys:

- `bins` (integer or `undef`, default `20`) - number of bins.
Pass `undef` for automatic bin count using Sturges' rule:
`ceil(log2(n) + 1)`.  Ignored when `binned` is set.
- `binned` (boolean, default 0) - treat `$data` as pre-computed bins
rather than as raw values.  Each element is a hashref with a `count` and
either a `label` or a numeric `lo`/`hi` pair from which the label `[lo,hi)`
is derived:

    ```perl
    { label => '[0,10)', count => 3 }
    { lo => 10, hi => 20, count => 5 }
    ```

    The caller owns the binning, so `d3.bin()` is never called: one bar is drawn
    per entry, in the order supplied, and the supplied counts are authoritative.

    The bin labels are drawn rotated.  The plot gives up as much room as they need,
    up to half the chart's height and a quarter of its width, so that they and
    `x_label` do not overlap and stay inside the chart.

- `scheme` (string, optional) - D3 categorical colour scheme (for example
`'tableau10'` or `'category10'`) whose first colour is used as the bar fill
when `color` is not given.
That colour is `colour_at($scheme, 0)`, so a caller shading the same data by
hand starts from the same colour the bars do.
- `x_label` (string, optional) - label shown below the X axis.
- `color` (string, default `'steelblue'`) - bar fill colour.
- `id` (string, optional) - override the default `svg_id` value.
- `responsive` (boolean, optional) - SVG responsive sizing override.

Returns `{ svg_id => 'histogram', html => Str }`.

#### Errors

- Throws `Data must be an array of numeric values` when `$data` is
not an ARRAY reference.
- Throws `Each value must be numeric` when any element is non-numeric.
- Throws `bins must be a positive integer` when `bins` is defined
but not a positive integer.
- Throws `Data must contain at least one bin` when `binned` is set and
`$data` holds no bins.
- Throws `Each pre-binned entry must be a hash reference` when a
pre-binned element is not a hashref.
- Throws `Bin count must be numeric` when a pre-binned `count` is
missing or not numeric.
- Throws `Bin count must not be negative` when a pre-binned `count` is
negative.
- Throws `Each pre-binned entry must have a label or numeric lo and hi`
when a pre-binned entry has neither a `label` nor a numeric `lo`/`hi` pair.

#### Api Specification

##### Input

```perl
{
    data => { type => 'arrayref' },
    opts => {
        type     => 'hashref',
        optional => 1,
        keys     => {
            bins    => { type => 'integer', optional => 1, default => 20 },
            binned  => { type => 'boolean', optional => 1, default => 0 },
            x_label => { type => 'string',  optional => 1, default => '' },
            color   => { type => 'string',  optional => 1, default => 'steelblue' },
            scheme  => { type => 'string',  optional => 1 },
            id      => { type => 'string',  optional => 1, default => 'histogram' },
            responsive => { type => 'boolean', optional => 1 },
        },
    },
}
```

##### Output

```perl
HashRef -- { svg_id => Str, html => Str }
```

## Support

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-html-d3 at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-D3](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-D3).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

```
perldoc HTML::D3
```

You can also look for information at:

## Bugs

It would help to have the render routine to return the head and body components separately.

## See Also

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/HTML-D3/coverage/)

## Author

Nigel Horne <njh@nigelhorne.com>

## Formal Specification

### Render\_Bar\_Chart

```
render_bar_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

pre  data = undef              ⇒ die "Data is not optional"
pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post ∀ d ∈ data . d[0] ⊆ result
```

### Render\_Line\_Chart

```
render_line_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post "d3.scalePoint" ⊆ result ∧ "d3.line()" ⊆ result
```

### Render\_Animated\_Bar\_Chart

```
render_animated_bar_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

pre  data = undef              ⇒ die "Data is not optional"
pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post ".transition()" ⊆ result ∧ ".delay(" ⊆ result
```

### Render\_Animated\_Line\_Chart

```
render_animated_line_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post "stroke-dashoffset" ⊆ result ∧ "d3.easeLinear" ⊆ result
```

### Render\_Pie\_Chart

```
render_pie_chart : HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → Str ∪ ⊥

pre  data = undef              ⇒ die "Data is not optional"
pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post "d3.pie()" ⊆ result ∧ "d3.arc()" ⊆ result ∧ "'#1f77b4'" ⊆ result
                                  -- category10's colours, inlined: no d3.scheme* is read
post opts.separator = S        ⇒  " S " ⊆ result (SVG legend: label S value)
```

### Render\_Animated\_Pie\_Chart

```
render_animated_pie_chart : HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → Str ∪ ⊥

pre  data = undef              ⇒ die "Data is not optional"
pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post "attrTween" ⊆ result ∧ "d3.interpolate" ⊆ result
post opts.separator = S        ⇒  " S " ⊆ result (SVG legend: label S value)
```

### Render\_Line\_Chart\_Snippet

```
render_line_chart_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
post result ∈ HashRef
post result.svg_id = opts.id // "chart"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
```

### Render\_Zoomable\_Line\_Chart\_Snippet

```
render_zoomable_line_chart_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
post result ∈ HashRef
post result.svg_id = opts.id // "chart"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post "d3.brushX()" ⊆ result.html
post opts.animated = 1  ⇒  "stroke-dashoffset" ⊆ result.html
                          ∧ "initialDrawDone" ⊆ result.html
```

### Render\_Pie\_Chart\_Snippet

```
render_pie_chart_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
pre  ∀ d ∈ data . d[1] < 0  ⇒  d[1] := |d[1]|      -- negative → absolute
pre  ∀ d ∈ data . d[1] = 0  ⇒  d ∉ result           -- zero → omitted
post result ∈ HashRef
post result.svg_id = "pie_chart"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post "d3.pie()" ⊆ result.html ∧ "schemeTableau10" ⊆ result.html
post opts.color_scheme = S ∧ S ∈ categorical_schemes()
                        ⇒ the D3 expression of S ⊆ result.html
post opts.color_scheme ∉ categorical_schemes()
                        ⇒ "schemeTableau10" ⊆ result.html  -- the default scheme
post opts.animated = 1  ⇒  "attrTween" ⊆ result.html
                          ∧ "initialDrawDone" ⊆ result.html
post opts.donut = 1     ⇒  "innerRadius" ⊆ result.html
post opts.max_slices = N ∧ N ≥ 2 ∧ |data| > N
                        ⇒  |result_slices| = N ∧ "Other" ∈ result_labels
post opts.separator = S ⇒  " S " ⊆ result.html (HTML legend: label S value (pct%))
```

### Render\_Heatmap\_Snippet

```
render_heatmap_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'       ⇒ die "Data must be an array of arrays"
pre  ∃ pt ∈ data . ref(pt) ≠ 'ARRAY'
                               ⇒ die "Each data point must be an array reference"
pre  ∃ pt ∈ data . |pt| < 3   ⇒ die "Each data point must have at least 3 elements"
pre  ∃ pt ∈ data . defined(pt[2]) ∧ ¬numeric(pt[2])
                               ⇒ die "Value must be numeric"
pre  opts.color_scheme = S ∧ S ∉ {YlOrRd,Blues,Greens,Purples,RdPu,YlGnBu}
                               ⇒ die "Unknown color_scheme: S"
pre  opts.cell_padding = N ∧ (N < 0 ∨ N > 8)
                               ⇒ die "cell_padding must be between 0 and 8"
pre  ∀ pt ∈ data . pt[2] = undef ⇒ pt ∉ result     -- undef rows skipped
pre  ∃ pt₁,pt₂ ∈ data . pt₁[0]=pt₂[0] ∧ pt₁[1]=pt₂[1]
                               ⇒ last-write wins
post result ∈ HashRef
post result.svg_id = "heatmap"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post "scaleSequential" ⊆ result.html
post opts.animated = 1         ⇒ "prefers-reduced-motion" ⊆ result.html
post opts.legend = 1           ⇒ "linearGradient" ⊆ result.html
```

### Render\_Bar\_Chart\_Snippet

```
render_bar_chart_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'       ⇒ die "Data must be an array of arrays"
pre  ∃ pt ∈ data . ref(pt) ≠ 'ARRAY'
                               ⇒ die "Each data point must be an array reference"
pre  ∃ pt ∈ data . |pt| < 2   ⇒ die "Each data point must have at least 2 elements"
pre  ∃ pt ∈ data . defined(pt[1]) ∧ ¬numeric(pt[1])
                               ⇒ die "Value must be numeric"
pre  opts.orientation ∉ {'vertical','horizontal'}
                               ⇒ die "orientation must be 'vertical' or 'horizontal'"
pre  opts.sort_bars ∉ {'value','label','none'}
                               ⇒ die "sort_bars must be 'value', 'label', or 'none'"
pre  ∀ pt ∈ data . pt[1] < 0  ⇒  pt[1] := |pt[1]|      -- negative → absolute
pre  ∀ pt ∈ data . pt[1] = undef ⇒ pt ∉ result          -- undef rows skipped
post result ∈ HashRef
post result.svg_id = opts.id // "bar_chart"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post "d3.scaleBand" ⊆ result.html ∧ "d3.scaleLinear" ⊆ result.html
post opts.animated = 1         ⇒ "prefers-reduced-motion" ⊆ result.html
post opts.color = 'categorical' ⇒ the default scheme's expression
                                  ("schemeTableau10") ⊆ result.html
post opts.max_bars = N ∧ N ≥ 2 ∧ |data| > N
                        ⇒ |result_bars| = N ∧ "Other" ∈ result_labels
```

### Render\_Multi\_Series\_Line\_Chart\_Snippet

```
render_multi_series_line_chart_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'        ⇒ die "Data must be an array of series"
pre  ∃ s ∈ data . ref(s) ≠ 'HASH'
                                ⇒ die "Each series must be a hashref with name and data"
pre  ∃ s ∈ data . ¬defined(s.name) ∨ ref(s.data) ≠ 'ARRAY'
                                ⇒ die "Each series must be a hashref with name and data"
post result ∈ HashRef
post result.svg_id = opts.id // "chart"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post "d3.scalePoint" ⊆ result.html ∧ "d3.scaleLinear" ⊆ result.html
post "d3.line()" ⊆ result.html
post #{path ∈ result.html : class = "msl-line"} = |data|   -- one path per series
post opts.x_label ≠ ''          ⇒ "msl-axis-label" ⊆ result.html
post opts.y_label ≠ ''          ⇒ "msl-axis-label" ⊆ result.html
post opts.scheme = S ∧ S ∈ categorical_schemes()
                                ⇒ the colours of S, as a JS array, ⊆ result.html
post opts.scheme ∉ categorical_schemes()
                                ⇒ the default scheme's colours ⊆ result.html
                                  -- not a d3.scheme<S> expression
post opts.animated = 1          ⇒ "stroke-dashoffset" ⊆ result.html
                                  ∧ "prefers-reduced-motion" ⊆ result.html
```

### Render\_Scatter\_Chart\_Snippet

```
render_scatter_chart_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'       ⇒ die "Data must be an array of arrays"
pre  ∃ pt ∈ data . ref(pt) ≠ 'ARRAY'
                               ⇒ die "Each data point must be an array reference"
pre  ∃ pt ∈ data . |pt| < 2   ⇒ die "Each data point must have at least 2 elements"
pre  ∃ pt ∈ data . ¬numeric(pt[0])
                               ⇒ die "X value must be numeric"
pre  ∃ pt ∈ data . ¬numeric(pt[1])
                               ⇒ die "Y value must be numeric"
post result ∈ HashRef
post result.svg_id = opts.id // "scatter_chart"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post "d3.scaleLinear" ⊆ result.html
post opts.animated = 1         ⇒ "prefers-reduced-motion" ⊆ result.html
post opts.colour_by_series = 1 ∧ ∃ pt ∈ data . defined(pt[3].series)
                               ⇒ "scaleOrdinal" ⊆ result.html
                                 ∧ "seriesNames" ⊆ result.html
                                 ∧ legend drawn (margin right = 140)
post opts.colour_by_series = 1 ∧ opts.scheme = S ∧ S ∈ categorical_schemes()
                               ⇒ the D3 expression of S ⊆ result.html
post opts.colour_by_series = 1 ∧ opts.scheme ∉ categorical_schemes()
                               ⇒ the default scheme's expression ⊆ result.html
post ∃ pt ∈ data . defined(pt[3].size)
                               ⇒ "d3.scaleSqrt" ⊆ result.html ∧ "rScale" ⊆ result.html
post opts.radius_range = [A,B]
                               ⇒ "range([A,B])" ⊆ result.html
post ∀ pt ∈ data . pt[3].size = undef
                               ⇒ "rScale" ∉ result.html      -- fixed radius
```

### Render\_Table\_Snippet

```
render_table_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'       ⇒ die "Data must be an array of arrays"
pre  |data| = 0                ⇒ die "Data must have at least one row (header row)"
pre  ∃ row ∈ data . ref(row) ≠ 'ARRAY'
                               ⇒ die "Each row must be an array reference"
post result ∈ HashRef
post result.table_id = opts.id // "data_table"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post opts.sortable ≠ 0         ⇒ "dt-sortable" ⊆ result.html
```

### Render\_Stacked\_Bar\_Snippet

```
render_stacked_bar_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'        ⇒ die "Data must be an array of hashes"
pre  ∃ row ∈ data . ref(row) ≠ 'HASH'
                                ⇒ die "Each data point must be a hash reference"
pre  ∃ row ∈ data . ¬numeric(row[val_col])
                                ⇒ die "Value must be numeric"
pre  opts.orient ∉ {'v','h'}    ⇒ die "orient must be 'v' or 'h'"
pre  defined(opts.sort) ∧ opts.sort ∉ {'value','label'}
                                ⇒ die "sort must be 'value' or 'label'"
post result ∈ HashRef
post result.svg_id = opts.id // "stacked_bar"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post "d3.stack()" ⊆ result.html
post "SCHEMES" ⊆ result.html
post opts.scheme = S ∧ S ∈ categorical_schemes()
                                ⇒ the D3 expression of S ⊆ result.html
post opts.scheme ∉ categorical_schemes()
                                ⇒ the default scheme's expression ⊆ result.html
```

### Render\_Combo\_Snippet

```
render_combo_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'        ⇒ die "Data must be an array of hashes"
pre  ∃ row ∈ data . ref(row) ≠ 'HASH'
                                ⇒ die "Each data point must be a hash reference"
pre  ∃ row ∈ data . ¬numeric(row[bar_col])
                                ⇒ die "Bar value must be numeric"
pre  ∃ row ∈ data . ¬numeric(row[line_col])
                                ⇒ die "Line value must be numeric"
post result ∈ HashRef
post result.svg_id = opts.id // "combo_chart"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post "d3.scaleBand" ⊆ result.html ∧ "d3.scaleLinear" ⊆ result.html
post "axisRight" ⊆ result.html
post "</b>" ∉ result.html ∧ "<\/b>" ∈ result.html
```

### Render\_Treemap\_Snippet

```
render_treemap_snippet :
    HTML::D3 × (ArrayRef | HashRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ∉ {'ARRAY','HASH'}
                                ⇒ die "Data must be an array of hashes or a hash tree"
pre  ref(data) = 'ARRAY' ∧ ∃ row ∈ data . ref(row) ≠ 'HASH'
                                ⇒ die "Each flat row must be a hash reference"
pre  ref(data) = 'ARRAY' ∧ ∃ row ∈ data . ¬exists(row.path)
                                ⇒ die "Each flat row must have a 'path' key"
pre  ref(data) = 'ARRAY' ∧ ∃ row ∈ data . ¬numeric(row.value)
                                ⇒ die "Each flat row must have a numeric 'value' key"
post result ∈ HashRef
post result.svg_id = opts.id // "treemap"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post "d3.treemap()" ⊆ result.html
post ref(data) = 'ARRAY' ⇒ "d3.stratify()" ⊆ result.html
post ref(data) = 'HASH'  ⇒ "d3.hierarchy(" ⊆ result.html
post opts.scheme = S ∧ S ∈ categorical_schemes()
                                ⇒ the D3 expression of S ⊆ result.html
post opts.scheme ∉ categorical_schemes()
                                ⇒ the default scheme's expression ⊆ result.html
```

### Render\_Histogram\_Snippet

```
render_histogram_snippet :
    HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

pre  ref(data) ≠ 'ARRAY'        ⇒ die "Data must be an array of numeric values"
pre  ∃ v ∈ data . ¬numeric(v)  ⇒ die "Each value must be numeric"
pre  defined(opts.bins) ∧ (¬integer(opts.bins) ∨ opts.bins < 1)
                                ⇒ die "bins must be a positive integer"
pre  opts.binned = 1 ∧ |data| = 0
                                ⇒ die "Data must contain at least one bin"
pre  opts.binned = 1 ∧ ∃ b ∈ data . ref(b) ≠ 'HASH'
                                ⇒ die "Each pre-binned entry must be a hash reference"
pre  opts.binned = 1 ∧ ∃ b ∈ data . ¬numeric(b.count)
                                ⇒ die "Bin count must be numeric"
pre  opts.binned = 1 ∧ ∃ b ∈ data . b.count < 0
                                ⇒ die "Bin count must not be negative"
pre  opts.binned = 1 ∧ ∃ b ∈ data . ¬defined(b.label) ∧ ¬(numeric(b.lo) ∧ numeric(b.hi))
                                ⇒ die "Each pre-binned entry must have a label or numeric lo and hi"
pre  opts.binned = 1 ∧ ¬defined(b.label) ∧ numeric(b.lo) ∧ numeric(b.hi)
                                ⇒ b.label := "[lo,hi)"
post result ∈ HashRef
post result.svg_id = opts.id // "histogram"
post result.html ∈ Str
post "<!DOCTYPE" ∉ result.html
post opts.binned ≠ 1            ⇒ "d3.bin()" ⊆ result.html
post opts.binned = 1            ⇒ "d3.bin()" ∉ result.html ∧ "scaleBand" ⊆ result.html
post opts.color defined         ⇒ c(clone)      -- explicit colour is the bar fill
post opts.color = undef ∧ opts.scheme = S ∧ S ∈ categorical_schemes()
                                ⇒ the D3 expression of S subscripted "[0]"
                                  ⊆ result.html            -- colour_at(S, 0)
post opts.color = undef ∧ opts.scheme ∉ categorical_schemes()
                                ⇒ the default scheme's first colour ⊆ result.html
post opts.bins = undef          ⇒ "Math.log2" ⊆ result.html
post opts.x_label ≠ ''         ⇒ "hg-axis-label" ⊆ result.html
```

### Render\_Line\_Chart\_With\_Tooltips

```
render_line_chart_with_tooltips : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post "mouseover" ⊆ result
post "</b>" ∉ result ∧ "<\/b>" ∈ result
```

### Render\_Multi\_Series\_Line\_Chart\_With\_Tooltips

```
render_multi_series_line_chart_with_tooltips : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of hashes"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post "</b>" ∉ result ∧ "<\/b>" ∈ result
```

### Render\_Multi\_Series\_Line\_Chart\_With\_Animated\_Tooltips

```
render_multi_series_line_chart_with_animated_tooltips : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

pre  ref(data) ≠ 'ARRAY'   ⇒ die "Data must be an array of hashes"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post "translateY" ⊆ result
post "</b>" ∉ result ∧ "<\/b>" ∈ result
```

### Render\_Multi\_Series\_Line\_Chart\_With\_Legends

```
render_multi_series_line_chart_with_legends : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of hashes"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post ".legend" ⊆ result
```

### Render\_Multi\_Series\_Line\_Chart\_With\_Interactive\_Legends

```
render_multi_series_line_chart_with_interactive_legends : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

pre  ref(data) ≠ 'ARRAY'            ⇒ die "Data must be an array of hashes"
post result ∈ Str
post "<!DOCTYPE" ⊆ result
post "isVisible" ⊆ result
post "isVisible ? 0 : 1" ⊆ result
post ".legend" ⊆ result
```

## License and Copyright

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
