# Copyright 2014, 2015, 2016, 2019 Kevin Ryde

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

package Finance::Quote::Ghana;
use 5.004;
use strict;
use Carp;

# uncomment this to run the ### lines
# use Smart::Comments;

use vars '$VERSION';
$VERSION = 15;


use constant GHANA_MARKET_URL =>
  'https://gse.com.gh/daily-shares-and-etfs-trades/';
   
sub methods {
  return (ghana => \&ghana_quotes);
}
sub labels {
  return (ghana => [ qw(date isodate
                        isin year_range
                        open net bid ask volume last
                        currency
                        method source success errormsg
                      ) ]);
}

sub ghana_quotes {
  my ($fq, @symbol_list) = @_;
  if (! @symbol_list) { return; }

  # The gse server (an Apache) will serve gzipped, so accept_decodable()
  # here saves some data transmission.
  #
  # user_agent() is set only to the package.  Would normally include the
  # libwww-perl identifier too, but some bad setup on the gse server gives
  # "406 Not acceptable" if more than one identifier.
  #
  require HTTP::Request;
  my $req = HTTP::Request->new ('GET', GHANA_MARKET_URL);
  $req->accept_decodable; # using decoded_content() below
  $req->user_agent (__PACKAGE__."/".$VERSION);
  ### req: $req->as_string

  my $ua = $fq->user_agent;
  my $resp = $ua->request ($req);
  ### resp headers: $resp->headers->as_string

  my %quotes;
  _parse ($fq, $resp, \%quotes, \@symbol_list);
  return wantarray() ? %quotes : \%quotes;
}

sub _parse {
  my ($fq, $resp, $quotes, $symbol_list) = @_;

  foreach my $symbol (@$symbol_list) {
    $quotes->{$symbol,'method'}   = 'ghana';
    $quotes->{$symbol,'source'}   = __PACKAGE__;
    $quotes->{$symbol,'success'}  = 0;
  }

  if (! $resp->is_success) {
    _errormsg ($quotes, $symbol_list, $resp->status_line);
    return;
  }
  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');

  # Eg. <span class="glyphicon glyphicon-calendar"></span> February 22, 2019</div>
  $content =~ m{glyphicon-calendar.*?([a-z]+) (\d{1,2}), (\d\d\d\d)}i
    or die "GSE: daily page cannot find trade date\n";
  my $date = "$1/$2/$3";  # "October/03/2014"

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => [ # qr/Session/i,
                 qr/ISIN/i,
                 qr/Share Code/i,
                 qr/Year High/i,
                 qr/Year Low/i,
                 qr/Previous Closing Price VWAP/i,
                 qr/Opening/i,
                 qr/Closing Price VWAP/i,
                 qr/Price Change/i,
                 qr/Closing Bid Price/i,
                 qr/Closing Offer Price/i,
                 qr/Total Shares Traded/i,
                 qr/Last Transaction Price/i,
                ]);
  $te->parse($content);
  my $ts = $te->first_table_found;
  if (! $ts) {
    _errormsg ($quotes, $symbol_list, 'rates table not found in HTML');
    return;
  }

  my %want_symbol;
  @want_symbol{@$symbol_list} = (); # hash slice
  my %seen_symbol;

  foreach my $row (@{$ts->rows()}) {
    ### $row

    my ($isin, $symbol, $year_high, $year_low,
        $previous_vwap, $open, $close_vwap, $change,
        $close_bid, $close_offer, $volume, $last)
      = @$row;
    if (! exists $want_symbol{$symbol}) { next; } # unwanted row

    # volume is for example "58,600"
    # strip the commas
    $volume =~ tr/,//d;

    # volume has been seen as "0.00", eg. from GLD
    # prefer to return it as an integer
    $volume =~ s/\.0*$//;

    $fq->store_date($quotes, $symbol, {usdate => $date});
    $quotes->{$symbol,'isin'}       = $isin;
    $quotes->{$symbol,'year_range'} = "$year_high-$year_low";
    $quotes->{$symbol,'open'}       = $open;
    $quotes->{$symbol,'net'}        = $change;
    $quotes->{$symbol,'bid'}        = $close_bid    if defined $close_bid;
    $quotes->{$symbol,'ask'}        = $close_offer  if defined $close_offer;
    $quotes->{$symbol,'volume'}     = $volume;
    $quotes->{$symbol,'last'}       = $last;
    $quotes->{$symbol,'currency'}   = 'GHS';

    # $quotes->{$symbol,'previous_vwap'} = $previous_vwap;
    # $quotes->{$symbol,'vwap'}          = $close_vwap;
    # $quotes->{$symbol,'copyright_url'} = COPYRIGHT_URL;
    $quotes->{$symbol,'success'}  = 1;
    $seen_symbol{$symbol} = 1;
  }

  # any not seen
  delete @want_symbol{keys %seen_symbol}; # hash slice
  foreach my $symbol (keys %want_symbol) {
    $quotes->{$symbol,'errormsg'} = 'No such symbol';
  }
}

sub _errormsg {
  my ($quotes, $symbol_list, $errormsg) = @_;
  foreach my $symbol (@$symbol_list) {
    $quotes->{$symbol,'errormsg'} = $errormsg;
  }
}

1;
__END__

=head1 NAME

Finance::Quote::Ghana - download quotes from Ghana Stock Exchange

=for Finance_Quote_Grab symbols CAL

=head1 SYNOPSIS

 use Finance::Quote;
 my $fq = Finance::Quote->new ('Ghana');
 my %quotes = $fq->fetch('ghana', 'CAL');

=head1 DESCRIPTION

This module downloads share prices from the Ghana Stock Exchange,

=over 4

L<https://www.gse.com.gh>

=back

Using the market trading results page

=over 4

L<https://gse.com.gh/daily-shares-and-etfs-trades/>

=back

=head2 Fields

The following standard C<Finance::Quote> fields are available

=for Finance_Quote_Grab fields flowed standard

    date isodate currency
    open last net volume
    bid ask
    year_range
    method source success errormsg

Plus the following extra

=for Finance_Quote_Grab fields table extra

    isin              ISIN share code

=head1 SEE ALSO

L<Finance::Quote>, L<LWP>

GSE web site L<http://www.gse.com.gh>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/finance-quote-grab/index.html>

=head1 LICENCE

Copyright 2014, 2015, 2016, 2019 Kevin Ryde

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
