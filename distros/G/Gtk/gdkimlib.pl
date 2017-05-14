#!/usr/bin/perl -w

use Gtk;
init Gtk;
Gtk::Gdk::ImlibImage->init();

$file = shift || die "Usage: $0 image_file\n";

$im = load_image Gtk::Gdk::ImlibImage ($file);

$w = $im->rgb_width;; 
$h = $im->rgb_height;

$win = new Gtk::Gdk::Window( {
	'window_type' => 'toplevel',
	'width' => $w,
	'height' => $h,
	'event_mask' => ['structure-mask']
} );

$im->render($w, $h);

$p = $im->move_image;
$b = $im->move_mask;

$win->set_back_pixmap($p, 0);

$win->shape_combine_mask($m, 0,0) if $m;

$win->show;

flush Gtk::Gdk;

while (1) {
	events_pending Gtk::Gdk;

	$e = Gtk::Gdk->event_get();
	next unless $e;
	next unless $e->{'type'} eq 'configure';

	$w = $e->{'width'};
	$h = $e->{'height'};

	$im->render($w, $h);
	$p->imlib_free;
	$p = $im->move_image;
	$b = $im->move_mask;
	$win->set_back_pixmap($p, 0);
	$win->shape_combine_mask($m, 0,0) if $m;
	$win->clear();
	flush Gtk::Gdk;
	
}

