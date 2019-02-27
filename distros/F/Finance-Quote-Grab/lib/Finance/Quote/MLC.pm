# Copyright 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2014, 2015, 2016 Kevin Ryde

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

package Finance::Quote::MLC;
use strict;

use vars qw($VERSION);
$VERSION = 15;

# uncomment this to run the ### lines
#use Smart::Comments;

sub methods {
  return (mlc => \&mlc_quotes);
}
sub labels {
  return (mlc => [ qw(date isodate name currency
                      last close
                      method source success errormsg

                      copyright_url
                    ) ]);
}

use constant COPYRIGHT_URL =>
  'http://www.mlc.com.au/mlc/im_considering_mlc/personal/footer_tools/advice_warning_and_disclaimer';


sub mlc_quotes {
  my ($fq, @symbol_list) = @_;
  my $ua = $fq->user_agent;
  my %quotes;

  foreach my $symbol (@symbol_list) {
    my $url = make_url ($symbol);

    my $req = HTTP::Request->new ('GET', $url);
    $ua->prepare_request ($req);
    $req->accept_decodable; # we know decoded_content() below
    $req->user_agent (__PACKAGE__."/$VERSION " . $req->user_agent);
    ### Request: $req->as_string

    my $resp = $ua->request ($req);
    resp_to_quotes ($fq, $resp, \%quotes, $symbol);
  }
  return wantarray() ? %quotes : \%quotes;
}

# Sample url:
# https://www.mlc.com.au/masterkeyWeb/execute/UnitPricesWQO?openAgent&reporttype=HistoricalDateRange&product=MasterKey%20Allocated%20Pension%20%28Five%20Star%29&fund=MLC%20Horizon%201%20-%20Bond%20Portfolio&begindate=19/05/2010&enddate=28/05/2010&
#
# The end date is today Sydney time.  Sydney timezone is +10, and +11 during
# daylight savings; but instead of figuring when daylight savings is in
# force just use +11 all the time.
#
# Obviously today's price won't be available just after midnight, so a time
# offset giving today after 9am or 4pm or some such could make more sense.
# Actually as of Feb 2009 price for a given day aren't available until the
# afternoon of the next weekday, so the end date used here is going to be
# anything from 1 to 4 days too much.  It does no harm to ask beyond what's
# available.
#
# The start date requested takes account of the slackness in the end date
# and the possibility of public holidays.  The worst case is on Tuesday
# morning.  The available price is still only the previous Friday, and if
# Thu/Fri are Christmas day and boxing day holidays then only Wednesday is
# available, and then want also the preceding day to get the prev price,
# which means the Tuesday, which is -7 days.  Go back 2 further days just in
# case too, for a total -9!
#
sub make_url {
  my ($symbol) = @_;

  my $t = time();
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
    = gmtime($t + 11 * 3600);
  my $hi_day = $mday;
  my $hi_month = $mon + 1;
  my $hi_year = $year + 1900;

  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
    = gmtime($t + 10 * 3600 - 9 * 86400);
  my $lo_day = $mday;
  my $lo_month = $mon + 1;
  my $lo_year = $year + 1900;

  my ($fund, $product) = symbol_to_fund_and_product ($symbol);

  require URI::Escape;
  return sprintf ('https://www.mlc.com.au/masterkeyWeb/execute/UnitPricesWQO?openAgent&reporttype=HistoricalDateRange&product=%s&fund=%s&begindate=%02d/%02d/%04d&enddate=%02d/%02d/%04d&',
                  URI::Escape::uri_escape ($product),
                  URI::Escape::uri_escape ($fund),
                  $lo_day, $lo_month, $lo_year,
                  $hi_day, $hi_month, $hi_year);
}

sub symbol_to_fund_and_product {
  my ($symbol) = @_;
  my $pos = index ($symbol, ',');
  if ($pos == -1) {
    return ($symbol, '');
  } else {
    return (substr ($symbol, 0, $pos),
            substr ($symbol, $pos+1));
  }
}

# store to hashref $quotes for $symbol based on HTTP::Response in $resp
#
# Initial line like:
#
#   historicalProduct1funds[0]="All Funds"
#
# Then price lines like:
#
#   historicalProduct1funds[1]="MLC Property Securities Fund,MasterKey Superannuation (Gold Star),29 March 2007,64.71567,0.00000";
#
sub resp_to_quotes {
  my ($fq, $resp, $quotes, $symbol) = @_;

  $quotes->{$symbol,'method'}   = 'mlc';
  $quotes->{$symbol,'currency'} = 'AUD';
  $quotes->{$symbol,'source'}   = __PACKAGE__;
  $quotes->{$symbol,'success'}  = 1;

  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');
  if (! $resp->is_success) {
    $quotes->{$symbol,'success'}  = 0;
    $quotes->{$symbol,'errormsg'} = $resp->status_line;
    return;
  }

  if ($content =~ /No unit prices available/i) {
    $quotes->{$symbol,'success'}  = 0;
    $quotes->{$symbol,'errormsg'} = 'No unit prices available';
    return;
  }

  my @data; # elements are arrayrefs [ $isodate, $price ]

  while ($content =~ /^historicalProduct1funds.*=\"(.*)\"/mg) {
    my ($got_fund, $got_product, $date, $price) = split /,/, $1;

    # skip historicalProduct1funds[0]="All Funds" bit
    if (! $got_product) { next; }

    $date = dmy_to_iso ($fq, $date);
    push @data, [ $date, $price ];
    ### $date
    ### $price
  }
  if (! @data) {
    $quotes->{$symbol,'success'}  = 0;
    $quotes->{$symbol,'errormsg'}
      = 'Oops, prices not matched in downloaded data';
    return;
  }

  # the lines come with newest date first, but don't assume that;
  # sort to oldest date in $data[0], newest in endmost elem
  @data = sort {$a->[0] cmp $b->[0]} @data;

  $fq->store_date($quotes, $symbol, {isodate => $data[-1]->[0]});
  $quotes->{$symbol,'last'} = $data[-1]->[1];
  if (@data > 1) {
    $quotes->{$symbol,'close'} = $data[-2]->[1];
  }
  $quotes->{$symbol,'copyright_url'} = COPYRIGHT_URL;
}

sub dmy_to_iso {
  my ($fq, $dmy) = @_;
  my %dummy_quotes;
  $fq->store_date (\%dummy_quotes, '', {eurodate => $dmy});
  return $dummy_quotes{'','isodate'};
}

1;
__END__

=head1 NAME

Finance::Quote::MLC - MLC fund prices

=head1 SYNOPSIS

 use Finance::Quote;
 my $fq = Finance::Quote->new ('MLC');
 my $fund = 'MLC MasterKey Horizon 1 - Bond Portfolio';
 my $product = 'MasterKey Allocated Pension (Five Star)';
 my %quotes = $fq->fetch('mlc', "$fund,$product");

=head1 DESCRIPTION

This module downloads MLC fund quotes from

=over 4

L<http://www.mlc.com.au>

=back

under

=over 4

https://www.mlc.com.au/masterkeyWeb/execute/FramesetUnitPrices

=back

As of Sept 2011 the web site terms of use,

=over 4

L<http://www.mlc.com.au/mlc/im_considering_mlc/personal/footer_tools/advice_warning_and_disclaimer>

=back

are for general information only, and only provided for residents of
Australia.  It's your responsibility to ensure your use of this module
complies with current and future terms.

=head2 Symbols

The symbols used are the fund name and product name with a comma, for
example

=for Finance_Quote_Grab symbols

    MLC Horizon 1 - Bond Portfolio,MasterKey Allocated Pension (Five Star)

This is a lot to type, but you can usually cut and paste it from the web
pages.  The page source in the link above has them in this form.

The fund part is the actual investment, but there isn't a single price quote
for it, rather the price varies with the product due to different fees
subtracted.

=head2 Fields

The following standard C<Finance::Quote> fields are available

=for Finance_Quote_Grab fields flowed standard

    date isodate name currency
    last close
    method source success errormsg

Plus the following extras

=for Finance_Quote_Grab fields flowed extra

    copyright_url

As of June 2009, prices are published some time in the afternoon of the
following business day (Friday's prices some time Monday afternoon).  So the
date field is always yesterday or the day before yesterday.  The currency is
always "AUD" Australian dollars.

=head1 SEE ALSO

L<Finance::Quote>, L<LWP>

MLC web site L<http://www.mlc.com.au>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/finance-quote-grab/index.html>

=head1 LICENCE

Copyright 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2014, 2015, 2016 Kevin Ryde

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
