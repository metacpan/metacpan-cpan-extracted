#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 6;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  my $uiinfo = [
    { type => "item", label => "Item" },
    { type => "toggleitem", label => "Toggle" },
    {
      type => "subtree",
      label => "Radio Items",
      subtree => [
        {
          type => "radioitems",
          moreinfo => [
            {
              type => "item",
              label => "A"
            },
            {
              type => "item",
              label => "B",
              callback => sub { warn @_; }
            }
          ]
        }
      ]
    }
  ];

  my $additional_uiinfo = [
    { type => "item", label => "Really?" }
  ];

  #############################################################################

  my $popup = Gnome2::PopupMenu -> new($uiinfo);
  isa_ok($popup, "Gtk2::Menu");
  isa_ok($popup -> get_accel_group(), "Gtk2::AccelGroup");

  $popup = Gnome2::PopupMenu -> new_with_accelgroup($uiinfo);
  isa_ok($popup, "Gtk2::Menu");
  isa_ok($popup -> get_accel_group(), "Gtk2::AccelGroup");

  $popup = Gnome2::PopupMenu -> new_with_accelgroup($uiinfo, Gtk2::AccelGroup -> new());
  isa_ok($popup, "Gtk2::Menu");
  isa_ok($popup -> get_accel_group(), "Gtk2::AccelGroup");

  $popup -> append_from($additional_uiinfo);

  my $window = Gtk2::Window -> new("toplevel");
  my $button = Gtk2::Button -> new("BUH!");

  $window -> add($button);

  $popup -> attach_to($button);
  $popup -> attach_to($button, "blub");

  if (join("", Gtk2 -> get_version_info()) >= 220) {
    my $event = Gtk2::Gdk::Event -> new("button_press");

    $popup -> do_popup(
      sub {
        my ($menu) = @_;
        return 23, 42;
      },
      undef,
      $event,
      "bla",
      $button
    );
  }

  # FIXME: how to make it return?
  # $popup -> do_popup_modal(
  #   sub {
  #     my ($menu) = @_;
  #     return 23, 42;
  #   },
  #   undef,
  #   $event,
  #   "bla",
  #   $button
  # );

  $window -> add_popup_items($uiinfo);
  $window -> add_popup_items($uiinfo, "blab");
}
