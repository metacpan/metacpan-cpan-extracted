# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BitStamp-Socket.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Finance::BitStamp::Socket') };

#########################

diag q{
You should just test from the command line with:

 $ perl -e 'use lib qw(lib); use base qw(Finance::BitStamp::Socket); main->new->go'

You should see text socket broadcasts from BitStamp dump to the screen

};

