use strict;
use Test::More 0.88;

use Email::Address;

my @addrs = Email::Address->parse(q{a@example.com b@example.com});

is(@addrs, 2, "we parse comma-free lists, for some reason");

done_testing;
