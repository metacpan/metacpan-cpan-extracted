#!/usr/bin/perl -w

use strict;
use Gtk2 '-init';
use Gnome2::Canvas;

use lib '../lib';

use Gtk2::Ex::MindMapView;
use Gtk2::Ex::MindMapView::ItemFactory;

my $window   = Gtk2::Window->new();

my $scroller = Gtk2::ScrolledWindow->new();

my $view     = Gtk2::Ex::MindMapView->new(aa=>1);

my $factory  = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$view);

$view->set_scroll_region(-350,-325,350,325);

$scroller->add($view);

$window->signal_connect('destroy'=>sub { _closeapp($view); });

$window->set_default_size(900,350);

$window->add($scroller);

my $item1 = _text_item($factory, "Hello World!");

$view->add_item($item1);

my $item2 = _url_item($factory, "Google Search Engine", "http://www.google.com");

$view->add_item($item1, $item2);

my $item3 = _picture_item($factory, "./monalisa.jpeg");

$view->add_item($item1, $item3);

$view->layout();

$window->show_all();

Gtk2->main();

exit 0;


sub _closeapp
{
    my $view = shift(@_);

    $view->destroy();

    Gtk2->main_quit();

    return 0;
}


sub _text_item
{
    my ($factory, $text) = @_;

    my $item = $factory->create_item(border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
				     content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
				     text=>$text,
				     font_desc=>Gtk2::Pango::FontDescription->from_string("Ariel Italic 8"),
				     hotspot_color_gdk=>Gtk2::Gdk::Color->parse('lightgreen'),
#				     outline_color_gdk=>Gtk2::Gdk::Color->parse('blue'),
				     fill_color_gdk   =>Gtk2::Gdk::Color->parse('white'));

    print "_text_item, item: $item\n";

    $item->signal_connect(event=>\&_test_handler);

    return $item;
}


sub _url_item
{
    my ($factory, $text, $url) = @_;

    my $browser = '/usr/bin/firefox %s';

    my $item = $factory->create_item(border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
				     content=>'Gtk2::Ex::MindMapView::Content::Uri',
				     text=>$text, uri=>$url, browser=>$browser,
				     hotspot_color_gdk=>Gtk2::Gdk::Color->parse('lightgreen'),
#				     outline_color_gdk=>Gtk2::Gdk::Color->parse('blue'),
				     text_color_gdk=>Gtk2::Gdk::Color->parse('blue'),
				     fill_color_gdk   =>Gtk2::Gdk::Color->parse('white'));

    print "_url_item, item: $item\n";

    $item->signal_connect(event=>\&_test_handler);

    return $item;
}


sub _picture_item
{
    my ($factory, $file) = @_;

    my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($file);

    my $item = $factory->create_item(border=>'Gtk2::Ex::MindMapView::Border::Rectangle',
				     content=>'Gtk2::Ex::MindMapView::Content::Picture',
				     pixbuf=>$pixbuf,
				     hotspot_color_gdk=>Gtk2::Gdk::Color->parse('lightgreen'),
				     fill_color_gdk   =>Gtk2::Gdk::Color->parse('white'));

    print "_picture_item, item: $item\n";

    $item->signal_connect(event=>\&_test_handler);

    return $item;
}

sub _test_handler
{
    my ($item, $event) = @_;

#    print "item: $item  event: $event\n";

    my $event_type = $event->type;

    my @coords = $event->coords;

    print "Event, type: $event_type  coords: @coords\n";
}


1;
