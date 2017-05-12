# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IBM-ThinkPad-ACPI-Extras.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
ok(1 == 1, "Never reached"); # dummy test
#BEGIN { use_ok('IBM::ThinkPad::ACPI::Extras') }; # fails if not a IBM ThinkPad

#########################

# TODO: Add some tests!
# The reason because I haven't implemented any test is,
# that's different for each model. So everyone who use
# this module should add (if desired) his individually
# test routines dependend of his thinkpad model.
