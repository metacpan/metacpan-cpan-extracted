#!/usr/bin/perl -w

# tag: test for creating <delete> elements

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

use Test::More tests => 2;

use Net::Jabber qw(Client);
use JOAP;

my $conn = new Net::Jabber::Client();

my $delete = new Net::Jabber::Query('delete');
$delete->SetXMLNS($JOAP::NS);

ok($delete, "Can create a <delete> using Query constructor.");

$delete = undef;

my $iq = new Net::Jabber::IQ();
$delete = $iq->NewQuery($JOAP::NS, 'delete');

ok($delete, "Can create a <delete> from an IQ.");
