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

# uncomment this to run the ### lines
#use Smart::Comments;

BEGIN {
  eval { require Gtk2 }
    or plan skip_all => "due to Gtk2 module not available -- $@";
  Gtk2->init_check
    or plan skip_all => "due to no DISPLAY";
  MyTestHelpers::glib_gtk_versions();
}

plan tests => 22;


{
  package Foo;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->string
                     ('mystring',
                      'mystring',
                      'Blurb.',
                      '', # default
                      Glib::G_PARAM_READWRITE),
                    ];
}
{
  package Bar;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->boxed
                     ('myrect',
                      'myrect',
                      'Blurb.',
                      'Gtk2::Gdk::Rectangle',
                      Glib::G_PARAM_READWRITE),
                    ];
  sub SET_PROPERTY {
    my ($self, $pspec, $newval) = @_;
    ### Bar SET_PROPERTY: $newval
    ### values: $newval && $newval->values
    $self->{'myrect'} = ($newval && $newval->copy);
  }
}

#-----------------------------------------------------------------------------
# windowed DrawingArea widget 

{
  my $toplevel = Gtk2::Window->new('popup');

  my $fixed = Gtk2::Fixed->new;
  $toplevel->add ($fixed);

  my $draw = Gtk2::DrawingArea->new;
  $draw->set_size_request (2000, 1000);

  my $size_allocate_ran = 0;
  $draw->signal_connect (size_allocate => sub {
                           diag "draw size-allocate signal runs";
                           $size_allocate_ran = 1;
                         });

  $fixed->put ($draw, 20,10);
  $toplevel->show_all;

  # might have to loop to get queued resizes processed
  MyTestHelpers::main_iterations();

  ok ($size_allocate_ran, 'draw size-allocate signal runs');
  #   diag $draw->size_request->width;
  ### draw allocation: $draw->allocation->values

  my $foo_width  = Foo->new;
  my $foo_height = Foo->new;
  my $foo_x      = Foo->new;
  my $foo_y      = Foo->new;
  my $bar        = Bar->new;
  Glib::Ex::ConnectProperties->new ([$draw,'widget-allocation#width'],
                                    [$foo_width,'mystring']);
  Glib::Ex::ConnectProperties->new ([$draw,'widget-allocation#height'],
                                    [$foo_height,'mystring']);
  Glib::Ex::ConnectProperties->new ([$draw,'widget-allocation#x'],
                                    [$foo_x,'mystring']);
  Glib::Ex::ConnectProperties->new ([$draw,'widget-allocation#y'],
                                    [$foo_y,'mystring']);
  Glib::Ex::ConnectProperties->new ([$draw,'widget-allocation#rectangle'],
                                    [$bar,'myrect']);
  is ($foo_width->get('mystring'), 2000);
  is ($foo_height->get('mystring'), 1000);
  is ($foo_x->get('mystring'), 20);
  is ($foo_y->get('mystring'), 10);
  {
    my $rect = $bar->get('myrect');
    is ($rect && $rect->width, 2000);
    is ($rect && $rect->height, 1000);
    is ($rect && $rect->x, 20);
    is ($rect && $rect->y, 10);
  }

  $draw->set_size_request (500, 300);
  # must loop for $fixed to act on queued resize
  MyTestHelpers::main_iterations();

  is ($foo_width->get('mystring'), 500);
  is ($foo_height->get('mystring'), 300);
  is ($foo_x->get('mystring'), 20);
  is ($foo_y->get('mystring'), 10);
  {
    my $rect = $bar->get('myrect');
    is ($rect && $rect->width, 500);
    is ($rect && $rect->height, 300);
    is ($rect && $rect->x, 20);
    is ($rect && $rect->y, 10);
  }
  $toplevel->destroy;
}

#-----------------------------------------------------------------------------

{
  package MyNoWindow;
  use Glib::Object::Subclass 'Gtk2::Widget';
}

{
  my $toplevel = Gtk2::Window->new('popup');

  my $fixed = Gtk2::Fixed->new;
  $toplevel->add ($fixed);

  my $nowin = Gtk2::DrawingArea->new;

  my $size_allocate_ran = 0;
  $nowin->signal_connect (size_allocate => sub {
                           diag "draw size-allocate signal runs";
                           $size_allocate_ran = 1;
                         });

  $fixed->put ($nowin, 2,1);
  $toplevel->show_all;

  # might have to loop to get queued resizes processed
  MyTestHelpers::main_iterations();

  ok ($size_allocate_ran, 'draw size-allocate signal runs');

  my $foo_x      = Foo->new;
  my $foo_y      = Foo->new;
  Glib::Ex::ConnectProperties->new ([$nowin,'widget-allocation#x'],
                                    [$foo_x,'mystring']);
  Glib::Ex::ConnectProperties->new ([$nowin,'widget-allocation#y'],
                                    [$foo_y,'mystring']);
  is ($foo_x->get('mystring'), 2);
  is ($foo_y->get('mystring'), 1);

  $fixed->move ($nowin, 4,3);

  # might have to loop for $fixed to act
  MyTestHelpers::main_iterations();

  is ($foo_x->get('mystring'), 4);
  is ($foo_y->get('mystring'), 3);

  $toplevel->destroy;
}

exit 0;
