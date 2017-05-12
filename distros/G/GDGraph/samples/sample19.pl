use strict;
use GD::Graph::bars;
use GD::Graph::hbars;
use GD::Graph::Data;
require 'save.pl';

$GD::Graph::Error::Debug = 5;

my $data = GD::Graph::Data->new(
[
    ["2004/2/1","2004/2/2","2004/2/3","2004/2/4","2004/2/5","2004/2/6","2004/2/7", "2004/2/8", "2004/2/9"],
    [  50000, 120000, 240000, 330000, 190000,  80000,  60000, 150000, 210000],
    [1033101,2200100,5300300,6400400,3192192,1600600, 900900,3333333,4444444],
]
) or die GD::Graph::Data->error;

my $values = $data->copy();
$values->set_y(1, 7, undef) or warn $data->error;
$values->set_y(2, 7, undef) or warn $data->error;

my @names = qw/sample19 sample19-h/;

my $path = $ENV{GDGRAPH_SAMPLES_PATH} ? $ENV{GDGRAPH_SAMPLES_PATH} : '';

for my $my_graph (GD::Graph::bars->new(600,400),
		  GD::Graph::hbars->new(600,400))
{
    my $name = shift @names;
    print STDERR "Processing $name\n";

    $my_graph->set( 
	x_label             => 'Date',
	y1_label            => 'Hits',
	y2_label            => 'Megabytes',
	title               => 'Using two axes with different formats',
	#y1_max_value        => 40,
	#y2_max_value        => 8,
	y_tick_number       => 8,
	y_label_skip        => 2,
        #y_number_format     => '%d', ### <-- this will override y{1,2}_number_format
	y1_number_format    => sub { # from perlfaq5
	  local $_ = shift;
	  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
	  $_;
	},
	y2_number_format    => sub { my $v = shift; sprintf("%.2f",$v/1024) },
	long_ticks          => 1,
	two_axes            => 1,
	legend_placement    => 'RT',
	x_label_position    => 1/2,

	bgclr		    => 'white',
	fgclr               => 'white',
	boxclr              => 'dblue',
	accentclr           => 'dblue',
	valuesclr           => '#ffff77',
	dclrs               => [qw(lgreen lred)],

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
