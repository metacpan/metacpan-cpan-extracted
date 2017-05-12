#!/usr/bin/perl -w

use Bonobo;

my $factory;

init Gnome 'bonobo-sample-container', '0.1';
init Bonobo;

my $w = new Gtk::Window;
my $b = new Gtk::Button('Add');
$b->signal_connect('clicked', \&create_container);
$w->add($b);
$w->show_all;

main Bonobo;

sub create_container {
	die unless Bonobo->activate;
	#my $win = new Gtk::Widget 'Gnome::BonoboWindow';# ('sample-container', 'Sample Perl/Bonobo container');
	my $win = new Gnome::BonoboWindow ('sample-container', 'Sample Perl/Bonobo container');
	my $uic = new Gnome::BonoboUIContainer;
	my $box = new Gtk::VBox;

	$uic->set_win($win);
	$win->set_default_size(500, 400);
	$win->signal_connect('destroy', sub {Gtk->main_quit;});
	
	warn "uic is $uic\n";
	$control = new_control Gnome::BonoboWidget (
		"OAFIID:bonobo_calculator:fab8c2a7-9576-437c-aa3a-a8617408970f",
		$uic->corba_objref);
	warn "control is $control\n";
	$box->pack_start($control, 0, 0, 0);
	$win->set_contents($control);
	$win->show_all;
	return 0;
}

