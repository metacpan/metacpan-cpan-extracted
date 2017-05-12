#!/usr/bin/perl -w

# tag: test for creating <search> requests

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

use Test::More tests => 20;

use Net::Jabber qw(Client);
use JOAP;

my $conn = new Net::Jabber::Client();

my $search = new Net::Jabber::Query('search');
$search->SetXMLNS($JOAP::NS);

ok (!$search->DefinedAttribute(), "no attribute defined yet.");
ok (!$search->GetAttribute(), "  so we can't get it.");

my $attr;

ok ($attr = $search->AddAttribute(), "can add an attribute with no args");
ok ($search->DefinedAttribute(), "attribute defined after added.");
ok ($search->GetAttribute(), "can get attribute after added");
is ($attr, $search->GetAttribute(), "result of AddAttribute() same as Get()");

ok (!$attr->DefinedName(), "no name defined yet.");
ok (!$attr->GetName(), "...so we can't get it.");

$attr->SetName('gar');

ok ($attr->DefinedName(), "added name; defined now.");
is ($attr->GetName(), 'gar', "name is what we set");

ok (!$attr->DefinedValue(), "no name defined yet.");
ok (!$attr->GetValue(), "...so we can't get it.");

ok ($attr->AddValue(i4 => 10), "can add value");

ok ($attr->DefinedValue(), "added value; defined now.");
ok ($attr->GetValue(), "Can get a value");
is ($attr->GetValue()->GetI4(), 10, "Value is what we set");

$search = undef;

$search = new Net::Jabber::Query('search');
$search->SetXMLNS($JOAP::NS);

ok ($attr = $search->AddAttribute(name => 'spock'), "can add an attribute with name arg");
ok ($search->DefinedAttribute(), "attribute defined after added.");
ok ($search->GetAttribute(), "can get attribute after added");
is ($search->GetAttribute()->GetName(), 'spock', "attribute name is correct");

# TODO: Add value with init args
