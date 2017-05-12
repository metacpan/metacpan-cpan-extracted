# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Lingua::FA::Number') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use_ok('Lingua::FA::Number');
my $s = Lingua::FA::Number::convert("Hi 1 Hi 2 Hi 3");
ok  ( defined($s) , "Defined?");
is  ($s, "Hi &#1777; Hi &#1778; Hi &#1779;" , "Error!");
