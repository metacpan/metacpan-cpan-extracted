#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2::Ex::WidgetCursor;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# for invisible cursor bits
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

plan tests => 57;
MyTestHelpers::glib_gtk_versions();

# return an arrayref
sub leftover_fields {
  my ($widget) = @_;
  my @leftover = grep /Gtk2::Ex::WidgetCursor/, keys %$widget;
  if (@leftover) {
    my %leftover;
    @leftover{@leftover} = @{$widget}{@leftover}; # hash slice
    diag "leftover fields: ", keys %leftover;
  }
  return \@leftover;
}

#-----------------------------------------------------------------------------
# VERSION

{
  my $want_version = 15;
  is ($Gtk2::Ex::WidgetCursor::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::WidgetCursor->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Gtk2::Ex::WidgetCursor->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::WidgetCursor->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $wc = Gtk2::Ex::WidgetCursor->new;
  is ($wc->VERSION, $want_version, 'VERSION object method');
  ok (eval { $wc->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $wc->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#-----------------------------------------------------------------------------
# _container_recursively()

{
  my $label = Gtk2::Label->new;
  is_deeply ([Gtk2::Ex::WidgetCursor::_container_recursively($label)],
             [$label],
             '_container_recursively - label only');

  my $box = Gtk2::HBox->new;
  is_deeply ([Gtk2::Ex::WidgetCursor::_container_recursively($box)],
             [$box],
             '_container_recursively - empty box');

  $box->add ($label);
  is_deeply ([Gtk2::Ex::WidgetCursor::_container_recursively($box)],
             [$box, $label],
             '_container_recursively - box containing label');

  my $box2 = Gtk2::HBox->new;
  $box2->add ($box);
  is_deeply ([Gtk2::Ex::WidgetCursor::_container_recursively($box2)],
             [$box2, $box, $label],
             '_container_recursively - box2,box,label');
}

{
  my $widget = Gtk2::Label->new;
  my @want = ($widget);
  foreach (1 .. 200) {
    my $box = Gtk2::HBox->new;
    $box->add ($widget);
    $widget = $box;
    unshift @want, $box;
  }
  is_deeply ([Gtk2::Ex::WidgetCursor::_container_recursively($widget)],
             \@want,
             '_container_recursively - ok on very deep nesting');
}

#-----------------------------------------------------------------------------

# return true if two Glib::Boxed objects $b1 and $b2 point to the same
# underlying C object
sub glib_boxed_equal {
  my ($b1, $b2) = @_;
  my $pspec = Glib::ParamSpec->boxed ('equal', 'equal', 'blurb', ref($b1),
                                      Glib::G_PARAM_READWRITE());
  if ($pspec->can('values_cmp')) {
    # new in Perl-Glib 1.220
    return $pspec->values_cmp($b1,$b2) == 0;
  } else {
    return 1;
  }
}

my $have_blank_cursor = scalar grep {$_->{'nick'} eq 'blank-cursor'}
  Glib::Type->list_values('Gtk2::Gdk::CursorType');
diag "have_blank_cursor is $have_blank_cursor";


# In Perl-Gtk2 before 1.183, passing undef, ie. NULL, to
# Gtk2::Gdk::Display->open() prints warnings, so do it with an actual
# $display_name string.
#
my $default_display = Gtk2::Gdk::Display->get_default;
my $display_name = $default_display->get_name;

# invisible cursor type
{
  my $cursor = Gtk2::Ex::WidgetCursor->invisible_cursor;
  is ($cursor->type,
      ($have_blank_cursor ? 'blank-cursor' : 'cursor-is-pixmap'),
      'invisible cursor type (blank or pixmap as available)');
}

# In the current code this ends up depending on
# gdk_cursor_new_for_display() to cache 'blank-cursor'.  Want to know if
# it doesn't, since the WidgetCursor docs claim invisible_cursor() caches.
#
ok (glib_boxed_equal (Gtk2::Ex::WidgetCursor->invisible_cursor,
                      Gtk2::Ex::WidgetCursor->invisible_cursor),
    'same invisible cursor object on repeat calls');

# different invisible object on different displays
SKIP: {
  my $d1 = $default_display;
  my $d2 = Gtk2::Gdk::Display->open ($display_name);
  if ($d1 == $d2) {
    skip 'due to only one GdkDisplay available', 1;
  }
  my $c1 = Gtk2::Ex::WidgetCursor->invisible_cursor ($d1);
  my $c2 = Gtk2::Ex::WidgetCursor->invisible_cursor ($d2);
  isnt ($c1, $c2);
}

# an invisible cursor hung on a display doesn't keep that object alive
# forever
SKIP: {
  require Scalar::Util;
  my $d = Gtk2::Gdk::Display->open ($display_name);
  if ($d == $default_display) {
    skip 'due to only one GdkDisplay available', 1;
  }
  my $c = Gtk2::Ex::WidgetCursor->invisible_cursor ($d);
  my $weak = $d;
  Scalar::Util::weaken ($weak);
  $d->close;
  $d = undef;
  is ($weak, undef);
}


# WidgetCursor should be garbage collected
{
  my $widget = Gtk2::Label->new ('hi');
  my $wobj = Gtk2::Ex::WidgetCursor->new (widget => $widget);
  Scalar::Util::weaken ($wobj);
  is ($wobj, undef, 'inactive - garbage collect');

  ok (! MyTestHelpers::any_signal_connections($widget),
      'inactive - no leftover signal connections on widget');
  is_deeply (leftover_fields($widget), [],
             'inactive - no leftover fields on widget');
}

# WidgetCursor should be garbage collected when active
{
  my $widget = Gtk2::Label->new ('hi');
  my $wobj = Gtk2::Ex::WidgetCursor->new (widget => $widget,
                                          active => 1);
  Scalar::Util::weaken ($wobj);
  is ($wobj, undef, 'active - garbage collect');

  ok (! MyTestHelpers::any_signal_connections($widget),
      'active - no leftover signal connections on widget');
  is_deeply (leftover_fields($widget), [],
             'active - no leftover fields on widget');
}

# two WidgetCursors should be garbage collected
{
  my $widget = Gtk2::Label->new ('hi');
  my $wobj1 = Gtk2::Ex::WidgetCursor->new (widget => $widget);
  my $wobj2 = Gtk2::Ex::WidgetCursor->new (widget => $widget);
  Scalar::Util::weaken ($wobj1);
  Scalar::Util::weaken ($wobj2);
  is ($wobj1, undef);
  is ($wobj2, undef);
}

# WidgetCursor on a realized widget should be garbage collected
{
  my $widget = Gtk2::Window->new ('toplevel');
  $widget->show;
  my $wobj = Gtk2::Ex::WidgetCursor->new (widget => $widget);
  Scalar::Util::weaken ($wobj);
  is ($wobj, undef);
}

# WidgetCursor doesn't keep widget alive forever
{
  my $widget = Gtk2::Label->new ('hi');
  my $wobj = Gtk2::Ex::WidgetCursor->new (widget => $widget);
  Scalar::Util::weaken ($widget);
  is ($widget, undef);
  if ($widget) {
    MyTestHelpers::findrefs($widget);
  }
}

# WidgetCursor doesn't keep widgets array alive forever
{
  my $widget1 = Gtk2::Label->new ('hi');
  my $widget2 = Gtk2::Label->new ('bye');
  my $aref = [$widget1, $widget2];
  my $wobj = Gtk2::Ex::WidgetCursor->new (widgets => $aref);

  Scalar::Util::weaken ($aref);
  is ($aref, undef);

  Scalar::Util::weaken ($widget1);
  is ($widget1, undef);

  Scalar::Util::weaken ($widget2);
  is ($widget2, undef);
}

# WidgetCursor add_widgets doesn't keep widget alive forever
{
  my $widget = Gtk2::Label->new ('hi');
  my $wobj = Gtk2::Ex::WidgetCursor->new;
  $wobj->add_widgets ($widget);
  Scalar::Util::weaken ($widget);
  is ($widget, undef);
}

# add_widgets with weakened undefs in wobj
{
  my $widget = Gtk2::Label->new ('hi');
  my $wobj = Gtk2::Ex::WidgetCursor->new (widgets => [ $widget ]);
  $widget = Gtk2::Label->new ('bye');
  $wobj->add_widgets ($widget);
}

# GtkButton when unrealized
{
  my $widget = Gtk2::Button->new;
  my @windows = grep {defined} $widget->Gtk2_Ex_WidgetCursor_windows;
  is_deeply (\@windows, [], ref($widget).' no window when unrealized');
}

# GtkTextView when unrealized
{
  my $widget = Gtk2::TextView->new;
  my @windows = grep {defined} $widget->Gtk2_Ex_WidgetCursor_windows;
  is_deeply (\@windows, [], ref($widget).' no window when unrealized');
}

# GtkEntry when unrealized
{
  my $widget = Gtk2::Entry->new;
  my @windows = grep {defined} $widget->Gtk2_Ex_WidgetCursor_windows;
  is_deeply (\@windows, [], ref($widget).' no window when unrealized');
}

# GtkSpinButton when unrealized
{
  my $adj = Gtk2::Adjustment->new (0, -100, 100, 1, 10, 0);
  my $widget = Gtk2::SpinButton->new ($adj, 10, 0);
  my @windows = grep {defined} $widget->Gtk2_Ex_WidgetCursor_windows;
  is_deeply (\@windows, [], ref($widget).' no window when unrealized');
}

#------------------------------------------------------------------------------
# cursor properties

{
  my $wcursor = Gtk2::Ex::WidgetCursor->new;
  my %notifies;
  $wcursor->signal_connect (notify => sub {
                              my ($wcursor, $pspec) = @_;
                              $notifies{$pspec->get_name} = 1;
                            });

  # claimed defaults
  is ($wcursor->get('cursor'), undef, 'cursor - default');
  is ($wcursor->get('cursor-name'), undef, 'cursor-name - default');
  is ($wcursor->get('cursor-object'), undef, 'cursor-object - default');

  # string
  %notifies = ();
  $wcursor->set (cursor => 'boat');
  is ($wcursor->get('cursor'), 'boat');
  is ($wcursor->get('cursor-name'), 'boat');
  is ($wcursor->get('cursor-object'), undef);
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1});

  # object
  my $fleur = Gtk2::Gdk::Cursor->new ('fleur');
  %notifies = ();
  $wcursor->set (cursor => $fleur);
  ok (glib_boxed_equal ($wcursor->get('cursor'), $fleur));
  is ($wcursor->get('cursor-name'), 'fleur');
  # boxed objects not equal
  ok (glib_boxed_equal ($wcursor->get('cursor-object'), $fleur));
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1});

  # cursor-name string
  %notifies = ();
  $wcursor->set (cursor_name => 'umbrella');
  is ($wcursor->get('cursor'), 'umbrella');
  is ($wcursor->get('cursor-name'), 'umbrella');
  is ($wcursor->get('cursor-object'), undef);
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1});

  # cursor-object object
  my $hand1 = Gtk2::Gdk::Cursor->new ('hand1');
  %notifies = ();
  $wcursor->set (cursor_object => $hand1);
  ok (glib_boxed_equal ($wcursor->get('cursor'), $hand1));
  is ($wcursor->get('cursor-name'), 'hand1');
  # boxed objects not equal
  ok (glib_boxed_equal ($wcursor->get('cursor-object'), $hand1));
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1});

  # cursor() method
  %notifies = ();
  $wcursor->cursor('watch');
  is ($wcursor->get('cursor'), 'watch');
  is ($wcursor->get('cursor-name'), 'watch');
  is ($wcursor->get('cursor-object'), undef);
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1});
}

exit 0;
