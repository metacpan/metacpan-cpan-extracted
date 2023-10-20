#!perl -wT

use warnings;
use strict;
use Test::Most tests => 4;

use_ok('Locale::Places');
isa_ok(Locale::Places->new(), 'Locale::Places', 'Creating Locale::Places object');
isa_ok(Locale::Places->new()->new(), 'Locale::Places', 'Cloning Locale::Places object');
isa_ok(Locale::Places::new(), 'Locale::Places', 'Creating Locale::Places object');
# ok(!defined(Locale::Places::new()));
