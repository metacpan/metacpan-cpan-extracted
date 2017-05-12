#!/usr/bin/perl -w

# tag: test for creating <read> elements

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

use Test::More tests => 11;

use Net::Jabber qw(Client);
use JOAP;

my $conn = new Net::Jabber::Client();

my $read = new Net::Jabber::Query('read');
$read->SetXMLNS($JOAP::NS);

ok($read, "Can create a read using Query constructor.");

$read = undef;

my $iq = new Net::Jabber::IQ();
$read = $iq->NewQuery($JOAP::NS, 'read');

ok($read, "Can create a read from an IQ.");

SKIP: {
    skip("can() doesn't work with Net::Jabber autoloading", 9);

    can_ok($read, 'GetName');
    can_ok($read, 'SetName');
    can_ok($read, 'DefinedName');

    can_ok($read, 'GetAttribute');
    can_ok($read, 'AddAttribute');
    can_ok($read, 'DefinedAttribute');

    can_ok($read, 'GetTimestamp');
    can_ok($read, 'SetTimestamp');
    can_ok($read, 'DefinedTimestamp');
}
