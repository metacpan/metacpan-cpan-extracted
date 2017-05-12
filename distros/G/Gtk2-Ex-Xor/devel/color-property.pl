#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2;

# uncomment this to run the ### lines
use Smart::Comments;

{
  package MyObject;
  use Glib::Object::Subclass 'Glib::Object',
    properties => [
                   Glib::ParamSpec->boxed
                   ('foreground-gdk',
                    'foreground-gdk',
                    'The colour to draw the lasso, as a Gtk2::Gdk::Color object with red,greed,blue fields set (a pixel is looked up on the target widget).',
                    'Gtk2::Gdk::Color',
                    Glib::G_PARAM_READWRITE),
                  ];

  my $c;
  sub GET_PROPERTY {
    my ($self, $pspec) = @_;
    my $pname = $pspec->get_name;
    my $c = Gtk2::Gdk::Color->new(1,2,3);
    ### ret: $c->to_string
    return $c;
  }
  sub SET_PROPERTY {
    my ($self, $pspec, $newval) = @_;
    my $pname = $pspec->get_name;
    ### $newval
    ### str: $newval->to_string
    $self->{$pname} = $newval;
  }
}

my $obj = MyObject->new;
my $c = $obj->get('foreground-gdk');
### str: $c->to_string
exit 0;
