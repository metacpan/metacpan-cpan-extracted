#!/usr/bin/perl -w

# Copyright 2017, 2018 Kevin Ryde
#
# This file is part of Graph-Graph6.
#
# Graph-Graph6 is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Graph6 is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Graph6.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl hog-fetch.pl NUM NUM ...
#
# Download graph6 format files of the given House of Graphs graph numbers.
# For example number 74 at https://hog.grinvin.org/ViewGraphInfo.action?id=74
# which is the complete-4.
#
# Output is to file ~/HOG/graph_NUM.g6 for each NUM number.  If that file
# exists already then it's not re-downloaded or overwritten.  Delete a file
# if for some reason you want to re-download.
#
# Filenames of this form are hinted in the HOG server reply, so would match
# a browser download.  But the server filename is ignored and the name here
# is fixed.
#
# Note that not all numbers are graphs, so don't blindly download ranges.
#
# The graph download is a HTTP POST.  You can get much the same effect from
# the command line by say
#
#     id=74
#     wget -O $HOME/HOG/graph_$id.g6 \
#          --post-data "graphFormatName=Graph6&id=$id" \
#          https://hog.grinvin.org/DownloadGraphs.action
#
#     curl --compressed -o $HOME/HOG/graph_$id.g6 \
#          --data "graphFormatName=Graph6&id=$id" \
#          https://hog.grinvin.org/DownloadGraphs.action
#
# As of Feb 2017 the server doesn't compress graph downloads, but 255
# vertices of graph6 is only 5kbytes anyway.

use 5.006;
use strict;
use warnings;
use FindBin;
use File::Slurp;
use HTTP::Message;
use LWP::UserAgent;

our $VERSION = 8;
my $option_verbose = 0;

if (@ARGV && $ARGV[0] eq '-v') { shift @ARGV; $option_verbose = 1; }

my $ua = LWP::UserAgent->new (keep_alive => 1);
$ua->agent("$FindBin::Script/$VERSION ".$ua->agent);

# ask for everything decoded_content() accepts
$ua->default_header('Accept-Encoding' => scalar HTTP::Message::decodable());
$ua->add_handler (request_send => sub {
                    my ($req, $ua, $headers) = @_;
                    if ($option_verbose) {
                      $|=1;
                      print "request:\n";
                      print $req->method," ",$req->uri,"\n";
                      print $req->headers->as_string,"\n";
                      print $req->decoded_content(raise_error=>0),"\n";
                      print "\n";
                    }
                    return;
                  });
$ua->add_handler (response_header => sub {
                    my ($resp, $ua, $headers) = @_;
                    if ($option_verbose) {
                      print "response: ",length($resp->as_string)," bytes\n";
                      print $resp->status_line,"\n";
                      print $resp->headers->as_string;
                      print "\n";
                    }
                  });

foreach my $id (@ARGV) {
  if ($id eq '-v' || $id eq '--verbose') {
    $option_verbose = 1;
    next;
  }

  unless ($id =~ /^\d+$/) {
    die "Unrecognised option: $id";
  }

  my $filename = "$ENV{HOME}/HOG/graph_$id.g6";
  if (-e $filename) {
    print "$filename exists already, skip\n";
    next;
  }

  my $url = 'https://hog.grinvin.org/DownloadGraphs.action';
  my $resp = $ua->post($url, { graphFormatName => 'Graph6', id => $id});
  unless ($resp->is_success) {
    die $resp->status_line;
  }

  my $content = $resp->decoded_content (raise_error=>1);
  print $content;
  File::Slurp::write_file($filename, $content);
}

exit 0;
