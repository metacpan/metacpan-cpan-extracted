#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 4;

use_ok('Genealogy::Obituary::Lookup');

if($ENV{'NO_NETWORK_TESTING'}) {
	Database::Abstraction::init({ directory => '/tmp' });
}

isa_ok(Genealogy::Obituary::Lookup->new(), 'Genealogy::Obituary::Lookup', 'Creating Genealogy::Obituary::Lookup object');
isa_ok(Genealogy::Obituary::Lookup::new(), 'Genealogy::Obituary::Lookup', 'Creating Genealogy::Obituary::Lookup object');
isa_ok(Genealogy::Obituary::Lookup->new()->new(), 'Genealogy::Obituary::Lookup', 'Cloning Genealogy::Obituary::Lookup object');
