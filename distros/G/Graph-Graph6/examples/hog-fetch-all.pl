#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019, 2020, 2021 Kevin Ryde
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


# Usage: perl hog-fetch-all.pl [-v|--verbose]
#
# Download all graphs from House of Graphs as a single big graph6 file.
# This is about 11 megabytes or so as of Feb 2021.  Not sure how efficient
# the server is on large search and downloads.  It's possible the requests
# hit it slightly hard, so don't run this frequently.
#
# Output is to a Graph6 format file hog-fetch-all-output.g6, with graphs in
# no particular order.
#
# This file can be used for offline or mechanical greps of graphs which
# exist at the House of Graphs, or perhaps as input to exercise an algorithm
# on graphs which are interesting enough to be there.


use 5.006;
use strict;
use warnings;
use FindBin;
use File::Slurp;
use HTTP::Message;
use WWW::Mechanize;

our $VERSION = 9;

my $option_verbose = 0;
my $output_filename = 'hog-fetch-all-output.g6';

# Do downloads in chunks of vertices.
#
# Circa Feb 2021, everything is about 11 mbytes which is too much for the
# server to build as one reply.  (It gives out-of-memory error backtrace.)
#
# Graphs go up to 256 vertices.  Put a smaller last value in the chunks if
# you want only up to some smaller size.
#
# The sizes here give roughly equal sized chunks as of Feb 2021.

# There's several graphs of the larger sizes, including a bulge of 303
# graphs of 240 vertices which alone are about 1.4 mbytes.  This leads to
# some close together steps.  See devel/hog-size-distribution.pl for
# generating chunk positions from an existing download.
#
# Entries like 24, 28 means fetch chunk 24..27 inclusive
my @chunks = (0, 31, 74, 120, 144, 160, 170, 182, 192, 194,
              202, 210, 216, 220, 226, 232, 240, 242, 243, 244, 999999);

# # uncomment this to try just small sizes
# @chunks = (0,1,2,3);

# # uncomment this to download every graph size individually (for instance if
# # the above chunking still gives pieces which are too big)
# @chunks = (0 .. 257);


foreach my $arg (@ARGV) {
  if ($arg eq '-v' || $arg eq '--verbose') {
    $option_verbose = 1;
  } else {
    die "Unrecognised option: $arg";
  }
}

# No cookies so get a fresh search each time.
# Or could increment the historyIndex parameter to mean start new search.
# Would that be better, worse, or same?
#
my $mech = WWW::Mechanize->new (keep_alive => 1,
                                cookie_jar => undef);
$mech->agent("$FindBin::Script/$VERSION ".$mech->agent);
# ask for all compressions decoded_content() knows
$mech->add_header('Accept-Encoding' => scalar HTTP::Message::decodable());

# diagnostic output
$mech->add_handler (request_send => sub {
                      my ($req, $mech, $headers) = @_;
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
$mech->add_handler (response_header => sub {
                      my ($resp, $mech, $headers) = @_;
                      if ($option_verbose) {
                        print "response: ",length($resp->as_string)," bytes\n";
                        print $resp->status_line,"\n";
                        print $resp->headers->as_string;
                        print "\n";
                      }
                    });

my $total_size = 0;
my $search_url = 'https://hog.grinvin.org/DoSearchGraphsInvariantRange.action';
foreach my $i (0 .. $#chunks-1) {
  my $from = $chunks[$i];
  my $to   = $chunks[$i+1] - 1;
  if ($option_verbose) {
    print "Fetch $from to $to inclusive\n";
  }

  my $resp = $mech->post
    ($search_url,
     { invariantId        => 15,  # number of vertices
       invariantValueFrom => $from,
       invariantValueTo   => $to,
       historyIndex       => 0,
       pageName           => 'start-new-search',
     });
  if (! $mech->success) {
    print "Oops start search $from..$to failed:\n";
    print $resp->status_line,"\n";
    exit 1;
  }

  my $content = $resp->decoded_content (raise_error=>1);
  # File::Slurp::write_file('/tmp/all.html', $content);

  # form has a historyIndex which identifies the search within a session
  $resp = $mech->submit_form(form_name => 'DownloadGraphs',
                             fields    => { graphFormatName => 'Graph6' },
                            );
  if (! $mech->success) {
    print "Oops, download of $from..$to search failed:\n";
    print $resp->status_line,"\n";
    print $resp->decoded_content,"\n";
    exit 1;
  }

  $content = $resp->decoded_content (raise_error=>1, charset=>'none');
  $total_size += length($content);

  if ($option_verbose) {
    print "Write $output_filename chunk ",length($content)," bytes\n";
  }
  File::Slurp::write_file($output_filename,
                          {append => ($i==0 ? 0 : 1),
                           binmode => ':raw', # newlines, not CRLF on DOS
                          },
                          $content);
}

print "total size $total_size\n";
exit 0;
