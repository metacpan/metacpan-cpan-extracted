package HTML::D3;

use strict;
use warnings;

use Carp qw(carp);
use JSON::MaybeXS;
use Object::Configure;
use Params::Get;
use Scalar::Util;

# TODO: add animated tooltips to charts with legends

=head1 NAME

HTML::D3 - A simple Perl module for generating charts using D3.js.

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

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

=head1 DESCRIPTION

HTML::D3 is a Perl module that provides functionality to create simple charts using D3.js.
The module generates HTML and JavaScript code to render the chart in a web browser.

=head1 METHODS

=head2 new

    my $chart = HTML::D3->new(%args);

Creates a new HTML::D3 object.
Accepts the following optional arguments:

=over 4

=item * C<width> - The width of the chart (default: 800).

=item * C<height> - The height of the chart (default: 600).

=item * C<title> - The title of the chart (default: 'Chart').

=back

=cut

# Constructor to initialize chart properties
sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params(undef, @_) || {};

	if(!defined($class)) {
		if((scalar keys %{$params}) > 0) {
			# Using HTML::D3->new(), not HTML::D3::new()
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %{$params} }, ref($class);
	}

	$params = Object::Configure::configure($class, $params);

	# Return the blessed object
	return bless {
		width => $params->{width}  || 800,  # Default chart width
		height => $params->{height} || 600,  # Default chart height
		title => $params->{title}  || 'Chart',  # Default chart title
	}, $class;
}

=head2 render_bar_chart

    my $html = $chart->render_bar_chart($data);

Generates HTML and JavaScript code to render a bar chart. Accepts the following arguments:

=over 4

=item * C<$data> - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

=back

Returns a string containing the HTML and JavaScript code for the chart.

=head3 Errors

=over 4

=item * Throws C<Data is not optional> when C<$data> is C<undef>.

=item * Throws C<Data must be an array of arrays> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required; undef dies

=head4 Output

    Str -- complete HTML5 document starting with C<< <!DOCTYPE html> >>;
           D3.js loaded from CDN; bar chart rendered with C<d3.scaleBand>.

=cut

# Method to render a bar chart with given data
sub render_bar_chart {
	my ($self, $data) = @_;

	die 'Data is not optional' if(!defined($data));

	# Validate input data to ensure it is an array of arrays
	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	# Generate JSON representation of data
	my $json_data = encode_json([
		map { { label => $_->[0], value => $_->[1] } } @$data
	]);

	# Generate HTML and D3.js JavaScript for rendering the bar chart
	my $html = $self->_preamble();
	$html .= $self->_head();
	$html .= <<"HTML";
<body>
    <h1 style="text-align: center;">$self->{title}</h1>
    <svg id="chart" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
    <script>
	const data = $json_data;

	const svg = d3.select("#chart");
	const margin = { top: 20, right: 30, bottom: 40, left: 40 };
	const width = $self->{width} - margin.left - margin.right;
	const height = $self->{height} - margin.top - margin.bottom;

	// Set up scales for x and y axes
	const x = d3.scaleBand()
	    .domain(data.map(d => d.label))
	    .range([0, width])
	    .padding(0.1);

	const y = d3.scaleLinear()
	    .domain([0, d3.max(data, d => d.value)])
	    .nice()
	    .range([height, 0]);

	const chart = svg.append("g")
	    .attr("transform", `translate(\${margin.left},\${margin.top})`);

	// Add bars to the chart
	chart.append("g")
	    .selectAll("rect")
	    .data(data)
	    .join("rect")
	    .attr("x", d => x(d.label))
	    .attr("y", d => y(d.value))
	    .attr("height", d => height - y(d.value))
	    .attr("width", x.bandwidth())
	    .attr("fill", "steelblue");

	// Add the y-axis
	chart.append("g")
	    .call(d3.axisLeft(y));

	// Add the x-axis with labels rotated for better readability
	chart.append("g")
	    .attr("transform", `translate(0,\${height})`)
	    .call(d3.axisBottom(x))
	    .selectAll("text")
	    .attr("transform", "rotate(-45)")
	    .style("text-anchor", "end");
    </script>
</body>
</html>
HTML

    return $html;
}

=head2 render_line_chart

    my $html = $chart->render_line_chart($data);

Generates HTML and JavaScript code to render a line chart. Accepts the following arguments:

=over 4

=item * C<$data> - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

=back

Returns a string containing the HTML and JavaScript code for the chart.

=head3 Errors

=over 4

=item * Throws C<Data must be an array of arrays> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required (undef dies)

=head4 Output

    Str -- complete HTML5 document; line chart with C<d3.scalePoint> and C<d3.line()>.

=cut

sub render_line_chart {
    my ($self, $data) = @_;

    # Validate input data
    die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

    # Generate JSON for data
    my $json_data = encode_json([
	map { { label => $_->[0], value => $_->[1] } } @$data
    ]);

    # Generate HTML and D3.js code
    my $html = $self->_preamble();
    $html .= $self->_head();
    $html .= <<"HTML";
<body>
    <h1 style="text-align: center;">$self->{title}</h1>
    <svg id="chart" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
    <script>
	const data = $json_data;

	const svg = d3.select("#chart");
	const margin = { top: 20, right: 30, bottom: 40, left: 40 };
	const width = $self->{width} - margin.left - margin.right;
	const height = $self->{height} - margin.top - margin.bottom;

	const x = d3.scalePoint()
	    .domain(data.map(d => d.label))
	    .range([0, width]);

	const y = d3.scaleLinear()
	    .domain([0, d3.max(data, d => d.value)])
	    .nice()
	    .range([height, 0]);

	const chart = svg.append("g")
	    .attr("transform", `translate(\${margin.left},\${margin.top})`);

	// Draw line
	const line = d3.line()
	    .x(d => x(d.label))
	    .y(d => y(d.value));

	chart.append("path")
	    .datum(data)
	    .attr("fill", "none")
	    .attr("stroke", "steelblue")
	    .attr("stroke-width", 2)
	    .attr("d", line);

	// Add points to the line
	chart.selectAll("circle")
	    .data(data)
	    .join("circle")
	    .attr("cx", d => x(d.label))
	    .attr("cy", d => y(d.value))
	    .attr("r", 4)
	    .attr("fill", "steelblue");

	// Add axes
	chart.append("g")
	    .call(d3.axisLeft(y));

	chart.append("g")
	    .attr("transform", `translate(0,\${height})`)
	    .call(d3.axisBottom(x))
	    .selectAll("text")
	    .attr("transform", "rotate(-45)")
	    .style("text-anchor", "end");
    </script>
</body>
</html>
HTML

    return $html;
}

=head2 render_line_chart_with_tooltips

    $html = $chart->render_line_chart_with_tooltips($data);

Generates HTML and JavaScript code to render a line chart with mouseover tooltips.
Accepts the following arguments:

=over 4

=item * C<$data> - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

=back

Returns a string containing the HTML and JavaScript code for the chart.
The JavaScript tooltip strings use C<< <\/b> >> (with a backslash) rather than
C<< </b> >> to satisfy html-tidy's requirement that C<< </ >> followed by a
letter not appear literally inside C<< <script> >> blocks.

=head3 Errors

=over 4

=item * Throws C<Data must be an array of arrays> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

    $self : HTML::D3                         -- required
    $data : ArrayRef[ ArrayRef[Str, Num] ]   -- required

=head4 Output

    Str -- complete HTML5 document; mouseover tooltip reveals label and value.
           Tooltip strings use C<< <\/b> >> not C<< </b> >>.

=cut

sub render_line_chart_with_tooltips
{
	my ($self, $data) = @_;

	# Validate input data
	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	# Generate JSON for data
	my $json_data = encode_json([
		map { { label => $_->[0], value => $_->[1] } } @$data
	]);

	# Generate HTML and D3.js code
	my $html = $self->_preamble();
	$html .= <<"HTML";
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$self->{title}</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
	.tooltip {
	    position: absolute;
	    background-color: white;
	    border: 1px solid #ccc;
	    padding: 5px;
	    font-size: 12px;
	    pointer-events: none;
	    opacity: 0;
	    transition: opacity 0.2s ease-in-out;
	}
    </style>
</head>
<body>
    <h1 style="text-align: center;">$self->{title}</h1>
    <svg id="chart" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
    <div class="tooltip" id="tooltip"></div>
    <script>
	const data = $json_data;

	const svg = d3.select("#chart");
	const tooltip = d3.select("#tooltip");
	const margin = { top: 20, right: 30, bottom: 40, left: 40 };
	const width = $self->{width} - margin.left - margin.right;
	const height = $self->{height} - margin.top - margin.bottom;

	const x = d3.scalePoint()
	    .domain(data.map(d => d.label))
	    .range([0, width]);

	const y = d3.scaleLinear()
	    .domain([0, d3.max(data, d => d.value)])
	    .nice()
	    .range([height, 0]);

	const chart = svg.append("g")
	    .attr("transform", `translate(\${margin.left},\${margin.top})`);

	// Draw line
	const line = d3.line()
	    .x(d => x(d.label))
	    .y(d => y(d.value));

	chart.append("path")
	    .datum(data)
	    .attr("fill", "none")
	    .attr("stroke", "steelblue")
	    .attr("stroke-width", 2)
	    .attr("d", line);

	// Add points to the line
	chart.selectAll("circle")
	    .data(data)
	    .join("circle")
	    .attr("cx", d => x(d.label))
	    .attr("cy", d => y(d.value))
	    .attr("r", 4)
	    .attr("fill", "steelblue")
	    .on("mouseover", (event, d) => {
		tooltip.style("opacity", 1)
		       .html(`Label: <b>\${d.label}<\\/b><br>Value: <b>\${d.value}<\\/b>`)
		       .style("left", (event.pageX + 10) + "px")
		       .style("top", (event.pageY - 30) + "px");
	    })
	    .on("mousemove", (event) => {
		tooltip.style("left", (event.pageX + 10) + "px")
		       .style("top", (event.pageY - 30) + "px");
	    })
	    .on("mouseout", () => {
		tooltip.style("opacity", 0);
	    });

	// Add axes
	chart.append("g")
	    .call(d3.axisLeft(y));

	chart.append("g")
	    .attr("transform", `translate(0,\${height})`)
	    .call(d3.axisBottom(x))
	    .selectAll("text")
	    .attr("transform", "rotate(-45)")
	    .style("text-anchor", "end");
    </script>
</body>
</html>
HTML

    return $html;
}

=head2 render_line_chart_snippet

    my $fragment = $chart->render_line_chart_snippet($data);
    # $fragment->{svg_id} - the id attribute of the <svg> element
    # $fragment->{html}   - embeddable HTML fragment (style + svg + script)

Generates an embeddable HTML fragment for a line chart with mouseover tooltips.
Unlike C<render_line_chart_with_tooltips>, this method returns a fragment with
no C<<!DOCTYPE>>, C<<html>>, C<<head>>, or C<<body>> wrapper, suitable for
splicing directly into a Mojolicious TT (or any other) layout.

The caller is responsible for loading D3 in the page C<<head>>, e.g.:

    <script src="https://d3js.org/d3.v7.min.js"></script>

Accepts the following arguments:

=over 4

=item * C<$data> - An array reference of data points. Each point is an array
reference with two required elements - the label (string) and the value
(numeric) - and an optional third element: a hash reference of extra key/value
pairs to display in the tooltip after the label and value rows.

    [$x, $y]          # basic point
    [$x, $y, \%row]   # point with extra tooltip data

=back

Returns a hash reference with:

=over 4

=item * C<svg_id> - The C<id> attribute used on the C<<svg>> element.

=item * C<html> - The embeddable fragment string.

=back

=cut

sub render_line_chart_snippet
{
	my ($self, $data) = @_;

	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	my $json_data = encode_json([
		map {
			my $point = { label => $_->[0], value => $_->[1] };
			$point->{extra} = $_->[2] if ref($_->[2]) eq 'HASH';
			$point
		} @$data
	]);

	my $svg_id = 'chart';

	my $html = <<"HTML";
<style>
    .tooltip {
	position: absolute;
	background-color: white;
	border: 1px solid #ccc;
	padding: 5px;
	font-size: 12px;
	pointer-events: none;
	opacity: 0;
	transition: opacity 0.2s ease-in-out;
    }
</style>
<svg id="$svg_id" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
<div class="tooltip" id="tooltip"></div>
<script>
    const data = $json_data;

    const svg = d3.select("#$svg_id");
    const tooltip = d3.select("#tooltip");
    const margin = { top: 20, right: 30, bottom: 40, left: 40 };
    const width = $self->{width} - margin.left - margin.right;
    const height = $self->{height} - margin.top - margin.bottom;

    const x = d3.scalePoint()
	.domain(data.map(d => d.label))
	.range([0, width]);

    const y = d3.scaleLinear()
	.domain([0, d3.max(data, d => d.value)])
	.nice()
	.range([height, 0]);

    const chart = svg.append("g")
	.attr("transform", `translate(\${margin.left},\${margin.top})`);

    const line = d3.line()
	.x(d => x(d.label))
	.y(d => y(d.value));

    chart.append("path")
	.datum(data)
	.attr("fill", "none")
	.attr("stroke", "steelblue")
	.attr("stroke-width", 2)
	.attr("d", line);

    chart.selectAll("circle")
	.data(data)
	.join("circle")
	.attr("cx", d => x(d.label))
	.attr("cy", d => y(d.value))
	.attr("r", 4)
	.attr("fill", "steelblue")
	.on("mouseover", (event, d) => {
	    let ttHtml = `Label: <b>\${d.label}<\\/b><br>Value: <b>\${d.value}<\\/b>`;
	    if (d.extra) {
		Object.entries(d.extra).forEach(([k, v]) => {
		    ttHtml += `<br>\${k}: <b>\${v}<\\/b>`;
		});
	    }
	    tooltip.style("opacity", 1)
		   .html(ttHtml)
		   .style("left", (event.pageX + 10) + "px")
		   .style("top", (event.pageY - 30) + "px");
	})
	.on("mousemove", (event) => {
	    tooltip.style("left", (event.pageX + 10) + "px")
		   .style("top", (event.pageY - 30) + "px");
	})
	.on("mouseout", () => {
	    tooltip.style("opacity", 0);
	});

    chart.append("g")
	.call(d3.axisLeft(y));

    chart.append("g")
	.attr("transform", `translate(0,\${height})`)
	.call(d3.axisBottom(x))
	.selectAll("text")
	.attr("transform", "rotate(-45)")
	.style("text-anchor", "end");
</script>
HTML

	return { svg_id => $svg_id, html => $html };
}

=head2 render_zoomable_line_chart_snippet

    my $fragment = $chart->render_zoomable_line_chart_snippet($data);
    # $fragment->{svg_id} - the id attribute of the <svg> element
    # $fragment->{html}   - embeddable HTML fragment (style + button + svg + script)

Like C<render_line_chart_snippet>, but adds brush-to-zoom: the user can drag
across a range of the x-axis to zoom into that region. A I<Reset zoom> button
(hidden until a zoom is active) returns the chart to its original extent.
Subsequent brushes on the zoomed view zoom in further; Reset always returns to
the full dataset.

The caller is responsible for loading D3 in the page C<<head>>.

Accepts the same arguments as C<render_line_chart_snippet>: an array reference
of data points, each C<[$x, $y]> or C<[$x, $y, \%extra]>.

=cut

sub render_zoomable_line_chart_snippet
{
	my ($self, $data) = @_;

	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	my $json_data = encode_json([
		map {
			my $point = { label => $_->[0], value => $_->[1] };
			$point->{extra} = $_->[2] if ref($_->[2]) eq 'HASH';
			$point
		} @$data
	]);

	my $svg_id = 'chart';
	my $tip_id = 'tooltip';
	my $rst_id = 'reset-btn';

	my $html = <<"HTML";
<style>
    .tooltip {
	position: absolute;
	background-color: white;
	border: 1px solid #ccc;
	padding: 5px;
	font-size: 12px;
	pointer-events: none;
	opacity: 0;
	transition: opacity 0.2s ease-in-out;
    }
    #$rst_id {
	display: none;
	margin-bottom: 4px;
	cursor: pointer;
    }
    .brush .selection {
	fill: steelblue;
	fill-opacity: 0.15;
	stroke: steelblue;
	stroke-width: 1;
    }
</style>
<button id="$rst_id">Reset zoom</button>
<svg id="$svg_id" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
<div class="tooltip" id="$tip_id"></div>
<script>
    const allData     = $json_data;
    let   currentData = allData.slice();

    const svg      = d3.select("#$svg_id");
    const tooltip  = d3.select("#$tip_id");
    const resetBtn = d3.select("#$rst_id");
    const margin   = { top: 20, right: 30, bottom: 40, left: 40 };
    const width    = $self->{width}  - margin.left - margin.right;
    const height   = $self->{height} - margin.top  - margin.bottom;

    const chart = svg.append("g")
	.attr("transform", `translate(\${margin.left},\${margin.top})`);

    // Scales (domain set in redraw)
    const x = d3.scalePoint().range([0, width]);
    const y = d3.scaleLinear().range([height, 0]);

    const lineFn = d3.line()
	.x(d => x(d.label))
	.y(d => y(d.value));

    // Brush appended first so circles sit above it and receive mouse events
    const brush = d3.brushX()
	.extent([[0, 0], [width, height]])
	.on("end", brushed);
    const brushGroup = chart.append("g").attr("class", "brush").call(brush);

    const linePath = chart.append("path")
	.attr("fill", "none")
	.attr("stroke", "steelblue")
	.attr("stroke-width", 2);

    const yAxisG = chart.append("g");
    const xAxisG = chart.append("g").attr("transform", `translate(0,\${height})`);

    function redraw(newData, ms) {
	x.domain(newData.map(d => d.label));
	y.domain([Math.min(0, d3.min(newData, d => d.value)), d3.max(newData, d => d.value)]).nice();

	const t = svg.transition().duration(ms);

	xAxisG.transition(t)
	    .call(d3.axisBottom(x))
	    .selectAll("text")
	    .attr("transform", "rotate(-45)")
	    .style("text-anchor", "end");

	yAxisG.transition(t).call(d3.axisLeft(y));

	linePath.datum(newData).transition(t).attr("d", lineFn);

	chart.selectAll("circle.pt")
	    .data(newData, d => d.label)
	    .join(
		enter => enter.append("circle")
		    .attr("class", "pt")
		    .attr("r", 4)
		    .attr("fill", "steelblue")
		    .attr("cx", d => x(d.label))
		    .attr("cy", d => y(d.value))
	    )
	    .on("mouseover", (event, d) => {
		let ttHtml = `Label: <b>\${d.label}<\\/b><br>Value: <b>\${d.value}<\\/b>`;
		if (d.extra) {
		    Object.entries(d.extra).forEach(([k, v]) => {
			ttHtml += `<br>\${k}: <b>\${v}<\\/b>`;
		    });
		}
		tooltip.style("opacity", 1)
		       .html(ttHtml)
		       .style("left", (event.pageX + 10) + "px")
		       .style("top",  (event.pageY - 30) + "px");
	    })
	    .on("mousemove", (event) => {
		tooltip.style("left", (event.pageX + 10) + "px")
		       .style("top",  (event.pageY - 30) + "px");
	    })
	    .on("mouseout", () => {
		tooltip.style("opacity", 0);
	    })
	    .transition(t)
	    .attr("cx", d => x(d.label))
	    .attr("cy", d => y(d.value));
    }

    redraw(currentData, 0);

    function brushed(event) {
	if (!event.selection) return;
	const [x0, x1] = event.selection;
	const zoomed = currentData.filter(d => {
	    const px = x(d.label);
	    return px >= x0 - 1 && px <= x1 + 1;
	});
	brushGroup.call(brush.move, null);   // clear brush rectangle
	if (zoomed.length < 2) return;
	currentData = zoomed;
	redraw(currentData, 500);
	resetBtn.style("display", "inline-block");
    }

    resetBtn.on("click", () => {
	currentData = allData.slice();
	redraw(currentData, 500);
	resetBtn.style("display", "none");
    });
</script>
HTML

	return { svg_id => $svg_id, html => $html };
}

=head2 render_multi_series_line_chart_with_tooltips

    $html = $chart->render_multi_series_line_chart_with_tooltips($data);

Generates HTML and JavaScript code to render a chart of many lines with mouseover tooltips.

Accepts the following arguments:

=over 4

=item * C<$data> - An array reference of series hashes. Each element is a hashref
with a C<name> key (string) and a C<data> key (array reference of C<< {label, value} >>
hashrefs).

    [
        { name => 'Series A', data => [{ label => 'Jan', value => 100 }, ...] },
        ...
    ]

=back

Returns a string containing the HTML and JavaScript code for the chart.
Tooltip strings use C<< <\/b> >> rather than C<< </b> >> for html-tidy compliance.

=head3 Errors

=over 4

=item * Throws C<Data must be an array of hashes> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

    $self : HTML::D3                                                   -- required
    $data : ArrayRef[ HashRef{ name: Str, data: ArrayRef[HashRef] } ] -- required

=head4 Output

    Str -- complete HTML5 document; one coloured line per series with mouseover tooltips.

=cut

sub render_multi_series_line_chart_with_tooltips
{
	my ($self, $data) = @_;

	# Validate input data
	die 'Data must be an array of hashes' unless ref($data) eq 'ARRAY';

	my $json_data = encode_json($data);

	# Generate HTML and D3.js code
	my $html = $self->_preamble();
	$html .= <<"HTML";
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$self->{title}</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
	.tooltip {
	    position: absolute;
	    background-color: white;
	    border: 1px solid #ccc;
	    padding: 5px;
	    font-size: 12px;
	    pointer-events: none;
	    opacity: 0;
	    transition: opacity 0.2s ease-in-out;
	}
    </style>
</head>
<body>
    <h1 style="text-align: center;">$self->{title}</h1>
    <svg id="chart" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
    <div class="tooltip" id="tooltip"></div>
    <script>
	const data = $json_data;

	const svg = d3.select("#chart");
	const tooltip = d3.select("#tooltip");
	const margin = { top: 20, right: 30, bottom: 40, left: 40 };
	const width = $self->{width} - margin.left - margin.right;
	const height = $self->{height} - margin.top - margin.bottom;

	const chart = svg.append("g")
	    .attr("transform", `translate(\${margin.left},\${margin.top})`);

	// Extract all labels and flatten them into a unique array
	const allLabels = Array.from(new Set(data.flatMap(series => series.data.map(d => d.label))));

	const x = d3.scalePoint()
	    .domain(allLabels)
	    .range([0, width]);

	const y = d3.scaleLinear()
	    .domain([0, d3.max(data.flatMap(series => series.data.map(d => d.value)))])
	    .nice()
	    .range([height, 0]);

	// Define color scale for series
	const color = d3.scaleOrdinal(d3.schemeCategory10);

	// Add axes
	chart.append("g")
	    .call(d3.axisLeft(y));

	chart.append("g")
	    .attr("transform", `translate(0,\${height})`)
	    .call(d3.axisBottom(x))
	    .selectAll("text")
	    .attr("transform", "rotate(-45)")
	    .style("text-anchor", "end");

	// Draw lines for each series
	data.forEach((series, i) => {
	    const line = d3.line()
		.x(d => x(d.label))
		.y(d => y(d.value));

	    // Add line
	    chart.append("path")
		.datum(series.data)
		.attr("fill", "none")
		.attr("stroke", color(i))
		.attr("stroke-width", 2)
		.attr("d", line);

	    // Add points and tooltips
	    chart.selectAll(\`circle.series-\${i}\`)
		.data(series.data)
		.join("circle")
		.attr("class", \`series-\${i}\`)
		.attr("cx", d => x(d.label))
		.attr("cy", d => y(d.value))
		.attr("r", 4)
		.attr("fill", color(i))
		.on("mouseover", (event, d) => {
		    tooltip.style("opacity", 1)
			   .html(\`Series: <b>\${series.name}<\\/b><br>Label: <b>\${d.label}<\\/b><br>Value: <b>\${d.value}<\\/b>\`)
			   .style("left", (event.pageX + 10) + "px")
			   .style("top", (event.pageY - 30) + "px");
		})
		.on("mousemove", (event) => {
		    tooltip.style("left", (event.pageX + 10) + "px")
			   .style("top", (event.pageY - 30) + "px");
		})
		.on("mouseout", () => {
		    tooltip.style("opacity", 0);
		});
	});
    </script>
</body>
</html>
HTML

    return $html;
}

=head2 render_multi_series_line_chart_with_animated_tooltips

    $html = $chart->render_multi_series_line_chart_with_animated_tooltips($data);

Generates HTML and JavaScript code to render a chart of many lines with animated mouseover tooltips.

Accepts the following arguments:

=over 4

=item * C<$data> - Same format as C<render_multi_series_line_chart_with_tooltips>:
an array reference of C<< { name, data } >> series hashes.

=back

Returns a string containing the complete HTML5 document.
The tooltip appears with a CSS C<translateY> slide-in animation.
Tooltip strings use C<< <\/b> >> for html-tidy compliance.

=head3 Errors

=over 4

=item * Throws C<Data must be an array of hashes> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

    $self : HTML::D3                                                   -- required
    $data : ArrayRef[ HashRef{ name: Str, data: ArrayRef[HashRef] } ] -- required

=head4 Output

    Str -- complete HTML5 document; animated tooltip uses CSS translateY transition.

=cut

sub render_multi_series_line_chart_with_animated_tooltips
{
	my ($self, $data) = @_;

	# Validate input data
	die 'Data must be an array of hashes' unless ref($data) eq 'ARRAY';

	# Generate JSON for data
	my $json_data = encode_json($data);

	# Generate HTML and D3.js code
	my $html = $self->_preamble();
	$html .= <<"HTML";
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$self->{title}</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
	.tooltip {
	    position: absolute;
	    background-color: white;
	    border: 1px solid #ccc;
	    padding: 5px;
	    font-size: 12px;
	    pointer-events: none;
	    opacity: 0;
	    transform: translateY(-10px);
	    transition: opacity 0.2s ease-in-out, transform 0.2s ease-in-out;
	}
    </style>
</head>
<body>
    <h1 style="text-align: center;">$self->{title}</h1>
    <svg id="chart" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
    <div class="tooltip" id="tooltip"></div>
    <script>
	const data = $json_data;

	const svg = d3.select("#chart");
	const tooltip = d3.select("#tooltip");
	const margin = { top: 20, right: 30, bottom: 40, left: 40 };
	const width = $self->{width} - margin.left - margin.right;
	const height = $self->{height} - margin.top - margin.bottom;

	const chart = svg.append("g")
	    .attr("transform", `translate(\${margin.left},\${margin.top})`);

	// Extract all labels and flatten them into a unique array
	const allLabels = Array.from(new Set(data.flatMap(series => series.data.map(d => d.label))));

	const x = d3.scalePoint()
	    .domain(allLabels)
	    .range([0, width]);

	const y = d3.scaleLinear()
	    .domain([0, d3.max(data.flatMap(series => series.data.map(d => d.value)))])
	    .nice()
	    .range([height, 0]);

	// Define color scale for series
	const color = d3.scaleOrdinal(d3.schemeCategory10);

	// Add axes
	chart.append("g")
	    .call(d3.axisLeft(y));

	chart.append("g")
	    .attr("transform", `translate(0,\${height})`)
	    .call(d3.axisBottom(x))
	    .selectAll("text")
	    .attr("transform", "rotate(-45)")
	    .style("text-anchor", "end");

	// Draw lines for each series
	data.forEach((series, i) => {
	    const line = d3.line()
		.x(d => x(d.label))
		.y(d => y(d.value));

	    // Add line
	    chart.append("path")
		.datum(series.data)
		.attr("fill", "none")
		.attr("stroke", color(i))
		.attr("stroke-width", 2)
		.attr("d", line);

	    // Add points and tooltips
	    chart.selectAll(\`circle.series-\${i}\`)
		.data(series.data)
		.join("circle")
		.attr("class", \`series-\${i}\`)
		.attr("cx", d => x(d.label))
		.attr("cy", d => y(d.value))
		.attr("r", 4)
		.attr("fill", color(i))
		.on("mouseover", (event, d) => {
		    tooltip.style("opacity", 1)
			   .style("transform", "translateY(0)")
			   .html(\`Series: <b>\${series.name}<\\/b><br>Label: <b>\${d.label}<\\/b><br>Value: <b>\${d.value}<\\/b>\`)
			   .style("left", (event.pageX + 10) + "px")
			   .style("top", (event.pageY - 30) + "px");
		})
		.on("mousemove", (event) => {
		    tooltip.style("left", (event.pageX + 10) + "px")
			   .style("top", (event.pageY - 30) + "px");
		})
		.on("mouseout", () => {
		    tooltip.style("opacity", 0)
			   .style("transform", "translateY(-10px)");
		});
	});
    </script>
</body>
</html>
HTML

    return $html;
}

=head2 render_multi_series_line_chart_with_legends

    $html = $chart->render_multi_series_line_chart_with_legends($data);

Generates HTML and JavaScript code to render a chart of many lines with a static
colour legend. Each series gets a labelled colour swatch in the legend area.

Accepts the following arguments:

=over 4

=item * C<$data> - Same format as C<render_multi_series_line_chart_with_tooltips>:
an array reference of C<< { name, data } >> series hashes.

=back

Returns a string containing the complete HTML5 document. The stylesheet defines
a C<.legend> CSS class used by the D3-generated legend elements.

=head3 Errors

=over 4

=item * Throws C<Data must be an array of hashes> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

    $self : HTML::D3                                                   -- required
    $data : ArrayRef[ HashRef{ name: Str, data: ArrayRef[HashRef] } ] -- required

=head4 Output

    Str -- complete HTML5 document; static colour legend rendered as SVG C<g> elements
           with the C<.legend> CSS class applied via D3 C<.attr("class", "legend")>.

=cut

sub render_multi_series_line_chart_with_legends {
	my($self, $data) = @_;

	# Validate input data
	die 'Data must be an array of hashes' unless ref($data) eq 'ARRAY';

	# Generate JSON for data
	my $json_data = encode_json($data);

	# Generate HTML and D3.js code
	my $html = $self->_preamble();
	$html .= <<"HTML";
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$self->{title}</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        .tooltip {
            position: absolute;
            background-color: white;
            border: 1px solid #ccc;
            padding: 5px;
            font-size: 12px;
            pointer-events: none;
            opacity: 0;
            transform: translateY(-10px);
            transition: opacity 0.2s ease-in-out, transform 0.2s ease-in-out;
        }
        .legend {
            font-size: 12px;
            cursor: pointer;
        }
        .legend rect {
            stroke-width: 1;
            stroke: #ccc;
        }
    </style>
</head>
<body>
    <h1 style="text-align: center;">$self->{title}</h1>
    <svg id="chart" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
    <div class="tooltip" id="tooltip"></div>
    <script>
        const data = $json_data;

        const svg = d3.select("#chart");
        const tooltip = d3.select("#tooltip");
        const margin = { top: 20, right: 120, bottom: 40, left: 40 };
        const width = $self->{width} - margin.left - margin.right;
        const height = $self->{height} - margin.top - margin.bottom;

        const chart = svg.append("g")
            .attr("transform", `translate(\${margin.left},\${margin.top})`);

        const legendArea = svg.append("g")
            .attr("transform", `translate(\${width + margin.left + 20},\${margin.top})`);

	// Extract all labels and flatten them into a unique array
        const allLabels = Array.from(new Set(data.flatMap(series => series.data.map(d => d.label))));

        const x = d3.scalePoint()
            .domain(allLabels)
            .range([0, width]);

        const y = d3.scaleLinear()
            .domain([0, d3.max(data.flatMap(series => series.data.map(d => d.value)))])
            .nice()
            .range([height, 0]);

	// Define color scale for series
        const color = d3.scaleOrdinal(d3.schemeCategory10);

        // Add axes
        chart.append("g")
            .call(d3.axisLeft(y));

        chart.append("g")
            .attr("transform", `translate(0,\${height})`)
            .call(d3.axisBottom(x))
            .selectAll("text")
            .attr("transform", "rotate(-45)")
            .style("text-anchor", "end");

        // Draw lines for each series
        data.forEach((series, i) => {
            const line = d3.line()
                .x(d => x(d.label))
                .y(d => y(d.value));

            // Add line
            chart.append("path")
                .datum(series.data)
                .attr("fill", "none")
                .attr("stroke", color(i))
                .attr("stroke-width", 2)
                .attr("class", \`line-\${i}\`)
                .attr("d", line);

            // Add points and tooltips
            chart.selectAll(\`circle.series-\${i}\`)
                .data(series.data)
                .join("circle")
                .attr("class", \`series-\${i}\`)
                .attr("cx", d => x(d.label))
                .attr("cy", d => y(d.value))
                .attr("r", 4)
                .attr("fill", color(i))
                .on("mouseover", (event, d) => {
                    tooltip.style("opacity", 1)
                           .style("transform", "translateY(0)")
                           .html(\`Series: <b>\${series.name}<\\/b><br>Label: <b>\${d.label}<\\/b><br>Value: <b>\${d.value}<\\/b>\`)
                           .style("left", (event.pageX + 10) + "px")
                           .style("top", (event.pageY - 30) + "px");
                })
                .on("mousemove", (event) => {
                    tooltip.style("left", (event.pageX + 10) + "px")
                           .style("top", (event.pageY - 30) + "px");
                })
                .on("mouseout", () => {
                    tooltip.style("opacity", 0)
                           .style("transform", "translateY(-10px)");
                });
        });

        // Add legend
        data.forEach((series, i) => {
            const legend = legendArea.append("g")
                .attr("transform", `translate(0, \${i * 20})`)
                .attr("class", "legend");

            legend.append("rect")
                .attr("width", 12)
                .attr("height", 12)
                .attr("fill", color(i));

            legend.append("text")
                .attr("x", 20)
                .attr("y", 10)
                .text(series.name)
                .style("alignment-baseline", "middle");

            // Optional: Interactive legend for toggling visibility (uncomment to use)
            // legend.on("click", () => {
            //     const visible = d3.selectAll(\`path.line-\${i}\`).style("opacity") === "1" ? 0 : 1;
            //     d3.selectAll(\`path.line-\${i}\`).style("opacity", visible);
            //     d3.selectAll(\`circle.series-\${i}\`).style("opacity", visible);
            // });
        });
    </script>
</body>
</html>
HTML

    return $html;
}

=head2 render_multi_series_line_chart_with_interactive_legends

    $html = $chart->render_multi_series_line_chart_with_interactive_legends($data);

Generates HTML and JavaScript code to render a chart of many lines with interactive legends to filter, highlight or modify elements based on legend selections.

Accepts the following arguments:

=over 4

=item * C<$data> - Same format as C<render_multi_series_line_chart_with_tooltips>:
an array reference of C<< { name, data } >> series hashes.

=back

Returns a string containing the complete HTML5 document. Clicking a legend entry
toggles that series' opacity using an C<isVisible> boolean flag in the D3 click
handler (opacity is set to C<isVisible ? 0 : 1> on each click).

=head3 Errors

=over 4

=item * Throws C<Data must be an array of hashes> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

    $self : HTML::D3                                                   -- required
    $data : ArrayRef[ HashRef{ name: Str, data: ArrayRef[HashRef] } ] -- required

=head4 Output

    Str -- complete HTML5 document; legend clicks toggle series visibility.
           The C<isVisible> JS variable tracks current visibility state.
           Opacity toggled by C<isVisible ? 0 : 1>.

=cut

sub render_multi_series_line_chart_with_interactive_legends
{
	my ($self, $data) = @_;

	# Validate input data
	die 'Data must be an array of hashes' unless ref($data) eq 'ARRAY';

	# Generate JSON for data
	my $json_data = encode_json($data);

	# Generate HTML and D3.js code
	my $html = $self->_preamble();
	$html .= <<"HTML";
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$self->{title}</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        .tooltip {
            position: absolute;
            background-color: white;
            border: 1px solid #ccc;
            padding: 5px;
            font-size: 12px;
            pointer-events: none;
            opacity: 0;
            transform: translateY(-10px);
            transition: opacity 0.2s ease-in-out, transform 0.2s ease-in-out;
        }
        .legend {
            font-size: 12px;
            cursor: pointer;
        }
        .legend rect {
            stroke-width: 1;
            stroke: #ccc;
        }
    </style>
</head>
<body>
    <h1 style="text-align: center;">$self->{title}</h1>
    <svg id="chart" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
    <div class="tooltip" id="tooltip"></div>
    <script>
        const data = $json_data;

        const svg = d3.select("#chart");
        const tooltip = d3.select("#tooltip");
        const margin = { top: 20, right: 150, bottom: 40, left: 40 };
        const width = $self->{width} - margin.left - margin.right;
        const height = $self->{height} - margin.top - margin.bottom;

        const chart = svg.append("g")
            .attr("transform", `translate(\${margin.left},\${margin.top})`);

        const legendArea = svg.append("g")
            .attr("transform", `translate(\${width + margin.left + 20},\${margin.top})`);

	 // Extract all labels and flatten them into a unique array
        const allLabels = Array.from(new Set(data.flatMap(series => series.data.map(d => d.label))));

        const x = d3.scalePoint()
            .domain(allLabels)
            .range([0, width]);

        const y = d3.scaleLinear()
            .domain([0, d3.max(data.flatMap(series => series.data.map(d => d.value)))])
            .nice()
            .range([height, 0]);

	// Define color scale for series
        const color = d3.scaleOrdinal(d3.schemeCategory10);

        // Add axes
        chart.append("g")
            .call(d3.axisLeft(y));

        chart.append("g")
            .attr("transform", `translate(0,\${height})`)
            .call(d3.axisBottom(x))
            .selectAll("text")
            .attr("transform", "rotate(-45)")
            .style("text-anchor", "end");

        // Draw lines for each series
        data.forEach((series, i) => {
            const line = d3.line()
                .x(d => x(d.label))
                .y(d => y(d.value));

            // Add line
            chart.append("path")
                .datum(series.data)
                .attr("fill", "none")
                .attr("stroke", color(i))
                .attr("stroke-width", 2)
                .attr("class", \`line-\${i}\`)
                .attr("d", line);

            // Add points and tooltips
            chart.selectAll(\`circle.series-\${i}\`)
                .data(series.data)
                .join("circle")
                .attr("class", \`series-\${i}\`)
                .attr("cx", d => x(d.label))
                .attr("cy", d => y(d.value))
                .attr("r", 4)
                .attr("fill", color(i))
                .on("mouseover", (event, d) => {
                    tooltip.style("opacity", 1)
                           .style("transform", "translateY(0)")
                           .html(\`Series: <b>\${series.name}<\\/b><br>Label: <b>\${d.label}<\\/b><br>Value: <b>\${d.value}<\\/b>\`)
                           .style("left", (event.pageX + 10) + "px")
                           .style("top", (event.pageY - 30) + "px");
                })
                .on("mousemove", (event) => {
                    tooltip.style("left", (event.pageX + 10) + "px")
                           .style("top", (event.pageY - 30) + "px");
                })
                .on("mouseout", () => {
                    tooltip.style("opacity", 0)
                           .style("transform", "translateY(-10px)");
                });
        });

        // Add legend with interactivity
        data.forEach((series, i) => {
            const legend = legendArea.append("g")
                .attr("transform", `translate(0, \${i * 20})`)
                .attr("class", "legend")
                .on("click", () => {
                    const isVisible = d3.selectAll(\`path.line-\${i}\`).style("opacity") === "1";

                    // Toggle visibility
                    d3.selectAll(\`path.line-\${i}\`).style("opacity", isVisible ? 0 : 1);
                    d3.selectAll(\`circle.series-\${i}\`).style("opacity", isVisible ? 0 : 1);

                    // Dim legend if series is hidden
                    legend.select("text").style("opacity", isVisible ? 0.5 : 1);
                });

            legend.append("rect")
                .attr("width", 12)
                .attr("height", 12)
                .attr("fill", color(i));

            legend.append("text")
                .attr("x", 20)
                .attr("y", 10)
                .text(series.name)
                .style("alignment-baseline", "middle");
        });
    </script>
</body>
</html>
HTML

    return $html;
}

sub _preamble
{
	my $html = <<'HTML';
<!DOCTYPE html>
<html lang="en">
HTML
	return $html;
}

sub _head
{
	my $self = shift;

	my $html = <<"HTML";
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>$self->{title}</title>
	<script src="https://d3js.org/d3.v7.min.js"></script>
</head>
HTML
	return $html;
}

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-html-d3 at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-D3>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc HTML::D3

You can also look for information at:

=head1 BUGS

It would help to have the render routine to return the head and body components separately.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/HTML-D3/coverage/>

=back

=head1 AUTHOR

Nigel Horne <njh@nigelhorne.com>

=encoding UTF-8

=head1 FORMAL SPECIFICATION

=head2 render_bar_chart

    render_bar_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  data = undef              ⇒ die "Data is not optional"
    pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post ∀ d ∈ data . d[0] ⊆ result

=head2 render_line_chart

    render_line_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "d3.scalePoint" ⊆ result ∧ "d3.line()" ⊆ result

=head2 render_lint_chart_with_tooltips

    render_line_chart_with_tooltips : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "mouseover" ⊆ result
    post "</b>" ∉ result ∧ "<\/b>" ∈ result

=head2 render_multi_series_line_chart_with_tooltips

    render_multi_series_line_chart_with_tooltips : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of hashes"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "</b>" ∉ result ∧ "<\/b>" ∈ result

=head2 render_multi_series_line_chart_with_animated_tooltips

    render_multi_series_line_chart_with_animated_tooltips : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'   ⇒ die "Data must be an array of hashes"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "translateY" ⊆ result
    post "</b>" ∉ result ∧ "<\/b>" ∈ result

=head2 render_multi_series_line_chart_with_legends

    render_multi_series_line_chart_with_legends : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of hashes"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post ".legend" ⊆ result

=head2 render_multi_series_line_chart_with_interactive_legends

    render_multi_series_line_chart_with_interactive_legends : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'            ⇒ die "Data must be an array of hashes"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "isVisible" ⊆ result
    post "isVisible ? 0 : 1" ⊆ result
    post ".legend" ⊆ result

=head1 LICENSE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
