use GD::Graph::linespoints;
require 'save.pl';

print STDERR "Processing sample42\n";

my $path = $ENV{GDGRAPH_SAMPLES_PATH} ? $ENV{GDGRAPH_SAMPLES_PATH} : '';

@data =  read_data_from_csv("${path}sample42.dat")
	or die "Cannot read data from sample42.dat";

$my_graph = new GD::Graph::linespoints( );

$my_graph->set( 
	x_label => 'X Label',
	y_label => 'Y label',
	title => 'A Lines and Points Graph, reading a CSV file',
	y_max_value => 80,
	y_tick_number => 6,
	y_label_skip => 2,
	markers => [ 1, 5 ],

	transparent => 0,
);

$my_graph->set_legend( 'data set 1', 'data set 2' );
$my_graph->plot(\@data);
save_chart($my_graph, 'sample42');


sub read_data_from_csv
{
	my $fn = shift;
	my @d = ();

	open(ZZZ, $fn) || return ();

	while (<ZZZ>)
	{
		chomp;
		# you might want Text::CSV here
		my @row = split /,/;

		for (my $i = 0; $i <= $#row; $i++)
		{
			undef $row[$i] if ($row[$i] eq 'undef');
			push @{$d[$i]}, $row[$i];
		}
	}

	close (ZZZ);

	return @d;
}


1;
