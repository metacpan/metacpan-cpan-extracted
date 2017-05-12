# Copyright 2008, 2009, 2010, 2011, 2013, 2014, 2015 Kevin Ryde

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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Finance::Quote::MGEX;
use 5.005;
use strict;

use vars '$VERSION';
$VERSION = 14;

# uncomment this to run the ### lines
# use Smart::Comments;

sub methods {
  return (mgex => \&mgex_quotes);
}
sub labels {
  return (mgex => [ qw(name currency
                       bid ask
                       open high low last close net
                       method source success errormsg

                       contract_month_iso time
                     ) ]);
}

# These are about 30 kbytes and 25 kbytes, and update every 60 seconds
# apparently, but there's no ETag or Last-Modified to save re-downloading.
#
use constant MGEX_AQUOTES_URL =>
  'http://sites.barchart.com/pl/mgex/aquotes.htx';
use constant MGEX_WQUOTES_URL =>
  'http://sites.barchart.com/pl/mgex/wquotes_js.js';

my %aq_url = (a => MGEX_AQUOTES_URL,
              w => MGEX_WQUOTES_URL);


# For individual quotes, but the pages are bigger than the wquote/aquote
# # eg. http://www.mgex.com/quotes.html?page=quote&sym=MW
# use constant MGEX_QUOTES_BASE =>
#   'http://www.mgex.com/quotes.html?page=quote&sym=';

sub mgex_quotes {
  my ($fq, @symbol_list) = @_;
  ### mgex_quotes() ...
  ### @symbol_list

  my $ua = $fq->user_agent;
  my %quotes;

  # while (@symbol_list) {
  #   my $symbol = shift @symbol_list;
  #   my $commodity = symbol_to_commodity($symbol);
  #   ### $commodity
  #   unless ($commodity) {
  #     _errormsg (\%quotes, [$symbol], 'No such symbol');
  #     next;
  #   }
  #   my $this_list = [ $symbol ];
  # 
  # }


  # split into symbols Ixxxx and AJxxx which are aquote and the rest wquote
  my @aq_keys;
  my %aq_symbol_list;
  foreach my $symbol (@symbol_list) {
    my $key = ($symbol =~ /^[AI]/ ? 'a' : 'w');
    unless ($aq_symbol_list{$key}) {
      push @aq_keys, $key;
    }
    push @{$aq_symbol_list{$key}}, $symbol;
  }
  ### @aq_keys
  ### %aq_symbol_list

  foreach my $aq (@aq_keys) {
    require HTTP::Request;
    my $req = HTTP::Request->new ('GET', $aq_url{$aq});
    $ua->prepare_request ($req);
    $req->accept_decodable; # we use decoded_content() below
    $req->user_agent (__PACKAGE__."/$VERSION " . $req->user_agent);
    ### req: $req->as_string

    my $resp = $ua->request ($req);
    resp_to_quotes ($fq, $resp, \%quotes, $aq_symbol_list{$aq});
  }
  return wantarray() ? %quotes : \%quotes;
}

sub symbol_to_commodity {
  my ($str) = @_;
  $str =~ s/[A-Z][0-9]+$//;
  return $str;
}

my %aquote_name_to_commodity
  = ('PIT NCI' => 'IC',
     'NCI'     => 'IC',
     'HRWI'    => 'IH',
     'HRSI'    => 'IP',
     'SRWI'    => 'IW',
     'NSI'     => 'IS',
     'AJC'     => 'AJ',
    );

my %month_code_to_month = ('F' => 1,
                           'G' => 2,
                           'H' => 3,
                           'J' => 4,
                           'K' => 5,
                           'M' => 6,
                           'N' => 7,
                           'Q' => 8,
                           'U' => 9,
                           'V' => 10,
                           'X' => 11,
                           'Z' => 12);
my @month_to_month_code
  = (undef, 'F','G','H','J','K','M','N','Q','U','V','X','Z');

my %month_name_to_number = ('jan' => 1,
                            'feb' => 2,
                            'mar' => 3,
                            'apr' => 4,
                            'may' => 5,
                            'jun' => 6,
                            'jul' => 7,
                            'aug' => 8,
                            'sep' => 9,
                            'oct' => 10,
                            'nov' => 11,
                            'dec' => 12);


sub _name_to_NSCM {
  my ($name) = @_;
  ### _name_to_NSCM(): $name
  my ($symbol, $commodity, $month, $y);

  if ($name =~ /^((PIT )?[A-Z]+) ([A-Za-z]+) '([0-9][0-9])$/) {
    ### aquotes.htx name ...
    #     "SRWI Feb '06"
    #     "PIT NCI Jan '06"
    #
    # in the past there were call options too, but not now
    #     "NCI Mar '07 1900 Call"
    #
    $name = $1;
    $commodity = $1;
    my $month_name = $3;
    $y = $4;

    $commodity = $aquote_name_to_commodity{$commodity}
      || return; # if unrecognised
    $month = $month_name_to_number{lc($month_name)}
      || return; # if unrecognised
    $symbol = $commodity
      . $month_to_month_code[$month]
        . $y; # two digit year

  } elsif ($name =~ m{\((([A-Z]+)([A-Z])([0-9]+))\)}) {
    # wquotes_js.js name like
    #     "MGEX (MWN9)"
    #     "KCBT (KEZ9)"
    #
    $name = undef;
    $symbol = $1;
    $commodity = $2;
    my $month_code = $3;
    $month = $month_code_to_month{$month_code}
      || return; # if unrecognised
    $y = $4;

  } else {
    return;
  }

  my $year = _y_to_year($y);
  ### $year
  my $contract_month = sprintf ('%04d-%02d-01', $year, $month);

  return ($name, $symbol, $commodity, $contract_month);
}

sub _y_to_year {
  my ($y) = @_;
  my $modulus = (length($y) == 1 ? 10 : 100);
  my $half = $modulus / 2;
  my $base = _this_year() - $half;
  return $base + (($y - $base) % $modulus);
}
sub _this_year {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time());
  return $year + 1900;
}

# store to hashref $quotes all the $symbol_list symbols picked out of a
# HTTP::Response in $resp
sub resp_to_quotes {
  my ($fq, $resp, $quotes, $symbol_list) = @_;

  my %want_symbol;
  @want_symbol{@$symbol_list} = (); # hash slice
  my %seen_symbol;

  foreach my $symbol (@$symbol_list) {
    $quotes->{$symbol,'method'}  = 'mgex';
    $quotes->{$symbol,'source'}  = __PACKAGE__;
    $quotes->{$symbol,'success'} = 0;  # false if not in returned
  }

  if (! $resp->is_success) {
    _errormsg ($quotes, $symbol_list, $resp->status_line);
    return;
  }
  my $content = $resp->decoded_content (raise_error => 1);

  $content = _javascript_document_write ($content);
  ### $content
  $content =~ s/&nbsp;/ /g;

  my $page_date;
  if ($content =~ /for ([a-zA-Z]+ [0-9]{1,2}, [0-9]{4})/) {
    $page_date = $1;
    ### $page_date
  }

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => [ qr/Contract/i,
                  qr/Last/i,
                  qr/Change/i,
                  qr/Bid/,
                  qr/Ask/i,
                  qr/Open/i,
                  qr/High/,
                  qr/Low/i,
                  qr/Settle/i,
                  qr/Time/i ]);
  $te->parse ($content);
  if (! $te->tables) {
    _errormsg ($quotes, $symbol_list, 'table not matched');
    return;
  }

  foreach my $row ($te->rows) {
    ### $row
    if (! defined $row->[0]) {
      ### undef empty row, skip ...
      next;
    }

    my ($orig_name, $last, $change, $bid, $ask, $open, $high, $low,
        $prev, $last_time)
      = map { my $str = $_;
              $str =~ s/^\s+//;
              $str =~ s/\s+$//;
              $str } @$row;

    my ($name, $symbol, $commodity, $contract_month)
      = _name_to_NSCM ($orig_name);
    if (! defined $symbol) {
      ### unrecognised row: $orig_name
      next;
    }
    ### $name
    ### $symbol
    ### $commodity
    ### $contract_month
    if (! exists $want_symbol{$symbol}) {
      ### not wanted: $symbol
      next;
    }

    # "5 x 195-2" or whatever for count of bid/offers
    # seen in 2006, but maybe no longer generated
    my ($bid_count, $ask_count);
    if ($bid =~ s/([0-9]+) x //) { $bid_count = $1; }
    if ($ask =~ s/([0-9]+) x //) { $ask_count = $1; }

    # trailing "s" for settlement price
    $last =~ s/s$//i;

    # "unch" for no change
    if ($change =~ /unch/i) { $change = 0; }

    $bid = _dash_frac_to_decimals ($bid);
    $ask = _dash_frac_to_decimals ($ask);

    $open   = _dash_frac_to_decimals ($open);
    $high   = _dash_frac_to_decimals ($high);
    $low    = _dash_frac_to_decimals ($low);
    $last   = _dash_frac_to_decimals ($last);
    $prev   = _dash_frac_to_decimals ($prev);
    $change = _dash_frac_to_decimals ($change);

    my $date = $page_date;
    ### $last_time
    if ($last_time =~ m{^\d+/\d+/\d+$}) {
      ### "Time" field like "09/26/11" in wquote ...
      $date = $last_time;
      undef $last_time;
    }

    $quotes->{$symbol,'name'}     = $name;
    $quotes->{$symbol,'currency'} = 'USD';
    $quotes->{$symbol,'contract_month_iso'} = $contract_month;

    if (defined $date) {
      $fq->store_date($quotes, $symbol, {usdate => $date});
    }
    $quotes->{$symbol,'time'}     = $last_time;

    $quotes->{$symbol,'bid'}      = $bid;
    $quotes->{$symbol,'ask'}      = $ask;
    if (defined $bid_count) {
      $quotes->{$symbol,'bid_count'} = $bid_count;
    }
    if (defined $ask_count) {
      $quotes->{$symbol,'ask_count'} = $ask_count;
    }
    $quotes->{$symbol,'open'}     = $open;
    $quotes->{$symbol,'high'}     = $high;
    $quotes->{$symbol,'low'}      = $low;
    $quotes->{$symbol,'last'}     = $last;
    $quotes->{$symbol,'net'}      = $change;
    $quotes->{$symbol,'close'}    = $prev;
    $quotes->{$symbol,'success'}  = 1;

    $seen_symbol{$symbol} = 1;
  }

  # message in any not seen in page
  delete @want_symbol{keys %seen_symbol}; # hash slice
  _errormsg ($quotes, [keys %want_symbol], 'No such symbol');
}

sub _errormsg {
  my ($quotes, $symbol_list, $errormsg) = @_;
  foreach my $symbol (@$symbol_list) {
    $quotes->{$symbol,'errormsg'} = $errormsg;
  }
}

#------------------------------------------------------------------------------
# generic

# convert number like "99-1" with dash fraction to decimals like "99.125"
# single dash digit is 1/8s
# three dash digits -xxy is xx 1/32s and y is 0,2,5,7 for further 1/4, 2/4,
# or 3/4 of 1/32
#
my %qu_to_quarter = (''=>0, 0=>0, 2=>1, 5=>2, 7=>3);
sub _dash_frac_to_decimals {
  my ($str) = @_;

  $str =~ /^\+?(.+)-(.*)/ or return $str;
  my $int = $1;
  my $frac = $2;

  if (length ($frac) == 1) {
    # 99-1
    # only 2 decimals for 1/4s, since for various commodities that's the
    # minimum tick
    return $int + ($frac / 8);

  } elsif (length ($frac) == 2 || length ($frac) == 3) {
    # 109-30, in 1/32nds
    # 99-130, in 1/32s then last dig 0,2,5,7 further 1/4s of that
    my $th = substr $frac, 0, 2;
    if ($th > 31) {
      die "Barchart: dash thirtyseconds out of range: $str";
    }
    my $qu = substr($frac, 2, 1);
    if (! exists $qu_to_quarter{$qu}) {
      die "Barchart: dash thirtyseconds further quarters unrecognised: $str";
    }
    $qu = $qu_to_quarter{$qu};
    return $int + (($th + $qu / 4) / 32);

  } else {
    die "Barchart: unrecognised dash number: $str";
  }
}

#------------------------------------------------------------------------------
# javascript mangling

# $str contains javascript style calls 
#     document.write('foo')
# return a string of the output produced by those calls
# this only works for constant strings
# escaped quotes \' are turned into just ' in the return
#
sub _javascript_document_write {
  my ($str) = @_;
  my $ret = '';
  while ($str =~ /document\.write\('((\\.|[^\'])*)'\)/sg) {
    $ret .= _javascript_string_unquote($1);
  }
  return $ret;
}

# undo javascript string backslash quoting in STR, per
#
#     https://developer.mozilla.org/en/JavaScript/Guide/Values,_Variables,_and_Literals#String_Literals
#
# Encode::JavaScript::UCS does \u, but not the rest
#
# cf Java as such not quite the same:
#   unicode: http://java.sun.com/docs/books/jls/third_edition/html/lexical.html#100850
#   strings: http://java.sun.com/docs/books/jls/third_edition/html/lexical.html#101089
#
my %javascript_backslash = ('b' => "\b",   # backspace
                            'f' => "\f",   # formfeed
                            'n' => "\n",   # newline
                            'r' => "\r",
                            't' => "\t",   # tab
                            'v' => "\013", # vertical tab
                           );
sub _javascript_string_unquote {
  my ($str) = @_;
  $str =~ s{\\(?:
              ((?:[0-3]?[0-7])?[0-7]) # $1 \377 octal latin-1
            |x([0-9a-fA-F]{2})        # $2 \xFF hex latin-1
            |u([0-9a-fA-F]{4})        # $3 \uFFFF hex unicode
            |(.)                      # $4 \n etc escapes
            )
         }{
           (defined $1 ? chr(oct($1))
            : defined $4 ? ($javascript_backslash{$4} || $4)
            : chr(hex($2||$3)))   # \x,\u hex
         }egx;
  return $str;
}

1;
__END__

=for stopwords MGEX Ryde

=head1 NAME

Finance::Quote::MGEX - download Minneapolis Grain Exchange quotes

=for Finance_Quote_Grab symbols MWZ15

=head1 SYNOPSIS

 use Finance::Quote;
 my $fq = Finance::Quote->new ('MGEX');
 my %quotes = $fq->fetch('mgex', 'MWZ15');

=head1 DESCRIPTION

This module downloads commodity futures quotes from the Minneapolis Grain
Exchange (MGEX),

=over

L<http://www.mgex.com>

=back

Using the futures page

=over

L<http://www.mgex.com/data_charts.html>

=back

which is

=over

L<http://sites.barchart.com/pl/mgex/aquotes.htx>

L<http://sites.barchart.com/pl/mgex/wquotes_js.js>

=back

=head2 Symbols

The available symbols are for example

=for Finance_Quote_Grab symbols MWZ15 AJK15 KEZ15 ZWZ15 ICH15 IHH15 IPH15 ISH15 IWH15

    MWZ15      Minneapolis wheat
    AJK15      apple juice concentrate
    KEZ15      Kansas wheat
    ZWZ15      CBOT wheat

    ICH15      national corn index
    IHH15      hard red winter wheat index
    IPH15      hard red spring wheat index
    ISH15      national soybean index
    IWH15      soft red spring wheat index

The "Z15" etc is the contract month letter and the year "15" for 2015.  The
month letters are the usual U.S. futures style

    F    January
    G    February
    H    March
    J    April
    K    May
    M    June
    N    July
    Q    August
    U    September
    V    October
    X    November
    Z    December

=head2 Fields

The following standard C<Finance::Quote> fields are returned

=for Finance_Quote_Grab fields flowed standard

    name currency
    bid ask
    open high low last close net
    method source success errormsg

Plus the following extras

=for Finance_Quote_Grab fields table extra

    time                  ISO string "HH:MM"
    contract_month_iso    ISO format YYYY-MM-DD contract month

Prices on the web pages are in eighths but are always returned here as
decimals so they can be used arithmetically.  For instance "195-2" meaning
S<195 2/8> becomes "195.25".

=head1 SEE ALSO

L<Finance::Quote>, L<LWP>

MGEX web site L<http://www.mgex.com>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/finance-quote-grab/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2013, 2014, 2015 Kevin Ryde

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
L<http://www.gnu.org/licenses/>

=cut
