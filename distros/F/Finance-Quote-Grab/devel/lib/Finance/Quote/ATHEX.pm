# Copyright 2011, 2014, 2015, 2016 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.

# cf ASEGR.pm

package Finance::Quote::ATHEX;
use 5.004;
use strict;
use Carp;

# uncomment this to run the ### lines
use Devel::Comments;

use vars '$VERSION';
$VERSION = 15;


# eg. http://www.helex.gr/content/en/marketdata/stocks/prices/Share_SearchResults.asp?share=HTO
#
use constant ATHEX_LAST30_BASE_URL =>
  'http://www.helex.gr/content/en/marketdata/stocks/prices/Share_SearchResults.asp?share=';

use constant ATHEX_SEARCH_BASE_URL =>
  'http://www.helex.gr/content/en/MarketData/Stocks/Prices/Share_SearchResults.asp?submit2=Go&myshare=ALPHA';

use constant ATHEX_STOCKINFO_BASE_URL =>
  'http://www.helex.gr/content/en/Companies/ListedCo/Profiles/pr_Snapshot.asp?Cid=';

sub methods {
  return (athex => \&athex_quotes);
}
sub labels {
  return (athex => [ qw(date isodate name
                        open high low last
                        method source success errormsg
                      ) ]);
}

sub athex_quotes {
  my ($fq, @symbol_list) = @_;
  my $ua = $fq->user_agent;
  my %quotes;

  foreach my $symbol (@symbol_list) {
    next unless defined (my $cid = symbol_to_cid ($fq, \%quotes, $symbol));
    my $url = ATHEX_STOCKINFO_BASE_URL . URI::Escape::uri_escape($cid);

    require HTTP::Request;
    my $req = HTTP::Request->new ('GET', $url);
    $ua->prepare_request ($req);
    $req->accept_decodable; # we have decoded_content() below
    $req->user_agent (__PACKAGE__."/$VERSION " . $req->user_agent);
    ### req: $req->as_string

    my $resp = $ua->request ($req);
    stockinfo_to_quotes ($fq, $resp, \%quotes, $symbol);


    # my $url = ATHEX_LAST30_BASE_URL . URI::Escape::uri_escape($symbol);
    # last30_to_quotes ($fq, $resp, \%quotes, $symbol);
  }
  return wantarray() ? %quotes : \%quotes;
}

sub symbol_to_cid {
  my ($fq, $quotes, $symbol) = @_;
  my $ua = $fq->user_agent;
  my $url = ATHEX_SEARCH_BASE_URL . URI::Escape::uri_escape($symbol);

  require HTTP::Request;
  my $req = HTTP::Request->new ('GET', $url);
  $ua->prepare_request ($req);
  $req->accept_decodable; # we have decoded_content() below
  $req->user_agent (__PACKAGE__."/$VERSION " . $req->user_agent);
  ### req: $req->as_string

  my $resp = $ua->request ($req);
  _search_resp_to_cid ($resp, $quotes, $symbol);
}
sub _search_resp_to_cid {
  my ($resp, $quotes, $symbol) = @_;
  if (! $resp->is_success) {
    $quotes->{$symbol,'errormsg'} = $resp->status_line;
    return undef;
  }
  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');

  if ($content =~ /Your search didn't return any results/) {
    $quotes->{$symbol,'errormsg'} = 'No such symbol';
    return undef;
  }

  if ($content =~ m{\Qhttp://www.helex.gr/content/en/Companies/ListedCo/Profiles/Profile.asp?cid=\E(\d+)}) {
    return $1;
  } else {
    $quotes->{$symbol,'errormsg'} = 'Oops, CID number not matched';
    return undef;
  }
}

sub stockinfo_to_quotes {
  my ($fq, $resp, $quotes, $symbol) = @_;
  ### ATHEX stockinfo_to_quotes() ...

  $quotes->{$symbol,'method'}   = 'athex';
  $quotes->{$symbol,'source'}   = __PACKAGE__;
  $quotes->{$symbol,'success'}  = 0;

  if (! $resp->is_success) {
    $quotes->{$symbol,'errormsg'} = $resp->status_line;
    return undef;
  }
  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');

  require HTML::TableExtract;
  {
    my $te = HTML::TableExtract->new
      (headers => [qr/Last.*Price/is,
                   qr/Change[^%]*$/is,
                   qr/Change.*%/is,
                  ]);
    $te->parse($content);
    if (! $te->tables) {
      $quotes->{$symbol,'errormsg'} = 'Oops, stockinfo day table not matched';
      return;
    }
    my $rows = $te->rows;
    ### $rows
    ($quotes->{$symbol,'last'},
     $quotes->{$symbol,'change'},
     $quotes->{$symbol,'p_change'})
     = @{$rows->[1]};
  }
  {
    my $te = HTML::TableExtract->new
      (headers => [qr/Day.*Max/is,
                   qr/Day.*Min/is,
                   qr/Previous.*Close/is,
                  ]);
    $te->parse($content);
    if (! $te->tables) {
      $quotes->{$symbol,'errormsg'} = 'Oops, stockinfo day table not matched';
      return;
    }
    my $rows = $te->rows;
    ### $rows
    ($quotes->{$symbol,'high'},
     $quotes->{$symbol,'low'},
     $quotes->{$symbol,'close'})  # previous
      = @{$rows->[1]};
  }

  my ($volume, $dollar_volume);
  {
    my $te = HTML::TableExtract->new
      (headers => [qr/Total.*Volume/is,
                   qr/Total Value/is,
                  ]);
    $te->parse($content);
    if (! $te->tables) {
      $quotes->{$symbol,'errormsg'} = 'Oops, stockinfo day table not matched';
      return;
    }
    my $rows = $te->rows;
    ### $rows
    ($volume, $dollar_volume) = @{$rows->[0]};
    $volume =~ s/,//g;  # remove comma thousands separators
    $dollar_volume =~ s/,//g;
    $quotes->{$symbol,'volume'} = $volume;
    $quotes->{$symbol,'dollar_volume'} = $dollar_volume;
  }
  {
    my $te = HTML::TableExtract->new
      (headers => [qr/Nr.*Trades/is,
                  ]);
    $te->parse($content);
    if (! $te->tables) {
      $quotes->{$symbol,'errormsg'} = 'Oops, stockinfo num trades table not matched';
      return;
    }
    my $rows = $te->rows;
    ### $rows
    ($quotes->{$symbol,'num_trades'}) = @{$rows->[1]};
  }
  {
    my $te = HTML::TableExtract->new
      (headers => [qr/Total.*Number.*shares/is,
                   qr/Market.*value/is,
                  ]);
    $te->parse($content);
    if (! $te->tables) {
      $quotes->{$symbol,'errormsg'} = 'Oops, stockinfo cap table not matched';
      return;
    }
    my $rows = $te->rows;
    ### $rows
    my ($shares_on_issue, $cap) = @{$rows->[0]};
    $shares_on_issue =~ s/,//g;  # remove comma thousands separators
    $cap =~ s/^\s+//; # whitespace
    $cap =~ s/\s+$//;
    $quotes->{$symbol,'total_shares'} = $shares_on_issue;
    $quotes->{$symbol,'cap'} = $cap; # market capitalization
  }

  $quotes->{$symbol,'currency'} = 'EUR';
  $quotes->{$symbol,'success'}  = 1;

  # $quotes->{$symbol,'name'}     = $name;
  #  $quotes->{$symbol,'open'}     = $open;
  # $fq->store_date($quotes, $symbol, {eurodate => $date});
}

sub last30_to_quotes {
  my ($fq, $resp, $quotes, $symbol) = @_;
  ### ATHEX last30_to_quotes() ...

  $quotes->{$symbol,'method'}  = 'athex';
  $quotes->{$symbol,'source'}  = __PACKAGE__;
  $quotes->{$symbol,'success'} = 0;

  if (! $resp->is_success) {
    $quotes->{$symbol,'errormsg'} = $resp->status_line;
    return;
  }
  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');

  # message in page if bad symbol
  if ($content =~ /Your search didn't return any results/) {
    ### unknown symbol ...
    $quotes->{$symbol,'errormsg'} = 'Unknown symbol';
    return;
  }

  unless ($content
          =~ m{Share Closing Prices: ([A-Z]+)[^-]*-[^>]*>([^<]+)</a>}) {
    $quotes->{$symbol,'errormsg'} = 'Oops, last30 name not matched';
    return;
  }
  my $name = $2;
  ### raw name: $name

  # Some names on the english pages have greek 8859-7 capitals, mung those
  # to plain ascii.  This tr generated by devel/athex-tr.pl.
  # Eg. "BANK in http://www.helex.gr/content/en/marketdata/stocks/prices/Share_SearchResults.asp?share=ALPHA
  #
  $name =~ tr{\xB6\xB8\xB9\xBA\xBF\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC9\xCA\xCB\xCC\xCD\xCE\xD0\xD1\xD3\xD4\xD9\xDC\xDD\xDF\xE1\xE2\xE3\xE4\xE5\xE6\xE9\xEA\xEB\xEC\xED\xF0\xF1\xF2\xF3\xF4\xF9\xFA\xFE}
             {AEHIOABGDEZHIKLMNXPRSTOaeiabgdeziklmnprsstoio};
  ### tr name: $name

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => ['Date', 'Open', 'Max', 'Min', 'Price', 'Volume' ]);
  $te->parse($content);
  if (! $te->tables) {
    $quotes->{$symbol,'errormsg'} = 'Oops, last30 table not matched';
    return;
  }

  my $rows = $te->rows;
  ### row: $rows->[0]
  if (! $rows->[0]) {
    $quotes->{$symbol,'errormsg'} = 'No trades';
    return;
  }

  my ($date, $open, $high, $low, $close, $volume) = @{$rows->[0]};
  my $prev;
  if ($rows->[1]) {
    $prev = $rows->[1]->[4];
  }

  $volume =~ s/,//g;  # remove comma thousands separators

  $quotes->{$symbol,'method'}   = 'athex';
  $quotes->{$symbol,'source'}   = __PACKAGE__;
  $quotes->{$symbol,'success'}  = 1;
  $quotes->{$symbol,'name'}     = $name;
  $quotes->{$symbol,'currency'} = 'EUR';
  $quotes->{$symbol,'open'}     = $open;
  $quotes->{$symbol,'high'}     = $high;
  $quotes->{$symbol,'low'}      = $low;
  $quotes->{$symbol,'last'}     = $close; # today's close
  $quotes->{$symbol,'close'}    = $prev;  # previous close
  $quotes->{$symbol,'volume'}   = $volume;
  $fq->store_date($quotes, $symbol, {eurodate => $date});
}


1;
__END__

=head1 NAME

Finance::Quote::ATHEX - download share quotes from ATHEX

=for Finance_Quote_Grab symbols HTO

=head1 SYNOPSIS

 use Finance::Quote;
 my $fq = Finance::Quote->new ('ATHEX');
 my %quotes = $fq->fetch('athex', 'HTO');

=head1 DESCRIPTION

This module downloads share prices from the Athens Stock Exchange,

=over 4

L<http://www.helex.gr/>

=back

Using the English "last 30 days" pages such as "HTO" for Hellenic Telecom,

=for Finance_Quote_Grab symbols HTO

=over 4

L<http://www.helex.gr/content/en/marketdata/stocks/prices/Share_SearchResults.asp?share=HTO>

=back

=head2 Fields

The following standard C<Finance::Quote> fields are available

=for Finance_Quote_Grab fields flowed standard

    date isodate name currency
    open high low last volume close
    method source success errormsg

=for Finance_Quote_Grab symbols ALPHA

For reference, some of the English names in the web pages have ISO-8859-7
Greek characters such as 0xC2 Beta for "B" in "BANK" of ALPHA BANK.  They're
transliterated to their apparent ASCII intention where possible.

=head1 CF

L<http://www.helex.gr/content/en/Companies/ListedCo/Profiles/pr_Snapshot.asp?Cid=99>

=back

=head1 SEE ALSO

L<Finance::Quote>, L<LWP>

ATHEX web site L<http://www.helex.gr>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/finance-quote-grab/index.html>

=head1 LICENCE

Copyright 2011, 2014, 2015, 2016 Kevin Ryde

Finance-Quote-Grab is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Finance-Quote-Grab is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Finance-Quote-Grab; see the file F<COPYING>.  If not, see
L<http://www.gnu.org/licenses/>.

=cut
