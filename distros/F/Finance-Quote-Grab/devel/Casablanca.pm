# examples/dump.pl:
#    ./dump.pl -casablanca BCE
#    , 'Casablanca'


# Copyright 2008, 2009, 2010, 2011, 2014, 2015, 2016 Kevin Ryde

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

package Finance::Quote::Casablanca;
use strict;

use vars qw($VERSION %label_to_field);
$VERSION = 15;

# uncomment this to run the ### lines
#use Smart::Comments;


# ENHANCE-ME: "figure of affair" is total business turnover or some such


sub methods {
  return (casablanca => \&casablanca_quotes);
}
sub labels {
  return (casablanca => [ qw(date isodate name currency
                             bid ask
                             open high low last close p_change volume
                             year_range
                             eps
                             div ex_div div_yield
                             cap
                             method source success errormsg

                             bid_quantity
                             ask_quantity
                             dollar_volume_both_sides
                             year_high
                             year_low
                             net_profit
                             payout_percent
                             par_value
                             shares_on_issue
                             nominal_capital
                           ) ]);
}
sub currency_fields {
  return (Finance::Quote::default_currency_fields(),
          qw(dollar_volume_both_sides
             year_high
             year_low
             net_profit
             par_value
             nominal_capital));
}

# Similar information is on the stocks-by-sector page
#
#     http://www.casablanca-bourse.com/cgi/ASP/Marche_Central/sectors_en.asp
#
# but there's no bid/offer there, so the individual pages are used.
#
use constant QUOTE_BASE_URL =>
  'http://www.casablanca-bourse.com/cgi/ASP/Donnees_Valeur/anglais/Donnes_valeurs.asp?ticker_valeur=';

sub make_url {
  my ($symbol) = @_;
  require URI::Escape;
  return QUOTE_BASE_URL . URI::Escape::uri_escape($symbol);
}

sub casablanca_quotes {
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
    resp_to_quotes ($fq, $symbol, $resp, \%quotes);
  }
  return wantarray() ? %quotes : \%quotes;
}

# The "Reference price" seems to be the previous close, ie. reference for
# the change amount.  The volume is a dollar volume, and it seems to be
# doubled, roughly 2 * price * "Total securities traded".
#
%label_to_field = ('currentprice'      => 'last',
                   'opening'           => 'open',
                   'referenceprice'    => 'close', # ie. previous

                   'todayshigh'        => 'high',
                   'todayslow'         => 'low',
                   'percentchange'     => 'p_change',

                   'actualcapital'     => 'cap', # think this is market cap
                   'volume'            => 'dollar_volume_both_sides',
                   'totalsecuritiestraded' => 'volume',

                   'bestbuyersask'            => 'ask',
                   'quantityofbestbuyersask'  => 'ask_quantity',
                   'bestsellersbid'           => 'bid',
                   'quantityofbestsellersbid' => 'bid_quantity',
                   'yearshigh'                => 'year_high',
                   'yearslow'                 => 'year_low',

                   # is exercice the results year for other figures?
                   'exercice'         => undef,
                   'capital'          => 'nominal_capital',
                   # total business revenue, or turnover ?
                   'figureofaffair'   => undef,

                   'dividend'         => 'div', # amount
                   'numberofshare'    => 'shares_on_issue',
                   'netresult'        => 'net_profit', # total

                   'ex-datedividend'  => 'ex_div', # date
                   'nominalvalue'     => 'par_value',

                   'payout(en%)'      => 'payout_percent',
                   'dividendyield(%)' => 'div_yield',
                   'earningpershare'  => 'eps',

                   # empty label
                   '' => undef,
                  );

# store to hashref $quotes for $symbol based on HTTP::Response in $resp
sub resp_to_quotes {
  my ($fq, $symbol, $resp, $quotes) = @_;

  $quotes->{$symbol,'method'} = 'casablanca';
  $quotes->{$symbol,'currency'} = 'MAD';
  $quotes->{$symbol,'source'} = __PACKAGE__;
  $quotes->{$symbol,'success'} = 1;

  # defaults to latin1, which is right
  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');
  if (! $resp->is_success) {
    $quotes->{$symbol,'success'}  = 0;
    $quotes->{$symbol,'errormsg'} = $resp->status_line;
    return;
  }
  $content =~ tr/\240/ /;

  if ($content =~ /Pas de r.sultat/) {
    $quotes->{$symbol,'success'}  = 0;
    $quotes->{$symbol,'errormsg'} = 'No information';
    return;
  }

  # Pick out the name, eg.
  # <center>
  #  <p>&nbsp;</p>
  #  <p><font color="#004496" face="Verdana" size="-1"><b>AUTO NEJMA    </b></font><br>
  if ($content !~ /<[bB]>([A-Z][^<\r\n]+)/) {
    $quotes->{$symbol,'success'}  = 0;
    $quotes->{$symbol,'errormsg'} = 'Cannot find stock name in page';
    return;
  }
  my $name = $1;
  $name =~ s/\s+$//; # trailing whitespace
  $quotes->{$symbol,'name'} = $name;

  # Pick out the date, eg.
  # <b>Session of:</b> </font><font color="#004496" face="Verdana" size="-2"><b>
  #      13/04/2007 </b></font> </td>
  # Match first d/m/y after "Session of" (possibly crossing newlines)
  if ($content !~ m{Session of.*?([0-9]{1,2}/[0-9]{1,2}/[0-9]{4})}s) {
    $quotes->{$symbol,'success'}  = 0;
    $quotes->{$symbol,'errormsg'} = 'Cannot find date in page';
    return;
  }
  $fq->store_date($quotes, $symbol, {eurodate => $1});

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new;
  $te->parse ($content);

  foreach my $ts ($te->tables) {
    my $rows = $ts->rows;
    foreach my $row (@$rows) {
      ### $row

      for (my $i = 0; $i <= $#$row-1; $i += 2) {
        my $label = $row->[$i];
        if (! defined $label) { next; }
        $label = lc $label;
        $label =~ s/[\s:']//g; # collapse for matching
        #         if (DEBUG) {
        #           if (! exists $label_to_field{$label}) {
        #             print "Unrecognised label: '$label'\n";
        #           }
        #         }
        my $field = $label_to_field{$label} or next;

        my $value = $row->[$i+1];
        $value =~ tr/\240/ /; # &nbsp; converted by TableExtract HTML::Parser
        $value =~ s/\s//g;    # whitespace leading, trailing, and thousands sep
        $value =~ tr/,/./;    # comma for decimal point
        if ($value eq '-') { $value = ''; }  # '-' when no value

        $quotes->{$symbol,$field} = $value;
      }
    }
  }

  if (! defined $quotes->{$symbol,'last'}) {
    $quotes->{$symbol,'success'}  = 0;
    $quotes->{$symbol,'errormsg'} = 'Price tables not matched in HTML';
    return;
  }

  # make year_range out of year_high and year_low because the latter two
  # aren't standard FQ fields
  if (defined $quotes->{$symbol,'year_high'}
      && defined $quotes->{$symbol,'year_low'}) {
    $quotes->{$symbol,'year_range'}
      = $quotes->{$symbol,'year_high'} . '-' . $quotes->{$symbol,'year_low'};
  }

  # ex-div is d/m/y format like 17/07/2006, change it to ISO to be unambiguous
  # can be empty when no dividends, eg. ACRED
  # http://www.casablanca-bourse.com/cgi/ASP/Donnees_Valeur/anglais/Donnes_valeurs.asp?ticker_valeur=ACR
  #
  if (defined $quotes->{$symbol,'ex_div'}) {
    if ($quotes->{$symbol,'ex_div'} eq '') {
      delete $quotes->{$symbol,'ex_div'};
    } else {
      $quotes->{$symbol,'ex_div'} = _dmy_to_iso ($quotes->{$symbol,'ex_div'});
    }
  }
}

# $str is a d/m/y date string like 17/07/2006, return an ISO form like
# 2006-07-17
sub _dmy_to_iso {
  my ($str) = @_;
  my ($day, $month, $year) = split /\//, $str;
  return sprintf '%04d-%02d-%02d', $year, $month, $day;
}

1;
__END__

=head1 NAME

Finance::Quote::Casablanca - download Casablanca Stock Exchange quotes

=for Finance_Quote_Grab symbols MNG BCE

=head1 SYNOPSIS

 use Finance::Quote;
 my $fq = Finance::Quote->new ('Casablanca');
 my %quotes = $fq->fetch('casablanca','MNG','BCE');

=head1 DESCRIPTION

This module downloads stock quotes from the Casablanca Stock Exchange,

=over 4

L<http://www.casablanca-bourse.com>

=back

Using pages like,

=for Finance_Quote_Grab symbols MNG

=over 4

L<http://www.casablanca-bourse.com/cgi/ASP/Donnees_Valeur/anglais/Donnes_valeurs.asp?ticker_valeur=MNG>

=back

The web site terms can be found at the end of the home page.  As of June
2009 reproduction of information is for personal private use.  It's your
responsibility to ensure your use of this module complies with current and
future terms.

Quotes are delayed by 20 minutes.

=head2 Fields

The following standard C<Finance::Quote> fields are available

=for Finance_Quote_Grab fields flowed standard

    date isodate name currency
    bid ask
    open high low last close p_change volume
    year_range
    eps
    div ex_div div_yield
    cap
    method source success errormsg

C<ex_div> is in ISO YYYY-MM-DD format, or if no dividend at all then the
field is omitted.

Plus the following extra fields

=for Finance_Quote_Grab fields table extra

    bid_quantity      number of shares at the bid
    ask_quantity      number of shares offered at the ask
    dollar_volume_both_sides
    year_high         \ as per year_range
    year_low          /
    net_profit        total company profit
    payout_percent    how much of net profit paid as dividends
    par_value         of each share
    shares_on_issue
    nominal_capital   par_value * shares_on_issue

C<cap> (market capitalization) is C<last> times C<shares_on_issue>.
C<net_profit> is C<eps> times C<shares_on_issue>.

C<dollar_volume_both_sides> is so named since it seems to add both the
buyer's dollar value and seller's dollar value, ie. roughly "2 * last *
volume".

=head1 SEE ALSO

L<Finance::Quote>, L<LWP>

Casablanca Stock Exchange web site L<http://www.casablanca-bourse.com>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/finance-quote-grab/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2014, 2015, 2016 Kevin Ryde

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
