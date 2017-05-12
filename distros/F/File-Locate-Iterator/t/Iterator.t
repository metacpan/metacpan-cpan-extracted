#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2014 Kevin Ryde

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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

eval { require Iterator }
  or plan skip_all => "Iterator.pm not available -- $@";

plan tests => 20;
require Iterator::Locate;

{
  my $want_version = 23;
  is ($Iterator::Locate::VERSION, $want_version, 'VERSION variable');
  is (Iterator::Locate->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Iterator::Locate->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Iterator::Locate->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $empty_locatedb = "\0LOCATE02\0";
  my $it = Iterator::Locate->new (database_str => $empty_locatedb);
  is ($it->VERSION, $want_version, 'VERSION object method');
  ok (eval { $it->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $it->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#-----------------------------------------------------------------------------
# samp.zeros / samp.locatedb

# read $filename and return a list of strings from it
# each strings in $filename is terminated by a NUL \0
# the \0s are not included in the return
sub slurp_zeros {
  my ($filename) = @_;
  open my $fh, '<', $filename or die "Cannot open $filename: $!";
  binmode($fh) or die "Cannot set binary mode";
  local $/ = "\0";
  my @ret = <$fh>;
  close $fh or die "Error reading $filename: $!";
  foreach (@ret) { chomp }
  return @ret;
}

{
  require FindBin;
  require File::Spec;
  my $samp_zeros    = File::Spec->catfile ($FindBin::Bin, 'samp.zeros');
  my $samp_locatedb = File::Spec->catfile ($FindBin::Bin, 'samp.locatedb');
  my $it = Iterator::Locate->new (database_file => $samp_locatedb);
  my @want = slurp_zeros ($samp_zeros);
  my @got;
  until ($it->is_exhausted) {
    push @got, $it->value;
  }
  is_deeply (\@got, \@want, 'samp.locatedb');
}

#------------------------------------------------------------------------------
# suffix

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Locate->new (database_str => $str,
                                  suffix => '.pl');
  is ($it->value, '/hello/world.pl');
  ok ($it->is_exhausted);
}

#------------------------------------------------------------------------------
# suffixes

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Locate->new (database_str => $str,
                                  suffixes => ['.pm','.pl']);
  is ($it->value, '/hello/world.pl');
  ok ($it->is_exhausted);
}

#------------------------------------------------------------------------------
# glob

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Locate->new (database_str => $str,
                                  glob => '*.pl');
  is ($it->value, '/hello/world.pl');
  ok ($it->is_exhausted);
}

#------------------------------------------------------------------------------
# globs

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Locate->new (database_str => $str,
                                  globs => ['*.pm','*.pl']);
  is ($it->value, '/hello/world.pl');
  ok ($it->is_exhausted);
}

#------------------------------------------------------------------------------
# regexp

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Locate->new (database_str => $str,
                                  regexp => qr/\.pl/);
  is ($it->value, '/hello/world.pl');
  ok ($it->is_exhausted);
}

#------------------------------------------------------------------------------
# regexps

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Locate->new (database_str => $str,
                                  regexps => [ qr/\.pm/, qr/\.pl/ ]);
  is ($it->value, '/hello/world.pl');
  ok ($it->is_exhausted);
}

exit 0;
