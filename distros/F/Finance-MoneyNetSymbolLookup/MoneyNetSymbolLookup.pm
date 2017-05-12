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

package Finance::MoneyNetSymbolLookup;
require 5.000;

require Exporter;
use strict;
use vars qw($VERSION @EXPORT @ISA $URL);

use LWP::UserAgent;
use HTTP::Request::Common;

$VERSION = '0.02';
$URL = ("http://www.moneynet.com/data/EQUIS/rawlookup/lookup.asp?NAME=");
@ISA = qw(Exporter);
@EXPORT = qw(&symbollookup);

sub symbollookup {
    my $search = $_[0];
    my($srch,$ua,$url,$sym,$name,$type,@qr);
    $url = $URL.$search;
    foreach (split('\r?\n',LWP::UserAgent->new->request(GET $url)->content)) {
	if (/^Symbol:(.*)/) {
	    ($sym,$name,$type) = split(',',$1);
	    push(@qr,[$sym,$name,$type]) if $type ne "TYPE";
	}
    }
    return wantarray() ? @qr : \@qr;
}

__END__

1;

=head1 NAME

Finance::MoneyNetSymbolLookup - Look up a stock symbol from MoneyNet

=head1 SYNOPSIS

  use Finance::MoneyNetSymbolLookup;
  @symbols = symbollookup $searchstring; # Look up stock symbols

=head1 DESCRIPTION

This module looks up stock symbols from MoneyNet.  The B<symbollookup>
function will return an array of lists, each containing the following
items:

    0 Symbol
    1 Company name
    2 Security type (typically B<STOCK> or B<MUTUAL FUND>)

=head1 EXAMPLE

    use Finance::MoneyNetSymbolLookup;
    @foo = symbollookup("apple");
    foreach (@foo) {
      print "Symbol: ${$_}[0]; Company: ${$_}[1]; Type: ${$_}[2]\n";
    }

=head1 COPYRIGHT

Copyright 1998, Dj Padzensky

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

The information that you obtain with this library may be copyrighted
by Reuters, Inc., and is governed by their usage license.  See
http://www.moneynet.com/home/MONEYNET/info/moneynetcopyright.asp for more
information.

=head1 AUTHOR

Dj Padzensky (C<djpadz@padz.net>), PadzNet, Inc.

The Finance::MoneyNetSymbolLookup home page can be found at
http://www.padz.net/~djpadz/MoneyNetSymbolLookup/

=cut
