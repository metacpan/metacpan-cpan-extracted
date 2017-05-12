use warnings;
use strict;

use Test::More;
use Devel::Unwind;

my $x=0;
mark L {unwind L,$x=1};
ok($x == 0, "unwind L,expr - is the same as (unwind L),expr");
mark L { unwind L if 0; ok "Shouldn't unwind" } or do { fail "unwind L if 0 - shouldn't unwind" };
mark L { unwind L 1,2,3,4 if 1; fail "Shouldn't execute" };
like($@, qr/^1234\b/, "unwind L expr - unwinds to mark L with the value of the expression");
done_testing;
