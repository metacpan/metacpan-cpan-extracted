use strict;
use GD::Graph::bars;
use GD::Graph::hbars;
use GD::Graph::Data;
require 'save.pl';

$GD::Graph::Error::Debug = 5;

my $data = GD::Graph::Data->new(
[
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    5,   12,   24,   33,   19,    8,    6,    15,    21],
    [    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
    [    2,    4,  4.5,    5,  2.5,  0.5,    1,     2,     3],
]
) or die GD::Graph::Data->error;

my $values = $data->copy();
$values->set_y(1, 7, undef) or warn $data->error;
$values->set_y(2, 7, undef) or warn $data->error;
$values->set_y(3, 7, undef) or warn $data->error;

my @names = qw/sample95 sample95-h/;

my $path = $ENV{GDGRAPH_SAMPLES_PATH} ? $ENV{GDGRAPH_SAMPLES_PATH} : '';

for my $my_graph (GD::Graph::bars->new(600,400),
                  GD::Graph::hbars->new(600,400))
{
    my $name = shift @names;
    print STDERR "Processing $name\n";

    $my_graph->set( 
	x_label             => 'x label',
	y1_label            => 'y1 label',
	y2_label            => 'y2 label',
	title               => 'Using two axes with three datasets',
	y1_max_value        => 40,
	y2_max_value        => 8,
	y_tick_number       => 8,
	y_label_skip        => 2,
	long_ticks          => 1,
	two_axes            => 1,
	use_axis            => [1, 2, 2],
	legend_placement    => 'RT',
	x_label_position    => 1/2,

	bgclr		    => 'white',
	fgclr               => 'white',
	boxclr              => 'dblue',
	accentclr           => 'dblue',
	valuesclr           => '#ffff77',
	dclrs               => [qw(lgreen lred lred)],

	bar_spacing         => 1,

	logo                => "${path}logo." . GD::Graph->export_format,
	logo_position       => 'BR',

	transparent         => 0,

	l_margin            => 10,
	b_margin            => 10,
	r_margin            => 10,
	t_margin            => 10,

	show_values         => 1,
	values_format       => "%4.1f",

    ) or warn $my_graph->error;

    if ($name =~ /-h$/)
    {
	$my_graph->set(x_labels_vertical => 0, values_vertical => 0);
	$my_graph->set_legend('bottom axis', 'top axis');
    }
    else
    {
	$my_graph->set(x_labels_vertical => 1, values_vertical => 1);
	$my_graph->set_legend('left axis', 'right axis');
    }

    my $font_spec = "../Dustismo_Sans";

    $my_graph->set_y_label_font($font_spec, 12);
    $my_graph->set_x_label_font($font_spec, 12);
    $my_graph->set_y_axis_font($font_spec, 10);
    $my_graph->set_x_axis_font($font_spec, 10);
    $my_graph->set_title_font($font_spec, 18);
    $my_graph->set_legend_font($font_spec, 8);
    $my_graph->set_values_font($font_spec, 8);

    $my_graph->plot($data) or die $my_graph->error;
    save_chart($my_graph, $name);
}

1;
