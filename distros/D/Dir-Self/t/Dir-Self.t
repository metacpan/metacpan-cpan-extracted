#!perl -w
use strict;

use Test::More tests => 3;

use Dir::Self;
ok 1, 'use Dir::Self';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

like __DIR__, '/\bt$/';

use lib __DIR__;
require "zerlegungsgleichheit/d.t";
like zd(), '/\bzerlegungsgleichheit$/';
