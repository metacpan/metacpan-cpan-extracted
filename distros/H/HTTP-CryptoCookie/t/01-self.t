# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('HTTP::CryptoCookie') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $key = join '', map { chr(int(rand(256))) } (0..31);
my $cc = new HTTP::CryptoCookie($key);

isa_ok($cc,'HTTP::CryptoCookie');
can_ok($cc, 'get_cookie');
can_ok($cc, 'set_cookie');
can_ok($cc, 'del_cookie');

