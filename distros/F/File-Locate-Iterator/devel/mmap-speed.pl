#!/usr/bin/perl -w

# Copyright 2009, 2010, 2014 Kevin Ryde.
#
# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator; see the file COPYING.  Failing that, go to
# <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Devel::TimeThis;
use Devel::Peek;

use Sys::Mmap ();
use File::Map ();

use constant ITERATIONS => 1000000;

sub sys_mmap {
  my $str;
  new Sys::Mmap $str, 64, '/tmp/mmap.pl.tmp'
    or die "Cannot Sys::Mmap->new: $!";
  # print Dump($str);
  my $x;
  {
    my $t = Devel::TimeThis->new ('Sys::Mmap tied');
    foreach (1 .. ITERATIONS) {
      # print $str;
      $x = $str . 'x';
    }
    # print "after loop\n";
  }
}

sub sys_mmap_raw {
  my $str;
  open my $fh, '<', '/tmp/mmap.pl.tmp' or die;
  Sys::Mmap::mmap ($str, 64,
                   Sys::Mmap::PROT_READ(), Sys::Mmap::MAP_SHARED(),
                   $fh, 0)
      or die "Cannot Sys::Mmap::mmap(): $!";
  # print Dump($str);
  my $x;
  {
    my $t = Devel::TimeThis->new ('Sys::Mmap mmap');
    foreach (1 .. ITERATIONS) {
      # print $str;
      $x = $str . 'x';
    }
  }
}

sub file_map {
  my $str;
  File::Map::map_file $str, '/tmp/mmap.pl.tmp';
  # print Dump($str);
  my $x;
  {
    my $t = Devel::TimeThis->new ('File::Map');
    foreach (1 .. ITERATIONS) {
      # print $str;
      $x = $str . 'x';
    }
  }
}

file_map();
sys_mmap();
#sys_mmap_raw();
