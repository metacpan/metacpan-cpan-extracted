# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GD-Cairo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;

use Test::More;
BEGIN { plan tests => 4 };
use GD::Cairo qw( :gd );
ok(1); # If we made it this far, we're ok.

ok(defined(gdBrushed));
ok(defined(gdGiantFont));

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(gdGiantFont->width,9,'gdGiantFont width');
