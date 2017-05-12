#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;
use Geo::StreetAddress::FR;

my $address = Geo::StreetAddress::FR->new;
ok ($address, "Geo::StreetAddress::FR object created");
ok (!$address->parse, "Call parse");
is ($address->message, "You have to set an adress : \$mystreetobject->adresse(\"name of my adress\")");