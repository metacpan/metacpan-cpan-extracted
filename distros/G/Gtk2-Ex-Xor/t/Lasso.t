#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

require Gtk2::Ex::Lasso;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
MyTestHelpers::glib_gtk_versions();

plan tests => 58;


sub my_lasso_start {
  my ($lasso) = @_;
  my $oldwarn = $SIG{'__WARN__'};
  local $SIG{'__WARN__'} = sub {
    my ($str) = @_;
    if ($str =~ /^Lasso->start\(\): cannot grab pointer/) {
      diag $str;
    } else {
      $oldwarn->(@_);
    }
  };
  $lasso->start;
}

#------------------------------------------------------------------------------
# VERSION

my $want_version = 22;
is ($Gtk2::Ex::Lasso::VERSION, $want_version, 'VERSION variable');
is (Gtk2::Ex::Lasso->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Gtk2::Ex::Lasso->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::Lasso->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}
{
  my $lasso = Gtk2::Ex::Lasso->new;
  is ($lasso->VERSION, $want_version, 'VERSION object method');
  ok (eval { $lasso->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $lasso->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#-----------------------------------------------------------------------------

sub show_wait {
  my ($widget) = @_;
  my $t_id = Glib::Timeout->add (10_000, sub {
                                   diag "Timeout waiting for map event";
                                   exit 1;
                                 });
  my $s_id = $widget->signal_connect (map_event => sub {
                                        Gtk2->main_quit;
                                        return 0; # propagate event
                                      });
  $widget->show;
  Gtk2->main;
  $widget->signal_handler_disconnect ($s_id);
  Glib::Source->remove ($t_id);
}

# return an arrayref
sub leftover_fields {
  my ($widget) = @_;
  return [ grep /Gtk2::Ex::Lasso/, keys %$widget ];
}


# destroyed when weakened inactive
{
  my $widget = Gtk2::Window->new ('toplevel');
  my $lasso = Gtk2::Ex::Lasso->new (widget => $widget);
  my $weak_lasso = $lasso;
  require Scalar::Util;
  Scalar::Util::weaken ($weak_lasso);
  $lasso = undef;
  MyTestHelpers::main_iterations();
  is ($weak_lasso, undef, 'inactive Lasso weakened');
  is_deeply (leftover_fields($widget), [],
             'no Lasso data left behind from inactive');
  $widget->destroy;
}

# destroyed when weakened active
{
  my $widget = Gtk2::Window->new ('toplevel');
  my $lasso = Gtk2::Ex::Lasso->new (widget => $widget);
  show_wait ($widget);
  my_lasso_start($lasso);
  my $weak_lasso = $lasso;
  Scalar::Util::weaken ($weak_lasso);
  $lasso = undef;
  is ($weak_lasso, undef, 'active Lasso weakened');
  is_deeply (leftover_fields($widget), [],
             'no Lasso data left behind from active');
  $widget->destroy;
}

# start() emits "notify::active"
{
  my $widget = Gtk2::Window->new ('toplevel');
  show_wait ($widget);
  my $lasso = Gtk2::Ex::Lasso->new (widget => $widget);
  my $seen_notify = 0;
  $lasso->signal_connect ('notify::active' => sub { $seen_notify = 1; });
  my_lasso_start($lasso);
  is ($seen_notify, 1, 'start() emits notify::active');
  $widget->destroy;
}

# end() emits "notify::active"
{
  my $widget = Gtk2::Window->new ('toplevel');
  show_wait ($widget);
  my $lasso = Gtk2::Ex::Lasso->new (widget => $widget);
  my_lasso_start($lasso);
  my $seen_notify = 0;
  $lasso->signal_connect ('notify::active' => sub { $seen_notify = 1; });
  $lasso->end;
  is ($seen_notify, 1, 'end() emits notify::active');
  $widget->destroy;
}

#------------------------------------------------------------------------------
# cursor properties

# return true if two Glib::Boxed objects $b1 and $b2 point to the same
# underlying C object
sub glib_boxed_equal {
  my ($b1, $b2) = @_;
  if (! defined $b1 || ! defined $b2) {
    return 0;
  }
  diag "b1 type:";
  diag $b1->type;
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
  my $lasso = Gtk2::Ex::Lasso->new;
  my %notifies;
  $lasso->signal_connect (notify => sub {
                            my ($lasso, $pspec) = @_;
                            $notifies{$pspec->get_name} = 1;
                          });

  # claimed defaults
  is ($lasso->get('cursor'),
      'hand1', 'cursor - default hand1');
  is ($lasso->get('cursor-name'), 'hand1',
      'cursor-name - default hand1');
  is ($lasso->get('cursor-object'), undef,
      'cursor-object - default merely undef');

 SKIP: {
    my $pspec = $lasso->find_property ('cursor');
    $pspec->can('get_default_value')
      or skip 'no pspec get_default_value() for Glib::ParamSpec->scalar() until Perl-Gtk2 1.240', 1;
  TODO: {
      local $TODO = 'no settable default for Glib::ParamSpec->scalar() yet';
      is ($pspec->get_default_value, 'hand1',
          'cursor - pspec get_default_value()');
    }
  }
  {
    my $pspec = $lasso->find_property ('cursor-name');
    is ($pspec->get_default_value, 'hand1',
        'cursor-name - pspec get_default_value()');
  }
 SKIP: {
    my $pspec = $lasso->find_property ('cursor-object');
    $pspec->can('get_default_value')
      or skip 'no pspec get_default_value() for Glib::ParamSpec->scalar() until Perl-Gtk2 1.240', 1;

    is ($pspec->get_default_value, undef,
        'cursor-object - pspec get_default_value() undef as yet');
  }

  # string
  %notifies = ();
  $lasso->set (cursor => 'boat');
  is ($lasso->get('cursor'), 'boat',
      'set() cursor "boat" - get cursor');
  is ($lasso->get('cursor-name'), 'boat',
      'set() cursor "boat" - get cursor-name');
  is ($lasso->get('cursor-object'), undef,
      'set() cursor "boat" - get cursor-object');
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1},
             'set() cursor "boat" - notify triple');

  # object
  my $fleur = Gtk2::Gdk::Cursor->new ('fleur');
  %notifies = ();
  $lasso->set (cursor => $fleur);
  ok (glib_boxed_equal ($lasso->get('cursor'), $fleur),
      'set() cursor fleur-obj - get cursor');
  is ($lasso->get('cursor-name'), 'fleur',
      'set() cursor fleur-obj - get cursor-name');
  # boxed objects not equal
  ok (glib_boxed_equal ($lasso->get('cursor-object'), $fleur),
      'set() cursor fleur-obj - get cursor-object');
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1},
             'set() cursor fleur-obj - notify triple');

  # cursor-name string
  %notifies = ();
  $lasso->set (cursor_name => 'umbrella');
  is ($lasso->get('cursor'), 'umbrella',
      'set() cursor-name "umbrella" - get cursor');
  is ($lasso->get('cursor-name'), 'umbrella',
      'set() cursor-name "umbrella" - get cursor-name');
  is ($lasso->get('cursor-object'), undef,
      'set() cursor-name "umbrella" - get cursor-object');
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1},
             'set() cursor-name "umbrella" - notify triple');

  # cursor-object object
  %notifies = ();
  $lasso->set (cursor_object => Gtk2::Gdk::Cursor->new ('plus'));
  ok (glib_boxed_equal ($lasso->get('cursor'),
                        Gtk2::Gdk::Cursor->new('plus')),
      'set() cursor-object "plus" - get cursor');
  is ($lasso->get('cursor-name'), 'plus',
      'set() cursor-object "plus" - get cursor-name');
  # boxed objects not equal
  ok (glib_boxed_equal ($lasso->get('cursor-object'),
                        Gtk2::Gdk::Cursor->new('plus')),
      'set() cursor-object "plus" - get cursor-object');
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1},
             'set() cursor-object "plus" - notify triple');

  # cursor-object pixmap
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
  $lasso->set (cursor_object => $cursor_obj);
  ok (glib_boxed_equal ($lasso->get('cursor'), $cursor_obj),
      'set() cursor-object pixmap - get cursor');
  is ($lasso->get('cursor-name'), undef,
      'set() cursor-object pixmap - get cursor-name');
  ok (glib_boxed_equal ($lasso->get('cursor-object'), $cursor_obj),
      'set() cursor-object pixmap - get cursor-object');
  is_deeply (\%notifies, {cursor=>1,cursor_name=>1,cursor_object=>1},
             'set() cursor-object pixmap - notify triple');
}

#------------------------------------------------------------------------------
# foreground properties

# return true if two Glib::Boxed objects $b1 and $b2 point to the same
# underlying C object
{
  my $n = 0;
  sub color_parts {
    my ($color) = @_;
    if (Scalar::Util::blessed($color)) {
      return $color->red .','. $color->blue .','. $color->green;
    } else {
      return 'not-a-color-object'.$n++;
    }
  }
}

{
  my $lasso = Gtk2::Ex::Lasso->new;
  my %notifies;
  $lasso->signal_connect (notify => sub {
                            my ($lasso, $pspec) = @_;
                            my $pname = $pspec->get_name;
                            $notifies{$pname} = 1;
                          });

  # claimed defaults
  is ($lasso->get('foreground'), undef, 'foreground - default undef');
  is ($lasso->get('foreground-name'), undef, 'foreground-name - default undef');
  is ($lasso->get('foreground-gdk'), undef,
      'foreground-gdk - default undef');

  # string
  %notifies = ();
  $lasso->set (foreground => 'white');
  is ($lasso->get('foreground'), 'white');
  is ($lasso->get('foreground-name'), 'white');
  is (color_parts ($lasso->get('foreground-gdk')),
      color_parts (Gtk2::Gdk::Color->parse('white')),
      'foreground string - foreground-gdk value');
  is_deeply (\%notifies, {foreground=>1,foreground_name=>1,foreground_gdk=>1},
             'foreground string - notifies');

  # object
  my $red = Gtk2::Gdk::Color->new (65535,0,0);
  %notifies = ();
  $lasso->set (foreground => $red);
  is (color_parts ($lasso->get('foreground')),
      color_parts ($red));
  is ($lasso->get('foreground-name'), '#ffff00000000');
  # boxed objects not equal
  is (color_parts ($lasso->get('foreground-gdk')),
      color_parts ($red));
  is_deeply (\%notifies, {foreground=>1,foreground_name=>1,foreground_gdk=>1},
             'foreground object notifies');

  # foreground-name string
  %notifies = ();
  $lasso->set (foreground_name => 'black');
  is ($lasso->get('foreground'), 'black');
  is ($lasso->get('foreground-name'), 'black');
  is (color_parts ($lasso->get('foreground-gdk')),
      color_parts (Gtk2::Gdk::Color->new (0,0,0)));
  is_deeply (\%notifies, {foreground=>1,foreground_name=>1,foreground_gdk=>1},
             'foreground-name notifies');

  # foreground-gdk object
  my $green = Gtk2::Gdk::Color->new (0,65535,0);
  %notifies = ();
  $lasso->set (foreground_gdk => $green);
  is (color_parts ($lasso->get('foreground')),
      color_parts ($green));
  is ($lasso->get('foreground-name'), '#0000ffff0000');
  # boxed objects not equal
  is (color_parts ($lasso->get('foreground-gdk')),
      color_parts ($green));
  is_deeply (\%notifies, {foreground=>1,foreground_name=>1,foreground_gdk=>1});
}

exit 0;
