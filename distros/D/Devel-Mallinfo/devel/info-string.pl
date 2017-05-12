#!/usr/bin/perl -w

# Copyright 2009, 2010, 2014 Kevin Ryde

# This file is part of Devel-Mallinfo.
#
# Devel-Mallinfo is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Devel-Mallinfo is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Devel::Mallinfo;

{
  my $str = Devel::Mallinfo::malloc_info_string(0);
  my $err = "$!";
  print "", (defined $str ? $str : 'undef'),"\n";
  print "errno $err\n";
  exit 0;
}

{
  for (;;) {
    Devel::Mallinfo::malloc_info_string(0);
  }
  exit 0;
}

{
  use BSD::Resource;
  my $limits = get_rlimits();
  print "limits ",join(' ',sort keys %$limits),"\n";

  BSD::Resource::setrlimit (BSD::Resource::RLIMIT_NOFILE(), 0, 0);
  my $str = Devel::Mallinfo::malloc_info_string(0);
  print "", (defined $str ? $str : 'undef'),"\n";
  exit 0;
}



# no good as tmpfile() doesn't respect TMPDIR variable
#
# #---------------------------------------------------------------------------
# # malloc_info() induced failure from disk full
# #
# SKIP: {
#   my $fullfs = '/tmp/fullfs';
#   exists &Devel::Mallinfo::malloc_info
#     or skip 'malloc_info() not available', 1;
#   -d $fullfs
#     or skip '/tmp/fullfs not available', 1;
#
#   local $ENV{'TMPDIR'} = "$fullfs/tmp";
#   my $str = Devel::Mallinfo::malloc_info_string(0);
#   my $err = $!;
# 
#   require POSIX;
#   is ($str, undef,
#       'malloc_info_string() undef on fullfs');
#   is ($err+0, POSIX::EMFILE(),
#       'malloc_info_string() errno ENOSPC on fullfs');
# }

