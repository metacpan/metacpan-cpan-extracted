#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde

# This file is part of Math-OEIS.
#
# Math-OEIS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-OEIS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-OEIS.  If not, see <http://www.gnu.org/licenses/>.


# Report possible cleanups stuff in ~/OEIS.
# Used to keep symlinks to relevant directories, but no more.
# Prefer A123456.internal.txt over A123456.internal.html.

use 5.004;
use strict;
use Math::OEIS;

# uncomment this to run the ### lines
use Smart::Comments;

foreach my $dir (Math::OEIS->local_directories()) {
  print "dir $dir\n";

  opendir my $dh, $dir or die;
  my @filenames = sort readdir $dh;
  closedir $dh;
  print "  ",scalar(@filenames)," files\n";

  my %filenames;
  @filenames{@filenames} = (); # hash slice

  foreach my $filename (@filenames) {
    my $target = readlink $filename // next;
    print "  symlink $filename -> $target\n";
  }
  foreach my $filename (@filenames) {
    next unless $filename =~ /\.internal\.html$/;
    my $txt_filename = $filename;
    $txt_filename =~ s/\.html/.txt/;
    if (-e $txt_filename) {
      print "  $filename and also $txt_filename\n";
    }

    my $html_filename = $filename;
    $html_filename =~ s/\.internal\.html$/.html/;
    if (! -e $html_filename) {
      print "  $filename without $html_filename\n";
    }
  }
}
exit 0;
