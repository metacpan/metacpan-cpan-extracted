# perl -w
#
#    Copyright (C) 2000, Dj Padzensky <djpadz@padz.net>
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

package Finance::HSHrates;
require 5.000;

require Exporter;
use strict;
use vars qw($VERSION @EXPORT @ISA $QURL);

use LWP::UserAgent;
use HTTP::Request::Common;

$VERSION = '0.01';
$QURL = ("http://www.hsh.com/today.html");
@ISA = qw(Exporter);
@EXPORT = qw(&getrates);

sub getrates {
    my ($ua,@q);
    $ua = LWP::UserAgent->new;
    $ua->env_proxy();
    foreach (split(/\015?\012/,$ua->request(GET $QURL)->content)) {
        push @q,$1 if /<B>\s*([0-9.]+%?)\s*<\/B>/;
    }
    return wantarray() ? @q : \@q;
}

1;

__END__

=head1 NAME

Finance::HSHrates - Get current US Mortgage Rates from HSH

=head1 SYNOPSIS

  use Finance::HSHrates;
  @rates = getrates;

=head1 DESCRIPTION

This module gets the current US Mortgage rages from HSH.  The B<getrates>
function will return an array with the following elements:

    0 30 Year Fixed - Rate
    1 30 Year Fixed - Points
    2 15 Year Fixed - Rate
    3 15 Year Fixed - Points
    4 1 Year Adjustable - Rate
    5 1 Year Adjustable - Points

=head1 COPYRIGHT

Copyright 2000, Dj Padzensky

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

The information that you obtain with this library may be copyrighted
by HSH Associates, Financial Publishers, and is governed by their
usage license.

=head1 AUTHOR

Dj Padzensky (C<djpadz@padz.net>), PadzNet, Inc.

The Finance::HSHrates home page can be found at
http://www.padz.net/~djpadz/HSHrates/

=cut
