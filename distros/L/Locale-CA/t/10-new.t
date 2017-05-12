#!perl -wT

use strict;

use Test::Most tests => 2;

use Locale::CA;

isa_ok(Locale::CA->new(), 'Locale::CA', 'Creating Locale::CA object');
ok(!defined(Locale::CA::new()));
