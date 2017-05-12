# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl LWP-Authen-OAuth.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('LWP::Authen::OAuth') };

#########################

my $ua = LWP::Authen::OAuth->new(oauth_consumer_secret => "anonymous");
ok($ua);

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

