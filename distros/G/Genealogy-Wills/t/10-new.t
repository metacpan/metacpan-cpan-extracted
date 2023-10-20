#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 4;

use_ok('Genealogy::Wills');

isa_ok(Genealogy::Wills->new(), 'Genealogy::Wills', 'Creating Genealogy::Wills object');
isa_ok(Genealogy::Wills->new()->new(), 'Genealogy::Wills', 'Cloning Genealogy::Wills object');
isa_ok(Genealogy::Wills::new(), 'Genealogy::Wills', 'Creating Genealogy::Wills object');
# ok(!defined(Genealogy::Wills::new()));
