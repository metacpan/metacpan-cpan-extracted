#!/usr/bin/perl -w

# tag: test for creating <describe> elements

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

use Test::More tests => 17;

use Net::Jabber qw(Client);
use JOAP;

my $conn = new Net::Jabber::Client();

my $describe = new Net::Jabber::Query('describe');
$describe->SetXMLNS($JOAP::NS);

ok($describe, "Can create a <describe> using Query constructor.");

$describe = undef;

my $iq = new Net::Jabber::IQ();
$describe = $iq->NewQuery($JOAP::NS, 'describe');

ok($describe, "Can create a <describe> from an IQ.");

SKIP: {
    skip("can() doesn't work with Net::Jabber autoloading", 15);

    can_ok($describe, 'GetAttributeDescription');
    can_ok($describe, 'AddAttributeDescription');
    can_ok($describe, 'DefinedAttributeDescription');

    can_ok($describe, 'GetMethodDescription');
    can_ok($describe, 'AddMethodDescription');
    can_ok($describe, 'DefinedMethodDescription');

    can_ok($describe, 'GetTimestamp');
    can_ok($describe, 'SetTimestamp');
    can_ok($describe, 'DefinedTimestamp');

    can_ok($describe, 'GetClass');
    can_ok($describe, 'SetClass');
    can_ok($describe, 'DefinedClass');

    can_ok($describe, 'GetSuperclass');
    can_ok($describe, 'SetSuperclass');
    can_ok($describe, 'DefinedSuperclass');
}
