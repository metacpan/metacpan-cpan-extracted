# -*- mode: perl; -*-

use strict;
use warnings;

use Math::BigFloat;
use Scalar::Util qw< refaddr >;

use Test::More tests => 2;

my $LIB = Math::BigFloat -> config('lib');

my $x = Math::BigFloat -> new("314159e-5");
my $y;

# testing copy() as an instance method

$y = $x -> copy();
subtest '$y = $x -> copy()' => sub {
    plan tests => 21;

    # object

    ok(defined($y), '$y is defined');
    is(ref($y), 'Math::BigFloat', '$y has the right class');
    isnt(refaddr($y), refaddr($x), '$y is a different object than $x');

    # sign

    ok(defined($y->{sign}), 'sign of $y is defined');
    is(ref($y->{sign}), '', 'sign of $y is not a reference');
    is($y->{sign}, $x->{sign}, 'sign of $y is correct');

    # mantissa

    ok(defined($y->{_m}), 'mantissa of $y is defined');
    is(ref($y->{_m}), ref($x->{_m}),
       'mantissa of $y and $x use the same reference type');
    isnt(ref($y->{_m}), '', 'mantissa of $y is a reference');
    isnt(refaddr($y->{_m}), refaddr($x->{_m}),
      'mantissa of $y is not the mantissa of $x');
    is($LIB->_str($y->{_m}), $LIB->_str($x->{_m}),
       'mantissa of $y is correct');

    # exponent sign

    ok(defined($y->{_es}), 'exponent sign of $y is defined');
    is(ref($y->{_es}), '', 'exponent sign of $y is not a reference');
    is($y->{_es}, $x->{_es}, 'exponent sign of $y is correct');

    # exponent value

    ok(defined($y->{_e}), 'exponent mantissa of $y is defined');
    is(ref($y->{_e}), ref($x->{_e}),
       'exponent mantissa of $y and $x use the same reference type');
    isnt(ref($y->{_e}), '', 'exponent mantissa of $y is a reference');
    isnt(refaddr($y->{_e}), refaddr($x->{_e}),
      'exponent mantissa of $y is not the mantissa of $x');
    is($LIB->_str($y->{_e}), $LIB->_str($x->{_e}),
       'exponent mantissa of $y is correct');

    # accuracy and precision

    is($y->{_a}, $x->{_a}, 'accuracy');
    is($y->{_p}, $x->{_p}, 'precision');
};

# testing copy() as a class method

$y = Math::BigFloat -> copy($x);
subtest 'Math::BigFloat -> copy($x)' => sub {
    plan tests => 21;

    # object

    ok(defined($y), '$y is defined');
    is(ref($y), 'Math::BigFloat', '$y has the right class');
    isnt(refaddr($y), refaddr($x), '$y is a different object than $x');

    # sign

    ok(defined($y->{sign}), 'sign of $y is defined');
    is(ref($y->{sign}), '', 'sign of $y is not a reference');
    is($y->{sign}, $x->{sign}, 'sign of $y is correct');

    # mantissa

    ok(defined($y->{_m}), 'mantissa of $y is defined');
    is(ref($y->{_m}), ref($x->{_m}),
       'mantissa of $y and $x use the same reference type');
    isnt(ref($y->{_m}), '', 'mantissa of $y is a reference');
    isnt(refaddr($y->{_m}), refaddr($x->{_m}),
      'mantissa of $y is not the mantissa of $x');
    is($LIB->_str($y->{_m}), $LIB->_str($x->{_m}),
       'mantissa of $y is correct');

    # exponent sign

    ok(defined($y->{_es}), 'exponent sign of $y is defined');
    is(ref($y->{_es}), '', 'exponent sign of $y is not a reference');
    is($y->{_es}, $x->{_es}, 'exponent sign of $y is correct');

    # exponent value

    ok(defined($y->{_e}), 'exponent mantissa of $y is defined');
    is(ref($y->{_e}), ref($x->{_e}),
       'exponent mantissa of $y and $x use the same reference type');
    isnt(ref($y->{_e}), '', 'exponent mantissa of $y is a reference');
    isnt(refaddr($y->{_e}), refaddr($x->{_e}),
      'exponent mantissa of $y is not the mantissa of $x');
    is($LIB->_str($y->{_e}), $LIB->_str($x->{_e}),
       'exponent mantissa of $y is correct');

    # accuracy and precision

    is($y->{_a}, $x->{_a}, 'accuracy');
    is($y->{_p}, $x->{_p}, 'precision');
};
