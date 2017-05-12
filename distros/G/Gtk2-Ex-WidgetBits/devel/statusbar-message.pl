#!/usr/bin/perl -w

# Copyright 2009, 2010, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use 5.010;
use Gtk2 '-init';
use Gtk2::Ex::Statusbar::Message;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (200, -1);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $buttonbox = Gtk2::HBox->new;
$vbox->pack_start ($buttonbox, 0,0,0);

my $statusbar = Gtk2::Statusbar->new;
$vbox->pack_start ($statusbar, 0,0,0);
$statusbar->signal_connect
  (notify => sub {
     my ($statusbar, $pspec) = @_;
     my $pname = $pspec->get_name;
     print "$progname: statusbar notify \"$pname\"\n";
   });
$statusbar->signal_connect
  (text_pushed => sub {
     my ($statusbar, $context_id, $str) = @_;
     $str = quote_str($str);
     print "$progname: statusbar text-pushed $context_id $str\n";
   });
$statusbar->signal_connect
  (text_popped => sub {
     my ($statusbar, $context_id, $str) = @_;
     $str = quote_str($str);
     print "$progname: statusbar text-popped $context_id $str\n";
   });
sub quote_str {
  my ($str) = @_;
  return (defined $str ? "\"$str\"" : '[undef]');
}

my $statusbar2 = Gtk2::Statusbar->new;
$vbox->pack_start ($statusbar2, 0,0,0);
$statusbar->signal_connect (notify => sub {
                              my ($statusbar2, $pspec) = @_;
                              my $pname = $pspec->get_name;
                              print "$progname: statusbar2 notify \"$pname\"\n";
                            });

my $msg = Gtk2::Ex::Statusbar::Message->new (statusbar => $statusbar);
$msg->set_message ('Hello');
$msg->signal_connect (notify => sub {
                        my ($msg, $pspec) = @_;
                        my $pname = $pspec->get_name;
                        print "$progname: msg notify \"$pname\"\n";
                      });

{
  my $button = Gtk2::Button->new_with_label ('Switch');
  $button->signal_connect (clicked => sub {
                             print "$progname: switch\n";
                             my $old = $msg->get('statusbar');
                             my $new = (! defined $old ? $statusbar
                                        : $old == $statusbar ? $statusbar2
                                        : undef);
                             $msg->set (statusbar => $new);
                           });
  $buttonbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Change');
  my $n = -1;
  $button->signal_connect (clicked => sub {
                             print "$progname: change\n";
                             my $old = $msg->get('message');
                             my $new = $old . $n--;
                             $msg->set_message ($new);
                           });
  $buttonbox->pack_start ($button, 0,0,0);
}
{
  my $statusbar = Gtk2::Statusbar->new;
  $vbox->pack_start ($statusbar, 0,0,0);
}

# {
#   require Gtk2::Ex::Statusbar::DynamicContext;
# 
#   my $cstrobj = Gtk2::Ex::Statusbar::DynamicContext->new;
#   print "$progname: ", $cstrobj->str, "\n";
# 
#   my $cstrobj2 = Gtk2::Ex::Statusbar::DynamicContext->new;
#   print "$progname: ", $cstrobj2->str, "\n";
# 
#   undef $cstrobj;
#   $cstrobj = Gtk2::Ex::Statusbar::DynamicContext->new;
#   print "$progname: ", $cstrobj->str, "\n";
# }

$toplevel->show_all;
Gtk2->main;
exit 0;
