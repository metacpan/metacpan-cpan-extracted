#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use Carp;
use File::Locate::Iterator;
# use File::Locate::Iterator::PP;
use Scalar::Util 'tainted';
use Taint::Util 'taint';

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $str = "\0LOCATE02\0\0/hello\0\006/world\0";
  taint($str);
  ### str: tainted($str)

  my $line = substr($str,0,1);
  ### line: tainted($line)

  my $it = File::Locate::Iterator->new (database_str => $str);
  my $entry = $it->next;
  ### entry: tainted($entry)
  exit 0;
}

{
  my $filename = File::Locate::Iterator->default_database_file;
  open my $fh, '<', $filename or die;
  my $line;
  read $fh, $line, 1 or die;
  ### line: tainted($line)

  my $it = File::Locate::Iterator->new (database_file => $filename,
                                        use_mmap => 0,
                                       );
  my $entry = $it->next;
  ### entry: tainted($entry)
  exit 0;
}

#   #   use warnings 'layer';
#   #   require File::Map;
#   #   print "File::Map version ", File::Map->VERSION, "\n";
#   #
#   #   my $use_mmap = 'if_possible';
#   #
#   #
#   #   my $mode = '<:encoding(iso-8859-1)';
#   # #   $mode = '<:utf8';
#   # #   $mode = '<:raw';
#   # #   $mode = '<:mmap';
#   #   open my $fh, $mode, $filename
#   #     or die;
#   #
#   #   { local $,=' '; print "layers ", PerlIO::get_layers($fh), "\n"; }
#   #
#   #   ### keys: keys %$it
#   #   print exists $it->{'fm'} ? "using mmap\n" : "using fh\n";
#   #
#   #   exit 0;
#   # }
#   #
#   #
#   # {
#   #   my $it = File::Locate::Iterator->new
#   #   print $it->next,"\n";
#   #   print $it->next,"\n";
# 
#   exit 0;
# }
