#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TreeModelFilter-DragDest.
#
# Gtk2-Ex-TreeModelFilter-DragDest is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or (at your
# option) any later version.
#
# Gtk2-Ex-TreeModelFilter-DragDest is distributed in the hope that it will
# be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TreeModelFilter-DragDest.  If not, see
# <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2::Ex::TreeModelFilter::Draggable;
use Test::More tests => 20;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin,'inc');

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $want_version = 3;
is ($Gtk2::Ex::TreeModelFilter::Draggable::VERSION, $want_version,
        'VERSION variable');
is (Gtk2::Ex::TreeModelFilter::Draggable->VERSION, $want_version,
        'VERSION class method');
{ ok (eval { Gtk2::Ex::TreeModelFilter::Draggable->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval{Gtk2::Ex::TreeModelFilter::Draggable->VERSION($check_version); 1},
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  my $filter = Gtk2::Ex::TreeModelFilter::Draggable->new ($store);

  isa_ok ($filter, 'Gtk2::Ex::TreeModelFilter::Draggable');
  isa_ok ($filter, 'Gtk2::TreeModelFilter');
  isa_ok ($filter, 'Gtk2::TreeModel');
  isa_ok ($filter, 'Gtk2::TreeDragSource');
  isa_ok ($filter, 'Gtk2::TreeDragDest')
    or diag "ISA is ".join(' ',@Gtk2::Ex::TreeModelFilter::Draggable::ISA);

  require Scalar::Util;
  Scalar::Util::weaken ($filter);
  is ($filter, undef, 'garbage collected when weakened');
}

ok (! eval { Gtk2::Ex::TreeModelFilter::Draggable->new; 1 },
    'too few args to new()');

{ my $tree = Gtk2::TreeStore->new ('Glib::String');
  { my $top = $tree->insert_after (undef, undef);
    $tree->set ($top, 0 => 123);
    my $sub = $tree->insert_after ($top, undef);
    $tree->set ($sub, 0 => 456);
  }

  my $root = Gtk2::TreePath->new_from_indices (0);
  my $filter = Gtk2::Ex::TreeModelFilter::Draggable->new ($tree, $root);

  ok (! eval { Gtk2::Ex::TreeModelFilter::Draggable->new ($tree, $root, 123);
               1 },
      'too many args to new()');

  is ($filter->get_value($filter->get_iter_first, 0), 456,
      'filtered sub-row');
}

package MySubclass;
use strict;
use warnings;
use Glib;
use Gtk2::Ex::TreeModelFilter::Draggable;
use Glib::Object::Subclass
  Gtk2::Ex::TreeModelFilter::Draggable::;

package main;
{ my $store = Gtk2::ListStore->new ('Glib::String');
  my $filter = MySubclass->new (child_model => $store,
                                virtual_root => Gtk2::TreePath->new);

  isa_ok ($filter, 'MySubclass');
  isa_ok ($filter, 'Gtk2::Ex::TreeModelFilter::Draggable');
  isa_ok ($filter, 'Gtk2::TreeModelFilter');
  isa_ok ($filter, 'Gtk2::TreeModel');
  isa_ok ($filter, 'Gtk2::TreeDragSource');
  isa_ok ($filter, 'Gtk2::TreeDragDest')
    or diag "ISA is ".join(' ',@Gtk2::Ex::TreeModelFilter::Draggable::ISA);

  require Scalar::Util;
  Scalar::Util::weaken ($filter);
  is ($filter, undef, 'garbage collected when weakened');
}

exit 0;
