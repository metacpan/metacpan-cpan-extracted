#!/usr/bin/perl -w

# tag: test for creating <search> responses

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

use Test::More tests => 10;

use Net::Jabber qw(Client);
use JOAP;

my $ADDR1 = 'Vulcan@being.example.com/Spock';
my $ADDR2 = 'Human@being.example.com/JedSanders';

my $conn = new Net::Jabber::Client();

my $search = new Net::Jabber::Query('search');
$search->SetXMLNS($JOAP::NS);

ok (!$search->DefinedItem(), "no item defined yet.");
ok (!$search->GetItem(), "  so we can't get it.");

my $item;

$search->SetItem($ADDR1);

ok ($search->DefinedItem(), "item defined after set.");
ok ($search->GetItem(), "can get item after added");
is ($search->GetItem(), $ADDR1, "result of SetItem() same as Get()");

$search->SetItem($ADDR2);

ok ($search->DefinedItem(), "item defined after second set.");
ok ($search->GetItem(), "can get item after second set");

is ($search->GetItem(), $ADDR1, "GetItem() returns first value in scalar context");

my @items;

@items = $search->GetItem();

is (@items, 2, "Got both items back.");
is_deeply (\@items, [$ADDR1, $ADDR2], "Both items returned in array context");


