# -*- mode: perl; -*-

# The purpose is primarily to test upgrading and downgrading, not whether the
# method returns the correct value for various input. That is tested elsewhere.

use strict;
use warnings;

use Scalar::Util 'refaddr';
use Test::More;

use Math::BigFloat;

note "\nNo upgrading or downgrading\n\n";

Math::BigInt -> upgrade(undef);
Math::BigFloat -> downgrade(undef);

subtest '$x = Math::BigInt -> from_oct("1.1p+2");'
  => sub {
      # this must not upgrade

      my $x = Math::BigInt -> from_oct("1.1p+2");

      is(ref($x), "Math::BigInt", "class");
      is($x, "NaN", "value");
  };

subtest '$x = Math::BigFloat -> from_oct("4");'
  => sub {
      # this must not downgrade

      my $x = Math::BigFloat -> from_oct("4");

      is(ref($x), "Math::BigFloat", "class");
      is($x, "4", "value");
  };

subtest '$x = Math::BigInt -> new("4"); $q = $x -> from_oct("1.1p+2");'
  => sub {
      # this must not upgrade

      my $x = Math::BigInt -> new("4");
      my $q = $x -> from_oct("1.1p+2");                 # = 4.5

      is(ref($x), "Math::BigInt", "class");
      is($x, "NaN", "value");
      is(refaddr($x), refaddr($q), "address");
  };

subtest '$x = Math::BigFloat -> new("4.5"); $q = $x -> from_oct("4");'
  => sub {
      # this must not downgrade

      my $x = Math::BigFloat -> new("4.5");
      my $q = $x -> from_oct("4");

      is(ref($x), "Math::BigFloat", "class");
      is($x, "4", "value");
      is(refaddr($x), refaddr($q), "address");
  };

note "\nUpgrading and downgrading\n\n";

Math::BigInt -> upgrade("Math::BigFloat");
Math::BigFloat -> downgrade("Math::BigInt");

subtest '$x = Math::BigInt -> from_oct("1.1p+2");'
  => sub {
      # this must upgrade

      my $x = Math::BigInt -> from_oct("1.1p+2");

      is(ref($x), "Math::BigFloat", "class");
      is($x, "4.5", "value");
  };

subtest '$x = Math::BigFloat -> from_oct("4");'
  => sub {
      # this must downgrade

      my $x = Math::BigFloat -> from_oct("4");

      is(ref($x), "Math::BigInt", "class");
      is($x, "4", "value");
  };

subtest '$x = Math::BigInt -> new("4"); $q = $x -> from_oct("1.1p+2");'
  => sub {
      # this must upgrade

      my $x = Math::BigInt -> new("4");
      my $q = $x -> from_oct("1.1p+2");                 # = 4.5

      is(ref($x), "Math::BigFloat", "class");
      is($x, "4.5", "value");
      is(refaddr($x), refaddr($q), "address");
  };

subtest '$x = Math::BigFloat -> new("4.5"); $q = $x -> from_oct("4");'
  => sub {
      # this must downgrade

      my $x = Math::BigFloat -> new("4.5");
      my $q = $x -> from_oct("4");

      is(ref($x), "Math::BigInt", "class");
      is($x, "4", "value");
      is(refaddr($x), refaddr($q), "address");
  };

done_testing();
