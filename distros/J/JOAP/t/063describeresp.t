#!/usr/bin/perl -w

# tag: test for creating <describe> responses

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

use Test::More tests => 85;

use Net::Jabber qw(Client);
use JOAP;

$DESC = 'Sample object';

$ATTRNAME = 'spock';
$ATTRTYPE = 'i4';
$ATTRDESC = 'number of spocks';

$METHNAME = 'gar';
$METHRETURNTYPE = 'string';
$METHDESC = 'Make it say \"gar\"';
$METHPARAM = 'howMany';
$METHPARAMTYPE = 'i4';
$METHPARAMDESC = 'How many times to say gar.';

my $conn = new Net::Jabber::Client();

my $describe = new Net::Jabber::Query('describe');
$describe->SetXMLNS($JOAP::NS);

ok(defined $describe, "get the describe thing");

ok (!$describe->DefinedDesc, "no description defined yet.");
ok (!$describe->GetDesc, "  so we can't get it.");

$describe->SetDesc($DESC);

ok ($describe->DefinedDesc, "description defined after added.");
ok ($describe->GetDesc, "can get description after added");
is ($describe->GetDesc, $DESC, "description is what we set");

ok (!$describe->DefinedAttributeDescription(), "no attribute defined yet.");
ok (!$describe->GetAttributeDescription(), "  so we can't get it.");

my $attrdesc;

ok ($attrdesc = $describe->AddAttributeDescription(), "can add an attribute with no args");
ok ($describe->DefinedAttributeDescription(), "attribute defined after added.");
ok ($describe->GetAttributeDescription(), "can get attribute after added");
is ($attrdesc, $describe->GetAttributeDescription(), "result of AddAttributeDescription() same as Get()");

ok (!$attrdesc->DefinedName(), "no name defined yet.");
ok (!$attrdesc->GetName(), "...so we can't get it.");

$attrdesc->SetName($ATTRNAME);

ok ($attrdesc->DefinedName(), "added name; defined now.");
is ($attrdesc->GetName(), $ATTRNAME, "name is what we set");

ok (!$attrdesc->DefinedType(), "no type defined yet.");
ok (!$attrdesc->GetType(), "...so we can't get it.");

$attrdesc->SetType($ATTRTYPE);

ok ($attrdesc->DefinedType(), "added type; defined now.");
ok ($attrdesc->GetType(), "Can get a type");
is ($attrdesc->GetType(), $ATTRTYPE, "Type is what we set");

ok (!$attrdesc->DefinedDesc(), "no desc defined yet.");
ok (!$attrdesc->GetDesc(), "...so we can't get it.");

$attrdesc->SetDesc($ATTRDESC);

ok ($attrdesc->DefinedDesc(), "added desc; defined now.");
ok ($attrdesc->GetDesc(), "Can get a desc");
is ($attrdesc->GetDesc(), $ATTRDESC, "Desc is what we set");

ok (!$describe->DefinedMethodDescription(), "no method defined yet.");
ok (!$describe->GetMethodDescription(), "  so we can't get it.");

my $methdesc;

ok ($methdesc = $describe->AddMethodDescription(), "can add an method with no args");
ok ($describe->DefinedMethodDescription(), "method defined after added.");
ok ($describe->GetMethodDescription(), "can get method after added");
is ($methdesc, $describe->GetMethodDescription(), "result of AddMethodDescription() same as Get()");

ok (!$methdesc->DefinedName(), "no name defined yet.");
ok (!$methdesc->GetName(), "...so we can't get it.");

$methdesc->SetName($METHNAME);

ok ($methdesc->DefinedName(), "added name; defined now.");
is ($methdesc->GetName(), $METHNAME, "name is what we set");

ok (!$methdesc->DefinedReturnType(), "no returnType defined yet.");
ok (!$methdesc->GetReturnType(), "...so we can't get it.");

$methdesc->SetReturnType($METHRETURNTYPE);

ok ($methdesc->DefinedReturnType(), "added returnType; defined now.");
ok ($methdesc->GetReturnType(), "Can get a returnType");
is ($methdesc->GetReturnType(), $METHRETURNTYPE, "ReturnType is what we set");

ok (!$methdesc->DefinedDesc(), "no desc defined yet.");
ok (!$methdesc->GetDesc(), "...so we can't get it.");

$methdesc->SetDesc($METHDESC);

ok ($methdesc->DefinedDesc(), "added desc; defined now.");
ok ($methdesc->GetDesc(), "Can get a desc");
is ($methdesc->GetDesc(), $METHDESC, "Desc is what we set");

ok (!$methdesc->DefinedParams, "No params defined yet");
ok (!$methdesc->GetParams, "...so we can't get them.");

my $p = $methdesc->AddParams();

ok ($methdesc->DefinedParams, "added params block; defined now.");
ok ($methdesc->GetParams, "Can get a params block");

ok (!$p->DefinedParams, "No params in params block.");
ok (!$p->GetParams, "No params in params block.");

my $pa = $p->AddParam();

ok ($pa, "Can add a param to params block.");
ok ($p->DefinedParams, "Params in params block.");
ok ($p->GetParams, "Params in params block.");

ok (!$pa->DefinedName, "No name defined yet.");
ok (!$pa->GetName, "No name defined yet.");

$pa->SetName($METHPARAM);

ok ($pa->DefinedName, "Name now defined.");
is ($pa->GetName, $METHPARAM, "Name is what we set.");

ok (!$pa->DefinedType, "No type defined yet.");
ok (!$pa->GetType, "No type defined yet.");

$pa->SetType($METHPARAMTYPE);

ok ($pa->DefinedType, "Type now defined.");
is ($pa->GetType, $METHPARAMTYPE, "Type is what we set.");

ok (!$pa->DefinedDesc, "No desc defined yet.");
ok (!$pa->GetDesc, "No desc defined yet.");

$pa->SetDesc($METHPARAMDESC);

ok ($pa->DefinedDesc, "Desc now defined.");
is ($pa->GetDesc, $METHPARAMDESC, "Desc is what we set.");

$describe = new Net::Jabber::Query('describe');
$describe->SetXMLNS($JOAP::NS);

$attrdesc = $describe->AddAttributeDescription(name => $ATTRNAME,
                                               type => $ATTRTYPE,
                                               desc => $ATTRDESC);

ok ($attrdesc, "can add an attribute with name arg");
ok ($describe->DefinedAttributeDescription(), "attribute defined after added.");
ok ($describe->GetAttributeDescription(), "can get attribute after added");
is ($describe->GetAttributeDescription(), $attrdesc, "It's the same as what was added.");
is ($attrdesc->GetName(), $ATTRNAME, "attribute name is correct");
is ($attrdesc->GetType(), $ATTRTYPE, "attribute type is correct");
is ($attrdesc->GetDesc(), $ATTRDESC, "attribute desc is correct");

$methdesc = $describe->AddMethodDescription(name => $METHNAME,
                                            returnType => $METHRETURNTYPE,
                                            desc => $METHDESC);

ok ($methdesc, "can add an method with name arg");
ok ($describe->DefinedMethodDescription(), "method defined after added.");
ok ($describe->GetMethodDescription(), "can get method after added");
is ($describe->GetMethodDescription(), $methdesc, "It's the same as what was added.");
is ($methdesc->GetName(), $METHNAME, "method name is correct");
is ($methdesc->GetReturnType(), $METHRETURNTYPE, "method type is correct");
is ($methdesc->GetDesc(), $METHDESC, "method desc is correct");

$methdesc->AddParams->AddParam(name => $METHPARAM,
                               type => $METHPARAMTYPE,
                               desc => $METHPARAMDESC);

ok ($methdesc->GetParams->DefinedParams, "Can add params with name arg.");

my @p = $methdesc->GetParams->GetParams;

is ($p[0]->GetName, $METHPARAM, "name arg is correct.");
is ($p[0]->GetType, $METHPARAMTYPE, "type arg is correct.");
is ($p[0]->GetDesc, $METHPARAMDESC, "type arg is correct.");
