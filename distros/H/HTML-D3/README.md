# NAME

HTML::D3 - A simple Perl module for generating charts using D3.js.

# VERSION

Version 0.12

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

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required; undef dies

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

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required; undef dies

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

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required (undef dies)

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

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required (undef dies)

#### Output

    Str -- complete HTML5 document; the line path animates via
           C<stroke-dashoffset> with C<d3.easeLinear>; data-point circles
           fade in with C<opacity> after the line transition completes.

## render\_pie\_chart

    my $html = $chart->render_pie_chart($data);

Generates HTML and JavaScript code to render a pie chart.
Each slice is coloured with `d3.schemeCategory10`; percentage labels appear
inside each slice and a colour legend is shown to the right of the pie.
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

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required; undef dies

#### Output

    Str -- complete HTML5 document; pie rendered with C<d3.pie()> and
           C<d3.arc()>; slices coloured with C<d3.schemeCategory10>;
           percentage label inside each slice; legend to the right.

## render\_animated\_pie\_chart

    my $html = $chart->render_animated_pie_chart($data);

Generates HTML and JavaScript code to render an animated pie chart where each
slice fans out from zero angle on page load using `attrTween` and
`d3.interpolate`.  Percentage labels fade in once all slices are drawn.
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

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required; undef dies

#### Output

    Str -- complete HTML5 document; slices animate via C<attrTween> with
           C<d3.interpolate> (1000 ms); percentage labels fade in afterwards.

## render\_pie\_chart\_snippet

    my $fragment = $chart->render_pie_chart_snippet($data);

Generates an embeddable pie chart fragment for use in existing HTML layouts.
The caller is responsible for loading D3 in the page `<head>`.
Returns a hashref (not a full HTML document) so it can be spliced into a
Mojolicious template or similar layout without corrupting the host page structure.

- `$data` - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).

### Errors

- Throws `Data must be an array of arrays` when `$data` is not an ARRAY reference.

### Side Effects

None.

### API SPECIFICATION

#### Input

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required (undef dies)

#### Output

    HashRef -- C<{ svg_id =E<gt> 'chart', html =E<gt> Str }>; the html value
               is an embeddable fragment containing only C<< <svg> >> and
               C<< <script> >> elements - no DOCTYPE, no page shell, no D3
               CDN tag (caller's responsibility).

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

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required

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
    # $fragment->{svg_id} - the id attribute of the <svg> element
    # $fragment->{html}   - embeddable HTML fragment (style + button + svg + script)

Like `render_line_chart_snippet`, but adds brush-to-zoom: the user can drag
across a range of the x-axis to zoom into that region. A _Reset zoom_ button
(hidden until a zoom is active) returns the chart to its original extent.
Subsequent brushes on the zoomed view zoom in further; Reset always returns to
the full dataset.

The caller is responsible for loading D3 in the page `<head`>.

Accepts the same arguments as `render_line_chart_snippet`: an array reference
of data points, each `[$x, $y]` or `[$x, $y, \%extra]`.

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

    $self : HTML::D3                                                   -- required
    $data : ArrayRef[ HashRef{ name: Str, data: ArrayRef[HashRef] } ] -- required

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

    $self : HTML::D3                                                   -- required
    $data : ArrayRef[ HashRef{ name: Str, data: ArrayRef[HashRef] } ] -- required

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

    $self : HTML::D3                                                   -- required
    $data : ArrayRef[ HashRef{ name: Str, data: ArrayRef[HashRef] } ] -- required

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

    $self : HTML::D3                                                   -- required
    $data : ArrayRef[ HashRef{ name: Str, data: ArrayRef[HashRef] } ] -- required

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

## render\_lint\_chart\_with\_tooltips

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
