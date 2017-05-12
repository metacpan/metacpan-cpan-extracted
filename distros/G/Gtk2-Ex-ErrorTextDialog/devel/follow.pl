#!/usr/bin/perl -w

# Copyright 2009, 2010, 2013 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Data::Dumper;
use Gtk2::Ex::TextView::FollowAppend;

use FindBin;
my $progname = $FindBin::Script;

# {
#   # get_buffer() and get('buffer') both create
#   my $textview = Gtk2::TextView->new;
#   my $buf = $textview->get('buffer');
#   print "$buf\n";
#   print $textview->set('buffer',undef);
#   # $textview->destroy;
#   print $textview->get('buffer');
#   undef $buf;
#   undef $textview;
#   exit 0;
# }


Gtk2->init;
my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->set_default_size (500, 200);
$toplevel->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

my $vbox = Gtk2::VBox->new;
$hbox->pack_start ($vbox, 0,0,0);

my $scrolled = Gtk2::ScrolledWindow->new;
$scrolled->set_policy ('automatic', 'always');
$hbox->pack_start ($scrolled, 1,1,1);

my $textbuf = Gtk2::TextBuffer->new;
my $textview = Gtk2::Ex::TextView::FollowAppend->new_with_buffer ($textbuf);
# my $textview = Gtk2::TextView->new_with_buffer ($textbuf);
# my $follow = Gtk2::Ex::TextView::FollowAppend->new ($textview);
$scrolled->add ($textview);

$textview->signal_connect (size_allocate => sub {
                             my ($textview, $alloc) = @_;
                             print "$progname: size_allocate ",
                               $alloc->x,",",$alloc->y,
                                 " ",$alloc->width,"x",$alloc->height,
                                   "\n";
                             Glib::Idle->add
                                 (sub {
                                    my $alloc = $textview->allocation;
                                    print "$progname: idle allocation ",
                                      $alloc->x,",",$alloc->y,
                                        " ",$alloc->width,"x",$alloc->height,
                                          "\n";
                                    return Glib::SOURCE_REMOVE;
                                  });
                           });
# $textview->get('vadjustment');



{
  my $button = Gtk2::Button->new_with_label ('Insert');
  $button->signal_connect
    (clicked => sub {
       print "$progname: insert text\n";
       $textbuf->insert ($textbuf->get_end_iter, "abc\ndef\n");
       $textview->grab_focus;
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("Insert Big");
  $button->signal_connect
    (clicked => sub {
       print "$progname: insert big text\n";
       $textbuf->insert ($textbuf->get_end_iter,
                         join("\n",1..50) . ('A' x 100) . "\n");
       $textview->grab_focus;
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("Insert Middle");
  $button->signal_connect
    (clicked => sub {
       print "$progname: insert middle text\n";
       my $len = $textbuf->get_char_count;
       my $iter = $textbuf->get_iter_at_offset ($len - 20);
       $textbuf->insert ($iter, "mid\ndle\n");
       $textview->grab_focus;
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb', 0, 8, 30, 10);
  my $button = Gtk2::Button->new_with_label ("pixbuf");
  $button->signal_connect
    (clicked => sub {
       print "$progname: insert pixbuf\n";
       $textbuf->insert_pixbuf ($textbuf->get_end_iter, $pixbuf);
       $textbuf->insert ($textbuf->get_end_iter, "\n");
       $textview->grab_focus;
     });
  $vbox->pack_start ($button, 0,0,0);
}
my $draw = Gtk2::DrawingArea->new;
$draw->set_size_request (10, 60);
$draw->show;
{
  my $button = Gtk2::Button->new_with_label ("Child");
  $button->signal_connect
    (clicked => sub {
       print "$progname: insert child\n";
       my $anchor = $textbuf->create_child_anchor ($textbuf->get_end_iter);
       $textbuf->insert ($textbuf->get_end_iter, "\n");
       $textview->grab_focus;
       $textview->add_child_at_anchor ($draw, $anchor);
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("Child Bigger");
  $button->signal_connect
    (clicked => sub {
       print "$progname: child bigger\n";
       my ($w, $h) = $draw->get_size_request;
       $draw->set_size_request ($w * 2, $h * 2);
       $textview->grab_focus;
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("Clear");
  $button->signal_connect
    (clicked => sub {
       print "$progname: clear\n";
       $textbuf->delete ($textbuf->get_start_iter, $textbuf->get_end_iter);
       $textview->grab_focus;
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("Scroll To Ins");
  $button->signal_connect
    (clicked => sub {
       print "$progname: clear\n";
       $textview->scroll_to_mark ($textbuf->get_insert, 0, 0, 0,0);
       $textview->grab_focus;
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("Ins Start");
  $button->signal_connect
    (clicked => sub {
       print "$progname: insert text\n";
       $textbuf->insert ($textbuf->get_start_iter, "at\nstart\n");
       $textview->grab_focus;
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_from_stock ('gtk-quit');
  $button->signal_connect (clicked => sub { $toplevel->destroy });
  $vbox->pack_start ($button, 0,0,0);
}


# my $tag_table = $textbuf->get_tag_table;
# print Data::Dumper->Dump([$tag_table],['tag_table']);
# 
# my $tag = Gtk2::TextTag->new ('foo');
# $tag->set (scale => 3,
#            background => 'green');
# $tag_table->add ($tag);
# 
# my $tag_invisible = Gtk2::TextTag->new ('invisible');
# $tag_invisible->set (invisible => 1);
# $tag_table->add ($tag_invisible);
# 
# $textbuf->insert_with_tags ($textbuf->get_end_iter, "------------\n", $tag);
# $textbuf->insert ($textbuf->get_end_iter, "def\n");
# 
# my $pixbuf2 = Gtk2::Gdk::Pixbuf->new ('rgb', 0, 8, 100, 1);
# 
# $textbuf->insert_with_tags ($textbuf->get_end_iter, "-----\n", $tag_invisible);
# 
# $textbuf->insert ($textbuf->get_end_iter, "ghi\n");
# 
# $textbuf->insert ($textbuf->get_end_iter, "klm\n");
# 
# # $textbuf->insert_child_anchor ($textbuf->get_end_iter, $anchor);
# # $textbuf->insert ($textbuf->get_end_iter, "nop\n");
# 
# 
# print Data::Dumper->Dump([$textbuf->get('text')],['get(text)']);
# print Data::Dumper->Dump([$textbuf->get_text($textbuf->get_start_iter,
#                                              $textbuf->get_end_iter,
#                                              1)
#                          ], ['get_text']);


$toplevel->show_all;
Gtk2->main;
exit 0;
