#!/usr/bin/perl -w

# Copyright 2015, 2016 Kevin Ryde
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

use strict;
use 5.010;

{
  # hog LWP post

  require HTTP::Request::Common;
  my $hog_url = 'http://hog.grinvin.org';
  my $graph6_str = 'Bw'; # complete 3

  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new (ssl_opts => { verify_hostname => 0 });
  $ua->ssl_opts(verify_hostname => 0);

  # must have file=something and Content-Type or else error
  # upload => $graph6_str,
  my $req = HTTP::Request::Common::POST
    ("$hog_url/DoSearchGraphFromFile.action",
     Content_Type => 'form-data',
     Content => [graphFormatName => "Graph6",
                 upload => [undef, "foo.g6",
                            Content_Type => 'text/plain',
                            Content => $graph6_str ],
                ]);
  $ua->prepare_request ($req);
  print $req->as_string;

  my $resp = $ua->request($req);
  print $resp->as_string;

  exit 0;
}
