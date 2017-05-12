#!/usr/bin/perl -w

#TITLE: GdkPixbuf
#REQUIRES: Gtk GdkPixbuf

use Gtk::Gdk::Pixbuf;

init Gtk;

$file = shift || '../../Gtk/samples/xpm/marble.xpm';

die "Can't find '$file'\n" unless -f $file;

$w = new Gtk::Window;
$w->signal_connect('delete_event', sub {Gtk->exit(0)});
$w->set_app_paintable(1);
$pb = new_from_file Gtk::Gdk::Pixbuf($file);

print "width ", $pb->get_width(), ", height ", $pb->get_height(), "\n" if $pb;

# kill 19, $$;

$w->signal_connect('expose_event', sub {
	# slow
	$pb->render_to_drawable_alpha($w->window,
		0, 0, 0, 0,
		$pb->get_width(), $pb->get_height(),
		0, 50, 0, 0, 0);
	1;
});
$w->set_usize($pb->get_width(), $pb->get_height());
$w->show_all;

#$w2 = new Gtk::Window;
#$w2->signal_connect('delete_event', sub {Gtk->exit(0)});
#$w2->set_app_paintable(1);

Gtk->main();

