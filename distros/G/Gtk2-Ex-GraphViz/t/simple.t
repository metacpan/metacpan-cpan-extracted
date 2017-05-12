use strict;
use warnings;
use Gtk2 -init;
use Glib qw(TRUE FALSE);
use GraphViz;
use Gtk2::Ex::GraphViz;
use Data::Dumper;

use Gtk2::TestHelper tests => 1;

my $g = GraphViz->new;
$g->add_node('Munich', shape => 'hexagon');
$g->add_node('Barcelona', shape => 'octagon');
$g->add_edge('Munich' => 'Barcelona');

my $label = Gtk2::Label->new('Move the mouse over the nodes/edges');
my $graphviz = Gtk2::Ex::GraphViz->new($g);

$graphviz->signal_connect ('mouse-enter-node' => 
	sub {
		my ($self, $x, $y, $nodename) = @_;
		my $nodetitle = $graphviz->{svgdata}->{g}->{g}->{$nodename}->{title};
		$label->set_text("Node : $nodetitle : $x, $y");
	}
);

$graphviz->signal_connect ('mouse-exit-node' => 
	sub {
		my ($self, $x, $y) = @_;
		$label->set_text('Move the mouse over the nodes/edges');
	}
);

$graphviz->signal_connect ('mouse-enter-edge' => 
	sub {
		my ($self, $x, $y, $edgename) = @_;
		my $edgetitle = $graphviz->{svgdata}->{g}->{g}->{$edgename}->{title};
		$label->set_text("Edge : $edgetitle : $x, $y");
	}
);

$graphviz->signal_connect ('mouse-exit-edge' => 
	sub {
		my ($self, $x, $y) = @_;
		$label->set_text('Move the mouse over the nodes/edges');
	}
);


my $vbox = Gtk2::VBox->new(FALSE, 0);
$vbox->pack_start ($graphviz->get_widget, TRUE, TRUE, 0);
$vbox->pack_start ($label, FALSE, TRUE, 0);    

my $window = Gtk2::Window->new;
$window->signal_connect('destroy' => sub { Gtk2->main_quit });
$window->add($vbox);
$window->set_default_size(500,400);
$window->show_all;

ok(1);
