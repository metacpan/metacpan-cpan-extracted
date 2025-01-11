# NAME

HTML::D3 - A simple Perl module for generating charts using D3.js.

# VERSION

Version 0.07

# SYNOPSIS

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

## render\_line\_chart

    my $html = $chart->render_line_chart($data);

Generates HTML and JavaScript code to render a line chart. Accepts the following arguments:

- `$data` - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.

## render\_line\_chart\_with\_tooltips

    $html = $chart->render_line_chart_with_tooltips($data);

Generates HTML and JavaScript code to render a line chart with mouseover tooltips.
Accepts the following arguments:

- `$data` - An array reference containing data points. Each data point should
be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.

## render\_multi\_series\_line\_chart\_with\_tooltips

    $html = $chart->render_multi_series_line_chart_with_tooltips($data);

Generates HTML and JavaScript code to render a chart of many lines with mouseover tooltips.

Accepts the following arguments:

- `$data` - An reference to an array of hashes containing data points.
Each data point should be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.

## render\_multi\_series\_line\_chart\_with\_animated\_tooltips

    $html = $chart->render_multi_series_line_chart_with_animated_tooltips($data);

Generates HTML and JavaScript code to render a chart of many lines with animated mouseover tooltips.

Accepts the following arguments:

- `$data` - An reference to an array of hashes containing data points.
Each data point should be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.

## render\_multi\_series\_line\_chart\_with\_legends

    $html = $chart->render_multi_series_line_chart_with_legends($data);

Generates HTML and JavaScript code to render a chart of many lines with animated mouseover tooltips.

Accepts the following arguments:

- `$data` - An reference to an array of hashes containing data points.
Each data point should be an array reference with two elements: the label (string) and the value (numeric).

Returns a string containing the HTML and JavaScript code for the chart.

# BUGS

It would help to have the render routine to return the head and body components separately.

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

# LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

This program is released under the following licence: GPL2
