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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::TiedMenuChildren;

require Gtk2;
MyTestHelpers::glib_gtk_versions();

Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
plan tests => 2546;

my $want_version = 5;
is ($Gtk2::Ex::TiedMenuChildren::VERSION, $want_version,
    'VERSION variable');
is (Gtk2::Ex::TiedMenuChildren->VERSION,  $want_version,
    'VERSION class method');
{ ok (eval { Gtk2::Ex::TiedMenuChildren->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::TiedMenuChildren->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# new

{
  my $menu = Gtk2::Menu->new;
  my $aref = Gtk2::Ex::TiedMenuChildren->new ($menu);
  require Scalar::Util;
  Scalar::Util::weaken ($aref);
  is ($aref, undef, 'aref garbage collected when weakened');
}

{
  my $menu = Gtk2::Menu->new;
  my $aref = Gtk2::Ex::TiedMenuChildren->new ($menu);
  require Scalar::Util;
  Scalar::Util::weaken ($menu);
  ok ($menu, 'store held alive by aref');
  $aref = undef;
  is ($menu, undef, 'then garbage collected when aref gone');
}


#------------------------------------------------------------------------------
# accessors

{
  my $menu = Gtk2::Menu->new;
  my @array;
  tie @array, 'Gtk2::Ex::TiedMenuChildren', $menu;
  my $tobj = tied(@array);

  is ($tobj->VERSION, $want_version, 'VERSION object method');
  $tobj->VERSION ($want_version);

  is ($tobj->menu, $menu, 'menu() accessor');
}


#------------------------------------------------------------------------------

my $menu = Gtk2::Menu->new;
tie (my @ttp, 'Gtk2::Ex::TiedMenuChildren', $menu);

sub menu_contents {
  return [$menu->get_children];
}

sub set_menu {
  foreach my $item ($menu->get_children) {
    $menu->remove ($item);
  }
  foreach my $item (@_) {
    $menu->append ($item);
  }
}

my $one   = Gtk2::MenuItem->new_with_label('one');   $one->set_name('One');
my $two   = Gtk2::MenuItem->new_with_label('two');   $two->set_name('Two');
my $three = Gtk2::MenuItem->new_with_label('three'); $three->set_name('Three');
my $four  = Gtk2::MenuItem->new_with_label('four');  $four->set_name('Four');
my $five  = Gtk2::MenuItem->new_with_label('five');  $five->set_name('Five');
my $six   = Gtk2::MenuItem->new_with_label('six');   $six->set_name('Six');
my $seven = Gtk2::MenuItem->new_with_label('seven'); $seven->set_name('Seven');
my $eight = Gtk2::MenuItem->new_with_label('eight'); $eight->set_name('Eight');
my $nine  = Gtk2::MenuItem->new_with_label('nine');  $nine->set_name('Nine');


#------------------------------------------------------------------------------
# fetch

{
  my @array;
  tie @array, 'Gtk2::Ex::TiedMenuChildren', $menu;

  is ($array[0], undef);
  is ($array[1], undef);

  $menu->add ($one);
  is ($array[0], $one);
  is ($array[1], undef);
  is ($array[-1], $one);

  $menu->append ($two);
  is ($array[0], $one);
  is ($array[1], $two);
  is ($array[2], undef);
  is ($array[-1], $two);
  is ($array[-2], $one);
}


#------------------------------------------------------------------------------
# store

{
  set_menu ();
  $ttp[1] = $two;
  is_deeply (menu_contents(), [$one], 'STORE to 1');
  $ttp[-1] = $two;
  is_deeply (menu_contents(), [$two], 'STORE to -1 of 1');

  set_menu ($one, $two);
  $ttp[0] = $three;
  is_deeply (menu_contents(), [$three, $two]);
  $ttp[1] = $four;
  is_deeply (menu_contents(), [$three, $four], 'STORE to last of 2');
  $ttp[-1] = $five;
  is_deeply (menu_contents(), [$three, $five], 'STORE to -1');
  $ttp[-2] = $one;
  is_deeply (menu_contents(), [$one, $five]);

  set_menu ($one, $two, $three, $four, $five);
  $ttp[2] = $six;
  is_deeply (menu_contents(), [$one, $two, $six, $four, $five],
             'STORE to middle');

  set_menu ($one, $two);
  $ttp[2] = $three;
  is_deeply (menu_contents(), [$one, $two, $three],
             'immediate past end');

  set_menu ($one, $two);
  $ttp[5] = $three;
  is_deeply (menu_contents(), [$one, $two, $three],
             'a distance past end');

  set_menu ($one, $two);
  $ttp[0] = $one;
  is_deeply (menu_contents(), [$one, $two],
             'store 0 unchanged');

  set_menu ($one, $two);
  $ttp[1] = $two;
  is_deeply (menu_contents(), [$one, $two],
             'store 1 unchanged');
}

#------------------------------------------------------------------------------
# fetchsize

{
  set_menu ();
  is ($#ttp, -1);
  is (scalar(@ttp), 0);

  set_menu ($one);
  is ($#ttp, 0);
  is (scalar(@ttp), 1);

  set_menu ($one,$two);
  is ($#ttp, 1);
  is (scalar(@ttp), 2);

  set_menu ($one,$two,$three);
  is ($#ttp, 2);
  is (scalar(@ttp), 3);
}

#------------------------------------------------------------------------------
# storesize

{
  set_menu ();
  $#ttp = -1;
  is_deeply (menu_contents(), [], 'storesize empty to size -1');

  set_menu ();
  $#ttp = -2;
  is_deeply (menu_contents(), [], 'storesize empty to size -2');

  set_menu ();
  $#ttp = -999;
  is_deeply (menu_contents(), [], 'storesize empty to size -999');

  set_menu ($one);
  $#ttp = -1;
  is_deeply (menu_contents(), [],
             'storesize truncate from 1 to size -1');

  set_menu ($one);
  $#ttp = -999;
  is_deeply (menu_contents(), [],
             'storesize truncate from 1 to size -999');

  set_menu ($one);
  $#ttp = 0;
  is_deeply (menu_contents(), [$one],
             'storesize unchanged 1');

  set_menu ($one,$two,$three,$four);
  $#ttp = 1;
  is_deeply (menu_contents(), [$one,$two],
             'storesize truncate from 4 to 2');

  set_menu ();
  $#ttp = 2;
  is_deeply (menu_contents(), [],
             'extend 0 to 3, no effect');

  set_menu ($one);
  $#ttp = 1;
  is_deeply (menu_contents(), [$one],
             'extend 1 to 2, no effect');

  set_menu ($one,$two);
  $#ttp = 3;
  is_deeply (menu_contents(), [$one,$two],
             'extend 2 to 4, no effect');
}


#------------------------------------------------------------------------------
# exists

{
  set_menu ();
  ok (! exists($ttp[0]));
  ok (! exists($ttp[1]));
  ok (! exists($ttp[-1]));

  set_menu ($one);
  ok (  exists($ttp[0]));
  ok (! exists($ttp[1]));
  ok (! exists($ttp[2]));
  ok (  exists($ttp[-1]));
  ok (! exists($ttp[-2]));
  ok (! exists($ttp[-99]));

  my @plain = ($one,$two);
  set_menu ($one,$two);
  foreach my $i (-3 .. 3) {
    is (exists($ttp[$i]), exists($plain[$i]), "exists $i");
  }
}

#------------------------------------------------------------------------------
# delete

{
  set_menu ();
  is_deeply ([delete $ttp[0]], [undef],
             'delete non-existent - return');
  is_deeply (menu_contents(), [],
             'delete non-existent - contents');

  set_menu ($one);
  is_deeply ([delete $ttp[0]], [$one],
             'delete sole element - return');
  is_deeply (menu_contents(), [],
             'delete sole element - contents');

  set_menu ($two);
  is_deeply ([delete $ttp[99]], [undef],
             'delete big non-existent - return');
  is_deeply (menu_contents(), [$two],
             'delete big non-existent - contents');

  set_menu ($one,$two);
  is_deeply ([delete $ttp[0]], [$one]);
  is_deeply (menu_contents(), [$two]);

  set_menu ($one,$two);
  is_deeply ([delete $ttp[1]], [$two]);
  is_deeply (menu_contents(), [$one],
             'delete last of 2');

  set_menu ($one,$two,$three,$four,$five);
  is_deeply ([delete $ttp[-2]], [$four],
             'delete -2 of 5 - return');
  is_deeply (menu_contents(), [$one,$two,$three,$five],
             'delete -2 of 5 - contents');

  set_menu ();
  is_deeply ([delete $ttp[-1]], [undef],
             'delete -1 of 0 - return');
  is_deeply (menu_contents(), [],
             'delete -1 of 0 - contents');

  set_menu ($one,$two);
  is_deeply ([delete $ttp[-100]], [undef],
             'delete -100 of 2 - return');
  is_deeply (menu_contents(), [$one,$two],
             'delete -100 of 2 - contents');

}

#------------------------------------------------------------------------------
# clear

{
  set_menu ();
  @ttp = ();
  is_deeply (menu_contents(), [],
             'clear empty');

  set_menu ($nine);
  @ttp = ();
  is_deeply (menu_contents(), [],
             'clear 1');

  set_menu ($one,$two,$three);
  @ttp = ();
  is_deeply (menu_contents(), [],
             'clear 3');
}


#------------------------------------------------------------------------------
# push

{
  set_menu ();
  push @ttp, $one;
  is_deeply (menu_contents(), [$one]);

  push @ttp, $two,$three;
  is_deeply (menu_contents(), [$one,$two,$three]);
}

#------------------------------------------------------------------------------
# pop

{
  set_menu ();
  is (pop @ttp, undef,
             'pop empty - scalar context');
  is_deeply ([pop @ttp], [pop @{[]}],
             'pop empty - array context');
  is_deeply (menu_contents(), [],
             'pop empty - contents');

  set_menu ($one);
  is (pop @ttp, $one);
  is_deeply (menu_contents(), []);

  set_menu ($one,$two);
  is (pop @ttp, $two);
  is_deeply (menu_contents(), [$one]);
}

#------------------------------------------------------------------------------
# shift

{
  set_menu ();
  my @plain;
  is_deeply ([shift @ttp], [shift @plain]);
  is_deeply (menu_contents(), [],
             'shift empty');

  set_menu ($one);
  is_deeply ([shift @ttp], [$one]);
  is_deeply (menu_contents(), []);

  set_menu ($one,$two);
  is_deeply ([shift @ttp], [$one]);
  is_deeply (menu_contents(), [$two]);

  set_menu ($one,$two,$three,$four);
  is_deeply ([shift @ttp], [$one]);
  is_deeply (menu_contents(), [$two,$three,$four]);
}

#------------------------------------------------------------------------------
# unshift

{
  set_menu ();
  my @plain;
  is (unshift(@ttp,$one), unshift(@plain,$one));
  is_deeply (menu_contents(), [$one]);

  set_menu ();
  @plain = ();
  is (unshift(@ttp,$one,$two,$three), unshift(@plain,$one,$two,$three));
  is_deeply (menu_contents(), [$one,$two,$three]);

  is (unshift(@ttp,$four,$five), unshift(@plain,$four,$five));
  is_deeply (menu_contents(), [$four,$five,$one,$two,$three]);
}


#------------------------------------------------------------------------------
# splice

{
  set_menu ($one);
  my $got = splice @ttp, 0,1;
  is ($got, $one, 'splice 0,1 to empty, scalar return');
}
{
  set_menu ($one,$two);
  my $got = splice @ttp, -2,2;
  is ($got, $two, 'splice -2,2 to empty, scalar return');

  my @plain = ($one,$two);
  $got = splice @plain, -2,2;
  is ($got, $two, 'splice -2,2 to empty on plain, scalar return');
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
    if ($msg =~ /^TiedChildren:/) {
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
  foreach my $old_content ([], [$one], [$one,$two],
                           [$one,$two,$three], [$one,$two,$three,$four]) {
    foreach my $new_content ([], [$nine], [$five,$six,$seven]) {
      foreach my $offset (-3 .. 3) {
        if ($offset < - @$old_content) { next; }

        foreach my $length (-3 .. 3) {
          set_menu (@$old_content);
          @plain = @$old_content;

          my $ttp_scalar;
          { local $SIG{__WARN__} = $ttp_warn_handler;
            $ttp_scalar = scalar (splice @ttp, $offset, $length, @$new_content);
          }
          my $plain_scalar;
          { local $SIG{__WARN__} = $plain_warn_handler;
            $plain_scalar = scalar (splice @plain, $offset, $length, @$new_content);
          }
          @plain = map {defined $_ ? ($_) : ()} @plain;

          my $name =
            "old=" . join(',',map{$_->get_name}@$old_content)
              . ", splice "
                . " " . (defined $offset ? $offset : 'undef')
                  . "," . (defined $length ? $length : 'undef')
                    . "  " . join(',',map{$_->get_name}@$new_content)
                      . " want=" . join(',',map{$_->get_name}@plain)
                      . " got=" . join(',',map{$_->get_name}@{menu_contents()});

          # diag $ttp_scalar && $ttp_scalar->get_name;
          # diag $plain_scalar && $plain_scalar->get_name;
          is        ($ttp_scalar, $plain_scalar,
                     "scalar context return: " . $name);
          is_deeply (menu_contents(), \@plain,
                     "scalar context leaves: " . $name);

          set_menu (@$old_content);
          @plain = @$old_content;
          my $ttp_aret;
          { local $SIG{__WARN__} = $ttp_warn_handler;
            $ttp_aret = [splice @ttp, $offset, $length, @$new_content];
          }
          my $plain_aret;
          { local $SIG{__WARN__} = $plain_warn_handler;
            $plain_aret = [splice @plain, $offset, $length, @$new_content];
          }
          @plain = map {defined $_ ? ($_) : ()} @plain;

          is_deeply ($ttp_aret, $plain_aret,
                     "array context return: " . $name);
          is_deeply (menu_contents(), \@plain,
                     "array context leaves: " . $name);
        }
      }
    }
  }
  is ($ttp_warn, $plain_warn, 'warnings count');
}

exit 0;
