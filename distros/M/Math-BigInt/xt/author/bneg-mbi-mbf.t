# -*- mode: perl; -*-

use strict;
use warnings;

use Scalar::Util 'refaddr';
use Test::More tests => 12;

use Math::BigFloat;

my $cases =
  [
   [ "-9",   "9"   ],
   [ "9",    "-9"   ],
   [ "0",    "0"   ],
   [ "-inf", "inf" ],
   [ "inf",  "-inf" ],
   [ "NaN",  "NaN" ],
  ];

for my $case (@$cases) {
    my ($in, $wanted) = @$case;

    subtest qq|Math::BigInt -> new("$in")| => sub {

        Math::BigInt -> upgrade(undef);
        Math::BigFloat -> downgrade(undef);

        my $x = Math::BigInt -> new($in);
        my $xa = refaddr($x);

        Math::BigInt -> upgrade("Math::BigFloat");
        Math::BigFloat -> downgrade("Math::BigInt");

        my $y = $x -> bneg();
        is($x, $wanted, "value");
        is(ref($x), "Math::BigInt", "class");
        is(refaddr($x), $xa, "address");
    };

    subtest qq|Math::BigFloat -> new("$in")| => sub {

        Math::BigInt -> upgrade(undef);
        Math::BigFloat -> downgrade(undef);

        my $x = Math::BigFloat -> new($in);
        my $xa = refaddr($x);

        Math::BigInt -> upgrade("Math::BigFloat");
        Math::BigFloat -> downgrade("Math::BigInt");

        my $y = $x -> bneg();
        is($x, $wanted, "value");
        is(ref($x), "Math::BigInt", "class");
        is(refaddr($x), $xa, "address");
    };
}
