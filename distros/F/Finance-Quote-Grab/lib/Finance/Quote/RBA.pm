# Copyright 2007, 2008, 2009, 2010, 2011, 2014, 2015, 2016, 2019 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.


package Finance::Quote::RBA;
use strict;
use Scalar::Util;
use Finance::Quote 1.15; # for isoTime()

use vars qw($VERSION %name_to_symbol);
$VERSION = 15;

# uncomment this to run the ### lines
#use Smart::Comments;


sub methods {
  return (rba => \&rba_quotes);
}
sub labels {
  return (rba => [ qw(date isodate name currency
                      last close
                      method source success errormsg

                      time copyright_url) ]);
}

use constant EXCHANGE_RATES_URL =>
  'https://www.rba.gov.au/statistics/frequency/exchange-rates.html';

use constant COPYRIGHT_URL =>
  'https://www.rba.gov.au/copyright/index.html';

sub rba_quotes {
  my ($fq, @symbol_list) = @_;
  if (! @symbol_list) { return; }

  my $ua = $fq->user_agent;
  require HTTP::Request;
  my $req = HTTP::Request->new ('GET', EXCHANGE_RATES_URL);
  $ua->prepare_request ($req);
  $req->accept_decodable; # using decoded_content() below
  $req->user_agent (__PACKAGE__."/$VERSION " . $req->user_agent);

  my $resp = $ua->request ($req);
  my %quotes;
  _parse ($fq, $resp, \%quotes, \@symbol_list);
  return wantarray() ? %quotes : \%quotes;
}

sub _parse {
  my ($fq, $resp, $quotes, $symbol_list) = @_;

  foreach my $symbol (@$symbol_list) {
    $quotes->{$symbol,'method'}  = 'rba';
    $quotes->{$symbol,'source'}  = __PACKAGE__;
    $quotes->{$symbol,'success'} = 0;
  }

  if (! $resp->is_success) {
    _errormsg ($quotes, $symbol_list, $resp->status_line);
    return;
  }
  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');

  # mung <tr id="USD"> to add <td>USD</td> so it appears in the TableExtract
  $content =~ s{<tr>}{<tr><td></td>}ig;
  $content =~ s{(<tr +id="([^"]*)">)}{$1<td>$2</td>}ig;

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (
     # now in a <caption> instead of a heading
     # headers => [qr/Units of Foreign Currencies per/i],
     slice_columns => 0);
  $te->parse($content);
  my $ts = $te->first_table_found;
  if (! $ts) {
    _errormsg ($quotes, $symbol_list, 'rates table not found in HTML');
    return;
  }

  # column of letters "P" "U" "B" "L" "I" "C" "H" "O" "L" "I" "D" "A" "Y"
  # on a bank holiday -- skip those
  my ($col, $prevcol);
  for (my $i = $ts->columns - 1; $i >= 2; $i--) {
    if (Scalar::Util::looks_like_number ($ts->cell (1, $i))) {
      $col = $i;
      last;
    }
  }
  for (my $i = $col - 1; $i >= 2; $i--) {
    if (Scalar::Util::looks_like_number ($ts->cell (1, $i))) {
      $prevcol = $i;
      last;
    }
  }
  ### $col
  ### $prevcol
  if (! defined $col) {
    _errormsg ($quotes, $symbol_list, 'No numeric columns found');
    return;
  }

  my $date = $ts->cell (0, $col);

  my %want_symbol;
  @want_symbol{@$symbol_list} = (); # hash slice
  my %seen_symbol;

  foreach my $row (@{$ts->rows()}) {
    ### $row

    my $symbol = $row->[0];
    $symbol or next;       # dates row, or no id="" in <tr>
    $symbol =~ s/_.*//; # _4pm on TWI
    $symbol = "AUD$symbol";
    if (! exists $want_symbol{$symbol}) { next; } # unwanted row

    my $name   = $row->[1];
    defined $name or next; # dates row
    ($name, my $time) = _name_extract_time ($fq, $name);

    my $rate = $row->[$col];
    my $prev = $row->[$prevcol];

    $fq->store_date($quotes, $symbol, {eurodate => $date});
    if (defined $time) {
      $quotes->{$symbol,'time'} = $time;
    }
    $quotes->{$symbol,'name'}   = $name;
    $quotes->{$symbol,'last'}   = $rate;
    $quotes->{$symbol,'close'}  = $prev;
    if ($symbol ne 'TWI') {
      $quotes->{$symbol,'currency'} = $symbol;
    }
    $quotes->{$symbol,'copyright_url'} = COPYRIGHT_URL;
    $quotes->{$symbol,'success'}  = 1;

    # don't delete AUDTWI from %want_symbol since want to get the last row
    # which is 16:00 instead of the 9:00 one
    $seen_symbol{$symbol} = 1;
  }


  delete @want_symbol{keys %seen_symbol}; # hash slice
  # any not seen
  _errormsg ($quotes, [keys %want_symbol], 'No such symbol');
}

sub _errormsg {
  my ($quotes, $symbol_list, $errormsg) = @_;
  foreach my $symbol (@$symbol_list) {
    $quotes->{$symbol,'errormsg'} = $errormsg;
  }
}

# pick out name and time from forms like
#     Trade-weighted index (9am)
#     Trade-weighted index (Noon)
#     Trade-weighted index (4pm)
# or without a time is 4pm, like
#     UK pound sterling
#
sub _name_extract_time {
  my ($fq, $name) = @_;

  if ($name =~ m/(.*?) +\(Noon\)$/i) {   # Noon
    return ($1, '12:00');
  } elsif ($name =~ m/(.*?) +\(([0-9]+)([ap]m)\)$/i) {  # 9am, 4pm
    return ($1, $fq->isoTime("$2:00$3"));
  } else {
    return ($name, '16:00');   # default 4pm
  }
}

1;
__END__

=head1 NAME

Finance::Quote::RBA - download Reserve Bank of Australia currency rates

=for test_synopsis my ($q, %rates);

=for Finance_Quote_Grab symbols AUDGBP AUDUSD

=head1 SYNOPSIS

 use Finance::Quote;
 $q = Finance::Quote->new ('RBA');
 %rates = $q->fetch ('rba', 'AUDGBP', 'AUDUSD');

=head1 DESCRIPTION

This module downloads currency rates for the Australian dollar from the
Reserve Bank of Australia,

=over 4

L<https://www.rba.gov.au/>

=back

using the page

=over 4

L<https://www.rba.gov.au/statistics/frequency/exchange-rates.html>

=back

As of June 2009 the web site terms of use,

=over 4

L<https://www.rba.gov.au/copyright/index.html>

=back

are for personal non-commercial use with proper attribution.  (It will be
noted material is to be used in ``unaltered form'', but the bank advises
import into a charting program is permitted.)  It's your responsibility to
ensure your use of this module complies with current and future terms.

=head2 Symbols

The symbols used are "AUDXXX" where XXX is the other currency.  Each is the
value of 1 Australian dollar in the other currency.  As of February 2019 the
following symbols are available

    AUDUSD    US dollar
    AUDCNY    Chinese renminbi
    AUDJPY    Japanese yen
    AUDEUR    Euro
    AUDKRW    South Korean won
    AUDSGD    Singapore dollar
    AUDNZD    New Zealand dollar
    AUDGBP    British pound sterling
    AUDMYR    Malaysian ringgit
    AUDTHB    Thai baht
    AUDIDR    Indonesian rupiah
    AUDINR    Indian rupee
    AUDTWD    Taiwanese dollar
    AUDVND    Vietnamese dong
    AUDHKD    Hong Kong dollar
    AUDPGK    Papua New Guinea kina
    AUDCHF    Swiss franc
    AUDAED    United Arab Emirates dirham
    AUDCAD    Canadian dollar

Plus the RBA's Trade Weighted Index for the Australian dollar, and the
Australian dollar valued in the IMF's Special Drawing Right basket of
currencies.

    AUDTWI    Trade Weighted Index
    AUDSDR    Special Drawing Right

The "AUD" in each is a bit redundant, but it's in the style of Yahoo Finance
currency crosses and makes it clear which way around the rate is expressed.

The currency symbols are "id" attributes in the HTML page source so a new
currency should be accessible by that code.

=head2 Fields

The following standard C<Finance::Quote> fields are returned

=for Finance_Quote_Grab fields flowed standard

    date isodate name currency
    last close
    method source success errormsg

Plus the following extras

=for Finance_Quote_Grab fields table extra

    time              ISO string "HH:MM"
    copyright_url

C<time> is always "16:00", ie. 4pm, currently.  The bank publishes TWI
(trade weighted index) values for 10am and Noon too, but not until the end
of the day when the 4pm value is the latest.

C<currency> is the other currency.  Prices are the value of an Australian
dollar in the respective currency.  For example in "AUDUSD" the C<currency>
is "USD".  C<currency> is omitted for "AUDTWI" since "TWI" is not a defined
international currency code.  But it is returned for "AUDSDR", the IMF
special drawing right basket.

=head1 OTHER NOTES

Currency rates are downloaded just as "prices", there's no tie-in to the
C<Finance::Quote> currency conversion feature.

The exchange rates page above includes an RSS feed in "cb" central bank
format, but it doesn't give previous day's rates for the Finance-Quote
"close" field.

=head1 SEE ALSO

L<Finance::Quote>, L<LWP>

RBA website L<https://www.rba.gov.au/>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/finance-quote-grab/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2014, 2015, 2016, 2019 Kevin Ryde

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
