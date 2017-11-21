# perl -w
#
#    Copyright (C) 1998-2002, Dj Padzensky <djpadz@padz.net>
#    Copyright (C) 2002-2015  Dirk Eddelbuettel <edd@debian.org>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# $Id: YahooQuote.pm,v 1.11 2010/03/27 00:44:10 edd Exp $

package Finance::YahooQuote;
require 5.005;

require Exporter;
use strict;
use vars qw($VERSION @EXPORT @ISA 
	    $QURL $QURLbase $QURLformat $QURLextended $QURLrealtime $QURLend
	    $TIMEOUT $PROXY $PROXYUSER $PROXYPASSWD);

use HTTP::Request::Common;
use Text::ParseWords;

$VERSION = '0.26';

## these variables govern what type of quote the modules is retrieving
# $QURLbase = "http://download.finance.yahoo.com/d/quotes.csv?e=.csv&f=";
$QURLbase = "https://download.finance.yahoo.com/d/quotes.csv?e=.csv&f=";
$QURLformat = "snl1d1t1c1p2va2bapomwerr1dyj1x";	# default up to 0.19
$QURLextended = "s7t8e7e8e9r6r7r5b4p6p5j4m3m4";	# new in 0.20
$QURLrealtime = "b2b3k2k1c6m2j3"; # also new in 0.20
$QURLend = "&s=";
$QURL = $QURLbase . $QURLformat . $QURLend; # define old format as default

@ISA = qw(Exporter);
@EXPORT = qw(&getquote &getonequote &getcustomquote 
	     &setQueryString &useExtendedQueryFormat 
	     &useRealtimeQueryFormat);
undef $TIMEOUT;

## simple function to switch to extended format
sub useExtendedQueryFormat {
  $QURLformat .= $QURLextended;
}

## simple function to append real-time format
sub useRealtimeQueryFormat {
  $QURLformat .= $QURLrealtime;
}

## allow module user to define a new query string
sub setQueryString {
  my $format = shift;
  $QURLformat = $format;
}

## Common function for reading the yahoo site and retrieving and
## parsing the data returned
## The format used is supplied as a second argument, the default function
## getquoye() below uses the default format $QURLformat, and either one of
## the two preceding functions can be used to select the extended format
sub readYahoo {

  my @symbols	= @{(shift)};
  my $format	= shift;

  my @qr;
  my $ua = RequestAgent->new;
  $ua->env_proxy;		# proxy settings from *_proxy env. variables.
  $ua->proxy('http', $PROXY) if defined $PROXY;
  $ua->timeout($TIMEOUT) if defined $TIMEOUT;

  #	Loop over the list of symbols, grabbing 199 symbols at a 
  #	time, since yahoo only lets you get 200 per request
  while ($#symbols > -1) {
    my @b = $#symbols >= 199 	? splice(@symbols,0,199) 
      : splice(@symbols,0,$#symbols+1);

    my $url = "$QURLbase${format}$QURLend".join('+',@b);
    foreach (split('\015?\012',$ua->request(GET $url)->content)) {
      my @q = quotewords(',',0,$_);
      push(@qr,[@q]);
    }
  }

  return \@qr;
}

my %fields = (
	      'Symbol'				=>  's',	# old default
	      'Name'				=>  'n',	# old default
	      'Last Trade (With Time)'		=>  'l',
	      'Last Trade (Price Only)'		=>  'l1',	# old default
	      'Last Trade Date'			=>  'd1',	# old default
	      'Last Trade Time'			=>  't1',	# old default
	      'Last Trade Size'			=>  'k3',
	      'Change and Percent Change'	=>  'c',
	      'Change'				=>  'c1',	# old default
	      'Change in Percent'		=>  'p2',	# old default
	      'Ticker Trend'			=>  't7',
	      'Volume'				=>  'v',	# old default
	      'Average Daily Volume'		=>  'a2',	# old default
	      'More Info'			=>  'i',
	      'Trade Links'			=>  't6',
	      'Bid'				=>  'b',	# old default
	      'Bid Size'			=>  'b6',
	      'Ask'				=>  'a',	# old default
	      'Ask Size'			=>  'a5',
	      'Previous Close'			=>  'p',	# old default
	      'Open'				=>  'o',	# old default
	      "Day's Range"			=>  'm',	# old default
	      '52-week Range'			=>  'w',	# old default
	      'Change From 52-wk Low'		=>  'j5',
	      'Pct Chg From 52-wk Low'		=>  'j6',
	      'Change From 52-wk High'		=>  'k4',
	      'Pct Chg From 52-wk High'		=>  'k5',
	      'Earnings/Share'			=>  'e',	# old default
	      'P/E Ratio'			=>  'r',	# old default
	      'Short Ratio'			=>  's7',
	      'Dividend Pay Date'		=>  'r1',	# old default
	      'Ex-Dividend Date'		=>  'q',
	      'Dividend/Share'			=>  'd',	# old default
	      'Dividend Yield'			=>  'y',	# old default
	      'Float Shares'			=>  'f6',
	      'Market Capitalization'		=>  'j1',	# old default
	      '1yr Target Price'		=>  't8',
	      'EPS Est. Current Yr'		=>  'e7',
	      'EPS Est. Next Year'		=>  'e8',
	      'EPS Est. Next Quarter'		=>  'e9',
	      'Price/EPS Est. Current Yr'	=>  'r6',
	      'Price/EPS Est. Next Yr'		=>  'r7',
	      'PEG Ratio'			=>  'r5',
	      'Book Value'			=>  'b4',
	      'Price/Book'			=>  'p6',
	      'Price/Sales'			=>  'p5',
	      'EBITDA'				=>  'j4',
	      '50-day Moving Avg'		=>  'm3',
	      'Change From 50-day Moving Avg'	=>  'm7',
	      'Pct Chg From 50-day Moving Avg'	=>  'm8',
	      '200-day Moving Avg'		=>  'm4',
	      'Change From 200-day Moving Avg'	=>  'm5',
	      'Pct Chg From 200-day Moving Avg'	=>  'm6',
	      'Shares Owned'			=>  's1',
	      'Price Paid'			=>  'p1',
	      'Commission'			=>  'c3',
	      'Holdings Value'			=>  'v1',
	      "Day's Value Change"		=>  'w1',
	      'Holdings Gain Percent'		=>  'g1',
	      'Holdings Gain'			=>  'g4',
	      'Trade Date'			=>  'd2',
	      'Annualized Gain'			=>  'g3',
	      'High Limit'			=>  'l2',
	      'Low Limit'			=>  'l3',
	      'Notes'				=>  'n4',
	      'Last Trade (Real-time) with Time'=>  'k1',
	      'Bid (Real-time)'			=>  'b3',
	      'Ask (Real-time)'			=>  'b2',
	      'Change Percent (Real-time)'	=>  'k2',
	      'Change (Real-time)'		=>  'c6',
	      'Holdings Value (Real-time)'	=>  'v7',
	      "Day's Value Change (Real-time)"	=>  'w4',
	      'Holdings Gain Pct (Real-time)'	=>  'g5',
	      'Holdings Gain (Real-time)'	=>  'g6',
	      "Day's Range (Real-time)"		=>  'm2',
	      'Market Cap (Real-time)'		=>  'j3',
	      'P/E (Real-time)'			=>  'r2',
	      'After Hours Change (Real-time)'	=>  'c8',
	      'Order Book (Real-time)'		=>  'i5',
	      'Stock Exchange'			=>  'x'		# old default
	     );

#	Let the user define which colums to retrive from yahoo
#	
sub getcustomquote {
  my $symbols = shift;
  my $columns = shift;

  my $format = join('',map {$fields{$_}} @{$columns});

  my $qr = readYahoo($symbols,$format);
  return wantarray() ? @$qr : $qr;
}

# get quotes for all symbols in array

sub getquote {
  my @symbols = @_;

  my $format = $QURLformat;	## Old default from variable
  my $qr = readYahoo(\@symbols,$format);
  return wantarray() ? @$qr : $qr;
}

# Input: A single stock symbol
# Output: An array, containing the list elements mentioned above.

sub getonequote {
    my @x;
    @x = &getquote($_[0]);
    return wantarray() ? @{$x[0]} : \@{$x[0]} if @x;
}

BEGIN {				# Local variant of LWP::UserAgent that 
  use LWP;			# checks for user/password if document 
  package RequestAgent;		# this code taken from lwp-request, see
  no strict 'vars';		# the various LWP manual pages
  @ISA = qw(LWP::UserAgent);

  sub new { 
    my $self = LWP::UserAgent::new(@_);
    $self->agent("Finance-YahooQuote/0.18");
    $self;
  }

  sub get_basic_credentials {
    my $self = @_;
    if (defined($PROXYUSER) and defined($PROXYPASSWD) and
 	$PROXYUSER ne "" and $PROXYPASSWD ne "") {
      return ($PROXYUSER, $PROXYPASSWD);
    } else {
      return (undef, undef)
    }
  }
}

1;

__END__

=head1 NAME

Finance::YahooQuote - Get stock quotes from Yahoo! Finance

=head1 SYNOPSIS

  use Finance::YahooQuote;
  # setting TIMEOUT and PROXY is optional
  $Finance::YahooQuote::TIMEOUT = 60;
  $Finance::YahooQuote::PROXY = "http://some.where.net:8080";
  @quote = getonequote $symbol;	# Get a quote for a single symbol
  @quotes = getquote @symbols;	# Get quotes for a bunch of symbols
  useExtendedQueryFormat();     # switch to extended query format
  useRealtimeQueryFormat();     # switch to real-time query format
  @quotes = getquote @symbols;	# Get quotes for a bunch of symbols
  @quotes = getcustomquote(["DELL","IBM"], # using custom format
			   ["Name","Book Value"]); # note array refs

=head1 DESCRIPTION

B<NOTE>: As of November 2017, the module is no longer all that useful
as Yahoo! decided to halt the API service it relies on.


This module gets stock quotes from Yahoo! Finance.  The B<getonequote>
function will return a quote for a single stock symbol, while the
B<getquote> function will return a quote for each of the stock symbols
passed to it.  B<getcustomquote> allows to specify a format other than
the default to take advantage of the extended range of available information.

The download operation is efficient: only one request is made even if
several symbols are requested at once. The return value of
B<getonequote> is an array, with the following elements:

    0 Symbol
    1 Company Name
    2 Last Price
    3 Last Trade Date
    4 Last Trade Time
    5 Change
    6 Percent Change
    7 Volume
    8 Average Daily Vol
    9 Bid
    10 Ask
    11 Previous Close
    12 Today's Open
    13 Day's Range
    14 52-Week Range
    15 Earnings per Share
    16 P/E Ratio
    17 Dividend Pay Date
    18 Dividend per Share
    19 Dividend Yield
    20 Market Capitalization
    21 Stock Exchange

If the extended format has been selected, the following fields are also
retrieved:

    22 Short ratio
    23 1yr Target Price
    24 EPS Est. Current Yr
    25 EPS Est. Next Year
    26 EPS Est. Next Quarter
    27 Price/EPS Est. Current Yr
    28 Price/EPS Est. Next Yr
    29 PEG Ratio
    30 Book Value
    31 Price/Book
    32 Price/Sales
    33 EBITDA
    34 50-day Moving Avg
    35 200-day Moving Avg

If the real-time format has been selected, the following fields are also
retrieved:

    36 Ask (real-time)
    37 Bid (real-time)
    38 Change in Percent (real-time)
    39 Last trade with time (real-time)
    40 Change (real-time)
    41 Day range (real-time)
    42 Market-cap (real-time)

The B<getquote> function returns an array of pointers to arrays with
the above structure.

The B<getonequote> function returns just one quote, rather than an array. It returns a simple array of values for the given symbol.

The B<setQueryString> permits to supply a new query string that will
be used for subsequent data requests.

The B<useExtendedQueryFormat> and B<useRealtimeQueryFormat> are
simpler interfaces which append symbols to the default quote string,
as detailed above.

The B<getcustomquote> returns an array of quotes corresponding to
values for the symbols supplied in the first array reference, and the
custom fields supplied in the second array reference. Here the custom
fields correspond to the 'named' fields of the list below.

Beyond stock quotes, B<Finance::YahooQuote> can also obtain quotes for
currencies (from the Philadephia exchange -- however Yahoo! appears to
have stopped to support the currency symbols in a reliable manner), US
mutual funds, options on US stocks, several precious metals and quite
possibly more; see the Yahoo! Finance website for full
information. B<Finance::YahooQuote> can be used for stocks from the
USA, Canada, various European exchanges, various Asian exchanges
(Singapore, Taiwan, HongKong, Kuala Lumpur, ...) Australia and New
Zealand. It should work for other markets supported by Yahoo.

You may optionally override the default LWP timeout of 180 seconds by setting
$Finance::YahooQuote::TIMEOUT to your preferred value.

You may also provide a proxy (for the required http connection) by using
the variable $Finance::YahooQuote::PROXY. Furthermore, authentication-based 
proxies can be used by setting the proxy user and password via the variables
$Finance::YahooQuote::PROXYUSER and $Finance::YahooQuote::PROXYPASSWD.

Two example scripts are provided to help with the mapping a stock
symbols as well as with Yahoo! Finance server codes. The regression
tests scripts in the B<t/> subdirectory of the source distribution
also contain simple examples.

=head2 The available custom fields

The following list contains all the available data fields at Yahoo!
along with the corresponding format string entry:

      Symbol				s
      Name				n
      Last Trade (With Time)		l
      Last Trade (Price Only)		l1
      Last Trade Date			d1
      Last Trade Time			t1
      Last Trade Size			k3
      Change and Percent Change		c
      Change				c1
      Change in Percent			p2
      Ticker Trend			t7
      Volume				v
      Average Daily Volume		a2
      More Info				i
      Trade Links			t6
      Bid				b
      Bid Size				b6
      Ask				a
      Ask Size				a5
      Previous Close			p
      Open				o
      Day's Range			m
      52-week Range			w
      Change From 52-wk Low		j5
      Pct Chg From 52-wk Low		j6
      Change From 52-wk High		k4
      Pct Chg From 52-wk High		k5
      Earnings/Share			e
      P/E Ratio				r
      Short Ratio			s7
      Dividend Pay Date			r1
      Ex-Dividend Date			q
      Dividend/Share			d
      Dividend Yield			y
      Float Shares			f6
      Market Capitalization		j1
      1yr Target Price			t8
      EPS Est. Current Yr		e7
      EPS Est. Next Year		e8
      EPS Est. Next Quarter		e9
      Price/EPS Est. Current Yr		r6
      Price/EPS Est. Next Yr		r7
      PEG Ratio				r5
      Book Value			b4
      Price/Book			p6
      Price/Sales			p5
      EBITDA				j4
      50-day Moving Avg			m3
      Change From 50-day Moving Avg	m7
      Pct Chg From 50-day Moving Avg	m8
      200-day Moving Avg		m4
      Change From 200-day Moving Avg	m5
      Pct Chg From 200-day Moving Avg	m6
      Shares Owned			s1
      Price Paid			p1
      Commission			c3
      Holdings Value			v1
      Day's Value Change		w1,
      Holdings Gain Percent		g1
      Holdings Gain			g4
      Trade Date			d2
      Annualized Gain			g3
      High Limit			l2
      Low Limit				l3
      Notes				n4
      Last Trade (Real-time) with Time	k1
      Bid (Real-time)			b3
      Ask (Real-time)			b2
      Change Percent (Real-time)	k2
      Change (Real-time)		c6
      Holdings Value (Real-time)	v7
      Day's Value Change (Real-time)	w4
      Holdings Gain Pct (Real-time)	g5
      Holdings Gain (Real-time)		g6
      Day's Range (Real-time)		m2
      Market Cap (Real-time)		j3
      P/E (Real-time)			r2
      After Hours Change (Real-time)	c8
      Order Book (Real-time)		i5
      Stock Exchange			x

=head1 FAQs

=head2 How can one figure out the format string?  

Provided a My Yahoo! (http://my.yahoo.com) account, go to the
following URL:

    http://edit.my.yahoo.com/config/edit_pfview?.vk=v1

Viewing the source of this page, you will come across the section that
defines the menus that let you select which elements go into a
particular view.  The <option> values are the strings that pick up
the information described in the menu item.  For example, Symbol
refers to the string "s" and name refers to the string "l".  Using
"sl" as the format string, we would get the symbol followed by the
name of the security.

The example script I<examine_server.sh> shows this in some more detail
and downloads example .csv files using B<GNU wget>.

=head2 What about different stock symbols for the same corporation?

This can be issue. For the first few years, Yahoo! Finance's servers 
appeared to be cover their respective local markets. E.g., the UK-based 
servers provided quotes for Europe, the Australian one for the Australia
and New Zealand and so on.  Hence, one needed to branch and bound code
and map symbols to their region's servers.

It now appears that this is no longer required, which is good news as it 
simplifies coding. However, some old symbols are no longer supported --
yet other, and supported, codes exist for the same company.  For example,
German stocks used to quoted in terms or their cusip-like 'WKN'. The
main server does not support these, but does support newer, acronym-based
symbols.  The example script examine_server.sh helps in finding the mapping
as e.g. from 555750.F to DTEGN.F for Deutsche Telekom. 

=head1 COPYRIGHT

Copyright 1998 - 2002 Dj Padzensky
Copyright 2002 - 2007 Dirk Eddelbuettel

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

The information that you obtain with this library may be copyrighted
by Yahoo! Inc., and is governed by their usage license.  See
http://www.yahoo.com/docs/info/gen_disclaimer.html for more
information.

=head1 AUTHOR

Dj Padzensky (C<djpadz@padz.net>), PadzNet, Inc., wrote the original
version. Dirk Eddelbuettel (C<edd@debian.org>) provided several
extensions based on DJ's original work and is the current maintainer.

=head1 SEE ALSO

The B<Finance::YahooQuote> home pages are found at
http://www.padz.net/~djpadz/YahooQuote/ and
http://dirk.eddelbuettel.com/code/yahooquote.html.

The B<smtm> (Show Me The Money) program uses Finance::YahooQuote for a
customisable stock/portfolio ticker and chart display, see 
http://dirk.eddelbuettel.com/code/smtm.html for more.  The B<beancounter>
program uses it to store quotes in a SQL database, see
http://dirk.eddelbuettel.com/code/beancounter.html.

=cut

