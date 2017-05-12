#!/usr/bin/perl -w -I../blib/lib -I../blib/arch
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Goo-Canvas.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Goo::Canvas') };
use lib qw(../blib/lib ../blib/arch);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok('Goo::Canvas', qw(get_items_at get_items_in_area));
