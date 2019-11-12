#!/usr/bin/perl -w

# Copyright 2010, 2019 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Filter-gunzip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use FindBin;
use File::Slurp;
BEGIN {$|=1}

{
  # .pl.gz files containing CRLF bytes in the gz
  require File::Locate::Iterator;
  my $it = File::Locate::Iterator->new (glob => '*.pl.gz');
  my $count = 0;
  while (defined (my $filename = $it->next)) {
    print $filename,"\r";
    my $gz = File::Slurp::read_file($filename, {err_mode=>'quiet'}) // next;
    if ($gz =~ /\r\n/g) {
      my $pos = pos($gz);
      printf "found $filename  byte position 0x%X\n", $pos;
      exit if $count++>20;
    }
  }
}

my $data_pl = File::Slurp::read_file($FindBin::Bin . '/data.pl');
foreach my $try (1 .. 1000) {
  print "$try\r";
  foreach my $level (1 .. 9) {
    foreach my $len (100 .. 200) {
      my $str = $data_pl;
      foreach (1 .. $len) {
        $str .= "\r\n" . chr(30 + int(rand(10)));
      }
    }
    File::Slurp::write_file('/tmp/make.pl');
    unlink '/tmp/make.pl.gz';
    system("gzip -$level /tmp/make.pl");
    my $gz = File::Slurp::read_file('/tmp/make.pl.gz');
    if ($gz =~ /\r\n/) {
      print "found\n";
      exit;
    }
  }
}
exit 0;
