# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use Math::BigFloat;

my $class = 'Math::BigFloat';

my ($x, $test);

################################################

my $entries =
  [

   [
    '$x = Math::BigFloat -> bzero(); $x -> bsin();',
    '0',
   ],

   [
    '$x = Math::BigFloat -> bone(); $x -> bsin();',
    '0.8414709848078965066525023216302989996226',
   ],

   # Test accuracy.

   [
    '$x = Math::BigFloat -> bone(); $x -> bsin(8);',
    '0.84147098',
   ],

   [
    '$x = Math::BigFloat -> bone(); $x -> accuracy(8); $x -> bsin();',
    '0.84147098',
   ],

   [
    '$x = Math::BigFloat -> bone(); $x -> accuracy(8); $x -> bsin(4);',
    '0.8415',
   ],

   [
    '$x = Math::BigFloat -> bone(); $x -> accuracy(4); $x -> bsin(8);',
    '0.84147098',
   ],

   # Test precision.

   [
    '$x = Math::BigFloat -> bone(); $x -> bsin(undef, -8);',
    '0.84147098',
   ],

   [
    '$x = Math::BigFloat -> bone(); $x -> precision(-8); $x -> bsin();',
    '0.84147098',
   ],

   [
    '$x = Math::BigFloat -> bone(); $x -> precision(-8); $x -> bsin(undef, -3);',
    '0.841',
   ],

   [
    '$x = Math::BigFloat -> bone(); $x -> precision(-3); $x -> bsin(undef, -8);',
    '0.84147098',
   ],

   # Test accuracy for large positive argument.

   [
    '$x = Math::BigFloat -> new("123.45678"); $x -> bsin();',
    '-0.804401000865501740112089385846151121696',
   ],

   [
    '$x = Math::BigFloat -> new("123.45678"); $x -> bsin(60);',
    '-0.804401000865501740112089385846151121695970189701914695913935',
   ],

   [
    '$x = Math::BigFloat -> new("123.45678"); $x -> accuracy(60); $x -> bsin();',
    '-0.804401000865501740112089385846151121695970189701914695913935',
   ],

   [
    '$x = Math::BigFloat -> new("123.45678"); $x -> accuracy(40); $x -> bsin(60);',
    '-0.804401000865501740112089385846151121695970189701914695913935',
   ],

   [
    '$x = Math::BigFloat -> new("123.45678"); $x -> accuracy(80); $x -> bsin(60);',
    '-0.804401000865501740112089385846151121695970189701914695913935',
   ],

   # Test precision for large positive argument.

   [
    '$x = Math::BigFloat -> new("123.45678"); $x -> bsin();',
    '-0.804401000865501740112089385846151121696',
   ],

   [
    '$x = Math::BigFloat -> new("123.45678"); $x -> bsin(undef, -6);',
    '-0.804401',
   ],

   [
    '$x = Math::BigFloat -> new("123.45678"); $x -> precision(-6); $x -> bsin();',
    '-0.804401',
   ],

   [
    '$x = Math::BigFloat -> new("123.45678"); $x -> precision(-5); $x -> bsin(undef, -6);',
    '-0.804401',
   ],

   [
    '$x = Math::BigFloat -> new("123.45678"); $x -> precision(-9); $x -> bsin(undef, -6);',
    '-0.804401',
   ],

   # Test accuracy for large negative argument.

   [
    '$x = Math::BigFloat -> new("-123.45678"); $x -> bsin();',
    '0.804401000865501740112089385846151121696',
   ],

   [
    '$x = Math::BigFloat -> new("-123.45678"); $x -> bsin(60);',
    '0.804401000865501740112089385846151121695970189701914695913935',
   ],

   [
    '$x = Math::BigFloat -> new("-123.45678"); $x -> accuracy(60); $x -> bsin();',
    '0.804401000865501740112089385846151121695970189701914695913935',
   ],

   [
    '$x = Math::BigFloat -> new("-123.45678"); $x -> accuracy(40); $x -> bsin(60);',
    '0.804401000865501740112089385846151121695970189701914695913935',
   ],

   [
    '$x = Math::BigFloat -> new("-123.45678"); $x -> accuracy(80); $x -> bsin(60);',
    '0.804401000865501740112089385846151121695970189701914695913935',
   ],

   # Test precision for large negative argument.

   [
    '$x = Math::BigFloat -> new("-123.45678"); $x -> bsin(undef, -60);',
    '0.804401000865501740112089385846151121695970189701914695913935',
   ],

   [
    '$x = Math::BigFloat -> new("-123.45678"); $x -> precision(-60); $x -> bsin();',
    '0.804401000865501740112089385846151121695970189701914695913935',
   ],

   [
    '$x = Math::BigFloat -> new("-123.45678"); $x -> precision(-93); $x -> bsin(undef, -60);',
    '0.804401000865501740112089385846151121695970189701914695913935',
   ],

   [
    '$x = Math::BigFloat -> new("-123.45678"); $x -> precision(-133); $x -> bsin(undef, -60);',
    '0.804401000865501740112089385846151121695970189701914695913935',
   ],

  ];

for my $entry (@$entries) {
    my ($test, $want) = @$entry;

    note "\n", $test, "\n\n";
    eval $test;
    die $@ if $@;

    is($x, $want, 'value of $x');
}

done_testing();
