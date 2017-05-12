#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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
use Perl6::Slurp ('slurp');
use Finance::Quote;

use lib 'devel/lib';

use Finance::Quote::ATHEX;
print "Finance::Quote::ATHEX version ",Finance::Quote::ATHEX->VERSION,"\n";

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $symbol = 'HTO';
  require HTTP::Response;
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = Perl6::Slurp::slurp('samples/athex/pr_Snapshot.asp?Cid=278');
  $resp->content($content);
  $resp->content_type('text/html');

  my $fq = Finance::Quote->new;
  my %quotes;
  Finance::Quote::ATHEX::stockinfo_to_quotes ($fq, $resp, \%quotes, $symbol);
  ### %quotes

  exit 0;
}
{
  my $symbol = 'HTO';
  require HTTP::Response;
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = Perl6::Slurp::slurp(</tmp/Share_SearchResults.asp.html>);
  $resp->content($content);
  $resp->content_type('text/html');

  my $fq = Finance::Quote->new;
  my %quotes;
  my $cid = Finance::Quote::ATHEX::_search_resp_to_cid ($resp, \%quotes, $symbol);
  ### $cid
  ### %quotes

  exit 0;
}
{
  require HTTP::Response;
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = Perl6::Slurp::slurp(<samples/athex/last30-hto-27sep11.html>);
  $resp->content($content);
  $resp->content_type('text/html');

  my $fq = Finance::Quote->new;
  my %quotes;
  Finance::Quote::ATHEX::resp_to_quotes ($fq, $resp, \%quotes, 'HTO');
  ### %quotes

  exit 0;
}

{
  my $fq = Finance::Quote->new ('-defaults', 'ATHEX');
  my %quotes = $fq->fetch ('mgex', 'HTO', 'ALPHA');
  ### %quotes
  exit 0;
}
