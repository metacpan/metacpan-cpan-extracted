use GIFgraph::area;
use strict;

print STDERR "Processing sample 2-2\n";

my @data = make_data();

my $my_graph = new GIFgraph::area();

$my_graph->set(
        x_label => 'X',
        y_label => 'Y',
		y_tick_number => 'auto',
        title => 'Incremental Area graph trick',
);

$my_graph->set_legend( 'base + set1 + set2', 'base + set 1', 'base' );

$my_graph->plot_to_gif( "sample22.gif", \@data );

exit;

sub make_data
{
	my @data;

	# Foreach data row
	while (<DATA>)
	{
		my @f = split ',';

		# First value (X) goes into @{$data[0]}
		push @{$data[0]}, $f[0];

		my $sum = 0;

		# The remaining ones get accumulated
		for (my $i = 1; $i <= $#f; $i++)
		{
			$sum += $f[$i];

			# And we store it backwards because we need to display an 
			# area graph, for lines or points graphs, we could just use:
			# push @{$data[$i]}, $sum;
			push @{$data[$#f - $i + 1]}, $sum;
		}
	}

	return @data;
}

__DATA__
1st,10,60,12
2nd,52,61,20
3rd,53,61,13
4th,54,12,14
5th,55,68,16
6th,56,66,10
7th,13,65,6
8th,58,61,3
9th,59,42,5
