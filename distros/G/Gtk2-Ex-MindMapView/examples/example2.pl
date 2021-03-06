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
#$view->set_scroll_region(0,0,350,325);

$scroller->add($view);

$window->signal_connect('destroy'=>sub { _closeapp($view); });

$window->set_default_size(900,350);

$window->add($scroller);

my $item1 = _text_item($factory, "Hello World!");

$view->add_item($item1);

my $item2 = _text_item($factory, "Sunny Day");

$view->add_item($item1, $item2);

my $item3 = _text_item($factory, "Cloudy day");

$view->add_item($item1, $item3);

my $item4 = _text_item($factory, "This is a longish bit of text that hopefully will exceed the maximum width of the mind map.");

$view->add_item($item1, $item4);

my $item5 = _text_item($factory, "Time for some music.");

$view->add_item($item1, $item5);

my $item7 = _text_item($factory, "Canadian Painters");

$view->add_item($item1, $item7);

my $item9 = _text_item($factory, "Good films");

$view->add_item($item1, $item9);

my $item10 = _text_item($factory, "The Sadies.");

$view->add_item($item5, $item10);

my $item11 = _text_item($factory, "The Byrds.");

$view->add_item($item5, $item11);

my $item12 = _text_item($factory, "The Grateful Dead.");

$view->add_item($item5, $item12);

my $item13 = _text_item($factory, "Possible rainshowers.");

$view->add_item($item3, $item13);

my $item14 = _text_item($factory, "Jean Paul Riopelle");

$view->add_item($item7, $item14);

my $item15 = _text_item($factory, "Paul Emile Borduas");

$view->add_item($item7, $item15);

my $item16 = _text_item($factory, "Tom Thompson");

$view->add_item($item7, $item16);

my $item17 = _text_item($factory, "Winged Migration");

$view->add_item($item9, $item17);

my $item18 = _text_item($factory, "Down By Law");

$view->add_item($item9, $item18);

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

    return $factory->create_item(border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
				 content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
				 text=>$text);
}



1;
