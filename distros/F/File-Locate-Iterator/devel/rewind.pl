#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Socket;

{
  open my $fh, '<:gzip', '/usr/share/doc/gzip/README.gz'
    or die "cannot open: $!";
  # print <$fh>;
  seek ($fh, 0, 0)
    or die "cannot seek: $!";
  exit 0;
}
# {
#   my ($rh, $wh);
#   socket ($rh, $wh) or die;
#   seek $rh, 0, 0 or die $!;
#   exit 0;
# }
{
  my ($rh, $wh);
  pipe ($rh, $wh) or die;
  seek $rh, 0, 0 or die $!;
  exit 0;
}
{
  open my $fh, '</dev/tty5' or die;
  seek $fh, 0, 0 or die $!;
  exit 0;
}
