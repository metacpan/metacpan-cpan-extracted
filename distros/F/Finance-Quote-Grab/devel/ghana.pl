#!/usr/bin/perl -w

# Copyright 2014, 2015 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use File::Slurp 'slurp';
use Finance::Quote;

use lib 'devel/lib';
use Finance::Quote::Ghana;
print "Finance::Quote::Ghana version ",Finance::Quote::Ghana->VERSION,"\n";

# uncomment this to run the ### lines
use Smart::Comments;



{
  require HTTP::Response;
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = slurp('samples/ghana/index1.php?linkid=5&sublinkid=12');
  $resp->content($content);
  $resp->content_type('text/html');

  my $fq = Finance::Quote->new ('Ghana');
  my %quotes;
  Finance::Quote::Ghana::_parse ($fq, $resp, \%quotes,
                                 ['SCB PREF', 'EBG','AADS','GLD']);
  ### %quotes

  exit 0;
}
{
  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new;

  my $data_time = 0;
  $ua->add_handler (response_data => sub {
                      my ($response, $ua, $headers, $data) = @_;
                      my $now = int(time());
                      if ($data_time != $now) {
                        my $len = length($data);
                        print "bytes $len\n";
                        # $data_time = $now;
                      }
                      return 1; # continue being called
                    });


  my $url = Finance::Quote::Ghana::GHANA_MARKET_URL();
  # $url = 'http://user42.tuxfamily.org/finance-quote-grab/index.html';

  require HTTP::Request;
  my $req = HTTP::Request->new ('GET', $url);
  $req->accept_decodable; # using decoded_content() below
  $ua->prepare_request ($req);

  my $user_agent =
    'User-Agent: Mozilla/5.0 '
    . "Finance::Quote::Ghana/$Finance::Quote::Ghana::VERSION "
    . $req->user_agent;
  # $user_agent =~ s/::/-/g;
  $req->user_agent ($user_agent);

  # $req->user_agent ('User-Agent: Mozilla/5.0');

  $req->user_agent ("Finance::Quote::Ghana/$Finance::Quote::Ghana::VERSION");

  print "[Request]\n", $req->as_string, "\n";

  my $resp = $ua->request ($req);
  print "[Response]\n", $resp->headers->as_string, "\n";
  exit 0;
}


{
  my $fq = Finance::Quote->new ('-defaults', 'Ghana');
  my %quotes = $fq->fetch ('ghana', 'CAL');
  ### %quotes
  exit 0;
}
