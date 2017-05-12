#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Dragger.
#
# Gtk2-Ex-Dragger is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dragger is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dragger.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Gtk2::Ex::Dragger;

require Gtk2;
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
plan tests => 32;

MyTestHelpers::glib_gtk_versions();

#------------------------------------------------------------------------------
# VERSION

my $want_version = 10;
{
  is ($Gtk2::Ex::Dragger::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::Dragger->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Gtk2::Ex::Dragger->VERSION($want_version); 1 },
      "VERSION class check $want_version");

  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::Dragger->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# gc weaken

{
  my $widget = Gtk2::DrawingArea->new;
  my $adj = Gtk2::Adjustment->new (100, -100, 1000, 10, 100, 800);
  my $dragger = Gtk2::Ex::Dragger->new (widget => $widget,
                                        hadjustment => $adj);

  ok ($dragger->VERSION >= $want_version, 'VERSION object method');
  ok (eval { $dragger->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $dragger->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  require Scalar::Util;
  Scalar::Util::weaken ($dragger);
  is ($dragger, undef, 'garbage collect when weakened');
}

{
  my $widget = Gtk2::DrawingArea->new;
  my $adj = Gtk2::Adjustment->new (100, -100, 1000, 10, 100, 800);
  my $dragger = Gtk2::Ex::Dragger->new (widget => $widget,
                                        hadjustment => $adj);

  Scalar::Util::weaken ($widget);
  is ($widget, undef, 'attached widget garbage collect when weakened');
}

#------------------------------------------------------------------------------
# cursor properties

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

{
  my $dragger = Gtk2::Ex::Dragger->new;
  my %notifies;
  $dragger->signal_connect (notify => sub {
                              my ($dragger, $pspec) = @_;
                              $notifies{$pspec->get_name} = 1;
                            });

  # claimed defaults
  is ($dragger->get('cursor'), undef, 'cursor - default');
  is ($dragger->get('cursor-name'), undef, 'cursor-name - default');
  is ($dragger->get('cursor-object'), undef, 'cursor-object - default');

  # string
  %notifies = ();
  $dragger->set (cursor => 'boat');
  is ($dragger->get('cursor'), 'boat');
  is ($dragger->get('cursor-name'), 'boat');
  is ($dragger->get('cursor-object'), undef);
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1});

  # object
  my $fleur = Gtk2::Gdk::Cursor->new ('fleur');
  %notifies = ();
  $dragger->set (cursor => $fleur);
  ok (glib_boxed_equal ($dragger->get('cursor'), $fleur));
  is ($dragger->get('cursor-name'), 'fleur');
  # boxed objects not equal
  ok (glib_boxed_equal ($dragger->get('cursor-object'), $fleur));
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1});

  # cursor-name string
  %notifies = ();
  $dragger->set (cursor_name => 'umbrella');
  is ($dragger->get('cursor'), 'umbrella');
  is ($dragger->get('cursor-name'), 'umbrella');
  is ($dragger->get('cursor-object'), undef);
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1},
             'set() cursor-name "hand1" - notify triple');

  # cursor-object object
  %notifies = ();
  $dragger->set (cursor_object => Gtk2::Gdk::Cursor->new('hand1'));
  ok (glib_boxed_equal ($dragger->get('cursor'),
                        Gtk2::Gdk::Cursor->new('hand1')),
      'set() cursor-object "hand1" - get cursor');
  is ($dragger->get('cursor-name'), 'hand1',
      'set() cursor-object "hand1" - get cursor-name');
  ok (glib_boxed_equal ($dragger->get('cursor-object'),
                        Gtk2::Gdk::Cursor->new('hand1')),
      'set() cursor-object "hand1" - get cursor-object');
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1},
             'set() cursor-object "hand1" - notify triple');

  # cursor-object pixmap
  {
    %notifies = ();
    my $rootwin = Gtk2::Gdk->get_default_root_window;
    my $pixmap = Gtk2::Gdk::Pixmap->new ($rootwin, 1, 1, -1);
    my $bitmap = Gtk2::Gdk::Pixmap->new ($rootwin, 1, 1, 1);
    my $cursor_obj = Gtk2::Gdk::Cursor->new_from_pixmap
      ($pixmap,
       $bitmap,
       Gtk2::Gdk::Color->new(0,0,0,0), # fg
       Gtk2::Gdk::Color->new(0,0,0,0), # bg
       0,0); # x,y hotspot
    $dragger->set (cursor_object => $cursor_obj);
    ok (glib_boxed_equal ($dragger->get('cursor'),
                          $cursor_obj),
        'set() cursor-object pixmap - get cursor');
    is ($dragger->get('cursor-name'), undef,
        'set() cursor-object pixmap - get cursor-name');
    ok (glib_boxed_equal ($dragger->get('cursor-object'),
                          $cursor_obj),
        'set() cursor-object pixmap - get cursor-object');
    is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1},
               'set() cursor-object pixmap - notify triple');
  }
}

exit 0;
