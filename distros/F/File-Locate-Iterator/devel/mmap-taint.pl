#!/usr/bin/perl -w

# Copyright 2011, 2014 Kevin Ryde.
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

use 5.005;
use strict;
use FindBin;
use Devel::Peek;
# use File::Map;

# uncomment this to run the ### lines
use Smart::Comments;

{
  # :mmap
  my $filename = '/etc/motd.tail';
  $filename = File::Spec->catfile ($FindBin::Bin, 'samp.locatedb');
  open my $fh, '<:mmap', $filename;
  exit 0;
}

{
  require File::Map;
  require Taint::Util;
  my $str;
  Taint::Util::taint($str);
  my $filename = '/etc/motd.tail';
  File::Map::map_file ($str, $filename);
  { my $t = Taint::Util::tainted($str);
    ### $t
  }
  Taint::Util::taint($str);
  { my $t = Taint::Util::tainted($str);
    ### $t
  }
  Dump($str);
  exit 0;
}

{
  # my $t;
  # my $x;
  #
  my $str = '';
  open my $fh, '<', \$str or die;
  my $x = <$fh>;
  ### $x
  my @stat = stat($fh);
  ### @stat

  exit 0;
}

{
  require IPC::SysV;
  my $shmid = shmget (IPC::SysV::IPC_PRIVATE(),
                      5000,
                      IPC::SysV::IPC_CREAT() | 0666); # world read/write
  ### $shmid

  {
    my $buff;
    shmread ($shmid, $buff, 0, 10) || die "$!";
    ### $buff
    require Taint::Util;
    my $t = Taint::Util::tainted($buff);
    ### $t
  }

  {
    my $addr = IPC::SysV::shmat ($shmid, undef, 0);
    ### $addr
    my $buff;
    require Taint::Util;
    my $t = Taint::Util::tainted($buff);
    ### $t
    IPC::SysV::memread($addr, $buff, 0, 10) || die $!;
    ### $buff
    require Taint::Util;
     $t = Taint::Util::tainted($buff);
    ### $t
  }
  exit 0;
}

{
  open my $fh, '<', '/etc/motd' or die;
  my $x;
  read $fh,$x,0;

  require Taint::Util;
  my $t = Taint::Util::tainted($x);
  ### $t
  exit 0;
}
# 
# 
# system ("echo $x");
# 
# $t = Taint::Util::tainted($x);
# ### $t
# 
# # Dump($x);
# # Taint::Util::taint($x);
# Dump($x);
# 
# Dump($x);
# 
# # Dump($str);
# exit 0;
