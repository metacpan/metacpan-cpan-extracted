use strict;
use GD::Graph::lines;
require 'save.pl';

my @data = ( 
    [                    "1st", "2nd", "3rd", "4th", "5th" ],
    [ map { log10($_) } ( 0.01, 0.134, 0.985,  10.2,    98)],
    [ map { log10($_) } ( 1023,   110,   9.4,   0.1, 0.012)]
);

sub log10 { return log(shift)/log(10) }

sub y_format
{
    my $value = shift;
    return sprintf "%g", 10**$value;
}

my $name = 'sample58';

my $graph = GD::Graph::lines->new;

print STDERR "Processing $name\n";

$graph->set( 
	title		=> 'Test of axis value transform',
	y_number_format => \&y_format,
	y_max_value	=> log10(1e4),
	y_min_value	=> log10(1e-3),
	y_tick_number	=> 7,
	transparent	=> 0,
);

$graph->plot(\@data);
save_chart($graph, $name);

1;
