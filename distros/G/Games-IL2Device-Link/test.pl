# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test;

BEGIN { plan tests => 7 };

use Games::IL2Device::Link;
ok(1); # If we made it this far, we're ok.

#########################
# test what we can

$ic = Games::IL2Device::Link->new;
ok(defined($ic) and ref eq 'IL2Device', 1);
ok($ic->addr("127.0.0.1"), "127.0.0.1");
ok($ic->port(7), 7);
ok($ic->il2connect, 0|1); # accept any for now
ok($ic->addr, "127.0.0.1");
ok($ic->port, 7);

