#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-CellLayout-Base.
#
# Gtk2-Ex-CellLayout-Base is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-CellLayout-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-CellLayout-Base.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;

{
  package MyViewer;
  use base 'Gtk2::Ex::CellLayout::Base';
  use Gtk2 1.180; # for Gtk2::CellLayout interface
  use Glib::Object::Subclass
    'Gtk2::DrawingArea',
      interfaces => [ 'Gtk2::CellLayout' ];

  sub PACK_START {
    my ($self, $cell, $expand) = @_;
    $self->{'myviewer-subclass'} = 'hello from MyViewer';
    $self->SUPER::PACK_START ($cell, $expand);
  }
}
{
  package MyViewerWithISA;
  use Gtk2 1.180; # for Gtk2::CellLayout interface

  our @ISA;
  use Glib::Object::Subclass
    'Gtk2::DrawingArea',
      interfaces => [ 'Gtk2::CellLayout' ];
  push @ISA, 'Gtk2::Ex::CellLayout::Base';

  sub PACK_START {
    my ($self, $cell, $expand) = @_;
    $self->{'myviewer-with-isa-subclass'} = 'hello from MyViewerWithISA';
    $self->SUPER::PACK_START ($cell, $expand);
  }
}

#------------------------------------------------------------------------------

use Test::More tests => 25;

BEGIN {
 SKIP: { eval 'use Test::NoWarnings; 1'
           or skip 'Test::NoWarnings not available', 1; }
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin,'inc');
use MyTestHelpers;

my $want_version = 5;
ok ($Gtk2::Ex::CellLayout::Base::VERSION >= $want_version,
    'VERSION variable');
ok (Gtk2::Ex::CellLayout::Base->VERSION  >= $want_version,
    'VERSION class method');
ok (eval { Gtk2::Ex::CellLayout::Base->VERSION($want_version); 1 },
    "VERSION class check $want_version");
ok (! eval { Gtk2::Ex::CellLayout::Base->VERSION($want_version + 1000); 1 },
    "VERSION class check " . ($want_version + 1000));

require Gtk2;
MyTestHelpers::glib_gtk_versions();

my $have_get_cells = MyViewer->can('get_cells');
diag "have_get_cells: ",($have_get_cells ? "yes" : "no");

#------------------------------------------------------------------------------
{
  my $viewer = MyViewer->new;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 0);

  is ($viewer->{'myviewer-subclass'}, 'hello from MyViewer');
  is_deeply ([$viewer->GET_CELLS], [$renderer],
             'GET_CELLS one renderer');

 SKIP: {
    $have_get_cells or skip 'due to no ->get_cells() method', 1;
    is_deeply ([$viewer->get_cells], [$renderer],
               'get_cells() one renderer');
  }
}

{
  my $viewer = MyViewerWithISA->new;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 0);

  is ($viewer->{'myviewer-with-isa-subclass'}, 'hello from MyViewerWithISA');
  is_deeply ([$viewer->GET_CELLS], [$renderer],
             'GET_CELLS() one renderer');
 SKIP: {
    $have_get_cells or skip 'due to no ->get_cells() method', 1;
    is_deeply ([$viewer->get_cells], [$renderer],
               'get_cells() one renderer');
  }
}

#------------------------------------------------------------------------------
# reorder()

{
  my $viewer = MyViewer->new;
  my $r1 = Gtk2::CellRendererText->new;
  my $r2 = Gtk2::CellRendererText->new;
  $viewer->pack_start ($r1, 0);
  $viewer->pack_start ($r2, 0);

  $viewer->reorder ($r1, 0);
  is_deeply ([$viewer->GET_CELLS], [$r1, $r2]);

  $viewer->reorder ($r1, 1);
  is_deeply ([$viewer->GET_CELLS], [$r2, $r1]);

  $viewer->reorder ($r1, 0);
  is_deeply ([$viewer->GET_CELLS], [$r1, $r2]);
}

{
  my $viewer = MyViewer->new;
  my $r1 = Gtk2::CellRendererText->new;
  my $r2 = Gtk2::CellRendererText->new;
  my $r3 = Gtk2::CellRendererText->new;
  $viewer->pack_start ($r1, 0);
  $viewer->pack_start ($r2, 0);
  $viewer->pack_start ($r3, 0);

  $viewer->reorder ($r1, 0);
  is_deeply ([$viewer->GET_CELLS], [$r1, $r2, $r3]);

  $viewer->reorder ($r1, 1);
  is_deeply ([$viewer->GET_CELLS], [$r2, $r1, $r3]);

  $viewer->reorder ($r3, 0);
  is_deeply ([$viewer->GET_CELLS], [$r3, $r2, $r1]);

  $viewer->reorder ($r3, 2);
  is_deeply ([$viewer->GET_CELLS], [$r2, $r1, $r3]);
}

#------------------------------------------------------------------------------
# pack_start() expand flag

{
  my $viewer = MyViewer->new;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 0);
  ok (! $viewer->{'cellinfo_list'}->[0]->{'expand'},
     'expand false');
}
{
  my $viewer = MyViewer->new;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 'true');
  ok ($viewer->{'cellinfo_list'}->[0]->{'expand'},
      'expand true');
}

#------------------------------------------------------------------------------
# _set_cell_data()

{
  my $liststore = Gtk2::ListStore->new ('Glib::String');
  $liststore->set_value ($liststore->append, 0 => 'Foo');
  my $viewer = MyViewer->new;
  $viewer->{'model'} = $liststore;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 1);

  my $iter = $liststore->get_iter_first;
  $viewer->_set_cell_data ($iter, weight => 123);
  is ($renderer->get('weight'), 123,
      'extra setting through _set_cell_data');

  $viewer->add_attribute ($renderer, text => 0);
  $viewer->_set_cell_data ($iter);
  is ($renderer->get('text'), 'Foo',
      'attribute setting from add_attribute()');

  $viewer->clear_attributes ($renderer);
  $renderer->set (text => 'Blah');
  $viewer->_set_cell_data ($iter);
  is ($renderer->get('text'), 'Blah',
      'attribute setting gone after clear_attributes()');
}

#------------------------------------------------------------------------------
# _cellinfo_starts, _cellinfo_ends

{
  my $viewer = MyViewer->new;
  my $r1 = Gtk2::CellRendererText->new; $viewer->pack_start ($r1, 0);
  my $r2 = Gtk2::CellRendererText->new; $viewer->pack_end ($r2, 0);
  my $r3 = Gtk2::CellRendererText->new; $viewer->pack_end ($r3, 0);
  my $r4 = Gtk2::CellRendererText->new; $viewer->pack_start ($r4, 0);
  my $r5 = Gtk2::CellRendererText->new; $viewer->pack_start ($r5, 0);
  my $r6 = Gtk2::CellRendererText->new; $viewer->pack_end ($r6, 0);

  is_deeply ([ map {$_->{'cell'}} $viewer->_cellinfo_starts ],
             [ $r1, $r4, $r5 ],
             '_cellinfo_starts() 1,4,5');
  is_deeply ([ map {$_->{'cell'}} $viewer->_cellinfo_ends ],
             [ $r2, $r3, $r6 ],
             '_cellinfo_ends() 2,3,6');
}


exit 0;
