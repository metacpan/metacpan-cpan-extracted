# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gftracks.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
use Gftracks qw /sec tidytime/;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(0,sec('00:00:00'));
is(60,sec('00:01:00'));
is(3600,sec('01:00:00'));
is(3660,sec('01:01:00'));
is(3661,sec('01:01:01'));

is(tidytime('23'),'0:23:00.000');
is(tidytime('23 34'),'0:23:34.000');
is('0:23:34.000',tidytime('23 34.'));
is('0:23:34.000',tidytime('23 34.0'));
is('1:23:34.000',tidytime('1 23 34'));
is('1:23:34.000',tidytime('1 23 34.'));
is('1:23:34.600',tidytime('1 23 34.6'));