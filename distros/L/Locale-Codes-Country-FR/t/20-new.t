#!perl -w

use strict;

# use lib 'lib';
use Test::Most tests => 4;

BEGIN {
	use_ok('Locale::Codes::Country::FR')
}

isa_ok(Locale::Codes::Country::FR->new(), 'Locale::Codes::Country::FR', 'Creating Locale::Codes::Country::FR object');
isa_ok(Locale::Codes::Country::FR::new(), 'Locale::Codes::Country::FR', 'Creating Locale::Codes::Country::FR object');
isa_ok(Locale::Codes::Country::FR->new()->new(), 'Locale::Codes::Country::FR', 'Cloning Locale::Codes::Country::FR object');
# ok(!defined(Locale::Codes::Country::FR::new()));
