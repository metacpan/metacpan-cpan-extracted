#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 4;

use_ok('Genealogy::ObituaryDailyTimes');

isa_ok(Genealogy::ObituaryDailyTimes->new(), 'Genealogy::ObituaryDailyTimes', 'Creating Genealogy::ObituaryDailyTimes object');
isa_ok(Genealogy::ObituaryDailyTimes::new(), 'Genealogy::ObituaryDailyTimes', 'Creating Genealogy::ObituaryDailyTimes object');
isa_ok(Genealogy::ObituaryDailyTimes->new()->new(), 'Genealogy::ObituaryDailyTimes', 'Cloning Genealogy::ObituaryDailyTimes object');
