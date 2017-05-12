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

# Iterator::Simple 0.05 does an import of UNIVERSAL.pm 'isa', which perl
# 5.12.0 spams about to warn(), so this check before nowarnings()
BEGIN {
  eval { require Iterator::Simple }
    or plan skip_all => "Iterator::Simple not available -- $@";
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 19;
require Iterator::Simple::Locate;

my $want_version = 23;
is ($Iterator::Simple::Locate::VERSION, $want_version, 'VERSION variable');
is (Iterator::Simple::Locate->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Iterator::Simple::Locate->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Iterator::Simple::Locate->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}
# Iterator::Simple::Locate->new object isn't an actual subclass, just a
# flavour of Iterator::Simple, so no object version number test


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
  my $it = Iterator::Simple::Locate->new (database_file => $samp_locatedb);
  my @want = slurp_zeros ($samp_zeros);
  my @got;
  while (defined (my $filename = $it->())) {
    push @got, $filename;
  }
  is_deeply (\@got, \@want, 'samp.locatedb');
}

#------------------------------------------------------------------------------
# suffix

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Simple::Locate->new (database_str => $str,
                                          suffix => '.pl');
  is ($it->(), '/hello/world.pl');
  is ($it->(), undef);
  is ($it->(), undef);
}

#------------------------------------------------------------------------------
# suffixes

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Simple::Locate->new (database_str => $str,
                                          suffixes => ['.pm','.pl']);
  is ($it->(), '/hello/world.pl');
  is ($it->(), undef);
  is ($it->(), undef);
}

#------------------------------------------------------------------------------
# glob

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Simple::Locate->new (database_str => $str,
                                          glob => '*.pl');
  is ($it->(), '/hello/world.pl');
  is ($it->(), undef);
}

#------------------------------------------------------------------------------
# globs

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Simple::Locate->new (database_str => $str,
                                          globs => ['*.pm','*.pl']);
  is ($it->(), '/hello/world.pl');
  is ($it->(), undef);
}

#------------------------------------------------------------------------------
# regexp

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Simple::Locate->new (database_str => $str,
                                          regexp => qr/\.pl/);
  is ($it->(), '/hello/world.pl');
  is ($it->(), undef);
}

#------------------------------------------------------------------------------
# regexps

{
  my $str = "\0LOCATE02\0\0/hello.c\0\006/world.pl\0";
  my $it = Iterator::Simple::Locate->new (database_str => $str,
                                          regexps => [ qr/\.pm/, qr/\.pl/ ]);
  is ($it->(), '/hello/world.pl');
  is ($it->(), undef);
}

exit 0;
