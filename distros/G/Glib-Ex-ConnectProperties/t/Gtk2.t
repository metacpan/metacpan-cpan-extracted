#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN {
  MyTestHelpers::nowarnings();

  eval { require Gtk2; 1 }
    or plan skip_all => "due to Gtk2 module not available -- $@";
}

plan tests => 40;

require Glib::Ex::ConnectProperties;
MyTestHelpers::glib_gtk_versions();


## no critic (ProtectPrivateSubs)

#-----------------------------------------------------------------------------
# boxed -- Gtk2::Border
#
# It the past it might have been necessary to load up Gtk2::Entry for it to
# register Gtk2::Boxed.  That's no longer so, as of Gtk2 circa 1.202.

{ my $pspec = Glib::ParamSpec->boxed ('foo','foo','blurb',
                                      'Gtk2::Border', ['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec, undef, undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec, undef, {left=>1,right=>2,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec, {left=>1,right=>2,top=>3,bottom=>4}, undef));

  ok (Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>2,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>0,right=>2,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>0,top=>3,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>2,top=>0,bottom=>4}));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       {left=>1,right=>2,top=>3,bottom=>4},
       {left=>1,right=>2,top=>3,bottom=>0}));
}

#-----------------------------------------------------------------------------
# enum Gtk2::Justification from Gtk2::Label

{ my $label = Gtk2::Label->new;
  my $pname = 'justify';
  my $pspec = $label->find_property ($pname)
    or die "Oops, Gtk2::Label doesn't have property '$pname'";
  diag "Gtk2::Label '$pname' pspec ",ref $pspec,
    ", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'right','right'));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'left','left'));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'right','left'));
}

#-----------------------------------------------------------------------------
# GdkColor - comparison by R/G/B contents using its 'equal' method

{ my $pspec = Glib::ParamSpec->boxed ('foo','foo','blurb',
                                      'Gtk2::Gdk::Color',['readable']);

  my $c1 = Gtk2::Gdk::Color->new (1,2,3);
  my $c1b = Gtk2::Gdk::Color->new (1,2,3);
  my $c2 = Gtk2::Gdk::Color->new (0,2,3);
  my $c3 = Gtk2::Gdk::Color->new (1,0,3);
  my $c4 = Gtk2::Gdk::Color->new (1,2,0);
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c1));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c1b));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c2));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c3));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $c1,$c4));
}

#-----------------------------------------------------------------------------
# boxed -- Gtk2::Gdk::Rectangle

{
  package MyRRR;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->boxed
                     ('rect',
                      'rect',
                      'Blurb.',
                      'Gtk2::Gdk::Rectangle',
                      Glib::G_PARAM_READWRITE),
                    ];
  sub SET_PROPERTY {
    my ($self, $pspec, $newval) = @_;
    ### Bar SET_PROPERTY: $newval
    ### values: $newval && $newval->values
    $self->{'rect'} = ($newval && $newval->copy);
  }
}

SKIP: {
  # eval {Glib->VERSION(1.240);1}
  #   or skip 'due to value_validate() buggy on non ref counted boxed before 1.240', 18;

  my $o1 = MyRRR->new;
  my $o2 = MyRRR->new;
  Glib::Ex::ConnectProperties->new ([$o1,'rect'],
                                    [$o2,'rect']);
  is ($o1->get('rect'), undef, 'o1 rect initial undef');
  is ($o2->get('rect'), undef, 'o2 rect initial undef');

  $o1->set(rect => Gtk2::Gdk::Rectangle->new(1,2,3,4));
  foreach my $o ($o1, $o2) {
    my $r = $o->get('rect');
    is ($r && $r->x, 1, 'r.x');
    is ($r && $r->y, 2);
    is ($r && $r->width, 3);
    is ($r && $r->height, 4);
  }

  $o2->set(rect => Gtk2::Gdk::Rectangle->new(5,6,7,8));
  foreach my $o ($o1, $o2) {
    my $r = $o->get('rect');
    is ($r && $r->x, 5, 'r.x');
    is ($r && $r->y, 6);
    is ($r && $r->width, 7);
    is ($r && $r->height, 8);
  }
}
SKIP: {
  # eval {Glib->VERSION(1.240);1}
  #   or skip 'due to value_validate() buggy on non ref counted boxed before 1.240', 6;

  my $o1 = MyRRR->new;
  my $o2 = MyRRR->new;
  Glib::Ex::ConnectProperties->new
      ([$o1,'rect'],
       [$o2,'rect',
        write_only => 1,
        func_in => sub {
          my ($rect) = @_;
          return $rect && $rect->new ($rect->x * 10,
                                      $rect->y * 10,
                                      $rect->width * 10,
                                      $rect->height * 10);

        }]);
  is ($o1->get('rect'), undef, 'o1 rect initial undef');
  is ($o2->get('rect'), undef, 'o2 rect initial undef');

  $o1->set(rect => Gtk2::Gdk::Rectangle->new(1,2,3,4));
  my $r = $o2->get('rect');
  is ($r && $r->x, 10, 'r.x');
  is ($r && $r->y, 20);
  is ($r && $r->width, 30);
  is ($r && $r->height, 40);
}

exit 0;
