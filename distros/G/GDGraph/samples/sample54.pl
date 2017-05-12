use GD::Graph::lines;
require 'save.pl';

print STDERR "Processing sample54\n";

my $path = $ENV{GDGRAPH_SAMPLES_PATH} ? $ENV{GDGRAPH_SAMPLES_PATH} : '';
@data = read_data("${path}sample54.dat")
	or die "Cannot read data from ${path}sample54.dat";

$my_graph = new GD::Graph::lines();

$my_graph->set( 
	x_label => 'Wavelength (nm)',
	y_label => 'Absorbance',
	title => 'Numerical X axis',

	y_min_value => 0,
	y_max_value => 2,
	y_tick_number => 8,
	y_label_skip => 4,

	x_tick_number => 'auto',
	x_label_skip => 2,

	box_axis => 0,
	line_width => 2,
	x_label_position => 1/2,
	r_margin => 15,

	x_labels_vertical => 1,

	transparent => 0,
);

$my_graph->set_legend('Thanks to Scott Prahl');
$my_graph->plot(\@data);
save_chart($my_graph, 'sample54');


sub read_data
{
	my $fn = shift;
	my @d = ();

	open(ZZZ, $fn) || return ();

	while (<ZZZ>)
	{
		chomp;
		my @row = split;

		for (my $i = 0; $i <= $#row; $i++)
		{
			undef $row[$i] if ($row[$i] eq 'undef');
			unshift @{$d[$i]}, $row[$i];
		}
	}

	close (ZZZ);

	return @d;
}


1;
