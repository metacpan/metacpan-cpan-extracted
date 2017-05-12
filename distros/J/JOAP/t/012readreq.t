#!/usr/bin/perl -w

# tag: test for creating <read> requests

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

my $iq = new Net::Jabber::IQ();
my $read = $iq->NewQuery($JOAP::NS, 'read');

ok(!$read->DefinedName(), "no name yet.");
ok(!$read->GetName(), "no name yet.");

$read->SetName('gar');

ok($read->DefinedName(), "Added a name");
is($read->GetName(), 'gar', "It added correctly.");

# not sure how to do this otherwise

$read->SetName('spock');

pass("add another name.");

my @names;

@names = $read->GetName();

is(@names, 2, "Have 2 names, like we said");
is_deeply(\@names, ['gar', 'spock'], "Get all names.");
