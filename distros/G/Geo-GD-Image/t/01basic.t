#!perl -w
use strict;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GD-WKB.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Geo::GD::Image') };

ok(GD::Image->newTrueColor(100,100));
ok(Geo::GD::Image->isa('GD::Image'));

my $i = Geo::GD::Image->newTrueColor(100,100);
ok($i);
ok($i->isa("GD::Image"));
ok($i->isa("Geo::GD::Image"));

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

