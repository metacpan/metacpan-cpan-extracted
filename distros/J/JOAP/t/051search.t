#!/usr/bin/perl -w

# tag: test for creating <search> elements

# Copyright (c) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

use Test::More tests => 8;

use Net::Jabber qw(Client);
use JOAP;

my $conn = new Net::Jabber::Client();

my $search = new Net::Jabber::Query('search');
$search->SetXMLNS($JOAP::NS);

ok($search, "Can create a <search> using Query constructor.");

$search = undef;

my $iq = new Net::Jabber::IQ();
$search = $iq->NewQuery($JOAP::NS, 'search');

ok($search, "Can create a <search> from an IQ.");

SKIP: {
    skip("can() doesn't work with Net::Jabber autoloading", 6);

    can_ok($search, 'GetAttribute');
    can_ok($search, 'AddAttribute');
    can_ok($search, 'DefinedAttribute');

    can_ok($search, 'GetItem');
    can_ok($search, 'SetItem');
    can_ok($search, 'DefinedItem');
}
