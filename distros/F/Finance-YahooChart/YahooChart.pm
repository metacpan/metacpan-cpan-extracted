# perl -w
#
#    Copyright (C) 1998, Dj Padzensky <djpadz@padz.net>
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

package Finance::YahooChart;
require 5.000;

require Exporter;
use strict;
use vars qw($VERSION @EXPORT @ISA $ICURL $CURL $ERROR %DEFAULTCHART);

$VERSION = '0.01';

# Intraday - b = intraday/big; t = intraday/small;
#	     w = week/big; v = week/small
# ex: $ICURL/b?s=aapl

$ICURL = "http://ichart.yahoo.com/";

# Normal charts - 0b = year/small; 3m = 3month/big; 1y = 1yr/big;
#		  2y = 2yr/big; 5y = 5yr/big;
#		  add s to chart against S&P500
#		  add m to include moving average
# ex: $CURL/0b/a/aapl.gif

$CURL = "http://chart.yahoo.com/c/";

%DEFAULTCHART = ( symbol => "aapl", type => "i", size => "b",
		  include => "" );
$ERROR = "";
@ISA = qw(Exporter);
@EXPORT = qw(&getchart);

sub getchart {
    my %param = @_;
    my %retval;
    $ERROR = "";
    foreach (keys %DEFAULTCHART) {
	$param{$_} = $DEFAULTCHART{$_} if ! defined $param{$_};
	$param{$_} = substr($param{$_},0,1) if $_ ne "symbol";
	$param{$_} = lc $param{$_};
    }
    $param{'size'} = "b" if $param{'size'} eq "l";
    if (!$param{'symbol'}) {
	$ERROR = "No symbol provided";
	return;
    }
    if ((!$param{'type'}) || ("iw1235" !~ /$param{'type'}/)) {
	$ERROR = "Invalid type: \"$param{'type'}\"";
	return;
    }
    if ((!$param{'size'}) || ("bs" !~ /$param{'size'}/)) {
	$ERROR = "Invalid size: \"$param{'size'}\"";
	return;
    }
    if ($param{'include'} && ("ms" !~ /$param{'include'}/)) {
	$ERROR = "Invalid include: \"$param{'include'}\"";
	return;
    }
    $retval{'url'} = $ICURL.($param{'size'} eq "b" ? "b":"t").
	"?s=$param{'symbol'}" if $param{'type'} eq "i";
    $retval{'url'} = $ICURL.($param{'size'} eq "b" ? "w":"v").
	"?s=$param{'symbol'}" if $param{'type'} eq "w";
    if ("1235" =~ $param{'type'}) {
	if ($param{'type'} eq "1") {
	    $retval{'url'} = $CURL.($param{'size'} eq "b" ? "1y":"0b");
	}
	elsif ($param{'size'} eq "s") {
	    $ERROR = "Size not available";
	    return;
	}
	else {
	    $retval{'url'} = $CURL.$param{'type'}.
		($param{'type'} eq "3" ? "m":"y");
	}
	$retval{'url'} .= $param{'include'} if $param{'size'} eq "b";
	$retval{'url'} .= "/".substr($param{'symbol'},0,1)."/".
	    $param{'symbol'}.".gif";
    }
    if ($retval{'url'}) {
	($retval{'width'},$retval{'height'}) =
	    $param{'size'} eq "b" ? (512,288):(192,96);
    }
    else {
	$ERROR = "Can't make that kind of chart";
	return;
    }
    return %retval;
}

__END__

1;

=head1 NAME

Finance::YahooChart - Get a chart from Yahoo! Finance

=head1 SYNOPSIS

  use Finance::YahooChart;
  %img = getchart(symbol => $symbol, size => $size, type => $type,
		  include => $include);
  print "<IMG SRC=$img{'url'} WIDTH=$img{'width'} HEIGHT=$img{'height'}>";

=head1 DESCRIPTION

This module gets charts from Yahoo! Finance.  The only function in the
module is the B<getchart> function, which takes the stock symbol, size
of the chart (I<b> for big, I<s> for small), the type of chart (I<i>
for intraday, I<w> for week, I<3> for 3-month, I<1> for 1-year, I<2>
for 2-year, and I<5> for 5-year), and any extra information to include
(I<s> for a comparison to the S&P 500, I<m> for a moving average).  It
returns a hash with the following elements:

  'url' => The URL of the chart
  'width' => The width of the chart
  'height' => The height of the chart

Note that not all combinations are available for all charts.

Big charts are available for all types.

Small charts are only available for I<i>, I<w>, and I<1> charts.

Includes are only available for big I<3>, I<1>, I<2>, and I<5> charts.

In most cases, if an invalid configuration is passed,
B<$Finance::YahooChart::Error> will be set to some kind of error message.

=head1 COPYRIGHT

Copyright 1998, Dj Padzensky

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

The information that you obtain with this library may be copyrighted
by Yahoo! Inc., and is governed by their usage license.  See
http://www.yahoo.com/docs/info/gen_disclaimer.html for more
information.

=head1 AUTHOR

Dj Padzensky (C<djpadz@padz.net>), PadzNet, Inc.

The Finance::YahooChart home page can be found at
http://www.padz.net/~djpadz/YahooChart/

=cut
