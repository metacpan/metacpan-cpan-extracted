#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde.
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
use File::Spec;
use FindBin;
# use lib::abs $FindBin::Bin;

use Sys::Mmap ();
use File::Map ();

#my $filename = File::Spec->devnull;
#my $filename = '/tmp/x';
my $filename = 't/samp.locatedb';

sub sys_mmap {
  my $str;
  new Sys::Mmap $str, 64, $filename
    or die "Cannot Sys::Mmap->new: $!";
}

sub sys_mmap_raw {
  my $str;
  open my $fh, '<', $filename or die;
  Sys::Mmap::mmap ($str, 8,
                   Sys::Mmap::PROT_READ(), Sys::Mmap::MAP_SHARED(),
                   $fh, 0)
      or die "Cannot Sys::Mmap::mmap(): $!";
  print "Sys::Mmap length ",length($str),"\n";
}

sub file_map {
  my $str;
  File::Map::map_file ($str, $filename);
  print "File::Map file length ",length($str),"\n";
}
sub file_map_fh {
  my $str;
  open my $fh, '<', $filename or die;
  print "File::Map handle $fh\n";
  File::Map::map_handle ($str, $fh);
  print "  length ",length($str),"\n";
}

sys_mmap_raw();
file_map();
file_map_fh();
# sys_mmap();
