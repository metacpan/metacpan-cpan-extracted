#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2014 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Glib::Ex::SourceIds;
use Test::More tests => 18;

use lib 't';
use MyTestHelpers;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

require Glib;
MyTestHelpers::glib_gtk_versions();

# suppresss for example
#   GLib-CRITICAL **: Source ID 3 was not found when attempting to remove it at t/SourceIds.t line 80.
# Is there another way to enquire whether a source ID exists?
#
Glib::Log->set_handler ('GLib', ['critical'], \&my_log_func);
sub my_log_func {
  my ($log_domain, $log_levels, $message) = @_;
  if ($message =~ /source .* not found/i) {
    return;
  }
  warn $message;
}

sub do_idle {
  diag "idle";
  return 0; # Glib::SOURCE_REMOVE
}

# version number
{
  my $want_version = 16;
  is ($Glib::Ex::SourceIds::VERSION, $want_version, 'VERSION variable');
  is (Glib::Ex::SourceIds->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Glib::Ex::SourceIds->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  ok (! eval { Glib::Ex::SourceIds->VERSION($want_version + 1000); 1 },
      "VERSION class check " . ($want_version + 1000));

  my $ids = Glib::Ex::SourceIds->new;
  is ($ids->VERSION, $want_version, 'VERSION object method');
  ok (eval { $ids->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $ids->VERSION($want_version + 1000); 1 },
      "VERSION object check " . ($want_version + 1000));
}

# the SourceIds object gets garbage collected when weakened
{
  my $id = Glib::Idle->add (\&do_idle);
  my $ids = Glib::Ex::SourceIds->new ($id);
  require Scalar::Util;
  Scalar::Util::weaken ($ids);
  is ($ids, undef,
      'SourceIds destroyed when weakened');
  ok (! Glib::Source->remove ($id),
      'held source disconnected by destroy');
}

# two held IDs disconnected
{
  my $id1 = Glib::Idle->add (\&do_idle);
  my $id2 = Glib::Idle->add (\&do_idle);
  my $ids = Glib::Ex::SourceIds->new ($id1, $id2);
  require Scalar::Util;
  Scalar::Util::weaken ($ids);
  is ($ids, undef,
      'SourceIds destroyed when weakened');
  ok (! Glib::Source->remove ($id1),
      'id1 disconnected by destroy');
  ok (! Glib::Source->remove ($id2),
      'id2 disconnected by destroy');
}

# two by add()
{
  my $id1 = Glib::Idle->add (\&do_idle);
  my $id2 = Glib::Idle->add (\&do_idle);
  my $ids = Glib::Ex::SourceIds->new;
  $ids->add ($id1, $id2);
  require Scalar::Util;
  Scalar::Util::weaken ($ids);
  is ($ids, undef,
      'add()ed SourceIds destroyed when weakened');
  ok (! Glib::Source->remove ($id1),
      'add()ed id1 disconnected by destroy');
  ok (! Glib::Source->remove ($id2),
      'add()ed id2 disconnected by destroy');
}

# SourceIds can cope if held ID is disconnected elsewhere
{
  my $id = Glib::Idle->add (\&do_idle);
  my $ids = Glib::Ex::SourceIds->new ($id);
  ok (Glib::Source->remove ($id), 'early remove');
  $ids = undef;
}

# explicit early remove
{
  my $id = Glib::Idle->add (\&do_idle);
  my $ids = Glib::Ex::SourceIds->new ($id);
  $ids->remove;
  ok (! Glib::Source->remove ($id),
      'early remove, already done');
}

exit 0;

