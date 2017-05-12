#!/usr/bin/perl -w

use lib '../lib';

use strict;
use Gtk2 '-init';
use Gnome2::Canvas;

use Gtk2::Ex::MindMapView;
use Gtk2::Ex::MindMapView::ItemFactory;

use Glib ':constants';

my $window   = Gtk2::Window->new();

my $scroller = Gtk2::ScrolledWindow->new();

local $main::view     = Gtk2::Ex::MindMapView->new(aa=>1);

$main::view->set(connection_color_gdk=>Gtk2::Gdk::Color->parse('darkred'));

#$main::view->set(connection_arrows=>'one-way');
$main::view->set(connection_arrows=>'two-way');

local $main::factory  = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$main::view);


my $vbox       = Gtk2::VBox->new();

my $hbox       = Gtk2::HBox->new();

local $main::entry1 = Gtk2::Entry->new_with_max_length(5);

my $button1    = Gtk2::Button->new_with_label('Draw');

my $button2    = Gtk2::Button->new_with_label('Clear');

$button1->signal_connect('clicked'=>\&_clickedbutton1);

$button2->signal_connect('clicked'=>\&_clickedbutton2);

$main::view->set_scroll_region(-350,-325,350,325);

$scroller->add($main::view);


$vbox->pack_start($scroller,TRUE, TRUE, 0);

$vbox->pack_start($hbox, FALSE, TRUE, 0);

$hbox->pack_start($main::entry1, FALSE, TRUE, 0);
$hbox->pack_start($button1,      FALSE, TRUE, 0);
$hbox->pack_start($button2,      FALSE, TRUE, 0);

$window->add($vbox);

$window->signal_connect('destroy'=>sub { _closeapp($main::view); });

$window->set_default_size(900,350);

$main::entry1->set_text("5");

_draw($main::view, $main::factory, 5);

$main::view->layout();

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


sub _draw
{
    my ($view, $factory, $count) = @_;

    my $item0 = _text_item($factory, 0);

    $view->add_item($item0);

    for my $index (1..$count)
    {
	my $item = _text_item($factory, $index);

	$view->add_item($item0, $item);
    }
}


sub _text_item
{
    my ($factory, $index) = @_;

    my @border_types = ('Gtk2::Ex::MindMapView::Border::RoundedRect',
  		        'Gtk2::Ex::MindMapView::Border::Rectangle',
		        'Gtk2::Ex::MindMapView::Border::Ellipse',
		       );

    my $border_index = $index % (scalar @border_types);

    my $border_type = $border_types[$border_index];

    my $item = $factory->create_item(border=>$border_type,
				     content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
				     text=>"item $index",
#				     font_desc=>Gtk2::Pango::FontDescription->from_string("Ariel Italic 8"),
#				     hotspot_color_gdk=>Gtk2::Gdk::Color->parse('lightgreen'),
				     outline_color_gdk=>Gtk2::Gdk::Color->parse('blue'),
				     fill_color_gdk   =>Gtk2::Gdk::Color->parse('white'));

    print "_text_item, item: $item\n";

    $item->signal_connect(event=>\&_test_handler);

    return $item;
}

sub _test_handler
{
    my ($item, $event) = @_;

    my $event_type = $event->type;

    my @coords = $event->coords;

    print "Event, type: $event_type  coords: @coords\n";
}

sub _clickedbutton1
{ # Draw
    my $entry = $main::entry1->get_text();

    if ($entry =~ m/^\d+$/io)
    {
	my $count = List::Util::max(0,$entry - 1);

	$main::view->clear();

	_draw($main::view, $main::factory, List::Util::min(25,$count));

	$main::view->layout();
    }
}

sub _clickedbutton2
{ # Clear

    $main::view->clear();
}


1;
