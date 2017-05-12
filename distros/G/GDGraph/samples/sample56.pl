use GD::Graph::lines;
require 'save.pl';

print STDERR "Processing sample56 (experimental)\n";

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

	x_tick_number => 14,
	x_min_value => 100,
	x_max_value => 800,
	x_ticks     => 1,
	x_tick_length => -4,
	x_long_ticks => 1,
	x_label_skip => 2,
	x_tick_offset => 2,

	no_axes => 1,
	line_width => 2,
	x_label_position => 1/2,
	r_margin => 15,

	transparent => 0,
);

$my_graph->set_legend('Thanks to Scott Prahl and Gary Deschaines');
$my_graph->plot(\@data);
save_chart($my_graph, 'sample56');


sub read_data
{
	my $fn = shift;
        local(*ZZZ);
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
