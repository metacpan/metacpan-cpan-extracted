package HTML::D3;

use strict;
use warnings;

use JSON::MaybeXS;
use Scalar::Util;

=head1 NAME

HTML::D3 - A simple Perl module for generating charts using D3.js.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use HTML::D3;

    my $chart = HTML::D3->new(
	width  => 1024,
	height => 768,
	title  => 'Sample Bar Chart'
    );

    my $data = [
	['Category 1', 10],
	['Category 2', 20],
	['Category 3', 30]
    ];

    my $html = $chart->render_bar_chart($data);
    print $html;

    $chart = HTML::D3->new(title => 'Sales Data');

    my $data = [
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
	my %args;
	if((@_ == 1) && (ref $_[0] eq 'HASH')) {
		%args = %{$_[0]};
	} elsif((@_ % 2) == 0) {
		%args = @_;
	} else {
		carp(__PACKAGE__, ': Invalid arguments passed to new()');
		return;
	}

	if(!defined($class)) {
		if((scalar keys %args) > 0) {
			# Using HTML::D3->new(), not HTML::D3::new()
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %args }, ref($class);
	}

	# Return the blessed object
	return bless {
		width  => $args{width}  || 800,  # Default chart width
		height => $args{height} || 600,  # Default chart height
		title  => $args{title}  || 'Chart',  # Default chart title
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

=cut

# Method to render a bar chart with given data
sub render_bar_chart {
    my ($self, $data) = @_;

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
		       .html(`Label: <b>\${d.label}</b><br>Value: <b>\${d.value}</b>`)
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

=head2 render_multi_series_line_chart_with_tooltips

    $html = $chart->render_multi_series_line_chart_with_tooltips($data);

Generates HTML and JavaScript code to render a chart of many lines with mouseover tooltips.

Accepts the following arguments:

=over 4

=item * C<$data> - An reference to an array of hashes containing data points.
Each data point should be an array reference with two elements: the label (string) and the value (numeric).

=back

Returns a string containing the HTML and JavaScript code for the chart.

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
			   .html(\`Series: <b>\${series.name}</b><br>Label: <b>\${d.label}</b><br>Value: <b>\${d.value}</b>\`)
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

=item * C<$data> - An reference to an array of hashes containing data points.
Each data point should be an array reference with two elements: the label (string) and the value (numeric).

=back

Returns a string containing the HTML and JavaScript code for the chart.

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
			   .html(\`Series: <b>\${series.name}</b><br>Label: <b>\${d.label}</b><br>Value: <b>\${d.value}</b>\`)
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

=head1 BUGS

It would help to have the render routine to return the head and body components separately.

=head1 AUTHOR

Nigel Horne <njh@bandsman.co.uk>

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
