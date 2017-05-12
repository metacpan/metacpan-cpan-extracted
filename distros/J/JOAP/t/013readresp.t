#!/usr/bin/perl -w

# tag: test for creating <read> responses

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

use Test::More tests => 22;

use Net::Jabber qw(Client);
use JOAP;

my $conn = new Net::Jabber::Client();

my $iq = new Net::Jabber::IQ();
my $read = $iq->NewQuery($JOAP::NS, 'read');

ok(defined $read, "get the read thing");

ok (!$read->DefinedAttribute(), "no attribute defined yet.");
ok (!$read->GetAttribute(), "  so we can't get it.");

my $attr;

ok ($attr = $read->AddAttribute(), "can add an attribute with no args");
ok ($read->DefinedAttribute(), "attribute defined after added.");
ok ($read->GetAttribute(), "can get attribute after added");
is ($attr, $read->GetAttribute(), "result of AddAttribute() same as Get()");

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

$read = undef;
$iq = undef;

$iq = new Net::Jabber::IQ();
$read = $iq->NewQuery($JOAP::NS, 'read');

ok ($attr = $read->AddAttribute(name => 'spock'), "can add an attribute with name arg");
ok ($read->DefinedAttribute(), "attribute defined after added.");
ok ($read->GetAttribute(), "can get attribute after added");
is ($read->GetAttribute(), $attr, "It's what we added.");
is ($read->GetAttribute()->GetName(), 'spock', "attribute name is correct");
