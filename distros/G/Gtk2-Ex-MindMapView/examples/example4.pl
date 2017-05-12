#!/usr/bin/perl -w

use strict;
use Gtk2 '-init';
use Gnome2::Canvas;

use lib '../lib';

use Gtk2::Ex::MindMapView;
use Gtk2::Ex::MindMapView::ItemFactory;

use Glib ':constants';

my $window     = Gtk2::Window->new();

my $scroller   = Gtk2::ScrolledWindow->new();

local $main::view    = Gtk2::Ex::MindMapView->new(aa=>1);

local $main::factory = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$main::view);

my $vbox       = Gtk2::VBox->new();

my $hbuttonbox = Gtk2::HButtonBox->new();

my $button1    = Gtk2::Button->new_with_label('Set Root');

my $button2    = Gtk2::Button->new_with_label('Delete');

my $button3    = Gtk2::Button->new_with_label('Add');

local $main::entry1 = Gtk2::Entry->new_with_max_length(30);

$button1->signal_connect('clicked'=>\&_clickedbutton1);

$button2->signal_connect('clicked'=>\&_clickedbutton2);

$button3->signal_connect('clicked'=>\&_clickedbutton3);

$main::view->set_scroll_region(-350,-163,350,325);

$scroller->add($main::view);

$vbox->pack_start($scroller,TRUE, TRUE, 0);

$vbox->pack_start($main::entry1, FALSE, TRUE, 0);

$vbox->pack_start($hbuttonbox, FALSE, TRUE, 0);

$hbuttonbox->pack_start_defaults($button1);
$hbuttonbox->pack_start_defaults($button2);
$hbuttonbox->pack_start_defaults($button3);

$window->add($vbox);

$window->signal_connect('destroy'=>\&_closeapp);

$window->set_default_size(450,450);

local $main::focus_item = _text_item($main::factory, "Hello World!");

$main::view->add_item($main::focus_item);

$main::view->layout();

$window->show_all();

Gtk2->main();

sub _clickedbutton1
{ # Set Root.
    $main::view->set_root($main::focus_item);

    $main::view->layout();
}

sub _clickedbutton2
{ # Delete Button

    my @predecessors = $main::view->predecessors($main::focus_item);

    if (scalar @predecessors == 0) # root.
    {
	$main::view->remove_item($main::focus_item);

	$main::focus_item = undef;
    }
    else
    {
	foreach my $predecessor_item (@predecessors)
	{
	    $main::view->remove_item($predecessor_item, $main::focus_item);

	    $main::focus_item = $predecessor_item;
	}
    }

    $main::view->layout();
}

sub _clickedbutton3
{ # Add Button
    my $text = $main::entry1->get_text();

    if ($text ne "")
    {
	my $item = _text_item($main::factory, $text);

	$main::view->add_item($main::focus_item, $item);

	if (!defined $main::focus_item)
	{
	    $main::focus_item = $item;
	}

	$main::view->layout();

	$main::entry1->set_text("");
    }
}


sub _closeapp
{
    Gtk2->main_quit();

    return 0;
}


sub _text_item
{
    my ($factory, $text) = @_;

    my $item = $factory->create_item(border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
				     content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
				     text=>$text,
				     font_desc=>Gtk2::Pango::FontDescription->from_string("Ariel Normal 12"),
				     outline_color_gdk=>Gtk2::Gdk::Color->parse('blue'),
				     fill_color_gdk   =>Gtk2::Gdk::Color->parse('white'));

    # Keep handler id so can remove handler for item.

    $item->signal_connect(event=>\&_test_handler);

    return $item;
}


sub _test_handler
{
    my ($item, $event) = @_;

    my $event_type = $event->type;

    my @coords = $event->coords;

#    print "Item: $item  Event, type: $event_type  coords: @coords\n";

    if ($event_type eq 'button-release')
    {
	$main::focus_item = $item;
    }
}
