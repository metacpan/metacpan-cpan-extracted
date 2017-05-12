# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More tests => 2;

use_ok('Event::IO::Server');
use_ok('Event::IO::Record');

