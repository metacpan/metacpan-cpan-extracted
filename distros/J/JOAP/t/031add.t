#!/usr/bin/perl -w

# tag: test for creating <add> elements

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

use Test::More tests => 7;

use Net::Jabber qw(Client);
use JOAP;

my $conn = new Net::Jabber::Client();

my $add = new Net::Jabber::Query('add');
$add->SetXMLNS($JOAP::NS);

ok ($add, "Can create an <add> element.");

SKIP: {
    skip("can() doesn't work with Net::Jabber autoloading", 6);

    can_ok($add, 'GetAttribute');
    can_ok($add, 'AddAttribute');
    can_ok($add, 'DefinedAttribute');

    can_ok($add, 'GetNewAddress');
    can_ok($add, 'SetNewAddress');
    can_ok($add, 'DefinedNewAddress');
}
