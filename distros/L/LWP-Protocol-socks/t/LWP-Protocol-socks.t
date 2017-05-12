# -*- mode: perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl LWP-Protocol-socks.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use_ok(qw(LWP::Protocol::socks));
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Tests for https://rt.cpan.org/Ticket/Display.html?id=48172
my $u = new URI('socks://user%3auser:pass%3apass@foobar.com/path/query=1');
ok($u);
is(ref($u), 'URI::socks', 'isa URI::socks');
is($u->scheme(), 'socks', 'scheme eq socks');
is($u->user(), 'user:user', 'user eq "user:user"');
is($u->pass(), 'pass:pass', 'pass eq "pass:pass"');
