# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 12;

my $class;
my $downgrade;

BEGIN {
    $class     = 'Math::BigFloat';
    $downgrade = 'Math::BigInt';
    use_ok($class);
    use_ok($downgrade);
}

# We need to create these before we enable downgrading, otherwise the
# downgrading will happen already in the constructors.

my $ninf  = $class -> binf("-");
my $nfour = $class -> new("-4");
my $ntwo  = $class -> new("-2");
my $none  = $class -> bone("-");

my $zero  = $class -> bzero();

my $pone  = $class -> bone();
my $ptwo  = $class -> new("2");
my $pfour = $class -> new("4");
my $pinf  = $class -> binf();

my $nan   = $class -> bnan();

# Enable downgrading.

$class -> downgrade($downgrade);

my $data =
  [
   # input, output, 0=down/1=up
   [ $ninf,   0,    0, ],
   [ $nfour, -0.25, 1, ],
   [ $ntwo,  -0.5,  1, ],
   [ $none,  -1,    0, ],
   [ $zero, "inf",  0, ],
   [ $pone,   1,    0, ],
   [ $ptwo,   0.5,  1, ],
   [ $pfour,  0.25, 1, ],
   [ $pinf,   0,    0, ],
   [ $nan,  "NaN",  0, ],
   ];

for my $entry (@$data) {
    my ($x, $want, $up) = @$entry;

    my $test = qq|binv("$x")|;
    my $y = $x -> binv();

    subtest $test => sub {
        plan tests => 3;

        if ($up) {
            is(ref($x), $class, "\$x is a $class");
            is(ref($y), $class, "\$y is a $class");
        } else {
            is(ref($x), $downgrade, "\$x is a $downgrade due to downgrading");
            is(ref($y), $downgrade, "\$y is a $downgrade due to downgrading");
        }

        is($y, $want, "\$y has the right value");
    };
}
