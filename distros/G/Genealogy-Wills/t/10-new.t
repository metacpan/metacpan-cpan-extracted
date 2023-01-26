#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 2;
use Genealogy::Wills;

isa_ok(Genealogy::Wills->new(), 'Genealogy::Wills', 'Creating Genealogy::Wills object');
ok(!defined(Genealogy::Wills::new()));
