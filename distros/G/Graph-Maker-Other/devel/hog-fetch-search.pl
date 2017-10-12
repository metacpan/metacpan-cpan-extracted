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


# Scripted download from House of Graphs of the graphs matching some search
# criteria.  Bit rough, but works.
#
# invariantId, operatorType and invariantValue in the query code below are
# the search.  The download is then Graph6 format and saved to a file
# hog-fetch-search-output.g6.
#
# One use is to download g6 of all graphs in HOG by asking for number of
# vertices GE 0.  As of Oct 2017 that's about 1mbyte.  (Less if confined to
# connected graphs, but no scripted condition for that here.)
#


use 5.006;
use strict;
use WWW::Mechanize;
use File::Slurp;

# uncomment this to run the ### lines
# use Smart::Comments;


my $mech = WWW::Mechanize->new (keep_alive => 1);
# ask for everything decoded_content() accepts
$mech->default_header ('Accept-Encoding' => HTTP::Message::decodable());
$mech->add_handler (request_send => sub {
                      my ($req, $mech, $headers) = @_;
                      print "request:\n";
                      print $req->method," ",$req->uri,"\n";
                      print $req->headers->as_string,"\n";
                      print $req->decoded_content(raise_error=>0),"\n";
                      print "\n";
                      return;
                    });
$mech->add_handler (response_header => sub {
                      my ($resp, $mech, $headers) = @_;
                      print "response: ",length($resp->as_string)," bytes\n";
                      print $resp->status_line,"\n";
                      print $resp->headers->as_string;
                      print "\n";
                    });

my $search_url = 'https://hog.grinvin.org/DoSearchGraphsInvariantValue.action';
my $resp = $mech->post
  ($search_url,
   { invariantId    => 15,  # number of vertices
     operatorType   => 'LE',
     invariantValue => 2,
     historyIndex   => 1,
     pageName       => 'start-new-search',
   });
if (! $mech->success) {
  print "oops\n";
  print $resp->status_line,"\n";
  exit 1;
}

my $content = $resp->decoded_content (raise_error=>1);
# File::Slurp::write_file('/tmp/all.html', $content);

# form has a historyIndex which identifies the search within a session
$resp = $mech->submit_form(form_name => 'DownloadGraphs',
                           fields    => { graphFormatName => 'Graph6' },
                          );

$content = $resp->decoded_content (raise_error=>1, charset=>'none');
# print $content;
File::Slurp::write_file('hog-fetch-search-output.g6',
                        {binmode => ':raw'},  # newlines, not CRLF on DOS
                        $content);

exit 0;






# $resp = $mech->post
#   ('https://hog.grinvin.org/DownloadGraphs.action',
#    { graphFormatName => 'Graph6',
#      historyIndex    => 1,
#    });
# print $resp->status_line,"\n";
# print $resp->headers->as_string;
# print "\n";










# print $resp->status_line,"\n";
# print $resp->headers->as_string;
# print "\n";

# my $content = $resp->decoded_content (raise_error=>1);
# print $content;
# File::Slurp::write_file('/tmp/all-search.html', $content);

# if ($resp->code != 302) {
#   print "oops, expected 302 redirect from search\n";
#   exit 1;
# }
#
# print "\n";
#
# my $url = $resp->header('Location');
# $url = URI->new_abs($url,$search_url);
# print $url;
# $resp = $mech->get($url);
# print $resp->status_line,"\n";
# print $resp->headers->as_string;
# print "\n";
