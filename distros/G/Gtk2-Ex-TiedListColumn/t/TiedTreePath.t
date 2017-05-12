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
use Test::More tests => 2543;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::TiedTreePath;

my $want_version = 5;
is ($Gtk2::Ex::TiedTreePath::VERSION, $want_version, 'VERSION variable');
is (Gtk2::Ex::TiedTreePath->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Gtk2::Ex::TiedTreePath->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::TiedTreePath->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();


#------------------------------------------------------------------------------
# new

{
  my $path = Gtk2::TreePath->new;
  my $aref = Gtk2::Ex::TiedTreePath->new ($path);
  require Scalar::Util;
  Scalar::Util::weaken ($aref);
  is ($aref, undef, 'aref garbage collected when weakened');
}

{
  my $path = Gtk2::TreePath->new;
  my $aref = Gtk2::Ex::TiedTreePath->new ($path);
  require Scalar::Util;
  Scalar::Util::weaken ($path);
  ok ($path, 'store held alive by aref');
  $aref = undef;
  is ($path, undef, 'then garbage collected when aref gone');
}


#------------------------------------------------------------------------------
# accessors

{
  my $path = Gtk2::TreePath->new;
  my @array;
  tie @array, 'Gtk2::Ex::TiedTreePath', $path, 0;
  my $tobj = tied(@array);

  is ($tobj->VERSION, $want_version, 'VERSION object method');
  $tobj->VERSION ($want_version);

  is ($tobj->path, $path, 'path() accessor');
}

{
  my $path = Gtk2::TreePath->new;
  my $aref = Gtk2::Ex::TiedTreePath->new ($path);
  my $tobj = tied(@$aref);

  is ($tobj->VERSION, $want_version, 'VERSION object method');
  $tobj->VERSION ($want_version);

  is (tied(@$aref)->path, $path, 'path() accessor');
}


#------------------------------------------------------------------------------

my $path = Gtk2::TreePath->new;
tie (my @ttp, 'Gtk2::Ex::TiedTreePath', $path);

sub path_contents {
  return [$path->get_indices];
}

sub set_path {
  while ($path->up) {}
  while (@_) { $path->append_index (shift @_) }
}

#------------------------------------------------------------------------------
# fetch

{
  my @array;
  tie @array, 'Gtk2::Ex::TiedTreePath', $path;

  set_path ();
  is ($array[0], undef);
  is ($array[1], undef);

  set_path (123);
  is ($array[0], '123');
  is ($array[1], undef);
  is ($array[-1], '123');

  set_path (123, 456);
  is ($array[0], 123);
  is ($array[1], 456);
  is ($array[2], undef);
  is ($array[-1], 456);
  is ($array[-2], 123);
}


#------------------------------------------------------------------------------
# store

{
  set_path (10);
  is_deeply (path_contents(), [10], 'STORE to 1');
  $ttp[-1] = 20;
  is_deeply (path_contents(), [20], 'STORE to -1 of 1');

  set_path (3, 4);
  $ttp[0] = 5;
  is_deeply (path_contents(), [5,4]);
  $ttp[1] = 66;
  is_deeply (path_contents(), [5,66], 'STORE to last of 2');
  $ttp[-1] = 77;
  is_deeply (path_contents(), [5,77], 'STORE to -1');
  $ttp[-2] = 123;
  is_deeply (path_contents(), [123,77]);

  set_path (10,11,12,13,14);
  $ttp[2] = 22;
  is_deeply (path_contents(), [10,11,22,13,14],
             'STORE to middle');

  set_path (11, 22);
  $ttp[2] = 33;
  is_deeply (path_contents(), [11,22,33],
             'immediate past end');

  set_path (10, 11);
  $ttp[5] = 15;
  is_deeply (path_contents(), [10,11,0,0,0,15],
             'a distance past end');
}

#------------------------------------------------------------------------------
# fetchsize

{
  set_path ();
  is ($#ttp, -1);
  is (scalar(@ttp), 0);

  set_path (10);
  is ($#ttp, 0);
  is (scalar(@ttp), 1);

  set_path (10,20);
  is ($#ttp, 1);
  is (scalar(@ttp), 2);

  set_path (10,20,30);
  is ($#ttp, 2);
  is (scalar(@ttp), 3);
}

#------------------------------------------------------------------------------
# storesize

{
  set_path ();
  $#ttp = -1;
  is_deeply (path_contents(), []);

  set_path ();
  $#ttp = -2;
  is_deeply (path_contents(), []);

  set_path (100);
  $#ttp = -1;
  is_deeply (path_contents(), [],
             'storesize truncate from 1 to empty');

  set_path (100);
  $#ttp = 0;
  is_deeply (path_contents(), [100],
             'storesize unchanged 1');

  set_path (100,101,102,103);
  $#ttp = 1;
  is_deeply (path_contents(), [100,101],
             'storesize truncate from 4 to 2');

  set_path ();
  $#ttp = 2;
  is_deeply (path_contents(), [0,0,0],
             'extend 0 to 3');

  set_path (10);
  $#ttp = 1;
  is_deeply (path_contents(), [10,0],
             'extend 1 to 2');

  set_path (10,20);
  $#ttp = 3;
  is_deeply (path_contents(), [10,20,0,0],
             'extend 2 to 4');
}


#------------------------------------------------------------------------------
# exists

{
  set_path ();
  ok (! exists($ttp[0]));
  ok (! exists($ttp[1]));
  ok (! exists($ttp[-1]));

  set_path (123);
  ok (  exists($ttp[0]));
  ok (! exists($ttp[1]));
  ok (! exists($ttp[2]));
  ok (  exists($ttp[-1]));
  ok (! exists($ttp[-2]));
  ok (! exists($ttp[-99]));

  my @plain = (111,222);
  set_path (111,222);
  foreach my $i (-3 .. 3) {
    is (exists($ttp[$i]), exists($plain[$i]), "exists $i");
  }
}

#------------------------------------------------------------------------------
# delete

{
  set_path ();
  is_deeply ([delete $ttp[0]], [undef],
             'delete sole element - return');
  is_deeply (path_contents(), [],
             'delete non-existent - contents');

  set_path (123);
  is_deeply ([delete $ttp[0]], [123],
             'delete sole element - return');
  is_deeply (path_contents(), [],
             'delete sole element - contents');

  set_path (456);
  is_deeply ([delete $ttp[99]], [undef],
             'delete big non-existent - return');
  is_deeply (path_contents(), [456],
             'delete big non-existent - contents');

  set_path (1,2);
  is_deeply ([delete $ttp[0]], [1]);
  is_deeply (path_contents(), [0,2]);

  set_path (1,2);
  is_deeply ([delete $ttp[1]], [2]);
  is_deeply (path_contents(), [1],
             'delete last of 2');

  set_path (1,2,3,4,5);
  is_deeply ([delete $ttp[-2]], [4],
             'delete -2 of 5 - return');
  is_deeply (path_contents(), [1,2,3,0,5],
             'delete -2 of 5 - contents');

  set_path ();
  is_deeply ([delete $ttp[-1]], [undef],
             'delete -1 of 0 - return');
  is_deeply (path_contents(), [],
             'delete -1 of 0 - contents');

  set_path (1,2);
  is_deeply ([delete $ttp[-100]], [undef],
             'delete -100 of 2 - return');
  is_deeply (path_contents(), [1,2],
             'delete -100 of 2 - contents');

}

#------------------------------------------------------------------------------
# clear

{
  set_path ();
  @ttp = ();
  is_deeply (path_contents(), [],
             'clear empty');

  set_path (9);
  @ttp = ();
  is_deeply (path_contents(), [],
             'clear 1');

  set_path (9,9,9);
  @ttp = ();
  is_deeply (path_contents(), [],
             'clear 3');
}


#------------------------------------------------------------------------------
# push

{
  set_path ();
  push @ttp, 123;
  is_deeply (path_contents(), [123]);

  push @ttp, 456,789;
  is_deeply (path_contents(), [123,456,789]);
}

#------------------------------------------------------------------------------
# pop

{
  set_path ();
  is (pop @ttp, undef,
             'pop empty - scalar context');
  is_deeply ([pop @ttp], [pop @{[]}],
             'pop empty - array context');
  is_deeply (path_contents(), [],
             'pop empty - contents');

  set_path (123);
  is (pop @ttp, 123);
  is_deeply (path_contents(), []);

  set_path (1,2);
  is (pop @ttp, 2);
  is_deeply (path_contents(), [1]);
}

#------------------------------------------------------------------------------
# shift

{
  set_path ();
  my @plain;
  is_deeply ([shift @ttp], [shift @plain]);
  is_deeply (path_contents(), [],
             'shift empty');

  set_path (123);
  is_deeply ([shift @ttp], [123]);
  is_deeply (path_contents(), []);

  set_path (1,2);
  is_deeply ([shift @ttp], [1]);
  is_deeply (path_contents(), [2]);

  set_path (1,2,3,4);
  is_deeply ([shift @ttp], [1]);
  is_deeply (path_contents(), [2,3,4]);
}

#------------------------------------------------------------------------------
# unshift

{
  set_path ();
  my @plain;
  is (unshift(@ttp,123), unshift(@plain,123));
  is_deeply (path_contents(), [123]);

  set_path ();
  @plain = ();
  is (unshift(@ttp,1,2,3), unshift(@plain,1,2,3));
  is_deeply (path_contents(), [1,2,3]);

  is (unshift(@ttp,4,5), unshift(@plain,4,5));
  is_deeply (path_contents(), [4,5,1,2,3]);
}


#------------------------------------------------------------------------------
# splice

{
  set_path (1,2);
  my $got = splice @ttp, -2,2;
  is ($got, 2, 'splice -2,2 to empty, scalar return');

  my @plain = (1,2);
  $got = splice @plain, -2,2;
  is ($got, 2, 'splice -2,2 to empty on plain, scalar return');
}

# this is pretty excessive, but makes sure to cover all combinations of
# positive and negative offset and length exceeding or not the array bounds.
#
SKIP: {
  my @plain;

  my $ttp_warn = 0;
  my $plain_warn = 0;
  my $ttp_warn_handler = sub {
    my ($msg) = @_;
    if ($msg =~ /^splice()/) {
      $ttp_warn++;
    } else {
      warn $msg;
    }
  };
  my $plain_warn_handler = sub {
    my ($msg) = @_;
    if ($msg =~ /^splice()/) {
      $plain_warn++;
    } else {
      warn $msg;
    }
  };
  foreach my $old_content ([], [10], [10,20],
                           [10,20,30], [10,20,30,40]) {
    foreach my $new_content ([], [9], [5,6,7]) {
      foreach my $offset (-3 .. 3) {
        if ($offset < - @$old_content) { next; }

        foreach my $length (-3 .. 3) {
          my $name =
            "old=" . join(':',@$old_content) . ""
              . ", splice "
                . " " . (defined $offset ? $offset : 'undef')
                  . "," . (defined $length ? $length : 'undef')
                    . "  " . join(':',@$new_content) . "";

          set_path (@$old_content);
          @plain = @$old_content;

          my $ttp_scalar;
          { local $SIG{__WARN__} = $ttp_warn_handler;
            $ttp_scalar = scalar (splice @ttp, $offset, $length, @$new_content);
          }
          my $plain_scalar;
          { local $SIG{__WARN__} = $plain_warn_handler;
            $plain_scalar = scalar (splice @plain, $offset, $length, @$new_content);
          }
          @plain = map {defined $_ ? $_ : 0} @plain;

          is        ($ttp_scalar, $plain_scalar,
                     "scalar context return: " . $name);
          is_deeply (path_contents(), \@plain,
                     "scalar context leaves: " . $name);

          set_path (@$old_content);
          @plain = @$old_content;
          my $ttp_aret;
          { local $SIG{__WARN__} = $ttp_warn_handler;
            $ttp_aret = [splice @ttp, $offset, $length, @$new_content];
          }
          my $plain_aret;
          { local $SIG{__WARN__} = $plain_warn_handler;
            $plain_aret = [splice @plain, $offset, $length, @$new_content];
          }
          @plain = map {defined $_ ? $_ : 0} @plain;

          is_deeply ($ttp_aret, $plain_aret,
                     "array context return: " . $name);
          is_deeply (path_contents(), \@plain,
                     "array context leaves: " . $name);
        }
      }
    }
  }
  is ($ttp_warn, $plain_warn, 'warnings count');
}

exit 0;
