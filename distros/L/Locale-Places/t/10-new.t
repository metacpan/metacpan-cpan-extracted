#!perl -wT

use warnings;
use strict;
use Test::Most tests => 2;
use Locale::Places;

isa_ok(Locale::Places->new(), 'Locale::Places', 'Creating Locale::Places object');
isa_ok(Locale::Places::new(), 'Locale::Places', 'Creating Locale::Places object');
# ok(!defined(Locale::Places::new()));
