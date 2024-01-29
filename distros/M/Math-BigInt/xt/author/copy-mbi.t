# -*- mode: perl; -*-

use strict;
use warnings;

use Math::BigInt;
use Scalar::Util qw< refaddr >;

use Test::More tests => 2;

my $LIB = Math::BigInt -> config('lib');

my $x = Math::BigInt -> new("314159");
my $y;

# testing copy() as an instance method

$y = $x -> copy();
subtest '$y = $x -> copy()' => sub {
    plan tests => 13;

    # object

    ok(defined($y), '$y is defined');
    is(ref($y), 'Math::BigInt', '$y has the right class');
    isnt(refaddr($y), refaddr($x), '$y is a different object than $x');

    # sign

    ok(defined($y->{sign}), 'sign of $y is defined');
    is(ref($y->{sign}), '', 'sign of $y is not a reference');
    is($y->{sign}, $x->{sign}, 'sign of $y is correct');

    # mantissa

    ok(defined($y->{value}), 'mantissa of $y is defined');
    is(ref($y->{value}), ref($x->{value}),
       'mantissa of $y and $x use the same reference type');
    isnt(ref($y->{value}), '', 'mantissa of $y is a reference');
    isnt(refaddr($y->{value}), refaddr($x->{value}),
      'mantissa of $y is not the mantissa of $x');
    is($LIB->_str($y->{value}), $LIB->_str($x->{value}),
       'mantissa of $y is correct');

    # accuracy and precision

    is($y->{accuracy}, $x->{accuracy}, 'accuracy');
    is($y->{precision}, $x->{precision}, 'precision');
};

# testing copy() as a class method

$y = Math::BigInt -> copy($x);
subtest '$y = Math::BigInt -> copy($x)' => sub {
    plan tests => 13;

    # object

    ok(defined($y), '$y is defined');
    is(ref($y), 'Math::BigInt', '$y has the right class');
    isnt(refaddr($y), refaddr($x), '$y is a different object than $x');

    # sign

    ok(defined($y->{sign}), 'sign of $y is defined');
    is(ref($y->{sign}), '', 'sign of $y is not a reference');
    is($y->{sign}, $x->{sign}, 'sign of $y is correct');

    # mantissa

    ok(defined($y->{value}), 'mantissa of $y is defined');
    is(ref($y->{value}), ref($x->{value}),
       'mantissa of $y and $x use the same reference type');
    isnt(ref($y->{value}), '', 'mantissa of $y is a reference');
    isnt(refaddr($y->{value}), refaddr($x->{value}),
      'mantissa of $y is not the mantissa of $x');
    is($LIB->_str($y->{value}), $LIB->_str($x->{value}),
       'mantissa of $y is correct');

    # accuracy and precision

    is($y->{accuracy}, $x->{accuracy}, 'accuracy');
    is($y->{precision}, $x->{precision}, 'precision');
};
