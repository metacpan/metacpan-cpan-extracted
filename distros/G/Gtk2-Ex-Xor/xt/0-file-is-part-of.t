#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# 0-file-is-part-of.t is shared by several distributions.
#
# 0-file-is-part-of.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-file-is-part-of.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
use strict;
use ExtUtils::Manifest;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $verbose = 1;

sub makefile_distname {
  my $filename = "Makefile";
  my $ret;
  open FH, "< $filename" or die "Cannot open $filename: $!";
  while (defined (my $line = <FH>)) {
    if ($line =~ /^DISTNAME\s*=\s*([^#]*)/) {
      $ret = $1;
      $ret =~ s/\s+$//;
      last;
    }
  }
  close FH or die "Error closing $filename: $!";
  return $ret;
}

sub check_file_is_part_of {
  my ($filename, $distname) = @_;

  my $good = 1;
  open FH, "< $filename" or die "Cannot open $filename: $!";
  while (defined (my $line = <FH>)) {
    $line =~ /[T]his file is part of/i or next;
    unless ($line =~ /[T]his file is part of \Q$distname/i) {
      diag "$filename: $line";
      $good = 0;
    }
  }
  close FH or die "Error closing $filename: $!";
  return $good;
}

my $manifest = ExtUtils::Manifest::maniread();
my @filenames = keys %$manifest;
plan tests => scalar(@filenames);

my $distname = makefile_distname();
if ($verbose) {
  diag "DISTNAME $distname";
}
if (! defined $distname) {
  die "Oops, DISTNAME not found in Makefile";
}

foreach my $filename (@filenames) {
  ok (check_file_is_part_of($filename,$distname),
      "$filename");
}

exit 0;
