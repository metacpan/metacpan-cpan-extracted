#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 4;

use_ok('Genealogy::Wills');

isa_ok(Genealogy::Wills->new(), 'Genealogy::Wills', 'Creating Genealogy::Wills object');
isa_ok(Genealogy::Wills->new()->new(), 'Genealogy::Wills', 'Cloning Genealogy::Wills object');
# ::new() with no args defaults class to __PACKAGE__ (documented LIMITATION;
# see LIMITATIONS POD). With args it misbehaves — use ->new() always.
isa_ok(Genealogy::Wills::new(), 'Genealogy::Wills', 'Function-call new() with no args falls back to package name');
