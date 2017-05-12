#!/usr/bin/perl -w

# TITLE: Style changes
# REQUIRES: Gtk

use Gtk;
use Cwd;

init Gtk;

$w = new Gtk::Window;
$w->signal_connect("destroy", sub {Gtk->main_quit});
$b = new Gtk::Button "Change me!";
$b->signal_connect("clicked", \&random_change);
$w->add($b);

$w->show_all;

main Gtk;

sub random_change {
	my ($o) = shift;
	my $s = new Gtk::RcStyle;
	my $test = int(rand(3));
	if ($test == 0) {
		my $c = {green =>int(rand(65355)), blue=>int(rand(65355)), red => int(rand(65355))};
		$c = $o->get_colormap->color_alloc($c);
		$s->modify_color(['fg', 'text'], 'normal', $c);
		$s->modify_color(['fg', 'text'], 'prelight', $c);
		warn "Change color\n";
	} elsif ($test == 1) {
		$s->modify_font("fixed");
		warn "Change font\n";
	} elsif ($test == 2) {
		$s->modify_bg_pixmap('normal', getcwd()."/xpm/warning.xpm");
		$s->modify_bg_pixmap('prelight', getcwd()."/xpm/warning.xpm");
		warn "Change pixmap\n";
	}
	$o->modify_style($s);
	$o->child->modify_style($s);
}

