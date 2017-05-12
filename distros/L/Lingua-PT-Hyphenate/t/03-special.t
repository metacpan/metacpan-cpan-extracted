# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 19;
BEGIN { use_ok('Lingua::PT::Hyphenate') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tests = '
FAN tás ti co
pro GRA ma dor
qUE
FAz
es TeS
MÓ DU LOS
';

my @tests = map { [split / /, $_] } split /\n/, $tests;

for (@tests) {
  my ($word, @expected) = ((join '', @$_), @$_);
  my @got = hyphenate($word);
  while ($a = shift @got) {
    $b = shift @expected;
    is($a,$b);
  }
  while (@expected) {
    $b = shift @expected;
    is(undef,$b);
  }
}

is(hyphenate(),());
is(hyphenate("123"),());
is(hyphenate("1hel2lo3"),());
