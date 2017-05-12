use strict;
use warnings;

use Gtk2::Ex::Graph::GD;
use GD::Graph::Data;
use Gtk2 -init;
use Glib qw /TRUE FALSE/;
use Data::Dumper;

use Gtk2::TestHelper tests => 2;

my $graph = Gtk2::Ex::Graph::GD->new(500, 300, 'bars');
isa_ok($graph, "Gtk2::Ex::Graph::GD");

# All the properties set here go straight into the GD::Graph::* object created inside.
# Therefore, any property acceptable to the GD::Graph::* object can be passed through here
$graph->set (
	title           	=> 'Mice, Fish and Lobsters',
	x_labels_vertical 	=> TRUE,
	bar_spacing     	=> 1,
	shadowclr       	=> 'dred',
	transparent     	=> 0,
	# cumulate			=> TRUE,
	type 				=> 	['bars'],
);

my @legend_keys = ('Field Mice Population');
$graph->set_legend(@legend_keys);

my $data = GD::Graph::Data->new([
    [ 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008,],
    [  1,  2,  5, 8,  3, 4.5,  1, 3,  4],
]) or die GD::Graph::Data->error;

$graph->signal_connect ('mouse-over' =>
	sub {
		#print Dumper @_;
	}
);

$graph->signal_connect ('clicked' =>
	sub {
		print Dumper @_;
	}
);

# This actually returns an eventbox instead of an image. 
# But you don't <really> care either way, do you ?
my $image = $graph->get_image($data);
isa_ok($image, "Gtk2::EventBox");

my $window = Gtk2::Window->new;
$window->signal_connect(destroy => sub { Gtk2->main_quit; });
$window->set_default_size(700, 500);
$window->add($image);
$window->show_all;