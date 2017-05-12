#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server Class subclass <describe> handling

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

use Test::More tests => 54;

use Net::Jabber qw(Client);
use JOAP;
use MyPerson;

$SRC = "User\@example.net/Client";
$DEST = "Person\@joap.example.com";

# describe

my $iq = new Net::Jabber::IQ;
my $ID = 'joap_describe_1';

$iq->SetTo($DEST);
$iq->SetFrom($SRC);
$iq->SetID($ID);
$iq->SetType('get');

my $desc = $iq->NewQuery($JOAP::NS, 'describe');

my $res = MyPerson->on_iq($iq);

ok($res, "Got a describe result.");

is($res->GetType, "result", "It's a result result.");
is($res->GetID, $ID, "ID came back correct.");
is($res->GetFrom, $DEST, "from is right.");
is($res->GetTo, $SRC, "to is right.");

my $qry = $res->GetQuery;

ok($qry, "Can get the query.");

ok($qry->DefinedDesc, "Has a description.");
ok(length($qry->GetDesc), "Description has non-zero length.");

ok($qry->DefinedTimestamp, "Has a timestamp.");
like($qry->GetTimestamp, qr/^(-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/, "It looks like a timestamp.");

ok($qry->DefinedAttributeDescription, "Has attribute descriptions.");

my @attrs = $qry->GetAttributeDescription;
my %attrs = map {($_->GetName, $_)} @attrs;

ok($attrs{'given_name'}, "Has the given name attribute.");
ok($attrs{'given_name'}->GetWritable, "given name correctly writable.");
ok($attrs{'given_name'}->GetRequired, "given name correctly required.");
is($attrs{'given_name'}->GetType, 'string', "Right type for given name.");
is($attrs{'given_name'}->GetAllocation, 'instance', "Right allocation for given name.");

ok($attrs{'family_name'}, "Has the family name attribute.");
ok($attrs{'family_name'}->GetWritable, "family name correctly writable.");
ok($attrs{'family_name'}->GetRequired, "family name correctly required.");
is($attrs{'family_name'}->GetType, 'string', "Right type for family name.");
is($attrs{'family_name'}->GetAllocation, 'instance', "Right allocation for family name.");

ok($attrs{'birthdate'}, "Has the birthdate attribute.");
ok($attrs{'birthdate'}->GetWritable, "birthdate correctly writable.");
ok($attrs{'birthdate'}->GetRequired, "birthdate correctly required.");
is($attrs{'birthdate'}->GetType, 'dateTime.iso8601', "Right type for birthdate.");
is($attrs{'birthdate'}->GetAllocation, 'instance', "Right allocation for birthdate.");

ok($attrs{'age'}, "Has the age attribute.");
ok(!$attrs{'age'}->GetWritable, "age correctly unwritable.");
ok(!$attrs{'age'}->GetRequired, "age correctly unrequired.");
is($attrs{'age'}->GetType, 'i4', "Right type for age.");
is($attrs{'age'}->GetAllocation, 'instance', "Right allocation for age.");

ok($attrs{'sign'}, "Has the sign attribute.");
ok(!$attrs{'sign'}->GetWritable, "sign correctly unwritable.");
ok(!$attrs{'sign'}->GetRequired, "sign correctly unrequired.");
is($attrs{'sign'}->GetType, 'string', "Right type for sign.");
is($attrs{'sign'}->GetAllocation, 'instance', "Right allocation for sign.");

ok($attrs{'species'}, "Has the species attribute.");
ok(!$attrs{'species'}->GetWritable, "species correctly unwritable.");
ok(!$attrs{'species'}->GetRequired, "species correctly unrequired.");
is($attrs{'species'}->GetType, 'string', "Right type for species.");
is($attrs{'species'}->GetAllocation, 'class', "Right allocation for species.");

ok($attrs{'population'}, "Has the population attribute.");
ok($attrs{'population'}->GetWritable, "population correctly unwritable.");
ok(!$attrs{'population'}->GetRequired, "population correctly unrequired.");
is($attrs{'population'}->GetType, 'i4', "Right type for population.");
is($attrs{'population'}->GetAllocation, 'class', "Right allocation for population.");

ok($qry->DefinedMethodDescription, "Has method descriptions");

my @meths = $qry->GetMethodDescription;
my %meths = map {($_->GetName, $_)} @meths;

ok ($meths{'walk'}, "Has the 'walk' method.");
is ($meths{'walk'}->GetReturnType, 'boolean', "The type is correct.");
ok ($meths{'walk'}->DefinedDesc, "Has a description.");
ok ($meths{'walk'}->DefinedParams, "Has params.");

my @params = $meths{'walk'}->GetParams->GetParams; # blech

my %params = map {($_->GetName, $_)} @params;

ok ($params{steps}, "Has the steps param.");
ok ($params{steps}->DefinedDesc, "Has a description.");
is ($params{steps}->GetType, 'i4', "Right type for steps param.");
