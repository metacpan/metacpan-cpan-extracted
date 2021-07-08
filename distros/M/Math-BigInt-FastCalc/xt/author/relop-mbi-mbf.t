#!perl

use strict;
use warnings;

use Test::More tests => 17642;

use Math::Complex ();

my $scalar_util_ok = eval { require Scalar::Util; };
Scalar::Util -> import('refaddr') if $scalar_util_ok;

diag "Skipping some tests since Scalar::Util is not installed."
  unless $scalar_util_ok;

my $inf = $Math::Complex::Inf;
my $nan = $inf - $inf;

my @table =
  (
   [ '<=>', 'bcmp', ],
   [ '==',  'beq',  ],
   [ '!=',  'bne',  ],
   [ '<',   'blt',  ],
   [ '<=',  'ble',  ],
   [ '>',   'bgt',  ],
   [ '>=',  'bge',  ],
  );

my @values = (-$inf, -2, 0, 2, $inf, $nan);

my @classes = (
               'Math::BigInt',
               'Math::BigFloat',
              );

for my $class (@classes) {

    use_ok($class);

    for my $entry (@table) {
        my $operator = $entry -> [0];
        my $method   = $entry -> [1];

        for my $xscalar (@values) {
            for my $yscalar (@values) {

                my $expected = eval qq|\$xscalar $operator \$yscalar|;

                note("#" x 70);
                note("");
                note(qq|"$xscalar" $operator "$yscalar" = |,
                       !defined $expected ? "undef"
                     : !length  $expected ? '""'
                     :          $expected);
                note("");
                note("#" x 70);

                {
                    my ($x, $y, $z);
                    my ($xval, $xaddr);
                    my ($yval, $yaddr);

                    $x = $class -> new("$xscalar");
                    $y = $class -> new("$yscalar");

                    my $test = qq|\$x = $class -> new("$xscalar"); |
                             . qq|\$y = $class -> new("$yscalar"); |;

                    $test .=   qq|\$xval = \$x -> copy(); |;
                    $test .=   qq|\$xaddr = refaddr(\$x); | if $scalar_util_ok;

                    $test .=   qq|\$yval = \$y -> copy(); |;
                    $test .=   qq|\$yaddr = refaddr(\$y); | if $scalar_util_ok;

                    $test .=   qq|\$z = \$x -> $method(\$y);|;

                    note("");
                    note("\$x -> $method(\$y) where \$x is an object",
                         " and \$y is an object");
                    note("");
                    note($test);
                    note("");

                    eval $test;

                    is($@, '', 'is $@ empty');

                    is($z,          $expected, 'value of $z');
                    is(ref($z),     '',        '$z is not a reference');

                    is($x, $xval, 'value of $x is unchanged');

                  SKIP: {
                        skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                        is(refaddr($x), $xaddr, 'address of $x is unchanged')
                    }

                    is($y, $yval, 'value of $y is unchanged');

                  SKIP: {
                        skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                        is(refaddr($y), $yaddr, 'address of $y is unchanged')
                    }
                }

                {
                    my ($x, $y, $z);
                    my ($xval, $xaddr);
                    my ($yval, $yaddr);

                    $x = $class -> new("$xscalar");
                    $y = $class -> new("$yscalar");

                    my $test = qq|\$x = $class -> new("$xscalar"); |
                             . qq|\$y = $class -> new("$yscalar"); |;

                    $test .=   qq|\$xval = \$x -> copy(); |;
                    $test .=   qq|\$xaddr = refaddr(\$x); | if $scalar_util_ok;

                    $test .=   qq|\$yval = \$y -> copy(); |;
                    $test .=   qq|\$yaddr = refaddr(\$y); | if $scalar_util_ok;

                    $test .=   qq|\$z = \$x $operator \$y;|;

                    note("");
                    note("\$x $operator \$y where \$x is an object and",
                         " \$y is an object");
                    note("");
                    note($test);
                    note("");

                    eval $test;

                    is($@, '', 'is $@ empty');

                    is($z,          $expected, 'value of $z');
                    is(ref($z),     '',        '$z is not a reference');

                    is($x, $xval, 'value of $x is unchanged');

                  SKIP: {
                        skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                        is(refaddr($x), $xaddr, 'address of $x is unchanged')
                    }

                    is($y, $yval, 'value of $y is unchanged');

                  SKIP: {
                        skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                        is(refaddr($y), $yaddr, 'address of $y is unchanged');
                    }
                }

                {
                    my ($x, $y, $z);
                    my ($xval, $xaddr);
                    my ($yval, $yaddr);

                    $x = $class -> new("$xscalar");
                    $y = $yscalar;

                    my $test = qq|\$x = $class -> new("$xscalar"); |
                             . qq|\$y = "$yscalar"; |;

                    $test .=   qq|\$xval = \$x -> copy(); |;
                    $test .=   qq|\$xaddr = refaddr(\$x); | if $scalar_util_ok;

                    $test .=   qq|\$yval = "$yscalar"; |;
                    $test .=   qq|\$yaddr = refaddr(\$y); | if $scalar_util_ok;

                    $test .=   qq|\$z = \$x -> $method(\$y);|;

                    note("");
                    note("\$x -> $method(\$y) where \$x is an object",
                         " and \$y is a scalar");
                    note("");
                    note($test);
                    note("");

                    eval $test;

                    is($@, '', 'is $@ empty');

                    is($z,          $expected, 'value of $z');
                    is(ref($z),     '',        '$z is not a reference');

                    is($x, $xval, 'value of $x is unchanged');

                  SKIP: {
                        skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                        is(refaddr($x), $xaddr, 'address of $x is unchanged');
                    }

                    is($y, $yval, 'value of $y is unchanged');

                  SKIP: {
                        skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                        is(refaddr($y), $yaddr, 'address of $y is unchanged');
                    }
                }

                {
                    my ($x, $y, $z);
                    my ($xval, $xaddr);
                    my ($yval, $yaddr);

                    $x = $class -> new("$xscalar");
                    $y = $class -> new("$yscalar");

                    my $test = qq|\$x = $class -> new("$xscalar"); |
                             . qq|\$y = "$yscalar"; |;

                    $test .=   qq|\$xval = \$x -> copy(); |;
                    $test .=   qq|\$xaddr = refaddr(\$x); | if $scalar_util_ok;

                    $test .=   qq|\$yval = "$yscalar"; |;
                    $test .=   qq|\$yaddr = refaddr(\$y); | if $scalar_util_ok;

                    $test .=   qq|\$z = \$x $operator \$y;|;

                    note("");
                    note("\$x $operator \$y where \$x is an object",
                         " and \$y is a scalar");
                    note("");
                    note($test);
                    note("");

                    eval $test;

                    is($@, '', 'is $@ empty');

                    is($z,          $expected, 'value of $z');
                    is(ref($z),     '',        '$z is not a reference');

                    is($x, $xval, 'value of $x is unchanged');

                  SKIP: {
                        skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                        is(refaddr($x), $xaddr, 'address of $x is unchanged')
                    }

                    is($y, $yval, 'value of $y is unchanged');

                  SKIP: {
                        skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                        is(refaddr($y), $yaddr, 'address of $y is unchanged')
                    }
                }

                {
                    my ($x, $y, $z);
                    my ($xval, $xaddr);
                    my ($yval, $yaddr);

                    $x = $class -> new("$xscalar");
                    $y = $class -> new("$yscalar");

                    my $test = qq|\$x = "$xscalar"; |
                             . qq|\$y = $class -> new("$yscalar"); |;

                    $test .=   qq|\$xval = "$xscalar"; |;
                    $test .=   qq|\$xaddr = refaddr(\$x); | if $scalar_util_ok;

                    $test .=   qq|\$yval = \$y -> copy(); |;
                    $test .=   qq|\$yaddr = refaddr(\$y); | if $scalar_util_ok;

                    $test .=   qq|\$z = \$x $operator \$y;|;

                    note("");
                    note("\$x $operator \$y where \$x is a scalar and",
                         " \$y is an object:");
                    note("");
                    note($test);
                    note("");

                    eval $test;

                    is($@, '', 'is $@ empty');

                    is($z,          $expected, 'value of $z');
                    is(ref($z),     '',        '$z is not a reference');

                    is($x, $xval, 'value of $x is unchanged');

                  SKIP: {
                        skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                        is(refaddr($x), $xaddr, 'address of $x is unchanged');
                    }

                    is($y, $yval, 'value of $y is unchanged');

                  SKIP: {
                        skip "Scalar::Util not available", 1 unless $scalar_util_ok;

                        is(refaddr($y), $yaddr, 'address of $y is unchanged');
                    }
                }
            }
        }
    }
}
