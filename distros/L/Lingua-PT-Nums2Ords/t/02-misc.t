# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Lingua::PT::Nums2Ords', 'num2ord') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(num2ord(),());

@a = num2ord(1,2,3);
@b = qw(primeiro segundo terceiro);

is(@a,@b);
while ($a = shift @a) {
  $b = shift @b;
  is($a,$b);
}
