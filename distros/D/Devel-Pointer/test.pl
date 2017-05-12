# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use Devel::Pointer;
ok(1); # If we made it this far, we're ok.

#########################

$a = 10;
$a_addr = sprintf("0x%x", address_of($a));
ok(\$a =~ /$a_addr/);

$a_addr = hex($a_addr);
ok(deref($a_addr) == 10);

$x = \$a;
$x += 0; # Two statements to avoid (disastrous) constant folding!
ok($x == \unsmash_sv($x));
$b = unsmash_sv($x);
ok($b == 10);
