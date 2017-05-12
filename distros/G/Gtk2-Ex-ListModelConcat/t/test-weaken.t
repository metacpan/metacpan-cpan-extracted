#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ListModelConcat.
#
# Gtk2-Ex-ListModelConcat is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ListModelConcat is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ListModelConcat.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2::Ex::ListModelConcat;
use Test::More;

my $have_test_weaken = eval "use Test::Weaken 2.000;
                             use Test::Weaken::Gtk2;
                             1";
if (! $have_test_weaken) {
  plan skip_all => "due to Test::Weaken 2.000 and/or Test::Weaken::Gtk2 not available -- $@";
}
plan tests => 3;

diag ("Test::Weaken version ", Test::Weaken->VERSION);
require Gtk2;


#------------------------------------------------------------------------------

{
  my $leaks = Test::Weaken::leaks
    (sub {
       return Gtk2::Ex::ListModelConcat->new;
     });
  is ($leaks, undef, 'deep garbage collection');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $store = Gtk2::ListStore->new ('Glib::String');
       my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $store ]);
       return [ $concat, $store ];
     });
  is ($leaks, undef, 'with one sub-model');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain($leaks);
  }
}

{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $s1 = Gtk2::ListStore->new ('Glib::String');
       my $s2 = Gtk2::ListStore->new ('Glib::String');
       my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);
       return [ $concat, $s1, $s2 ];
     });
  is ($leaks, undef, 'with two sub-models');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain($leaks);
  }
}

exit 0;
