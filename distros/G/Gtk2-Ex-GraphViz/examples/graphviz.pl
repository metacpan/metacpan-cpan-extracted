use strict;
use warnings;
use Gtk2 -init;
use Glib qw(TRUE FALSE);
use GraphViz;
use Gtk2::Ex::GraphViz;
use Data::Dumper;

my $g = GraphViz->new;

$g->add_node('London', shape => 'box', fillcolor =>'lightblue', style     =>'filled',);
$g->add_node('Paris', label => 'City of\nlurve', );
$g->add_node('New York', shape => 'circle');
$g->add_node('Milan', shape => 'egg');
$g->add_node('Frankfurt', shape => 'triangle');
$g->add_node('Dubai', shape => 'diamond');
$g->add_node('Dallas', shape => 'trapezium');
$g->add_node('Budapest', shape => 'parallelogram');
$g->add_node('Prague', shape => 'house');
$g->add_node('Munich', shape => 'hexagon');
$g->add_node('Barcelona', shape => 'octagon');

$g->add_edge('Milan' => 'Paris');
$g->add_edge('London' => 'Paris');
$g->add_edge('London' => 'New York');
$g->add_edge('Paris' => 'New York');
$g->add_edge('Frankfurt' => 'New York');
$g->add_edge('Frankfurt' => 'New York');
$g->add_edge('Frankfurt' => 'Dubai');
$g->add_edge('Frankfurt' => 'Dallas');
$g->add_edge('Frankfurt' => 'Budapest');
$g->add_edge('Budapest' => 'Prague');
$g->add_edge('Budapest' => 'Munich');
$g->add_edge('Munich' => 'Barcelona');

my $label = Gtk2::Label->new('Move the mouse over the nodes/edges');
my $graphviz = Gtk2::Ex::GraphViz->new($g);
# print Dumper $graphviz->{svgdata};

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
		#print "Exiting node\n";
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
		#print "Exiting edge\n";
		$label->set_text('Move the mouse over the nodes/edges');
	}
);

my $hbox = Gtk2::HBox->new(FALSE, 0);
$hbox->pack_start (Gtk2::Label->new, TRUE, TRUE, 0);    
$hbox->pack_start ($graphviz->get_widget, FALSE, FALSE, 0);
$hbox->pack_start (Gtk2::Label->new, TRUE, TRUE, 0);    

my $scrolledwindow = Gtk2::ScrolledWindow->new (undef, undef);
$scrolledwindow->set_policy('automatic', 'automatic');
$scrolledwindow->add_with_viewport($hbox);

my $vbox = Gtk2::VBox->new(FALSE, 0);
$vbox->pack_start ($scrolledwindow, TRUE, TRUE, 0);
$vbox->pack_start (Gtk2::Label->new, FALSE, TRUE, 0);    
$vbox->pack_start ($label, FALSE, TRUE, 0);    
$vbox->pack_start (Gtk2::Label->new, FALSE, TRUE, 0);    

my $window = Gtk2::Window->new;
$window->signal_connect('destroy' => sub { Gtk2->main_quit });
$window->add($vbox);
$window->set_default_size(500,400);
$window->show_all;
Gtk2->main;


