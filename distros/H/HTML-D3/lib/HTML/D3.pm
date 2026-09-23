package HTML::D3;

use 5.010;
use strict;
use warnings;

use Carp qw(carp);
use JSON::MaybeXS;

my $_JSON = JSON::MaybeXS->new(utf8 => 0);
use Object::Configure;
use Params::Get;
use Params::Validate::Strict;
use Scalar::Util qw(blessed looks_like_number);

=head1 NAME

HTML::D3 - A simple Perl module for generating charts using D3.js.

=head1 VERSION

Version 0.17

=cut

our $VERSION = '0.17';

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

The C<=head3 API SPECIFICATION> subsections use L<Params::Validate::Strict>
schema syntax (C<< type => 'arrayref' >> etc.) as a documentation convention.
The module is also used at runtime in C<new()> to validate constructor
arguments; it is therefore a required runtime dependency.  The schemas describe
the parameter contract in machine-readable notation and can be plumbed into a
WAF or test generator if desired.

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

sub new
{
	my $class = shift;

	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params(undef, \@_) || {},
		schema => {
			height => {
				type => 'integer',
				optional => 1,
				minimum => 1,
			}, width => {
				type => 'integer',
				optional => 1,
				minimum => 1,
			}, title => {
				type => 'string',
				optional => 1,
			}
		}
	});

	if(!defined($class)) {
		if((scalar keys %{$params}) > 0) {
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}
		# When called as HTML::D3::new(undef) with no args, default to the package.
		# Passing args via ::new() is unsupported and carps above.
		$class = __PACKAGE__;
	} elsif(blessed($class)) {
		return bless { %{$class}, %{$params} }, ref($class);
	}

	$params = Object::Configure::configure($class, $params);

	return bless {
		width  => $params->{width}  || 800,
		height => $params->{height} || 600,
		title  => $params->{title}  || 'Chart',
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

    {
        data => {
		type => 'arrayref',
		element_type => [ 'string', 'number' ]
	}
    }

    Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
    non-arrayref dies.

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
	my $json_data = $_JSON->encode([
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

=head2 render_animated_bar_chart

    my $html = $chart->render_animated_bar_chart($data);

Generates HTML and JavaScript code to render a bar chart where each bar grows
upward from the baseline on page load.  Bars are staggered so they rise
one-after-another from left to right.
Accepts the following arguments:

=over 4

=item * C<$data> - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).

=back

Returns a string containing the complete HTML5 document.

=head3 Errors

=over 4

=item * Throws C<Data is not optional> when C<$data> is C<undef>.

=item * Throws C<Data must be an array of arrays> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
    non-arrayref dies.

=head4 Output

    Str -- complete HTML5 document; each bar animates from height=0 upward
           using C<d3.transition()> with a staggered per-bar delay.

=cut

sub render_animated_bar_chart {
	my ($self, $data) = @_;

	die 'Data is not optional' if(!defined($data));
	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	my $json_data = $_JSON->encode([
		map { { label => $_->[0], value => $_->[1] } } @$data
	]);

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

	// Each bar starts at the baseline (y=height, height=0) and grows upward.
	chart.append("g")
	    .selectAll("rect")
	    .data(data)
	    .join("rect")
	    .attr("x", d => x(d.label))
	    .attr("y", height)
	    .attr("height", 0)
	    .attr("width", x.bandwidth())
	    .attr("fill", "steelblue")
	    .transition()
	    .duration(800)
	    .delay((d, i) => i * 100)
	    .attr("y", d => y(d.value))
	    .attr("height", d => height - y(d.value));

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

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
    non-arrayref dies.

=head4 Output

    Str -- complete HTML5 document; line chart with C<d3.scalePoint> and C<d3.line()>.

=cut

sub render_line_chart {
	my ($self, $data) = @_;

	# Validate input data
	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	# Generate JSON for data
	my $json_data = $_JSON->encode([
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

=head2 render_animated_line_chart

    my $html = $chart->render_animated_line_chart($data);

Generates HTML and JavaScript code to render a line chart where the line
draws itself from left to right on page load, followed by each data-point
circle fading in once the line is complete.
Accepts the following arguments:

=over 4

=item * C<$data> - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).

=back

Returns a string containing the complete HTML5 document.

=head3 Errors

=over 4

=item * Throws C<Data must be an array of arrays> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
    non-arrayref dies.

=head4 Output

    Str -- complete HTML5 document; the line path animates via
           C<stroke-dashoffset> with C<d3.easeLinear>; data-point circles
           fade in with C<opacity> after the line transition completes.

=cut

sub render_animated_line_chart {
	my ($self, $data) = @_;

	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	my $json_data = $_JSON->encode([
		map { { label => $_->[0], value => $_->[1] } } @$data
	]);

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

	const line = d3.line()
	    .x(d => x(d.label))
	    .y(d => y(d.value));

	// Animate the line drawing left-to-right using stroke-dashoffset.
	const path = chart.append("path")
	    .datum(data)
	    .attr("fill", "none")
	    .attr("stroke", "steelblue")
	    .attr("stroke-width", 2)
	    .attr("d", line);

	const totalLength = path.node().getTotalLength();

	path
	    .attr("stroke-dasharray", totalLength)
	    .attr("stroke-dashoffset", totalLength)
	    .transition()
	    .duration(1500)
	    .ease(d3.easeLinear)
	    .attr("stroke-dashoffset", 0);

	// Data-point circles fade in after the line finishes.
	chart.selectAll("circle")
	    .data(data)
	    .join("circle")
	    .attr("cx", d => x(d.label))
	    .attr("cy", d => y(d.value))
	    .attr("r", 4)
	    .attr("fill", "steelblue")
	    .attr("opacity", 0)
	    .transition()
	    .delay(1500)
	    .duration(300)
	    .attr("opacity", 1);

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

=head2 render_pie_chart

    my $html = $chart->render_pie_chart($data);
    my $html = $chart->render_pie_chart($data, { separator => ':' });

Generates HTML and JavaScript code to render a pie chart.
Each slice is coloured with C<d3.schemeCategory10>; percentage labels appear
inside each slice and a colour legend is shown to the right of the pie.
Accepts the following arguments:

=over 4

=item * C<$data> - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).

=item * C<%opts> - Optional hashref of options.

=over 8

=item * C<separator> (string, default C<'/'>) - Character shown between the
label and value in the SVG legend.

=back

=back

Returns a string containing the complete HTML5 document.

=head3 Errors

=over 4

=item * Throws C<Data is not optional> when C<$data> is C<undef>.

=item * Throws C<Data must be an array of arrays> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

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

=head4 Output

    Str -- complete HTML5 document; pie rendered with C<d3.pie()> and
           C<d3.arc()>; slices coloured with C<d3.schemeCategory10>;
           percentage label inside each slice; legend to the right.

=cut

sub render_pie_chart {
	my ($self, $data, $opts) = @_;
	$opts //= {};

	die 'Data is not optional' if(!defined($data));
	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	my $separator = $opts->{separator} // '/';

	my $json_data = $_JSON->encode([
		map { { label => $_->[0], value => $_->[1] } } @$data
	]);

	my $html = $self->_preamble();
	$html .= $self->_head();
	$html .= <<"HTML";
<body>
    <h1 style="text-align: center;">$self->{title}</h1>
    <svg id="chart" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
    <script>
	const data = $json_data;

	const width = $self->{width};
	const height = $self->{height};
	const radius = Math.min(width, height) / 2 - 40;

	const color = d3.scaleOrdinal(d3.schemeCategory10);

	const pie = d3.pie()
	    .sort(null)
	    .value(d => d.value);

	const arc = d3.arc()
	    .innerRadius(0)
	    .outerRadius(radius);

	const labelArc = d3.arc()
	    .innerRadius(radius * 0.65)
	    .outerRadius(radius * 0.65);

	const total = d3.sum(data, d => d.value);

	const svg = d3.select("#chart");

	const pieGroup = svg.append("g")
	    .attr("transform", `translate(\${width * 0.45},\${height / 2})`);

	const arcs = pieGroup.selectAll(".arc")
	    .data(pie(data))
	    .join("g")
	    .attr("class", "arc");

	arcs.append("path")
	    .attr("d", arc)
	    .attr("fill", d => color(d.data.label))
	    .attr("stroke", "white")
	    .style("stroke-width", "2px");

	arcs.append("text")
	    .attr("transform", d => `translate(\${labelArc.centroid(d)})`)
	    .attr("text-anchor", "middle")
	    .attr("font-size", "11px")
	    .attr("fill", "white")
	    .attr("pointer-events", "none")
	    .text(d => Math.round(d.data.value / total * 100) + "%");

	// Legend
	const legend = svg.append("g")
	    .attr("transform", `translate(\${width * 0.72},\${(height - data.length * 22) / 2})`);

	legend.selectAll("rect")
	    .data(pie(data))
	    .join("rect")
	    .attr("x", 0)
	    .attr("y", (d, i) => i * 22)
	    .attr("width", 14)
	    .attr("height", 14)
	    .attr("fill", d => color(d.data.label));

	legend.selectAll("text")
	    .data(pie(data))
	    .join("text")
	    .attr("x", 20)
	    .attr("y", (d, i) => i * 22 + 11)
	    .attr("font-size", "12px")
	    .text(d => `\${d.data.label} $separator \${d.data.value}`);
    </script>
</body>
</html>
HTML

	return $html;
}

=head2 render_animated_pie_chart

    my $html = $chart->render_animated_pie_chart($data);
    my $html = $chart->render_animated_pie_chart($data, { separator => ':' });

Generates HTML and JavaScript code to render an animated pie chart where each
slice fans out from zero angle on page load using C<attrTween> and
C<d3.interpolate>.  Percentage labels fade in once all slices are drawn.
Accepts the following arguments:

=over 4

=item * C<$data> - An array reference of data points.  Each data point is an
array reference with two elements: the label (string) and the value (numeric).

=item * C<%opts> - Optional hashref of options.

=over 8

=item * C<separator> (string, default C<'/'>) - Character shown between the
label and value in the SVG legend.

=back

=back

Returns a string containing the complete HTML5 document.

=head3 Errors

=over 4

=item * Throws C<Data is not optional> when C<$data> is C<undef>.

=item * Throws C<Data must be an array of arrays> when C<$data> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

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

=head4 Output

    Str -- complete HTML5 document; slices animate via C<attrTween> with
           C<d3.interpolate> (1000 ms); percentage labels fade in afterwards.

=cut

sub render_animated_pie_chart {
	my ($self, $data, $opts) = @_;
	$opts //= {};

	die 'Data is not optional' if(!defined($data));
	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	my $separator = $opts->{separator} // '/';

	my $json_data = $_JSON->encode([
		map { { label => $_->[0], value => $_->[1] } } @$data
	]);

	my $html = $self->_preamble();
	$html .= $self->_head();
	$html .= <<"HTML";
<body>
    <h1 style="text-align: center;">$self->{title}</h1>
    <svg id="chart" width="$self->{width}" height="$self->{height}" style="border: 1px solid black;"></svg>
    <script>
	const data = $json_data;

	const width = $self->{width};
	const height = $self->{height};
	const radius = Math.min(width, height) / 2 - 40;

	const color = d3.scaleOrdinal(d3.schemeCategory10);

	const pie = d3.pie()
	    .sort(null)
	    .value(d => d.value);

	const arc = d3.arc()
	    .innerRadius(0)
	    .outerRadius(radius);

	const labelArc = d3.arc()
	    .innerRadius(radius * 0.65)
	    .outerRadius(radius * 0.65);

	const total = d3.sum(data, d => d.value);

	const svg = d3.select("#chart");

	const pieGroup = svg.append("g")
	    .attr("transform", `translate(\${width * 0.45},\${height / 2})`);

	const arcs = pieGroup.selectAll(".arc")
	    .data(pie(data))
	    .join("g")
	    .attr("class", "arc");

	// Each slice fans out from zero angle using attrTween.
	arcs.append("path")
	    .attr("fill", d => color(d.data.label))
	    .attr("stroke", "white")
	    .style("stroke-width", "2px")
	    .transition()
	    .duration(1000)
	    .attrTween("d", function(d) {
		const i = d3.interpolate({ startAngle: 0, endAngle: 0 }, d);
		return t => arc(i(t));
	    });

	// Percentage labels fade in after slices finish drawing.
	arcs.append("text")
	    .attr("transform", d => `translate(\${labelArc.centroid(d)})`)
	    .attr("text-anchor", "middle")
	    .attr("font-size", "11px")
	    .attr("fill", "white")
	    .attr("pointer-events", "none")
	    .attr("opacity", 0)
	    .text(d => Math.round(d.data.value / total * 100) + "%")
	    .transition()
	    .delay(1000)
	    .duration(300)
	    .attr("opacity", 1);

	// Legend
	const legend = svg.append("g")
	    .attr("transform", `translate(\${width * 0.72},\${(height - data.length * 22) / 2})`);

	legend.selectAll("rect")
	    .data(pie(data))
	    .join("rect")
	    .attr("x", 0)
	    .attr("y", (d, i) => i * 22)
	    .attr("width", 14)
	    .attr("height", 14)
	    .attr("fill", d => color(d.data.label));

	legend.selectAll("text")
	    .data(pie(data))
	    .join("text")
	    .attr("x", 20)
	    .attr("y", (d, i) => i * 22 + 11)
	    .attr("font-size", "12px")
	    .text(d => `\${d.data.label} $separator \${d.data.value}`);
    </script>
</body>
</html>
HTML

	return $html;
}

=head2 render_pie_chart_snippet

    my $fragment = $chart->render_pie_chart_snippet(\@slices);
    my $fragment = $chart->render_pie_chart_snippet(\@slices, \%opts);
    # $fragment->{svg_id} - always 'pie_chart'
    # $fragment->{html}   - embeddable fragment; caller must load D3 v7

Generates an embeddable pie or donut chart fragment for use in existing HTML
layouts.  Returns C<{ svg_id =E<gt> 'pie_chart', html =E<gt> Str }>.  The
caller is responsible for loading D3 v7 before embedding the fragment.

=head3 Data format

Each element of C<\@slices> is C<[$label, $value]> or C<[$label, $value, \%extra]>.
Negative values are silently converted to their absolute value.  Zero-value
slices are silently omitted.  C<\%extra> key/value pairs are shown as
additional rows in the hover tooltip.

=head3 Options (C<\%opts>)

=over 4

=item * C<animated> (bool, default 0) - fan slices in from arc-length 0 on
first render using C<attrTween> / C<d3.easeBackOut> (800 ms, staggered).
Respects C<prefers-reduced-motion>.

=item * C<donut> (bool, default 0) - render as a donut chart (inner radius
38% of outer radius); the total sum appears in the centre hole.

=item * C<sort_slices> (string, default C<'none'>) - C<'value'> for
largest-first, C<'label'> for alphabetical, C<'none'> for input order.

=item * C<max_slices> (int, default 0) - when E<gt> 0, only the top N-1
slices are shown individually; the rest are collapsed into an C<"Other"> slice.

=item * C<legend> (bool, default 1) - render an HTML legend panel beside the chart.

=item * C<color_scheme> (string, default C<'tableau10'>) - D3 categorical
colour scheme.  Supported: C<tableau10>, C<category10>, C<set2>, C<set3>,
C<paired>.

=item * C<separator> (string, default C<'/'>) - Character shown between the
label and value in each legend entry (e.g. C<'/'> produces
C<Label / 12.34 (42.0%)>, C<':'> produces C<Label : 12.34 (42.0%)>).

=back

=head3 Errors

=over 4

=item * Throws C<Data must be an array of arrays> when C<\@slices> is not an ARRAY reference.

=back

=head3 Side Effects

None.

=head3 API SPECIFICATION

=head4 Input

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

=head4 Output

    HashRef -- C<{ svg_id =E<gt> 'pie_chart', html =E<gt> Str }>;
               embeddable fragment; no DOCTYPE, no page shell, no D3 CDN tag.

=cut

sub render_pie_chart_snippet {
	my ($self, $data, $opts) = @_;
	$opts //= {};

	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	my $animated     = $opts->{animated}    ? 1 : 0;
	my $donut        = $opts->{donut}       ? 1 : 0;
	my $sort_slices  = $opts->{sort_slices} // 'none';
	my $max_slices   = int($opts->{max_slices} // 0);
	my $show_legend  = exists $opts->{legend} ? ($opts->{legend} ? 1 : 0) : 1;
	my $color_scheme = $opts->{color_scheme} // 'tableau10';
	my $separator    = $opts->{separator}   // '/';

	# Normalise: absolute values, drop zeros, pull optional extra hashref
	my @slices;
	for my $pt (@$data) {
		my $val = abs($pt->[1] // 0);
		next if $val == 0;
		my %s = (label => $pt->[0], value => $val);
		$s{extra} = $pt->[2] if ref($pt->[2]) eq 'HASH';
		push @slices, \%s;
	}

	# Sort before max_slices so the "top N" is stable
	if ($sort_slices eq 'value') {
		@slices = sort { $b->{value} <=> $a->{value} } @slices;
	} elsif ($sort_slices eq 'label') {
		@slices = sort { $a->{label} cmp $b->{label} } @slices;
	}

	# Collapse tail into "Other"
	if ($max_slices >= 2 && scalar(@slices) > $max_slices) {
		my @by_val = sort { $b->{value} <=> $a->{value} } @slices;
		my @top    = @by_val[0 .. $max_slices - 2];
		my $other  = 0;
		$other += $_->{value} for @by_val[$max_slices - 1 .. $#by_val];
		push @top, { label => 'Other', value => $other };
		@slices = @top;
	}

	my $json_data = $_JSON->encode(\@slices);

	my $svg_id   = 'pie_chart';
	my $tip_id   = 'pie_chart_tip';
	my $leg_id   = 'pie_chart_legend';
	my $wrap_id  = 'pie_chart_wrap';
	my $width    = $self->{width};
	my $height   = $self->{height};

	my $inner_radius_js = $donut ? 'radius * 0.38' : '0';

	# Animation initialisation (empty when not animated)
	my $anim_init_js = $animated
		? 'var noAnim = window.matchMedia("(prefers-reduced-motion: reduce)").matches;' . "\n" .
		  "    let initialDrawDone = false;\n"
		: '';

	# Legend fade-in as part of the animation block
	my $legend_anim_js = ($animated && $show_legend) ? <<"LANIM" : '';
        d3.select("#$leg_id")
            .style("opacity", 0)
            .transition()
            .delay(data.length * 60 + 100)
            .duration(300)
            .style("opacity", 1);
LANIM

	# Path drawing code — animated vs plain
	my $anim_draw_js;
	if ($animated) {
		$anim_draw_js = <<"ANIM_DRAW";
    if (!initialDrawDone && !noAnim) {
        paths.attr("d", arc({ startAngle: 0, endAngle: 0 }))
            .transition()
            .duration(800)
            .ease(d3.easeBackOut.overshoot(1.2))
            .delay((d, i) => Math.min(i * 60, 300))
            .attrTween("d", function(d) {
                var interp = d3.interpolate({ startAngle: 0, endAngle: 0 }, d);
                return function(t) { return arc(interp(t)); };
            });
$legend_anim_js        initialDrawDone = true;
    } else {
        paths.attr("d", arc);
    }
ANIM_DRAW
	} else {
		$anim_draw_js = "    paths.attr(\"d\", arc);\n";
	}

	# Centre label in donut hole
	my $donut_center_js = $donut ? <<'DONUT' : '';
    pieGroup.append("text")
        .attr("text-anchor", "middle")
        .attr("dominant-baseline", "middle")
        .attr("font-size", "16px")
        .attr("font-weight", "bold")
        .text(fmt(total));
DONUT

	# HTML legend panel — built by D3 against the legend div
	# Single-quote heredoc so JS template-literal ${...} is preserved verbatim
	my $legend_section_js = $show_legend ? <<"LEGEND_JS" : '';
    d3.select("#$leg_id")
        .selectAll(".bi-pie-legend-entry")
        .data(pieSlices)
        .join("div")
        .attr("class", "bi-pie-legend-entry")
        .attr("data-slice-index", (d, i) => i)
        .html((d, i) => {
            const pct = (d.data.value / total * 100).toFixed(1);
            const sw = '<span class="bi-pie-swatch" style="background:' + color(d.data.label) + '"></span>';
            return sw + ' ' + d.data.label + ' $separator ' + fmt(d.data.value) + ' (' + pct + '%)';
        });
LEGEND_JS

	my $legend_div_html = $show_legend
		? qq(    <div id="$leg_id" class="bi-pie-legend"></div>\n)
		: '';

	my $html = <<"HTML";
<style>
    #$wrap_id {
	display: flex;
	flex-wrap: wrap;
	align-items: center;
    }
    .bi-pie-legend {
	padding-left: 16px;
	font-size: 13px;
    }
    .bi-pie-legend-entry {
	margin: 4px 0;
	white-space: nowrap;
    }
    .bi-pie-swatch {
	display: inline-block;
	width: 12px;
	height: 12px;
	border-radius: 2px;
	vertical-align: middle;
	margin-right: 4px;
    }
    .bi-pie-tooltip {
	position: absolute;
	background: rgba(255,255,255,0.95);
	border: 1px solid #ccc;
	border-radius: 4px;
	padding: 6px 10px;
	font-size: 12px;
	pointer-events: none;
	display: none;
	line-height: 1.6;
    }
</style>
<div id="$wrap_id">
    <svg id="$svg_id" width="$width" height="$height"></svg>
$legend_div_html</div>
<div class="bi-pie-tooltip" id="$tip_id"></div>
<script>
    const data = $json_data;

    const SCHEMES = {
        tableau10:  d3.schemeTableau10,
        category10: d3.schemeCategory10,
        set2:       d3.schemeSet2,
        set3:       d3.schemeSet3,
        paired:     d3.schemePaired,
    };
    const color = d3.scaleOrdinal(SCHEMES['$color_scheme'] || d3.schemeTableau10)
        .domain(data.map(d => d.label));

    const width  = $width;
    const height = $height;
    const radius = Math.min(width, height) / 2 - 40;
    const innerRadius = $inner_radius_js;

    const arc      = d3.arc().innerRadius(innerRadius).outerRadius(radius);
    const labelArc = d3.arc().innerRadius(radius * 0.7).outerRadius(radius * 0.7);

    const pie = d3.pie().sort(null).value(d => d.value);
    const pieSlices = pie(data);

    const total = d3.sum(data, d => d.value);
    const fmt   = d3.format(",.2f");

    $anim_init_js
    const svg     = d3.select("#$svg_id");
    const tooltip = d3.select("#$tip_id");

    const pieGroup = svg.append("g")
        .attr("transform", \`translate(\${$width * 0.5},\${$height / 2})\`);

    const arcs = pieGroup.selectAll(".arc")
        .data(pieSlices)
        .join("g")
        .attr("class", "arc");

    const paths = arcs.append("path")
        .attr("fill", d => color(d.data.label))
        .attr("stroke", "white")
        .style("stroke-width", "2px")
        .attr("data-label", d => d.data.label)
        .attr("data-value", d => d.data.value)
        .on("mouseover", function(event, d) {
            const pct = (d.data.value / total * 100).toFixed(1);
            let tip = "<b>" + d.data.label + "<\\/b><br>" +
                      fmt(d.data.value) + " (" + pct + "%)";
            if (d.data.extra) {
                Object.entries(d.data.extra).forEach(([k, v]) => {
                    tip += "<br>" + k + ": " + v;
                });
            }
            tooltip.html(tip)
                   .style("display", "block")
                   .style("left", (event.pageX + 12) + "px")
                   .style("top",  (event.pageY - 24) + "px");
        })
        .on("mousemove", function(event) {
            tooltip.style("left", (event.pageX + 12) + "px")
                   .style("top",  (event.pageY - 24) + "px");
        })
        .on("mouseout", function() {
            tooltip.style("display", "none");
        });

$anim_draw_js
$donut_center_js
$legend_section_js</script>
HTML

	return { svg_id => $svg_id, html => $html };
}

=head2 render_heatmap_snippet

    my $fragment = $chart->render_heatmap_snippet(\@triples);
    my $fragment = $chart->render_heatmap_snippet(\@triples, \%opts);
    # $fragment->{svg_id} - always 'heatmap'
    # $fragment->{html}   - embeddable fragment; caller must load D3 v7

Generates an embeddable grid heatmap for use in existing HTML layouts.
Each cell sits at the intersection of an X-axis label and a Y-axis label;
its colour encodes the cell's numeric value using a sequential D3 colour
scale.  Returns C<{ svg_id =E<gt> 'heatmap', html =E<gt> Str }>.  The
caller is responsible for loading D3 v7 before embedding the fragment.

=head3 Data format

Each element of C<\@triples> is C<[$x_label, $y_label, $value]>.
C<$value> must be numeric or C<undef> (C<undef> rows are silently
skipped).  Zero is a valid value and maps to the lightest cell colour.
The caller is responsible for any aggregation: if multiple triples share
the same (x_label, y_label) pair, the last one wins.

=head3 Options (C<\%opts>)

=over 4

=item * C<color_scheme> (string, default C<'YlOrRd'>) - D3 sequential
colour scheme.  Supported: C<YlOrRd>, C<Blues>, C<Greens>, C<Purples>,
C<RdPu>, C<YlGnBu>.

=item * C<x_label> (string, default C<''>) - Axis title below the X axis.

=item * C<y_label> (string, default C<''>) - Axis title left of the Y axis.

=item * C<val_label> (string, default C<'Value'>) - Tooltip value label.

=item * C<show_values> (bool, default 0) - Print value inside each cell.
Auto-suppressed when any cell is narrower than 28 px.

=item * C<cell_padding> (int 0-8, default 2) - Gap in pixels between cells.

=item * C<legend> (bool, default 1) - Render a colour-scale legend bar.

=item * C<animated> (bool, default 0) - Fade cells in on first load.
Respects C<prefers-reduced-motion>.

=back

=head3 Errors

=over 4

=item * Dies with C<Data must be an array of arrays> when C<\@triples>
is not an ARRAY reference.

=item * Dies with C<Each data point must be an array reference> when a
triple element is not an arrayref.

=item * Dies with C<Each data point must have at least 3 elements> when
a triple has fewer than 3 elements.

=item * Dies with C<Value must be numeric> when C<$value> is defined but
not numeric.

=item * Dies with C<Unknown color_scheme: E<lt>nameE<gt>> for an
unsupported C<color_scheme> value.

=item * Dies with C<cell_padding must be between 0 and 8> when
C<cell_padding> is outside the valid range.

=back

=head3 Side Effects

Appends a tooltip C<div> to the page when the fragment is rendered in
the browser.

=head3 API SPECIFICATION

=head4 Input

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

=head4 Output

    HashRef -- C<{ svg_id =E<gt> 'heatmap', html =E<gt> Str }>;
               embeddable fragment; no DOCTYPE, no page shell, no D3 CDN tag.

=cut

sub render_heatmap_snippet {
	my ($self, $data, $opts) = @_;
	$opts //= {};

	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	my %color_scheme_map = (
		YlOrRd  => 'd3.interpolateYlOrRd',
		Blues   => 'd3.interpolateBlues',
		Greens  => 'd3.interpolateGreens',
		Purples => 'd3.interpolatePurples',
		RdPu    => 'd3.interpolateRdPu',
		YlGnBu  => 'd3.interpolateYlGnBu',
	);

	my $color_scheme = $opts->{color_scheme} // 'YlOrRd';
	die "Unknown color_scheme: $color_scheme"
		unless exists $color_scheme_map{$color_scheme};
	my $d3_interpolator = $color_scheme_map{$color_scheme};

	my $cell_padding = defined($opts->{cell_padding}) ? int($opts->{cell_padding}) : 2;
	die 'cell_padding must be between 0 and 8'
		unless $cell_padding >= 0 && $cell_padding <= 8;

	my $x_label    = $opts->{x_label}    // '';
	my $y_label    = $opts->{y_label}    // '';
	my $val_label  = $opts->{val_label}  // 'Value';
	my $show_values = $opts->{show_values} ? 1 : 0;
	my $legend     = exists $opts->{legend} ? ($opts->{legend} ? 1 : 0) : 1;
	my $animated   = $opts->{animated}   ? 1 : 0;

	my @triples;
	for my $pt (@$data) {
		die 'Each data point must be an array reference'
			unless ref($pt) eq 'ARRAY';
		die 'Each data point must have at least 3 elements'
			unless scalar(@$pt) >= 3;
		next unless defined $pt->[2];
		die 'Value must be numeric' unless looks_like_number($pt->[2]);
		push @triples, { x => $pt->[0], y => $pt->[1], v => $pt->[2] + 0 };
	}

	my $json_data = $_JSON->encode(\@triples);

	# encode_json only accepts refs; escape label strings manually for JS
	my ($x_label_esc, $y_label_esc, $val_label_esc) = map {
		my $s = $_;
		$s =~ s/\\/\\\\/g;
		$s =~ s/"/\\"/g;
		$s =~ s/\n/\\n/g;
		$s =~ s/\r/\\r/g;
		$s
	} ($x_label, $y_label, $val_label);

	my $svg_id = 'heatmap';
	my $tip_id = 'heatmap_tip';

	my $width  = $self->{width};
	my $height = $self->{height};

	my $margin_top    = 30;
	my $margin_right  = $legend ? 65 : 20;
	my $margin_bottom = $x_label ? 60 : 40;
	my $margin_left   = $y_label ? 80 : 60;
	my $inner_w = $width  - $margin_left - $margin_right;
	my $inner_h = $height - $margin_top  - $margin_bottom;

	my $anim_block = $animated ? <<"ANIM" : '';
    var noAnim = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (!noAnim) {
        cellGs.attr("opacity", 0)
            .transition()
            .duration(300)
            .delay(function(d) { return yMap.get(d.y) * 50; })
            .attr("opacity", 1);
    }
ANIM

	my $legend_block = $legend ? <<"LEGBLOCK" : '';
    {
        var defs = svg.append("defs");
        var lgId = "heatmap-lg";
        var lg = defs.append("linearGradient")
            .attr("id", lgId)
            .attr("x1", "0").attr("y1", "1")
            .attr("x2", "0").attr("y2", "0");
        for (var i = 0; i <= 6; i++) {
            lg.append("stop")
                .attr("offset", (i / 6 * 100) + "%")
                .attr("stop-color", colorScale(maxV * i / 6));
        }
        var lgX = margin.left + innerW + 15;
        var lgBarH = Math.min(innerH, 150);
        var lgBarY = margin.top + (innerH - lgBarH) / 2;
        svg.append("rect")
            .attr("x", lgX)
            .attr("y", lgBarY)
            .attr("width", 12)
            .attr("height", lgBarH)
            .attr("fill", "url(#" + lgId + ")");
        var lgScale = d3.scaleLinear().domain([0, maxV]).range([lgBarH, 0]);
        svg.append("g")
            .attr("transform", "translate(" + (lgX + 12) + "," + lgBarY + ")")
            .call(d3.axisRight(lgScale).ticks(4));
    }
LEGBLOCK

	my $html = <<"HTML";
<style>
    #$svg_id { display: block; }
    #$tip_id {
	position: absolute;
	background: rgba(255,255,255,0.95);
	border: 1px solid #ccc;
	border-radius: 4px;
	padding: 6px 10px;
	font-size: 12px;
	pointer-events: none;
	display: none;
	line-height: 1.6;
    }
    .hm-cell-text {
	font-size: 10px;
	fill: #222;
	pointer-events: none;
	text-anchor: middle;
	dominant-baseline: middle;
    }
</style>
<svg id="$svg_id" width="$width" height="$height"></svg>
<div id="$tip_id"></div>
<script>
(function() {
    var data = $json_data;
    var cellPad = $cell_padding;
    var showVals0 = $show_values;
    var xLabelStr = "$x_label_esc";
    var yLabelStr = "$y_label_esc";
    var valLabelStr = "$val_label_esc";
    var margin = { top: $margin_top, right: $margin_right, bottom: $margin_bottom, left: $margin_left };
    var innerW = $inner_w;
    var innerH = $inner_h;

    function esc(s) {
        return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    var xMap = new Map(), yMap = new Map();
    data.forEach(function(d) {
        if (!xMap.has(d.x)) xMap.set(d.x, xMap.size);
        if (!yMap.has(d.y)) yMap.set(d.y, yMap.size);
    });
    var xLabels = Array.from(xMap.keys());
    var yLabels = Array.from(yMap.keys());

    var maxV = d3.max(data, function(d) { return d.v; }) || 0;
    var colorScale = d3.scaleSequential($d3_interpolator)
        .domain(maxV === 0 ? [0, 1] : [0, maxV]);

    var xPad = Math.min(cellPad / Math.max(1, innerW / Math.max(1, xLabels.length)), 0.4);
    var yPad = Math.min(cellPad / Math.max(1, innerH / Math.max(1, yLabels.length)), 0.4);

    var xScale = d3.scaleBand().domain(xLabels).range([0, innerW]).paddingInner(xPad);
    var yScale = d3.scaleBand().domain(yLabels).range([0, innerH]).paddingInner(yPad);

    var showVals = showVals0 && xScale.bandwidth() >= 28 && yScale.bandwidth() >= 28;

    var svg = d3.select("#$svg_id");
    var g = svg.append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    g.append("g").attr("class", "hm-x-axis")
        .call(d3.axisTop(xScale).tickSize(0))
        .call(function(a) { a.select(".domain").remove(); });
    g.append("g").attr("class", "hm-y-axis")
        .call(d3.axisLeft(yScale).tickSize(0))
        .call(function(a) { a.select(".domain").remove(); });

    if (xLabelStr) {
        svg.append("text")
            .attr("x", margin.left + innerW / 2)
            .attr("y", $height - 4)
            .attr("text-anchor", "middle")
            .attr("font-size", "12px")
            .text(xLabelStr);
    }
    if (yLabelStr) {
        svg.append("text")
            .attr("transform", "rotate(-90)")
            .attr("x", -(margin.top + innerH / 2))
            .attr("y", 14)
            .attr("text-anchor", "middle")
            .attr("font-size", "12px")
            .text(yLabelStr);
    }

    var tip = d3.select("#$tip_id");

    var gridMap = new Map();
    data.forEach(function(d) { gridMap.set(d.x + "\\t" + d.y, d); });
    var cells = Array.from(gridMap.values());

    var cellGs = g.selectAll(".hm-cell")
        .data(cells)
        .join("g")
        .attr("class", "hm-cell")
        .attr("transform", function(d) {
            return "translate(" + xScale(d.x) + "," + yScale(d.y) + ")";
        });

    cellGs.append("rect")
        .attr("width", xScale.bandwidth())
        .attr("height", yScale.bandwidth())
        .attr("fill", function(d) { return colorScale(d.v); })
        .on("mouseover", function(event, d) {
            tip.html("X: " + esc(d.x) + "<br>Y: " + esc(d.y) + "<br>" + esc(valLabelStr) + ": " + d.v.toLocaleString())
               .style("display", "block")
               .style("left", (event.pageX + 12) + "px")
               .style("top",  (event.pageY - 24) + "px");
        })
        .on("mousemove", function(event) {
            tip.style("left", (event.pageX + 12) + "px")
               .style("top",  (event.pageY - 24) + "px");
        })
        .on("mouseout", function() { tip.style("display", "none"); });

    if (showVals) {
        cellGs.append("text")
            .attr("class", "hm-cell-text")
            .attr("x", xScale.bandwidth() / 2)
            .attr("y", yScale.bandwidth() / 2)
            .text(function(d) { return d.v.toLocaleString(); });
    }

$legend_block
$anim_block})();
</script>
HTML

	return { svg_id => $svg_id, html => $html };
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

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is C<[ Str, Num ]>; passing C<undef> or a
    non-arrayref dies.

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
	my $json_data = $_JSON->encode([
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

	my $json_data = $_JSON->encode([
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
    my $fragment = $chart->render_zoomable_line_chart_snippet($data, { animated => 1 });
    # $fragment->{svg_id} - the id attribute of the <svg> element
    # $fragment->{html}   - embeddable HTML fragment (style + button + svg + script)

Like C<render_line_chart_snippet>, but adds brush-to-zoom: the user can drag
across a range of the x-axis to zoom into that region. A I<Reset zoom> button
(hidden until a zoom is active) returns the chart to its original extent.
Subsequent brushes on the zoomed view zoom in further; Reset always returns to
the full dataset.

The caller is responsible for loading D3 in the page C<<head>>.

Accepts the same arguments as C<render_line_chart_snippet>: an array reference
of data points, each C<[$x, $y]> or C<[$x, $y, \%extra]>, plus an optional
second argument C<$opts> (hashref).

=head3 Options

=over 4

=item * C<animated> (boolean, default C<0>) - when true, the initial page load
animates the line drawing left-to-right via the C<stroke-dashoffset> technique
(1200 ms, C<d3.easeLinear>), then fades in data-point circles after the line
finishes (300 ms after a 1200 ms delay).  Respects
C<prefers-reduced-motion>: when the user has requested reduced motion the line
is drawn immediately at full opacity.  Subsequent zoom and reset redraws are
never animated regardless of this flag.

=back

=head3 API SPECIFICATION

=head4 Input

    {
        data => { type => 'arrayref' },
        opts => { type => 'hashref', optional => 1, default => {} },
    }

    Each element of C<$data> is C<[ Str, Num ]> or C<[ Str, Num, HashRef ]>;
    passing C<undef> or a non-arrayref dies.
    Recognised C<opts> key: C<animated> (boolean, default C<0>).

=head4 Output

    HashRef -- C<{ svg_id =E<gt> 'chart', html =E<gt> Str }>;
               embeddable fragment; no DOCTYPE, no page shell, no D3 CDN tag.

=head3 Errors

Dies with I<Data must be an array of arrays> if C<$data> is not an arrayref.

=head3 Side Effects

None.

=cut

sub render_zoomable_line_chart_snippet
{
	my ($self, $data, $opts) = @_;
	$opts //= {};

	die 'Data must be an array of arrays' unless ref($data) eq 'ARRAY';

	my $json_data = $_JSON->encode([
		map {
			my $point = { label => $_->[0], value => $_->[1] };
			$point->{extra} = $_->[2] if ref($_->[2]) eq 'HASH';
			$point
		} @$data
	]);

	my $svg_id = 'chart';
	my $tip_id = 'tooltip';
	my $rst_id = 'reset-btn';

	# Single-quote heredoc so <\/b> is preserved verbatim in the output —
	# double-quote would require <\\/b> to survive Perl interpolation.
	my $circle_handlers = <<'HANDLERS';
		.on("mouseover", (event, d) => {
		    let ttHtml = `Label: <b>${d.label}<\/b><br>Value: <b>${d.value}<\/b>`;
		    if (d.extra) {
			Object.entries(d.extra).forEach(([k, v]) => {
			    ttHtml += `<br>${k}: <b>${v}<\/b>`;
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
HANDLERS

	my $init_flag   = $opts->{animated} ? 'let initialDrawDone = false;' : '';

	my $redraw_body;
	if ($opts->{animated}) {
		$redraw_body = <<"ANIM";
	if (!initialDrawDone) {
	    var prefersReduced = window.matchMedia &&
		window.matchMedia('(prefers-reduced-motion: reduce)').matches;
	    linePath.datum(newData).attr("d", lineFn);
	    if (prefersReduced) {
		linePath.attr("stroke-dasharray", null).attr("stroke-dashoffset", null);
	    } else {
		const L = linePath.node().getTotalLength();
		linePath
		    .attr("stroke-dasharray", L)
		    .attr("stroke-dashoffset", L)
		    .transition()
		    .duration(1200)
		    .ease(d3.easeLinear)
		    .attr("stroke-dashoffset", 0);
	    }
	    chart.selectAll("circle.pt")
		.data(newData, d => d.label)
		.join(
		    enter => enter.append("circle")
			.attr("class", "pt")
			.attr("r", 4)
			.attr("fill", "steelblue")
			.attr("cx", d => x(d.label))
			.attr("cy", d => y(d.value))
			.attr("opacity", prefersReduced ? 1 : 0)
		)
$circle_handlers		.transition()
		.duration(prefersReduced ? 0 : 300)
		.delay(prefersReduced ? 0 : 1200)
		.attr("opacity", 1);
	    initialDrawDone = true;
	} else {
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
$circle_handlers		.transition(t)
		.attr("cx", d => x(d.label))
		.attr("cy", d => y(d.value));
	}
ANIM
	} else {
		$redraw_body = <<"PLAIN";
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
$circle_handlers	    .transition(t)
	    .attr("cx", d => x(d.label))
	    .attr("cy", d => y(d.value));
PLAIN
	}

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

    $init_flag

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

$redraw_body    }

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

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is a hashref with keys C<name> (string) and
    C<data> (arrayref of hashrefs with C<label> and C<value> keys);
    passing C<undef> or a non-arrayref dies.

=head4 Output

    Str -- complete HTML5 document; one coloured line per series with mouseover tooltips.

=cut

sub render_multi_series_line_chart_with_tooltips
{
	my ($self, $data) = @_;

	# Validate input data
	die 'Data must be an array of hashes' unless ref($data) eq 'ARRAY';

	my $json_data = $_JSON->encode($data);

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

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is a hashref with keys C<name> (string) and
    C<data> (arrayref of hashrefs with C<label> and C<value> keys);
    passing C<undef> or a non-arrayref dies.

=head4 Output

    Str -- complete HTML5 document; animated tooltip uses CSS translateY transition.

=cut

sub render_multi_series_line_chart_with_animated_tooltips
{
	my ($self, $data) = @_;

	# Validate input data
	die 'Data must be an array of hashes' unless ref($data) eq 'ARRAY';

	# Generate JSON for data
	my $json_data = $_JSON->encode($data);

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

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is a hashref with keys C<name> (string) and
    C<data> (arrayref of hashrefs with C<label> and C<value> keys);
    passing C<undef> or a non-arrayref dies.

=head4 Output

    Str -- complete HTML5 document; static colour legend rendered as SVG C<g> elements
           with the C<.legend> CSS class applied via D3 C<.attr("class", "legend")>.

=cut

sub render_multi_series_line_chart_with_legends {
	my($self, $data) = @_;

	# Validate input data
	die 'Data must be an array of hashes' unless ref($data) eq 'ARRAY';

	# Generate JSON for data
	my $json_data = $_JSON->encode($data);

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

    {
        data => { type => 'arrayref' },
    }

    Each element of C<$data> is a hashref with keys C<name> (string) and
    C<data> (arrayref of hashrefs with C<label> and C<value> keys);
    passing C<undef> or a non-arrayref dies.

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
	my $json_data = $_JSON->encode($data);

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

=head2 render_animated_bar_chart

    render_animated_bar_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  data = undef              ⇒ die "Data is not optional"
    pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post ".transition()" ⊆ result ∧ ".delay(" ⊆ result

=head2 render_animated_line_chart

    render_animated_line_chart : HTML::D3 × (ArrayRef | undef) → Str ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "stroke-dashoffset" ⊆ result ∧ "d3.easeLinear" ⊆ result

=head2 render_pie_chart

    render_pie_chart : HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → Str ∪ ⊥

    pre  data = undef              ⇒ die "Data is not optional"
    pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "d3.pie()" ⊆ result ∧ "d3.arc()" ⊆ result ∧ "d3.schemeCategory10" ⊆ result
    post opts.separator = S        ⇒  " S " ⊆ result (SVG legend: label S value)

=head2 render_animated_pie_chart

    render_animated_pie_chart : HTML::D3 × (ArrayRef | undef) × (HashRef | undef) → Str ∪ ⊥

    pre  data = undef              ⇒ die "Data is not optional"
    pre  ref(data) ≠ 'ARRAY'      ⇒ die "Data must be an array of arrays"
    post result ∈ Str
    post "<!DOCTYPE" ⊆ result
    post "attrTween" ⊆ result ∧ "d3.interpolate" ⊆ result
    post opts.separator = S        ⇒  " S " ⊆ result (SVG legend: label S value)

=head2 render_line_chart_snippet

    render_line_chart_snippet : HTML::D3 × (ArrayRef | undef) → HashRef ∪ ⊥

    pre  ref(data) ≠ 'ARRAY'  ⇒ die "Data must be an array of arrays"
    post result ∈ HashRef
    post result.svg_id = "chart"
    post result.html ∈ Str
    post "<!DOCTYPE" ∉ result.html

=head2 render_zoomable_line_chart_snippet

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

=head2 render_pie_chart_snippet

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

=head2 render_heatmap_snippet

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

=head2 render_line_chart_with_tooltips

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
