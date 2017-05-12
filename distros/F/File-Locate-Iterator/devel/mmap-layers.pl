#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde.
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
use Devel::Peek;
use FindBin;

use File::Map ();

{
  my $str = "hello\n";
  open my $fh, '<&=-1' or die "$!";
  { local $,=' '; print "layers:",PerlIO::get_layers($fh),"\n"; }
  print "File::Map handle $fh\n";
  my $map;
  File::Map::map_handle ($map, $fh);
  print "  length ",length($map),"\n";
  exit 0;
}

{
  my $str = "hello\n";
  open my $fh, '<', \$str or die;
  { local $,=' '; print "layers:",PerlIO::get_layers($fh),"\n"; }
  print "File::Map handle $fh\n";
  my $map;
  File::Map::map_handle ($map, $fh);
  print "  length ",length($map),"\n";
  print $map;
  exit 0;
}

{
#my $filename = '/tmp/x';
my $filename = 't/samp.locatedb';

  open my $fh, '< :crlf', $filename or die;
  print "File::Map handle $fh\n";
  my $str;
  File::Map::map_handle ($str, $fh);
  print "  length ",length($str),"\n";
}
