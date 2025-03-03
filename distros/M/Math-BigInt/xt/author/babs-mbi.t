# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 72;
use Scalar::Util qw< refaddr >;

use Math::BigInt;
use Math::BigFloat;
use Math::BigRat;

my $cases =
  [
   [ "-9",   "9"   ],
   [ "9",    "9"   ],
   [ "0",    "0"   ],
   [ "-inf", "inf" ],
   [ "inf",  "inf" ],
   [ "NaN",  "NaN" ],
  ];

note("\nMath::BigInt->babs() without downgrading and upgrading\n\n");

note("babs() as an instance method");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    my $x = Math::BigInt -> new($in);
    my $xa = refaddr($x);
    my $y = $x -> babs();

    subtest qq|\$x = Math::BigInt -> new("$in"); \$y = \$x -> babs();| =>
      sub {
          plan tests => 3;
          is(ref($x), 'Math::BigInt', 'class');
          is(refaddr($y), $xa, 'address');
          is($x, $wanted, 'value');
      };
}

note("babs() as a class method given a scalar");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    my $y = Math::BigInt -> babs($in);

    subtest qq|\$y = Math::BigInt -> babs("$in");| =>
      sub {
          plan tests => 2;
          is(ref($y), 'Math::BigInt', 'class');
          is($y, $wanted, 'value');
      };
}

note("babs() as a class method given a Math::BigInt");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    my $x = Math::BigInt -> new($in);
    my $y = Math::BigInt -> babs($x);

    subtest qq|\$x = Math::BigInt -> new("$in"); \$y = Math::BigInt -> babs(\$x);| =>
      sub {
          plan tests => 2;
          is(ref($y), 'Math::BigInt', 'class');
          is($y, $wanted, 'value');
      };
}

note("babs() as a class method given a Math::BigFloat");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    my $x = Math::BigFloat -> new($in);
    my $y = Math::BigInt -> babs($x);

    subtest qq|\$x = Math::BigFloat -> new("$in"); \$y = Math::BigInt -> babs(\$x);| =>
      sub {
          plan tests => 2;
          is(ref($y), 'Math::BigInt', 'class');
          is($y, $wanted, 'value');
      };
}

note("babs() as a class method given a Math::BigRat");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    my $x = Math::BigRat -> new($in);
    my $y = Math::BigInt -> babs($x);

    subtest qq|\$x = Math::BigRat -> new("$in"); \$y = Math::BigInt -> babs(\$x);| =>
      sub {
          plan tests => 2;
          is(ref($y), 'Math::BigInt', 'class');
          is($y, $wanted, 'value');
      };
}

note("babs() as a function");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    my $y = Math::BigInt::babs($in);

    subtest qq|\$y = Math::BigInt::babs("$in");| =>
      sub {
          plan tests => 2;
          is(ref($y), 'Math::BigInt', 'class');
          is($y, $wanted, 'value');
      };
}

note("\nMath::BigInt->babs() with downgrading and upgrading\n\n");

note("babs() as an instance method");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    Math::BigInt -> upgrade(undef);
    Math::BigFloat -> downgrade(undef);

    my $x = Math::BigInt -> new($in);
    my $xa = refaddr($x);

    Math::BigInt -> upgrade("Math::BigFloat");
    Math::BigFloat -> downgrade("Math::BigInt");

    my $y = $x -> babs();

    subtest qq|\$x = Math::BigInt -> new("$in"); \$y = \$x -> babs();| =>
      sub {
          plan tests => 3;
          is(ref($x), 'Math::BigInt', 'class');
          is(refaddr($y), $xa, 'address');
          is($x, $wanted, 'value');
      };
}

note("babs() as a class method");

note("babs() as a class method given a scalar");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    Math::BigInt -> upgrade("Math::BigFloat");
    Math::BigFloat -> downgrade("Math::BigInt");

    my $y = Math::BigInt -> babs($in);

    subtest qq|\$y = Math::BigInt -> babs("$in");| =>
      sub {
          plan tests => 2;
          is(ref($y), 'Math::BigInt', 'class');
          is($y, $wanted, 'value');
      };
}

note("babs() as a class method given a Math::BigInt");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    Math::BigInt -> upgrade(undef);
    Math::BigFloat -> downgrade(undef);

    my $x = Math::BigInt -> new($in);

    Math::BigInt -> upgrade("Math::BigFloat");
    Math::BigFloat -> downgrade("Math::BigInt");

    my $y = Math::BigInt -> babs($x);

    subtest qq|\$x = Math::BigInt -> new("$in"); \$y = Math::BigInt -> babs(\$x);| =>
      sub {
          plan tests => 2;
          is(ref($y), 'Math::BigInt', 'class');
          is($y, $wanted, 'value');
      };
}

note("babs() as a class method given a Math::BigFloat");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    Math::BigInt -> upgrade(undef);
    Math::BigFloat -> downgrade(undef);

    my $x = Math::BigFloat -> new($in);

    Math::BigInt -> upgrade("Math::BigFloat");
    Math::BigFloat -> downgrade("Math::BigInt");

    my $y = Math::BigInt -> babs($x);

    subtest qq|\$x = Math::BigFloat -> new("$in"); \$y = Math::BigInt -> babs(\$x);| =>
      sub {
          plan tests => 2;
          is(ref($y), 'Math::BigInt', 'class');
          is($y, $wanted, 'value');
      };
}

note("babs() as a class method given a Math::BigRat");

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    Math::BigInt -> upgrade(undef);
    Math::BigFloat -> downgrade(undef);

    my $x = Math::BigRat -> new($in);

    Math::BigInt -> upgrade("Math::BigFloat");
    Math::BigFloat -> downgrade("Math::BigInt");

    my $y = Math::BigInt -> babs($x);

    subtest qq|\$x = Math::BigRat -> new("$in"); \$y = Math::BigInt -> babs(\$x);| =>
      sub {
          plan tests => 2;
          is(ref($y), 'Math::BigInt', 'class');
          is($y, $wanted, 'value');
      };
}

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    note("babs() as a function");

    Math::BigInt -> upgrade("Math::BigFloat");
    Math::BigFloat -> downgrade("Math::BigInt");

    my $y = Math::BigInt::babs($in);

    subtest qq|\$y = Math::BigInt::babs("$in");| =>
      sub {
          plan tests => 2;
          is(ref($y), 'Math::BigInt', 'class');
          is($y, $wanted, 'value');
      };
}
