## Name

HTML::D3 - A simple Perl module for generating charts using D3.js.

## Version

Version 0.18

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
Each slice is coloured with `d3.schemeCategory10`; percentage labels appear
inside each slice and a colour legend is shown to the right of the pie.
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
       C<d3.arc()>; slices coloured with C<d3.schemeCategory10>;
       percentage label inside each slice; legend to the right.
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
`paired`.
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
reference with two required numeric elements (x, y) and an optional third
hash reference of extra key/value pairs shown as extra tooltip rows.

    ```
    [$x, $y]          # basic point
    [$x, $y, \%row]   # point with extra tooltip data
    ```

- `\%opts` - Optional hash reference:
    - `id` (string, default `'scatter_chart'`) - `id` of the `<svg`> element.
    - `color` (CSS colour or `'categorical'`, default `'steelblue'`) -
    Fill colour for the data points.  `'categorical'` uses the Tableau-10 palette.
    - `x_label` (string, default `''`) - Label for the X axis.
    - `y_label` (string, default `''`) - Label for the Y axis.
    - `value_label` (string, default `'Value'`) - Prefix for the tooltip value row.
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
post "d3.pie()" ⊆ result ∧ "d3.arc()" ⊆ result ∧ "d3.schemeCategory10" ⊆ result
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
post opts.color = 'categorical' ⇒ "schemeTableau10" ⊆ result.html
post opts.max_bars = N ∧ N ≥ 2 ∧ |data| > N
                        ⇒ |result_bars| = N ∧ "Other" ∈ result_labels
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
