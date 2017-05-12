#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TiedListColumn.
#
# Gtk2-Ex-TiedListColumn is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TiedListColumn is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TiedListColumn.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2::Ex::TiedListColumn;
use Test::More tests => 2525;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $want_version = 5;
is ($Gtk2::Ex::TiedListColumn::VERSION, $want_version, 'VERSION variable');
is (Gtk2::Ex::TiedListColumn->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Gtk2::Ex::TiedListColumn->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::TiedListColumn->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();
diag "ListStore can('insert_with_values'): ",
  Gtk2::ListStore->can('insert_with_values')||'no',"\n";


#------------------------------------------------------------------------------
# new

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  my $aref = Gtk2::Ex::TiedListColumn->new ($store);
  require Scalar::Util;
  Scalar::Util::weaken ($aref);
  is ($aref, undef, 'aref garbage collected when weakened');
}

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  my $aref = Gtk2::Ex::TiedListColumn->new ($store);
  require Scalar::Util;
  Scalar::Util::weaken ($store);
  ok ($store, 'store held alive by aref');
  $aref = undef;
  is ($store, undef, 'then garbage collected when aref gone');
}


#------------------------------------------------------------------------------
# accessors

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  my @array;
  tie @array, 'Gtk2::Ex::TiedListColumn', $store, 0;
  my $tobj = tied(@array);

  is ($tobj->VERSION, $want_version, 'VERSION object method');
  $tobj->VERSION ($want_version);

  is ($tobj->model, $store,
      'model() accessor');
  is ($tobj->column, 0,
      'column() accessor');
}

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  my $aref = Gtk2::Ex::TiedListColumn->new ($store);
  my $tobj = tied(@$aref);

  is ($tobj->VERSION, $want_version, 'VERSION object method');
  $tobj->VERSION ($want_version);

  is (tied(@$aref)->model, $store,
      'model() accessor');
  is (tied(@$aref)->column, 0,
      'column() accessor');
}


#------------------------------------------------------------------------------

my $store = Gtk2::ListStore->new (('Glib::Int') x 6, 'Glib::String');
tie my @tarr, 'Gtk2::Ex::TiedListColumn', $store, 6;
my @plain;

sub store_contents {
  my @ret;
  for (my $iter = $store->get_iter_first;
       $iter;
       $iter = $store->iter_next($iter)) {
    push @ret, $store->get_value($iter,6);
  }
  return \@ret;
}

sub set_store {
  @plain = @_;
  $store->clear;
  foreach (@_) {
    my $iter = $store->insert (999);
    $store->set_value ($iter, 6 => $_);
  }
}

#------------------------------------------------------------------------------
# fetch

{
  my @tarr;
  tie @tarr, 'Gtk2::Ex::TiedListColumn', $store, 6;

  set_store ();
  is ($tarr[0], undef);
  is ($tarr[1], undef);

  set_store ('a');
  is ($tarr[0], 'a');
  is ($tarr[1], undef);
  is ($tarr[-1], 'a');

  set_store ('a','b');
  is ($tarr[0], 'a');
  is ($tarr[1], 'b');
  is ($tarr[2], undef);
  is ($tarr[-1], 'b');
  is ($tarr[-2], 'a');
}


#------------------------------------------------------------------------------
# store

{
  set_store ('a');
  $tarr[0] = 'b';
  $plain[0] = 'b';
  is_deeply (store_contents(), \@plain);
  $tarr[-1] = 'c';
  $plain[-1] = 'c';
  is_deeply (store_contents(), \@plain);

  set_store ('a','b');
  $tarr[0] = 'x';
  $plain[0] = 'x';
  is_deeply (store_contents(), \@plain);
  $tarr[1] = 'y';
  $plain[1] = 'y';
  is_deeply (store_contents(), \@plain);
  $tarr[-1] = 'z';
  $plain[-1] = 'z';
  is_deeply (store_contents(), \@plain);
  $tarr[-2] = 'w';
  $plain[-2] = 'w';
  is_deeply (store_contents(), \@plain);

  set_store ('a','b');
  $tarr[2] = 'x';
  $plain[2] = 'x';
  is_deeply (store_contents(), \@plain,
             'immediate past end');

  set_store ('a','b');
  $tarr[5] = 'x';
  $plain[5] = 'x';
  is_deeply (store_contents(), \@plain,
             'a distance past end');
}


#------------------------------------------------------------------------------
# fetchsize

{
  set_store ('a');
  my @tarr;
  tie @tarr, 'Gtk2::Ex::TiedListColumn', $store;

  set_store ();
  is ($#tarr, -1);
  is (scalar(@tarr), 0);

  set_store ('a');
  is ($#tarr, 0);
  is (scalar(@tarr), 1);

  set_store ('a','b');
  is ($#tarr, 1);
  is (scalar(@tarr), 2);
}


#------------------------------------------------------------------------------
# storesize

{
  set_store ();
  $#tarr = -1;
  $#plain = -1;
  is_deeply (store_contents(), \@plain);

  set_store ();
  $#tarr = -2;
  $#plain = -2;
  is_deeply (store_contents(), \@plain);

  set_store ('b');
  $#tarr = -1;
  $#plain = -1;
  is_deeply (store_contents(), \@plain,
             'storesize truncate from 1 to empty');

  set_store ('b');
  $#tarr = 0;
  $#plain = 0;
  is_deeply (store_contents(), \@plain,
             'storesize unchanged 1');

  set_store ('a','b','c','d');
  $#tarr = 1;
  $#plain = 1;
  is_deeply (store_contents(), \@plain,
             'storesize truncate from 4 to 2');

  set_store ();
  $#tarr = 2;
  $#plain = 2;
  is_deeply (store_contents(), \@plain,
             'extend 0 to 3');

  set_store ('a');
  $#tarr = 1;
  $#plain = 1;
  is_deeply (store_contents(), \@plain,
             'extend 1 to 2');
}

#------------------------------------------------------------------------------
# exists

{
  set_store ();
  is (exists($tarr[0]), exists($plain[0]));
  is (exists($tarr[1]), exists($plain[1]));
  is (exists($tarr[-1]), exists($plain[-1]));

  set_store ('b');
  is (exists($tarr[0]), exists($plain[0]));
  is (exists($tarr[1]), exists($plain[1]));
  is (exists($tarr[2]), exists($plain[2]));
  is (exists($tarr[-1]), exists($plain[-1]));
  is (exists($tarr[-2]), exists($plain[-2]));
  is (exists($tarr[-99]), exists($plain[-99]));

  set_store ('a','b');
  foreach my $i (-3 .. 3) {
    is (exists($tarr[$i]), exists($plain[$i]), "exists $i");
  }
}



#------------------------------------------------------------------------------
# delete

{
  set_store ();
  delete $tarr[0];
  delete $plain[0];
  is_deeply (store_contents(), \@plain,
             'delete non-existent');

  set_store ('a');
  delete $tarr[0];
  delete $plain[0];
  is_deeply (store_contents(), \@plain,
             'delete sole element');

  set_store ('a');
  delete $tarr[99];
  delete $plain[99];
  is_deeply (store_contents(), \@plain,
             'delete big non-existent');

  set_store ('a','b');
  delete $tarr[0];
  delete $plain[0];
  is_deeply (store_contents(), \@plain);
  #
  # tied array not the same as ordinary perl array for exists on deleted
  # elements
  # is (exists($tarr[0]), exists($plain[0]));

  set_store ('a','b');
  delete $tarr[1];
  delete $plain[1];
  is_deeply (store_contents(), \@plain,
             'delete last of 2');

}


#------------------------------------------------------------------------------
# clear

{
  set_store ();
  @tarr = ();
  @plain = ();
  is_deeply (store_contents(), \@plain,
             'clear empty');

  set_store ('a','b','c');
  @tarr = ();
  @plain = ();
  is_deeply (store_contents(), \@plain,
             'clear 3');
}


#------------------------------------------------------------------------------
# push

SKIP: {
  $store->can('insert_with_values')
    or skip 'no insert_with_values() for push', 2;

  set_store ();
  push @tarr, 'z';
  push @plain, 'z';
  is_deeply (store_contents(), \@plain);

  push @tarr, 'x','y';
  push @plain, 'x','y';
  is_deeply (store_contents(), \@plain);
}

#------------------------------------------------------------------------------
# pop

{
  set_store ();
  is (pop @tarr, pop @plain,
      'pop empty - scalar context');
  is_deeply ([pop @tarr], [pop @plain],
             'pop empty - array context');
  is_deeply (store_contents(), \@plain,
             'pop empty');

  set_store ('x');
  is (pop @tarr, pop @plain);
  is_deeply (store_contents(), \@plain);

  set_store ('x','y');
  is (pop @tarr, pop @plain);
  is_deeply (store_contents(), \@plain);
}

#------------------------------------------------------------------------------
# shift

{
  set_store ();
  is_deeply ([shift @tarr], [shift @plain]);
  is_deeply (store_contents(), \@plain,
             'shift empty');

  set_store ('x');
  is_deeply ([shift @tarr], [shift @plain]);
  is_deeply (store_contents(), \@plain);

  set_store ('x','y');
  is_deeply ([shift @tarr], [shift @plain]);
  is_deeply (store_contents(), \@plain);
}

#------------------------------------------------------------------------------
# unshift

SKIP: {
  $store->can('insert_with_values')
    or skip 'no insert_with_values() for unshift', 4;

  set_store ();
  is (unshift(@tarr,'z'), unshift(@plain,'z'));
  is_deeply (store_contents(), \@plain);

  is (unshift(@tarr,'x','y'), unshift(@plain,'x','y'));
  is_deeply (store_contents(), \@plain);
}


#------------------------------------------------------------------------------
# splice

{
  set_store ('a','b');
  my $got = splice @tarr, -2,2;
  is ($got, 'b', 'splice -2,2 to empty, scalar return');

  my @plain = ('a','b');
  $got = splice @plain, -2,2;
  is ($got, 'b', 'splice -2,2 to empty on plain, scalar return');
}

# this is pretty excessive, but makes sure to cover all combinations of
# positive and negative offset and length exceeding or not the array bounds.
#
SKIP: {
  $store->can('insert_with_values')
    or skip 'no insert_with_values() for splice', 2437;

  my $tarr_warn = 0;
  my $plain_warn = 0;
  local $SIG{__WARN__} = sub {
    my ($msg) = @_;
    if ($msg =~ /^TiedListColumn/) {
      $tarr_warn++;
    } elsif ($msg =~ /^splice()/) {
      $plain_warn++;
    } else {
      print STDERR $msg;
    }
  };
  foreach my $old_content ([], ['w'], ['w','x'],
                           ['w','x','y'], ['w','x','y','z']) {
    foreach my $new_content ([], ['f'], ['f','g','h']) {
      foreach my $offset (-3 .. 3) {
        if ($offset < - @$old_content) { next; }

        foreach my $length (-3 .. 3) {
          my $name =
            "'" . join(',',@$old_content) . "'"
              . " splice "
                . " " . (defined $offset ? $offset : 'undef')
                  . "," . (defined $length ? $length : 'undef')
                    . "  '" . join(',',@$new_content) . "'";

          set_store (@$old_content);
          my $tarr_ret = scalar (splice @tarr, $offset, $length, @$new_content);
          my $plain_ret = scalar (splice @plain, $offset, $length, @$new_content);
          is        ($tarr_ret, $plain_ret,
                     "scalar context return: " . $name);
          is_deeply (store_contents(), \@plain,
                     "scalar context leaves: " . $name);

          set_store (@$old_content);
          $tarr_ret = [splice @tarr, $offset, $length, @$new_content];
          $plain_ret = [splice @plain, $offset, $length, @$new_content];
          is_deeply ($tarr_ret, $plain_ret,
                     "array context return: " . $name);
          is_deeply (store_contents(), \@plain,
                     "array context leaves: " . $name);
        }
      }
    }
  }
  is ($tarr_warn, $plain_warn, 'warnings count');
}

exit 0;
