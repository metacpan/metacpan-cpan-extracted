#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Glib::Ex::ConnectProperties;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
MyTestHelpers::glib_gtk_versions();

Gtk2::InfoBar->can('new')
  or plan skip_all => "due to Gtk2::InfoBar not available (per Gtk pre 2.20 or Perl-Gtk2 pre 1.240)";

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY";

plan tests => 6;


{
  package Foo;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->boolean
                     ('mybool',
                      'mybool',
                      'Blurb.',
                      '', # default
                      Glib::G_PARAM_READWRITE),
                    ];
}

{
  my $foo = Foo->new (mybool => 0);
  my $infobar = Gtk2::InfoBar->new ('gtk-ok' => 'ok');
  $infobar->show_all;
  my $action_area = $infobar->get_action_area;
  my $button = ($action_area->get_children)[0];
  diag $button;

  Glib::Ex::ConnectProperties->new
      ([$foo, 'mybool'],
       [$infobar, 'response-sensitive#ok', write_only => 1]);
  ok (! $foo->get('mybool'));
  ok (! $button->get('sensitive'));
  # $infobar->set_response_sensitive ('ok', 0);

  $foo->set (mybool => 1);
  ok ($foo->get('mybool'));
  ok ($button->get('sensitive'));

  $foo->set (mybool => 0);
  ok (! $foo->get('mybool'));
  ok (! $button->get('sensitive'));

  $infobar->destroy;
}

exit 0;
