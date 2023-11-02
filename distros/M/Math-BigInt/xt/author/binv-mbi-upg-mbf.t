# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 12;

my $class;
my $upgrade;

BEGIN {
    $class   = 'Math::BigInt';
    $upgrade = 'Math::BigFloat';
    use_ok($class);
    use_ok($upgrade);
}

# We need to create these before we enable upgrading, otherwise the upgrading
# will happen already in the constructors.

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

# Enable upgrading.

$class -> upgrade($upgrade);

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

        is(ref($x), $class, "\$x is still a $class");

        if ($up) {
            is(ref($y), $upgrade, "\$y is a $upgrade due to upgrading");
        } else {
            is(ref($y), $class, "\$y is a $class");
        }

        is($y, $want, "\$y has the right value");
    };
}
