#!perl -wT

use strict;

use Test::Most tests => 2;

use Locale::AU;

isa_ok(Locale::AU->new(), 'Locale::AU', 'Creating Locale::AU object');
isa_ok(Locale::AU::new(), 'Locale::AU', 'Creating Locale::AU object');
