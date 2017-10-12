#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl hog-fetch.pl NUM NUM ...
#
# Download graph6 format files of the given House of Graphs graph numbers.
# For example number 74 at https://hog.grinvin.org/ViewGraphInfo.action?id=74
# is the complete-4.
#
# Note that not all id numbers are graphs, so don't try to download
# successive numbers.
#
# Output is to file ~/HOG/NUM.g6 for each NUM number.  If that file exists
# already then it's not re-downloaded or overwritten.  (Delete a file if for
# some reason want to re-download.)
#

use 5.006;
use strict;
use LWP::UserAgent;
use File::Slurp;

# uncomment this to run the ### lines
# use Smart::Comments;


foreach my $id (@ARGV) {
  # my $id = 19655;

  my $ua = LWP::UserAgent->new (keep_alive => 1);
  # ask for everything decoded_content() accepts
  $ua->default_header ('Accept-Encoding' => HTTP::Message::decodable());

  my $filename = "$ENV{HOME}/HOG/$id.g6";
  if (-e $filename) {
    print "$filename exists already\n";
    next;
  }
  my $url = 'https://hog.grinvin.org/DownloadGraphs.action';
  my $resp = $ua->post($url, { graphFormatName => 'Graph6', id => $id});
  my $content = $resp->decoded_content (raise_error=>1);
  print $content;
  File::Slurp::write_file($filename, $content);
}

exit 0;
