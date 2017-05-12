# die's should be errormsg returns
# give back all months?
# stock quotes too?
# fallback for mgex and others, with symbol munging


# Copyright 2008, 2009, 2010, 2011, 2014, 2015 Kevin Ryde

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

package Finance::Quote::Barchart;
use 5.005;
use strict;
use Carp;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 14;

# The intraday commodity quotes pages are used, like oats
#
#     http://www2.barchart.com/ifutpage.asp?code=BSTK&sym=O
#
# which is about 35 kbytes each.  An alternative would be the combined
# pages like all grains
#
#     http://www2.barchart.com/mktcom.asp?code=BSTK&section=grains
#
# which has the front month or two of various at about 50kbytes the lot.

use constant BARCHART_EXCHANGE_BASE_URL =>
  'http://www2.barchart.com/ifutpage.asp?code=BSTK&sym=';

sub methods {
  return (barchart => \&barchart_quotes);
}
sub labels {
  return (barchart => [ qw(date isodate name
                           open high low last net
                           method source success errormsg

                           copyright_url) ]);
}

sub barchart_quotes {
  my ($fq, @symbol_list) = @_;
  my $ua = $fq->user_agent;
  my %quotes;

  foreach my $symbol (@symbol_list) {
    my $commodity = $symbol;
    $commodity =~ s/[A-Z][0-9][0-9]$//;
    my $url = BARCHART_EXCHANGE_BASE_URL . URI::Escape::uri_escape($commodity);

    require HTTP::Request;
    my $req = HTTP::Request->new ('GET', $url);
    $ua->prepare_request ($req);
    $req->accept_decodable; # we know decoded_content() below
    $req->user_agent (__PACKAGE__."/$VERSION " . $req->user_agent);
    ### req: $req->as_string

    my $resp = $ua->request ($req);
    resp_to_quotes ($fq, $symbol, $resp, \%quotes);
  }
  return wantarray() ? %quotes : \%quotes;
}

sub resp_to_quotes {
  my ($fq, $target_symbol, $resp, $quotes) = @_;

  my $content = $resp->decoded_content (raise_error => 1);

  # eg. "   <B>CRUDE OIL</B> Delayed Futures -20:10 - Sunday, 19 June"
  #     "   <B>SIMEX NIKKEI 225</B> Delayed Futures -18:20 - Tuesday, 12 December</td>"
  #     "   <B>OATS   </B> Daily Futures -     Friday, 20 April                 </td>
  $content =~ m{([^<>\r\n]+) *</B> Delayed Futures *- *([0-9]+:[0-9]+) *- *[A-Za-z]+, ([0-9]+ [A-Za-z]+)}is
    or die 'Barchart: ifutpage name/date/time not matched';
  my $name = $1;
  my $head_time = $2;
  my $head_date = $3;
  ### head
  ### $name
  ### $head_time
  ### $head_date

  require Suffix::NZ;
  $head_date = Suffix::NZ::dm_str_to_nearest_iso ($head_date);

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => ['Contract', 'Last', 'Change', 'Open', 'High', 'Low', 'Time']);
  $te->parse($content);
  if (! $te->tables) { die 'Barchart: ifutpage price columns not matched'; }

  my $saw_target = 0;
  foreach my $row ($te->rows) {
    ### $row
    my ($month, $last, $change, $open, $high, $low, $time) = @$row;

    # eg. "August '05 ( CLQ05 )"
    $month =~ /(.*)\( *([^ )]+) *\)/p
      or die 'Barchart: ifutpage month form not recognised';
    my $month_name = $1; # "August '05"
    my $symbol     = $2; # "CLQ05"

    if (defined $target_symbol && $symbol ne $target_symbol) { next; }

    $month_name =~ s/ +$//; # trailing spaces

    # trailing "s" on last for settlement price
    # have also seen "c", maybe for close
    $last =~ s/[cs]$//i;

    if ($time =~ /:/) {
      # time is HH:MM on same day as the quote
      $fq->store_date($quotes, $symbol, {usdate => $head_date});
      $quotes->{$symbol,'time'} = $time;
    } else {
      # time is a date MM/DD/YY later (on the weekend)
      $fq->store_date($quotes, $symbol, {usdate => $time});
    }

    # dash is frac in various CBOT
    if ($last =~ /-/) {
      $open   = dash_frac_to_decimals ($open);
      $high   = dash_frac_to_decimals ($high);
      $low    = dash_frac_to_decimals ($low);
      $last   = dash_frac_to_decimals ($last);
      $change = dash_frac_to_decimals ($change);
    }

    $quotes->{$symbol,'method'}  = 'barchart';
    $quotes->{$symbol,'source'}  = __PACKAGE__;
    $quotes->{$symbol,'success'} = 1;
    $quotes->{$symbol,'name'}   = "$name $month_name";
    $quotes->{$symbol,'open'}   = $open;
    $quotes->{$symbol,'high'}   = $high;
    $quotes->{$symbol,'low'}    = $low;
    $quotes->{$symbol,'last'}   = $last;
    $quotes->{$symbol,'net'}    = $change;
  }

  if (! $saw_target) {
    $quotes->{$target_symbol,'method'}   = 'barchart';
    $quotes->{$target_symbol,'source'}   = __PACKAGE__;
    $quotes->{$target_symbol,'errormsg'} = 'Unknown symbol';
    $quotes->{$target_symbol,'success'}  = 0;
  }
}

# convert number like "99-1" with dash fraction to decimals like "99.125"
# single dash digit is 1/8s
# three dash digits -xxy is xx 1/32s and y is 0,2,5,7 for further 1/4, 2/4,
# or 3/4 of 1/32
#
my %qu_to_quarter = (''=>0, 0=>0, 2=>1, 5=>2, 7=>3);
sub dash_frac_to_decimals {
  my ($str) = @_;

  $str =~ /^\+?(.+)-(.*)/p or return $str;
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

1;
__END__

=head1 NAME

Finance::Quote::Barchart - download futures quotes from Barchart

=head1 SYNOPSIS

 use Finance::Quote;
 my $fq = Finance::Quote->new ('Barchart');
 my %quotes = $fq->fetch('barchart', 'CLZ11');

=head1 DESCRIPTION

This module downloads  futures quotes from Barchart,

=over 4

L<http://www.barchart.com>

=back

Using the intraday futures pages like NYMEX crude oil for December 2009,

=over 4

L<http://www2.barchart.com/ifutpage.asp?code=BSTK&sym=CLZ11>

=back

=head2 Fields

The following standard C<Finance::Quote> fields are available

    date isodate name currency
    bid ask
    open high low last net
    method source success errormsg

Plus the following extras

    month         ISO format YYYY-MM-DD contract month

Prices from some exchanges appear on the web pages in eighths, but they're
always returned here as decimal amounts, so for instance CBOT oats "99-1"
becomes "99.125".

=head1 SEE ALSO

L<Finance::Quote>, L<LWP>

Barchart web site L<http://www.barchart.com>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/finance-quote-grab/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2014, 2015 Kevin Ryde

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
