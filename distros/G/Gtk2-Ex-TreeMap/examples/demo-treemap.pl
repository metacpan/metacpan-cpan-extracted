use strict;
use warnings;
use Data::Dumper;
use XML::Simple;

use Gtk2 -init;
use Glib qw /TRUE FALSE/;

use Gtk2::Ex::TreeMap;

# This is our little tooltip window.
my $tooltip_label = Gtk2::Label->new;
my $tooltip = Gtk2::Window->new('popup');
$tooltip->set_decorated(0);
$tooltip->set_position('mouse'); # We'll choose this to start with.
$tooltip->add($tooltip_label);
my $tooltip_displayed = FALSE;

my $xmlstr;
while (<DATA>) {
	$xmlstr .= $_;
}
my $tree = XMLin($xmlstr, ForceArray => 1);

my $treemap = Gtk2::Ex::TreeMap->new([600,400]);

my $current_chosen_path = [];
$treemap->signal_connect('mouse-over', \&show_popup);

$treemap->draw_map($tree);

my $window = Gtk2::Window->new;
$window->signal_connect(destroy => sub { Gtk2->main_quit; });
$window->add($treemap->get_image);
$window->show_all;
Gtk2->main;

sub show_popup {
	my ($x, $y, $path, $node) = @_;
	my $str1 = join ':', @$current_chosen_path;
	my $str2 = join ':', @$path;
	if ($str1 ne $str2) { # Path has changed
		@$current_chosen_path = @$path;
		my $size = $node->{size} || "unknown";
		my $description = $node->{description} || "unknown";
		my $color = $node->{color} || "unknown";
		my $desc = "size = $size\ndesc = $description\ncolor = $color";
	    $tooltip_label->set_label($desc);
	    $tooltip->hide;
        $tooltip->show_all;
	}
	return 0;
}


__DATA__
<Node>
	<Node>
		<Node size="9" color="0,0,80" description="0 0"/>
		<Node size="7" color="0,120,80" description="0 1"/>
		<Node>
			<Node size="9" color="0,0,100" description="0 2 0"/>
			<Node size="9" color="0,0,110" description="0 2 1"/>
			<Node>
				<Node size="8" color="0,0,100" description="0 2 2 0"/>
				<Node size="2" color="0,0,110" description="0 2 2 1"/>
			</Node>
		</Node>
	</Node>
	<Node>
		<Node size="7" color="0,170,200" description="1 0"/>
		<Node size="5" color="0,170,210" description="1 1"/>
		<Node size="9" color="0,170,220" description="1 2"/>
	</Node>
</Node>	