use strict;
use Gnome2::Canvas;

require "canvas-arrowhead.pl";
require "canvas-curve.pl";
require "canvas-features.pl";
require "canvas-fifteen.pl";
require "canvas-primitives.pl";
require "canvas-rich-text.pl";

sub create_canvas {
	my $app = Gtk2::Window->new;

	$app->signal_connect (delete_event => sub { Gtk2->main_quit; 1 });

	my $notebook = Gtk2::Notebook->new;
	$notebook->show;

	$app->add ($notebook);

	$notebook->append_page (CanvasPrimitives::create (0), Gtk2::Label->new ("Primitives"));
    	$notebook->append_page (CanvasPrimitives::create (1), Gtk2::Label->new ("Antialias"));  
	$notebook->append_page (CanvasArrowhead::create (), Gtk2::Label->new ("Arrowhead"));
	$notebook->append_page (CanvasFifteen::create (), Gtk2::Label->new ("Fifteen"));
	$notebook->append_page (CanvasFeatures::create (), Gtk2::Label->new ("Features"));
	$notebook->append_page (CanvasRichText::create (), Gtk2::Label->new ("Rich Text"));
	$notebook->append_page (CanvasBezierCurve::create (), Gtk2::Label->new ("Bezier Curve"));

	$app->show;
}


Gtk2->init;

create_canvas ();

Gtk2->main;
