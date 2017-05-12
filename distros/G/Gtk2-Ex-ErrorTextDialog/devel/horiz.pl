#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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


# child widget constrains width
#
# pixbuf doesn't constrain width, but does induce horiz scrollbar
#

use 5.008;
use strict;
use warnings;
use Data::Dumper;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->set_default_size (200, 300);
$toplevel->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

my $scrolled = Gtk2::ScrolledWindow->new;
$scrolled->set_policy ('automatic', 'always');
$toplevel->add ($scrolled);


my $textbuf = Gtk2::TextBuffer->new();
my $textview = Gtk2::TextView->new_with_buffer ($textbuf);
$scrolled->add ($textview);


my $tag_table = $textbuf->get_tag_table;
print Data::Dumper->Dump([$tag_table],['tag_table']);

{
  my $tag = Gtk2::TextTag->new ('foo');
  $tag->set (scale => 3,
             background => 'green');
  $tag_table->add ($tag);

  $textbuf->insert ($textbuf->get_end_iter, "next line green scaled up\n");
  $textbuf->insert_with_tags ($textbuf->get_end_iter, "------------\n", $tag);
}

my $pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb', 0, 8, 400, 1);
my $pixbuf2 = Gtk2::Gdk::Pixbuf->new ('rgb', 0, 8, 100, 1);
{
  $textbuf->insert ($textbuf->get_end_iter,
                    "next line insert_pixbuf, varying size\n");
  $textbuf->insert_pixbuf ($textbuf->get_end_iter, $pixbuf);
}

{
  $textbuf->insert ($textbuf->get_end_iter, "\nnext line invisible\n");
  my $tag_invisible = Gtk2::TextTag->new ('invisible');
  $tag_invisible->set (invisible => 1);
  $tag_table->add ($tag_invisible);

  $textbuf->insert_with_tags ($textbuf->get_end_iter, "-----\n",
                              $tag_invisible);
}
{
  $textbuf->insert ($textbuf->get_end_iter, "next line strikethrough\n");
  my $tag_strikethrough = Gtk2::TextTag->new ('strikethrough');
  $tag_strikethrough->set (strikethrough => 1,
                           # strikethrough_set => 1,
                           background => 'pink');
  $tag_table->add ($tag_strikethrough);

  $textbuf->insert_with_tags ($textbuf->get_end_iter, "--XXX---\n\n",
                              $tag_strikethrough);
}
{
  $textbuf->insert ($textbuf->get_end_iter, "next line plain dashes\n");
  $textbuf->insert ($textbuf->get_end_iter, "---AAA------\n");
}
{
  $textbuf->insert ($textbuf->get_end_iter, "next line bold dashes\n");
  my $tag_bold = Gtk2::TextTag->new ('bold');
  # $tag_bold->set (weight => 'bold');
  $tag_bold->set (weight => 'ultraheavy',
                 # style => 'italic',
                 );
  $tag_table->add ($tag_bold);
  $textbuf->insert_with_tags ($textbuf->get_end_iter, "---AAA------\n",
                              $tag_bold);
}
{
$textbuf->insert ($textbuf->get_end_iter, "next drawingarea child\n");

my $anchor = $textbuf->create_child_anchor ($textbuf->get_end_iter);
$textbuf->insert ($textbuf->get_end_iter, "\n");

my $draw = Gtk2::DrawingArea->new;
$draw->set_size_request (40, 5);
$textview->add_child_at_anchor ($draw, $anchor);
}

$textbuf->insert ($textbuf->get_end_iter, "the end\n");

# $textbuf->insert_child_anchor ($textbuf->get_end_iter, $anchor);
# $textbuf->insert ($textbuf->get_end_iter, "nop\n");


print Data::Dumper->Dump([$textbuf->get('text')],['get(text)']);
print Data::Dumper->Dump([$textbuf->get_text($textbuf->get_start_iter,
                                             $textbuf->get_end_iter,
                                             1)
                         ], ['get_text']);


{
  my $iter = $textbuf->get_start_iter;
  while ((my $match_start, $iter) = $iter->forward_search ("\x{FFFC}", [])) {
    print $match_start->get_offset, " ", $iter->get_offset,
      " ", ($match_start->get_pixbuf || 'no pixbuf'), "\n";
  }
}

Glib::Timeout->add
  (15000, sub {
     my $iter = $textbuf->get_start_iter;
     for (;;) {
       print "from ",$iter->get_offset,"\n";
       my ($match_start, $match_end) = $iter->forward_search("\x{FFFC}",[])
         or last;
       my $offset = $match_start->get_offset;
       print "$match_start at $offset\n";
       my $p = $match_start->get_pixbuf;
       if (! $p) {
         $iter = $match_end;
         next;
       }
       $textbuf->delete ($match_start, $match_end);

       $p = ($p == $pixbuf ? $pixbuf2 : $pixbuf);
       print "  insert $p\n";
       $iter = $textbuf->get_iter_at_offset ($offset);
       $textbuf->insert_pixbuf ($iter, $p);
       $iter = $textbuf->get_iter_at_offset ($offset+1);
     }
     print "  done\n";
     return 1; # Glib::SOURCE_CONTINUE
   });

$toplevel->show_all;
Gtk2->main;
exit 0;
