#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2013, 2014, 2015, 2019 Kevin Ryde

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
$|=1;

use Finance::Quote::MGEX;
print "Finance::Quote::MGEX version ",Finance::Quote::MGEX->VERSION,"\n";

# uncomment this to run the ### lines
use Smart::Comments;

{
  require HTTP::Response;
  my $resp = HTTP::Response->new(200, 'OK');
  my $content;
  # my $content = slurp('samples/mgex/intraday-no.html');
  $content = slurp('samples/mgex/wquotes_js.js.6');
  $content = slurp('samples/mgex/aquotes.htx.9');
  $resp->content($content);
  $resp->content_type('application/x-javascript');

  #  print $content;
  # print Finance::Quote::MGEX::_javascript_document_write($content);
  my $html = Finance::Quote::MGEX::_javascript_document_write($content);
  require HTML::FormatText::W3m;
  print HTML::FormatText::W3m->format_string ($html);

  my $fq = Finance::Quote->new ('MGEX');
  my %quotes;
  Finance::Quote::MGEX::resp_to_quotes ($fq, $resp, \%quotes,
                                        ['ISH19','MWZ0','MWZ19']);
  ### %quotes

  exit 0;
}

{
  # my $fq = Finance::Quote->new ('-defaults', 'MGEX');
  my $fq = Finance::Quote->new ('MGEX');
  my %quotes = $fq->fetch ('mgex', 'AJK15');
  ### %quotes
  exit 0;
}







  # my $url = Finance::Quote::MGEX::barchart_customer_resp_to_url ($resp, 'XYZ');
  # say $url;
