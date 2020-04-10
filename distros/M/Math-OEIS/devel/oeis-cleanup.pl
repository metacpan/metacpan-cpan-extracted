#!/usr/bin/perl -w

# Copyright 2017, 2019, 2020 Kevin Ryde

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
# Prefer A123456.internal.txt over A123456.internal.html.
#

use 5.004;
use strict;
use Math::OEIS;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;

my $column = 46;  # for Emacs dired

my %anums;
foreach my $dir (Math::OEIS->local_directories()) {
  print "dir $dir\n";

  opendir my $dh, $dir or die;
  my @filenames = sort readdir $dh;
  closedir $dh;
  print "  ",scalar(@filenames)," files\n";

  foreach my $filename (@filenames) {
    if ($filename =~ /[Ab](\d{6,7})\..*(txt|htm).*/i) {
      $anums{"A$1"} = $filename;
    }
  }

  my %filenames;
  @filenames{@filenames} = (); # hash slice

  # (I used to keep files in directories of related sequences, with symlinks
  # to them, but no longer.)
  foreach my $i (0 .. $#filenames) {
    my $filename = $filenames[$i];
    my $target = readlink $filename // next;
    print "$dir:",$i+3,":$column: symlink $filename -> $target\n";
  }

  foreach my $i (0 .. $#filenames) {
    my $filename = $filenames[$i];
    if ($filename =~ /b(\d+)\.txt$/) {
      my $html_filename = "$dir/A$1.html";
      unless (-e $html_filename) {
        print "$dir:",$i+3,":$column: $filename without $html_filename\n";
      }
    }

    if ($filename =~ /\.internal\.html$/) {
      my $txt_filename = $filename;
      $txt_filename =~ s/\.html/.txt/;
      if (-e "$dir/$txt_filename") {
        print "$dir:",$i+3,":$column: $filename and also $txt_filename\n";
      }

      my $html_filename = $filename;
      $html_filename =~ s/\.internal\.html$/.html/;
      unless (-e "$dir/$html_filename") {
        print "$dir:",$i+3,":$column: $filename without $html_filename\n";
      }
    }
  }
}

{
  require Math::NumSeq::OEIS::File;
  my @anums = sort keys %anums;
  foreach my $anum (@anums) {
    my $want_i_start;
    unless (eval { $want_i_start = Math::NumSeq::OEIS::File->new
                     (anum => $anum,
                      _dont_use_afile => 1,
                      _dont_use_bfile => 1)
                     ->i_start;
                   1 }) {
      print "$anum from $anums{$anum}\n  $@";
      next;
    }

    # {
    #   my $got_i_start = Math::NumSeq::OEIS::File->new
    #     (anum => $anum,
    #      _dont_use_internal => 0,
    #      _dont_use_afile => 1,
    #      _dont_use_bfile => 1)->i_start;
    #   unless ($want_i_start == $got_i_start) {
    #     print "$anum: HTML and internal different OFFSET $want_i_start vs $got_i_start\n";
    #   }
    # }

    foreach my $prefix ('b','a') {
      if (defined Math::OEIS->local_filename(anum_to_bfile_basename($anum,$prefix))) {
        my $got_i_start = Math::NumSeq::OEIS::File->new
          (anum => $anum,
           _dont_use_internal => 1,
           _dont_use_afile => ($prefix eq 'a' ? 0 : 1),
           _dont_use_bfile => ($prefix eq 'b' ? 0 : 1))
          ->i_start;
        unless ($want_i_start == $got_i_start) {
          print "$anum: internal and $prefix-file different OFFSET $want_i_start vs $got_i_start\n";
        }
      }
    }
  }
}

sub anum_to_bfile_basename {
  my ($anum, $prefix) = @_;
  return (defined $prefix ? $prefix : 'b') . substr($anum,1) . '.txt';
}

exit 0;
