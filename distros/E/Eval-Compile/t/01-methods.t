# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Eval-Compile.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use ExtUtils::testlib;
use Eval::Compile;

my $s = 'Eval::Compile';

can_ok( $s, 'ceval');
can_ok( $s, 'cache_eval');
can_ok( $s, 'cached_eval');
can_ok( $s, 'cache_this');
can_ok( $s, 'cache_eval_undef');
use_ok( $s, 'cache_this', 'cached_eval', 'ceval', 'cache_eval', 'cache_eval_undef' );


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

