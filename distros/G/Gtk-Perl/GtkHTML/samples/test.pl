#!/usr/bin/perl

#TITLE: HTML test (GtkHTML)
#REQUIRES: Gtk GtkHTML

use Gtk::HTML::Simple;
use LWP::UserAgent;
use URI;

init Gtk;

Gtk::Widget->set_default_colormap(Gtk::Gdk::Rgb->get_cmap());
Gtk::Widget->set_default_visual(Gtk::Gdk::Rgb->get_visual());

$window = new Gtk::Window -toplevel;
$window->signal_connect('delete_event', sub {Gtk->exit(0)});
$sw = new Gtk::ScrolledWindow(undef, undef);
$sw->set_policy('automatic', 'automatic');
#$sw = new Gtk::HBox(0, 0);

$url = shift || 'file:/var/www/index.html';

$html = new Gtk::HTML::Simple;

$html->signal_connect('load_done', sub {print "load done\n"});
$html->signal_connect('title_changed', sub {$window->set_title($html->get_title())});
$html->signal_connect('on_url', sub {shift; print "on_url: ", shift,"\n"});
$html->signal_connect('object_requested', sub {shift; my $e= shift; print "want obj\n"; my $w = new Gtk::Button($e->classid); $w->show; $e->add($w);});
$sw->show;
$sw->add($html);
$window->add($sw);
$html->realize;

$window->set_default_size(500, 400);

show_all $window;
$html->load_url($url);
#$html->set_editable(1);

#Gtk->timeout_add(2000, sub {
#	$html->save(sub {print $_[0];1});
#	return 0;
#});
main Gtk;

