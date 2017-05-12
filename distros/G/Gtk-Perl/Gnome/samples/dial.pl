#!/usr/bin/perl

$NAME = 'Dial';

use Gnome;

init Gnome "dial.pl";

                $range_window = new Gtk::Window -toplevel;
                $range_window->signal_connect("destroy", sub { exit });
                $range_window->set_title("range controls");
                $range_window->border_width(0);
                
                $box1 = new Gtk::VBox(0,0);
                $range_window->add($box1);
                $box1->show;
                
                $box2 = new Gtk::VBox(0,10);
                $box2->border_width(10);
                $box1->pack_start($box2, 1, 1, 0);
                $box2->show;
                
                $adjustment = new Gtk::Adjustment(0.0, 0.0, 101.0, 0.1, 1.0, 1.0);
                
                $scale = new Gtk::HScale($adjustment);
                $scale->set_usize(150,30);
                $scale->set_update_policy(-delayed);
                $scale->set_digits(1);
                $scale->set_draw_value(1);
                $box2->pack_start($scale, 1, 1, 0);
                $scale->show;
                
                $scrollbar = new Gtk::HScrollbar $adjustment;
                $scrollbar->set_update_policy(-continuous);
                $box2->pack_start($scrollbar, 1, 1, 0);
                $scrollbar->show;

                
                $dial = new Gtk::Dial $adjustment;
                $dial->set_update_policy(-continuous);
                $box2->pack_start($dial, 1, 1, 0);
                $dial->show;
                
                $separator = new Gtk::HSeparator;
                $box1->pack_start($separator, 0, 1, 0);
                $separator->show;
                
                $box2 = new Gtk::VBox(0,10);
                $box2->border_width(10);
                $box1->pack_start($box2, 0, 1, 0);
                $box2->show;
                
                $button = new Gtk::Button "close";
                $button->signal_connect("clicked", sub {destroy $range_window});
                $box2->pack_start($button, 1, 1, 0);
                $button->can_default(1);
                $button->grab_default;
                show $button;


show $range_window;
			

main Gtk;	
