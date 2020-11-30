#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 2;
use Genealogy::ObituaryDailyTimes;

isa_ok(Genealogy::ObituaryDailyTimes->new(), 'Genealogy::ObituaryDailyTimes', 'Creating Genealogy::ObituaryDailyTimes object');
ok(!defined(Genealogy::ObituaryDailyTimes::new()));
