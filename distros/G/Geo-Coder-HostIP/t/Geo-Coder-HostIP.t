# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geo-Coder-HostIP.t'

#########################

use Test::More tests => 2;
BEGIN { use_ok('Geo::Coder::HostIP') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1);
