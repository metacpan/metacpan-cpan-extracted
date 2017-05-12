#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-History is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-History.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2::Ex::History::ModelSensitive;

plan tests => 20;

#-----------------------------------------------------------------------------
my $want_version = 8;
my $check_version = $want_version + 1000;
is ($Gtk2::Ex::History::ModelSensitive::VERSION, $want_version,
    'VERSION variable');
is (Gtk2::Ex::History::ModelSensitive->VERSION,  $want_version,
    'VERSION class method');
{ ok (eval { Gtk2::Ex::History::ModelSensitive->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  ok (! eval { Gtk2::Ex::History::ModelSensitive->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# new()
{
  my $ms = Gtk2::Ex::History::ModelSensitive->new;
  isa_ok ($ms, 'Gtk2::Ex::History::ModelSensitive');

  is ($ms->VERSION, $want_version, 'VERSION object method');
  ok (eval { $ms->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $ms->VERSION($want_version + 1000); 1 },
      "VERSION object check " . ($want_version + 1000));

  Scalar::Util::weaken ($ms);
  is ($ms, undef, 'gc when weakened');
}

#------------------------------------------------------------------------------

{
  my $model = Gtk2::ListStore->new ('Glib::String');
  my $target = Gtk2::Label->new;

  my $ms = Gtk2::Ex::History::ModelSensitive->new ($target, $model);
  ok (! $target->get('sensitive'));

  $model->append;
  ok ($target->get('sensitive'));
  $model->append;
  ok ($target->get('sensitive'));

  $model->remove ($model->get_iter_first);
  ok ($target->get('sensitive'));

  $model->remove ($model->get_iter_first);
  ok (! $target->get('sensitive'));

  Scalar::Util::weaken ($ms);
  is ($ms, undef, 'gc when weakened, with model and target');
}

# initially non-empty
{
  my $model = Gtk2::ListStore->new ('Glib::String');
  $model->append;
  my $target = Gtk2::Label->new;
  $target->set_sensitive (0);

  my $ms = Gtk2::Ex::History::ModelSensitive->new ($target, $model);
  ok ($target->get('sensitive'));

  $model->append;
  ok ($target->get('sensitive'));

  $model->remove ($model->get_iter_first);
  ok ($target->get('sensitive'));

  $model->remove ($model->get_iter_first);
  ok (! $target->get('sensitive'));

  Scalar::Util::weaken ($ms);
  is ($ms, undef, 'gc when weakened, with model and target');
}

exit 0;
