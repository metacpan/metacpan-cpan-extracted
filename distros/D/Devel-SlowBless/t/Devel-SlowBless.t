# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Devel-SlowBless.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Carp;
use Test::More tests => 4;
BEGIN { use_ok('Devel::SlowBless') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# just a basic test of sub_gen

my $start = Devel::SlowBless::sub_gen;

eval 'sub UNIVERSAL::foo { 42 }';

my $next = Devel::SlowBless::sub_gen;

cmp_ok($next, '>', $start);

*foo = [];

is(Devel::SlowBless::sub_gen, $next);

$start = Devel::SlowBless::amg_gen;

eval 'use overload q("") => sub { 1 }';

$next = Devel::SlowBless::amg_gen;
if ($] < 5.017001) {
  cmp_ok($next, '>', $start);
} else {
  is($next + $start, 0);
}
