# NAME

HTML::D3 - A simple Perl module for generating charts using D3.js.

# VERSION

Version 0.15

# SYNOPSIS

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

# DESCRIPTION

HTML::D3 is a Perl module that provides functionality to create simple charts using D3.js.
The module generates HTML and JavaScript code to render the chart in a web browser.

# METHODS

The `=head3 API SPECIFICATION` subsections use [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
schema syntax (`type => 'arrayref'` etc.) as a documentation convention.
The module is also used at runtime in `new()` to validate constructor
arguments; it is therefore a required runtime dependency.  The schemas describe
the parameter contract in machine-readable notation and can be plumbed into a
WAF or test generator if desired.

## new

    my $chart = HTML::D3->new(%args);

Creates a new HTML::D3 object.
Accepts the following optional arguments:

- `width` - The width of the chart (default: 800).
- `height` - The height of the chart (default: 600).
- `title` - The title of the chart (default: 'Chart').

## render\_bar\_chart

    my $html = $chart->render_bar_chart($data);

Generates HTML and JavaScript code to render a bar chart. Accepts the following arguments:

- `$data` - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.

### Errors

- Throws `Data is not optional` when `$data` is `undef`.
- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

    {
        data => {
                type => 'arrayref',
                element_type => [ 'string', 'number' ]
        }
    }

    Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
    non-arrayref dies.

#### Output

    Str -- complete HTML5 document starting with C<< <!DOCTYPE html> >>;
           D3.js loaded from CDN; bar chart rendered with C<d3.scaleBand>.

## render\_animated\_bar\_chart

    my $html = $chart->render_animated_bar_chart($data);

Generates HTML and JavaScript code to render a bar chart where each bar grows
upward from the baseline on page load.  Bars are staggered so they rise
one-after-another from left to right.
Accepts the following arguments:

- `$data` - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the complete HTML5 document.

### Errors

- Throws `Data is not optional` when `$data` is `undef`.
- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
    non-arrayref dies.

#### Output

    Str -- complete HTML5 document; each bar animates from height=0 upward
           using C<d3.transition()> with a staggered per-bar delay.

## render\_line\_chart

    my $html = $chart->render_line_chart($data);

Generates HTML and JavaScript code to render a line chart. Accepts the following arguments:

- `$data` - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.

### Errors

- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
    non-arrayref dies.

#### Output

    Str -- complete HTML5 document; line chart with C<d3.scalePoint> and C<d3.line()>.

## render\_animated\_line\_chart

    my $html = $chart->render_animated_line_chart($data);

Generates HTML and JavaScript code to render a line chart where the line
draws itself from left to right on page load, followed by each data-point
circle fading in once the line is complete.
Accepts the following arguments:

- `$data` - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the complete HTML5 document.

### Errors

- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
    non-arrayref dies.

#### Output

    Str -- complete HTML5 document; the line path animates via
           C<stroke-dashoffset> with C<d3.easeLinear>; data-point circles
           fade in with C<opacity> after the line transition completes.

## render\_pie\_chart

    my $html = $chart->render_pie_chart($data);
    my $html = $chart->render_pie_chart($data, { separator => ':' });

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

### Errors

- Throws `Data is not optional` when `$data` is `undef`.
- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

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

#### Output

    Str -- complete HTML5 document; pie rendered with C<d3.pie()> and
           C<d3.arc()>; slices coloured with C<d3.schemeCategory10>;
           percentage label inside each slice; legend to the right.

## render\_animated\_pie\_chart

    my $html = $chart->render_animated_pie_chart($data);
    my $html = $chart->render_animated_pie_chart($data, { separator => ':' });

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

### Errors

- Throws `Data is not optional` when `$data` is `undef`.
- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

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

#### Output

    Str -- complete HTML5 document; slices animate via C<attrTween> with
           C<d3.interpolate> (1000 ms); percentage labels fade in afterwards.

## render\_pie\_chart\_snippet

    my $fragment = $chart->render_pie_chart_snippet(\@slices);
    my $fragment = $chart->render_pie_chart_snippet(\@slices, \%opts);
    # $fragment->{svg_id} - always 'pie_chart'
    # $fragment->{html}   - embeddable fragment; caller must load D3 v7

Generates an embeddable pie or donut chart fragment for use in existing HTML
layouts.  Returns `{ svg_id => 'pie_chart', html => Str }`.  The
caller is responsible for loading D3 v7 before embedding the fragment.

### Data format

Each element of `\@slices` is `[$label, $value]` or `[$label, $value, \%extra]`.
Negative values are silently converted to their absolute value.  Zero-value
slices are silently omitted.  `\%extra` key/value pairs are shown as
additional rows in the hover tooltip.

### Options (`\%opts`)

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

### Errors

- Throws `Data must be an array of arrays` when `\@slices` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

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

#### Output

    HashRef -- C<{ svg_id =E<gt> 'pie_chart', html =E<gt> Str }>;
               embeddable fragment; no DOCTYPE, no page shell, no D3 CDN tag.

## render\_line\_chart\_with\_tooltips

    $html = $chart->render_line_chart_with_tooltips($data);

Generates HTML and JavaScript code to render a line chart with mouseover tooltips.
Accepts the following arguments:

- `$data` - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.
The JavaScript tooltip strings use `<\/b>` (with a backslash) rather than
`</b>` to satisfy html-tidy's requirement that `</` followed by a
letter not appear literally inside `<script>` blocks.

### Errors

- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
    non-arrayref dies.

#### Output

    Str -- complete HTML5 document; mouseover tooltip reveals label and value.
           Tooltip strings use C<< <\/b> >> not C<< </b> >>.

## render\_line\_chart\_snippet

    my $fragment = $chart->render_line_chart_snippet($data);
    # $fragment->{svg_id} - the id attribute of the <svg> element
    # $fragment->{html}   - embeddable HTML fragment (style + svg + script)

Generates an embeddable HTML fragment for a line chart with mouseover tooltips.
Unlike `render_line_chart_with_tooltips`, this method returns a fragment with
no `<!DOCTYPE`>, `<html`>, `<head`>, or `<body`> wrapper, suitable for
splicing directly into a Mojolicious TT (or any other) layout.

The caller is responsible for loading D3 in the page `<head`>, e.g.:

    <script src="https://d3js.org/d3.v7.min.js"></script>

Accepts the following arguments:

- `$data` - An array reference of data points. Each point is an array
reference with two required elements - the label (string) and the value
(numeric) - and an optional third element: a hash reference of extra key/value
pairs to display in the tooltip after the label and value rows.

        [$x, $y]          # basic point
        [$x, $y, \%row]   # point with extra tooltip data

Returns a hash reference with:

- `svg_id` - The `id` attribute used on the `<svg`> element.
- `html` - The embeddable fragment string.

## render\_zoomable\_line\_chart\_snippet

    my $fragment = $chart->render_zoomable_line_chart_snippet($data);
    my $fragment = $chart->render_zoomable_line_chart_snippet($data, { animated => 1 });
    # $fragment->{svg_id} - the id attribute of the <svg> element
    # $fragment->{html}   - embeddable HTML fragment (style + button + svg + script)

Like `render_line_chart_snippet`, but adds brush-to-zoom: the user can drag
across a range of the x-axis to zoom into that region. A _Reset zoom_ button
(hidden until a zoom is active) returns the chart to its original extent.
Subsequent brushes on the zoomed view zoom in further; Reset always returns to
the full dataset.

The caller is responsible for loading D3 in the page `<head`>.

Accepts the same arguments as `render_line_chart_snippet`: an array reference
of data points, each `[$x, $y]` or `[$x, $y, \%extra]`, plus an optional
second argument `$opts` (hashref).

### Options

- `animated` (boolean, default `0`) - when true, the initial page load
animates the line drawing left-to-right via the `stroke-dashoffset` technique
(1200 ms, `d3.easeLinear`), then fades in data-point circles after the line
finishes (300 ms after a 1200 ms delay).  Respects
`prefers-reduced-motion`: when the user has requested reduced motion the line
is drawn immediately at full opacity.  Subsequent zoom and reset redraws are
never animated regardless of this flag.

### API SPECIFICATION

#### Input

    {
        data => { type => 'arrayref' },
        opts => { type => 'hashref', optional => 1, default => {} },
    }

    Each element of C<$data> is C<[ Str, Num ]> or C<[ Str, Num, HashRef ]>;
    passing C<undef> or a non-arrayref dies.
    Recognised C<opts> key: C<animated> (boolean, default C<0>).

#### Output

    HashRef -- C<{ svg_id =E<gt> 'chart', html =E<gt> Str }>;
               embeddable fragment; no DOCTYPE, no page shell, no D3 CDN tag.

### Errors

Dies with _Data must be an array of arrays_ if `$data` is not an arrayref.

### Side Effects

None.

## render\_multi\_series\_line\_chart\_with\_tooltips

    $html = $chart->render_multi_series_line_chart_with_tooltips($data);

Generates HTML and JavaScript code to render a chart of many lines with mouseover tooltips.

Accepts the following arguments:

- `$data` - An array reference of series hashes. Each element is a hashref
with a `name` key (string) and a `data` key (array reference of `{label, value}`
hashrefs).

        [
            { name => 'Series A', data => [{ label => 'Jan', value => 100 }, ...] },
            ...
        ]

Returns a string containing the HTML and JavaScript code for the chart.
Tooltip strings use `<\/b>` rather than `</b>` for html-tidy compliance.

### Errors

- Throws `Data must be an array of hashes` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is a hashref with keys C<name> (string) and
    C<data> (arrayref of hashrefs with C<label> and C<value> keys);
    passing C<undef> or a non-arrayref dies.

#### Output

    Str -- complete HTML5 document; one coloured line per series with mouseover tooltips.

## render\_multi\_series\_line\_chart\_with\_animated\_tooltips

    $html = $chart->render_multi_series_line_chart_with_animated_tooltips($data);

Generates HTML and JavaScript code to render a chart of many lines with animated mouseover tooltips.

Accepts the following arguments:

- `$data` - Same format as `render_multi_series_line_chart_with_tooltips`:
an array reference of `{ name, data }` series hashes.

Returns a string containing the complete HTML5 document.
The tooltip appears with a CSS `translateY` slide-in animation.
Tooltip strings use `<\/b>` for html-tidy compliance.

### Errors

- Throws `Data must be an array of hashes` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is a hashref with keys C<name> (string) and
    C<data> (arrayref of hashrefs with C<label> and C<value> keys);
    passing C<undef> or a non-arrayref dies.

#### Output

    Str -- complete HTML5 document; animated tooltip uses CSS translateY transition.

## render\_multi\_series\_line\_chart\_with\_legends

    $html = $chart->render_multi_series_line_chart_with_legends($data);

Generates HTML and JavaScript code to render a chart of many lines with a static
colour legend. Each series gets a labelled colour swatch in the legend area.

Accepts the following arguments:

- `$data` - Same format as `render_multi_series_line_chart_with_tooltips`:
an array reference of `{ name, data }` series hashes.

Returns a string containing the complete HTML5 document. The stylesheet defines
a `.legend` CSS class used by the D3-generated legend elements.

### Errors

- Throws `Data must be an array of hashes` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is a hashref with keys C<name> (string) and
    C<data> (arrayref of hashrefs with C<label> and C<value> keys);
    passing C<undef> or a non-arrayref dies.

#### Output

    Str -- complete HTML5 document; static colour legend rendered as SVG C<g> elements
           with the C<.legend> CSS class applied via D3 C<.attr("class", "legend")>.

## render\_multi\_series\_line\_chart\_with\_interactive\_legends

    $html = $chart->render_multi_series_line_chart_with_interactive_legends($data);

Generates HTML and JavaScript code to render a chart of many lines with interactive legends to filter, highlight or modify elements based on legend selections.

Accepts the following arguments:

- `$data` - Same format as `render_multi_series_line_chart_with_tooltips`:
an array reference of `{ name, data }` series hashes.

Returns a string containing the complete HTML5 document. Clicking a legend entry
toggles that series' opacity using an `isVisible` boolean flag in the D3 click
handler (opacity is set to `isVisible ? 0 : 1` on each click).

### Errors

- Throws `Data must be an array of hashes` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is a hashref with keys C<name> (string) and
    C<data> (arrayref of hashrefs with C<label> and C<value> keys);
    passing C<undef> or a non-arrayref dies.

#### Output

    Str -- complete HTML5 document; legend clicks toggle series visibility.
           The C<isVisible> JS variable tracks current visibility state.
           Opacity toggled by C<isVisible ? 0 : 1>.

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-html-d3 at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-D3](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-D3).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc HTML::D3

You can also look for information at:

# BUGS

It would help to have the render routine to return the head and body components separately.

# SEE ALSO

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/HTML-D3/coverage/)

# AUTHOR

Nigel Horne <njh@nigelhorne.com>

# FORMAL SPECIFICATION

## render\_bar\_chart

    render_bar_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  data = undef              ⇒ die "Data is not optional"
    pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post ∀ d ∈ data . d[0] ⊆ result

## render\_line\_chart

    render_line_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "d3.scalePoint" ⊆ result ∧ "d3.line()" ⊆ result

## render\_animated\_bar\_chart

    render_animated_bar_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  data = undef              ⇒ die "Data is not optional"
    pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post ".transition()" ⊆ result ∧ ".delay(" ⊆ result

## render\_animated\_line\_chart

    render_animated_line_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "stroke-dashoffset" ⊆ result ∧ "d3.easeLinear" ⊆ result

## render\_pie\_chart

    render_pie_chart : HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → Str ∪ ⊥

    pre  data = undef              ⇒ die "Data is not optional"
    pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "d3.pie()" ⊆ result ∧ "d3.arc()" ⊆ result ∧ "d3.schemeCategory10" ⊆ result
    post opts.separator = S        ⇒  " S " ⊆ result (SVG legend: label S value)

## render\_animated\_pie\_chart

    render_animated_pie_chart : HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → Str ∪ ⊥

    pre  data = undef              ⇒ die "Data is not optional"
    pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "attrTween" ⊆ result ∧ "d3.interpolate" ⊆ result
    post opts.separator = S        ⇒  " S " ⊆ result (SVG legend: label S value)

## render\_line\_chart\_snippet

    render_line_chart_snippet : HTML::D3 × (ArrayRef | undef) → HashRef ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
    post result ∈ HashRef
    post result.svg_id = "chart"
    post result.html ∈ Str
    post "<!DOCTYPE" ∉ result.html

## render\_zoomable\_line\_chart\_snippet

    render_zoomable_line_chart_snippet :
        HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → HashRef ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
    post result ∈ HashRef
    post result.svg_id = "chart"
    post result.html ∈ Str
    post "<!DOCTYPE" ∉ result.html
    post "d3.brushX()" ⊆ result.html
    post opts.animated = 1  ⇒  "stroke-dashoffset" ⊆ result.html
                              ∧ "initialDrawDone" ⊆ result.html

## render\_pie\_chart\_snippet

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

## render\_line\_chart\_with\_tooltips

    render_line_chart_with_tooltips : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "mouseover" ⊆ result
    post "</b>" ∉ result ∧ "<\/b>" ∈ result

## render\_multi\_series\_line\_chart\_with\_tooltips

    render_multi_series_line_chart_with_tooltips : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of hashes"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "</b>" ∉ result ∧ "<\/b>" ∈ result

## render\_multi\_series\_line\_chart\_with\_animated\_tooltips

    render_multi_series_line_chart_with_animated_tooltips : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'   ⇒ die "Data must be an array of hashes"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "translateY" ⊆ result
    post "</b>" ∉ result ∧ "<\/b>" ∈ result

## render\_multi\_series\_line\_chart\_with\_legends

    render_multi_series_line_chart_with_legends : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of hashes"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post ".legend" ⊆ result

## render\_multi\_series\_line\_chart\_with\_interactive\_legends

    render_multi_series_line_chart_with_interactive_legends : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'            ⇒ die "Data must be an array of hashes"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "isVisible" ⊆ result
    post "isVisible ? 0 : 1" ⊆ result
    post ".legend" ⊆ result

# LICENSE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
